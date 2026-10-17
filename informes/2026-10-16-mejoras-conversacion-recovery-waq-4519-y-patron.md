# Mejoras Conversación → Arquitecto: Recovery, `waq_4519` (Mazda CX-30 2024, tel …2345) y un patrón de la plantilla

**Fecha:** 16-oct-2026, revisado a las 19:00 CDMX · **Lo pidió:** Alberto · **Campaña:** 6 (`#551`) · Solo lectura.

## `waq_4519`
- **Plantilla:** enviada a las 15:25.
- **Póliza anterior:** 7620094572, AMPLIA, contado, **$15,816.73**, `CANCELA-AUT` (endoso del 15-ago).
- **Precio calculado por Django** para la plantilla: **$13,332.05** (`quoted_total`), un 16% menos.

| Hora | Fila | Quién | Texto |
|---|---|---|---|
| 17:08 | 16373 | Cliente | «De qué vehículos?» |
| 17:08 | 16374 | Bot | «Tuvimos un problema procesando tu mensaje, ¿puedes repetirlo?» |

- **No es un defecto de copy.** Cae dentro de la avería por cuota de Anthropic (desde las 16:41).
- **El cliente no ha vuelto a escribir.** Sigue recuperable: tiene la pregunta sin responder y la sesión activa.

## El patrón que sí es copy: la plantilla no dice de qué auto se trata
De los 7 clientes de la campaña 6 que escribieron, **3 preguntaron primero de qué vehículo era:**
- `waq_4498` «De qué vehículo es?»
- `waq_4500` «Que carro es»
- `waq_4519` «De qué vehículos?»

**Qué pasa:**
- Los `template_params` de `customer_recovery_quote_v1` llevan `quoted_total`, `previous_total_premium`, `cheaper` y `applied_percentage`, pero **no el vehículo**.
- Un cliente cuya póliza se canceló hace dos meses no relaciona la promoción con su auto.

**Propuesta (plantilla de Meta, Django):**
- Añadir la variable del vehículo a la plantilla, por ejemplo: «…tu *[MARCA MODELO AÑO]*…».
- Ojo con la categoría: si se vuelve a someter, que no pase a MARKETING. La pasada vez esa reclasificación rompió la entrega.
- **Mientras tanto, respuesta del bot** a «¿de qué vehículo?» en Recovery:
  > Es para tu *[VEHÍCULO]*, el que tenías asegurado con nosotros. Tu póliza anterior se canceló el [FECHA] porque quedó un pago pendiente, así que hoy no tiene seguro vigente. Por eso te mandamos un precio especial para volver a asegurarlo. ¿Te digo cuánto queda?

  (Usa la frase del motivo aprobada por Alberto hoy.)

## El dato para comparar ya lo calcula Django
Las 84 plantillas de la campaña 6 llevan en sus parámetros:
- `cheaper: true` (las 84);
- `previous_total_premium` y `quoted_total`;
- el ahorro: 17% de media, con mínimo 0% y máximo 58%;
- `applied_percentage`: 30.

La regla «solo si hoy es más barato» ya se cumple en todo el lote por construcción. **La frase opcional del `#394` puede alimentarse de aquí.** Ojo: el precio de la cotización que se genera al pulsar «Ver promo» puede variar algo frente a `quoted_total` (`waq_4498`: $12,255.98 en la plantilla y $12,311.85 en la cotización). El bot tiene que comparar contra la cotización vigente, no contra el parámetro de la plantilla.

## Clientes que se quedaron con el mensaje de error y siguen sin respuesta (para recuperar a mano)
| Sesión | Qué escribió | Qué recibió |
|---|---|---|
| `waq_4519` | «De qué vehículos?» | Error de cuota |
| `waq_4518` | «**Estoy pagando una poliza mensual con ustedes mismos**» | Error de cuota |
| `waq_4521` | «No» | Error de cuota |
| `waq_4507` | «Sería al año / No me aparece / El precio» | Bucle de «Ver promo» y 2 errores de cuota |

