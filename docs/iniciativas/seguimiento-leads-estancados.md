# Iniciativa — Seguimiento automático de leads estancados (15-16 jul 2026)

> Estado: ✅ **Desplegado a `hyl-wai-production` (18-19 jul 2026), arranque seguro.** Código
> (interpolación + check de `status`) mergeado y desplegado (release 319, `a49a7838`), migración
> `0041` corrida (2 tablas nuevas confirmadas), fixture de 21 filas cargado (verificado por
> conteo, `pg_stat_user_tables`), flags en arranque seguro (`ENABLED=false`, `DRY_RUN_DEFAULT=true`,
> release 320), y el job de envío creado en **Advanced Scheduler** (no el Scheduler estándar —
> decisión explícita: con `delay_mins` cortos como 5/5/10, el piso de 10 min del Scheduler
> estándar habría añadido hasta ~10 min de imprecisión extra sobre cada intento). Webhook de PROD
> ya con autenticación completa (Dashboard + n8n, E2E real confirmado — ver sección abajo).
> **19 jul, madrugada: casi se activó envío real a las 11pm — ver sección "Casi-incidente" abajo.**
> Estado seguro actual: `ENABLED=true`, `DRY_RUN_DEFAULT=true` (confirmado en vivo). Falta antes
> de activar envío real de verdad: (1) filtro de horario 9am-8pm CDMX (decidido, sin construir
> todavía — Alberto lo dejó como pendiente explícito), (2) configurar
> `N8N_PROACTIVE_WA_MESSAGE_URL`/`N8N_PROACTIVE_WA_MESSAGE_TOKEN` en PROD (no existen — ver
> abajo), ambos antes de volver a tocar `DRY_RUN_DEFAULT`.
> Guardado en git (no en memoria local) para persistir entre las 3 laptops de Alberto.
> Handoff consolidado usado para el despliegue: `docs/2026-07-18-handoff-juan-checkpoint-followups-produccion.md`.
> Ejecutor original en STG: Agente n8n. Reporte fuente: `Agente-n8n:docs/2026-07-16-resumen-arquitecto-seguimiento-leads-estancados.md`.

## ✅ Cerrado (19 jul, madrugada) — auth del webhook PROD

El webhook `proactive-wa-message` (workflow `Retomar Conversacion`, PROD) ya tiene autenticación
completa, desplegada en 2 fases sin romper nada del lado real:

1. **Dashboard**: `pages/api/n8n-proactive-message.js` ya manda `Authorization: Bearer <token>`
   (commit `800feb7`), env vars `N8N_PROACTIVE_WEBHOOK_TOKEN`/`N8N_PROACTIVE_WEBHOOK_TOKEN_STG`
   cargadas en Vercel — verificado en vivo por el Arquitecto (código en `main`, env vars
   confirmadas).
2. **n8n**: nodo `Webhook` de PROD con `authentication: headerAuth` + credencial `Retomar
   Conversacion Header Auth PROD` — verificado en vivo (403 sin header, 403 con header
   incorrecto, ambos probados directo por el Arquitecto).
3. **E2E real confirmado**: Alberto usó "Tomar conversación" en el Dashboard PROD sobre un lead
   real (teléfono 524461134053, mensaje "Hola, imaginamos que nos cotizaste por error.") —
   ejecución **3128** en n8n, trace completo verificado (`Webhook` → `Execute a SQL query` →
   `Send message`), WhatsApp real entregado (`wamid` real). Una ejecución posterior (3130) fue la
   prueba deliberada de payload vacío de Agente n8n, error esperado, no un problema.

**Por qué el orden importó:** este mismo webhook lo usa el botón "Tomar conversación" del
autenticación antes de que el Dashboard mande el header, se rompe esa función en producción real
para agentes reales.

## Origen

Alberto viene rescatando manualmente conversaciones de WhatsApp que se quedan a medias (cliente recibe la cotización o llega a un punto del flujo y deja de contestar), mandando un mensaje de seguimiento horas después con buenos resultados. Arrancó el 15 jul a partir de una pregunta operativa sobre el lead #1353 y terminó en un acuerdo de implementación con Juan.

## Diseño

**7 checkpoints** (puntos de espera del bot) derivados de `conversation_phase`/`captured_data`, con política de hasta 3 reintentos por checkpoint.

**Principio de diseño clave:** no se agrega ningún campo de estado nuevo en `qualitas_lead` ni en `whatsapp_sessions`. Ya existen tres fuentes distintas compitiendo por decir "en qué estado está un lead" (`Lead.estado`, `conversation_phase`, `LeadActionEvent`) y confirmaron que dos ya están desincronizadas en producción (un lead con `captured_data` completo seguía en `estado='COTIZACION_INICIADA'`). Los checkpoints se derivan en vivo; los reintentos se cuentan contando eventos en `LeadActionEvent`, no con un contador nuevo.

## Tabla de reglas de reintentos (`qualitas_leadfollowuppolicy`) — versión final para PROD

