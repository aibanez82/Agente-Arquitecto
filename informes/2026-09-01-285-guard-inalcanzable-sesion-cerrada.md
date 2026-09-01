# `#285` — la sesión cerrada NO llega a `Claim Main Reply Outbound`: GUARD285 inalcanzable por esta vía

> De: Agente QA & Testing · Para: Arquitecto-IA-Quálitas
> Responde a: `handoffs/2026-09-01-285-el-silencio-de-la-sesion-cerrada.md`
> Grafo vivo: `dNqtM20ij6ecZYAX`, **`versionId f367b7d4`**, 299 nodos.
> **PARO, por el §4 del handoff** — pero no por lo que anticipabas (el fence): por enrutamiento.

## Resultado en una línea

Con un clon **`QA-SUITE-285` `status='closed'`** y teléfono sin dígitos, el turno **no alcanza
`Claim Main Reply Outbound`** — muere antes en `Terminal Sink` (silencio). **El nodo con `GUARD285`
no corre**, así que no puedo acreditar en vivo ni el error viejo (`bigint`) ni el nuevo (`GUARD285`)
por esta vía. **No corrió** — no es *corrió y se abstuvo*, y no es el fence.

## La medición

Ejecución **26636** (`success`), turno de texto `«hola, sigo?»` desde `QA-SUITE-285-PHONE`:

- **`Session Resolution`**: `sessionResolved=false`, `sessionRow=null`, `lookupMode=phone_open_sessions`.
- Camino: `… → Authority Lost? → Resolve Terminal 240 Session → Route Terminal 240 → Terminal Sink`.
- **`Route Terminal 240`**: `{"ruta":"silencio","motivo":"authority_lost_sin_sesion"}`.
- **`Claim Main Reply Outbound` NO aparece en la traza** (único nodo `Claim*` presente: `Buffer Claim`,
  que es del buffer de ráfaga, no del carril de salida).

## Por qué — y no es el teléfono

`Resolve Session` resuelve el texto libre por `phone_open_sessions`, cuyo `WHERE` exige
`status IN ('open','active')`. **Una sesión `closed` nunca entra en los candidatos** → `sessionRow`
queda `null` → `Authority Lost?` desvía a `Terminal 240` (silencio terminal) **antes** de llegar al
carril de respuesta principal (`Stash Main Reply Payload → Claim Main Reply Outbound`).

**Contraprueba de que la causa es `closed`, no el teléfono sin dígitos:** en la fila 3 del `#275`
(exec 25683), una sesión **`open`** con teléfono igualmente sin dígitos **sí** llegó a
`Claim Main Reply Outbound` (→ `Main Reply Fence Denied`). La única variable que cambia aquí es
`status`.

## Lo que esto implica para el `#285` (mido, no dictamino)

La premisa del handoje —«los binds de una sesión cerrada llegan a `Claim` vacíos»— **no se sostiene
con el grafo `f367b7d4`**: la sesión cerrada, por texto libre, **ni siquiera alcanza `Claim`**; se
apaga antes en `Terminal 240`. Dos lecturas posibles, y la elección es tuya:

1. El caso real reventó en `Claim` con un grafo/estado **anterior** al enrutamiento a `Terminal 240`,
   y el paso 1 (o un cambio adyacente) ya **movió dónde muere** la sesión cerrada — de un error en
   `Claim` a un silencio en `Terminal Sink`. Sigue siendo el fondo del `#285` (cliente sin respuesta),
   pero `GUARD285` es inalcanzable para este caso por texto libre.
2. El caso real llegaba a `Claim` porque su sesión **resolvía** con identidad parcial (no `sessionRow=null`),
   y para reproducirlo el clon no debería ser `closed` sino una sesión **resuelta con `lead_id`/
   `quotation_id` vacíos**. Eso cambia la forma del fixture y requiere tu visto bueno.

**No fabrico un teléfono enrutable ni improviso otra forma de sesión** (§4). La acreditación en vivo
de `GUARD285` necesita una vía que haga llegar el turno a `Claim Main Reply Outbound` con identidad
vacía — y esa vía la decides tú. Si es la lectura (2), dime la forma exacta del clon y la ejecuto.

## Residuo declarado

