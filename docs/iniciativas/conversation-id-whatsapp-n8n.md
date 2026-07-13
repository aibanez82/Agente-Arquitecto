# Iniciativa — Conversation ID como identidad conversacional WhatsApp (12 jul 2026)

> Estado: 🟡 Propuesta validada por el Arquitecto, handoffs enviados. **Nada desplegado todavía** — ni en STG ni en PROD.
> Guardado en git (no en memoria local) para persistir entre las 3 laptops de Alberto.

## Origen

Juan Aguayo entregó un documento técnico consolidado proponiendo mover la identidad conversacional de n8n de `phone_number` a `conversation_id`. Fuente completa: `aguayo-co/HYL-WAI:docs/reporte-alberto-n8n-conversation-id-whatsapp-meta.md`, rama `fix/conversation-id-whatsapp-n8n`.

## Por qué importa

Resuelve de raíz **Issue #21** (confirmado en la auditoría E2E del 11 jul: `sessionId = phoneNumber` literal — un teléfono con 2 cotizaciones activas mezcla ambas conversaciones). Mitiga **#13** (follow-up cotiza forma de pago distinta) y **#20** (duplicados ~9-11%). Se cruza con **#4** (n8n nunca hace INSERT en `whatsapp_sessions`) y **#7** (Payment Confirmation no marca `estatus_pago`) porque toca exactamente los mismos nodos.

## Validación del Arquitecto (12 jul)