> ✅ Consolidado 18 jul: copy final (rediseño de Agente Mejoras Conversación del 17 jul + quitar
> "Soy Uriel, de Quálitas" de `quote_sent/1` por redundante con la plantilla de Meta) + `delay_mins`
> reales de producción, decididos por Alberto. Reemplaza la tabla vieja de este doc (que traía el
> copy genérico "Hola, soy de SeguroAuto" y `delay_mins=1`, el fixture de pruebas rápidas de STG).

**`delay_mins` real de PROD — mismo patrón en los 6 checkpoints activos:** intento 1 = 5 min desde
el último mensaje del bot, intento 2 = 5 min desde el mensaje del intento 1 (~10 min desde el
mensaje original), intento 3 = 10 min desde el mensaje del intento 2 (~20 min desde el original).
`delay_mins` se mide desde el último mensaje del bot, no es acumulado en la BD — la cadena sale
sola con estos 3 valores. `payment_link_sent` sigue desactivado — **confirmado explícitamente por
Alberto (18 jul)**: el riesgo de decirle a un cliente que falta pagar cuando ya pagó (estatus de
pago poco confiable, sin webhook de Quálitas, mismo motivo por el que existe Agente Conciliación)
es peor que un recordatorio de dato faltante. Queda apagado hasta que Agente Conciliación tenga
estatus de pago confiable — no hay fecha objetivo todavía.

| Checkpoint | Intento | `delay_mins` | Activo | Mensaje |
|---|---|---|---|---|
| `quote_sent` | 1 | 5 | ✅ | "¡Hola! 😊 Tu cotización para tu **[MARCA MODELO AÑO]** por **$[PRECIO] MXN** sigue guardada — ¿seguimos con el trámite?" ⚠️ placeholder, ver interpolación |
| `quote_sent` | 2 | 5 | ✅ | "¿Seguimos con tu cotización? Nada más faltan un par de datos y queda lista tu póliza." |
| `quote_sent` | 3 | 10 | ✅ | "Por ahora no te escribo más — tu cotización queda guardada, así que si quieres retomarla más adelante, contéstame por aquí cuando gustes." |
| `personal_data_captured` | 1 | 5 | ✅ | "¡Seguimos por aquí! Ya tengo tus datos — solo me falta el VIN o las placas para avanzar con tu seguro." |
| `personal_data_captured` | 2 | 5 | ✅ | "¿Me compartes el VIN o las placas cuando puedas? Es lo único que falta para seguir." |
| `personal_data_captured` | 3 | 10 | ✅ | "Por ahora no insisto más — en cuanto me compartas el VIN o las placas, seguimos. Aquí quedo." |
| `vin_plates_captured` | 1 | 5 | ✅ | "Ya con eso, solo me falta tu dirección para continuar con la emisión." |
| `vin_plates_captured` | 2 | 5 | ✅ | "¿Me compartes tu dirección para seguir avanzando?" |
| `vin_plates_captured` | 3 | 10 | ✅ | "Por ahora no insisto más — con tu dirección seguimos cuando quieras. Aquí quedo." |
| `address_captured` | 1 | 5 | ✅ | "Ya casi terminamos — ¿necesitas factura para esta póliza?" |
| `address_captured` | 2 | 5 | ✅ | "Solo me falta saber si requieres factura, ¿sí o no?" |
| `address_captured` | 3 | 10 | ✅ | "Por ahora no insisto más — nada más dime si requieres factura y seguimos. Aquí quedo." |
| `rfc_digits_pending` | 1 | 5 | ✅ | "Para tu factura necesito tu RFC completo con homoclave." |
| `rfc_digits_pending` | 2 | 5 | ✅ | "¿Me compartes tu RFC completo para terminar tu factura?" |
| `rfc_digits_pending` | 3 | 10 | ✅ | "Por ahora no insisto más — en cuanto tenga tu RFC, genero tu factura. Aquí quedo." |
| `summary_pending` | 1 | 5 | ✅ | "Tu resumen ya está listo: **[MARCA MODELO AÑO]**, **$[PRECIO] MXN**. ¿Seguimos con la emisión de tu póliza?" ⚠️ placeholder, ver interpolación |
| `summary_pending` | 2 | 5 | ✅ | "Tu precio preferencial por contratar en digital solo está disponible hoy — ¿confirmamos y avanzamos con tu póliza?" |
| `summary_pending` | 3 | 10 | ✅ | "Por ahora no insisto más — tu cotización sigue lista si decides retomarla. Aquí quedo." |
| `payment_link_sent` | 1-3 | — | ⛔ | desactivado, validación de pagos pendiente |

`rfc_digits_pending` solo aplica si el cliente pidió factura en `address_captured`; si dijo que no, ese checkpoint se salta y va directo a `summary_pending`.

**Nota:** esta tabla es la referencia canónica para el fixture real de PROD que Juan tiene que
cargar — reemplaza al fixture de pruebas de STG (`delay_mins=1`, copy viejo). Las 2 filas con
placeholders siguen bloqueadas por la interpolación de variables (checklist de Juan).

