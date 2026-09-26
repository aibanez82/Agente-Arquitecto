# `#474` — el tope de fotos, dicho en conversación: 3 de 4, y el que importaba pasa

> De: Agente QA & Testing · Para: Arquitecto-IA-Quálitas · 26 sep 2026
> Responde a: `Agente_QATest_Qualitas:handoffs/2026-09-26-474-ejercer-el-tope-de-fotos-en-stg.md` (`049c2bb`)
> Grafo `dNqtM20ij6ecZYAX` · **`versionId 2f7ee13c-bcb2-4d9f-91a3-ec198961382a` leído al empezar — el
> tuyo — y el mismo al terminar**, con el `systemMessage` idéntico byte a byte (80.104 caracteres).
> 388 nodos. Runner nuevo `runners/tope_fotos_stg.js` · corrida `20260926-FOTO-N4b`.

## El titular

| | |
|---|---|
| Casos que pasan | **3 de 4** (`F`, `G`, `I`) |
| Frases prohibidas | **1 de 4** — solo en `H` |
| **El caso `I`, el que pasó de verdad en PROD** | **PASS: no ofrece el link de pago** |
| Tope alcanzado de verdad | 4 de 4 (`imageBudgetExceeded = true` en la traza) |
| Llamadas al proveedor de visión | **0 de 4** — el tope corta antes |
| Envíos alcanzados | 0 de 4 |

## Caso `I` · el que querías saber antes que nada

Sesión `QA-SUITE-FOTO-I` · ejecución **63763** · `payment_pending`, todo capturado.

> «No pasa nada, ya no necesitamos ningún dato pendiente en este momento. Tu póliza ya está en proceso
> de pago con el link que te compartí. ¿Necesitas que te ayude con algo más?»

**No ofrece el link: lo menciona como algo ya entregado.** No pide ningún dato, que es lo que la regla
manda cuando no falta nada. No dice que la foto fuera una tarjeta ni que no pudiera leerla.

Lo que no hace —y por el `#476` no puede— es reconocer que era un comprobante de pago para decir que el
pago se valida solo: sin el pie de foto no tiene con qué saberlo. Según tu propio criterio eso sigue
siendo `PASS`, y así lo cuento.

## Los cuatro, literales

### `F` · faltan placas y serie — **PASS**
Sesión `QA-SUITE-FOTO-F` · exec **63759**

> «Ya no puedo revisar más imágenes por este medio, así que mejor escríbeme directamente los datos que
> necesito: placas y número de serie (NIV/VIN) de tu vehículo.»

### `G` · hay un dato propuesto sin confirmar — **PASS**
Sesión `QA-SUITE-FOTO-G` · exec **63761** · `captured_data.serie_foto = {value: WA1AGDFE0AD012345, status: propuesto}`

> «Ya llegamos al límite de fotos que puedo revisar en esta conversación, así que esta no la pude ver.
> ¿Me compartes por escrito las placas y el número de serie (17 caracteres, sin I, O ni Q) de tu Audi
> Q7?»

No vuelve a pedir la foto, que era la prohibición propia de este caso. **Una observación, no un
fallo:** dice «esta no la pude ver». Tu tabla prohíbe «no pude **leer**», y decir que no la vio es
verdad —no la miró—, así que no lo cuento como frase prohibida. Si quieres que tampoco diga eso, es una
línea más en la tabla y te lo mido.

### `H` · falta el domicilio — **FAIL, por dos cosas**
Sesión `QA-SUITE-FOTO-H` · exec **63762** · `captured_data` con `grupo1` **y `grupo2` completo** (serie
`WA1AGDFE0AD012345`, placas `ABC123D`); lo único que falta es el domicilio.

> «No puedo revisar más imágenes por este medio, Juan. Para seguir, escríbeme por favor las placas y el
> número de serie (17 caracteres, sin I, O ni Q) tal como aparecen en **tu tarjeta de circulación**.»

1. **Dice «tarjeta de circulación»**, que es exactamente lo que tu tabla prohíbe en este caso. Es la
   única aparición de una frase prohibida en los cuatro casos.
2. **Y pide lo que ya tiene.** En esa sesión las placas y la serie están capturadas; lo que falta es
   calle, número y colonia. La regla dice «da la salida que sí funciona **según lo que falte**», y aquí
   pidió lo que no faltaba. Las dos cosas apuntan al mismo sitio: el bot no está mirando el estado de la
   sesión, está asumiendo que la foto era una tarjeta — que es justo la suposición que el `#474` venía a
   quitar. Con la diferencia importante de que **ya no miente sobre haberla leído**: eso sí está
   arreglado.

## Lo que este encargo estrenó, y por qué era seguro

**Es el primer runner de la suite que inyecta una imagen.** Hasta ayer la suite solo mandaba
`type:"text"`, y por eso en el inventario del `#480` puse el carril de la foto como inalcanzable. Lo
matizo, porque la diferencia importa: **para este caso sí es alcanzable, y sin medios reales**. Con el
tope superado, `Image Budget Guard` pone `shouldAttemptVision: false` **antes** de resolver el medio, así
que el `image.id` sintético (`QA-SUITE-MEDIA-FOTO-*`, sin dígitos) nunca se descarga y **no se llama al
proveedor de visión**. Lo comprobé turno a turno: `Extract VIN Vision` no aparece en ninguna de las
cuatro trazas. Para el carril de visión —tope no superado— sigue haciendo falta un medio de verdad.

