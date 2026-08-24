# Adenda al informe F6 — revert verificado E2E, y el followup legacy observado con hora y fila

> Agente n8n · 24 ago 2026. Completa `2026-08-24-n8n-f6-smoke-rojo-paso1-revertido.md`.

## El revert, verificado con un mensaje real (03:35 UTC)

Alberto escribió al bot revertido. Las tres fuentes:

1. **n8n**: ejecución **9767**, `status=success`, **11,1 s** (03:35:30 UTC) — la primera ejecución
   buena de PROD desde el 20 ago.
2. **`n8n_chat_histories`**: filas 10738–10741 — turno humano (ctx qid=3501, FORD EDGE 2020),
   llamada a `Get_Quotation_Data` (contra el Django de PROD), y la respuesta del agente.
3. **`qualitas_whatsappmessage`**: sin fila para esta respuesta, y es LO ESPERADO — el bot de 119
   envía directo por el nodo WhatsApp y no registra en esa tabla; ese registro es parte de la capa
   S1 que llega con el candidato. La entrega la acreditan la ejecución en success y la recepción
   confirmada en el teléfono.

**El bot vivo de PROD queda verificado post-revert: VERDE.**

## Observado, no buscado: el followup legacy disparó sobre el lead del smoke

| fila | template | hora UTC | contexto |
|---|---|---|---|
| 1922 | `saludos_inicial_sin_pdf_con_boton` | 03:11:36 | el WhatsApp inicial de la cotización 3501 (lead 2049) — el «primer WhatsApp» del paso 1 |
| **1923** | **`cotizacion_followup_15m`** | **03:20:26** | **el followup legacy, disparado ~9 min después de crearse la cotización, en mitad de la ventana muerta del smoke** (bot revertido a las 03:15, sin actividad del cliente desde las 03:11) |

Matiz honesto: no es exactamente la reproducción del `#204` tal como está descrito (followup
cayendo sobre conversación VIVA), porque aquí la conversación estaba muerta por el outage — un
followup sobre conversación inactiva es su comportamiento nominal. Lo que sí acredita, con fila y
hora: **el scheduler legacy está activo, alcanza a leads recién creados en ~9 min (no 15), y
conviviría con el carril de descuentos del candidato en cuanto F4 se reintente.** La ventana del
`#204` es real y está medida.

El lead 2049 / cotización 3501 / conversación quedan **sin tocar**, como evidencia. Si hay que
dejar esa sesión sin seguimientos pendientes, es una acción que pido antes de ejecutar.
