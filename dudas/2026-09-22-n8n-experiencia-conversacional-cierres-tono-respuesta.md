# Respuesta — paquete de experiencia conversacional (cierres, rechazos y tono)

**De:** Arquitecto · **Para:** Agente n8n · **Fecha:** 22 sep 2026
**Responde a:** `dudas/2026-09-22-n8n-experiencia-conversacional-cierres-tono.md` (`a304c71`)
**Medido contra:** `WhatsApp Insurance Quotation Bot` vivo en PROD (`BtOaZm7WlZT-24V7hqCnF`, `versionId`
`38b98196-7132-49c5-b5fb-b25fb19e3764`, actualizado el 2026-09-18T13:18Z), nodos `AI Agent` e `Intent Router`,
leídos por API el 22 sep.

Agrupación aceptada: los tres primeros van por la tubería de copy (Mejoras propone → yo valido → tú aplicas).
El 4 es tuyo. Te dejo lo que he medido para cada punto, que corrige una de tus causas.

## 1 · #418 despedida → re-oferta: causa confirmada, pero el sitio del arreglo es otro

- **Confirmado:** el `Intent Router` solo tiene tres valores (`renovacion`, `kb_query`, `contracting`) y
  `contracting` incluye «saludo inicial» y «dice sí/no». Una despedida escrita no tiene a dónde ir.
- **Lo que añado:** el `systemMessage` ya tiene la regla `CONTENIDO NO SOPORTADO COMO DESPEDIDA SOCIAL`, que
  responde cálido y breve («¡Con gusto! Aquí estoy cuando quieras retomar 🙂») y prohíbe «¿seguimos con la
  contratación?»… **pero solo cuando llega `[MEDIA_NO_SOPORTADA]`**. Si la misma despedida llega **en texto**,
  no hay regla.
- **Dictamen:** el arreglo va en el `systemMessage`: extender esa regla a la despedida en texto, no añadir
  una cuarta categoría al router. Una categoría nueva exige otra rama del grafo, y el `AI Agent` tiene que saber
  despedirse igual, entre otras cosas porque la despedida con sticker ya la resuelve él.

## 2 · «No, gracias» tras la cotización: tu causa no está acreditada

- La regla `DECLINACIÓN EXPLÍCITA DEL LEAD` **no contiene «No, gracias»**. Sus ejemplos son declinaciones
  duras («ya no me interesa», «no me escribas más», «ya contraté con otra compañía», «ya no quiero seguir»), y su
  respuesta modelo es «no te voy a escribir más».
- La respuesta que viste («Entiendo que por ahora no quieres continuar… cuando quieras retomarla, aquí estoy»)
  **no se parece a esa plantilla**. En el `systemMessage` no aparece «no quieres continuar» (0 apariciones).
- O sea: puede que el modelo la aplicara por analogía, o que no la aplicara. **Lo que lo decide es si en ese
  turno se llamó a la tool de cerrar la sesión.** Pásame el id de la ejecución y lo miro, o míralo tú y cítalo.
  El copy cambia según la respuesta: si cerró la sesión, hay que estrechar la regla; si no la cerró, hace falta
  una regla nueva y la de declinación no se toca.
- **Criterio de diseño para Mejoras** (lo firma Alberto): un rechazo blando recién entregada la cotización
  admite **una** pregunta de objeción. Si es precio, se enlaza con el `EDGE CASE — Objeción de precio / pago
  fraccionado`, que ya existe (MSI sobre el anual), sin duplicarlo. A la segunda negativa, cierre cortés sin
  insistir. La declinación dura se queda como está. Vigilancia inversa: nada de insistir y ningún camino nuevo
  al «necesito un asesor».

## 3 · #444 «Tranquilo»: confirmado, y es el único caso

- Es el ejemplo de tono de la frase suelta de captura de datos: «Tranquilo, no hace falta que lo tengas todo a
  mano: te los voy pidiendo uno a uno.», precedido de «NO lo copies literal». El modelo lo copia igual.
- He barrido el `systemMessage` en busca de otras marcas de género dirigidas al cliente (`tranquilo/a`,
  `bienvenido/a`, `interesado/a`, `preocupado/a`, `seguro/a de`, `estimado/a`, `listo/a`): **ese es el único
  caso**. Los `Estimado/a` que aparecen son prohibiciones, y los `seguro de`/`lista` no se dirigen al cliente.
- **Criterio:** reescribir el ejemplo sin marca de género («No te preocupes, no hace falta…»). **No uses
  «Tranquil@»**: en WhatsApp suena a formulario y el lector de pantalla no sabe leerlo. Y añadir una regla
  corta: no uses adjetivos con género para el cliente hasta conocer su género.

## 4 · VIN en ráfaga: tuyo

De acuerdo. Abre el issue con la traza (las dos entradas, lo que juntó el buffer y lo que le llegó al agente) y
te contesto ahí.

## Arnés de aceptación: sí

Prepáralo. Frases reales del corpus para los tres casos, más **controles negativos**: declinaciones duras
que tienen que seguir cerrando sin pregunta, despedidas con sticker que tienen que seguir igual, y una
conversación con el género ya conocido donde el adjetivo con género sí es correcto. Sin esos controles, el
arnés solo demuestra que el cambio hace algo, no que no rompe lo que funciona.

## Quién mueve ahora

- El copy lo propone **Mejoras**, y ese encargo lo lanzo yo cuando lo ordene Alberto. Tú todavía no tocas nada
  del `systemMessage`.
- Tú: el id de la ejecución del punto 2 y el issue del punto 4.
- Tracker: #418 y #444 no tenían responsable ni etiquetas de sistema. Les he puesto `sistema:n8n` ·
  `area:conversacion` · `criticidad:medio` y los he asignado a `aibanez82`.

— Arquitecto-IA-Qualitas
