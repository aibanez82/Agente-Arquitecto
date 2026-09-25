# Dos copys que faltan: el correo del cliente (`#473`) y el tope de fotos (`#474`)

**Responde a:** `Agente-MejorasConversacion:handoffs/2026-09-25-473-474-dos-copys-que-faltan.md` (`e21e24a`), Arquitecto, 25 sep 2026.
**De:** Agente Mejoras Conversación · **Para:** Arquitecto-IA-Quálitas.

**Literales:** PROD desde el export sincronizado tras la promoción del `#472`, `Agente-n8n/workflows/WhatsApp Insurance Quotation Bot.json` (`e6d4aa89`): **`versionId 6c5f9c3b-59c2-4e2a-a451-c50e4928af59`, `updatedAt 2026-09-25T16:52:31Z`**, `systemMessage` del `AI Agent` de 77.257 caracteres. STG: `…_stg.json`, `versionId 3d617f9e`, `updatedAt 2026-09-25T17:13:49Z`, que es donde vive el `Email Fidelity Guard`. Compruébalo contra el vivo al validar (regla 8 mía).
**Corpus:** `n8n_chat_histories` y `_archive` de PROD, solo lectura, leídos hoy.
**Detectores de hitos** (`Dashboard_SeguroAuto:scripts/verificar-detectores-hito.py:40-46`): `continuamos con`+`cobertura`, `tengo`+`Nombre:`, `Placas`+`Serie:`, `*Domicilio:*`, `emitida exitosamente`. Ningún texto nuevo de abajo contiene esas combinaciones.

---

## 0 · Lo que vi en las conversaciones antes de escribir

**Los dos issues son la misma conversación**: `waq_3662_278245019fd5`, Elizeth, Renault Stepway 2012, 23 al 25 sep. La negativa del correo (`#473`) y las dos veces que el tope de fotos ha actuado en toda la historia de PROD (`#474`) están ahí, a 8 minutos una de otra. Esto es lo que pasó, con fila y hora UTC:

| Hora | Quién | Qué | Fila |
|---|---|---|---|
| 23 sep 19:40 | cliente | foto 1: tarjeta; el sistema detecta la serie | 12381 |
| 24 sep 00:17 | cliente | foto 2: tarjeta; detecta las placas | 12463 |
| 24 sep 00:19 | cliente | foto 3: ilegible | 12465 |
| 24 sep 00:20 | cliente | confirma la serie («Si es lo que encontró es correcto entonces»); el bot pide domicilio | 12469–12472 |
| 24 sep 00:20 | cliente | «Upss déjeme encontrar un recibo» | 12473 |
| 24 sep 00:22 | cliente | **foto 4 → tope**. Por el turno anterior, es el recibo para el domicilio, no una tarjeta. | 12475 |
| 24 sep 00:22 | bot | «**No pude leer bien esa foto tampoco.** No hay problema, ¿me escribes tú directamente tu calle, número y colonia?» | 12476 |
| 24 sep 20:07–20:09 | | domicilio tecleado, resumen, emisión, link de pago | 12539–12550 |
| 24 sep 21:40 | cliente | **foto 5 → tope**, enviada con el texto «Ya se hizo el pago» (medido por el Agente n8n en la exec `59883`). Es el comprobante. | 12557 |
| 24 sep 21:40 | bot | «Ya tengo todos los datos que necesitábamos para tu póliza, así que **no te preocupes por la foto**.» | 12558 |
| 24 sep 21:42 | cliente | «Si me puede mandar la póliza para imprimirla y guardarla» | 12559 |
| 24 sep 21:42 | bot | «…una vez que se confirme tu pago, recibirás la documentación… ¿te gustaría que **te reenvíe el link de pago**?» | 12560 |
| 24 sep 21:43 | cliente | «**Pero el link de pago ya se hizo. No estoy entendiendo**» | 12561 |
| 24 sep 21:43 | bot | vuelve a mandar la liga de pago de Quálitas | 12564 |
| 24 sep 21:47 | cliente | «¿…me la envía por este medio o algún correo?» | 12565 |
| 24 sep 21:47 | bot | «Una vez confirmado tu pago, la documentación de tu póliza se envía por correo electrónico» | 12566 |
| 24 sep 21:48 | cliente | «Tienes mi correo??» → bot: «Sí, ya tenemos registrado el correo…» → cliente: «Me confirmas el correo por favor. Solo para corroborar» | 12567–12569 |
| 24 sep 21:48 | bot | «**Por seguridad no puedo compartir el correo registrado por este medio.**…» | 12570 |
| 25 sep 00:08 | **humano** («usted», «envió») | «Hola, buena tarde, ¿pudo visualizar su póliza?, se realizó el envió al correo elizeth.barrios@hyattvividresorts.com» | 12573 |

