# Contadores que cortan la respuesta — medición y propuesta antes de cablear

**De:** Agente n8n · **Para:** Arquitecto · **Fecha:** 18 sep 2026
**Responde a:** tu mensaje directo sobre `onError` en los nodos de contador (arco #338/#256)
**Medido sobre:** STG vivo `021d4c92` (349 nodos) y PROD vivo `de20a75c` (330 nodos)

Tienes razón y el defecto es más ancho de lo que tu tabla de tres filas dice. Medido, propuesto,
**nada cableado** — esperando tu firma como en el #325.

---

## 1 · Confirmo tu tabla, y hay un patrón ya establecido a favor

Los tres nodos que nombraste, sin `onError` (= `stopWorkflow`), en la cadena síncrona de respuesta:
`Increment Jailbreak Attempt` (STG), `Increment KB Counter` (STG **y** PROD), `Update Out of Scope in
DB` (STG **y** PROD). Confirmado nodo a nodo.

**Y el patrón que propones no es nuevo en este grafo: 27 nodos ya usan `continueRegularOutput`** —
todos los `Persist Human Row (*)`, `Persist Guard VIN`, `Reopen Discount Poll`, `Persist Availability
Outcome`, `Discount Normal Guard`, `Repair Window (AI/RAG)`… Es exactamente la clase «registrar/contar
no puede tumbar el turno». No invento un mecanismo: aplico el que ya rige para 27 hermanos.

## 2 · La opción correcta es `continueRegularOutput`, y por qué NO la otra

- **`continueRegularOutput`**: al fallar el nodo, **pasa el item de entrada a la salida normal** (con
  un campo `error` añadido) y el flujo sigue al nodo de abajo. Es lo que queremos: el `Restore…` y el
  `Stash Main Reply Payload` corren igual, y la respuesta del cliente sale. Sumar es lo que se pierde;
  responder, no.
- **`continueErrorOutput`** (la del guardrail en el #325): enruta a la salida de error `[2]`. Aquí
  **no hay** esa arista cableada, así que el item se perdería igual que hoy — salvo que además
  cableáramos la salida de error de vuelta al `Restore`, más nodos y más frágil. Aquí sí queremos
  seguir, al revés que en el guardrail: descartada.

**Verificado que el `Restore` de abajo sobrevive al passthrough** (leen por referencia cruzada, no por
posición): `Restore After KB Counter` repone desde `$('RAG IA Agent')` con fallback
`|| kbAgentData.rateLimitData`; `Restore After Jailbreak Increment` desde `$('Jailbreak Warning
Message')`; `Restore After Out of Scope Update` conserva `shouldBan` de `$('Increment Out of Scope')`,
que es lo que decide la respuesta. En los tres, el dato del contador puede quedar impreciso en el
fallo (tolerable: un intento sin contar), pero **la respuesta se computa y sale**. Esto lo MIDO en el
control positivo, no te pido que me creas.

## 3 · Hay un SEGUNDO modo de fallo que `onError` NO cubre — y quiero tu decisión

`onError` cubre el **error de nodo** (mi avería 51815: parámetro inválido → excepción). Pero hay otro
camino por el que estos mismos nodos pueden devolver **cero items sin lanzar error**: un `UPDATE … RETURNING`
que afecta **0 filas** (sesión inelegible por el `WHERE` de estado) → 0 items de salida → cadena cortada
por vacío, no por excepción. Eso solo lo tapa **`alwaysOutputData: true`**.

Medido: `Increment Jailbreak Attempt` **ya lo tiene** (se lo puse en el #256, justo por esto).
`Increment KB Counter` y `Update Out of Scope in DB`: **no**. Si quieres «el cliente recibe su mensaje»
de verdad, los dos modos hacen falta. **Propongo poner `alwaysOutputData: true` a esos dos en el mismo
paquete**; si prefieres tratarlo aparte, dímelo y solo va el `onError`.

## 4 · Los hermanos: el mismo defecto, con nombre y apellido (handoff no agota el sistema)

Barriendo TODOS los postgres que alcanzan el sumidero de respuesta y **escriben**, sin `onError`, del
mismo perfil «contabilidad, no producto» que los tres tuyos (STG y PROD por igual):

| Nodo | Qué cuenta/marca | ¿Mismo defecto? |
|---|---|---|
| `Increment Image Counter` | contador de imágenes por sesión | **Sí, gemelo exacto** |
| `Update Activity` | `last_activity` de la sesión | Sí (marca, no producto) |
| `Update Phase in DB` | fase para el PRÓXIMO turno | Sí (no decide la respuesta de ESTE) |
| `Apply Affinity Update` | afinidad de la sesión | Sí (métrica) |

Y uno que **NO** meto sin que lo mires: `Resolve Session` (escribe `is_banned`/`out_of_scope`,
resolución de sesión) — puede ser producto, no contabilidad; su fallo quizá SÍ deba parar. Igual que
**no toco** los que solo **leen** en la cadena (`Load Session`, los `Claim … Outbound` de idempotencia
de envío): ahí `stopWorkflow` puede ser lo correcto —sin sesión no hay respuesta, y tragarse un fallo
de `Claim` podría duplicar un envío—. Meter `onError` a ciegas en todos violaría el criterio de
admisión (#179): cada uno necesita nombrar su defecto.

**Mi recomendación de alcance:** los 3 tuyos + `Increment Image Counter` (gemelo indiscutible) en este
paquete; `Update Activity`, `Update Phase in DB`, `Apply Affinity Update` si los bendices (defecto por
construcción, no observado); `Resolve Session` y los de lectura, fuera hasta análisis propio.

## 5 · Control positivo que te enseñaré (tu criterio, ahora en verde)

Forzaré el fallo del incremento con un valor real y mediré, sobre teléfono sintético (cero entrega):
un turno donde el nodo contador **da error de nodo** y el cliente **igual recibe su mensaje** —el
`output` presente en `Stash Main Reply Payload`, la ejecución en estado `success`, el contador sin
subir—. Es exactamente lo que mi avería hizo por accidente, ahora provocado y en verde. Lo haré con un
PUT de control (nodo roto a propósito + `onError`) y restauración garantizada en `finally`; te aviso
que mete ~30 s un workflow con un nodo roto al STG vivo (tráfico solo mío, sintético).

## Lo que decides antes de que cablee

1. `continueRegularOutput` en los nodos objetivo: **OK** / ajustar.
2. `alwaysOutputData` en `Increment KB Counter` y `Update Out of Scope in DB`: **en el paquete** / aparte.
3. Alcance de hermanos: ¿solo `Increment Image Counter`, o también `Update Activity`/`Update Phase in
   DB`/`Apply Affinity Update`?

Con tu respuesta, cableo STG con el control positivo y te traigo el verde. PROD lo promueves tú (con la
trampa del #342 y las 2-salidas del gemelo ya anotadas).

— Agente n8n
