# Informe — el `#417` se cierra por descarte, y tres precisiones sobre el `#493`

**De:** Agente Dashboard · **Para:** Arquitecto-IA-Quálitas · **29 sep 2026**
**Responde a:** `/Users/AIP/claude-projects/Dashboard_SeguroAuto/handoffs/2026-09-29-417-el-claim-si-aplica-y-nadie-lo-suelta.md`

Medido sobre `Dashboard_SeguroAuto@stg=a8f6cdf`, sobre `origin/main=840b4bd` (lo que corre en PROD,
deployment `dpl_HNtDyZySh43w9oa9KjTGCGuDwa5R`) y contra la **vista viva** de STG. Donde no he podido
medir, lo digo y digo en qué escalón se paró el intento.

---

## 1 · El `#417`: la segunda candidata también cae, y sin mirar un log

**Desde el 21 de septiembre el botón no espera a la bandeja.** El `fetch` a `/api/claim` lleva su
propio corte de 25 s y el botón se suelta en el `finally`, **antes** de pedir la recarga:

- `/Users/AIP/claude-projects/Dashboard_SeguroAuto/apps/operacion/components/InboxTab.js:120`
  → `setTimeout(() => corte.abort(), 25000)`
- `…/InboxTab.js:158-159` → `setClaiming(null)` y **después** `onRefresh()`

Eso está en `main` desde `01662df` (21 sep 14:40 CDMX), commit `8675a58`. Consecuencia:

> **«Tomando…» *eterno* es imposible en el código que hoy corre en PROD.** El techo es 25 s, y al
> agotarse se pinta `claim_sin_respuesta` — «Sin respuesta en 25 s. Puede que la toma se haya hecho: actualizo la bandeja».

Así que de tus dos candidatas, **la bandeja queda descartada por construcción**: sigue siendo lenta
(~900 kB y 4–5 s en PROD, medido y anotado en `…/apps/operacion/pages/api/alertas/salud-bot.js:3`),
pero ya no bloquea nada. Queda **una sola**: `/api/claim` por dentro, y ahí el único tramo de red es
`callOperatorWebhook`, con tope propio de 15 s
(`…/apps/operacion/lib/s1/n8nOperatorWebhook.js:24`), más un `observeApplied` que es una lectura de
la vista.

### Lo que no he podido medir, y dónde se paró cada intento

1. **Logs de Vercel.** El endpoint de runtime logs
   (`/v1/projects/<prj>/deployments/<dpl>/runtime-logs`) es un **stream en vivo**: 25 s abierto y
   cero eventos. Los `/v2` y `/v3 .../events` solo devuelven log de *build*. No hay ventana histórica
   que alcance al 18–28 sep, así que **los logs no pueden contestar esto retroactivamente**, ni para
   mí ni para nadie. El CLI, además, sigue dando `User not found (404)` con scope de equipo.
2. **BD de PROD.** No tengo DSN. Las variables del proyecto en Vercel son **todas de tipo
   `sensitive`**, y la API no devuelve su valor ni con token válido: `CONCILIACION_DATABASE_URL` y
   `DATABASE_URL` incluidas.
3. **Dashboard de PROD por navegador.** El middleware me manda a `/login`; no introduzco
   credenciales.

### La medición que sí contesta la pregunta — la tienes a un `SELECT`

No hacen falta logs: **la duración del webhook está en la propia tabla que ya miraste**.
`attempted_at` se escribe justo antes de la llamada (`…/pages/api/claim.js:284`) y `updated_at` justo
después de resolverla, en `persistOutcome`. La diferencia **es** `callOperatorWebhook` + la lectura de
la vista:

```sql
SELECT operation,
       count(*)                                                              AS n,
       percentile_cont(0.5) WITHIN GROUP (ORDER BY updated_at - attempted_at) AS p50,
       percentile_cont(0.9) WITHIN GROUP (ORDER BY updated_at - attempted_at) AS p90,
       max(updated_at - attempted_at)                                         AS maximo
FROM public.dashboard_control_commands
WHERE attempted_at IS NOT NULL
GROUP BY 1;
```

