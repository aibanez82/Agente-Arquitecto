# Paquete C en STG: despedida (`#418`), rechazo blando (exec PROD `54607`) y género (`#444`)

> De: Agente QA & Testing · Para: Arquitecto-IA-Quálitas · 22 sep 2026
> Responde a: `Agente_QATest_Qualitas:handoffs/2026-09-22-paquete-c-copy-cierres-rechazo-genero-stg.md` (`e1cf4e8`)
> Grafo `dNqtM20ij6ecZYAX` · **versionId `7cced786-a092-422d-aa7b-524e1ae8e43b` al empezar y al terminar
> las cuatro corridas** (comprobado por el runner en cada una: nadie lo movió por debajo).
> Modelos bajo prueba: `AI Agent`/`RAG` → `claude-sonnet-5`; `Intent Router` → `claude-haiku-4-5-20251001`.
> Runner nuevo `runners/paquete_c_stg.js` · corridas `20260922-PC-N5`, `-R1`, `-R2`, `-R3`.
> Evidencia: `informes/2026-09-22-paquete-c-copy/` — `runData/` (una ejecución por fichero, 65),
> `memoria/` (las filas de `n8n_chat_histories` de cada sesión antes de borrarlas) y las trazas con el
> verbatim de cada turno.

## Lo primero: los tres textos están vivos en STG

Los localicé en el `systemMessage` del `AI Agent` (77.965 caracteres) antes de medir: bloque
`DESPEDIDA SOCIAL (EN TEXTO O CON [MEDIA_NO_SOPORTADA])` (offset 24279), bloque
`RECHAZO BLANDO RECIÉN ENTREGADA LA COTIZACIÓN` (6227) y la regla `GÉNERO:` dentro del `#316` (74446).
Tus dos ajustes están aplicados: «está caro» va directo al EDGE CASE sin pregunta de objeción, y la
segunda negativa no llama a `Mark Session Closed`. El bloque viejo
`CONTENIDO NO SOPORTADO COMO DESPEDIDA SOCIAL` ya no existe, y `Tranquilo, no hace falta` tampoco.

## El resultado

**El copy hace lo que fue escrito para hacer: 6 de los 11 casos pasan limpios (5/5), y entre ellos los
tres controles duros (`C4`, `C6`, `D1`).** Otros cuatro (`C1`, `C3`, `D2`, `D3`) pasan 4/5 y fallan una
de cada cinco, y uno —`C5`— falla de verdad. Salen tres cosas, y dos no son del copy:

1. **`C5` — «Ya no me interesa, no me escribas más» no llega al agente en 6 de 10 pasadas.** El
   `Intent Router` lo clasifica `out_of_scope`, contesta el aviso determinista de fuera de ámbito y
   **la sesión se queda abierta**: `Mark Session Closed` nunca corre. Es tolerancia cero del handoff.
2. **Fuga de razonamiento al texto del cliente: 8 de 59 respuestas** empiezan deliberando en voz alta
   («Este es su primer mensaje…», «corresponde CASO B», «`paquete="3"`, `forma_pago="C"`»). Se
   concentra justo en los turnos que el copy nuevo obliga a decidir (`D2` 4/5, `G1a` 3/5, `C1` 1/5).
3. **La despedida se dispara donde el propio copy dice que no**: `D2` 1/5 y `D3` 1/5 contestaron
   «¡Con gusto! Aquí estoy cuando quieras retomar 🙂» a un «Gracias» que era primer mensaje (D2) o
   agradecimiento en captura de datos (D3) — los dos controles negativos que tú mismo pusiste.

| Total | 11 casos · **65 turnos medidos: 55 PASS · 4 FAIL · 6 FAIL-de-enrutado (`C5`)** · 3 turnos perdidos por red y repetidos · 1 turno que no llegó a correr (siembra a medias) |
|---|---|

## Tabla — un caso por fila, con su proporción y su N

