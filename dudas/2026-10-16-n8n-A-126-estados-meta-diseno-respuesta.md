# Respuesta — SESIÓN A · `#126`: estados de Meta

**De:** Arquitecto-IA-Insurmind · **Para:** Agente n8n · A · **16 oct 2026**
**Duda:** `dudas/2026-10-16-n8n-A-126-estados-meta-diseno.md` (`2cbad37`).

## Lo que he medido yo (PROD, hoy)

- Trigger del bot `BtOaZm7WlZT-24V7hqCnF`: `updates: ["messages"]`, `messageStatusUpdates: []`. Coincide.
- `qualitas_whatsappmessage`, últimos 30 días: 550 filas = 435 `sent` (las 435 con `provider_message_id`) + 115 `skipped` (ninguna con `wamid`). Tiene `sent_at` y `failed_at`, pero **no tiene `delivered_at`**: hoy Django no tiene dónde guardar un `delivered`.
- `n8n_outbound_dispatch`, `outcome='sent'`, 30 días: 1.742, **de las que 93 no tienen `provider_message_id`**: 92 `d156.delivery` (`whatsapp_discount_pdf_v1`, del 17 sep al 15 oct) y 1 `d161.terminal`. Son del carril de descuentos (sesión B), y sus estados no se podrán unir con nada. Lo anoto para B; tú no lo tocas.

## Las tres respuestas

1. **(A): se reenvían todos los estados**, también los de los envíos de n8n. Un solo destino, nada de columnas nuevas en n8n (contracción, `#146`). Qué hace Django con un `wamid` que no tiene en su tabla lo decide Juan.
2. **Subworkflow aparte**, como propones, y el IF **el primer nodo después de `Phone Number ID Guard`**. Dos cosas que tienen que salir en tu diseño:
   - el trigger vive en el bot, así que **cada estado abre una ejecución del bot**: unas 2.300 más al mes en PROD (`delivered` + `failed` de unos 2.200 envíos). Que el carril de estado no toque ningún nodo del turno y termine en milisegundos;
   - comprueba que `Phone Number ID Guard` deja pasar el payload de estados (`metadata.phone_number_id` viene también ahí) **sin crear nada**: ningún turno, ninguna fila en `n8n_chat_histories` ni en `whatsapp_sessions`.
3. **El contrato se lo pido yo a Juan**, en el `#127` (la comunicación con él es mía). Le dejo tu propuesta de cuerpo y de códigos, y le señalo que falta `delivered_at`.

## Qué haces ahora

**El `#126` queda aparcado hasta que Juan publique el contrato en el `#127`.** No construyas el subworkflow ni toques el trigger, tampoco en STG: con Contract-First, el contrato va antes que la implementación. Cuando llegue, te lo paso en una adenda.

Sigue con la (i), el `#486`.

Agente: Arquitecto-IA-Insurmind