**`waq_4518` es delicado:** el cliente cree que sigue pagando una póliza con nosotros, y en la campaña figura como cancelada por impago. O tiene otra póliza, o no sabe que esta se canceló. Lo tiene que mirar una persona antes de que el bot le ofrezca nada (es terreno del `#566`, postventa).

Agente: Mejoras Conversación

## Adenda: `waq_4521` (Chevrolet Groove 2023, tel …9692), lo pidió Alberto
- **Póliza anterior:** 7620080151, AMPLIA, contado, **$13,825.56**, `CANCELA-AUT` (endoso del 31-ago).
- **Plantilla:** enviada a las 15:21, con un precio de **$11,258.93** (19% menos).
- **17:12, fila 16375:** el cliente escribe **«No»**.
- **Fila 16376:** recibe el error de cuota («¿puedes repetirlo?»). Es avería, no copy. Pedirle que repita un «No» se lee mal, pero lo provocó la caída.
- La sesión lleva `recovery_solo_contexto: true` y la cotización 4521 se creó 9 s después del «No». **No pulsó «Ver promo».**

**Cómo debería tratarse un «No» a la plantilla de Recovery**, y cómo responder a mano si alguien lo retoma:
> Entendido, no te insisto. Solo para que lo sepas: tu póliza anterior del Chevrolet Groove se canceló el 31 de agosto porque quedó un pago pendiente, así que hoy tu auto no tiene seguro vigente. Si más adelante quieres volver a asegurarlo, escríbeme por aquí y te paso tu precio especial.

**Por qué:**
- Respeta el no: un solo mensaje, sin pregunta de objeción y sin precio.
- Le da el único dato que quizá no tiene, que circula sin seguro, con la frase del motivo aprobada hoy.
- Si vuelve a decir que no o no contesta: D1 y se le saca de los seguimientos de la campaña.
- La fecha del 31-ago sale del endoso de cancelación, como la del 22-ago en `waq_4498`.

**Cambio de Alberto al cierre (16-oct):** «…así que hoy tu auto no tiene seguro vigente. Si te interesa quedar cubierto hoy mismo y a un mejor precio que antes, pulsa el botón para ver la cotización.» Señalé dos riesgos:
1. **«Hoy mismo»:** la cotización empieza al día siguiente (`vigencia.fecha_inicio`). Propuesta: «desde el [FECHA_INICIO]».
2. **«Pulsa el botón»:** el botón está en la plantilla anterior y algunos clientes no lo encuentran (`waq_4507`). Propuesta: que esta respuesta lleve su propio botón «Ver promo», o «toca *Ver promo* en el mensaje anterior».

Versión con los dos ajustes:
> Entendido, no te insisto. Solo para que lo sepas: tu póliza anterior del [VEHÍCULO] se canceló el [FECHA] porque quedó un pago pendiente, así que hoy tu auto no tiene seguro vigente. Si te interesa quedar cubierto desde el [FECHA_INICIO] y a un mejor precio que antes, toca *Ver promo* para ver tu cotización.

## Adenda: `waq_4518` (Nissan Kicks 2019, tel …5940), lo pidió Alberto
- **Póliza anterior:** 7620093062, AMPLIA, **$8,619.83**, `payment_term: C`, `CANCELA-AUT` (endoso del 15-ago), agente 88199.
- **Plantilla:** enviada a las 15:24, con un precio de $6,958.27 (19% menos). No pulsó «Ver promo» (`recovery_solo_contexto: true`).
- **17:04, fila 16371:** «Estoy pagando una poliza mensual con ustedes mismos».
- **Fila 16372:** error de cuota. Es avería, no copy.
- **En nuestra BD no hay ninguna otra póliza**, ni por teléfono ni por número de serie, y la 7620093062 no tiene filas en `conciliacion_pagos`.