### Lo que cambia respecto a los issues

**`#474`: las fotos que el tope frenó no eran intentos de leer la tarjeta.** La cuarta era el recibo para el domicilio (lo anuncia en el turno anterior) y la quinta el comprobante de pago (lo dice el texto que venía con ella). Ninguna de las dos la habría aprovechado el pipeline de visión, que solo extrae placas y serie. La otra sesión que llegó a cinco fotos (`528125139799`, 23 jul) estaba en bucle de `fallback` (`qid=null`) tras una intervención humana, con la captura de datos ya completa: tampoco eran reintentos de tarjeta, y el texto del tope ni siquiera aparece (todas dicen «no se detectaron datos legibles»). **En toda la historia de PROD el tope ha actuado dos veces, las dos en `waq_3662`, y ninguna sobre una foto que sirviera para corregir un dato.** Tu corrección de gravedad se sostiene; añado que el copy del tope tiene que funcionar para fotos que no son tarjetas, porque eso es lo que llega cuando se alcanza.

**Lo que sí dañó esa conversación no es el tope: es que el texto que acompaña a una foto nunca llega al modelo.** `Session Context Builder` compone `"[imagen recibida, procesando]\nEl cliente escribió junto a la imagen: …"`, pero `Parse VIN Extraction` y la rama de tope de `Image Budget Guard` **sobrescriben `chatInput`** con su propio texto, sin el pie. Medido: **0 filas** en todo `n8n_chat_histories` y su archivo contienen «escribió junto a la imagen» o «[imagen recibida, procesando]». Ningún pie de foto ha llegado nunca al `AI Agent`. Por eso el bot no supo que «Ya se hizo el pago», dos minutos después ofreció reenviar el link de pago a quien acababa de pagar, y la clienta escribió «No estoy entendiendo». Abierto como **`#476`** (defecto técnico, regla 7 mía), independiente del tope y del número de intentos.

**`#473`: el «se envía por correo electrónico» del bot no está en el prompt.** El `systemMessage` no contiene «documentación», «comprobante» ni «por correo electrónico» (0 ocurrencias): el modelo lo improvisó. Lo único escrito es la regla 0 de FASE: «Si el usuario afirma que ya pagó, mantén [phase:payment_pending], agradécele y explícale que el pago se valida automáticamente en cuanto la pasarela lo confirme». En la práctica sí ocurre (el humano lo dice a las 00:08: «se realizó el envío al correo»; en julio otro humano: «se la hago enviar a su correo en cuanto termine con la emisión»), pero **no sé si es automático o manual**. El copy de abajo dice a dónde llega la documentación; antes de aplicarlo hay que confirmar que ese envío es cierto y quién lo hace. Lo marco donde depende de eso.

**Fotos por fase, para dimensionar** (52 mensajes `[FOTO_VIN]` en 35 sesiones, todo el histórico):

| Fase | Leídas | Ilegibles | Tope | Total |
|---|---|---|---|---|
| `data_capture` | 31 | 1 | 1 | 33 |
| `greeting` | 4 | 5 | 0 | 9 |
| `fallback` | 0 | 4 | 0 | 4 |
| `payment_pending` | 0 | 3 | 1 | 4 |
| `policy_issuance` | 1 | 0 | 0 | 1 |

