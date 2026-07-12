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
| Agente n8n | Reescribir `Session Context Builder`, `Merge Session Data`, `Load Session`, el nodo de cierre de pago, el INSERT de Retomar Conversación. | `Agente-n8n/handoffs/2026-07-12-handoff-conversation-id-whatsapp.md` |
| Agente QA | Plan de pruebas fases 3-4 en staging. | `Agente_QATest_Qualitas/handoffs/2026-07-12-handoff-test-conversation-id-whatsapp.md` |
| Alberto | Validar en Meta Business Manager que la plantilla `cotizacion_inicial_link` tiene botón quick-reply en posición 0 **antes** de pasar Django a `dual` en cualquier ambiente. | Meta Business Manager |

## Riesgos / cosas a vigilar

- **Sequencing:** n8n puede prepararse en paralelo, pero probar `dual` de verdad requiere que Django esté desplegado en `shadow`/`dual` en STG primero — coordinar con Juan el momento del merge + deploy a `hyl-wai-stg`.
- Este cambio toca el mismo workflow de pago que **#7** y el mismo INSERT silencioso de **#4** — conviene resolverlos en la misma pasada, no en dos handoffs separados que reabran el mismo nodo dos veces.
- STG no tiene todavía las columnas nuevas — no está migrado. Confirmar con Juan que la migración 0033 corrió ahí antes de que Agente n8n empiece a probar contra `Postgres STG`.
- No pasar producción a `enforced` sin pasar por `shadow` y `dual` primero (explícito en el documento de Juan — respetar el orden).

## Estado

🟡 12 jul: propuesta validada, handoffs enviados a Agente n8n y Agente QA. Nada desplegado todavía en ningún ambiente.