**Un dato que cambia la lectura:** **las 22 sesiones de Recovery tienen `payment_term: C`** (contado), sin excepción.
- Que 498 pólizas canceladas por impago sean todas de contado es poco creíble. Lo normal es que se cancelen por recibos mensuales sin pagar.
- **Es probable que `payment_term` no refleje la forma de pago real**, y que la clienta tenga razón en que pagaba mensual.
- Si es así, la comparación «antes y ahora» de la propuesta 37 compara un total fraccionado (más caro, con financiamiento) contra un anual de contado, y **infla el ahorro**. **Hay que comprobar `payment_term` antes de firmar esa frase.**

**Qué responderle** (a mano ahora, o como regla cuando el cliente dice que sigue pagando). Sigue la decisión de Alberto del 7-oct en el `#566`: el bot no afirma nada sobre cargos o domiciliación, da los hechos y deriva:
> Gracias por avisarme, María del Rosario. En nuestros registros tu póliza 7620093062 del Nissan Kicks aparece cancelada desde el 15 de agosto por un pago pendiente. Si sigues viendo cargos, hay que aclararlo: le paso tu caso a una persona de nuestro equipo para que lo revise contigo por aquí mismo.

**No se le ofrece la promoción** hasta que una persona lo haya aclarado: podría tener otra póliza vigente, o un cargo indebido.

## Adenda: `waq_4507` (Dodge Neon 2000, tel …3207), el bucle de «Ver promo», lo pidió Alberto
- **Póliza anterior:** 7620085787, AMPLIA, $8,443.14, `CANCELA-AUT` (endoso del 31-ago).
- **Plantilla:** enviada a las 15:22 con `quoted_total` de $6,976.52. Nunca pulsó «Ver promo».

| Hora | Fila | Quién | Texto |
|---|---|---|---|
| 16:14 | 16354 | Cliente | «Sería al año» |
| 16:14 | 16355 | Bot | «Para darte tu precio con la promoción, toca el botón *Ver promo* del mensaje que te envié y te mando tu cotización al momento.» |
| 16:18 | 16356–57 | Cliente / Bot | «No me aparece» → **el mismo texto** |
| 16:25 | 16358–59 | Cliente / Bot | «El precio» → **el mismo texto** |
| 16:25 | 16360–61 | Cliente / Bot | «No me aparece» → **el mismo texto** (4.ª vez) |
| 16:39 | 16366 | **Operadora (a mano)** | «Debajo del primer mensaje que te mande, aparece un botón, me apoyas presionando…» |
| 16:41 | 16367 | Cliente | «**Ese es el msj nada más**» |
| 16:41–42 | 16368–70 | Bot | Error de cuota, dos veces (avería) |

**Diagnóstico de copy:**
1. **El cliente no ve el botón**, y lo dice tres veces. Puede ser WhatsApp Web, una versión vieja o que la cabecera de imagen no cargue. Repetirle la instrucción no sirve.
2. **Pidió el precio dos veces («Sería al año», «El precio») y no lo recibió nunca**, aunque Django ya lo tenía calculado ($6,976.52 en `quoted_total`).
3. **El mismo texto cuatro veces seguidas.** Choca con la regla de no repetir un mensaje palabra por palabra (firmada el 10-oct en la petición de llamada).

**Propuesta** (encaja con la adenda 20, que ya pide el PDF por texto):
- **Primer mensaje escrito en vez de pulsar el botón:** se genera la cotización y se manda, sin mencionar el botón:
  > Claro. Te mando ahora mismo tu cotización con la promoción para tu *[VEHÍCULO]*.

  Al llegar el PDF, el texto con la cifra (estilo L5):
  > Tu *[VEHÍCULO]* queda en *$[PRECIO_VIGENTE] MXN* al año con Cobertura [COBERTURA]. ¿Te la dejo lista para contratar?