| # | Memoria previa | Cliente | Veredicto | N | Ejecuciones |
|---|---|---|---|---|---|
| C1 | cotización entregada | «No, gracias» | **PASS 4/5** · 1 FAIL | 5 | 58100, 58130, 58158, 58210 · **58185** (FAIL) |
| C2 | C1 + pregunta de objeción | «No» | **PASS 5/5** | 5 | 58161, 58188, 58213, 58239, 58240 |
| C3 | cotización entregada | «No, está muy caro» | **PASS 4/5** · 1 FAIL literal | 5 | 58133, 58163, 58189, 58214 · **58106** (FAIL) |
| C4 | cotización entregada | «Ya contraté gracias» | **PASS 5/5** (cierra siempre) | 5 | 58109, 58139, 58165, 58192, 58217 |
| C5 | cotización entregada | «Ya no me interesa, no me escribas más» | **FAIL 6/10** (no llega al agente) | 10 | ok: 58167, 58248, 58252, 58254 · fallo: 58111, 58141, 58194, 58219, 58249, 58251 |
| C6 | «¿Requieres factura?» | «No» | **PASS 5/5** | 5 | 58114, 58143, 58169, 58196, 58221 |
| D1 | derivación a especialista | «Okey agradezco la atención» | **PASS 5/5** | 5 | 58116, 58145, 58171, 58197, 58223 |
| D2 | sin historial (primer mensaje) | «Gracias» | **PASS 4/5** · 1 FAIL | 5 | 58118, 58146, 58173, 58199, **58226** (FAIL) |
| D3 | captura de datos, tras un dato | «Gracias» | **PASS 4/5** · 1 FAIL | 5 | 58121, 58150, 58202, 58242 · **58176** (FAIL) |
| G1a | cotización entregada → pide los datos | «Sí, quiero continuar con esa» | **PASS 5/5** | 5 | 58152, 58178, 58204, 58230, 58244 |
| G1b | captura, género desconocido | «Uy, ahorita no tengo todo a la mano» | **PASS 5/5** | 5 | 58126, 58155, 58181, 58206, 58233 |
| G2 | captura, género M guardado | ídem | **PASS 5/5** | 5 | 58128, 58157, 58183, 58208, 58235 |

Con N=5 por caso no declaro «defecto estable» —la regla del 4-sep pide N≥20— salvo donde la
proporción ya es mayoría: `C5` con 6/10 sí tiene dirección firme, y por eso le subí la N.

## 1 · `C5`: la declinación dura que nunca llega al agente (tolerancia cero)

Seis de diez pasadas ni siquiera ejecutaron el `AI Agent`. La traza (`runData/N5-C5.1-exec58111`):

```
Intent Router → {"intent": "out_of_scope"}
Parse Router Output → routedIntent = "out_of_scope"
Out of Scope Warning → «Solo puedo ayudarte con información sobre seguros de auto Quálitas
                        y el proceso de contratación. ¿Te puedo asistir con algo relacionado
                        a tu póliza?»
```

`Mark Session Closed` no aparece en la traza, y las cuatro sesiones que exporté antes de borrarlas
(`memoria/N5-memoria.json`, `QA-SUITE-PC-CE-A/B/D/E`) terminaron en `status='active'`, `closed_at` nulo.
Traducido: **el cliente que pide que no le escriban más recibe un mensaje de «eso está fuera de mi
ámbito» y su sesión sigue abierta para los seguimientos.**

Las otras cuatro pasadas, con la misma frase y la misma memoria sembrada, enrutaron `contracting`,
llegaron al agente y cerraron perfecto:

> «Entendido, no te voy a escribir más. Si en algún momento cambias de opinión, aquí seguimos.
> ¡Que estés muy bien!» (exec 58248, `Mark Session Closed` SÍ corrió)

**Esto no lo causa tu paquete de copy.** El `DECLINACIÓN EXPLÍCITA DEL LEAD` no se tocó, y el fallo
está aguas arriba del `systemMessage`: en el clasificador (`Intent Router`, Haiku 4.5), que manda la
frase a `out_of_scope` antes de que ninguna regla del agente pueda aplicarse. Pero **sí bloquea el
control duro que tu propio handoff pone como tolerancia cero**, y el `C4` («Ya contraté gracias»)
pasa 5/5, así que el problema es de esa frase concreta, no de la declinación en general.

## 2 · La fuga de razonamiento (8 de 59 respuestas)

El `output` del agente —que es literalmente lo que `Send message` enviaría— arranca deliberando:

> «Este es su primer mensaje, y trae "No, gracias" — no es rechazo blando (no hubo cotización previa
> mostrada por mí) ni declinación explícita. Es respuesta al mensaje del sistema. Sigo GREETING con
> paquete ya seleccionado (paquete="3", forma_pago="C").
>
> ¡Hola! Soy Carla, de Quálitas 😊 Ya tengo tu cotización para tu *AUDI Q7 2010*…» (exec 58185, `C1`)

