# Inventario — usos de `session_id` en el Dashboard fuera del perímetro S1 (DOCS-ONLY)

> **4 ago 2026, ~21:55 CDMX.** Pedido por Alberto durante la espera del dictamen r6. Árbol
> auditado: `Dashboard_seguroautoqualitas@c911d4c` (candidato S1 v1.1 congelado, solo lectura;
> cero cambios en ese repo). Propósito: insumo para la migración a `conversation_id` como
> identidad canónica en S2–S5 — NO es una lista de bugs de S1.

## Marco contractual (por qué esto no es una desviación hoy)

S1 v1.1 §7.1/§7.2 mantiene `session_id` como clave exacta con `identity_mode` derivado
(legacy/shadow/v2); en v2, `session_id === conversation_id` — convergen en el mismo string.
Con PROD a 0 sesiones `waq_*` y `conversation_id` ~57% poblada, la lógica keyeada en
`session_id` es la ÚNICA que cubre todas las filas. La pregunta correcta no es "¿usa
session_id?" sino "¿qué pasa en cada superficie cuando lleguen filas v2 (`waq_*`)?".

## A. Rechaza o rompe con sesiones v2 — acción NECESARIA en el paso a `dual`

1. **`pages/api/n8n-proactive-message.js:121-161` — `handleLegacyProd`** (el camino PROD,
   conservado byte a byte por requisito del propio contrato S1):
   - `VALID_SESSION_PREFIXES = ['52','57','1']` (L141-143): semántica de prefijo TELEFÓNICO
     sobre `session_id` → **rechazaría toda sesión `waq_*`** con "prefijo inválido".
   - `phone_number: session_id` en el POST al webhook (L154): la conflación
     transporte/identidad que el gate de Juan señaló en el STOP original — sigue viva en el
     camino legacy (el camino S1, `handleS1` + builder, ya es conforme).
   - **Migración:** al activar `dual`, el builder S1 pasa a ser el único camino (S2/S3 según
     alcance de workflows); retiro del handler legacy en S5.

## B. Claves de datos por `session_id` — correctas hoy; dependen de la BD, no del Dashboard

2. **`pages/api/db-leads.js:96-99`** — JOIN a `n8n_chat_histories` por `session_id`: la tabla
   de n8n SE KEYEA así (ownership n8n). El Dashboard no puede migrar esto unilateralmente;
   la salida real es la tabla canónica propuesta (`whatsapp-event-canonico-propuesta.md`) o
   una decisión n8n en S2+. También: `COALESCE(ws.session_id, wsa.session_id)` (L35-36,
   fallback a archive) — ya rotulado en el código como "legacy ajeno a S1".
3. **`pages/api/claim.js`** — `dashboard_conversation_claims` keyea el claim por `session_id`
   (+ `uq_claims_active_session`). Resuelto SIEMPRE server-side (conforme S1). En v2 la clave
   toma el mismo valor que `conversation_id` — sin cambio de código. Coherente con nuestra
   propuesta S2 (consulta canónica de control parametrizada por `session_id`).
4. **`dashboard_message_audit`** (`saveAudit`, `n8n-proactive-message.js:170-179`) — registra
   `session_id`. Sin riesgo. Mejora aditiva opcional para la era dual: registrar también
   `conversation_id`/`identity_mode` (columna nueva = DDL → requiere autorización; hasta
   entonces, nada).

## C. UI/display — cosmético, pero visible en cuanto existan filas `waq_*`

5. **`components/ConversationModal.js:48` y `ConversationWorkspace.js:190`** —
   `lead.telefono || sessionId` como fallback del campo 📱: con una sesión v2 mostraría
   `waq_81003_…` como si fuera un teléfono. Fix de una línea (fallback a `phone_number`,
   que es el transporte real). No urgente; entra natural en S3 (Atención Humana toca esas
   superficies).
6. **`components/FunnelV2.js:435-437`** — `session_id != null` como proxy de "canal WA":
   sigue siendo válido en v2 (`waq_*` también es no-null). **Sin acción.**
7. **`components/ChatHistory.js:57`** — `session_id` en el pie técnico de debug. Sin acción
   (opcional: mostrar ambos IDs en la era dual).

## D. Perímetro S1 — ya conforme (referencia, sin acción)

`pages/api/conversation.js`, `pages/api/inbox.js`, `lib/s1/*` (resolve/identity/ids/
retomarBuilder/runtimeMode): resolución server-side por lead/cotización, `session_id` del
cliente solo cruza-verifica, `identity_mode` derivado, coherencia de selectores, IDs
canónicos. Es el patrón a extender, no a corregir.

## Mapa a etapas

| Etapa | Acción sobre este inventario |
|---|---|
| S2 | Nada obligatorio. La consulta canónica de control por `session_id` (propuesta en `#135 c.5187242434`) es compatible con la convergencia v2. |
| S3 (Atención Humana) | Ítem 5 (display) entra natural; decidir si el camino proactivo legacy (ítem 1) se unifica aquí o en S4. |
| S4 (Metepec) | Workflows que escriben mirrors — junto con la migración de escritores propuesta para A5. |
| S5 (limpieza) | Retiro de `handleLegacyProd` (ítem 1), del fallback archive rotulado legacy (ítem 2b) y de todo camino no-builder. |

**Resumen ejecutivo:** solo el ítem 1 (handler proactivo legacy) rompe funcionalmente con
sesiones v2, y su existencia es hoy un requisito contractual (PROD intacto). El resto es
convergencia automática (B), cosmética (C) o dependencia de BD ajena al Dashboard (2). La
arquitectura S1 ya apunta en la dirección correcta; el trabajo real de "conversation_id
canónico" es de S3–S5 y de n8n/BD tanto como del Dashboard.
