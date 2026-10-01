# Foto ilegible: el bot pide «datos personales» como si salieran de la tarjeta

**Para:** Arquitecto-IA-Quálitas · **De:** Agente Mejoras Conversación · **1 oct 2026**
**Responde a:** `Agente-MejorasConversacion:handoffs/2026-10-01-foto-ilegible-pide-datos-personales.md` (`064c325`). Encargo de Alberto.
**Fuentes:** `n8n_chat_histories` PROD (todas las filas, sin corte de fecha). Prompt y nodos leídos de los exports de `Agente-n8n`: PROD `4e5a6b92` y STG `2e7eeb8f`. El bloque relevante es **idéntico** en los dos (comparado byte a byte). La regla 8 pide confirmar contra el vivo: confírmalo con tu acceso de API antes de traducir.

---

## Respuesta corta

- **Frecuencia en PROD del caso exacto: 0.** Ningún turno de PROD responde a una foto ilegible pidiendo datos personales. El escenario de la ejecución 71220 de STG no ha ocurrido en PROD: nunca ha llegado una foto mientras el pendiente eran los datos personales.
- **Frecuencia del patrón general: 1 caso claro en 17 turnos.** El patrón general es pedir algo que no sale de la tarjeta, atado a la foto como si viniera de ella. El caso claro fue el 22-sep, antes de que existiera la regla que lo prohíbe. Hay además 1 caso ambiguo.
- **Abandono: sin señal.** En el único caso claro, el cliente contestó para corregir al bot.
- **Veredicto: sí, cambiarlo, con prioridad baja.** La regla que debería evitarlo ya existe en el prompt. Está escrita como coletilla de una viñeta cuya primera frase ordena lo contrario, y el modelo de STG copió esa primera frase. Además, desde el 26-sep el modelo recibe el texto que el cliente escribe junto a la foto, y ninguna regla le dice qué hacer con él. Es una edición pequeña dentro de un bloque que ya existe.

---

## 1 · Frecuencia en PROD

### Qué se contó

Busqué todas las filas de cliente que contienen alguno de los dos marcadores de foto ilegible:
- «no se detectaron datos legibles» (lo genera `Parse VIN Extraction`)
- «sin lograr una lectura confiable» (lo genera `Image Budget Guard` tras varias fotos)

Para cada una, tomé la siguiente respuesta del bot en la misma sesión, sin contar las llamadas a herramientas.

| Qué | N |
|---|---|
| Filas con el marcador | 19 |
| Sesiones distintas (`count(distinct session_id)`) | 14 |
| Filas que son **herencia de historial**, no un turno nuevo | 2 |
| **Turnos reales** | **17** |
| **Sesiones reales**, sin contar las heredadas | **12** |

Las dos filas heredadas son 11919 (`waq_3620`) y 13270 (`waq_3744`). Cada una tiene la misma marca de tiempo al microsegundo para la entrada y la respuesta, y lleva el `[CTX:]` de la sesión anterior (`qid=3619` y `qid=3740`). Es el mismo patrón que vimos en el #462.

### Los 17 turnos, leídos uno a uno

| Fila | Fecha | Fase / pendiente | Qué respondió el bot | Clase |
|---|---|---|---|---|
| 6591 | 17-jul | payment_pending | «no pude leer la imagen… si es un comprobante de pago… contacta a un agente» | Posventa, correcto |
| 6801 | 17-jul | — | «¿qué necesitas? … tu póliza 7620098923 o el pago» | Posventa, correcto |
| 8750, 8796, 8812, 8834 | 23-jul | fallback, sin qid | «No conozco esta respuesta… agente especializado» (×4) | Fallback heredado (ver nota) |
| 9642 | 27-jul | greeting | «No pude leer datos de la imagen… ¿Podrías escribirme qué opción de cobertura y forma de pago prefieres?» | No nombra la tarjeta. Une la foto con lo pendiente («escribirme»), pero sin confusión de origen |
| 10009 | 28-jul | greeting | Otra foto con consejos, o escribir placas y número de serie | Correcto |
| 10082 | 29-jul | greeting | «Entiendo que quieres enviar una foto, pero aún no hemos confirmado el plan…» | Correcto, separa las dos cosas |
| 10456 | 31-jul | payment_pending | «Recibí tu imagen… ¿Es el comprobante de pago?» | Correcto |
| 11866 | 22-sep | payment_pending | «Para tu póliza ya emitida no necesito otra foto del vehículo…» | Correcto |
| **11908** | **22-sep** | **greeting** | **«No pude leer bien los datos de tu tarjeta de circulación en esa foto. ¿Me confirmas si seguimos con tu Cooper 2016…?»** | **Patrón. La foto no era una tarjeta** |
| 12465 | 24-sep | data_capture, personal_data_captured | «No pude leer bien esa foto. Mientras tanto, ¿me confirmas… Placas / Serie?» | Correcto, el dato sí sale de la tarjeta |
| 12475 | 24-sep | data_capture, vin_plates_captured | «No pude leer bien esa foto tampoco. No hay problema, ¿me escribes tú directamente tu calle, número y colonia?» | **Ambiguo** (ver abajo) |
| 12557 | 24-sep | payment_pending | «Ya tengo todos los datos… no te preocupes por la foto» | Correcto |
| 13014 | 29-sep | data_capture, pendiente=placas y número de serie | «¿Me compartes las placas y el número de serie… escritos?» | Correcto |
| 13228 | 30-sep | greeting, pendiente=nada; con texto del cliente | «No pude leer bien esa imagen. Y no te preocupes por lo de tu ex esposo, aquí la cotización queda a tu nombre 🙂 ¿Continuamos con…?» | Correcto, y **reconoce lo que escribió el cliente** |