## Coordinación con Juan — arquitectura de funnel

Juan trae en paralelo una propuesta más grande (`Lead.estado` como verdad comercial canónica, separada de canal/conversación/pago, con migración de datos). Es la base correcta de fondo, pero es una migración de producción de riesgo medio-alto. Se acordó **no esperarla**: Juan adoptó el diseño de checkpoints como "parche temporal" a implementar primero, dejando su arquitectura grande para después. Explícitamente fuera de alcance del parche: tocar `Lead.estado`, los choices, o declarar pagos desde n8n.

## Verificación contra PROD (solo lectura, 16 jul)

Antes de que Juan empezara a implementar, se verificaron 4 supuestos de su plan contra la base de producción real y se corrigieron:

- `n8n_chat_histories.session_id` siempre es el teléfono, nunca `conversation_id` (0 de 1,784 filas con formato conversation_id) — su plan asumía una "conversación v2" que no existe.
- Los valores reales de `conversation_phase` no incluyen `closed`/`archived`/`expired` como asumía su documento — solo `greeting/data_capture/summary_confirmation/policy_issuance/payment_pending/completed`.
- La ventana de 24h de WhatsApp limita los reintentos por texto libre — no contemplada en su plan original.
- El payload de ejemplo de su plan incluía `conversation_id` junto con `phone_number`, lo cual rompería la inserción en `n8n_chat_histories` por prioridad de campos en el nodo existente.

También se encontró (no reportado por Juan) que `lead_id` no siempre viene poblado en `whatsapp_sessions` (~12% históricamente), resoluble vía `quotation_id`.

## Trabajo ya aplicado del lado de n8n (STG)

- Autenticación `headerAuth` agregada al webhook `proactive-wa-message` (workflow `Retomar Conversación`) en STG — antes no tenía ninguna. Verificado 403 sin token / 200 con token, `webhookId` sin cambios, workflow sigue activo.
- Confirmado que `Retomar Conversación` (59 ejecuciones reales en PROD desde el 2 de julio, 100% éxito) ya cumple el contrato que necesita el parche sin cambio adicional.
- Fixture de política armado con `delay_mins=1` (valor rápido deliberado, solo pruebas STG) para los 6 checkpoints activos; `payment_link_sent` queda apagado a propósito.

## Riesgos / cosas a vigilar (añadidos por el Arquitecto, 16 jul)

- **✅ Solapamiento con el scheduler de follow-up viejo — descartado (16 jul, aclarado por Alberto y verificado en código).** Ese mecanismo (`qualitas/whatsapp_followups.py`, `quote_followup_15m`) no es de "15 minutos" — el nombre quedó de una versión anterior; el delay real en STG es `WHATSAPP_QUOTE_FIRST_FOLLOWUP_DELAY_MINUTES=4`. Más importante: `evaluate_n8n_activity_for_followup` solo lo dispara cuando `conversation_phase == 'greeting'` **y no hay ningún mensaje humano todavía** (`n8n_human_message_detected` lo bloquea si el cliente respondió algo, aunque sea una palabra) — es exclusivamente el recordatorio de "no contestó nada a la plantilla inicial". El nuevo `checkpoint_followups` exige lo contrario: que exista al menos un mensaje humano reciente y que la fase ya haya avanzado más allá de `greeting`. Las dos poblaciones son mutuamente excluyentes por diseño — un lead no puede calificar para ambos sistemas al mismo tiempo. **Bug #13 sigue siendo un problema real pero independiente** (afecta solo al scheduler viejo, no al nuevo).
- **Contrato del webhook compartido.** `Retomar Conversación` es el mismo workflow que usa el botón "Tomar conversación" del Dashboard, y exige que `phone_number`/`session_id` empiecen con `52` (`docs/protocolos/workflow-proactivo-dashboard.md`) — la misma regla frágil que causó el bug del fallback `'52'+telefono` en `LeadModal.js` durante la iniciativa de `conversation_id` (ver `docs/iniciativas/conversation-id-whatsapp-n8n.md`). Si el nuevo servicio de Django construye `session_id` de otra forma (o en algún caso usa `conversation_id`), rompe. **Acción:** que el handoff a Juan lo deje explícito antes de que implemente el servicio de envío.

## Verificación de la implementación de Django en STG (16 jul, Arquitecto)

Juan implementó el parche (commit `789443b`, migración `0041_lead_checkpoint_followups`) y entregó
un reporte detallado del contrato (`reporte-alberto-n8n-checkpoint-followups-whatsapp.md`).
Verificado contra el código real de `stg` y datos reales de Postgres/n8n STG — no solo leído:

**Coincide con el contrato, confirmado en código y BD real:** modelos, migración, los 7 checkpoints,
ventana 24h, tope de 3 intentos, exclusión por póliza emitida, idempotencia (`LeadCheckpointFollowupAttempt`
+ `LeadActionEvent`), fixture cargado (21 filas, 6 checkpoints activos `delay_mins=1`,
`payment_link_sent` apagado), flags seguros por default (`ENABLED=false`, dry-run `true`).

