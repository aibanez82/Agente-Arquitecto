# Bug #11 — Sesión pegada a la 1ª cotización al recotizar

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
