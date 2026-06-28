# Estado Unificado de un Lead

## Lógica de estado (centralizada en `lib/metrics.js`)

```javascript
SI conversation_phase = 'completed'
  → PAGADO

SI qualitas_lead.estado = 'POLIZA_EMITIDA' Y conversation_phase = 'greeting' o NULL
  → Cerró por web (sin WhatsApp)

SI conversation_phase IN ('data_capture', 'summary_confirmation', 'policy_issuance', 'payment_pending')
  → En flujo WhatsApp activo

SI conversation_phase = 'greeting' Y estado = 'COTIZACION_INICIADA' Y fecha < NOW - 48h
  → ABANDONADO

SI conversation_phase = 'greeting' Y estado = 'COTIZACION_INICIADA' Y fecha >= NOW - 48h
  → EN ESPERA
```

## Fuentes de verdad por campo

| Campo | Fuente fiable | Fuente con bug |
|---|---|---|
| Estado de negocio | `qualitas_lead.estado` | — |
| Hitos conversacionales WA | `n8n_chat_histories` (BOOL_OR + LIKE) | `whatsapp_sessions.conversation_phase` |
| Póliza emitida | `qualitas_polizaemitida` | — |
| Pago confirmado | `qualitas_polizaemitida.estatus_pago` | — |

## Regla crítica

**Nunca usar `whatsapp_sessions.conversation_phase` como fuente de verdad.**
Siempre inferir la fase real desde `n8n_chat_histories`.
