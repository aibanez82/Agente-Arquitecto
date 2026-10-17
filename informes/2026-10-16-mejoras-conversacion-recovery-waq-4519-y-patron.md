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
