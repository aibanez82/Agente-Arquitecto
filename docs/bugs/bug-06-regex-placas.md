# Bug #6 — Regex placas rechaza 6 caracteres

**Sistema:** n8n · **Estado:** ✅ Resuelto (9 jul, verificado en prod 10 jul)

## Fila de la tabla original

| 6 | ~~Regex placas rechaza 6 caracteres (`/^[A-Z0-9]{7}$/`) — Issue #2~~ | n8n | ✅ Resuelto — ver detalle abajo |

## Detalle Bug #6 (regex placas — RESUELTO 9 jul)

**Detalle Bug #6 (regex placas — RESUELTO 9 jul):**
- Detectado de forma convergente por dos vías independientes: (a) handoff del Arquitecto a Agente n8n del 8 jul (`docs/2026-07-08-handoff-agente-n8n-bug6-regex-placas-6-7-caracteres.md`); (b) Agente Mejoras Conversación lo identificó por separado como "M13" (`Agente-MejorasConversacion/informes/parches/M13-validador-placas.md`) y confirmó un caso real en producción el mismo 9 jul (`informes/correcciones/2026-07-09-caso-004.md`): placa válida `96F841` (6 caracteres) rechazada, bloqueando al lead.
- Nodo `Validate Personal Data` (`@n8n/n8n-nodes-langchain.toolCode`), campo `jsCode`: `const placasRegex = /^[A-Z0-9]{7}$/;` → `/^[A-Z0-9]{6,7}$/`. México usa formatos válidos de 6 y 7 caracteres.
- Verificado que Django no tiene validación propia de formato de placas (grep exhaustivo sobre `aguayo-co/HYL-WAI`, cero resultados) — no hay segunda capa que reconciliar, a diferencia del Bug #10 con la serie/VIN.
- Aplicado por Agente n8n: commit `d3e9307` (rama `stg`, repo `Agente-n8n`) — confirmado en vivo por el Arquitecto contra la instancia de n8n de STG (`placasRegex = /^[A-Z0-9]{6,7}$/` en el JSON real). Desplegado a **PRODUCCIÓN** el 9 jul, según reporte de Agente n8n (PUT→200, activate→200, `webhookId` sin cambios `18c1b498-...`, 62 nodos, `AI Agent.systemMessage` actualizado a "6-7 caracteres" en sus 2 menciones, `Phone Number ID Guard` del Bug #15 intacto). **✅ Verificado de forma independiente por el Arquitecto el 10 jul, en vivo contra la API de PROD** (Alberto compartió el `N8N_API_KEY` de producción): los 5 puntos del reporte coinciden exactos — regex, ambas menciones del prompt, guard con su condición `phone_number_id == 1028815256982638` sin tocar, mismo `webhookId`, 62 nodos.
