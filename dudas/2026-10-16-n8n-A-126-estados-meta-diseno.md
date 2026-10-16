# Duda — SESIÓN A · `#126`: dónde entran los estados de Meta en n8n, adónde van y qué hace falta de Juan

**De:** Agente n8n · A · **Para:** Arquitecto · **16 oct 2026**
**Orden:** `Agente-n8n:handoffs/2026-10-14-A-firmas-orden-prod-591-y-cola.md`, fila k. Primero, una duda de diseño.
**Alcance:** el veredicto de Alberto del 25 ago: **solo `failed` y `delivered`; `read` fuera desde el diseño.**
**Estado:** sin construir nada.

## Lo medido

1. **El bot tiene un único trigger de WhatsApp**, y hoy **descarta los estados**.
   - `WhatsApp Message Trigger` está con `updates: ["messages"]` y `messageStatusUpdates: []`, igual en STG `676069a3` y en PROD.
   - n8n filtra los `statuses[]` antes de que entren en el workflow.
   - Meta permite **una URL de webhook por app**, y el trigger de n8n la registra. Un segundo trigger en otro workflow le quitaría la URL al bot, así que **los estados tienen que entrar por este mismo trigger**.
2. **El pipeline del bot da por hecho que hay un `messages[0]`.**
   - Detrás del trigger vienen `Phone Number ID Guard` y `Register Inbound Turn`.
   - Un estado que siguiera ese camino reventaría o, peor, crearía turnos fantasma. Hace falta desviarlo **antes** de cualquier nodo del turno.
3. **Django:** `qualitas_whatsappmessage` ya tiene `provider_message_id` (el `wamid`), `status`, `sent_at`, `failed_at`, `error_code` y `error_message`. Lo medí en PROD el 25 ago: el `wamid` estaba en 1.927 de 1.928 filas.
   - El `wamid` del evento de estado es justo ese `provider_message_id`, así que la unión es directa.
   - Volumen de los últimos 30 días: **550** mensajes de Django.
4. **Los mensajes que manda el propio n8n NO están en esa tabla.**
   - Son las respuestas del bot, las fijas, las de descuentos y los PDF.
   - Están en `n8n_outbound_dispatch.provider_message_id`: **1.742** `sent` en los últimos 30 días, **3 veces más** que los de Django.

## Propuesta de diseño

- **Entrada.** En el trigger, `messageStatusUpdates: ["delivered", "failed"]`. `sent` no entra: ya lo sabemos por el 200 del envío.
  - Justo después de `Phone Number ID Guard`, un IF «¿es un estado?» (hay `statuses` y no hay `messages`).
  - Ese IF **deriva a un subworkflow aparte**, «Estados WhatsApp», con un `Execute Workflow` que no espera. Así el bot no carga con esa lógica y un fallo allí no toca un turno.
- **Normalización:**
  - `{schema_version: 1, wamid, status: delivered|failed, timestamp, errors: [{code, title, details}]}`;
  - **sin teléfono ni contenido**, como pide el `#126`.
- **Destino:** el endpoint interno de Django del `#127`, `POST`, con Bearer `N8N_TOKEN`. Es idempotente por `(wamid, status)`.
- **Fallos:** reintento acotado. Si no entra, queda en `console.error` y en la ejecución. **Sin tabla nueva de pendientes**, porque rige la contracción (`HYL-WAI#146`, C9: nada de instrumentación nueva).

## Lo que pregunto

1. **¿Los estados de los mensajes que manda n8n también van a Django?** Son 3 de cada 4 envíos. Hay dos opciones:
   - **(A)** Se reenvían todos. Django guarda también los `wamid` que no conoce, o devuelve `matched=false`. Tiene sentido si Django va a ser la fuente de verdad de **todos** los mensajes salientes, como dice el `#127`.
   - **(B)** Solo los de Django, y los de n8n se escriben en `n8n_outbound_dispatch`. Eso supone una columna nueva, `delivery_status`, y choca con la contracción.

   **Recomiendo (A):** un solo destino y nada de instrumentación nueva en n8n. Pero lo que haga Django con un `wamid` que no conoce lo decide Juan.
2. **¿Subworkflow aparte (propuesta) o carril dentro del bot?** El subworkflow aísla mejor, pero es un workflow más que mantener en STG y en PROD.
3. **El contrato del endpoint lo define Juan en el `#127`.** Lo que necesito de él:
   - la ruta;
   - el cuerpo;
   - los códigos de respuesta (`2xx` = guardado, `409` = duplicado, `404` = `wamid` desconocido, si elige la B);
   - y si quiere `errors[]` completo o solo `code` + `title`.

   ¿Se lo pides tú, o lo dejo en el `#126` como propuesta?

**Prueba en STG cuando toque:** con el número de prueba de STG, activar los estados solo en el trigger de STG, mandar un mensaje a Alberto o a un número de prueba de Meta, y comprobar que llegan `delivered` y, con un número inválido, `failed`.

Agente: Agente n8n · A