- Rama real: 1 commit de código (`e9cf0e0`) + 3 commits de docs. **NO mergeada** a `stg` ni `main` — nada desplegado.
- Migración `qualitas/migrations/0033_whatsapp_conversation_id_phase2.py`: defensiva, chequea existencia de tabla/columna antes de `ALTER`, índices condicionales. Default `WHATSAPP_CONVERSATION_ID_MODE=legacy` → **cero cambio de comportamiento** si se despliega tal cual.
- Nombres de nodo citados por Juan verificados **1:1 contra n8n PROD vivo** vía API (no contra nuestro backup local, que lleva desactualizado desde el 6 jul — issue #30). Su análisis es más preciso que nuestra propia copia.
- Queries citadas confirmadas carácter por carácter contra el live: `Load Session`, `Check Session Exists`, el nodo de cierre de pago (nombre real tiene un espacio inicial: `" Mark Session Completed"`), el INSERT de `Retomar Conversacion`.

## Diseño (resumen — detalle completo en el documento de Juan)

- `phoneNumber` = destino de envío WhatsApp (nunca cambia).
- `sessionId` = identidad conversacional resuelta. v1 legacy = teléfono. v2 = `conversation_id`.
- `conversationId` = formato `waq_<cotizacion_id>_<12hex>`, sin PII.
- Feature flag Django `WHATSAPP_CONVERSATION_ID_MODE`: `legacy` → `shadow` → `dual` → `enforced`.
- Payload quick reply v2: `qc:v2:cv:<conversation_id>:l:<lead_id>:c:<cotizacion_id>:m:<token>` (v1 sigue vivo como fallback: `qc:v1:l:<lead_id>:c:<cotizacion_id>:m:<token>`).
- Columnas nuevas en `whatsapp_sessions`/`whatsapp_sessions_archive`: `conversation_id VARCHAR(80)`, `lead_id INTEGER`, `status VARCHAR(30) DEFAULT 'open'`, `closed_at TIMESTAMPTZ`.

## Rollout de fases (propuesto por Juan, adoptado)

1. **Staging Django `shadow`** — solo persiste `conversation_id`, payload visible sigue v1. n8n puede seguir legacy.
2. **Staging Django `dual` + n8n actualizado** — payload v2 real, click de quick reply real en Meta staging.
3. **Regresión legacy** — payload v1, sesión vieja (`session_id = phoneNumber`), pago sin `conversation_id`, mensaje sin payload.
4. **Multi-cotización mismo teléfono** — 2 cotizaciones, historiales separados, `/api/cotizacion/detalle/` y `/api/emitir-externo/` correctos, el pago cierra solo la conversación correcta.
5. **`enforced`** — solo después de estabilizar 1-4. Nunca saltar directo a producción.

## Repartición de trabajo

| Quién | Qué | Dónde |
|---|---|---|
| Juan / Django | Rama lista y shadow-safe. Falta merge a `stg` + deploy cuando Agente n8n esté listo para probar `dual`. Debe correr la migración 0033 en STG antes de cualquier prueba. | `aguayo-co/HYL-WAI` |
| Agente n8n | Reescribir `Session Context Builder`, `Merge Session Data`, `Load Session`, el nodo de cierre de pago, el INSERT de Retomar Conversación. **Actualizado 12 jul tarde:** requiere además reestructurar `Check Session Exists`/`Load Session`/`Session Router` (ver abajo) — no basta con tocar solo `Session Context Builder`. | `Agente-n8n/handoffs/2026-07-12-handoff-conversation-id-whatsapp.md` |
| Code Agent Dashboard | Endpoint proactivo (`n8n-proactive-message.js`), quitar fallback `'52'+telefono` en `LeadModal.js`, resolver conversación por `cotizacion_id` en `conversation.js`, exponer columnas nuevas en `db-leads.js`, actualizar `CLAUDE.md` propio. | `Dashboard_SeguroAuto/docs/2026-07-12-handoff-conversation-id-whatsapp.md` |
| Agente QA | Plan de pruebas fases 3-4 en staging (n8n + Django). Pendiente sumar los 4 casos del Dashboard (legacy, v2, multi-cotización, sin sesión) cuando el Code Agent tenga su parte lista. | `Agente_QATest_Qualitas/handoffs/2026-07-12-handoff-test-conversation-id-whatsapp.md` |
| Juan | Validar en Meta Business Manager (él es el dueño de la cuenta Meta) que la plantilla `cotizacion_inicial_link` tiene botón quick-reply en posición 0 **antes** de pasar Django a `dual` en cualquier ambiente. Correr la migración 0033 en STG. Mergear la rama a `stg` + deploy con el flag correspondiente. | Meta Business Manager / Heroku |

## Actualización (12 jul, tarde) — Juan amplió el documento con 2 hallazgos

1. **Nuevo alcance: Dashboard.** Juan auditó el zip del Dashboard y entregó `docs/reporte-alberto-dashboard-conversation-id-whatsapp.md` — reemplaza cualquier guía previa tipo `resumen-fix-whatsapp-sessions-n8n.md`. Hallazgo principal: el endpoint proactivo valida `session_id.startsWith('52')`, que es falso en v2, y `LeadModal.js` inventa `session_id = '52'+telefono` cuando falta — ambos rompen con `conversation_id`. El funnel principal NO se rompe (sigue uniendo por `quotation_id`). Traducido a handoff concreto arriba.
2. **Corrección estructural en n8n, validada contra el export real de STG (no PROD).** La cadena STG es `Session Context Builder -> Check Session Exists -> Session Router -> Load Session/Fallback Flag -> Merge Session Data`. `Check Session Exists`/`Load Session` solo buscan por `session_id` literal, y `Session Context Builder` no consulta Postgres — así que reescribir solo ese nodo (como decía mi handoff original) **no alcanza**: payload v1, mensajes sin payload y desambiguación seguirían cayendo en fallback. Hace falta un nodo `Resolve Session` nuevo, o reescribir `Check Session Exists`/`Load Session` en sitio. Ya corregido en el handoff del Agente n8n.

## Dashboard — completado en rama, bloqueado en la misma migración (12 jul, noche)

El Code Agent del Dashboard implementó los 6 puntos del checklist en rama `fix/conversation-id-whatsapp-n8n` (commit `c18bf18`, pusheada, **sin mergear a `main`**). Reportó y el Arquitecto verificó en vivo:

- **STG todavía no tiene la migración 0033** — confirmado directo contra la Postgres de `hyl-wai-stg` (vía Heroku API + Heroku Platform, no solo el acceso readonly del sandbox del Dashboard): `whatsapp_sessions` no tiene `conversation_id`/`lead_id`/`status`/`closed_at`, y `django_migrations` se detiene en `0032`. `WHATSAPP_CONVERSATION_ID_MODE` ni siquiera está seteado como config var en `hyl-wai-stg` todavía.
- El código nuevo del Dashboard, al depender de esas columnas, **rompe con error SQL duro si se corre hoy** — el Code Agent lo verificó honestamente contra PROD antes de asumir éxito, y correctamente no mergeó ni desplegó nada.
- ⚠️ **Riesgo operativo a vigilar:** Vercel genera Preview automático por rama — el Preview de `fix/conversation-id-whatsapp-n8n` en el Dashboard va a mostrar `/api/db-leads` roto (500) hasta que la migración aterrice en STG. No es un bug nuevo si alguien lo abre por error.
- Spot-check del Arquitecto sobre `pages/api/n8n-proactive-message.js`: el diff coincide con el handoff (SELECT ampliado, validación sobre `phone_number`, payload nuevo a n8n). Sin objeciones.
- Las 4 pruebas mínimas quedan pendientes de correr contra STG una vez migrado — coordinar con Agente QA.

## Riesgos / cosas a vigilar

- **Sequencing:** n8n y Dashboard pueden prepararse en paralelo, pero probar `dual` de verdad requiere que Django esté desplegado en `shadow`/`dual` en STG primero — coordinar con Juan el momento del merge + deploy a `hyl-wai-stg`.
- Este cambio toca el mismo workflow de pago que **#7** y el mismo INSERT silencioso de **#4** — conviene resolverlos en la misma pasada, no en dos handoffs separados que reabran el mismo nodo dos veces.
- STG no tiene todavía las columnas nuevas — no está migrado. Confirmar con Juan que la migración 0033 corrió ahí antes de que Agente n8n empiece a probar contra `Postgres STG`.
- No pasar producción a `enforced` sin pasar por `shadow` y `dual` primero (explícito en el documento de Juan — respetar el orden).
- La reestructuración de `Check Session Exists`/`Load Session`/`Session Router` es más invasiva de lo que se pensó inicialmente — vale la pena que el Agente n8n confirme cuál de las 2 opciones (nodo nuevo vs. reescribir en sitio) eligió antes de que avance mucho.

## Estado

🟡 12 jul (tarde): propuesta ampliada a Dashboard + corregida estructuralmente en n8n. Handoffs actualizados/enviados a Agente n8n, Agente QA y Code Agent Dashboard. Nada desplegado todavía en ningún ambiente.
