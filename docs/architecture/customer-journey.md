# Customer Journey — Dashboard de Leads Qualitas (Hylant)

> Mapeo confirmado contra la base de datos real de producción (Heroku Postgres Standard-0, exploración 21-22 jun 2026) y validado con el admin del sistema Django.

---

## Mapeo completo confirmado

El journey usa **dos tablas en paralelo**:

| Tabla | Campo clave | Fuente |
|---|---|---|
| `qualitas_lead` | `estado` | Django (estado de negocio) |
| `whatsapp_sessions` | `conversation_phase` | n8n (estado conversacional del bot) |

**Join:** `qualitas_lead → qualitas_cotizacion → whatsapp_sessions` vía `cotizacion_id / quotation_id`

---

## Mapeo de estados confirmado por el admin de Django

| `conversation_phase` | Estado Django equivalente | Término Hylant | Notas |
|---|---|---|---|
| `greeting` | `COTIZACION_INICIADA` | **LEAD** | WhatsApp enviado con cotización PDF del motor tarifario de Qualitas. El lead aún no ha respondido. |
| `data_capture` | `DATOS_EMISION_INICIADOS` | **CONTESTAN** | El lead respondió al WhatsApp y está dando sus datos (nombre, vehículo, domicilio) por bloques. |
| `summary_confirmation` | — | — | El bot muestra el resumen completo de todos los datos y pide confirmación final antes de emitir. |
| `policy_issuance` | `DATOS_EMISION_COMPLETADOS` | — | Datos confirmados, proceso de emisión en curso. **0 registros en producción actualmente** — fase aún no alcanzada. |
| `payment_pending` | `POLIZA_EMITIDA` | **PÓLIZAS EMITIDAS · PAGO PENDIENTE** | Póliza emitida por Qualitas, link de pago enviado. **0 registros en producción actualmente** — el sistema llega directamente de `completed` en el flujo actual. |
| `completed` | `PAGO_APROBADO` | **PÓLIZA PAGADA** | Pago confirmado. Venta cerrada. |

---

## Conteos en producción (22 jun 2026)

### `whatsapp_sessions` (activa)
| `conversation_phase` | Count |
|---|---|
| `greeting` | 67 |
| `data_capture` | 4 |
| `summary_confirmation` | 1 |
| `completed` | 1 |
| `policy_issuance` | 0 |
| `payment_pending` | 0 |

### `whatsapp_sessions_archive`
Vacío — el mecanismo de archivo aún no se ha activado.

---

## Grupos de leads para el dashboard

Todos calculados desde `whatsapp_sessions.conversation_phase` (fuente de verdad para el estado real del journey):

| Métrica dashboard | Definición | Fuente |
|---|---|---|
| **LEADS** | Total de leads del período | `qualitas_lead` (todos) |
| **CONTESTAN** | `conversation_phase != 'greeting'` | `whatsapp_sessions` |
| **EN ESPERA** | `COTIZACION_INICIADA` + `greeting/null` + `fecha_creacion < 48h` | ambas tablas |
| **ONLINE** | `POLIZA_EMITIDA` + `greeting/null` (completaron por web sin WA) | ambas tablas |
| **VÍA WEB EN PROCESO** | `DATOS_EMISION_INICIADOS` + `greeting/null` | ambas tablas |
| **PÓLIZAS EMITIDAS · PAGO PENDIENTE** | `POLIZA_EMITIDA` + `conversation_phase != 'completed'` | ambas tablas |
| **PÓLIZA PAGADA** | `conversation_phase = 'completed'` | `whatsapp_sessions` |
| **ABANDONADOS** | `COTIZACION_INICIADA` + `greeting/null` + `fecha_creacion > 48h` | ambas tablas |

---

## Hallazgo sobre PAGO_APROBADO

El lead 696 (Soraida Varas, WHATSAPP) apareció como `PAGO_APROBADO` en Google Sheets (capturado el 15 jun a las 16:35) pero actualmente está en `DATOS_EMISION_COMPLETADOS` en `qualitas_lead`. Tiene `poliza_id = 1718`. Posible bug: el estado retrocedió en Django después de haber llegado a `PAGO_APROBADO`. **Pendiente de investigar con el admin de Django.**

---

## Flujo conversacional WhatsApp (confirmado por capturas reales)

1. Bot envía PDF de cotización + "¿Continuamos? Responde este mensaje para continuar." → `greeting`
2. Lead responde "Ok" → `data_capture`
3. Bot recopila datos por bloques con mini-confirmaciones por bloque (comportamiento conversacional de n8n, sin estado propio):
   - Bloque 1: datos personales (nombre, fecha nacimiento, género, INE)
   - Bloque 2: datos fiscales y vehículo (factura, placas, VIN)
   - Bloque 3: domicilio (validado contra CP del motor tarifario)
4. Bot muestra resumen completo → `summary_confirmation`
5. Lead confirma → `policy_issuance` (emisión en Qualitas)
6. Qualitas emite póliza → `payment_pending` (link de pago enviado)
7. Pago confirmado → `completed`

---

## Referencias

- Tablas con acceso de solo lectura: `qualitas_lead`, `qualitas_cotizacion`, `qualitas_asegurado`, `qualitas_polizaemitida`, `whatsapp_sessions`, `whatsapp_sessions_archive`, `n8n_chat_histories`, `n8n_chat_histories_archive`
- Credencial: `readonly_leads` en Heroku app `hyl-wai-production` (Standard-0)
- Arquitectura de BBDD: ver `django-mirror-decision.md`
