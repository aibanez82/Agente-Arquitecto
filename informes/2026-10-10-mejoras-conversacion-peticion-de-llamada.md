# Mejoras Conversación → Arquitecto: el cliente quiere hablar por teléfono

**Fecha:** 10-oct-2026 · **Autoriza:** Alberto (10-oct) · **Caso:** qid 4379, sesión `waq_4379_36bcd686140e`, PROD 9-oct
**Tubería:** valida el Arquitecto contra el grafo vivo, aplica el Agente n8n en STG y luego PROD. Es copy y no hay nada técnico roto, así que no va al tracker.

## Objetivo (palabras de Alberto)
> El objetivo es calmarlo y que siga la conversación por WhatsApp. Desde ese canal le podemos resolver todas las dudas y, sobre todo, obtener un mejor precio que si llama por teléfono.

## Qué pasó en el caso
El cliente estaba listo para contratar: recibió el descuento (Amplia anual de $8,781.87 a $7,880.90) y preguntó por coberturas, pago semestral y fechas de pago. Lo perdimos porque quería llamar:

| id | Cliente | Bot |
|---|---|---|
| 14859–14874 | «Le llamo del …» / «le marco y manda a buzón» / «le estoy llamando de este número» / «para la contratación pero no me responde» | Cuatro variaciones de «por este medio seguimos… ¿seguimos aquí?». Nunca le dice que el número no recibe llamadas |
| 14875–14882 | «Quiero llamar» / «Quiero que me llamen» / «no sé por qué no puedo recibir una cotización más personal» | Tres veces el **mismo texto, palabra por palabra**: enlace de WhatsApp de un agente especializado |
| 14883–14886 | «Tengo dudas y usted no me quiere responder» → «Olvídelo» | «cuéntame cuál es tu duda» → despedida pasiva |

Las dudas estaban resueltas. Lo que lo hizo irse fue sentirse ignorado: ninguna respuesta atendía lo que pedía.

## Textos (estilo «Carla», tuteo, sin adjetivos con género)

**A. Primera mención de llamada o buzón** («le llamo», «le marco», «me manda a buzón», «no contestan»):
> Perdona la confusión: este número es solo de WhatsApp, por eso no entran las llamadas. Pero por aquí te atiendo igual de rápido y sin esperas, y además con el precio preferencial que solo tenemos en este medio. Dime qué te falta y lo resolvemos ahora mismo.

**B. Petición expresa de llamada** («quiero llamar», «quiero que me llamen», «prefiero por teléfono»):
> Te entiendo, a veces es más fácil hablarlo. Solo te cuento por qué te conviene seguir aquí: por WhatsApp te respeto el precio con descuento que ya tienes ($7,880.90), que por teléfono no aplica, y resolvemos todo en unos minutos, sin esperar a que te devuelvan la llamada. ¿Qué duda tienes? Respóndeme aquí y te la aclaro al momento.

(La cifra sale de la cotización vigente, no va fija). **Pendiente:** Alberto le está preguntando a Hylant qué contestar en este escenario, y B puede cambiar con esa respuesta. Mientras tanto aplica el objetivo de arriba. Sí hay devolución de llamada (Montserrat, de Hylant), pero no se ofrece salvo que Hylant lo indique.

**C. Queja de no ser atendido** («no me quiere responder», «nadie me contesta», «no me hace caso»):
> Tienes razón, perdóname: te insistí y no te escuché bien. Vamos a lo tuyo: ¿tu duda es sobre el pago, la cobertura o algo más? Te contesto aquí mismo.

**D. Cuando el cliente pregunta por dividir el pago** (semestral, trimestral o mensual): responde a lo que preguntó y, junto, pone las cifras de meses sin intereses de la anual:
> Sí se puede semestral: $4,543.91 y luego $3,650.72 ($8,194.63 en total). Aunque te conviene más la anual de $7,880.90 a meses sin intereses con tarjeta de crédito participante: 6 pagos de $1,313.48 o 12 de $656.74, sin costo extra. ¿Cuál te acomoda?

Las cifras de meses sin intereses salen de dividir la prima anual entre 3, 6 o 12. Si se menciona algún banco, que sea según la KB: **BBVA participa en 3 y 6 meses, no en 12**. En el caso (14852) el bot puso a BBVA en la lista de 12 meses.

## Reglas que acompañan al copy
1. **A se usa una sola vez por sesión.** Si el cliente vuelve a hablar de llamar, se pasa a B. Si insiste después de B, no se vuelve a defender el canal: se responde a la duda si la hay o se aplica C. Nunca más de dos defensas del canal seguidas.
2. **Cuando pide una llamada, no se manda el enlace de WhatsApp del agente especializado como respuesta:** es otro chat, no una llamada, y al cliente le suena a que lo están mandando a otro lado.
3. **No repetir el mismo mensaje palabra por palabra** dentro de la misma sesión. Si la situación se repite, se cambia el enfoque, no solo la redacción.
4. Ninguno de los textos usa las 5 cadenas de los detectores de hitos (`continuamos con`+`cobertura`, `tengo`+`Nombre:`, `Placas`+`Serie:`, `*Domicilio:*`, `emitida exitosamente`).

## Preguntas para validar contra el grafo
- ¿Hoy qué decide la respuesta de 14876, 14878 y 14882: el EDGE CASE de escalamiento del AI Agent, el Intent Router o el RAG? La última llegó tras `search_knowledge_base1`.
- ¿Choca B con M26 (defender WhatsApp frente a la oficina física)? La idea es que sea su hermana: mismo argumento de precio, para el teléfono.

Agente: Mejoras Conversación
