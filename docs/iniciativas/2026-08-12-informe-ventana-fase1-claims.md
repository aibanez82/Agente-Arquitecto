# Informe de ventana — Fase 1 (parcial): paridad de `dashboard_conversation_claims` en PRODUCCIÓN

**Fecha:** 12 ago 2026 · **Estado: APLICADA Y ACREDITADA**, con dos divergencias declaradas.
**Plan:** `2026-08-12-plan-promocion-stg-a-prod-v2.md` · **Runbook:** `2026-08-12-runbook-fase1-esquema-en-prod.md`

## Quién hizo qué — la regla de los dos criterios

| | |
|---|---|
| **Autoriza** | Alberto |
| **Aplica** | **Alberto**, desde TablePlus, con el runbook |
| **Acredita** | **Arquitecto**, leyendo `pg_catalog` de producción |

**Quien despliega no acredita: respetado.** Se registra aquí porque hasta ahora solo constaba en una
conversación, y desde fuera «se cumplió la regla» y «no se cumplió» eran indistinguibles. Ese defecto
lo levantó el Agente Dashboard, y tenía razón.

## Alcance ejecutado

**Solo la migración de claims.** La de `whatsapp_sessions` **no entró**, y es **una decisión, no un
olvido**: su fichero usa construcciones de cliente `psql` (`:'dry_run'`, `\if/\else/\endif`) que
TablePlus no interpreta. El runbook contemplaba exactamente este caso —las dos tablas son
independientes— y se tomó el camino de aplicar solo claims, que desbloquea la Fase 2 y deja Atención
Humana esperando una segunda ventana.

- Migración: `Dashboard@fix/fase0-claims-paridad-prod:migrations/2026-08-12-fase0-claims-paridad-prod.sql`
- Backup previo: `heroku pg:backups:capture` → **`b006`**
- Resultado: sin error, ninguna guarda disparada.

## Acreditación

**Primera pasada — contra la especificación:** 12 columnas con tipo, nulabilidad y los tres defaults
exactos · 5 índices · `ck_claims_state` presente y **nada de #156 colado** · 16 filas, ni una creada ni
borrada. **0 fallos.**

**Segunda pasada — contra el criterio real del plan** (catálogo de PROD == catálogo de STG). Esta la
provocó el desafío del Agente Dashboard, y **es la que encontró algo**:

| Objeto | Resultado |
|---|---|
| Constraints | **IGUAL** |
| Columnas | **DIFIERE en una**: `session_id` es `NOT NULL` en STG y **nullable** en PROD |
| Índices | **DIFIERE en uno**: `dashboard_claims_active_idx` existe solo en PROD |

**Efectos de los backfills, medidos:**

| | |
|---|---|
| `state` | **8 filas** a `released`. Filas `active` con `released_at`: **0** |
| `epoch` | **1 fila** (de 1 a 2). Distribución final: `{1: 15, 2: 1}`. Filas con `epoch ≤ 0`: **0** |
| `(session_id, epoch)` repetidos | **0** — la mina de #156 queda desactivada |

## Las dos divergencias, y qué se hace con cada una

**1 · `session_id` sin `NOT NULL` — gap real, no previsto.** El handoff pedía «añadir las seis columnas
que faltan», y `session_id` ya existía, así que nadie miró su nulabilidad. Hoy no rompe nada —hay **0**
filas con `session_id` nulo y `claim.js` lo resuelve siempre en servidor— pero **la paridad no está
completa**. `uq_claims_active_session` es un único parcial sobre esa columna: con nulos permitidos, una
fila con `session_id` nulo escaparía a la restricción.
→ **Acción:** `ALTER COLUMN session_id SET NOT NULL`, con guarda de cero nulos, **en la segunda
ventana**. No se hace ad hoc.