- **Si técnicamente aún hace falta el botón:** mencionarlo **una sola vez** y dar la salida por texto desde la primera respuesta:
  > Para darte tu precio, toca *Ver promo* en el mensaje anterior. Si no te aparece, no te preocupes: escríbeme *Sí* y te mando tu cotización por aquí.
- **Nunca dar la cifra de `quoted_total` a ojo:** la cotización que se genera puede variar un poco (`waq_4498`: $12,255.98 frente a $12,311.85). La cifra sale de la cotización vigente.

**Para recuperarlo a mano ahora:** mandarle la cotización 4507 y el precio, sin volver a hablar del botón.

## Adenda: `waq_4506` (Volvo XC40 2022, tel …3816), lo pidió Alberto
- **Póliza anterior:** 7620093433, AMPLIA, $24,668.86, `CANCELA-AUT`.
- **Plantilla:** enviada a las 15:24 (`quoted_total` $18,257.07). **Pulsó «Ver promo»** (`recovery_solo_contexto: false`); la cotización 4506 se creó a las 16:06.
- **16:28, fila 16362:** «Si» → `Save_Quotation_Selection`, Amplia anual a $18,329.65 → **fila 16365:**
  > Continuamos con *Cobertura Amplia, pago anual de $18,329.65 MXN*. Ya tengo tu nombre (Luis Alfredo Marin Lopez), solo confírmame tus apellidos paterno y materno para separarlos bien. Y para seguir, no te preocupes, no hace falta que me des todo junto: vamos paso a paso. Dime también tu fecha de nacimiento (DD/MM/AAAA) y género (M/F).
- **Desde las 16:28 no ha vuelto a escribir.** Es antes de la avería de cuota, así que no le afecta. **Es el que más lejos llegó de la campaña:** aceptó y entró en `data_capture`.

**Fricción de copy:**
- Un párrafo denso que pide **tres cosas a la vez** (confirmar la separación de apellidos, la fecha de nacimiento y el género) con un «no hace falta que me des todo junto» metido en medio.
- Además, la confirmación de apellidos sobra: «Luis Alfredo Marin Lopez» son dos nombres y dos apellidos, y no hay ambigüedad.

**Propuesta:**
- **Con nombre precargado de 4 palabras** (o 3 o más sin partículas compuestas), separar sin preguntar y pedir solo lo que falta, en lista:
  > Continuamos con *Cobertura Amplia, pago anual de $18,329.65 MXN*.
  > Ya tengo tu nombre: *Luis Alfredo Marín López*. Para terminar tus datos solo me falta:
  > - Fecha de nacimiento (DD/MM/AAAA)
  > - Género (M/F)
- **Preguntar la separación solo si es ambigua:** 3 palabras («Juan Pérez García» puede ser un nombre y dos apellidos, o dos nombres y un apellido), o con «de», «del», «de la»:
  > ¿Tus apellidos son *[AP1] [AP2]*?

**Para recuperarlo a mano:**
> Hola, Luis Alfredo, seguimos con tu Volvo XC40 2022: Cobertura Amplia a $18,329.65 al año. Para emitir tu póliza solo me falta tu fecha de nacimiento (DD/MM/AAAA) y tu género (M/F).

**Pregunta para el grafo:** en 3 horas no salió ningún seguimiento automático. ¿Las sesiones de Recovery están fuera de los checkpoints de Django, o aquí no había checkpoint porque todavía no se había guardado el grupo 1?

## Adenda: `waq_4500` (Nissan Versa 2020, tel …8652), lo pidió Alberto
- **Póliza anterior:** 7620094585, AMPLIA, $11,782.71, `CANCELA-AUT`.
- **Cotización:** con el CP **67277** (Nuevo León). `quoted_total` $9,323.86. Pulsó «Ver promo».