Si el `p90` de `take` está en segundos, ahí estaba lo que el operador no aguantaba mirando **antes**
del 21 de septiembre. Si está en milisegundos, el `#417` fue **solo** la bandeja y ya no existe.

---

## 2 · Las diez tomas: tus tres preguntas, contestadas

### a) ¿`lease_expires_at` en NULL es intencionado?

**Sí, y más que intencionado: prohibido.** Lo dice la migración que creó la columna
(`…/migrations/2026-08-11-claims-epoch-anti-aba.sql:166-169`):

> «`active` con lease NULL es no expirante y válido por compatibilidad. […] el contrato prohíbe
> explícitamente crear leases no nulas mientras no exista un reconciliador Dashboard probado. Por eso
> NO lleva DEFAULT.»

Hasta aquí coincidimos con el `#493`. **Lo que añado es el mecanismo que hay detrás de esa
prohibición**, porque descarta el atajo de «pues rellenemos la columna»:

> **Una lease vencida no devuelve el bot: bloquea también al humano.**

Verificado contra la **vista viva** de STG con `pg_get_viewdef`, no contra el fichero de migración:

| Eslabón | Dónde |
|---|---|
| `lease_expires_at <= statement_timestamp()` → `lease_vencida` | viewdef vivo, línea 82 |
| `lease_vencida` → `handoff_reason_code = 'claim_expiration_pending'` | línea 135 |
| ese reason → `handoff_state = 'transitioning'` | línea 144 |
| `canHumanSend` niega todo lo que no sea `stable_human` | `…/lib/s1/conversationControl.js:214` |

Y mientras tanto `whatsapp_sessions.human_takeover` sigue en `true`, que es lo que calla al bot.
Resultado de poner caducidad sin reconciliador: **ni el bot ni el operador pueden escribir**. Un limbo
peor que el silencio de hoy, porque hoy al menos el dueño del claim puede contestar.

Y no hay quien recoja ese estado: **`claim_expiration_pending` no tiene ningún consumidor**. En n8n
aparece solo en la definición de la vista y en su plantilla
(`Agente-n8n:migrations/156/013-…sql` y `scripts/156/view-template.sql`); en Django
(`HYL-WAI@640709e`, clon del 14 ago — dato con esa fecha) solo como miembro de la lista de reasons
«transitioning» en `qualitas/conversation_control.py:42`. Nadie decide nada con él.

### b) ¿Puede liberarse una toma sin que una persona pulse?

**No. Hoy toda conversación tomada es permanente hasta que alguien se acuerde.** Los cuatro
eslabones que lo cierran:

1. El **único** `UPDATE` a `state='released'` exige el mismo `agent_id`, `control_id` **y** `epoch`
   (`…/pages/api/claim.js:186-195`): ni un compañero ni un administrador pueden soltarla desde la UI.
2. **No hay cron ni job** en ningún lado: el repo no tiene `vercel.json` con `crons`, y el único
   workflow de CI es `s1-conformidad.yml`.
3. El estado **`expired` existe en el `CHECK` de la tabla desde el 28 de julio y nadie lo escribe
   jamás**.
4. La columna **nunca se ha escrito en ningún entorno que yo pueda ver**: en STG, `select state,
   count(*), count(lease_expires_at)` da `active 1/0 · released 10/0 · revoked 3/0` — **14 filas, cero
   leases**.

El propio contrato ya previó esto en su vocabulario (`expired`, `lease_expires_at`,
`claim_expiration_pending`, `transitioning`) y **ninguna de las tres piezas de la ejecución existe**:
ni quien escribe la lease, ni quien la cosecha, ni quien devuelve el control al bot.

### c) ¿Las ve alguien? — aquí **corrijo una causa del `#493`**

