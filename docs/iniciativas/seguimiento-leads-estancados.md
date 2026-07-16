# Iniciativa — Seguimiento automático de leads estancados (15-16 jul 2026)

> Estado: 🟡 Django implementado y verificado en STG (16 jul, commit `789443b`, migración `0041`). **Bloqueante encontrado: n8n no cumple el contrato que el propio Juan especificó** (ver sección "Verificación de la implementación" abajo). Nada activado para envío real todavía, nada en PROD.
> Guardado en git (no en memoria local) para persistir entre las 3 laptops de Alberto.
> Ejecutor: Agente n8n. Reporte fuente: `Agente-n8n:docs/2026-07-16-resumen-arquitecto-seguimiento-leads-estancados.md`.

## Origen

Alberto viene rescatando manualmente conversaciones de WhatsApp que se quedan a medias (cliente recibe la cotización o llega a un punto del flujo y deja de contestar), mandando un mensaje de seguimiento horas después con buenos resultados. Arrancó el 15 jul a partir de una pregunta operativa sobre el lead #1353 y terminó en un acuerdo de implementación con Juan.

## Diseño

**7 checkpoints** (puntos de espera del bot) derivados de `conversation_phase`/`captured_data`, con política de hasta 3 reintentos por checkpoint.

**Principio de diseño clave:** no se agrega ningún campo de estado nuevo en `qualitas_lead` ni en `whatsapp_sessions`. Ya existen tres fuentes distintas compitiendo por decir "en qué estado está un lead" (`Lead.estado`, `conversation_phase`, `LeadActionEvent`) y confirmaron que dos ya están desincronizadas en producción (un lead con `captured_data` completo seguía en `estado='COTIZACION_INICIADA'`). Los checkpoints se derivan en vivo; los reintentos se cuentan contando eventos en `LeadActionEvent`, no con un contador nuevo.

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

- **Solapamiento con el scheduler de follow-up que ya existe.** Django ya tiene un mecanismo de seguimiento de 15 min (`qualitas/whatsapp_followups.py` → `resolver_opcion_cotizacion_whatsapp`), con **Bug #13** abierto (puede enviar el precio de una forma de pago distinta a la cotizada verbalmente) e **Issue #74** (dejó de dispararse el 30 jun, causa raíz nunca cerrada). El reporte de esta iniciativa no dice si el nuevo sistema de checkpoints/`LeadFollowupPolicy` reemplaza a ese scheduler viejo, corre en paralelo, o lo desactiva. Si corren los dos a la vez sobre el mismo lead estancado, hay riesgo real de mensaje duplicado — y el nuevo hereda el mismo riesgo de Bug #13 si tampoco lee `forma_pago` confirmada antes de mandar el seguimiento. **Acción:** preguntarle a Juan explícitamente qué pasa con el scheduler viejo antes de que arranque la implementación de Django.
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

## Pendiente / no cerrado

- **🔴 Bloqueante:** que Agente n8n corrija el nodo de `Retomar Conversacion` (STG, luego PROD) para
  que la clave de inserción sea `body.session_id` sin fallback a `conversation_id` — ver sección de
  verificación arriba.
- Django ya implementado en STG — pendiente solo activarlo (ver siguiente punto), no arrancar desde cero.
- Alberto tiene pendiente compartirle a Juan el token de autenticación del webhook (ya generado, falta mandarlo por canal seguro, no por git) y `N8N_PROACTIVE_WA_MESSAGE_URL`/`_TOKEN` siguen sin configurarse en `hyl-wai-stg`.
- **Solapamiento con el scheduler viejo de 15 min** (`WHATSAPP_FOLLOWUPS_ENABLED=1`, activo en STG y PROD) sin resolver — Juan no lo abordó en su reporte detallado tampoco. Sin riesgo mientras `checkpoint_followups` siga apagado.
- `delay_mins` finales de producción sin definir — el fixture actual (`delay_mins=1`) es explícitamente solo para pruebas en STG.
- Autenticación del webhook en **PROD sigue sin aplicar** — decisión aparte, pendiente de coordinar (ese workflow tiene uso manual activo hoy).
- Sin verificación end-to-end todavía: falta provocar un lead estancado real en STG y confirmar que el reintento completo (Django → n8n → WhatsApp → `LeadActionEvent`) funciona, y debe esperar a que se corrija el gap de `session_id` de n8n primero (si no, el mensaje se perdería igual aunque Django marque `sent`).
