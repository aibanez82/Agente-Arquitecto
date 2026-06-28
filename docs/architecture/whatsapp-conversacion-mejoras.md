# WhatsApp — Mejoras de Conversación Pendientes

## Problemas identificados

### 1. conversation_phase no se actualiza (Bug crítico)
El campo `whatsapp_sessions.conversation_phase` se queda en `greeting` aunque 
la conversación haya avanzado.

**Workaround actual:** leer hitos reales desde `n8n_chat_histories` con BOOL_OR + LIKE.
**Solución definitiva:** n8n debe actualizar `conversation_phase` en Django en cada etapa.

### 2. TEST_EMAILS no filtrados en n8n
Los leads de prueba reciben mensajes de WhatsApp — Meta los cobra igual.
**Solución:** agregar nodo IF en n8n antes del envío que filtre contra lista TEST_EMAILS.

### 3. 4 leads reales sin whatsapp_session
Leads con teléfono válido que nunca recibieron mensaje de WhatsApp:

| ID | Email | Teléfono | Fecha | Estado |
|----|-------|----------|-------|--------|
| 837 | chrisjv_18@live.com | 7751535147 | 2026-06-23 23:26 UTC | DATOS_EMISION_INICIADOS |
| 834 | nieblaoctavio3@gmail.com | 6673299200 | 2026-06-23 21:28 UTC | COTIZACION_INICIADA |
| 810 | cecisarara@gmail.com | 4443320860 | 2026-06-22 19:43 UTC | COTIZACION_INICIADA |
| 802 | arelicerontrejo@gmail.com | 5574548758 | 2026-06-22 18:39 UTC | COTIZACION_INICIADA |

**Pendiente:** revisar logs de n8n en esas fechas con Juan Aguayo.

### 4. Prefijo 57 en session_id
session_id usa prefijo Colombia (57) en lugar de México (52).
Afecta solo leads de prueba de Juan Aguayo (tabla NumeroPruebaWhatsapp).

## Mejoras futuras

- Campos booleanos explícitos en BD para hitos WA (en lugar de LIKE frágil sobre n8n_chat_histories)
- Reactivar Cache-Control en db-leads.js cuando el dashboard esté estabilizado
