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
