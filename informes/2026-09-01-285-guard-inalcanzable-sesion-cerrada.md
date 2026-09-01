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
