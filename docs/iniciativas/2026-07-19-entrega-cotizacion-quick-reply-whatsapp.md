# Entrega de cotización vía quick reply — nuevo modo `resumen_quick_reply` (Juan)

> Origen: Juan (equipo Django/Wagtail), doc en `aguayo-co/HYL-WAI:docs/instrucciones-alberto-n8n-entrega-cotizacion-whatsapp.md`
> (rama `stg`). Diagnosticado por el Arquitecto contra el código real (STG/PROD), no solo leído.

## Qué construyó Juan (ya real, en `stg` de HYL-WAI, no en `main`)

Wagtail ahora permite elegir, por administrador, el modo del WhatsApp inicial que manda Django:

- `pdf_adjunto` (el que existe hoy en PROD): Django adjunta el PDF directo.
- `resumen_quick_reply` (nuevo): Django manda imagen + 3 variables (vehículo/cobertura/monto) +
  un botón quick reply. **n8n debe entregar el PDF/enlace después del clic** — hoy no lo hace.

Verificado en código real (`origin/stg` de `aguayo-co/HYL-WAI`):
- Migración `0045_whatsapp_initial_delivery_mode.py` — selector con **default `resumen_quick_reply`**.
- `qualitas/whatsapp_quote_preview.py` — los dos modos como constantes.
- `qualitas/whatsapp_conversations.py:245` — genera el payload `qc:v2:cv:<conv>:l:<lead>:c:<cot>:m:<token>`.
- `qualitas/views.py:701-807` — endpoint `POST /api/cotizacion/detalle/` (`urls.py:12`) ya
  implementado y probado (`tests/views/test_whatsapp_api.py`), devuelve `documento_cotizacion`
  con `autorizado`/`disponible`/`url`/`filename`/`caption`/`mensaje_no_disponible`.

**Todo esto vive solo en `stg`, no mergeado a `main`** — sin riesgo inmediato en PROD todavía.
Confirmado: `git merge-base --is-ancestor` da NO para main.

## Corrección a una afirmación del doc de Juan (verificado, no asumido)

El doc dice: *"Los exports n8n actualmente versionados no constituyen evidencia de esta
integración: todavía no resuelven `interactive.button_reply.id`..."* — **esto es parcialmente
inexacto.** Verificado en vivo contra el nodo `Session Context Builder` del bot principal (STG
`dNqtM20ij6ecZYAX` y PROD `BtOaZm7WlZT-24V7hqCnF`, ambos idénticos en esto):

- **Ya extrae `interactive.button_reply.id`** (y también `button.payload` para quick-replies
  sobre plantilla) como `buttonPayload`, sin usar nunca `.title` — exactamente la regla que pide
  el runbook.
- **Ya parsea `qc:v1`/`qc:v2` con la misma gramática** (`qc:v2:cv:<id>:l:<id>:c:<id>:m:<hex>`),
  ya resuelve `conversationId`/`quotationId`/`leadId`, ya fija `lookupMode: payload_v2/payload_v1`
  para `Resolve Session`.

Esto es reusado de Issue #21 (identidad conversacional, ya en PROD desde el 16 jul) — el payload
`qc:v1`/`v2` no se inventó para este feature, ya existía para resolución de sesión por clic en
general.

**Lo que sí falta de verdad (aquí Juan tiene razón):** hoy, cuando llega un `buttonPayload`, el
flujo solo fija `chatInput = "Continuar cotización"` y sigue el camino conversacional normal
hacia el agente de IA — **no hay ninguna rama determinística que intercepte antes del agente,
llame a `/api/cotizacion/detalle/` y entregue el documento.** Falta genuinamente:

1. IF `quoteDocumentAction` inmediatamente después de `Session Context Builder`/`Resolve Session`,
   antes del agente IA (necesita un criterio de negocio para distinguir "este payload es de
   entrega de documento" de otros usos futuros del mismo `qc:v1/v2` — a definir con Juan si hace
   falta un marcador adicional, o si todo `buttonPayload` válido en este flujo implica entrega).
2. Nodo HTTP Request a `POST /api/cotizacion/detalle/` con `Authorization: Bearer N8N_TOKEN`.
3. Lógica de decisión de la tabla del runbook (autorizado/disponible → entregar; no autorizado →
   alerta; no disponible → `mensaje_no_disponible`; etc.).
4. Envío del documento o enlace a Meta (nodo HTTP Request nuevo, tipo `document`).
5. Idempotencia durable por `messages[0].id` (Data Table de n8n o mecanismo ya aprobado) — no
   existe hoy nada equivalente para este flujo.
6. Registro en `n8n_chat_histories` con descripción sanitizada (`quote_document_sent`), sin el
   PDF ni el header `Authorization`.

## Riesgo transversal que el Arquitecto valida (regla de oro del protocolo)

- **`N8N_TOKEN` hardcodeado como default en `qualitas/views.py`** (pendiente de seguridad ya
  trackeado en `CLAUDE.md` desde antes) — con este feature deja de ser solo un problema de
  higiene: ese token ahora gatea el acceso a PDFs de cotización de clientes reales (URL firmada
  del documento). Sube de prioridad. Recomendación: rotar y mover a solo-env **antes** de activar
  este flujo en PROD, no después.
- **Secuencia de despliegue** — el propio doc de Juan ya lo advierte y coincide con mi lectura:
  si Wagtail se mergea/despliega a `main`/PROD con el default `resumen_quick_reply` **antes** de
  que n8n tenga la rama nueva lista, un cliente real recibe el resumen + botón, hace clic, y no
  pasa nada — el bot sigue conversando normal pero nunces entrega el PDF. Mismo patrón de riesgo
  que el casi-incidente de `checkpoint_followups` de anoche: un flag/feature adelantado sin su
  contraparte lista en el otro sistema. **No mergear `stg`→`main` en HYL-WAI hasta que n8n esté
  validado en staging**, coordinar explícitamente con Juan el orden.

## Alcance real del trabajo pendiente para Agente n8n

Menor de lo que sugiere el runbook completo de Juan — los pasos 1-2 de su "Orden recomendado de
implementación" (extracción de `button_reply.id`, parseo v1/v2) ya están hechos. El trabajo real
es la rama determinística de entrega (pasos 3 en adelante del runbook: `quoteDocumentAction`,
HTTP a Django, entrega a Meta, idempotencia, manejo de errores) — construir y validar en STG,
igual que cualquier otro cambio de este workflow.

## Pendiente

Sin handoff enviado todavía — pendiente de decidir con Alberto si se arma ahora o se prioriza
contra el filtro de horario de `checkpoint_followups` (ver `docs/iniciativas/seguimiento-leads-estancados.md`).
