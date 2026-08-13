# Runbook — Fase 1: aplicar el esquema en PRODUCCIÓN

**Para:** Alberto, operando. **De:** Arquitecto-IA-Qualitas · 12 ago 2026.
**Plan:** `2026-08-12-plan-promocion-stg-a-prod-v2.md`, Fase 1.
**Formato:** SQL puro, para pegar en TablePlus. Sin `psql`, sin metacomandos.

> **Esta ventana escribe en producción.** DDL aditivo en tres tablas y un `UPDATE` de hasta 8 filas.
> No cambia comportamiento —nadie lee esas columnas todavía— pero es escritura y necesita autorización
> explícita tuya en el momento.

---

## 0 ante. ⚠️ El orden de las migraciones es un **requisito duro**, no una preferencia

**Las migraciones de paridad de la Fase 0 van SIEMPRE antes que las de `#156`.** Invertirlo no degrada
nada: **aborta**.

Motivo, medido: las dos banderas del archive tienen **tres** estados posibles, no dos —ausente en PROD,
nullable en STG, y `NOT NULL DEFAULT false` que no existe en ninguna base pero que **crearía** el paso
P2 de `migrations/156/001-readiness`, porque copia la nulabilidad de la tabla activa—.

| Orden | Qué pasa |
|---|---|
| **Fase 0 → `156/001`** (el del plan) | Las siete entran **nullable** en el archive. Después, P2 las encuentra y es un no-op. PROD acaba igual que STG. **Correcto** |
| `156/001` → Fase 0 (invertido) | P2 las crea `NOT NULL DEFAULT false`. Luego la guarda G3 de la Fase 0 ve una columna con otra forma que su objetivo y **aborta la transacción entera**: `STOP/G3: … ya existe con NOT NULL=t y el objetivo es NOT NULL=f. Nada escrito.` |

Ese aborto es *fail-closed* y es el comportamiento correcto —mejor abortar que escribir sobre un
esquema que no se reconoce—, pero significa que **el orden es una dependencia**. Queda declarado aquí,
que es el documento de la ventana, y no en un comentario dentro de un fichero.

**Consecuencia práctica:** el merge de `#156` a `stg` y la aplicación de sus migraciones **no pueden
adelantarse** a las ventanas de paridad. Está alineado con el plan —#156 va después de la Fase 5— pero
ahora se sabe *por qué* y no solo *en qué orden*.

---

## 0 bis. Quién aplica y quién acredita — **decidir antes de abrir**

Lo levantó el Agente Dashboard y al primer borrador de este runbook le faltaba. La regla de ventana es:

> **Quien despliega no acredita. Dos criterios, no uno.**

Y hay un hecho que la condiciona: **el Agente Dashboard no puede aplicar nada** — trabaja bajo cero
accesos vivos y en producción ni siquiera puede leer `dashboard_conversation_claims`. El Arquitecto sí
tiene lectura de PROD; Alberto tiene Heroku.

Dos repartos válidos, y hay que elegir uno **antes** de abrir:

| | Aplica | Acredita |
|---|---|---|
| **A** | Alberto, desde TablePlus con este runbook | El Arquitecto, leyendo el catálogo por su cuenta |
| **B** | El Arquitecto | Alberto, con las consultas de este documento |

**Recomiendo A.** El que escribe las consultas de verificación no debería ser el mismo que ejecuta el
cambio, y así el segundo par de ojos mira de verdad y no repite su propio trabajo.

## 0 ter. ¿Y si la migración de n8n no está lista?

**Las dos tablas son independientes: no hay dependencia técnica entre las dos migraciones.** Así que
esta ventana *puede* aplicar solo la de claims.

Pero es una decisión, no un automatismo. Aplicar solo claims desbloquea la **Fase 2** (Dashboard a
producción) y deja la **Fase 3.2** (Atención Humana) esperando otra ventana. Si la de n8n va a estar en
horas, esperar y hacer una sola ventana cuesta menos que hacer dos. **Lo decide Alberto en el momento**,
y se anota cuál de los dos caminos se tomó.

---

## 0. Antes de abrir la ventana

| # | Comprobación | Estado |
|---|---|---|
| 1 | Las **dos migraciones** entregadas, revisadas por mí y acreditadas en PostgreSQL efímero | ⏳ Fase 0 en curso |
| 2 | **Backup capturado**: `heroku pg:backups:capture -a hyl-wai-production` y anotado el ID | ⏳ |
| 3 | Rollback escrito y a mano (§5) | ⏳ |
| 4 | Nadie más tocando la base | ⏳ |

