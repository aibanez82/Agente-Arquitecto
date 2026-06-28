# Customer Journey — Dashboard de Leads Qualitas (Hylant)

> Mapeado contra la base de datos real de producción (Heroku Postgres Standard-0, exploración 21-22 jun 2026).

## Mapeo de estados confirmado

| `conversation_phase` | Estado Django | Término Hylant | Notas |
|---|---|---|---|
| `greeting` | `COTIZACION_INICIADA` | LEAD | WhatsApp enviado, lead aún no ha respondido |
| `data_capture` | `DATOS_EMISION_INICIADOS` | CONTESTAN | Lead respondió, dando datos por bloques |
| `summary_confirmation` | — | — | Bot muestra resumen, pide confirmación |
| `policy_issuance` | `DATOS_EMISION_COMPLETADOS` | — | Datos confirmados, emisión en curso |
| `payment_pending` | `POLIZA_EMITIDA` | PÓLIZAS EMITIDAS · PAGO PENDIENTE | Póliza emitida, link de pago enviado |
| `completed` | `PAGO_APROBADO` | PÓLIZA PAGADA | Pago confirmado, venta cerrada |

## Flujo conversacional WhatsApp

1. Bot envía PDF de cotización → `greeting`
2. Lead responde "Ok" → `data_capture`
3. Bot recopila datos por bloques:
   - Bloque 1: datos personales (nombre, fecha nacimiento, género, INE)
   - Bloque 2: datos fiscales y vehículo (factura, placas, VIN)
   - Bloque 3: domicilio (validado contra CP del motor tarifario)
4. Bot muestra resumen completo → `summary_confirmation`
5. Lead confirma → `policy_issuance`
6. Qualitas emite póliza → `payment_pending`
7. Pago confirmado → `completed`

## Grupos de leads para el dashboard

| Métrica | Definición |
|---|---|
| LEADS | Total de leads del período |
| CONTESTAN | `conversation_phase != 'greeting'` |
| EN ESPERA | `COTIZACION_INICIADA` + `greeting/null` + `fecha_creacion < 48h` |
| ONLINE | `POLIZA_EMITIDA` + `greeting/null` (cerraron por web sin WA) |
| VÍA WEB EN PROCESO | `DATOS_EMISION_INICIADOS` + `greeting/null` |
| PÓLIZAS EMITIDAS · PAGO PENDIENTE | `POLIZA_EMITIDA` + `conversation_phase != 'completed'` |
| PÓLIZA PAGADA | `conversation_phase = 'completed'` |
| ABANDONADOS | `COTIZACION_INICIADA` + `greeting/null` + `fecha_creacion > 48h` |

## Referencias

- Tablas: `qualitas_lead`, `qualitas_cotizacion`, `whatsapp_sessions`, `n8n_chat_histories`
- Credencial: `readonly_leads` en Heroku app `hyl-wai-production` (Standard-0)