**2 · `dashboard_claims_active_idx` solo en PROD — deliberado, y ahora redundante.** Se ordenó
expresamente no tocarlo («esta migración no borra nada»). Con `state` ya poblado,
`released_at IS NULL` y `state = 'active'` son el mismo conjunto, así que duplica a
`uq_claims_active_lead`.
→ **Acción:** retirarlo en la **Fase 5 (higiene)**, junto al índice duplicado de
`whatsapp_sessions.quotation_id`. No urge y no molesta.

## Servicio verificado — **ventana CERRADA**

- **El Dashboard lee en producción:** bandeja de **Chats** cargando, verificado por Alberto. Se pidió
  expresamente ese segundo clic porque la primera comprobación fue sobre *Resumen*, que **no toca** la
  tabla migrada — matiz del Agente Dashboard, y es el que convierte la comprobación en prueba.
- **El bot responde:** verificado por Alberto.
- **Lecturas acreditadas por el Arquitecto** contra producción: el `JOIN` exacto del `inbox.js`
  desplegado devuelve 1 312 leads · 8 con claim · 8 con agente, y la consulta del `409` también corre.

**Firmado como segundo criterio por el Agente Dashboard** (`informes/2026-08-12-dashboard-cierre-jornada.md`).

## Corrección: el DDL fue aditivo en columnas pero **restrictivo en escrituras**

Dije que producción no cambiaba de comportamiento «porque nadie lee esas columnas». Las **lecturas** no
cambian — verificado. Las **escrituras sí**, y no por las columnas sino por un índice nuevo:

`uq_claims_active_session` es único sobre `session_id` donde `state='active'`. En producción
**`session_id` es el teléfono**, así que dos leads del mismo teléfono ya no pueden estar tomados a la
vez. Y eso ocurre: hay **12 pares de leads con el mismo teléfono** en 30 días (`qualitas-issues#20`).

**Degrada bien y es deseable:** el `claim.js` desplegado captura el `23505` y devuelve **409**, no un
500 — leído en el código. El único defecto es cosmético: busca al dueño por `lead_id` y, como el claim
vive en *el otro* lead, dice «Ya tomada por otro agente» sin nombrarlo. Y lo que impide es exactamente
lo que un claim existe para impedir: dos agentes escribiendo en la misma conversación de WhatsApp.
Hoy hay **0 sesiones con más de un claim activo**.

## La lección, que es de método y es mía

Acredité contra **una lista que yo mismo escribí** a partir de la medición previa, no contra la fuente
que el criterio nombra. Salió «0 fallos» y era verdad —todo lo que comprobé estaba bien— pero **la
comprobación era más estrecha que el criterio**. Las dos divergencias estaban ahí desde el primer
minuto y no las vi.

Que las encontrara el segundo par de ojos es exactamente para lo que existe el segundo par de ojos. La
regla no es una formalidad: **es lo que convierte «no encontré fallos» en «no hay fallos».**

---

# Anexo — Fase 2: Dashboard promovido a producción (12 ago)

**Aplica:** Arquitecto (merge `stg` → `main`, `0d2ee73` → `fb808bc`) · **Verifica:** Alberto (prueba
observable en la UI) · **Acredita:** Arquitecto (estado en base). Autorizado por Alberto.

**Precondiciones, verificadas en el momento y no de memoria:** impacto del endurecimiento del visor
**remedido justo antes → 0 de 1084 sesiones afectadas** · punto de retorno anotado · merge sin
conflictos · Fase 1 aplicada.

**Despliegue:** Vercel `Ready` en 32 s.

**Acreditación — la prueba que nunca se había ejecutado:** primer clic de «Tomar conversación» → crea
claim; segundo clic → rechazado; liberar → funciona.

