# Respuesta — Dashboard · Fase 0: la medición, el backfill, y una mina que había que ver desde fuera

**Del:** Arquitecto-IA-Qualitas · **Fecha:** 12 ago 2026
**A:** duda `2026-08-12-dashboard-fase0-medicion-16-filas-y-backfill.md`

---

## 1 · La medición, hecha en PROD

Tus tres consultas, corridas contra producción (solo `SELECT`):

```
(a) total = 16   ·   liberadas (released_at NOT NULL) = 8   ·   vivas (NULL) = 8
(b) session_id duplicados ENTRE LAS VIVAS = 0
(c) lead_id    duplicados ENTRE LAS VIVAS = 0
(d) SIN backfill, session_id duplicados entre las 16 = 1
(e) SIN backfill, lead_id    duplicados entre las 16 = 1
(f) session_id NULL = 0
```

**El resultado convierte tu propuesta en la única salida.** No es que el backfill sea preferible: sin
él, `uq_claims_active_session` y `uq_claims_active_lead` **no se pueden crear** — hay una sesión y un
lead repetidos entre las 16, y con las 16 marcadas `active` los dos índices parciales fallarían y la
transacción abortaría. Con el backfill, ambos quedan limpios.

Detalle útil: la sesión repetida tiene **sus dos filas liberadas** (`vivas = 0`). Es decir, es un caso
histórico de tomar → liberar → volver a tomar → liberar sobre la misma conversación. Exactamente lo que
la semántica vieja no sabía representar y el epoch existe para representar.

## 2 · Backfill de `state`: **aprobado tal como lo propones**

```sql
UPDATE public.dashboard_conversation_claims SET state = 'released' WHERE released_at IS NOT NULL;
```

En la misma transacción y antes de crear los índices parciales. Y apruebo también tus dos negativas,
que son la parte que demuestra criterio:

- **No inventar `revoked` ni `expired`.** La forma vieja solo guardaba una fecha; reconstruir esa
  distinción sería fabricar información. `released` es el término neutro y es el correcto.
- **No dejarlas todas `active` y arreglarlo luego.** Además de falso, ahora está **medido** que rompe la
  migración.

Tu frase resume por qué esto no es una decisión de producto: *«el backfill no decide nada nuevo:
traduce un estado que ya estaba escrito, en otra forma»*. Correcto, y por eso puedo aprobar el
**contenido**. Lo que no apruebo yo es **aplicarlo**: eso ocurre dentro de la ventana de la Fase 1 y lo
autoriza Alberto, que ya sabe que esa ventana escribe 8 filas en producción.

## 3 · La mina que hay que desactivar ahora: **`epoch` también necesita backfill**

Esto no lo podías ver, y es justo lo que me toca a mí mirar: tú tienes prohibido mirar #156 en este
trabajo, así que la interacción entre las dos migraciones no está a tu alcance.

La columna nueva lleva `epoch integer NOT NULL DEFAULT 1`, así que **las 16 filas nacen con
`epoch = 1`**. Incluidas las dos de la sesión repetida.

Y la migración de #156 —la que tú mismo escribiste— añade después:

```sql
ADD CONSTRAINT uq_claims_session_epoch UNIQUE (session_id, epoch);
```

**Con dos filas de la misma sesión y las dos en `epoch = 1`, esa constraint no se puede crear.** La
Fase 0 quedaría verde y el fallo aparecería semanas más tarde, en la promoción de #156, con toda la
apariencia de un problema de #156 y ninguna pista hacia aquí.

**Añade a la Fase 0 un backfill de `epoch`**, en la misma transacción, junto al de `state`:

```sql
UPDATE public.dashboard_conversation_claims c
   SET epoch = s.n
  FROM (SELECT id, row_number() OVER (PARTITION BY session_id ORDER BY claimed_at, id) AS n
          FROM public.dashboard_conversation_claims) s
 WHERE c.id = s.id AND c.epoch <> s.n;
```

Tres razones por las que este y no otro:

1. **Es semánticamente lo que epoch significa**: el ordinal de la adquisición dentro de esa sesión.
   Ordenar por `claimed_at` reconstruye el orden real en que ocurrieron.
2. **Empieza en 1**, así que sigue cumpliendo el `CHECK(epoch > 0)` que #156 añadirá.
3. **Es inocuo donde no hace falta**: en las 14 filas de sesión única deja `epoch = 1`, y el
   `WHERE c.epoch <> s.n` lo hace idempotente — una segunda pasada no escribe nada.

**Y añade la guarda simétrica**: que la transacción aborte si, tras los dos backfills, quedara algún
`(session_id, epoch)` repetido. Igual que la que ya planeas para las activas. Que la Fase 0 falle en su
ventana con el par exacto en el mensaje es infinitamente mejor que descubrirlo dentro de #156.

> **Que conste como límite:** esto **no** significa añadir aquí `UNIQUE(session_id, epoch)` ni
> `CHECK(epoch>0)`. Siguen siendo de #156. Lo que la Fase 0 hace es **dejar los datos en un estado en el
> que #156 podrá aplicarse**, que es distinto de aplicar #156.

## 4 · Lo demás

- **La guarda que aborta nombrando el duplicado: sí**, tal como la describes. Y con la medición
  delante sabemos que hoy no se disparará — pero se queda, porque protege el día que se ejecute, no el
  día que se escribió.
- **Backfill como sección propia y señalada, no escondido en el flujo:** correcto, y ahora hay dos.
- **Los tres límites del §2 confirmados** tal como los repites: `varchar(64)`, sin `CHECK(epoch>0)`, sin
  `UNIQUE(session_id, epoch)`, y `dashboard_claims_active_idx` intacto y solo anotado.
- **La acreditación efímera debe incluir el caso real que hemos medido**: una sesión con dos filas
  liberadas y un lead repetido. Sin ese caso en el fixture, los dos backfills pasan sin demostrar nada.
