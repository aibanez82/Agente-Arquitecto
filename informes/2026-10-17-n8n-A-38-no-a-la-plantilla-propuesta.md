# n8n · A → Arquitecto: firma 38 (versión B, «No» a la plantilla de Recovery). Medición y propuesta de mecanismo

**Fecha:** 17-oct-2026 · **Orden:** `Agente-n8n:handoffs/2026-10-14-A-firmas-orden-prod-591-y-cola.md`, adendas 16 y 17 (`82a050a8`).

**No he tocado nada. 0 llamadas a modelo.** He leído:
- el bot vivo de STG (`606da14f`) y el de PROD (`1265f994`);
- la BD de PROD, en solo lectura;
- `HYL-WAI` en `origin/main`.

**Acuse de la adenda 17:** la 40 queda aprobada como dices. «Otra ciudad» cuenta. «Con placas de estado de México» va como control negativo y «Cambié de placas, del Estado de México» como positivo. La regla del precio va al prompt de los dos agentes, acotada a residencia / CP / ciudad. Y viaja con el `#608`.

## Lo medido
- **La plantilla solo tiene un botón,** el quick reply `recovery-<participante>` («Ver promo»), según `recovery_campaign_sender.py:955-974`. Así que **un «No» siempre llega como texto libre.**
- **Hoy, ningún nodo reconoce ese «No».** Está en `waq_4521` (16375): fue el primer mensaje del cliente, y la respuesta fue «Tuvimos un problema», por la cuota.
- **El `#418` no lo cubre:**
  - `clasificaDespedida` devuelve `null` en el primer mensaje («no hay ultimoBot», G2).
  - También devuelve `null` con todo lo que empieza por «no»: es el rechazo blando del `#461`.
- **«Fuera de los seguimientos de la campaña».** El seguidor de Recovery de Django (`whatsapp_checkpoint_followups.py`) corta en dos casos:
  - la sesión de n8n no está `open`/`active` (línea 2801);
  - el teléfono tiene `MarketingContactPreference` en `opted_out` (2902-2916).
- **El endpoint de baja ya existe:** `POST /api/v1/n8n/recovery/opt-out` (`recovery_n8n.py:1902`, `urls.py:37`).
  - `action` = `marketing_opt_out`, `reason` ∈ {`user_requested`, `meta_marketing_stopped`, `operator_recorded`}.
  - Lleva los mismos campos comunes que `request_quote_pdf`.
  - **Verificado en destino:** sin credencial responde 401 en STG y en PROD. Una ruta inexistente responde 301, así que la ruta existe en los dos.
  - **Ningún nodo lo llama todavía,** ni en STG ni en PROD.

## Mecanismo propuesto
1. **Detección en `Parse Router Output`,** sin tocar el prompt del router, como el enganche (A) de la adenda 22. Se crea un flag `recoveryNoPlantilla` que exige las tres cosas:
   - una sesión `recovery_solo_contexto`;
   - **ninguna fila `ai` previa del bot en la sesión**, para que el «No» conteste a la plantilla y no a una pregunta del bot;
   - el mensaje entero es un rechazo: «no», «nop», «nel», «no gracias», «no me interesa», «no estoy interesado/a», «ahorita no», «por ahora no», «no quiero», «no necesito», «no tengo interés», con «gracias» opcional al final.

   Es una lista de mensaje completo, igual que los patrones de precio. Así «no me aparece», «no sé» o «no entiendo» **no** entran: «no me aparece» va al enganche (A).
2. **La frase la monta el grafo,** con las mismas piezas que la 13.2:
   - `[VEHÍCULO]`;
   - `[FECHA]`, de `issued_at`;
   - `[FECHA_INICIO]`, del XML de la cotización;
   - el formato de fecha sin año cuando es el año en curso;
   - **sin la cláusula** si falta un dato.

   Por eso va con la 13.2: es la misma función de frases, con una variante más.
3. **Un carril propio, `Recovery No Plantilla`,** clonado del de envío de `Recovery Ver Promo`: Claim, filas human y ai, Send y Settle, sin cambios.
   - Lo clono porque los nodos de envío de Ver Promo leen `$('Recovery Ver Promo Copy')` directamente. Reusarlos obligaría a tocar lo que ya está acreditado.
4. **El segundo «No»:**
   - Si la sesión ya tiene la 38, es decir, una fila `ai` que empieza por «Entendido, no te insisto.», y el mensaje es otro rechazo, va **D1 del `#418`**.
   - D1 se manda por el carril de despedida fija que ya existe, con su texto literal.
5. **El «Sí» después de la 38:**
   - Si la última fila `ai` es la 38 y el mensaje es un sí corto («sí», «va», «dale», «claro», «ok»), entonces `recoveryVerPromo` = verdadero.
   - Eso lo lleva al carril de la adenda 20, que hace `request_quote_pdf` por texto, sin depender del clasificador.
6. **Fuera de los seguimientos: la baja va con el PRIMER «No»,** no con el segundo.
   - La 38 dice «no te insisto». Un seguimiento automático después la contradiría.
   - **«No contesta»** no genera ningún turno en n8n, así que no hay dónde poner la baja si se espera al segundo «No».
   - **Cómo:** un nodo HTTP lateral detrás de `Settle … Sent` de la 38, que solo corre si el mensaje salió. Hace `POST opt-out` con `reason=user_requested`.
     - El participante, la campaña y el outbound salen del Lookup de la adenda 20, ampliado con dos columnas.
     - El `event_id` se deriva del wamid del «No», así que es idempotente.
   - Si la baja falla, el mensaje ya salió. Queda una fila en un ledger para revisarla, sin reintentos ni otro mensaje al cliente.
   - **Alternativa descartada:** cerrar la sesión (`Mark Session Closed`) también corta los seguimientos, pero choca con el `#285` (sesión closed sin respuesta), que está en pausa.

## Lo que necesitas decidir
1. **¿Baja con el primer «No» o con el segundo?** Recomiendo el primero, por lo de arriba.
   - **Ojo:** `opt-out` es una **baja promocional del teléfono**. `opt_out_marketing_contact` suprime a todos los participantes de ese dueño, así que deja fuera también campañas futuras, no solo los seguimientos de esta.
   - Si eso es más de lo que quiere Alberto, la alternativa es pedirle a Juan una marca más estrecha, por participante. Eso sí sería pieza de Django.
2. **«Ya tengo seguro», «ya contraté con otro».** La 38 diría «hoy tu auto no tiene seguro vigente», que para ese cliente es falso.
   - Mi propuesta: **excluirlos** de la 38. Irían a D5 del `#418` («Gracias por avisarme…»), igual que su clase `definitiva`, y con baja.
   - Hoy D5 no sale en el primer mensaje (G2). Para Recovery, habría que permitirlo.
3. **El «No» que contesta a una pregunta del bot** (por ejemplo, «¿Te cuento cuánto queda?» de la 13.2). Según la firma, eso **no** es el «No» a la plantilla, y lo dejo al modelo. ¿De acuerdo?

**Arnés**, cuando toque, detrás del E2E del `#551` y con la 13.2:
- **Sin modelo:** el detector en node con frases reales y sintéticas, y la función de frases.
- **Con modelo:**
  - 4 casos, N≤3: «No», «No gracias», el «No» seguido de «No» (que da D1) y el «No» seguido de «Sí» (que da el PDF);
  - una regresión N=1: «no me aparece».
- **Unas 25 llamadas.**
- **La baja va contra Django STG** con el participante limpio, y se anuncia antes, porque tiene efecto sobre ese teléfono.

Agente n8n · A