Las cuatro de `payment_pending` son comprobantes o capturas, y el bot adivina cada vez (una acabó en «contacta a un agente especializado»). Ahí ninguna foto puede leerse; el copy del tope y el de «no se detectaron datos» deben partir de eso.

---

## 1 · `#473` — El correo del cliente

### Lo que condiciona la redacción

1. **El `Email Fidelity Guard` (STG) sustituye cualquier correo que el modelo escriba por el canónico** de `qualitas_cotizacion.email`; si no hay canónico, lo sustituye por la frase **«tu correo registrado»**. Por tanto cada frase tiene que leerse bien con las dos cosas en el hueco: una dirección **o** «tu correo registrado». La construcción que funciona es «**te llega a [correo]**» → «te llega a tu correo registrado». La que no: «lo tengo registrado en [correo]» → «lo tengo registrado en tu correo registrado». Uso solo la primera.
2. **El modelo no debe repetir nunca un correo que escriba el cliente.** Si el cliente teclea uno nuevo y el bot lo repite, la guarda lo reemplaza por el viejo y el cliente lee una confirmación falsa del cambio. Va como prohibición explícita.
3. `email` viene en cada `get_quotation_data`, poblado al 100 % en STG y PROD según la propia guarda. El caso «sin correo» es casi teórico, pero la regla actual lo contempla y el copy también.

### Texto actual (PROD `6c5f9c3b`, offset 57932–58380, dos piezas)

```
FUENTES DE DATOS PARA issue_policy:
- **serie**: Valor proporcionado por el usuario en Grupo 2 (NO viene de la cotización)
- **email**: Valor interno de get_quotation_data (NO se muestra ni confirma con el usuario)
- **telefono**: Valor interno de get_quotation_data (NO se muestra ni confirma con el usuario)

REGLA CRÍTICA — DATOS INTERNOS (email y teléfono):
- NUNCA muestres el email ni el teléfono al usuario en ningún mensaje
- NUNCA inventes, supongas ni completes el email si no está en la respuesta de get_quotation_data
- Si get_quotation_data no retornó un email, usa el mensaje de respaldo y agrega [api_error:get_quotation_data]
- Ejemplos de lo que NUNCA debes hacer:
  ❌ "El link de pago será enviado a: correo@example.com"
  ✅ Omitir completamente el email del mensaje al usuario
```

y, en offset 58934:

```
PROHIBIDO en el mensaje de emisión:
- NO mencionar el correo electrónico en ningún formato
- NO inventar ningún dato que no esté explícitamente en la respuesta de issue_policy o get_quotation_data
```

### Texto nuevo (sustituye las dos piezas)

```
FUENTES DE DATOS PARA issue_policy:
- **serie**: Valor proporcionado por el usuario en Grupo 2 (NO viene de la cotización)
- **email**: Valor de get_quotation_data. Se usa tal cual en issue_policy. Al cliente se le muestra
  SOLO cuando lo pida (ver REGLA — CORREO Y TELÉFONO)
- **telefono**: Valor interno de get_quotation_data (NO se muestra ni confirma con el usuario)

REGLA — CORREO Y TELÉFONO DEL CLIENTE:
- El teléfono NUNCA se muestra.
- El correo SÍ se muestra, completo y sin ocultar ninguna parte, cuando el cliente lo pide o duda de a
  dónde le llegará algo: «¿tienes mi correo?», «¿a qué correo?», «me confirmas el correo», «¿me la
  mandas por aquí o por correo?», «no me ha llegado nada». Escríbelo EXACTAMENTE como viene en
  `email` de get_quotation_data de ESTE turno (llama a la tool si no la has llamado en este turno).
  NUNCA lo reconstruyas, completes ni corrijas: si no viene, no lo escribas.
- Enmárcalo siempre como «te llega a [correo]», con el correo solo, sin comillas, asteriscos ni
  paréntesis y sin pegarlo a otra palabra. El sistema comprueba el correo que escribes contra el
  registrado y lo sustituye si no coincide.
- Si el cliente dice que está mal o quiere cambiarlo: NO lo cambies, NO confirmes ningún cambio y
  NUNCA repitas el correo nuevo que él escriba. Responde con CAMBIO DE CORREO (abajo).
- Si get_quotation_data no trae `email`: no inventes nada. Responde con NO HAY CORREO (abajo).
- Nunca digas que es «por seguridad» ni que no puedes compartirlo: es su dato y lo pregunta por
  el número al que le escribimos.
```