**Franja recomendada: 13:00–15:00 UTC (07:00–09:00 MX).** En 7 días de tráfico solo hubo 36 mensajes,
y ninguno entre las 02:00 y las 15:00 UTC. No es que la ventana de lock importe —son 1 084 filas— sino
que si algo sale mal, el rato hasta arreglarlo cuesta menos.

---

## 1. Foto del antes (copiar el resultado antes de tocar nada)

```sql
SELECT 'whatsapp_sessions' AS tabla, count(*) AS filas FROM public.whatsapp_sessions
UNION ALL SELECT 'whatsapp_sessions_archive', count(*) FROM public.whatsapp_sessions_archive
UNION ALL SELECT 'dashboard_conversation_claims', count(*) FROM public.dashboard_conversation_claims;
```

Esperado hoy: **1084 · 113 · 16**. Si no cuadra, no es un problema — solo significa que la base ha
vivido desde que medí; anótalo y sigue.

```sql
SELECT c.relname AS tabla, count(*) AS columnas
FROM pg_attribute a
JOIN pg_class c ON c.oid = a.attrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relname IN ('whatsapp_sessions','whatsapp_sessions_archive','dashboard_conversation_claims')
  AND a.attnum > 0 AND NOT a.attisdropped
GROUP BY c.relname ORDER BY 1;
```

Esperado **antes**: `dashboard_conversation_claims` **6** · `whatsapp_sessions` **17** ·
`whatsapp_sessions_archive` **19**.

---

## 2. Aplicar — una migración por vez, verificando entre medias

**Orden: primero n8n (sesiones), después Dashboard (claims).** No porque haya dependencia entre ellas
—no la hay— sino porque la de sesiones es DDL puro y la de claims además escribe datos: si algo va a
salir mal, que salga en la más simple.

### 2.1 · Sesiones y archive — migración del Agente n8n

Pegar el fichero entregado en `Agente-n8n:migrations/prod-paridad/`. Es una sola transacción con sus
guardas: **o entra entera o no entra nada**.

Verificación inmediata:

```sql
SELECT c.relname AS tabla, a.attname AS columna,
       format_type(a.atttypid, a.atttypmod) AS tipo,
       a.attnotnull AS not_null,
       pg_get_expr(d.adbin, d.adrelid) AS por_defecto
FROM pg_attribute a
JOIN pg_class c ON c.oid = a.attrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
LEFT JOIN pg_attrdef d ON d.adrelid = a.attrelid AND d.adnum = a.attnum
WHERE n.nspname = 'public'
  AND c.relname IN ('whatsapp_sessions','whatsapp_sessions_archive')
  AND a.attname IN ('human_takeover','human_takeover_control_id','human_takeover_epoch',
                    'metepec_derived','metepec_derived_at','metepec_op_lock_id','metepec_op_locked_at')
ORDER BY c.relname, a.attname;
```

**Tienen que salir 14 filas** (7 columnas × 2 tablas). Y la asimetría deliberada de STG debe estar
reproducida:

- en `whatsapp_sessions`: `human_takeover` y `metepec_derived` con `not_null = true` y
  `por_defecto = false`;
- en `whatsapp_sessions_archive`: las dos **nullable y sin default**.

Si sale otra cosa: **abortar aquí**, no continuar con claims.

### 2.2 · Claims — migración del Agente Dashboard

Pegar el fichero entregado en `Dashboard:migrations/`. Incluye **dos backfills** dentro de la misma
transacción, y por eso esta parte escribe datos:

- `state = 'released'` donde `released_at IS NOT NULL` — hoy son **8 filas**;
- `epoch` por orden real de adquisición dentro de cada sesión — hoy toca **2 filas** (la sesión
  repetida), el resto se quedan en 1.

Verificación de columnas:

```sql
SELECT a.attname AS columna, format_type(a.atttypid, a.atttypmod) AS tipo, a.attnotnull AS not_null,
       pg_get_expr(d.adbin, d.adrelid) AS por_defecto
FROM pg_attribute a
JOIN pg_class c ON c.oid = a.attrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
LEFT JOIN pg_attrdef d ON d.adrelid = a.attrelid AND d.adnum = a.attnum
WHERE n.nspname = 'public' AND c.relname = 'dashboard_conversation_claims'
  AND a.attnum > 0 AND NOT a.attisdropped
ORDER BY a.attnum;
```