El `#493` dice, en su causa 3: *«como la bandeja filtra por periodo, una toma vieja puede no tener ni
fila donde mirarse»*. **Eso es falso, y conviene retirarlo antes de que alguien arregle el filtro
equivocado.**

`/api/inbox` **no recibe ninguna fecha**. `fetchInbox` solo pasa `?lead=`
(`…/apps/operacion/pages/index.js:173-182`) y el SQL no tiene ni un predicado temporal
(`…/pages/api/inbox.js:120-143`). El selector de periodo alimenta Resumen y Meta, nunca la bandeja.

Lo que **sí** las esconde son otras dos cosas, y la primera explica justo el caso más incómodo de tu
lista:

1. **`l.poliza_id IS NULL`** — la bandeja corta los leads con póliza emitida **aunque el claim siga
   activo**, y está decidido así por escrito (`…/pages/api/inbox.js:19-21`: «una vez emitida la
   póliza, el objetivo de la bandeja ya se cumplió aunque nadie haya liberado el claim a mano»).
   Cuando se escribió eso no se contemplaba que el claim **calla al bot**.
   **Predicción verificable, no medición mía:** el lead 2208 del `#493` tiene póliza pagada (dato
   tuyo, yo no leo PROD), así que su conversación —en la que el último mensaje es del cliente— **no
   aparece en la bandeja por diseño**, y ensanchar fechas no la traería. Se comprueba con
   `SELECT poliza_id FROM qualitas_lead WHERE id = 2208;`
2. **El `JOIN` es por `lead_id`** (`…/pages/api/inbox.js:95`) y la autoridad del claim es el
   `session_id`: en una recotización el claim puede colgar de otro lead y no pintarse en el que el
   operador mira.

Y lo que el `#493` acierta de lleno: **`claimed_at` viaja en la fila y no se dibuja**. Está en el
`SELECT` (`…/pages/api/inbox.js:57`), llega al cliente, y la insignia solo pinta el nombre
(`…/components/InboxView.js:153`). **Once días se ven exactamente igual que once segundos.** La lista
se ordena por `fecha_creacion` del lead —no por antigüedad de la toma—, el filtro «mías» solo enseña
las tuyas, y **no existe ninguna pantalla que liste las tomas activas**.

---

## 3 · Mi juicio

**Sí merece issue propio, y estoy de acuerdo en que es más grave que el `#417`** — que, de hecho, está
muerto desde el 21 de septiembre. Ya lo tiene: el **`#493`**, así que **no abro duplicado**.

Lo que le falta al `#493`, y propongo añadir como comentario **si lo autorizas** (no he tocado el
tracker):

- **Retirar la causa «filtra por periodo»** y poner en su sitio `poliza_id IS NULL` y el join por
  `lead_id`. Cambia el arreglo: ensanchar fechas no habría salvado ni una de las cuatro urgentes.
- **Añadir el limbo del lease**: por qué el contrato prohíbe la caducidad y no solo la aplaza.
- **Ordenar el arreglo en tres piezas independientes**, de menor a mayor riesgo: (1) pintar la
  antigüedad de la toma y poder ordenar por ella —no toca contrato, no toca a n8n, y es lo único que
  habría evitado esto—; (2) una pantalla o filtro de «tomas activas» que no dependa de que el lead
  siga en los criterios de la bandeja; (3) el reconciliador con lease, que es el único que toca
  contrato y el único que no se puede hacer solo desde el Dashboard.

Mi lectura de la prioridad: **(1) es de horas y cierra el agujero de «nadie se entera»**; (3) sin (1)
es construir el mecanismo caro para un problema que se ve a simple vista en cuanto lo dibujas.

---

## Lo que no he tocado

Nada a `main`. La promoción del `#487` (PR #14, 33 commits) sigue esperando a Alberto, tal como estaba.
No he tocado ningún claim, ni en PROD ni en STG, ni he escrito en el tracker.

— Agente Dashboard
