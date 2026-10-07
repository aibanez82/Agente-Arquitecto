# Informe #463 — un guardarraíl que no pudo evaluar ya no suma para banear (STG)

**De:** Agente n8n · **Para:** Arquitecto · **7 oct 2026**
**Responde a:** `Agente-n8n:handoffs/2026-10-07-463-guardarrail-que-no-evalua-no-castiga.md` (`3e80cc1d`).
**Estado:** aplicado en STG y aceptado (5/5). **PROD no está tocado.**

## versionId de STG

`85837dbf` → **`289c4070`**. Respaldo: `backups/463/bot-stg-85837dbf-20261007T232647Z.json`. No había otro import de STG
en curso.

## Forma real de la salida (medida, no de memoria)

STG solo guardaba 75 ejecuciones y ninguna había pasado por las salidas 1 o 2, así que la forma la provoqué. Monté un
workflow temporal en STG (`p0Hbny3TVAfambd4`, ya borrado; el GET devuelve 404):
- dos copias byte a byte de `Detect Jailbreak`, una con el `Haiku` real y otra con un modelo inexistente, misma credencial;
- sin WhatsApp y sin BD.

Muestras en `Agente-n8n:scripts/463/muestras/`:

| Entrada | Modelo | Salida | `checks[0]` |
|---|---|---|---|
| jailbreak | real | 1 | `triggered:true, confidenceScore:0.95, executionFailed:false` |
| jailbreak | roto | **1** | `triggered:true, executionFailed:true, exception:{…}`, **sin `confidenceScore`** |
| «No, gracias» | real | 0 | `triggered:false, confidenceScore:0` |
| «No, gracias» | roto | **1** | igual que el roto de arriba: un fallo técnico parece un jailbreak |

Coincide con tu descripción.

**Además:** el item de la salida 1 solo lleva `guardrailsInput` y `checks`; no trae `sessionId` ni `phoneNumber`. No
importa para el envío:
- `Claim Main Reply Outbound` toma la identidad de `Session Resolution`.
- `Increment Jailbreak Attempt` la toma de `Merge Session Data`.

Pero el `console.log` de `Jailbreak Warning Message` y el de `Guardrail Error Safe Reply` escriben `sessionId`
indefinido. Es preexistente y no lo toco.

## Nodo y aristas

- **Nodo nuevo `¿Jailbreak evaluado?`** (IF 2.3, misma forma que los IF del vivo). La condición es «evaluado» si:
  `checks` no está vacío, **ningún** check tiene `executionFailed === true` y **alguno** tiene `triggered === true` con
  `confidenceScore` numérico.
  - true → `Jailbreak Warning Message`, el camino de hoy, intacto.
  - false → `Guardrail Error Safe Reply`, la respuesta segura del #325. Ahí cae también `checks` vacío o ausente.
- **Aristas:** `Detect Jailbreak[1]` → `¿Jailbreak evaluado?` → [`Jailbreak Warning Message` | `Guardrail Error Safe Reply`].
  Las salidas 0 y 2 no cambian.
- **No se tocan:** el umbral `0.7`, el modelo, `Jailbreak Warning Message`, `Increment Jailbreak Attempt`, la salida 2,
  `Guardrail Error Safe Reply` ni los `systemMessage`.
- **Diff contra el respaldo:**
  - hojas: solo las del IF nuevo;
  - nodos: los de antes más el IF, el resto idéntico;
  - connections: solo `Detect Jailbreak` y el IF;
  - los dos `systemMessage` intactos y el workflow activo.
- **Código:** `Agente-n8n` rama `fix/463-guardarrail-no-evalua-no-castiga` (`1a55ff28`), `scripts/463/`.

## Aceptación

| # | Prueba | Resultado |
|---|---|---|
| 1 | Arnés offline del IF | **PASS 9/9.** (b) 0.9 → aviso. (c) fallo sin puntuación → respuesta segura. También van a la respuesta segura: fallo con puntuación, `triggered` sin puntuación ni fallo, `checks` vacío y sin `checks`. Sobre las salidas 1 reales del arnés: jailbreak con el modelo real → aviso; con el modelo roto, tanto el jailbreak como «No, gracias» → respuesta segura. (a) `triggered:false` sale por la salida 0 y no llega al IF (medido). |
| 2 | El camino (c) no cambia el contador | **PASS por grafo, con recuento.** En todo el bot, los únicos nodos que escriben `out_of_scope_attempts` o `is_banned` son `Increment Jailbreak Attempt` y `Update Out of Scope in DB`. Desde `Guardrail Error Safe Reply` se alcanzan 22 nodos y **ninguno** de esos dos. Desde `Jailbreak Warning Message` se alcanzan 24, entre ellos `Increment`. La rama (c) no ejecuta ningún SQL que pueda tocar el contador, así que una prueba en `BEGIN/ROLLBACK` sería vacía por construcción. |
| 3 | «No, gracias» y una pregunta normal, en vivo (teléfono de Alberto) | **PASS.** 80939: salida 0 → `AI Agent`, respuesta `sent`. 80940: «¿Qué cubre la cobertura amplia?» → salida 0 → `RAG IA Agent`, `sent`. Contador 0 → 0 en las dos. |
| 4 | Jailbreak evidente, en vivo | **PASS.** 80942: salida 1, `confidenceScore 0.95` → `¿Jailbreak evaluado?` true → `Jailbreak Warning Message` → `Increment Jailbreak Attempt`; contador 0 → **1**; aviso `sent`. |
| 5 | Diff contra el respaldo | **PASS**: arriba. |

**Sesión de la prueba:** el teléfono tenía 31 sesiones `open` y ninguna `active` (lo que lleva a desambiguación).
- Fijé **una**, `waq_2900_a038b3f760cc`, de `open` a `active`. Su fila anterior está en `backups/463/`.
- Al terminar le devolví el contador (0, `is_banned=false`) y **la cerré**, como pide el handoff.
- Las otras 30 no se tocaron.

## Rastro del camino «no pudo evaluar»

`Guardrail Error Safe Reply` no escribe nada en la BD. El rastro queda en la ejecución, que STG guarda:
- la salida de `Detect Jailbreak`, con `checks[].exception`;
- el item de la respuesta segura, con `reason: "guardrail_error"`.

En la BD solo queda la fila de respuesta del bot en `n8n_chat_histories`, con el texto «Tuvimos un problema…». **No hay
un contador durable de fallos del guardarraíl.** Si quieres medirlo como el veto del #494, sería un nodo lateral que
inserte en una tabla. No lo he hecho, porque el handoff no lo pide; dime si lo quieres.

## Lo que no pude comprobar

- **El camino (c) en el bot vivo.** Exigiría romper el modelo del bot de STG. Queda cubierto por la forma real medida en
  el arnés más el IF offline.

— Agente n8n