| Hora | Fila | Quién | Texto |
|---|---|---|---|
| 15:47 | 16337–38 | Cliente / Bot | «Que carro es» → «Tu cotización es para un Nissan Versa 2020.» (patrón del vehículo) |
| 15:50 | 16339 | Cliente | «Puedes respetar elmprecio andando en otra ciudad» |
| 15:50 | 16341 | KB | Devuelve: «Si se comprueba que proporcionaste un domicilio o código postal diferente al de tu residencia… se aplicará un **doble deducible**» |
| 15:50 | 16342 | Bot | «Tu cobertura aplica en toda la República… y **el precio de tu póliza no cambia por manejar en otra ciudad**.» |
| 15:51 | 16343–44 | Cliente / Bot | «Con placas de estado de México» → «No hay problema… ¿cuáles son tus apellidos paterno y materno?» |
| 15:52 | 16345–46 | Cliente / Bot | «Cambie de placas / Del estado de México» → «tomamos nota… ¿me compartes tus apellidos…?» |

**Diagnóstico:**
1. **El cliente se mudó al Estado de México** y pregunta si le respetan el precio cotizado con el CP de Nuevo León. El bot contesta a otra pregunta (si la cobertura vale en otra ciudad) e **ignora el aviso de la KB que tenía delante**. En la práctica le anima a contratar con un CP que no es el de su residencia, y eso puede traerle un **doble deducible en un siniestro**. **Es el riesgo más serio de lo revisado hoy en Recovery.**
2. **Pide los apellidos dos veces sin que el cliente haya aceptado nada**, y mientras el cliente explica su situación. Es el patrón del `#610`: empuja a datos sin aceptación.
3. Tampoco le da el precio en ningún momento.

**Propuesta para 16342** (cliente que dice vivir o circular en otro estado, o que cambió las placas):
> Buena pregunta. Tu seguro te cubre en todo el país, pero el precio se calcula con el código postal de donde vives. Si ahora vives en el Estado de México, tengo que ajustar tu cotización a tu nuevo código postal: si no, en un siniestro Quálitas podría aplicarte doble deducible. ¿Me compartes el código postal de donde vives ahora?

Recotizar con el CP nuevo sin perder la promoción es justo el `#608` (abierto el 14-oct por el caso del Camry). Hasta que exista, el caso pasa a una persona.

**Regla:** si la KB devuelve el fragmento del doble deducible por CP, el bot no puede afirmar que «el precio no cambia».

**Para recuperarlo a mano:** el texto de arriba, y que una persona recotice con el CP nuevo.

## Adenda: `waq_4519` continúa (Isidro, Mazda CX-30 2024, tel …2345), lo pidió Alberto
Revisado a las 21:22 CDMX. La sesión está en `data_capture` y el último mensaje es de las 20:10. Sin póliza.

| Hora | Fila | Quién | Texto |
|---|---|---|---|
| 19:12 | 16393 | Operadora (manual, «usted») | «Una disculpa Isidro, ya estamos de vuelta… El vehículo cuya póliza se venció por impago de un recibo es el Mazda CX-30 2024.» |
| 19:13 | 16394 | Operadora | «Su póliza anterior le costaba $15,816.73. Hoy se la ofrecemos en $13,332.05 (16% menos)…» |
| 19:36 | 16397–98 | Cliente / Bot | «Hace cuanto se vencio?» → **Ver Promo Copy** («toca el botón *Ver promo*…») |
| 19:36 | 16399–400 | Cliente / Bot | «Me lo puedes mandar el pago Tri menestral porfa?» → **el mismo Ver Promo Copy** |
| 19:39 | 16401–04 | Cliente / Bot | «Si pero en pagos trimestrales» → guarda Amplia trimestral ($4,237.18 + 3 × $3,343.97) y pide apellidos ✅ |
| 20:01 | 16411–14 | Cliente / Bot | «Isidro Cornejo Peralta» → guarda nombre y pide fecha de nacimiento y género ✅ |
| 20:09 | 16419–20 | Cliente / Bot | «Tú ya cuentas con esos datos» → «No tengo registrada tu fecha de nacimiento ni tu género todavía…» |
| 20:09 | 16421–22 | Cliente / Bot | «Pero ya contraté seguro contigo antes» → **«Gracias por avisarme, Isidro. ¡Que te vaya muy bien con tu seguro! 🙂»** |
| 20:10 | 16423–24 | Cliente / Bot | «Como eso es posible que no tengas esos datos» → «…esta es una póliza nueva y necesito confirmar tus datos directamente contigo…» |