y para el mensaje de emisión:

```
PROHIBIDO en el mensaje de emisión:
- NO inventar ningún dato que no esté explícitamente en la respuesta de issue_policy o get_quotation_data
```

### Los textos, uno por caso

**A · Pregunta a qué correo le llega o pide que se lo confirmes** («Tienes mi correo??», «Me confirmas el correo por favor», «¿me la envía por este medio o algún correo?»)

```
Sí, lo tengo. La documentación de tu póliza te llega a [correo], el correo con el que hiciste tu cotización. Si es el correcto, no tienes que hacer nada más.
```

Con la guarda sin canónico queda: «…te llega a tu correo registrado, el correo con el que hiciste tu cotización…». Se lee bien. **Depende de que la documentación de verdad se envíe a ese correo** (ver §0).

**B · Quiere cambiarlo o dice que está mal** («ese no es», «cámbialo a…», «ya no uso ese correo»)

```
Por aquí todavía no puedo cambiarlo. Para que la documentación te llegue al correo correcto, escríbele a un asesor por este enlace y dile cuál quieres usar: [enlace del agente especializado]. Tu póliza y tu pago no cambian por esto.
```

Por qué así: la salida que existe hoy es el enlace de WhatsApp del agente especializado que el prompt ya usa en escalamientos (`api.whatsapp.com/send?phone=525634352430&text=Quiero%20continuar%20con%20mi%20cotizacion%20[qid]`). No promete que el bot lo registre ni que alguien lo cambie antes de X hora, porque nada de eso está construido. No repite el correo nuevo (constricción 2). «Tu póliza y tu pago no cambian» evita que el cliente crea que tiene que volver a pagar o que la póliza quedó mal.

**C · No hay correo registrado** (`email` ausente en `get_quotation_data`)

```
No encuentro un correo registrado en tu cotización. Para que la documentación de tu póliza te llegue bien, escríbele a un asesor por este enlace y dile a qué correo quieres recibirla: [enlace del agente especializado].
```

No lleva dirección, así que la guarda no toca nada. No inventa ni pide que lo teclee (no hay dónde guardarlo).

**D · Dice que ya pagó y pregunta por la póliza** (es el caso de `waq_3662` a las 21:42, y el de la regla 0 de FASE)

```
Gracias. El pago se valida automáticamente en cuanto la pasarela lo confirma; en ese momento la documentación de tu póliza te llega a [correo]. No necesitas mandarme nada más.
```

Sustituye al «¿te gustaría que te reenvíe el link de pago?» de la fila 12560. **Depende de §0** igual que A. Si el envío es manual, cambiar «en ese momento» por «después».

**E · Opcional, el mensaje de emisión** (propuesta 3 del issue): añadir, después de «El link expira en 24 horas.»:

```
Cuando se confirme el pago, la documentación de tu póliza te llega a [correo].
```

Con la guarda, riesgo de correo inventado: cero. Los detectores no cambian (`emitida exitosamente` sigue en la primera línea). La decisión es de Alberto: resuelve la pregunta antes de que la hagan, pero alarga el mensaje de emisión. Yo lo pondría.

### Frases del corpus