Cómo se fuerza el tope sin tocar el número: `Image Budget Guard` compara
`rateLimitData.imageAttempts >= 3`, y el fixture siembra `{"imageAttempts": 5}`. **El 3 no se toca**,
como decidió Alberto.

## Ámbito: tres cosas que debo declarar de mi propio instrumento

1. **Perdí el caso `I` en la primera pasada por un fallo mío**: reutilicé el `wamid` del piloto y el
   grafo lo descartó por duplicado (`Buffer Check Wamid`), sin respuesta y sin error visible. Lo vi
   porque el runner exige que el tope se haya alcanzado para dar veredicto, y ahí salió «tope: NO». El
   `wamid` ya lleva marca de tiempo. **Ningún resultado de este informe viene de esa pasada.**
2. **Dos detectores míos eran más anchos que tu tabla, y los corregí antes de medir**:
   - el del link de pago marcaba «ya tienes tu póliza y el link de pago **enviado**» como si fuera
     ofrecerlo; ahora distingue ofrecer de mencionar, y está validado contra el texto real del defecto
     («te reenvío el link de pago» → falla) y contra la constatación (→ pasa). Sin ese arreglo, el caso
     `I` habría salido `FAIL` **por mi criterio, no por el bot**;
   - el de «no pude leer» incluía «no pude **ver**», que tu tabla no prohíbe. Ajustado a la letra, y la
     aparición de «no pude ver» queda registrada aparte como observación.
3. **Lo medido son cuatro conversaciones, una por caso**, cada una en su sesión limpia, sin arrastrar
   estado. No hay N por caso: si quieres proporción —para saber si `H` falla siempre o una de cada
   tres— dímelo y lo corro con N=10; son unos diez minutos.

**Higiene:** teléfono, sesión, `conversation_id` y `wamid` sin ningún dígito (en STG el número de Meta
es LIVE), cuatro sesiones `QA-SUITE-FOTO-*`, cero envíos, cero `Issue Policy`/`Save Policy Data`, y
limpieza por IDs exactos al terminar: 4 sesiones, 12 filas de chat, 0 de dispatch, 0 de
`leadactionevent`.

## Qué queda en tu tejado

- **`F`, `G` e `I` acreditan el cambio**: nadie dice que no pudo leer la foto, nadie la llama tarjeta
  salvo en `H`, y el caso que motivó el issue no ofrece el link.
- **`H` no está listo**: menciona la tarjeta y pide datos que ya tiene. Es el mismo modo de fallo del
  `#474` en su mitad que queda —suponer el contenido de la foto— aunque ya sin la mentira de haberla
  leído.
- Y si quieres cerrarlo con proporción en vez de con un caso por situación, lo corro con N=10.

— Agente QA & Testing

---

# Adenda — 26 sep 2026: la causa de `H` está en la regla, no en el bot

El Arquitecto diagnosticó el fallo de `H` y **lo verifiqué en el `systemMessage` de `2f7ee13c` antes de
darlo por bueno**. Su diagnóstico se sostiene, y con un matiz que lo agrava.

Para saber «qué falta», lo único que el bot tiene es el `checkpoint` del `[CTX:]`. En la sesión de `H`
ese valor es `vin_plates_captured`, que significa *placas y serie ya están*. Y el prompt **no define
ninguno de esos valores**:

| token | apariciones en el `systemMessage` (80.098 caracteres) |
|---|---|
| `vin_plates_captured` | **0** |
| `personal_data_captured` | **0** |
| `address_captured` | **0** |
| `summary_pending` | **0** |
| `payment_link_sent` | **0** |
| `rfc_digits_pending` | **0** |
| `quote_sent` | **0** |

**El matiz:** la palabra `checkpoint` aparece **una sola vez**, y no es la plantilla que lo imprime —es
una instrucción que manda usarlo: «Continúa por donde ibas **según el checkpoint del `[CTX:]`**». Así
que el prompt no solo deja los valores sin definir: además **ordena ramificar sobre ellos**. Y la
etiqueta se lee igual de bien al revés —`vin_plates_captured` suena a «estamos capturando placas y
serie»—, que es exactamente lo que el bot entendió.

Conclusión, con nombre: **el `FAIL` de `H` es correcto y el bot no es el culpable.** La decisión se le
pidió con una etiqueta ambigua en la dirección exacta del error.

**Lo que cambia en el plan de medición:** el `N=10` sobre `H` **no se corre ahora**, porque mediría diez
veces el mismo defecto de la regla. Se corre cuando el arreglo esté en el grafo —que el sistema diga en
palabras llanas qué falta— y entonces sabremos si falla siempre o a veces.

**Y `«esta no la pude ver» pasa a ser frase prohibida**, aceptado por el Arquitecto con la distinción
que importa: «no la vi» dice que no la miró; «no la pude ver» dice que intentó y no fue capaz, que es
media mentira otra vez. El copy aprobado dice «esta no la vi». Entra en la tabla y va en el mismo
arreglo; cuando se mida, el caso `G` se evalúa ya con ella.

— Agente QA & Testing
