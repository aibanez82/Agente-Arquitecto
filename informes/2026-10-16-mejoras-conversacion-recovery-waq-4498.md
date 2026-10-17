# Mejoras Conversación → Arquitecto: Recovery, `waq_4498` (MINI Cooper Countryman 2019, tel …9382)

**Fecha:** 16-oct-2026, revisado a las 18:42 CDMX · **Lo pidió:** Alberto · **Campaña:** 6 (`#551`) · Solo lectura.

## Datos
- **Lead de origen:** 3825, de la carga del 1-oct por la noche.
- **Cotización nueva:** 4498. Sesión `waq_4498_5d6d0629a59f` en `greeting`; último mensaje a las 15:53. Sin póliza.
- **Plantilla:** `customer_recovery_quote_v1` enviada a las 15:25.
- **`captured_data.previous_policy`:**
  - póliza **7620094767**, AMPLIA, contado;
  - **prima total $15,932.89**;
  - `valid_to` 2027-05-04;
  - `issued_at` 2026-08-22 con el endoso 281535;
  - **`source_user: CANCELA-AUT`**.
- **`recovery_precarga.nombre_completo`: «GESTION Y TECNOLOGIA AMBIENTAL»**. Es una **empresa**.
- **Cotización 4498, Amplia anual: $12,311.85**, con `fecha_inicio` el **17-oct**.

## La conversación
| Hora | Fila | Quién | Texto |
|---|---|---|---|
| 15:40 | 16335 | Cliente | «De qué vehículo es?» |
| 15:40 | 16336 | Bot | «Tu cotización es para un MINI COOPER 2019. ¿Seguimos con tus datos para continuar?» |
| 15:53 | 16347 | Cliente | «**ya se venció el seguro?!? desde cuando?** / Trimestral en cuanto saldría» |
| 15:53 | 16350 | Bot | «Entiendo tu sorpresa — esa póliza no estaba vencida por fecha (su vigencia llegaba hasta mayo de 2027), pero en nuestros registros ya no aparece activa. Por eso te estamos ofreciendo una póliza nueva…, que empezaría hoy mismo.» Y después **las 6 opciones** (4 de Amplia y 2 de Limitada) y «¿Cuál te gustaría contratar?» |

**Ojo con 16336:** tu handoff pone `waq_4498` (15:40) entre las conversaciones del `#617` que se quedaron sin respuesta. En el historial la respuesta está, pero puede que no llegara al cliente. Su segundo mensaje, 13 minutos después, no sigue a 16336, y eso cuadra con que no la viera. **Compruébalo en la ejecución.**

## Lo que falla (copy)
1. **El cliente se entera a medias de que no tiene seguro.**
   - «Ya no aparece activa» es vago. El dato dice que Quálitas **la canceló de forma automática** (`CANCELA-AUT`), probablemente el 22-ago (`issued_at` del endoso). Esa fecha hay que confirmarla.
   - El cliente preguntó «¿desde cuándo?» y no se le contestó.
   - Es el momento con más valor de toda la campaña: hoy no tiene seguro y no lo sabía.
2. **Dice «empezaría hoy mismo» y la cotización empieza el 17-oct**, mañana. Para alguien sin seguro, ese día de diferencia importa.
3. **No contesta lo que preguntó.** Pidió el trimestral y recibió seis opciones, con la Limitada sin pedirla (`#461`).
4. **No usa el mejor argumento que tenía.** La póliza anterior costaba $15,932.89 y hoy la Amplia anual son $12,311.85, un 23% menos. `commercial_comparison` sale `unavailable` («previous_quote_missing») porque busca una *cotización* anterior, pero el dato está en `previous_policy.total_premium`. Es lo que propone el `#394`.
5. **16336** respondió «De qué vehículo es?» sin explicar de dónde sale la cotización. Un cliente de Recovery no recuerda haber pedido nada.

## Texto propuesto para 16350 (prima anterior solo si Alberto lo aprueba)
> Tu póliza anterior del MINI Cooper (7620094767) la canceló Quálitas de forma automática el [FECHA_CANCELACIÓN], así que hoy tu auto no tiene seguro vigente. Por eso te mandamos esta promoción: una póliza nueva con Cobertura Amplia que empieza el [FECHA_INICIO].
> En trimestral queda en un primer pago de $3,945.91 y luego 3 pagos de $3,052.75 ($13,104.16 en total). Si la pagas anual son $12,311.85, menos que los $15,932.89 de tu póliza anterior.
> ¿Te la dejo lista para contratar?

**Para 16336:**
> Es para tu MINI Cooper Countryman 2019, el que tenías asegurado con nosotros. Tu póliza anterior ya no está activa, y por eso te mandamos un precio especial para volver a asegurarlo. ¿Te cuento cuánto queda?

**Reglas:**
- La causa de la cancelación («un recibo sin pagar») **solo se dice si el dato la trae**. `CANCELA-AUT` dice que fue automática, no por qué.
- La fecha de inicio sale de `vigencia.fecha_inicio`, nunca «hoy» a ojo.

## Riesgo que no es copy
**El asegurado es una persona moral** («GESTION Y TECNOLOGIA AMBIENTAL»). El flujo de WhatsApp pide nombre, fecha de nacimiento y género, y calcula el RFC de persona física (`#545`). Si el cliente dice que sí, **el bot no sabe emitir esta póliza**.
- ¿Admite la campaña 6 personas morales? Si no, hay que excluirlas del lote, o darles una salida: derivarlas a una persona o al carril que exista para empresas.
- Lo dejo para el tracker.

Agente: Mejoras Conversación

## Adenda (16-oct, correcciones del Arquitecto, `75e25f0`)
- **La campaña 6 son pólizas que Quálitas canceló por impago** (`reason=cancelled_nonpayment`, datos en `qualitas_recoveryprofile`), no leads que no compraron. **El motivo sí lo trae el dato**, así que la regla de «solo si el dato la trae» se cumple. Qué tan explícito ser («por un pago pendiente») lo decide Alberto. Propuesta suave:
  > Tu póliza anterior del MINI Cooper (7620094767) se canceló el [FECHA] porque quedó un pago pendiente, así que hoy tu auto no tiene seguro vigente.
- **16336 sí llegó al cliente** (15:40:59, con wamid). Lo que perdió el `#617` fue el turno siguiente (ejecución 96652, 15:41, Ver Promo Copy). La lectura de la conversación no cambia.
- La persona moral está confirmada en la precarga. La pregunta de si la campaña admite empresas la decide Alberto.

**Decisión de Alberto (16-oct, en mi sesión):** la versión suave le parece bien: «Tu póliza anterior del [VEHÍCULO] se canceló el [FECHA] porque quedó un pago pendiente, así que hoy tu auto no tiene seguro vigente.» Pendiente de firma en la bandeja.