**🔴 Gap real encontrado — no es un bug de Django, es de n8n:** Juan documentó explícitamente que
n8n debe escribir el historial con `n8n_chat_histories.session_id = body.session_id`, tratando
`conversation_id` solo como metadata (secciones 3.3 y 9.1 de su reporte, y lo repite como ítem de
checklist en su sección 15). **El nodo real de `Retomar Conversacion_stg` (verificado vía API de
n8n) NO hace eso** — resuelve la clave de inserción con
`conversation_id || session_id || phone_number`, exactamente lo contrario. Confirmado que no es
hipotético: **3 sesiones reales en STG hoy** (cotizaciones 1711, 1712, 1704) tienen `session_id`
(teléfono) y `conversation_id` (`waq_...`) distintos y ambos poblados — si cualquiera llega a un
checkpoint elegible con el envío real activado, el mensaje se insertaría bajo la clave equivocada y
el bot (que lee por teléfono) nunca lo vería. Causa: el nodo quedó con la lógica de prioridad de la
iniciativa de `conversation_id` (pensada para desambiguar múltiples cotizaciones del mismo teléfono
en el flujo principal), y nadie la reconcilió con este contrato nuevo, que asume lo contrario.
Detalle completo y plan de acción: `docs/2026-07-16-respuesta-juan-verificacion-checkpoint-followups.md`.

**Aparte, confirmado que sí existe una plantilla de Meta aprobada** (`cotizacion_followup_15m`, del
scheduler viejo) — no sirve para esta iniciativa (que solo manda texto libre en ventana 24h, por
diseño explícito de Juan), pero confirma que el camino de aprobación con Meta ya es viable para la
iniciativa paralela de "recordatorios por fecha mencionada".

## ✅ Gap de n8n cerrado (16 jul, verificado en vivo por el Arquitecto)

Juan mandó un plan más completo y estricto que el fix mínimo inicial
(`docs/2026-07-16-plan-juan-n8n-stg-proactive-wa-message-session-id.md` en `Agente-n8n`): `session_id`
sin ningún fallback (ni a `conversation_id` ni a `phone_number` — si falta, el webhook debe fallar),
validación completa de payload, e idempotencia real del lado de n8n. Agente n8n lo implementó
(`Retomar Conversacion_stg`, commit `eb656c5`) y en el camino encontró que esa validación estricta
rompía el botón "Tomar conversación" del Dashboard (payload mínimo sin `timestamp`/`checkpoint`/etc.)
— lo reportó como riesgo bloqueante en vez de parchearlo por su cuenta. El Arquitecto verificó
contra el código real del Dashboard (`pages/api/n8n-proactive-message.js`: solo manda 3 campos, y ni
siquiera lee la respuesta JSON de n8n, solo el status HTTP) y decidió la opción más limpia: **un solo
webhook, con validación dual** — estricta solo si el payload trae `checkpoint`+`idempotency_key`
(caso Django), laxa si no (caso Dashboard). Cero cambios necesarios en Django o en el Dashboard.

Implementado (commit `ef5e0af`, nodo nuevo `IF Is Checkpoint Followup?`) y **verificado en vivo por
el Arquitecto contra la API real de n8n** (12 nodos, condición del IF, conexiones del grafo — no
solo el reporte del ejecutor): coincide exactamente. 5 pruebas (A-E) corridas por Agente n8n contra
el webhook real de STG con verificación directa en Postgres, incluida una Prueba E que replica el
payload exacto del Dashboard. De paso, el ejecutor encontró y documentó un gotcha nuevo de n8n: un
valor vacío (`""`) en una línea de `queryReplacement` de un nodo Postgres hace que n8n pierda esa
posición de parámetro por completo (mismo patrón que el gotcha ya conocido de `$fromAI` con cadena
vacía) — fix fue no dejar `timestamp` vacío nunca, usar `new Date().toISOString()` como respaldo.

Con esto, el lado de n8n queda completo. Detalle completo:
`Agente-n8n:docs/2026-07-16-respuesta-plan-juan-session-id.md` y
`Agente-n8n:docs/2026-07-16-respuesta-validacion-dual-proactive-wa-message.md`.

## Documentos (en `Agente-n8n`)

- `docs/2026-07-15-handoff-para-juan-seguimiento-automatico-leads-estancados.md` — diseño original.
- `docs/2026-07-15-plan-seguimiento-leads-analisis-vs-propuesta-juan.md` — análisis y plan en 3 fases.
- `docs/2026-07-16-respuesta-a-juan-verificacion-parche-seguimiento.md` — las 4 correcciones verificadas.
- `docs/2026-07-16-handoff-para-ia-juan-integracion-webhook-retomar-conversacion.md` — contrato de integración (endpoint, auth, payload).
- `docs/2026-07-16-fixture-qualitas-leadfollowuppolicy-borrador.json` — valores de prueba.
- `docs/2026-07-16-handoff-para-juan-seguimiento-leads-consolidado.md` — versión consolidada, referencia práctica vigente.
- `docs/2026-07-16-resumen-arquitecto-seguimiento-leads-estancados.md` — el resumen que originó este doc.
- `reporte-alberto-n8n-checkpoint-followups-whatsapp.md` (Juan, entregado 16 jul) — contrato de datos detallado de lo implementado, verificado por el Arquitecto (ver sección arriba).
- `Agente-Arquitecto:docs/2026-07-16-respuesta-juan-verificacion-checkpoint-followups.md` — la verificación y el gap encontrado.

