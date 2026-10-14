# Mejoras Conversación → Arquitecto: la pausa ofrece el descuento, de forma coherente

**Fecha:** 14-oct-2026 · **Caso:** `waq_4450`/`waq_4451` (BR-V), filas 15666–15677
**Decisión de Alberto (14-oct, en mi sesión):** sí, una pausa sin descuento previo abre el descuento, firmado como regla y con el mensaje del precio. **Pero lo que más le importa es que la conversación sea coherente**, y aquí no lo es. Texto suyo de referencia:
> ok, está bien tomarse tiempo, pero si quieres puedo ofrecerte un descuento extra si contratas hoy conmigo. ¿Quieres ver cómo queda?

Alberto lo tiene que firmar en la bandeja: su autorización te llega por ahí, no relatada por mí.

## Qué falla hoy (el caso)
| Fila | Quién | Texto |
|---|---|---|
| 15666 | Seguimiento | «¿Cómo te pareció tu cotización del *BR-V* por *$8,863.59 MXN*? ¿Avanzamos?» |
| 15667 | Cliente | «Bien gracias voy a checarlo y me comunico con ustedes» |
| 15668 | Bot | «Déjame checar tu cotización para buscarte el mejor precio posible. Ahorita te cuento.» |
| 15670 | Bot | «¡Lo conseguí! 🎉 Hay un descuento aprobado… Logré un descuento especial si contratas hoy conmigo» |

El cliente dice «me tomo mi tiempo» y el bot contesta a otra cosa, como si hubiera pedido un precio mejor. No reconoce lo que dijo, no le pregunta, y además repite el anuncio del descuento en la misma burbuja.

## Textos propuestos

**P1 · El cliente pausa y aún no hubo descuento** («lo checo», «lo voy a revisar», «voy a checarlo y me comunico», «lo pienso»). Sustituye a la entrada directa en el carril:
> Claro, está bien tomarte tu tiempo. Solo una cosa: si quieres, puedo ofrecerte un descuento extra si contratas hoy conmigo. ¿Quieres ver cómo queda?

**P2 · El cliente dice que sí** («sí», «a ver», «va», «Aceptar»). Entra el carril de descuento como hoy, con el anuncio limpio:
> ¡Lo conseguí! 🎉 Me aprobaron un descuento para tu cotización. Ya estoy armando la nueva y te la mando por aquí en cuanto esté lista.

(Se quita la frase pegada al final, «Logré un descuento especial si contratas hoy conmigo».)

**P3 · Llega el PDF con descuento.** L5 firmado, **enviado justo después del PDF sin esperar a que el cliente escriba**. Es «el mensaje con el precio» que pide Alberto:
> Con el descuento, tu *[VEHÍCULO]* queda en *$[PRECIO_VIGENTE] MXN* al año. ¿Te la dejo lista para contratar?

**P4 · El cliente dice que no a P1** («no», «no gracias», «luego»). D1 firmado, y no se vuelve a ofrecer:
> ¡Con gusto! Tu cotización queda guardada; cuando quieras retomarla, escríbeme por aquí 🙂

## Reglas (grafo)
1. **P1 sale una sola vez por conversación.** Sustituye al gancho D2 cuando aún no hubo descuento. Si ya hubo descuento, la pausa recibe D2 (o el texto 3 del `#596` cuando se firme).
2. **El carril de descuento solo entra después de un sí a P1.** Ya no entra directo ante una pausa.
3. **No aplica a una despedida pura** («gracias, ya contraté», «ya conseguí»): esas reciben D1 o D5 y no se ofrece descuento.
4. **P3 sale automáticamente con el PDF con descuento.** Si se automatiza también el texto 2 del `#596` (+20 min), este va después de P3, no en su lugar.

## Pendiente que cruza
P1 dice «si contratas hoy conmigo», con las palabras de Alberto. Según el `#596` §0, el descuento no caduca hoy en los datos (33 h, como mínimo). Si Alberto elige H en la decisión V/H, P1 queda así:
> Claro, está bien tomarte tu tiempo. Solo una cosa: si quieres, puedo ofrecerte un descuento extra para tu cotización. ¿Quieres ver cómo queda?

Agente: Mejoras Conversación
