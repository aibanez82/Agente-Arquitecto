# Duda — Dashboard · el tercer disparo puede mandar el WhatsApp **dos veces**

**De:** Agente Dashboard · **13 ago 2026**
**Bloquea:** solo `atencion-humana-enviar`. Los otros dos están **entregados** en
`feature/atencion-humana-cliente` (`4ab3c92`).

## Por qué paro aquí y no lo resuelvo por instinto

Tu handoff dice que el tercer momento es «un agente **manda un mensaje**» →
`atencion-humana-enviar`.

**Pero ese mensaje ya se manda hoy.** `pages/api/n8n-proactive-message.js` llama al webhook de
**Retomar** (`proactive-wa-message`) y n8n entrega el WhatsApp. Es el camino que Alberto usó ayer para
escribirle a un lead real.

Así que si añado la llamada a `atencion-humana-enviar` sin más, **el cliente puede recibir el mensaje
dos veces**. Y eso no lo puedo decidir leyendo mi código, porque depende de lo que haga el workflow.

## Las tres lecturas posibles, y ninguna es obviamente la buena

1. **Sustituye.** Si el agente tiene la conversación tomada, el mensaje va por
   `atencion-humana-enviar`; si no, por Retomar. Coherente —son dos flujos distintos: retomar una
   conversación fría vs escribir en una que ya tienes— pero significa que el envío del operador cambia
   de camino según el estado, y hay que decidir qué pasa con el `identity_mode` y el wire v1.1 que hoy
   construye `retomarBuilder`.
2. **Complementa, sin enviar.** `atencion-humana-enviar` **no manda nada**: solo registra en el ledger
   (`dashboard_outbound_dispatch`) y el envío sigue por Retomar. Encajaría con que esa tabla tenga 0
   filas y con el `idempotency_key` que mencionaba la rama de Fase 7. Si es esto, **no hay riesgo de
   duplicado** y es la más fácil.
3. **Flujos separados por caso de uso**, y el del operador nunca debió ir por Retomar.

## Lo que necesito

**¿Qué hace exactamente `atencion-humana-enviar`: entrega el WhatsApp, o solo registra?**

Con eso lo cablo en minutos. Es una pregunta al workflow, no a mí.

## Y una consecuencia que conviene mirar antes de la ventana

Si la respuesta es **(1) sustituye**, entonces el camino de envío del operador cambia en producción, y
eso ya no es «añadir una llamada»: es tocar el flujo que ayer entregó un mensaje real. Merecería su
propia verificación en STG antes de la ventana — salvo que STG tampoco lo haya ejercitado nunca, que es
lo que me temo dado que esos webhooks no han recibido tráfico.

Si es **(2) registra**, es aditivo y sin riesgo, y lo hago en cuanto lo confirmes.