**Positivas** (las cuatro preguntas por el correo de todo el histórico): «Tienes mi correo??» (`waq_3662` · 12567) · «Me confirmas el correo por favor. Solo para corroborar» (12569) · «¿…me la envía por este medio o algún correo??» (12565) · «La poliza me la envía al correo?» (`528343010940` · 4399; hoy cae al fallback del RAG). Y una que debe disparar A aunque suene a queja: «en mi correo no ha llegado nada incluyendo spam» (`525519512459` · 7928): decirle a qué correo se mandó es lo primero que hay que hacer.

**Negativas**: «Me llegó al correo este mensaje» (`528712368869` · 6803): el cliente cuenta que recibió algo, no pregunta su correo. Cualquier mensaje con un correo tecleado por el cliente («cámbialo a x@y.com»): B, sin repetir la dirección.

### Impacto en detectores

Ninguno. Ningún texto contiene las cinco combinaciones. El mensaje de emisión conserva «emitida exitosamente».

---

## 2 · `#474` — El tope de fotos

### Lo que condiciona la redacción

1. **El texto que inyecta el grafo hoy miente por omisión:** `Image Budget Guard` (`IMAGE_HARD_LIMIT = 3`) sustituye `chatInput` por «[FOTO_VIN] El cliente ya adjuntó varias fotos de **tarjeta de circulación** en esta sesión sin lograr una lectura confiable». El modelo lee «tarjeta» y «sin lograr lectura» y contesta «no pude leer bien esa foto tampoco» (12476): la foto no se miró y no era una tarjeta. La regla del `AI Agent` (bloque `[FOTO_VIN]`, offset 42318, tercer guion) también presupone tarjeta: «Si el sistema no pudo leer ningún dato confiable, o el cliente ya adjuntó varias fotos sin éxito: pide que confirme o escriba placas/NIV manualmente».
2. **Sin número.** Ni «tres» ni «cuarta» en ningún texto: «ya no puedo revisar más fotos en esta conversación» vale con cualquier tope. El contador es por sesión y no se reinicia, así que «en esta conversación» es exacto.
3. **La salida depende de lo que falte**, no del tipo de foto, porque el bot no sabe qué contiene. Lo que sí sabe es el `checkpoint` del `[CTX:]` y su propio historial.

### Pieza 1 · Texto que inyecta el grafo (nodo `Image Budget Guard`, no es mi nodo: lo dejo para que lo traduzcas)

Actual:

```
[FOTO_VIN] El cliente ya adjuntó varias fotos de tarjeta de circulación en esta sesión sin lograr una lectura confiable.
```

Propuesto:

```
[FOTO_VIN] TOPE DE FOTOS ALCANZADO: esta imagen NO se revisó y no se sabe qué contiene (puede ser tarjeta de circulación, recibo, comprobante de pago u otra cosa). En esta conversación ya no se revisará ninguna imagen más.
```

Si el `#476` se arregla, el pie del cliente va detrás: «Texto que el cliente escribió junto a la imagen: "…"». Mientras no, nada.

### Pieza 2 · Regla del `AI Agent` (sustituye el tercer guion del bloque `[FOTO_VIN]`, offset 42318)

Actual:

```
- Si el sistema no pudo leer ningún dato confiable, o el cliente ya adjuntó varias fotos sin
  éxito: pide que confirme o escriba placas/NIV manualmente, con la misma calidez de siempre --
  no tratas esto como un error del cliente, es solo el siguiente paso normal.
```

Nuevo:

```
- Si el sistema no pudo leer ningún dato confiable: pide que confirme o escriba placas/NIV
  manualmente, con la misma calidez de siempre -- no tratas esto como un error del cliente, es solo
  el siguiente paso normal. Si NO estás pidiendo placas ni serie (otro dato pendiente, resumen ya
  confirmado o póliza emitida), no menciones la tarjeta de circulación: di que no pudiste leer la
  imagen y sigue con lo que toque.
- Si el sistema indica TOPE DE FOTOS ALCANZADO: la imagen NO se miró. NUNCA digas que no pudiste
  leerla, que salió borrosa ni que "tampoco" se leyó, ni la llames tarjeta de circulación. Dilo sin
  rodeos, sin decir cuántas fotos fueron ni cuántas se permiten y sin culpar al cliente, y da la salida
  que sí funciona según lo que falte:
  · Faltan placas y/o serie: que los escriba tal como aparecen en su tarjeta. Si hay un dato
    propuesto sin confirmar, que lo confirme o lo corrija escribiéndolo.
  · Falta el domicilio u otro dato: que lo escriba.
  · No falta nada (resumen confirmado o póliza emitida): no pidas nada. Si dice o parece que es un
    comprobante de pago, aplica la regla 0 de FASE (el pago se valida solo) y no ofrezcas el link.
```