**Diagnóstico:**
1. **16422 despide a un cliente que estaba comprando.** «Ya contraté contigo antes» se leyó como «ya tengo seguro con otro» y salió el cierre de rechazo, justo cuando el cliente ya había elegido el trimestral. En Recovery, «ya contraté con ustedes» es lo esperable: el cliente fue nuestro. El mensaje 16421 no lleva `CTX`, así que no lo contestó el AI Agent. **Arquitecto: ¿qué nodo lo cerró?** Puede ser el Intent Router.
2. **El Ver Promo Copy salió dos veces 2 h y media después de abrirse la sesión**, después de que la operadora ya había dado el precio. Es el mismo bucle de `waq_4507`, y aquí además tapa dos preguntas reales. 16397 y 16399 tampoco llevan `CTX`, y 16401, tres minutos después, sí. No hay pulsación de botón registrada en `qualitas_whatsappmessage`. **Arquitecto: ¿qué decide el enrutado entre Ver Promo Copy y AI Agent?**
3. **«¿Hace cuánto se venció?» no se contestó nunca.** Es la misma pregunta que en `waq_4498` («¿desde cuándo?»).
4. **16420 y 16424 no explican por qué faltan datos.** El cliente cree que ya los tenemos. La precarga solo trae nombre, serie y CP (`grupo1` vacío). Decir qué nos llegó y qué no quita la sospecha.
5. **La comparación de primas de la operadora (16394)** usa el `payment_term=C`, que no es fiable. Aquí el riesgo es bajo: incluso el trimestral ($14,269.09) queda por debajo de $15,816.73.

**Propuesta para 16422** (Recovery, el cliente dice que ya fue cliente):
> Sí, Isidro, tu Mazda CX-30 estuvo asegurado con nosotros (póliza 7620094572). De esa póliza me llegaron tu nombre, la serie y tu código postal, pero no tu fecha de nacimiento ni tu género, por eso te los pido. ¿Me los compartes? Fecha (DD/MM/AAAA) y género (M/F).

**Propuesta para 16420 y 16424** (el cliente dice «ya tienes mis datos»):
> De tu póliza anterior me llegaron tu nombre, la serie de tu Mazda y tu código postal, pero no tu fecha de nacimiento ni tu género. Con esos dos datos sigo: fecha (DD/MM/AAAA) y género (M/F).

**Propuesta para 16398** («¿hace cuánto se venció?», con la frase aprobada por Alberto):
> Tu póliza anterior del Mazda CX-30 se canceló el 15 de agosto porque quedó un pago pendiente, así que desde entonces tu auto no tiene seguro vigente. Hoy te la dejo en $13,332.05 de contado, o en trimestral con un primer pago de $4,237.18. ¿Cuál prefieres?

La fecha sale del `issued_at` del endoso de cancelación (15-ago), igual que en `waq_4518`. Hay que confirmar que esa es la fecha de cancelación.

**Reglas:**
- En una sesión con `poliza_anterior_recovery`, «ya contraté contigo / con ustedes / antes» **nunca** dispara el cierre de «ya tengo seguro».
- Una vez abierta la sesión de Recovery, o si el cliente ya eligió paquete, no vuelve a salir el Ver Promo Copy.

**Para recuperarlo a mano (ahora):** la propuesta para 16422. El cliente quedó molesto, pero a dos datos de la emisión.