**12 columnas.** `control_id uuid NOT NULL DEFAULT gen_random_uuid()` · `conversation_id varchar(64)` ·
`quotation_id integer` · `epoch integer NOT NULL DEFAULT 1` · `state text NOT NULL DEFAULT 'active'` ·
`lease_expires_at timestamptz`.

Verificación de índices y del CHECK:

```sql
SELECT indexname FROM pg_indexes
WHERE schemaname = 'public' AND tablename = 'dashboard_conversation_claims' ORDER BY 1;
```

Esperado: `dashboard_claims_active_idx` · `dashboard_conversation_claims_pkey` ·
`uq_claims_active_lead` · `uq_claims_active_session` · `uq_claims_control_id`.

```sql
SELECT conname FROM pg_constraint
WHERE conrelid = 'public.dashboard_conversation_claims'::regclass ORDER BY 1;
```

Debe aparecer `ck_claims_state`. **No** deben aparecer `ck_claims_epoch_positivo` ni
`uq_claims_session_epoch`: esos son de #156 y **no entran en esta ventana**. Si están, algo se ha
mezclado — abortar y decírmelo.

Verificación de los backfills:

```sql
SELECT state, count(*) AS filas, count(*) FILTER (WHERE released_at IS NOT NULL) AS con_fecha_de_liberacion
FROM public.dashboard_conversation_claims GROUP BY state ORDER BY 1;
```

Esperado: **`active` 8** (todas con `con_fecha_de_liberacion = 0`) y **`released` 8** (todas con 8).
Cualquier fila `active` que tenga fecha de liberación es un fallo del backfill.

```sql
SELECT session_id, epoch, count(*) AS veces
FROM public.dashboard_conversation_claims
GROUP BY session_id, epoch HAVING count(*) > 1;
```

**Tiene que devolver cero filas.** Es la prueba de que la mina de `#156` quedó desactivada: si aquí
sale algo, la migración de descuentos no podrá aplicarse más adelante.

---

## 3. Que el mundo sigue girando

Después del DDL, y **antes de cerrar la ventana**:

1. **El bot responde.** Manda un WhatsApp desde el teléfono de pruebas y comprueba que contesta. n8n
   escribe en `whatsapp_sessions` y acabamos de añadirle columnas: es la comprobación que de verdad
   importa.
2. **El Dashboard lee.** Abre la consola: la bandeja y el listado de leads cargan con los mismos
   conteos que antes.
3. **Nada nuevo en los logs de Heroku** en los minutos siguientes.

```sql
SELECT count(*) AS mensajes_ultima_hora
FROM public.n8n_chat_histories
WHERE id > (SELECT max(id) - 50 FROM public.n8n_chat_histories);
```

---

## 4. Criterios de aborto

Cualquiera de estos y se cierra la ventana **sin continuar**:

- una migración aborta por su propia guarda — es lo que tiene que pasar si la realidad no coincide;
  **no la fuerces**, tráemela y se corrige el artefacto;
- la cuenta de columnas no cuadra tras aplicar;
- aparece un `(session_id, epoch)` repetido;
- el bot deja de responder o el Dashboard deja de leer.

**Regla dura, la que se rompió en S1:** nada se arregla dentro de una ventana abierta. Se cierra, se
corrige el artefacto, se vuelve otro día.

---

## 5. Rollback

Solo si hace falta de verdad, y sabiendo que **no hará falta casi nunca**: las columnas son aditivas y
en producción **nadie las lee todavía**. Dejarlas puestas es inocuo, y esa es la salida preferida.

Si aun así hay que deshacer:

```sql
ALTER TABLE public.dashboard_conversation_claims
  DROP CONSTRAINT IF EXISTS ck_claims_state;
DROP INDEX IF EXISTS public.uq_claims_control_id;
DROP INDEX IF EXISTS public.uq_claims_active_session;
DROP INDEX IF EXISTS public.uq_claims_active_lead;
ALTER TABLE public.dashboard_conversation_claims
  DROP COLUMN IF EXISTS control_id,
  DROP COLUMN IF EXISTS conversation_id,
  DROP COLUMN IF EXISTS quotation_id,
  DROP COLUMN IF EXISTS epoch,
  DROP COLUMN IF EXISTS state,
  DROP COLUMN IF EXISTS lease_expires_at;

ALTER TABLE public.whatsapp_sessions
  DROP COLUMN IF EXISTS human_takeover,
  DROP COLUMN IF EXISTS human_takeover_control_id,
  DROP COLUMN IF EXISTS human_takeover_epoch,
  DROP COLUMN IF EXISTS metepec_derived,
  DROP COLUMN IF EXISTS metepec_derived_at,
  DROP COLUMN IF EXISTS metepec_op_lock_id,
  DROP COLUMN IF EXISTS metepec_op_locked_at;

ALTER TABLE public.whatsapp_sessions_archive
  DROP COLUMN IF EXISTS human_takeover,
  DROP COLUMN IF EXISTS human_takeover_control_id,
  DROP COLUMN IF EXISTS human_takeover_epoch,
  DROP COLUMN IF EXISTS metepec_derived,
  DROP COLUMN IF EXISTS metepec_derived_at,
  DROP COLUMN IF EXISTS metepec_op_lock_id,
  DROP COLUMN IF EXISTS metepec_op_locked_at;
```

