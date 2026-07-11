# Bug #9 — POST /api/emitir-externo/ devuelve HTTP 400 recurrente

**Sistema:** Django · **Estado:** 🔴 Crítico

## Fila de la tabla original

| 9 | `POST /api/emitir-externo/` devuelve HTTP 400 recurrente — la emisión de pólizas falla y Django se traga la causa (mensaje genérico, sin logging). Detectado 1 jul 2026. | Django | 🔴 Crítico |

## Detalle Bug #9 (emisión 400)

**Detalle Bug #9 (emisión 400):**
- El nodo `Issue Policy` en n8n hace `POST https://seguroautoqualitas.com/api/emitir-externo/` (endpoint de Django, no Quálitas directo).
- Django responde `400 {"status":"error","msg":"Experimentamos intermitencias…"}` — mensaje enlatado genérico.
- Buscando por `request_id` en Papertrail **no hay más líneas**: la vista no loguea el fault real ni el campo que falla. `service=708ms` sugiere rechazo en validación de Django, no caída de Quálitas.
- El error **no se guarda en BD** (`qualitas_cotizacionrespuestaxml` es de cotización, no de emisión; `qualitas_leadactionevent` no registra fallos de emisión).
- Probablemente **no** es el Bug #8 (teléfono ausente daría emisión con campo vacío, no 400).
- Pista para Juan: `QUALITAS_AMBIENTE_FLAG = 0` (verificar si es el valor correcto para emisión en vivo).
- Petición doble a Juan: (a) causa raíz del campo que falla; (b) **observabilidad** — loguear el fault de Quálitas y devolver la causa en un campo `detail`.
- Repetido al menos 2 veces el 1 jul 2026 (12:49:32 y 13:05:15 CDMX). request_id ejemplo: `f00e2d0d-927b-33a1-66dc-e6193db0a1f1`.