**El caso claro (11908, `waq_3619`, Mini Cooper).** El bot da por hecho que la foto era la tarjeta de circulación y, en el mismo mensaje, pide confirmar el plan. Su siguiente mensaje, en la sesión heredada `waq_3620`, fue: **«No es tarjeta de circulación, es foto de la promoción, el cartel»**. Es el mismo error de fondo que el de STG: el bot llama «tarjeta» a cualquier imagen y pide lo pendiente como si viniera de ella. Ocurrió el 22-sep, cuatro días antes de que existiera la regla que lo prohíbe (ver §3).

**El caso ambiguo (12475, `waq_3662`, la Stepway de #473 y #474).** «¿Me escribes **tú directamente** tu calle…?» presenta el domicilio como alternativa a la foto. Pero en esa conversación las fotos eran recibos y comprobantes, no tarjetas, como medí el 25-sep. Un comprobante de domicilio sí lleva calle y colonia, así que la lectura del bot pudo ser razonable. El cliente contestó con su domicilio. No lo cuento como fallo.

**Nota sobre los 4 fallbacks de julio.** Son de una sesión del sistema anterior (`phase=fallback`, `qid=null`). Desde entonces no se han repetido. Quedan fuera del veredicto.

### Desde que existe la regla

La regla «si no estás pidiendo placas ni serie… no menciones la tarjeta de circulación» llegó a PROD el **26-sep** (`ca16e12d`, PROD `988717c9`). Desde ese día hay **2 turnos reales en PROD** (13014 y 13228), y **los dos cumplen**. El de STG que reportas es, por tanto, **una violación de una regla vigente**, no un hueco del prompt. Con una muestra de 2 en PROD no se puede estimar una tasa de violación.

---

## 2 · ¿Abandonan después?

Para cada turno real, comprobé si el cliente volvió a escribir en la sesión. Una respuesta que llega menos de 10 segundos después del bot es un mensaje que el cliente ya estaba escribiendo, no una reacción, y la marco aparte.

| Resultado | Turnos | Cuáles |
|---|---|---|
| El cliente no vuelve a escribir | 4 | 6591, 8834, 10009, 11866 |
| Escribe, pero en ráfaga de menos de 10 s (no reacciona al bot) | 3 | 6801, 10082, 13228 |
| Escribe y reacciona | 10 | resto |

- **Ninguno de los 4 sin respuesta es del patrón.** Dos son posventa. Uno es el fallback de julio. El otro (10009) recibió la respuesta correcta.
- **En el único caso del patrón (11908), el cliente contestó para corregir al bot.** No abandonó en ese turno.

Conclusión: **no hay evidencia de que este copy cause abandono.** El corpus es demasiado pequeño para afirmar lo contrario.

---

## 3 · Dónde nace el texto

No es una plantilla: lo redacta el modelo del **AI Agent**. Hay dos instrucciones que lo empujan, y faltan otras dos.

**(a) El `systemMessage`, bloque «FOTO DE TARJETA DE CIRCULACIÓN (extracción automática de placas + VIN/NIV)», tercera viñeta.** Igual en PROD `4e5a6b92` y en STG `2e7eeb8f`:

```
- Si el sistema no pudo leer ningún dato confiable: pide que confirme o escriba placas/NIV
  manualmente, con la misma calidez de siempre -- no tratas esto como un error del cliente, es solo
  el siguiente paso normal. Si NO estás pidiendo placas ni serie (otro dato pendiente, resumen ya
  confirmado o póliza emitida), no menciones la tarjeta de circulación: di que no pudiste leer la
  imagen y sigue con lo que toque.
```

**La primera frase manda lo contrario de la segunda.** Ordena pedir «manualmente», y la excepción va detrás, como coletilla. El bot de STG hizo justo eso: tomó «no pude leer… tarjeta de circulación» y «¿me compartes **manualmente**…?» de la primera frase, y les puso detrás el dato pendiente. La palabra «manualmente» de su respuesta sale literalmente de esta viñeta. La viñeta del tope de fotos, justo debajo, sí está ordenada por `pendiente`, y en PROD funciona.

**(b) El marcador de `Parse VIN Extraction`.** Igual en PROD y STG:

```
[FOTO_VIN] El cliente adjuntó una imagen, pero no se detectaron datos legibles del vehículo.
```

«Datos legibles **del vehículo**» da por hecho que la imagen era un documento del vehículo. El marcador del tope, en cambio, dice expresamente que no se sabe qué contiene («puede ser tarjeta de circulación, recibo, comprobante de pago u otra cosa»). Con un marcador así, el error del Mini Cooper era más difícil.

**(c) Falta una regla para el texto del cliente.** Desde `d7205151` (26-sep, #476), el marcador añade *«Texto que el cliente escribió junto a la imagen: "…"»*. En ese despliegue no se tocó el AI Agent («AI Agent NO se toca»), y el `systemMessage` no menciona ese texto en ningún sitio: no hay ninguna coincidencia de «junto a la imagen». En 13228 el modelo lo reconoció por su cuenta. En STG 71220 no lo hizo.

**(d) `pendiente=nada` no significa lo mismo en todas las fases.** En 13228 la sesión estaba en `greeting` con `pendiente=nada`, y sí había algo pendiente: elegir el plan. La regla del tope traduce `pendiente=nada` como «resumen confirmado o póliza emitida», y eso no vale para `greeting`. Lo tengo en cuenta en la propuesta.

---

## 4 · Propuesta

### 4.1 · `systemMessage`, bloque «FOTO DE TARJETA DE CIRCULACIÓN», tercera viñeta

**Sustituir** la viñeta citada en §3(a) **por:**

```
- Si el sistema no pudo leer ningún dato confiable, lo que dices depende de `pendiente` en el
  [CTX:] (no lo deduzcas tú):
  · pendiente=placas y número de serie: di que no pudiste leer los datos y ofrece las dos salidas,
    otra foto (completa, con buena luz, sin reflejos) o que te escriba placas y número de serie.
    Con la misma calidez de siempre: no es un error del cliente.
  · cualquier otro pendiente (datos personales, domicilio, RFC, factura, confirmación del
    resumen): esa imagen NO sustituye al dato pendiente, ni lo iba a sustituir. En una frase corta,
    di que no pudiste leer la imagen, SIN llamarla tarjeta de circulación ni suponer qué era. En
    una frase aparte, pide el dato pendiente como en tu flujo normal. NO uses «manualmente», «tú
    directamente», «entonces», «así que» ni «en su lugar», ni nada que presente el dato pendiente
    como alternativa a la foto. Si el texto del cliente indica que era su tarjeta o algo de su
    auto, dile que las placas y el número de serie se los pides más adelante y que ahí puede
    mandar otra foto o escribirlos.
  · pendiente=nada: sigue con lo que toque en la fase. En greeting, la elección de cobertura y
    forma de pago. Con la póliza emitida, no pidas nada. Si dice o parece que es un comprobante de
    pago, aplica la regla 0 de FASE.
- Si junto al [FOTO_VIN] aparece «Texto que el cliente escribió junto a la imagen», ese texto SÍ
  lo escribió el cliente. Antes de seguir, reconócelo en pocas palabras, sin citarlo entre
  comillas y sin suponer sobre la imagen nada que él no haya dicho. Si contiene una pregunta o un
  dato, atiéndelo.
```

**Ejemplo para añadir tras la viñeta.** Es el caso de STG: `pendiente=datos personales`, con el texto «Esta es la de mi coche».

```
Ejemplo (pendiente=datos personales, el cliente escribió que es la de su coche):
"Gracias por mandarme la de tu coche. No logré leer los datos en esa imagen, pero no te
preocupes: las placas y el número de serie te los pido más adelante, y ahí me puedes mandar
otra foto o escribirlos.

Para seguir, necesito tus datos personales:
- Nombre completo
- Fecha de nacimiento
- Género"
```

**Lo que cambia respecto a la respuesta de STG.** Esta era la respuesta:

> No pude leer bien los datos de tu tarjeta de circulación en esa imagen. ¿Me compartes manualmente tus datos personales para continuar? Necesito: Nombre completo · Fecha de nacimiento · Género

- **Reconoce lo que escribió el cliente** («la de tu coche»).
- **Separa las dos cosas en dos párrafos:** la foto, y lo que hace falta ahora.
- **Desaparece «manualmente».**
- **Le dice al cliente que su foto no fue en vano**, porque más adelante sí sirve.
- **No afirma que la imagen fuera una tarjeta.** Si el cliente no lo dice, el ejemplo no lo supone.

### 4.2 · Opcional: el marcador de `Parse VIN Extraction`

Esto es texto de grafo, no copy de cliente. Lo propongo por coherencia con el marcador del tope:

```
[FOTO_VIN] El cliente adjuntó una imagen, pero no se pudo leer en ella ningún dato del vehículo. No se sabe qué contiene (puede ser tarjeta de circulación u otra cosa).
```

**Tiene una dependencia que hay que cambiar a la vez.** El Dashboard recorta el marcador para pintar la burbuja del operador. Lo hace en `Dashboard_SeguroAuto/apps/operacion/lib/s1/anuncioDeFoto.js`, líneas 23 y 26, con dos patrones:
- `/el cliente adjunto una (?:foto|imagen)[^.]*\./`
- `/pero no se detectaron datos legibles del vehiculo\.?/`

Con el marcador nuevo, el primer patrón recortaría solo la primera frase, y «No se sabe qué contiene…» quedaría a la vista del operador como si lo hubiera escrito el cliente. Es el mismo tipo de fallo que corrigió el #487. Si se adopta, el patrón del Dashboard y su test (`scripts/s1/test/anuncio-foto-evento-510.test.js`) tienen que cambiar en el mismo despliegue. Si no compensa coordinarlo, la §4.1 sola resuelve el caso: el prompt ya le dirá al modelo que no suponga qué era la imagen.

### 4.3 · Detectores

- **El ejemplo de §4.1 no contiene ninguna de las cinco cadenas.** No hay «Nombre:» con dos puntos, ni «tengo». «placas» va en minúscula y no aparece «Serie:». Tampoco hay «continuamos con», «*Domicilio:*» ni «emitida exitosamente».
- **La propuesta no toca ninguna frase que busque un detector.** Las frases que disparan `dio_datos_personales` («tengo» + «Nombre:») y `dio_vin` («Placas» + «Serie:») viven en las confirmaciones de los grupos 1 y 2, y no se tocan.

---

## 5 · Hallazgo lateral, ya abierto como #502

Dos de las respuestas de esta muestra, 13229 y 10083, preguntan en `greeting` «¿Continuamos con la Cobertura Amplia…?». Las dos disparan `confirmo_cobertura` sin que el cliente haya confirmado nada. Lo tienes abierto como **#502**. Mi medición de hoy en PROD, con la misma lógica de `db-leads.js` (`ILIKE '%continuamos con%'` + `'%cobertura%'`, sin `source`):

```
sesiones con confirmo_cobertura = true:                     217
de ellas, solo por mensajes con «¿Continuamos con…» (pregunta): 72
```

Es tu 70 de 214 del 29-sep, con tres días más de datos. No abro issue nuevo.

---

## 6 · Resumen para traducir

| Qué | Dónde | Prioridad |
|---|---|---|
| Sustituir la 3.ª viñeta por la versión ordenada por `pendiente` + regla del texto del cliente + ejemplo | AI Agent · `systemMessage` · bloque «FOTO DE TARJETA DE CIRCULACIÓN» | Baja. Corrige una violación vista en STG, y en PROD el caso exacto tiene 0 ocurrencias |
| Marcador neutro | `Parse VIN Extraction`, rama sin datos, **junto con** `anuncioDeFoto.js` del Dashboard | Opcional. No hace falta si entra la §4.1 |
| Nada | Detectores | — |

**Pendiente de confirmar por ti:**
- **Bloque en el vivo.** Que el bloque citado sea idéntico en el `systemMessage` vivo de PROD y STG (regla 8).
- **Fecha de la ejecución.** Si la ejecución 71220 de STG corrió con el bloque ya presente (STG `2e7eeb8f`). Si es así, es una violación de la regla. Si no, era el hueco previo.