> **El `DROP COLUMN` de claims destruye los backfills**: `state` y `epoch` se van con la columna. Si se
> vuelve a aplicar, se recalculan igual desde `released_at` y `claimed_at`, que siguen ahí. No se pierde
> información real — pero conviene saberlo antes de teclearlo, no después.

El backup del paso 0.2 es la red de seguridad de último recurso.

---

## 6. Lo que esta ventana deja listo, y lo que no

**Deja listo:** que el Dashboard de `stg` pueda funcionar en producción (Fase 2) y que Atención Humana
tenga dónde escribir (Fase 3). **No cambia** ni una respuesta al cliente.

**No hace:** ni promover código, ni activar nada, ni tocar `#156`.

---

## Apéndice · Una precondición de la Fase 2, resuelta hoy sin gastar ventana

El plan pedía «acreditar por comportamiento qué camino toma el proactivo en PROD con
`S1_DASHBOARD_MODE` ausente». Dos hechos, comprobados:

1. **La variable no existe en Production** (verificado en Vercel: solo están las tres del proactivo).
2. **Da igual que exista.** `getS1DashboardMode()` devuelve `null` salvo que
   `VERCEL_ENV === 'preview'` **y** la rama sea `stg`. En producción `VERCEL_ENV` es `production`, así
   que devuelve `null` **por construcción, no por el valor de la variable**. Y el selector del proactivo
   es `if (s1Mode) … else handleLegacyProd(…)`, de modo que producción toma el **camino legacy** —
   coherente con que el 100 % de sus sesiones tengan `session_id = phone_number`.

Sigue habiendo que observarlo **después** de desplegar, porque una cosa es leer el código y otra ver el
sistema; pero ya no es una incógnita, y poner o quitar esa variable en producción **no cambiaría nada**.

**Deuda que hay que decir en voz alta:** lo que viaja a producción es `stg`, que **difiere de la
candidata S1 acreditada** (`feature/s1-v11-dashboard`) — los guards fueron retirados el 9 de agosto.
En producción esos guards nunca actuaron (el modo siempre fue `null` allí), así que **no hay cambio de
comportamiento por eso**. Pero conviene que conste: se promueve `stg`, no la candidata.


---

## Corrección (13 ago) — retirada la excepción de «dos sistemas» para Atención Humana

En el trabajo de la Fase 4 se declaró que la ventana de Atención Humana era una **excepción** a «un
sistema, una ventana», porque los `webhookId` se generarían al crear el workflow y habría que cablear
el Dashboard **en medio** de la secuencia.

**La premisa era falsa.** La URL de un webhook de n8n se construye con su **`path`**, no con su
`webhookId`; el id solo hace de path cuando el `path` está vacío. Verificado contra producción:

```
Retomar Conversacion · nodo Webhook
  path       proactive-wa-message      <- de aquí sale la URL
  webhookId  afd2b47d-bd99-4525-93a6-42764b8f56df   (interno)
```

**Consecuencias:** las URLs de Atención Humana **se conocen desde ya**, el Dashboard puede cablearse
**antes y en paralelo**, y **la excepción queda retirada**: vuelve a ser una ventana normal.

Lo único que sobrevive: la URL **solo responde con el workflow activo** (inactivo → 404), así que
activar es el último paso.

**De quién salió el error y cómo se encontró:** lo dedujo el Agente n8n y lo trasladé yo sin
verificarlo. Lo encontró él mismo al escribir los datos exactos que le pedí — la precisión destapó una
premisa que el razonamiento correcto había dado por buena. Es la cuarta vez hoy que el fallo no está en
el razonamiento sino en el hecho de partida.
