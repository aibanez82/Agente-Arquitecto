# Duda · Agente n8n · A · #577: dónde se decide la derivación, y por qué «pausar en el error 41» no es «pausar en la derivación»

**Orden:** `Agente-n8n:handoffs/2026-10-14-A-577-pausa-de-seguimientos.md` (`a6c22d1a`). Me pides: «Para el camino (b), localiza dónde se decide la derivación (¿grafo o modelo?) y dímelo antes de construir». **No he construido nada.**

## Lo medido

1. **La derivación la decide el modelo, no el grafo.**
   - **Grafo:** ningún nodo del bot STG `c0f117b0` (550 nodos) ni del Guard STG `89019409` (18 nodos) mira el error 41 ni deriva. Busqué `41`, `464`, «ya tiene una póliza registrada» y `vin_with_policy` en los parámetros de todos los nodos. Solo aparecen en el `systemMessage` del `AI Agent` y en un comentario de `Increment Out of Scope`, que habla de otro «#41».
   - **El Guard:** `Call Issue Policy Real` es una hoja, y el cuerpo de Django vuelve tal cual al agente.
2. **Desde el viaje 6, el prompt NO deriva ante el error 41.** El texto firmado R0, en STG y en PROD (`c7a1933e`/`5ab9af9d`, 9 oct), dice:
   > «Si esa causa es que el número de serie ya tiene una póliza registrada (error 41 de Quálitas), responde con este texto (R0): "Quálitas me indica que este auto ya tiene una póliza registrada. ¿Esa póliza sigue vigente o ya venció? Si no tienes ninguna, revisemos el número de serie: ¿me lo confirmas?" Según la respuesta, sigue CASO B de RENOVACIÓN DE PÓLIZA (b1 si ya venció, c1 si sigue vigente).»

   **Es una pregunta que sigue vendiendo**: una póliza nueva desde hoy, o una diferida a la fecha de vencimiento. No es una derivación.
3. **PROD, `n8n_chat_histories`, histórico completo:** las respuestas del bot que casan con `ya tiene una p.liza registrada|no podr.a emitir una nueva` son **4, en 3 sesiones**.
   - **Una sola derivación:** h 12073, `waq_3639`, 22 sep, la del `#464`. Fue improvisación del modelo antes de R0.
   - **Las otras 3** (h 12071, 13876, 14185) piden confirmar el VIN.

## Lo que implica

**Si se pausa en el Guard ante el error 41**, como propones, se pausa también al lead que sigue por R0:
- «sigue vigente» lleva a c1, una póliza nueva que empieza al vencer la actual: es una venta;
- «ya venció» lleva a b1;
- «el VIN estaba mal» lleva a corregirlo y emitir.

Esos leads se quedan sin seguimientos para siempre, porque el `DELETE` (despausar) «no se usa todavía». El `#464` pedía lo contrario: pausar **cuando se le dice que no se puede emitir y se le deriva**.

## Opciones

| | dónde | ventaja | coste |
|---|---|---|---|
| **A** | Guard: `PUT` ante el error 41, como en el handoff | simple; el orden `2xx` → mensaje sale solo, porque el modelo escribe después de la tool | pausa leads vivos (R0 → c1/b1); haría falta el `DELETE` al reanudarse |
| **B** (la que recomiendo) | El Guard **marca** el bloqueo en la sesión: una escritura SQL `captured_data.emision_bloqueada = {code, ts}`, el patrón «tool a guards = columna SQL», porque `$()` no ve `ai_tool` (#261a). El **bot**, en su camino de envío, antes de mandar un mensaje que lleve el **enlace del agente** con esa marca puesta, hace el `PUT` y espera el `2xx`; si el `PUT` falla, reintento acotado, y luego `pause_failed` registrado y escalado. El mensaje sale igualmente, sin darse por pausado | pausa exactamente **la derivación** (lo del `#464`), sea por el error 41 o por cualquier otro bloqueo; el orden `2xx` → mensaje es por construcción (el grafo retiene el envío) | más grafo (un nodo de marca en el Guard, y en el bot `IF` + `HTTP` + `Settle` en el camino de envío) |
| **C** | Como A, más `DELETE` cuando la conversación sigue (otra llamada a `issue_policy`, captura de datos…) | cubre los dos sentidos | usa el `DELETE`, que Juan aún no da por bueno, y define «se reanudó» con reglas propias |

**Una pregunta de alcance**, que viene de tu propio `#464` («Alcance a decidir»): ¿la pausa cubre solo la derivación por un bloqueo de emisión, o también las demás derivaciones con enlace (persona, cancelación…)? Con B es una condición más en el mismo sitio.

**Defecto concreto que atrapa** (criterio `#179`): `waq_3639`, PROD, 22 sep. Tres checkpoints `django_checkpoint_followup_v06` («¿Seguimos con la emisión?», «solo hoy», «no insisto más») tras «no podría emitir una nueva… contacta con un agente».

**Espero tu decisión** (A, B o C, y el alcance) antes de construir.

— Agente n8n · A
