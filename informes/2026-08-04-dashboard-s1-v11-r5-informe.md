# Informe — Dashboard S1 v1.1 ronda 5 (selectores del request como string canónico, sin `parseInt`)

> Del Agente Dashboard al Arquitecto, 4 ago 2026. Responde a
> `Dashboard:handoffs/2026-08-04-s1-v11-ronda5-selectores-string-canonico.md` y al dictamen r4
> de Juan en `#132` (`c.5186765378`, marcador `contract-first:s1-v1.1:dashboard-r4-review:3b02d6d`,
> 2026-08-05T02:16Z). Este informe va aquí (no a `Dashboard/main`) por la regla de proceso.

## Candidato

| Campo | Valor |
|---|---|
| Rama | `feature/s1-v11-dashboard` (inmóvil tras este commit) |
| SHA sucesor (único, sobre `3b02d6d`) | `974a3261b9b6a64c9e98c66937822e8e37a70083` |
| Tree | `d4e9fee5122fb444b0a511d7e4ac0b2509e005b9` |
| Base r4 | `3b02d6db6233a311306c42fa668c3142570d2be1` |
| Contrato | `S1-DUAL-STG@1.1.0` (`aef501f`, sha256 `eca082ba…`) — SIN cambios |
| CI | **success** — run `30970362762`, headSha `974a326`, suite **65/65** + build verde. `https://github.com/aibanez82/Dashboard_seguroautoqualitas/actions/runs/30970362762` |

Un solo push, ya terminado. Fixture y contrato sin tocar.

## El P0 y el fix (verificado contra los dos canarios adyacentes)

**Diagnóstico (confirmado por el Arquitecto):** `conversation.js:68-69` parseaba los selectores
del request con `parseInt` (Number) → redondeo sobre 2^53 (`parseInt("9007199254740993") === …992`)
**antes** de `idEquals` y de los binds SQL. El helper de r4 era exacto pero recibía el dato ya
redondeado → un selector EXACTO de A podía seleccionar/comparar contra B (devolver la conversación
o el lead vecino). Punto ciego compartido: el unit de r4 alimentaba `idEquals` directo, sin
atravesar el `parseInt` del handler.

**Fix:** los selectores viven como **string canónico de dígitos de punta a punta**.

- `toCanonicalId(req.query.lead_id | cotizacion_id)` (valida `^\d+$`, normaliza vía `BigInt`).
  Presencia detectada con comparación explícita `!= null && !== ''` (no truthiness); **presente
  pero no numérico → 400** (mismo shape). El gate "ninguno presente → 400" usa `== null` explícito
  (con strings, `"0"` sería falsy).
- Los binds SQL reciben el string canónico (`pg` castea a `BIGINT` en el servidor); `idEquals`
  recibe el string del request. **Ningún camino hace aritmética con el selector** (verificado por
  grep sobre el handler). Los usos truthiness aguas abajo (`if (leadId)`, etc.) son seguros:
  `toCanonicalId` nunca devuelve `""` (solo string de dígitos o null), y `"0"` es truthy.

## Rojo → verde de los dos canarios (handler REAL, IDs adyacentes `9007199254740993`/`…992`)

- **Por cotización:** request `lead_id=91003&cotizacion_id=9007199254740993`, fila
  `quotation_id:"9007199254740992"`. Rojo sobre `3b02d6d`: `reqCotId` redondea a `…992`,
  `idEquals(…992,"…992")=true` → **200** con datos de la cotización vecina. Verde con el fix:
  `reqCotId="…993"` → `idEquals` false → **409** antes de leer historial/mensajes (asertado por
  captura de SQL).
- **Por lead:** request `lead_id=9007199254740993`. Rojo sobre `3b02d6d`: el bind del candidato
  es el Number `9007199254740992` (`actual: 9007199254740992`) → seleccionaría el lead vecino.
  Verde con el fix: el bind es exactamente **`"9007199254740993"`** (string, todos los dígitos) →
  el stub sin esa fila devuelve objeto vacío, jamás el vecino.

Tests nuevos en `scripts/s1/test/handlers.test.js` (handler real vía seam de runtime): los dos
canarios + validación `400` no-numérico. El test r3 de binds se actualizó a IDs string
(PostgreSQL-like) y bind `['91003','81003']`, coherente con selectores-string. Los tres casos
ordinarios r4 y el resto de la suite intactos.

Suite completa: **65 tests, 65 pass, 0 fail** (62 previos + 3 r5). Build
`npm run build --workspace=operacion`: verde. Node 22 en CI.

## Item 5 — mismo patrón en OTRAS superficies S1 (NO tocadas; para levantamiento preventivo)

Barrido `parseInt|Number(` sobre `pages/api/{db-leads,inbox,n8n-proactive-message}.js` y `lib/s1/`.
**No las he modificado** (fuera del alcance del dictamen). Candidatas:

1. **`lib/s1/retomarBuilder.js:34` y `:37`** — comparación de identidad con coerción a Number:
   `Number(rowLead) !== Number(leadId)` y `Number(rowQuotation) !== Number(cotizacionId)`. Mismo
   riesgo exacto que el P0 recién cerrado (redondeo >2^53 en la validación de eco de Retomar).
   **Candidata fuerte** — `idEquals` de `lib/s1/ids.js` la resolvería directamente.
2. **`pages/api/inbox.js:139`** — `const focusLeadId = req.query.lead ? parseInt(req.query.lead, 10) : null`.
   Selector de lead parseado con `parseInt`; si alimenta bind/filtro, mismo redondeo. Candidata.
3. **`pages/api/db-leads.js:187-193`** — `parseInt(funnel.total_leads)` etc. son **conteos**
   agregados del funnel, NO PKs BIGINT. Fuera de la clase de riesgo (no son selectores de identidad);
   los listo solo para descartarlos explícitamente.

## Notas de proceso

- **Cero acciones vivas:** toda la suite es stubs. Sin deploy, sin abrir Preview, sin BD real, sin secretos.
- **Preview Vercel auto-creado por el push** (efecto automático, declarado, sin acceso): no lo abrí ni lo cito.
- `stg` y `main` del Dashboard intactos; `claim.js` intacto; fencing preservado.
- Cambios acotados a este cierre: `apps/operacion/pages/api/conversation.js` (import + parseo de
  selectores) y `scripts/s1/test/handlers.test.js`. Nada fuera del P0.

Listo para reverificación sobre el árbol inmóvil `974a326`.
