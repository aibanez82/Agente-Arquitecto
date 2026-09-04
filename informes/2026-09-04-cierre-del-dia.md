# Cierre del 4 de septiembre de 2026

> Arquitecto-IA-Qualitas · lo que se cerró, lo que se abrió y lo que aprendimos.

## Lo que quedó cerrado, con medición propia

| Issue | Qué era |
|---|---|
| **`#250`** | La emisión por WhatsApp estaba rota en PROD. Acreditada con **dos emisiones reales**, una de un cliente de verdad (BYD SONG PLUS, 20.673,46 de primer pago). Ventana rota: 2 días y 6 horas, **cero ventas perdidas** |
| **`#292` `#293` `#295` `#298` `#299` `#260`** | Los seis paquetes que viajaron a PROD el 2 sep, certificados uno a uno contra el grafo vivo y la BD |
| **`#302`** | El guard del `#298`, con su **primera observación real en producción** (exec 25689) |
| **`#315`** | A quien pedía «solo daños a terceros» le rebajábamos la Amplia. **Arreglado en STG y en PROD**, con los dos criterios en cada entorno |
| **`#316`** | El bot pedía «Declaración PEP» y no sabía explicarla. Una fila de la KB, corregida y comprobada en conversación real |

## Lo que abrimos, que antes no veíamos

| Issue | Qué |
|---|---|
| **`#306`** | El seguimiento automático escribe **encima de conversaciones vivas**: 40 % de los envíos de PROD, con despedida falsa incluida |
| **`#307`** | La barrera determinista del estado de póliza está **detrás de una puerta probabilística**: de cuatro formulaciones equivalentes, solo dos entran |
| **`#312`** | El carril de descuentos **no se puede ejercitar con sesiones sintéticas**: el claim exige teléfono canonicalizable |
| **`#313`** | «¿Hay descuento si pago de contado?» abría un escalón de descuento |
| **`#320`** | **Decimos que la Limitada no cubre incendio ni inundación y las Condiciones Generales dicen que sí** |
| **`#323`** | El bot **niega la suma asegurada que tiene delante**, por una instrucción nuestra que quedó obsoleta |
| **`#324`** | Afirma que el cliente **tiene Robo Parcial**, que no contrató, con un 25 % inventado |
| **`#325`** | Una pregunta sobre el deducible **reventó el guardrail** y dejó al cliente en silencio |

## Los tres arreglos medidos de punta a punta

**El clasificador de descuentos: de 0/100 a 96/100.** Cinco frases reales que **nunca** se reconocían —«tienes alguna promoción», «Descuentod», «ya es lo menos?», la despedida con competidor— pasan a pleno en dos tandas separadas. Y el falso positivo del contado **baja a cero**: eran fuerzas opuestas y no hubo que elegir. **En STG; en producción sigue vivo.**

**El `#315` en producción**, con la conversación real de Alberto como acreditación.

**El acompañamiento al pedir datos**, que salió en vivo y con testigo: *«No hace falta que me los des todos de golpe, te los voy pidiendo uno a uno.»*

## Lo que aprendimos, que vale más que los arreglos

**Un cambio verificado no es un cambio efectivo.** El acompañamiento se aplicó dos veces con aritmética perfecta, empalme byte a byte y checks 11/11 — **en el nodo que no responde esa pregunta**. La frase del Agente n8n: «un cambio impecable en el nodo que no interviene».

**Del banco salen direcciones y ceros, no probabilidades.** El mismo clasificador dio 8 % por la mañana y 50 % a media mañana con el grafo, el catálogo y el CLI idénticos. Lo que sobrevivió a tres remediciones fueron los ceros — y se confirmaron en vivo: 0 de 11 turnos reales.

**Una barandilla puede caducar.** La instrucción que impedía inventar la suma asegurada era correcta cuando no teníamos el dato. Con el `#194` desplegado, **la misma frase que protegía pasó a impedir decir la verdad**.

**Y el que más me costó:** tres errores míos los cazaron los ejecutores midiendo, no razonando — el contexto que el clasificador no recibe, el nodo que no intervenía, y una frase colocada en el bloque equivocado que **contradecía un issue cerrado dos horas antes**. Los tres eran teorías mías bien argumentadas y falsas.

## Lo que quedó abierto y de quién es

**De Alberto:** el SQL de la Limitada, la orden de promover el clasificador a PROD, y las **nueve preguntas para Hylant** (`docs/preguntas-abiertas-para-hylant.md`) — una de ellas bloquea el arreglo del `#323`.

**De Juan:** el `#272` —**ocho ramas, ocho descripciones del mismo payload, cero filas escritas**—, `#301`, `#303`, `#305` y `#306`.

**En marcha:** el grupo B del set de coberturas, esperando la corrección de la KB.

Agente: Arquitecto-IA-Qualitas
