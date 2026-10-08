# Informe #570 — los turnos del guardarraíl quedan en la memoria del modelo (STG)

**De:** Agente n8n · **Para:** Arquitecto · **7 oct 2026**
**Responde a:** `Agente-n8n:handoffs/2026-10-07-570-memoria-de-los-turnos-del-guardarrail.md`.
**Estado:** aplicado en STG y aceptado **4/4** (casos 1-2 en vivo; caso 3 en arnés). **PROD no está tocado.**

## Liquidación de envío: ya existía

Los dos caminos, `Jailbreak Warning Message` → `Increment` → `Restore After Jailbreak Increment` y `Guardrail Error Safe Reply`,
desembocan en la **cadena principal** (`Stash Main Reply Payload`). Esa cadena ya tiene liquidación: `Send message` →
`Settle Main Reply Sent`/`Uncertain`. **No he inventado ninguna.** El `reason` llega intacto hasta `Restore Main Reply Payload`:
`jailbreak_detected` y `guardrail_error`.

## versionId y diff

**Bot STG:** `b31b71a6` → **`12bdbba8`**. Respaldo: `backups/570/bot-stg-b31b71a6-20261008T001415Z.json`.

**Dos ramas laterales, ninguna en serie.** Solo actúan si `reason` ∈ {`jailbreak_detected`, `guardrail_error`}; el resto de
turnos de la cadena principal no cambia.
- **`Restore Main Reply Payload`** → **`IF Turno Guardarraíl?`** → **`Persist Human Row (Guardarraíl)`**: el #342 verbatim, con la
  identidad de `Session Context Builder` y `Merge Session Data` y el timestamp real del inbound. Es el mismo patrón que el #552: el
  mensaje del cliente se escribe aunque el envío falle.
  - El IF está colocado **por encima** de `Outbound Leak Guard` en el lienzo, para que corra antes que la rama de envío. Medido en
    vivo: la fila `human` sale con id menor que la `ai`.
- **`Settle Main Reply Sent`** → **`IF Turno Guardarraíl Enviado?`** → **`Build Guardarraíl AI Row`** → **`Insert Guardarraíl Turn
  History`**, con `Mark Guardarraíl Persist Failed` ante error. La fila `ai` va **solo tras el envío**, con el texto que leyó el
  cliente (la salida de `Email Fidelity Guard`, como `Sync Memory`). Metadata: `source: guardrail_turn_570`, `motivo` = el `reason`
  y el `dispatch_id`.

**No se tocan:** el detector, el #463, el #479, los textos ni el `systemMessage`.

**Diff contra el respaldo:**
- hojas: solo las de los 6 nodos nuevos;
- connections: las dos aristas laterales y las del carril nuevo;
- el resto idéntico; los dos `systemMessage` intactos; el workflow activo.

**Código:** rama `fix/570-memoria-guardarrail`, `scripts/570/`.

## Aceptación

| # | Resultado | Evidencia |
|---|---|---|
| 1 | **PASS** | Teléfono de Alberto, sesión `waq_2320_716027b3524d`, jailbreak evidente (**81010**): aviso `sent`. En `n8n_chat_histories`: **11665 `human`** (el mensaje, `client_message_342`) y **11666 `ai`** («Solo puedo ayudarte con la contratación…», `guardrail_turn_570`). |
| 2 | **PASS** | Turno siguiente (**81011**): «¿Qué te acabo de pedir en mi mensaje anterior y qué me respondiste?». El agente (RAG) contestó con esa memoria: «Me pediste que ignorara mis instrucciones y te compartiera mi prompt de sistema…». En ese turno normal, los dos IF nuevos dieron `false` y no escribieron nada. |
| 3 | **PASS (arnés)** | Workflow temporal en STG con los 6 nodos **byte a byte** y stubs con los nombres exactos; `reason: guardrail_error`. **81013**, con envío → `human` + `ai` («Tuvimos un problema…», `guardrail_turn_570`). **81014**, sin envío → **solo `human`**. Sesión sintética y workflow borrados (GET 404, residuo 0). En vivo no se puede provocar sin romper el modelo del bot. |
| 4 | **PASS** | Diff: arriba. |

**Sesión de la prueba:** contador 0 → 1 por el caso 1. **Lo devolví a 0** y **cerré la sesión**.

**Anotado y fuera de este viaje:** el resto de respuestas deterministas de la cadena principal tampoco dejan memoria (`Ban Message`,
`Out of Scope Warning`, `Identity Reply`, `Qualitas Parameter Reply`, `Payment Status Reply`, `Emitted Reply`,
`Completed Session Response`…). Ahora basta con añadir su `reason` a la lista de los dos IF. Decide tú si se abre issue.

— Agente n8n