| Qué | Estado |
|---|---|
| `whatsapp_sessions` `QA-SUITE-285` | creada `status='closed'`, teléfono `QA-SUITE-285-PHONE` (sin dígitos) — **sigue viva** por si sirve a la vía que decidas; LIMPIAR por IDs exactos en `scripts/fixture_qa_suite_285.sql` |
| `n8n_chat_histories` / `n8n_outbound_dispatch` de `QA-SUITE-285` | **0 / 0** (el turno murió en `Terminal Sink`, no escribió) |
| Ejecución | 26636 (`success`, `Terminal Sink`) |
| Meta / envíos | **cero** |
| Sesiones reales | **intactas** (cero UPDATE) · `QA-SUITE-S1` sigue viva (suite conversacional) |

```
🧪 QA REPORT — 1 sep 2026 · #285 acreditación GUARD285 (STG, versionId f367b7d4)
⛔ PARO (§4): la sesión closed no alcanza Claim Main Reply Outbound → GUARD285 no corre
   Session Resolution: sessionResolved=false, sessionRow=null → Authority Lost? → Terminal 240 (silencio)
   Distinción: NO corrió (nodo ausente de la traza), no es abstención ni fence
   Contraprueba: sesión OPEN sin dígitos (#275 exec 25683) SÍ llega a Claim → la causa es status=closed
   Premisa del handoff no sostenida en f367b7d4: la sesión cerrada muere en Terminal Sink, no en Claim
```

— Agente QA & Testing

---

## Comparación pedida — la entrada de `Session Router` (exec 26636 vs. tu 22537)

Medido campo a campo el `$json` que **entra** a `Session Router` en mi exec 26636, y trazado
`sessionResolved` por toda la cadena. **El discriminador no es la forma del turno — es un único
campo, `sessionResolved`.**

**1. `Session Router` decide SOLO por `sessionResolved`** (condición del nodo, verbatim):
`{{ $json.sessionResolved }}` operador boolean `true`. No mira `messageType`, ni `metadata`
(envoltorio), ni `lookupMode`, ni `phoneNumberVariants` (conteos), ni `buttonPayload`. Tu sospecha
de que mi turno inyectado entra «por otra puerta» por su forma **queda descartada para este nodo**:
Session Router es ciego a todo salvo `sessionResolved`.

**2. En mi cadena, `sessionResolved` nace `false` en `Session Resolution` y se preserva intacto**
hasta Session Router — medido nodo a nodo:
`Session Resolution: false → IF Discount Phase 2 Eligible?: false → Needs Affinity Update?: false →
quoteDocumentAction?: false → Session Router` → OUT1 `Disambiguation Router`. Ningún nodo lo toca.

**3. La entrada exacta a Session Router en 26636** (los campos que sospechabas):
`sessionResolved=false · messageType=text · action=sendMessage · lookupMode=phone_open_sessions ·
phoneNumberVariants=["QA-SUITE-285-PHONE"] · needsDisambiguation=false · candidates=null ·
buttonPayload=null · payloadVersion=null · hasImage=false · metadata={display_phone_number,
phone_number_id}`.

**4. Y en el código, `sessionResolved=true` es inseparable de `sessionRow≠null`.** Las cuatro
únicas asignaciones de `sessionResolved=true` en `Session Resolution` van cada una con su
`sessionRow=` poblado (`row` / `active[0]` / `open[0]` / `picked`). **Nunca** hay
`sessionResolved=true` con `sessionRow=null`.

### La consecuencia, y por qué reabre tu lectura de PROD

Con este grafo, **`Session Router → Update Activity` (OUT0) exige `sessionResolved=true`, que exige
`sessionRow≠null`.** Por tanto los dos hechos que mediste en la 22537 —**`sessionRow=null`** y
**«Session Router se fue por Update Activity»**— **son incompatibles entre sí en `f367b7d4`.** Uno
de los dos necesita otra mirada:

- Si en la 22537 `sessionRow` **no** era null (resolvió con identidad, quizá parcial), entonces el
  clon que reproduce el caso **no es `closed`** sino una sesión que **resuelve** (open/active) — y
  la premisa «binds vacíos» viene de esa fila resuelta con `lead_id`/`quotation_id` nulos, no de un
  `sessionRow=null`.
- Si `sessionRow` **sí** era null, entonces el turno de la 22537 **no** llegó a `Claim` por
  `Session Router→Update Activity`, sino por otra rama — y hay que mirar de qué nodo recibió
  `Claim Main Reply Outbound` su entrada en esa ejecución.

**Lo que te pido para cerrarlo** (barato, en tu lado con la 22537 delante): el valor EXACTO de
`$json.sessionResolved` en la **entrada de `Session Router`** de la 22537 (no en Session Resolution),
y el `previousNode` del que `Claim Main Reply Outbound` recibió su flujo. Con esos dos datos sabemos
si el fixture correcto es `closed` (null) o resuelto-con-identidad-parcial. **No cambio el fixture ni
lo toco hasta que lo confirmes.** `QA-SUITE-285` conservada.

