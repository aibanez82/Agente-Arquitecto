# Bug #11 — Sesión pegada a la 1ª cotización al recotizar

**Sistema:** Django · **Estado:** ✅ Resuelto — desplegado y verificado en PROD (11 jul)

## ✅ Resolución (11 jul) — Juan implementó la Opción (a), verificada en vivo

Juan aplicó el fix en Django y lo compartió como `/Users/AIP/Downloads/resumen-fix-whatsapp-sessions-n8n.md` (resumen suyo, dirigido a Alberto/Arquitecto/Agente n8n). Implementa exactamente la opción **(a)** que quedó pendiente de decisión abajo: recotización = conversación fresca.

**Qué cambia (`qualitas/models.py`, `qualitas/utils.py`, migración `0032_whatsapp_sessions_archive_operational_fix`):**
- El archivado de la sesión anterior ocurre **solo después** de que el nuevo WhatsApp inicial se envió con éxito (evita archivar una sesión activa si el envío falla).
- Si se envía bien: Django archiva `whatsapp_sessions` y `n8n_chat_histories` de la sesión vieja (a `_archive`), borra las filas activas, y crea una fila nueva en `whatsapp_sessions` en fase `greeting` apuntando a la cotización nueva.
- Fallback `ON CONFLICT (session_id) DO UPDATE` por si la fila con ese `session_id` todavía existe.
- El archivado ya no usa `SELECT *` — copia columnas explícitas, más resistente a diferencias de esquema entre tabla activa y archive.
- **Fix estructural importante:** antes, `session_id` era PK/unique en las tablas `_archive`, lo que probablemente impedía archivar más de una recotización por teléfono (colisión de llave). La migración `0032` cambia la PK de ambas tablas archive a `archive_id` (BIGSERIAL) y deja `session_id` como índice no-único — ahora sí se puede archivar cada recotización de un mismo teléfono.
- Contrato con n8n **sin cambios**: `session_id = phone_number`, n8n sigue leyendo `whatsapp_sessions` y escribiendo en `n8n_chat_histories` igual que siempre. Único cuidado para n8n: si algún workflow esperaba encontrar historial viejo tras una recotización, ya no está en la tabla activa (vive en `_archive`) — es el comportamiento deseado (conversación limpia), no un bug.

**Verificado en vivo por el Arquitecto (11 jul), no solo por el resumen de Juan:**
- Commit `5b05f57` ("Fix WhatsApp session operational archive flow") confirmado en `origin/main`, mergeado vía PR #98 + sync PR #99.
- Heroku `hyl-wai-production`: release **v314**, "Deploy `0a2602ea`" (que incluye `5b05f57`), `current: true`, desplegado 2026-07-11T05:50:32Z — mismo día, horas antes de este chequeo.
- Esquema real en PROD: `whatsapp_sessions_archive` y `n8n_chat_histories_archive` ya tienen PK `archive_id` (bigint), confirmado por consulta directa a `pg_index`/`pg_attribute`.
- El mecanismo ya se disparó una vez en PROD: una fila en `whatsapp_sessions_archive` con `session_id='573107696237'` (el número de prueba de Juan, el mismo de los Bugs #2/#15), archivada a las 2026-07-11T06:03:12Z — 13 minutos después del deploy. Consistente con que Juan probó su propio fix recotizando con su número de prueba.

**Pendiente (no bloqueante):** confirmar con más tráfico real (no solo la prueba de Juan) que el flujo completo funciona con leads reales recotizando, y que el Dashboard ya ve el funnel completo (el síntoma original del 4 jul, 9/46 leads fuera del funnel). El Agente Dashboard puede reverificar esto en su próxima pasada.

---

## Detalle original (pre-fix, mantenido como registro)

**Sistema:** n8n · **Estado:** 🟠 Alto — registrado, en pausa (Alberto lo piensa)

## Fila de la tabla original

| 11 | Sesiones pegadas a la 1ª cotización al recotizar — leads reales caen fuera del funnel WhatsApp. Detectado 4 jul 2026 por el Dashboard agent (9/9 verificado: 46 enviados, solo 37 en funnel). | n8n | 🟠 Alto — **registrado, en pausa (Alberto lo piensa).** Ver detalle abajo. |

## Detalle Bug #11 (sesión pegada a la 1ª cotización al recotizar) — REGISTRADO, EN PAUSA

**Detalle Bug #11 (sesión pegada a la 1ª cotización al recotizar) — REGISTRADO, EN PAUSA (Alberto lo piensa):**
- **Síntoma (Dashboard agent, 4 jul):** el funnel "VÍA WHATSAPP" pierde leads — 46 enviados hoy, solo 37 en el funnel; los 9 faltantes recibieron el mensaje y varios conversan activamente, pero el dashboard no los ve. 9/9 verificado.
- **Causa raíz:** `whatsapp_sessions` es **única por teléfono** (`session_id='52'+telefono`). Al recotizar (común: 2-4 cotizaciones por número), se crea cotización nueva pero la fila de sesión ya existe y **su `quotation_id` NO se actualiza** → queda pegado a la 1ª cotización. El join del dashboard (`whatsapp_sessions.quotation_id = qualitas_cotizacion.id`) no encuentra la cotización nueva → lead fuera del funnel.
- **✅ Dónde vive el fix — CORREGIDO 9 jul, leído directo del código:** el bot de conversación NUNCA escribe `quotation_id` (solo lo lee de la BD). Pero **NO hay ningún "workflow del webhook de lead creado" en n8n** — eso era una inferencia nunca verificada (confirmado por API: PROD solo tiene 3 workflows, ninguno de "lead creado"). El `quotation_id` se asigna con un **`INSERT INTO whatsapp_sessions` de SQL crudo dentro de Django** (`qualitas/models.py`, en el `serve()` de la landing page, justo después de enviar el WhatsApp inicial vía Meta Graph API directo). **El fix es un cambio de Django, no de n8n:** cambiar ese `INSERT` a `INSERT ... ON CONFLICT (session_id) DO UPDATE SET quotation_id = EXCLUDED.quotation_id, ...`. Ver la corrección completa de arquitectura más arriba (sección "Regla crítica de arquitectura").
- **Arquitectura — NO "sesión por cotización":** WhatsApp = un hilo por número, y `n8n_chat_histories` (memoria) se llavea por `session_id=teléfono`. Lo correcto: una sesión por teléfono apuntando a la cotización **más reciente** → UPSERT de `quotation_id`.
- **DECISIÓN PENDIENTE de Alberto:** al actualizar `quotation_id`, ¿(a) resetear a `greeting` + limpiar `captured_data` (recotización = conversación fresca; recomendado, porque el historial y `captured_data` arrastran contexto/serie del auto anterior y si recotiza otro auto quedan mal), o (b) mantener fase/captured_data y solo cambiar `quotation_id`? Depende de por qué recotiza la gente (mismo auto más barato vs otro auto).
- **Prerrequisito para el fix:** solo la decisión (a)/(b) — ya NO hace falta exportar ningún workflow (no existe). El cambio es en `qualitas/models.py` de `aguayo-co/HYL-WAI`, tarea de **Juan**, no del Agente n8n.
- **Mitigación dashboard (aprobada como interina):** asociar la sesión por teléfono al lead más reciente + reetiquetar "Recotizaciones" en UI. El arreglo limpio es upstream (Django).
- **Relación:** encaja con el proyecto CSF (el `captured_data` debe resetear en recotización) y con Bug #4 (leads sin whatsapp_session).
