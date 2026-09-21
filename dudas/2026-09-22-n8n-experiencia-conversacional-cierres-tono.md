# Paquete de experiencia conversacional — cierres, rechazos y tono (hallazgos de Alberto en PROD)

**De:** Agente n8n · **Para:** Arquitecto · **Fecha:** 22 sep 2026
**Origen:** Alberto revisando conversaciones reales de PROD (capturas). Te los agrupo porque comparten
raíz —el manejo de cierres/rechazos y el tono viven en el `systemMessage` del `AI Agent`— y por la
regla del ecosistema, un cambio ahí lo valida el **Agente Mejoras Conversación** y lo firma Alberto.
Yo he medido dónde nace cada uno; el diseño es tuyo/de Mejoras.

## 1 · Despedida tras derivación → el bot re-oferta (HYL-WAI #418, Alberto pidió señalártelo)
Cliente pregunta por estatus de una póliza emitida (fuera de alcance) → el bot deriva y ofrece seguir
con la cotización. Cliente cierra: «Okey agradezco la atención». El bot **re-oferta** la cotización.
Causa (medida, exec PROD 46790): el Intent Router no tiene categoría de despedida; cae en el default
`contracting` y con cotización activa el AI Agent retoma la venta. Esperado: reconocer la despedida y
cerrar sin insistir.

## 2 · «No, gracias» tras la cotización → cierra sin sondear la objeción (nuevo)
Cliente recibe el PDF con precio y responde «No, gracias». El bot cierra cortés («Entiendo que por
ahora no quieres continuar… cuando quieras retomarla, aquí estoy»). **Alberto quiere que, en ese
punto, sondee la objeción antes de rendirse**: preguntar si fue el precio o si tiene alguna duda.
Causa (medida): la regla `DECLINACIÓN EXPLÍCITA DEL LEAD` del `systemMessage` mete «No, gracias» en el
mismo saco que «no me escribas más» / «ya contraté con otra» → cierra la sesión y «no hagas preguntas
de seguimiento». **El matiz de diseño es tuyo:** distinguir un rechazo blando recién entregada la
cotización (una pregunta de objeción: precio/duda) de una declinación dura (respetarla, no insistir).
Ojo con la vigilancia inversa ya abierta (no volverse insistente / el «necesito un asesor»).

## 3 · «Tranquilo» cuando no se conoce el género (HYL-WAI #444, nuevo)
En captura de datos, antes de saber el género (lo está pidiendo), el bot dice «Tranquilo». El lead era
mujer. Causa (medida): es un ejemplo de tono en el `systemMessage` con el masculino hardcodeado, que el
modelo copia. Esperado: forma neutra («Tranquil@») o sin marca de género hasta conocer el dato.

## 4 · VIN mandado en ráfaga, ignorado (nuevo, EN DIAGNÓSTICO — funcional, no de prompt)
Cliente responde «Ok» y en el mensaje siguiente el VIN (`1HGCM56486A161211`, 17 chars válidos); el bot
**repite la misma pregunta del VIN** en vez de tomarlo. Esto huele a buffer de ráfaga (Wait Rafaga /
Buffer) que no juntó los dos mensajes, no a tono. Lo estoy midiendo en la ejecución; abriré issue
propio con la traza y te lo paso por separado — puede ser de ejecutor si es el buffer.

## Lo que propongo
Los tres primeros son de `systemMessage`/tono → para el Agente Mejoras Conversación con tu validación y
firma de Alberto; te los agrupo para que priorices. El cuarto lo cierro yo con diagnóstico y, si es el
buffer, es mío. Dime si quieres que prepare un arnés de aceptación (frases reales del corpus) para los
tres de tono cuando Mejoras traiga el copy.

— Agente n8n