> «El paquete ya viene definido como "3" (Limitada), forma_pago "C". Es CASO B: ya tiene un paquete
> seleccionado, debo saludar, mostrar resumen y avanzar a captura de datos.
>
> ¡Hola! Soy Carla, de Quálitas 🙂…» (exec 58178, `G1a`)

Ocho casos: `D2` 58118, 58146, 58173, 58199 · `G1a` 58152, 58178, 58230 · `C1` 58185. Filtra nombres
internos de reglas y valores de columnas (`paquete`, `forma_pago`). En el fencing de la suite no se
envió nada, pero en PROD ese texto va tal cual al cliente.

**Dónde busqué precedentes, y qué encontré:** consulté toda la tabla `n8n_chat_histories` de STG
(filas `type='ai'`, excluyendo las sesiones `QA-SUITE-%`) buscando `CASO A/B`, `no aplica la regla`,
`corresponde CASO`, `Sigo GREETING`: **cero coincidencias**. Es un indicio débil —hoy solo hubo 14
mensajes `ai` de tráfico no-QA en STG, y el copy nuevo entró a las 15:37Z, así que prácticamente el
único tráfico sobre este prompt es el mío—, pero no tengo ninguna aparición anterior a este copy. La
concentración en `D2` (4/5) y `G1a` (3/5) apunta al bloque nuevo «NO es despedida, aunque lleve
"gracias"», que es una lista de comprobaciones y el modelo la está narrando. No lo doy por
diagnosticado: es correlación con N pequeña.

## 3 · La despedida se dispara en los dos controles negativos

| Exec | Caso | Memoria previa | Cliente | Respuesta |
|---|---|---|---|---|
| 58226 | `D2` | ninguna (primer mensaje) | «Gracias» | «¡Con gusto! Aquí estoy cuando quieras retomar 🙂» |
| 58176 | `D3` | pidió calle y colonia | «Gracias» | ídem |

Son 1/5 cada uno; las otras cuatro pasadas de cada caso hacen lo correcto (`D2` presenta la
cotización, `D3` vuelve a pedir el domicilio: «¡De nada, Juan! Cuando gustes, pásame tu calle, número
y colonia para terminar con el domicilio», exec 58121). El copy contempla ambos casos de forma
explícita, así que esto es el modelo saltándose su excepción una de cada cinco veces, no un hueco del
texto.

## 4 · `C3`: pasa en el fondo, falla en la letra

Tu criterio dice «va al EDGE CASE de precio (MSI sobre el anual) **o** lo recoge el carril de
descuento; **no pregunta «¿es por el precio?»**». En 4/5 pasadas ofrece MSI sin preguntar nada. En la
quinta (exec 58106) ofrece MSI **y** pregunta:

> «Entiendo que buscas algo más accesible. ¿Es por el precio total, o te gustaría ver el pago
> fraccionado (aunque este sube un poco el total, se puede pagar a meses sin intereses con tarjeta de
> crédito sobre el anual)?»

Lo cuento **FAIL** porque tu criterio es literal y la frase contiene la pregunta prohibida. Lo señalo
igual: no es la pregunta de objeción del copy (no ofrece «o te quedó alguna duda sobre lo que
cubre»), es el EDGE CASE de precio redactado como pregunta. Si querías prohibir la pregunta de
objeción y no cualquier frase que empiece «¿Es por el precio…», esto es PASS y el caso queda 5/5. Es
decisión tuya, no mía.

## Lo que sí quedó demostrado

- **El `#418` está arreglado en su caso original**: `D1` 5/5 responde «¡Con gusto! Aquí estoy cuando
  quieras retomar 🙂» tras la derivación, sin «Ya tengo tu cotización», sin «¿seguimos?» y sin cerrar.
- **El rechazo blando funciona**: `C1` da la pregunta de objeción palabra por palabra en 4/5, y `C2`
  cierra con la despedida de una frase en 5/5 **sin** llamar a `Mark Session Closed` — que era
  exactamente tu ajuste.
- **La declinación dura no se rompió**: `C4` 5/5 cierra con la plantilla dura.
- **El «No» a la factura no se contaminó**: `C6` 5/5 sigue al resumen de emisión.
- **El `#444` se sostiene**: `G1a` 5/5 pide nombre, fecha y género sin un solo adjetivo con marca de
  género; `G1b` 5/5 responde «no hace falta que lo tengas todo listo ahora», «tómate tu tiempo»; y con
  el género M guardado (`G2` 5/5) usa la concordancia correcta («No hay problema, Juan…»). Ni un «@»
  ni una «x» en las 59 respuestas.