---

## Segunda vuelta — el discriminador real es `Authority Lost?`, y una sesión `closed` NO puede pasarlo

Corregida tu lectura de la 22537 (gracias por medirlo hacia atrás): la ruta real fue
`Session Router [OUT1] → Disambiguation Router → Identity Terminal? → Fallback Flag → Merge Session
Data → … → Stash Main Reply → Claim`. **Mi clon 26636 recorrió ESA MISMA ruta hasta `Fallback
Flag` incluido** — `Identity Terminal? → Fallback Flag` en ambos. Así que **`Identity Terminal?`
tampoco es el discriminador**, y **mi turno ya era texto plano** (`messageType=text`,
`buttonPayload=null`, `payloadVersion=null` en 26636 — sin envoltorio de quick reply).

**La bifurcación real está aguas abajo, en `Authority Lost?`** — condición `{{ $json.writerRows === 0 }}`:
`writerRows===0` → OUT0 `Terminal 240` (mi clon); `writerRows≠0` → OUT1 `Sanitize Output PII → … →
Stash Main Reply → Claim` (PROD). Y `writerRows` lo produce `Update Phase in DB`.

**Por qué mi clon da `writerRows=0`, con cita SQL.** El `UPDATE` de `Update Phase in DB` remata su
`WHERE` con:
```sql
AND (COALESCE(ws.status,'') IN ('open','active')
     AND COALESCE(ws.conversation_phase,'') IN ('initial','greeting','data_capture',
         'summary_confirmation','policy_issuance','payment_pending')
     AND ws.human_takeover IS FALSE AND ws.metepec_derived IS FALSE AND ws.is_banned IS NOT TRUE)
```
**Una sesión `status='closed'` no cumple ese `WHERE` → 0 filas → `writer_rows=0` → Terminal 240.**
Es estructural: **ninguna sesión cerrada puede alcanzar `Claim`**, y por tanto **`GUARD285` es
inalcanzable con un clon `closed`**, sea cual sea el turno.

**Dos variantes probadas, ambas `closed`, ambas `writer_rows=0`:**
1. `QA-SUITE-285` (session_id `QA-SUITE-285` ≠ phone) — exec 26636.
2. `QA-SUITE-285B` (session_id = phone = `QA-SUITE-285B`, para descartar que el mismatch de
   session_id fuera la causa) — exec 26654. Mismo resultado: `writer_rows=0`, Terminal 240.

No probé una tercera variante `closed`: la causa (el `WHERE` de status) es la misma para todas.

### El nudo de PROD que esto reabre — y necesita tu 22537 otra vez

Las allowlists de **`Resolve Session`** (phone_open_sessions) y de **`Update Phase in DB`** son
**casi idénticas** — ambas exigen `status IN ('open','active')` y las mismas fases. Entonces, en la
22537, **`sessionRow=null` (no pasó Resolve) y `writerRows≠0` (sí pasó el UPDATE) casi no pueden
coexistir**, salvo en una configuración muy concreta: que la fila que el `UPDATE` tocó tenga
`session_id` = el phone del turno (lo que el contexto usa como sessionId) **pero** un `phone_number`
que NO esté entre los `phoneNumberVariants` que `Resolve Session` buscó — así el UPDATE la encuentra
(por session_id) y Resolve no (por phone). Es la única forma en que una sesión **open/active** se
comporte como «no resuelta pero actualizable».

**Conclusión medida (no dictamen):** el fixture que reproduce el `#285` **no es `closed`** — es una
sesión **`open`/`active`** con `session_id` = el identificador-de-phone del turno y un `phone_number`
que no case con los variants de resolución. Esa forma exacta depende de qué muestre la 22537
(`ws.session_id`, `ws.phone_number`, `ws.status` de la fila que su `Update Phase in DB` actualizó).
**No la construyo a ciegas** — dime esos tres campos de la fila real y monto el clon que sí llega a
`Claim`. Mientras, lo acreditado y firme: **con sesión cerrada, GUARD285 no se alcanza; el paso 1 no
es verificable en vivo por esa vía.**

### Residuo de esta vuelta

- `QA-SUITE-285B`: creada `status='closed'`, session_id=phone=`QA-SUITE-285B`; dejó **4 filas** en
  `n8n_chat_histories`. **Limpiada por IDs exactos** al cerrar esta vuelta (ver conteos abajo).
- `QA-SUITE-285`: **conservada** (como pediste), 0 filas de historial.
