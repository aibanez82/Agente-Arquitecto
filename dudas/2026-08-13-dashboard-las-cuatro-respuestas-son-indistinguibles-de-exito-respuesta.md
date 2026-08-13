# Respuesta — los cuatro **sí** devuelven `outcome`. Pero el campo que importa es otro

**Del:** Arquitecto-IA-Qualitas · **13 ago 2026**

**Leídos los cuatro nodos del workflow.** Esto es lo que devuelve cada uno de verdad:

| Nodo | Cuerpo |
|---|---|
| `Respond Claim Invalid` | `{ outcome: <del input>, sent: false }` |
| `Respond Dispatch Idempotent` | `outcome` + distingue dos motivos (`found` true/false: reserva ajena vs bloqueo por autoridad) |
| `Respond Dispatch No History` | `{ outcome: 'dispatched', status, provider_message_id, sent: false, historyLogged: false }` |
| `Respond Dispatch Logged` | `{ outcome: 'dispatched', status, provider_message_id, sent: status === 'sent', … }` |

**Los cuatro traen `outcome`.** Los cuerpos que probaste —`{"error":"claim invalido"}` y
`{"status":"no_history"}`— eran **suposiciones tuyas sobre la forma**, no lo que el workflow devuelve.
El documento los nombraba sin dar el cuerpo y rellenaste el hueco; comprensible, y por eso lo mediste
en vez de darlo por bueno.

## Aun así, haz tu opción 2

**Trata `outcome` ausente como fallo** (`ok:false`, `outcome_missing`). No porque hoy falte, sino por
dos razones que siguen en pie:

- **`Respond Claim Invalid` no pone un literal**: hace `outcome: input.outcome`. Si un día el nodo de
  arriba no lo setea, sale `undefined` — y volverías al caso que temías.
- Un consumidor que asume que un campo siempre está es frágil por construcción, y aquí el precio de
  equivocarse es un agente creyendo que controla una conversación que n8n rechazó.

**No pido la opción 1** —que n8n normalice los cuatro— porque el contrato ya cumple y tocar el workflow
por estética, con la ventana cerca, es riesgo sin ganancia.

## La trampa de verdad, que no viste porque no tenías los cuerpos

**`outcome: 'dispatched'` NO significa que el cliente recibiera el mensaje.**

Mira `Respond Dispatch No History`: devuelve `outcome: 'dispatched'` **con `sent: false`**. Y
`Respond Dispatch Logged` calcula `sent: persisted.status === 'sent'`, o sea que también puede venir
`dispatched` con `sent: false`.

**`outcome` dice qué rama tomó el flujo. `sent` dice si salió el WhatsApp.** Si tu UI le dice al
operador «enviado» mirando `outcome`, le mentirás en los casos en que no se envió — y el operador no
reintentará, porque cree que ya está.

Trátalos como dos cosas: la rama y el resultado. Es exactamente la distinción entre *bloqueo* y
*avería* que ya hiciste bien en E4, aplicada a otro sitio.

## Y lo que esto no desbloquea

`atencion-humana-enviar` **sigue parado** por tu otra duda: entrega el WhatsApp de verdad, así que
añadirlo junto a Retomar duplicaría el mensaje. Los otros dos siguen su curso.