## Reporte de Juan (17 jul, tarde) — retomó tras el fix del 403

- Promovió a `hyl-wai-stg` los cambios de `checkpoint_followups`/`proactive-wa-message`: flags de envío real activos, comando principal corre.
- Agregó un **comando nuevo de reintento auditable** — reintenta intentos fallidos específicos sin tocar la BD a mano (no estaba en el contrato original, es una herramienta operativa que se agregó sobre la marcha).
- Validó que la cotización 1717 (la del 403 original) queda **detectable como retryable** por el comando nuevo.
- Corrió dry-run de `checkpoint_followups`: hay candidatos elegibles.
- **Todavía no reporta un envío real confirmado** — lo de arriba es detección/dry-run, no el WhatsApp de verdad saliendo. Ver pendiente abajo.

**✅ Resuelto (17 jul, confirmado por Alberto):** el intervalo de 3 minutos era un artefacto de querer iterar rápido en STG (mismo patrón que el fixture `delay_mins=1`, explícitamente "solo pruebas") — **no es un requisito real de producción**. No hace falta ningún addon nuevo ni dyno adicional: el Heroku Scheduler estándar (10 min/hourly/daily) alcanza para producción. Para seguir iterando rápido en STG mientras se prueba, usar `heroku run` manual (como ya se hizo para el fix del 403) en vez de montar un scheduler de alta frecuencia solo para pruebas — se descartan Cron To Go, Advanced Scheduler y el proceso `clock` para esta iniciativa.

## 🔴 Scheduler de Heroku en STG: nunca existió ningún job (17 jul, noche — Arquitecto)

Alberto probó en vivo por WhatsApp (STG, 525551074144) esperando que el recordatorio automático saltara ~10 min después de dejar de responder. No saltó. Diagnóstico:

- **Flags confirmados activos vía Heroku config-vars API** (`hyl-wai-stg`): `WHATSAPP_CHECKPOINT_FOLLOWUPS_ENABLED=true` (release 175, 17 jul 04:09:46 UTC) y `WHATSAPP_CHECKPOINT_FOLLOWUPS_DRY_RUN_DEFAULT=false` (release 176, 17 jul 12:26:00 UTC) — no es un problema de flags ni de dry-run.
- El Heroku Scheduler **estándar** (a diferencia de Advanced Scheduler) no expone sus jobs por la Platform API — solo por el dashboard web. Verificado ahí directamente (Alberto autenticado en Heroku): **`dashboard.heroku.com/apps/hyl-wai-stg/scheduler` muestra "When you create a new job in this app it will appear here" — no hay ningún job creado.**
- El add-on Scheduler (`scheduler-graceful-93653`) tiene `created_at: 2026-07-17T16:41:59Z` — se (re)provisionó el mismo día, ~2h53min antes de la prueba de Alberto. Los jobs viven dentro del propio add-on (no en config vars ni en release history), así que si existió un job antes, se perdió al recrear el add-on; más probable: nunca se creó ninguno.
- Los envíos reales que sí se ven en `qualitas_leadcheckpointfollowupattempt` (16:37 UTC, 19:08 UTC — ver sección "Reporte de Juan" arriba) vinieron de `heroku run` manual, no de un cron corriendo en background.

**Causa raíz: no es un bug de n8n, BD ni de timing — nadie había creado el job `enviar_seguimientos_whatsapp --message-key checkpoint_followups` en el Scheduler de STG.**

**✅ Resuelto (17 jul, noche):** Juan creó el job directo en el dashboard. Verificado por el Arquitecto en la misma pantalla:

```
$ python manage.py enviar_seguimientos_whatsapp --message-key checkpoint_followups --limit 20
Basic · Every 10 minutes · Last Run: Never · Next Due: July 17, 2026 8:19 PM UTC
```

**✅ Confirmado (17 jul, 20:11 UTC) — primera prueba 100% automática de punta a punta, verificada en vivo por el Arquitecto:**

- Dashboard Scheduler: `Last Run: July 17, 2026 8:10 PM UTC` (ya no "Never").
- `qualitas_leadcheckpointfollowupattempt` id=4: cotización **1751**, checkpoint `vin_plates_captured`, intento 1, `status=sent`, `idempotency_key=checkpoint_followup:1751:vin_plates_captured:1`, `created_at=2026-07-17T20:11:06Z`.
- `n8n_chat_histories` id=1872, `session_id=525551074144`, tipo `ai`: *"Perfecto. Ahora necesito tu dirección para continuar."* — coincide exacto con la plantilla de intento 1 de `vin_plates_captured`.

