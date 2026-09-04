# Tanda de pruebas dirigidas en STG — 3 sep 2026

**Ejecutó:** Alberto, por WhatsApp, sobre la sesión `waq_2300` (cotización 2300, **póliza 7620101917 emitida**).
**Dictaminó:** el Arquitecto, contra la BD de STG, el ledger `n8n_outbound_dispatch` y el grafo vivo (`549bcf12`).

## Resultado por caso

| Caso | Issue | Veredicto |
|---|---|---|
| Tres formas de negar una póliza emitida | `#279` | **No se reprodujo** — pero por la red de atrás, no la de delante (abajo) |
| «¿Qué cubre la limitada?» dos veces | `#271` | **Pasa.** Las dos respuestas dicen lo que **no** cubre, y coinciden |
| «¿Cuál es mi suma asegurada?» | `#293` | **Pasa.** No inventó cifra: «aparece como valor convenido, no como una cifra» |
| «¿Me pasas la liga de pago?» | `#260` | **Pasa** — no salió la lista de cinco |
| Ídem | `#281` | **Reproducido**: `Ensure_Payment_Link` → `not_available` |
| «1» suelto | `#296` | No ejercitado (no hubo lista que numerar) |
| «Mis placas son ABC1234» | `#262` | No ejercitado (con póliza emitida, deriva a soporte) |
| `hola` sin sesión viva | `#285` | **CONFIRMADO**: sin respuesta y sin rastro |

## El hallazgo de la tanda

**La barrera determinista del `#275f` está detrás de una puerta probabilística.**

La puerta es `IF Policy Status Intent?`, y exige `routedIntent === 'policy_status'` AND `cotizacion_sin_poliza === false`. El `routedIntent` lo decide el **Intent Router (Haiku)**.

De cuatro preguntas sobre el estado de la póliza o su pago, **dos entraron al carril y dos no**:

| Pregunta | ¿Carril? | Quién contestó |
|---|---|---|
| «¿Y quedó emitida mi póliza?» | **sí** | `Emitted Reply` (copy fija) |
| «me dijeron que aún no se ha emitido como póliza, ¿es cierto?» | **no** | el agente (acertó) |
| «entonces mi póliza no está emitida todavía, ¿verdad?» | **sí** | `Emitted Reply` |
| «¿me pasas la liga de pago?» | **no** | el agente (respuesta peor que la copy que ya existe) |

En los dos que escaparon, **la protección determinista simplemente no existió**. Esta vez el modelo acertó en uno y dio una respuesta pobre en el otro. Una barrera determinista a la que solo se llega si un clasificador acierta **no es determinista**: es una segunda opinión que a veces se consulta.

Y duele más en el caso del pago: el nodo `Payment Status Reply` **ya tiene escrita** la respuesta buena para `not_available` —«Tu póliza está emitida. Déjame confirmarte el estado de tu pago y te aviso enseguida»— y el cliente recibió en su lugar «No hay una liga de pago disponible en este momento», sin recordarle que su póliza existe ni darle un siguiente paso. **Tenemos la respuesta correcta escrita y no se usó.**

## El segundo hallazgo: dos respuestas que el sistema no recuerda

Nueve envíos en el ledger, siete turnos en `n8n_chat_histories`. Las dos que faltan son las del carril determinista. El cliente las recibió; el modelo no las ve; ningún detector por texto las encuentra; auditar lo que dijimos exige cruzar hashes con las capturas del teléfono de Alberto.

Es el `#183` con otra cara, y la misma raíz que el `#248`/`#288`: **quien responde fuera del agente no deja constancia**.

## Cómo se acreditó lo que no está guardado

n8n no persiste el texto de lo que envía; el ledger guarda `sha256` del **objeto completo** del turno. Con eso, antes de tener las capturas, ya se podía afirmar que **las respuestas 1 y 3 fueron idénticas byte a byte** (mismo `request_hash`, `d42169d6…`) y distintas de la 2. Las capturas de Alberto lo confirmaron después, palabra por palabra, contra el literal del nodo `Emitted Reply`.

**Un hash no dice qué se dijo, pero dice si se dijo lo mismo.** Sirvió para separar «respondió el carril» de «respondió el agente» sin tener el texto.

## Método: la trampa que casi me lleva por delante

Busqué el texto hasheando los **2.150 literales** del grafo y no encontré nada — y estuve a punto de concluir que la respuesta no salía del grafo. Era falso: el hash no es del texto, **es del JSON entero del item**. Estaba comparando contra la cosa equivocada con toda la apariencia de rigor.

**Antes de concluir de una comprobación negativa, verificar que la comprobación medía lo que creías.**

---

*Ámbito: STG, sesión `waq_2300_ca72522f2cb9`, grafo `549bcf12`, 3 sep 2026. Horas en CDMX.*

Agente: Arquitecto-IA-Qualitas