| Evidencia | |
|---|---|
| Fila creada | `id=17 · lead=2040 · quotation_id=3492 · epoch=1 · control_id presente` |
| **Por qué prueba que corre el código nuevo** | el `claim.js` anterior insertaba **solo** `lead_id, session_id, agent_id`. Que la fila traiga `quotation_id` es imposible con el código viejo. Las filas 15 y 16, anteriores, lo tienen a `NULL` |
| Liberar | la fila acabó en `state='released'` — el camino nuevo exige `control_id` **y** `epoch` **y** ser su dueño |
| Invariantes | 0 sesiones con >1 claim activo · 0 pares `(session_id, epoch)` repetidos |

> El «Ready» de Vercel dice que **se desplegó**. La fila con `quotation_id` dice que **se ejecutó**. Solo
> la segunda es acreditación.

**Arregla dos fallos que estaban vivos en producción:** «Tomar conversación» (roto desde el 28 jul,
fallaba siempre y para todos, y nadie lo detectó porque no se había vuelto a pulsar) y el `parseInt`
sobre `lead_id`/`cotizacion_id`, que redondea por encima de 2^53 y podía seleccionar el lead vecino —
el del FAIL P1 del 4 de agosto.

**Rollback disponible y no usado:** promover el deployment anterior en Vercel.

---

# Anexo — Fase 4, promoción 1: Retomar Conversación en producción (13 ago)

**Autoriza:** Alberto · **Ejecuta:** Agente n8n (`promover-retomar.py --go --confirm-ventana`) ·
**Acredita:** Arquitecto (API de n8n, retrato propio del antes) · **Cierra:** Alberto (envío real).

**Alcance real:** un solo parámetro de un solo nodo — `Normalize & Validate.jsCode`, **1 338 → 10 169**
caracteres. El plan del 10 ago describía además un cambio `WA Config STG` → `WA Config` que **no
existía**: producción ya tiene su propio nodo. Menos cambio del previsto, medido y no supuesto.

**Acreditación — 0 fallos**, contra un retrato del antes que tomé por separado:

| | | |
|---|---|---|
| ① | `webhookId` de `Webhook` y de `Send message` | **intactos** — Bug #12 evitado |
| ② | 12 nodos, `active = true` | sin pérdidas ni añadidos |
| ③ | `jsCode` 1 338 → 10 169 | el cambio entró |
| ④ | referencias `$('...')` en el código vivo | **0** — portable |

`versionId`: `a83ec90c…` → `fa42a9b4…`.

**Cierre por comportamiento:** mensaje proactivo real desde el Dashboard de producción, **recibido en el
teléfono**. Registrado en `n8n_chat_histories` (`id=10673`, 03:05:02) y en `dashboard_message_audit`
(`id=19`, `claim=18`, `webhook_ok=true`). Atravesó el nodo cambiado de punta a punta.

**Acreditado de propina:** `dashboard_message_audit.claim_id` **se escribe en producción**. Era la
columna que el Agente Dashboard levantó como posible pérdida silenciosa de rastro; queda probada con un
envío real.

## El falso positivo, que es la lección de esta ventana

La guarda anti-Bug#15 del guion era `'WA Config STG' in json.dumps(workflow)` y **abortó**: el `jsCode`
que se promovía menciona esa cadena en **dos líneas de comentario**, y copiarlo byte a byte era una
decisión tomada y escrita.

En palabras del ejecutor: *«el guion abortaba por cumplir su propio plan, y además gritaba REVERTIR ya
sobre una promoción correcta — la peor clase de falso positivo: el que empuja a deshacer algo que
estaba bien.»*

Corregido en el sitio correcto: la guarda ahora busca **un nodo** llamado `WA Config STG` o **una
referencia `$('WA Config STG')`**, que es lo único que ejecutaría. Un comentario no ejecuta nada. Se
aplicó también al guion de Atención Humana, que tenía el mismo defecto y aún no se había usado.

> **Y el patrón del día, completo:** una comprobación **más ancha** que el criterio grita en falso; una
> **más estrecha** deja pasar. Hoy nos han pasado las dos — su guarda y mi primera acreditación — y las
> dos se pagan.