Sin ningún `heroku run` manual de por medio — Scheduler → Django → n8n → BD funcionando solo.

**✅ Cerrado del todo (17 jul, minutos después) — entrega real confirmada, no solo `status=sent`:** Alberto recibió el mensaje por WhatsApp y respondió `"ok!"`. Verificado en `n8n_chat_histories`: id=1873 (`human`, contexto `qid=1751 | phase=data_capture`) → id=1874 (`ai`, *"Listo, Juan. Necesito tu dirección..."*) — el bot retomó la conversación con normalidad, mismo patrón que la validación previa de la cotización 1750. Con esto, el bloqueante del Scheduler en STG queda cerrado por completo: job creado, corrida automática sin intervención manual, y entrega + continuación real confirmadas.

## Copy rediseñado (Agente Mejoras Conversación, 17 jul) — ya cargado en STG, ya reflejado en la tabla de arriba

Los 18 mensajes activos de `qualitas_leadfollowuppolicy` en STG fueron reemplazados el 17 jul
(`Agente-n8n:docs/2026-07-17-cargados-18-textos-checkpoint-followups-stg.md`) por la propuesta de
Agente Mejoras Conversación: corrige la marca a "Uriel, de Quálitas" (luego quitada de
`quote_sent/1` el 18 jul, ver decisión #4 abajo — redundante con la plantilla de Meta), usa
vehículo/precio como gancho en apertura y cierre, y cambia el tono del intento 3 de "último
recordatorio" a un cierre sin presión. La tabla de "versión final para PROD" más arriba ya
incorpora este copy — texto completo comparado (actual vs. propuesto), como referencia histórica
del diseño: artefacto `propuesta-reintentos` de Alberto.

**3 decisiones abiertas del diseño, resueltas/pendientes (18 jul, con Alberto):**
1. **Interpolación de variables** — `quote_sent/1` y `summary_pending/1` tienen los placeholders
   `[MARCA MODELO AÑO]`/`$[PRECIO] MXN` literales, sin resolver — salen tal cual en WhatsApp hoy.
   Requiere que Juan modifique `render_policy_message` en `whatsapp_checkpoint_followups.py` para
   exponer esos datos (reusar `resolver_opcion_cotizacion_whatsapp`/`obtener_precio_anual_real`
   como en `whatsapp_followups.py`). **Pendiente: Alberto lo cierra directo con Juan.** No debe
   promoverse a PROD con los corchetes literales.
2. **✅ Resuelto — "precio preferencial... solo está disponible hoy" (`summary_pending/2`).**
   Decisión de Alberto: es copy de marketing intencional, no una afirmación fáctica de negocio
   (no requiere verificar que la tarifa cambie literalmente día a día). Se mantiene tal cual.
3. **❌ Decidido — NO se activa la salida explícita en intento 3.** Alberto (18 jul): le parece
   muy dura/tajante ("contéstame 'no, gracias' y no te vuelvo a escribir"). El mecanismo de
   detección de declinación (gap de abajo) sigue construyéndose igual — cubre la declinación
   orgánica del lead en cualquier momento, solo que el intento 3 no invita explícitamente a usarla.
4. **✅ Aplicado y verificado en STG (18 jul) — quitar "Soy Uriel, de Quálitas." de `quote_sent/1`.**
   Ese saludo ya va en la plantilla de Meta del primer contacto; repetirlo en el primer recordatorio
   es redundante. `UPDATE` corrido directo por el Arquitecto contra Postgres STG (acceso de
   escritura ya establecido ahí), confirmado `rowCount=1` y texto releído: "¡Hola! 😊 Tu cotización
   para tu *[MARCA MODELO AÑO]* por *$[PRECIO] MXN* sigue guardada — ¿seguimos con el trámite?".
   Las 18 filas de STG ahora coinciden 100% con la versión final de la tabla de arriba. Sigue
   bloqueado el placeholder real hasta la interpolación de variables del punto 1.

## 🔴 Gap confirmado (18 jul) — el sistema no detecta que un lead declinó, y mecanismo unificado de fix

Verificado contra el código real: `evaluate_checkpoint_followup_candidate`
(`qualitas/whatsapp_checkpoint_followups.py`) nunca revisa el contenido de los mensajes del
cliente — solo fase/checkpoint, que el último mensaje sea del bot, ventana de 24h y tope de 3
intentos. El `systemMessage` del `AI Agent` en PROD sí tiene una regla de "escalamiento
inmediato" si el usuario dice que quiere cancelar, pero esa reacción es solo conversacional — no
persiste nada. **Resultado: si un lead escribe "ya no me interesa", "no me escribas más" o "ya
contraté con otra compañía", el siguiente recordatorio programado de ese checkpoint se manda
igual, horas después.**

**Mecanismo de fix — reparto real de trabajo (18 jul, corregido tras revisar más código):**

- **De Alberto/n8n (Agente n8n), sin depender de Juan:** el `AI Agent` reconoce la intención de
  declinar (orgánica, o el "no, gracias" explícito del punto 3 si se activa) y hace
  `UPDATE whatsapp_sessions SET status = 'closed'` directo por Postgres — n8n ya tiene ese acceso
  (mismo patrón que el `UPDATE` del copy del 17 jul). **No hace falta columna nueva:** `status`
  ya existe (migración de `conversation_id`) y `'closed'` ya es un valor reconocido en este mismo
  código base.
- **De Juan, cambio mínimo con precedente exacto en su propio código:** verificado que el
  scheduler viejo (`qualitas/n8n_whatsapp_activity.py:109-110`) **ya respeta `status`** —
  `if status in {"completed","closed","archived","expired"}: no elegible`. El sistema nuevo
  (`whatsapp_checkpoint_followups.py`) **no tiene ese check en absoluto** — captura `status` en
  metadata pero nunca lo evalúa. Pedirle a Juan que agregue las mismas 2 líneas (mismo patrón,
  ya probado en su código) a `evaluate_checkpoint_followup_candidate`. Bajo riesgo, no es diseño
  nuevo.
- Con esto, decisión #3 (arriba) y este gap se cierran con el mismo mecanismo — no son dos
  proyectos separados.
- **Efecto colateral a tener presente (no necesariamente malo):** `status != 'open'/'active'`
  también saca al lead de la lista de "conversaciones activas" que usa `whatsapp_conversations.py`
  (filtro ya existente ahí) — razonable para un lead que declinó, pero vale la pena que Alberto lo
  sepa antes de activarlo.

**✅ Implementado y verificado en STG (18 jul), certificado por el Arquitecto.** Nodo nuevo `Mark
Session Closed` (tool del `AI Agent`) + 2 cambios en el `systemMessage`: el bullet existente
"quiere cancelar" ahora también cierra la sesión (decisión de Alberto: sí debe marcar
`status='closed'`, independiente del escalamiento a humano), y un bloque nuevo "DECLINACIÓN
EXPLÍCITA DEL LEAD" que cierra sin escalar. Verificado en vivo por el Arquitecto: nodo confirmado
en el workflow real de STG, ejecuciones 402 (declinación, sin link de agente) y 403 (cancelación,
con link) coinciden exacto por trace, `whatsapp_sessions.status='closed'` + `closed_at` confirmado
en Postgres STG. **✅ Promovido a PROD (18 jul, noche), certificado por el Arquitecto:** nodo `Mark
Session Closed` y ambos bloques de `systemMessage` confirmados en el workflow real de PROD;
ejecución 3103 (*"ya no me interesa"*) releída — `Mark Session Closed` ejecutado, respuesta sin
link de agente, `status='closed'` + `closed_at` confirmados en Postgres PROD. La frase de copy
"no, gracias" del intento 3 sigue sin implementar — Alberto decidió NO activarla (18 jul, "muy
dura"), cae en este mismo mecanismo si cambia de opinión después.

**⚠️ Recordatorio: esto solo escribe el flag — Juan todavía no lo lee.** Hasta que Juan agregue el
check de `status` en `evaluate_checkpoint_followup_candidate` (2 líneas, mismo patrón que
`n8n_whatsapp_activity.py:109-110`), un lead marcado `closed` seguirá recibiendo recordatorios
automáticos igual. No bloqueante para seguir probando n8n, pero sí bloqueante antes de activar
envío real en PROD.

## Pendiente / no cerrado

- **✅ Resuelto (18 jul) — `delay_mins` reales de producción definidos por Alberto:** 5/5/10 min por intento, ver tabla "versión final para PROD" arriba. Falta que Juan cargue el fixture real en PROD.
- Autenticación del webhook en **PROD sigue sin aplicar** — decisión aparte, pendiente de coordinar (ese workflow tiene uso manual activo hoy). El fix de validación dual/`session_id` tampoco se aplicó a PROD todavía — sería un segundo paso coordinado, no automático.
- **✅ Re-confirmado (18 jul, verificado directo en Postgres PROD):** el sistema `checkpoint_followups` en su conjunto sigue sin existir en PROD — tabla `qualitas_leadfollowuppolicy` no existe ahí (`relation does not exist`). Coherente con todo lo de arriba: nada de esta iniciativa se ha promovido.
- **🔴 Hallazgo nuevo, sistema aparte (18 jul):** la plantilla de WhatsApp Business `cotizacion_followup_15m` — del mecanismo viejo de recordatorio a 15 min (`qualitas/whatsapp_followups.py`, activo en PROD desde el 25 jun, deliberadamente no unificado con `checkpoint_followups` por riesgo de baneo de Meta) — tiene copy desactualizado ("Hola, soy de SeguroAuto...") pese a que el copy de `checkpoint_followups` ya se rediseñó ("Uriel, de Quálitas..."). El contenido vive en una plantilla aprobada por Meta Business Manager, no en código ni BD — nadie la actualizó cuando se rediseñó el copy. Pendiente: actualizar y re-someter esa plantilla a aprobación en Meta (fuera del alcance de n8n/Django). Detalle: `Agente-n8n:docs/2026-07-18-hallazgo-plantilla-meta-cotizacion-followup-15m-desactualizada.md`.

## 🔴 Casi-incidente (19 jul, madrugada) — casi se manda envío real a las 11pm, y falta config real

Al activar `ENABLED=true`/`DRY_RUN_DEFAULT=false` (paso 8 del handoff a Juan,
`docs/2026-07-19-handoff-juan-activar-envio-real-checkpoint-followups.md`), Alberto notó que eran
las 11pm hora CDMX — 8 leads reales estaban `eligible` y a punto de recibir su primer recordatorio
automático a una hora inapropiada. **No existe ningún filtro de horario en el diseño original.**

Se pidió revertir de inmediato. Verificado en logs de Heroku en tiempo real: la corrida de las
05:30 UTC (justo después del cambio) **no mandó nada real** — no por el flag, sino porque
`N8N_PROACTIVE_WA_MESSAGE_URL` **nunca se configuró en `hyl-wai-production`** (confirmado directo
contra `config-vars`, no solo por el log: la variable no existe, tampoco
`N8N_PROACTIVE_WA_MESSAGE_TOKEN`). El camino de envío real de `checkpoint_followups` nunca se
había ejercitado en PROD hasta ese momento — el dry-run de toda la noche solo probó la lógica de
elegibilidad (`evaluate_checkpoint_followup_candidate`), que nunca toca la red; el código de envío
real (`send_due_checkpoint_followups` → llamada a n8n) es un camino completamente separado que
nunca se había ejecutado.

Juan revirtió `DRY_RUN_DEFAULT` a `true` — confirmado en vivo (`ENABLED=true`,
`DRY_RUN_DEFAULT=true`, estado seguro, cero riesgo de envío real).

**Antes de volver a intentar el envío real, faltan 4 cosas:**
1. **Filtro de horario — decidido, sin construir.** Alberto: **9am a 8pm hora CDMX**. Falta
   especificar y aplicar el fix (mismo patrón que el check de `status` de hoy: una condición más
   en `evaluate_checkpoint_followup_candidate`, comparando la hora local de
   `America/Mexico_City` contra la ventana — fuera de horario, `ineligible` y se reintenta solo en
   la siguiente corrida del Scheduler ya dentro de la ventana). Alberto lo dejó explícitamente
   como pendiente, no urgente esa noche.
2. **✅ Resuelto (19 jul) — `N8N_PROACTIVE_WA_MESSAGE_URL` y `N8N_PROACTIVE_WA_MESSAGE_TOKEN`
   configurados en PROD**, verificado directo contra `config-vars` de Heroku. El token reusa el
   mismo valor que ya tenía el Dashboard (`N8N_PROACTIVE_WEBHOOK_TOKEN`, mismo webhook/auth) —
   quedó además una variable duplicada con ese nombre viejo, sin efecto (Django no la lee), se
   puede borrar cuando se quiera.
3. **✅ Resuelto (19 jul) — versión robusta de `Retomar Conversacion` promovida a PROD**, verificada
   de forma independiente por el Arquitecto (no solo por el reporte de Agente n8n):
   - **Estructura**: 12 nodos en PROD (antes 3), `webhookId` sin cambio
     (`afd2b47d-bd99-4525-93a6-42764b8f56df`), credencial correcta de PROD
     (`Retomar Conversacion Header Auth PROD`, `9BE6CuKVOiuZBgDq`), `active=true`. `Normalize &
     Validate` confirma `session_id: String(body.session_id || "").trim()` — sin fallback a
     `conversation_id`, el bug de prioridad queda genuinamente corregido.
   - **Envío real de prueba (ejecución 3135)**: pasó por `Insert History` con éxito, clave
     `session_id` (no `conversation_id`) — confirmado a nivel de configuración del nodo.
   - **Idempotencia (ejecución 3136)**: reenvío con el mismo `idempotency_key` fue directo a
     `Build Already-Processed Response` (`status: "already_processed"`), nunca tocó `Insert
     History` — sin duplicar.
   - **Postgres PROD**: 0 filas bajo la clave de sesión de prueba y 0 bajo la clave incorrecta
     (`conversation_id`) — la fila de prueba fue borrada como se reportó.
   - **Bonus — camino "Tomar conversación" del Dashboard sigue intacto** (ejecución 3137, payload
     real sin `checkpoint`, teléfono `525551074144`): fila real `id=7327` en `n8n_chat_histories`,
     `created_at` coincide exacto con la ejecución — el uso manual activo hoy no se rompió.

   Reporte de Agente n8n certificado. `DRY_RUN_DEFAULT` sigue en `true`, sin riesgo de tráfico
   automático real. Detalle: `Agente-n8n:handoffs/2026-07-19-handoff-promover-retomar-conversacion-robusto-prod.md`.
4. **Verificar en STG primero** (con el filtro de horario ya puesto ahí) antes de repetir en PROD.

**No tocar `DRY_RUN_DEFAULT` de nuevo hasta que los 4 puntos estén resueltos.**