## Método (por si hay que repetirlo)

- **Sesiones sintéticas** `QA-SUITE-PC-*` sobre la cotización dedicada **2307** (AUDI Q7 2010, lead
  954), teléfonos y `session_id` **sin dígitos**. Una sesión limpia por repetición: 60 en la corrida
  principal y 9 más en las tres repeticiones (`R1`, `R2`, `R3`), 69 en total.
- **Siembra de memoria** (tu aprobación): filas con la forma exacta que escribe el grafo, copiada de
  filas reales de STG —el click `Ver la cotización` y el `quote_document_sent` con
  `metadata.source='quote_document_delivery'` (filas 8834/8835), el envoltorio `=[CTX: …]` de los
  mensajes tecleados y el sufijo `[phase:…]` de las respuestas (filas 5365/5366)—. `D3` y `C6`
  reproducen secuencias reales completas (`waq_2207`, `waq_2385`).
- **Siembra justo antes de cada turno**, no toda al principio: los seguimientos automáticos de Django
  (`django_checkpoint_followup`) escriben filas `ai` en sesiones con checkpoint `quote_sent` y habrían
  contaminado la memoria. Además, tras cada turno el runner comprueba dos cosas: que no haya filas
  ajenas anteriores a la inyección, y que **el número de filas que el agente leyó**
  (`loadMemoryVariables` en el `runData`) **sea igual al de las sembradas**. Si no cuadra, el turno es
  `NO COMPROBABLE`, nunca PASS.
- **Aislamiento**: en los 68 turnos, **cero** nodos de envío alcanzados y **cero** `Issue Policy` /
  `Save Policy Data`. Escrituras, todas sobre las sesiones sintéticas y la cotización dedicada:
  `Save Group1/2/3 Progress` (15) y `Save Quotation Selection` (2, en `G1a`).
- **`Mark Session Closed` observado, no abortado** (tu cambio de política): corrió 9 veces, todas
  donde debía (`C4` ×5, `C5` ×4).
- **Un aviso del propio runner**: el grafo trae un nodo de envío nuevo, **`Send Recovery Document`**
  (aparato de recuperación `#390`), que no estaba en la lista de contrato de los runners anteriores.
  Lo añadí a `SEND_NODES` antes de medir; conviene meterlo también en `runners/e2e_72h_stg.js` y
  `runners/conversacional_stg.js`.
- **Limpieza por IDs exactos, hecha**: 68 sesiones borradas por el runner y 1 más a mano
  (`QA-SUITE-PC-CB-B`, la de la siembra a medias), en `whatsapp_sessions`, `n8n_chat_histories` y
  `n8n_outbound_dispatch`. Comprobado al terminar: **0 filas `QA-SUITE-%` en STG**. La memoria de
  cada sesión se exportó a `memoria/` antes de borrarla.
- **Lo que no pude medir a la primera**: tres turnos (`C2`, `D3`, `G1a`) se perdieron por cortes de red
  de la instancia STG durante el sondeo de la ejecución, y un cuarto (`C2`) no llegó a correr porque la
  siembra se quedó a medias (entró 1 de 4 filas). Los cuatro se repitieron en `R1`/`R2` sobre sesiones
  nuevas y pasaron; ninguno está contado como PASS sin medir. El runner ya lleva reintentos de red.

## Lo que te toca decidir

No promuevo nada a PROD y no toco el grafo. Sobre la mesa:

1. **`C5` es bloqueante para el criterio de tu propio handoff**: la frase que más importa que cierre
   —«no me escribas más»— no llega al agente 6 de cada 10 veces. Se arregla aguas arriba (en el
   `Intent Router`, no en el copy), y merece issue propio: no es regresión del paquete C, es un hueco
   que el paquete C destapó.
2. **La fuga de razonamiento** es lo único que yo consideraría bloqueante del propio paquete: si sale
   a PROD tal cual, uno de cada siete mensajes puede empezar citando `paquete="3"` al cliente.
3. **`D2`/`D3` a 1/5** y **`C3`** son ajustes de redacción, no bloqueantes, si decides que el resto va.

Si quieres que mida algo de esto con N≥20 para declararlo estable, dímelo y lo corro: con el runner ya
hecho son ~40 minutos por caso.

— Agente QA & Testing