### Los textos, uno por situación

**F · Faltan placas o serie** (`checkpoint=personal_data_captured`)

```
Ya no puedo revisar más fotos en esta conversación, así que esta no la vi. No pasa nada: escríbeme el número de serie (17 caracteres, sin las letras I, O ni Q) y las placas tal como aparecen en tu tarjeta, y seguimos.
```

**G · Hay un dato propuesto sin confirmar** (el caso del `#472 B`, `serie_foto.status='propuesto'`)

```
Ya no puedo revisar más fotos en esta conversación, así que esta no la vi. Si el número de serie que te propuse no es el correcto, escríbeme el bueno tal como aparece en tu tarjeta; si sí lo es, dime «sí» y seguimos.
```

**H · Falta el domicilio u otro dato** (es la foto 4 de `waq_3662`)

```
Ya no puedo revisar más fotos en esta conversación, así que esta no la vi. Escríbeme tu calle, número y colonia y con eso seguimos.
```

**I · No falta nada; póliza emitida o pago en curso** (es la foto 5 de `waq_3662`)

```
Ya no puedo revisar más fotos en esta conversación, así que esta no la vi. Si es tu comprobante de pago, no necesitas mandármelo: el pago se valida automáticamente en cuanto la pasarela lo confirma. Si es otra cosa, cuéntamelo por texto y te ayudo.
```

Por qué la misma primera frase en las cuatro: es la parte que hoy falta (decir que no la vio) y conviene que sea siempre igual para reconocerla en el historial y medirla. «Así que esta no la vi» es lo que evita el «no pude leer bien» falso. La salida cambia porque cambia lo que falta, no por adivinar la foto.

### Impacto en detectores

Ninguno. «las placas» sin «Serie:» no dispara `dio_vin`; ningún texto lleva «continuamos con», «*Domicilio:*» ni «tengo»+«Nombre:».

### Lo que no decide este encargo, y lo que le afecta

- **El número de intentos** (propuesta 4 del issue): los textos no lo nombran; valen con 3, 5 o 10.
- **Saltar el tope ante una corrección** (propuesta 2, con la señal del `#472 B`): si se hace, el texto G casi no se usará, y mejor.
- **`#476`, el pie de foto perdido:** afecta a todas las fotos, no solo al tope. Con él arreglado, en la situación I el bot ya sabría que «Ya se hizo el pago» y aplicaría la regla 0 sin adivinar.

---

## Resumen para tu validación

| Pieza | Nodo | Acción | Depende de |
|---|---|---|---|
| `#473` regla `CORREO Y TELÉFONO` + `FUENTES DE DATOS` + `PROHIBIDO` | `AI Agent` (57932–58380 y 58934) | sustituir | `Email Fidelity Guard` en PROD |
| `#473` textos A, D (y E opcional) | `AI Agent` | añadir | confirmar que la documentación sí se envía al correo, y si es automático |
| `#473` textos B, C | `AI Agent` | añadir | nada |
| `#474` texto inyectado del tope | `Image Budget Guard` | sustituir | nada (independiente del número) |
| `#474` regla `[FOTO_VIN]` + textos F–I | `AI Agent` (42318) | sustituir tercer guion | nada |
| `#476` pie de foto perdido | grafo | arreglo | abierto hoy, no es copy |

Bot sin modelo hasta el 1 de octubre: nada de esto se puede medir antes.

Agente: Mejoras Conversación
