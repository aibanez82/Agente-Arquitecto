# Informe — Dashboard S1 v1.1 ronda 6 (FINAL): los tres gaps consolidados

> Del Agente Dashboard al Arquitecto, 4 ago 2026. Responde a
> `Dashboard:handoffs/2026-08-04-s1-v11-ronda6-tres-gaps-finales.md` y al dictamen r5 de Juan
> en `#132` (`c.5187067002`, marcador `contract-first:s1-v1.1:dashboard-r5-review:974a326`,
> 2026-08-05T03:07Z). Este informe va aquí (no a `Dashboard/main`) por la regla de proceso.

## Candidato

| Campo | Valor |
|---|---|
| Rama | `feature/s1-v11-dashboard` (inmóvil tras este commit) |
| SHA sucesor (único, sobre `974a326`) | `c911d4c9539633ee45efd36e6308f7d0db18e591` |
| Tree | `94aa2d9dbdae39051e7eed84be8c6b5d83e23666` |
| Base r5 | `974a3261b9b6a64c9e98c66937822e8e37a70083` |
| Contrato | `S1-DUAL-STG@1.1.0` (`aef501f`, sha256 `eca082ba…`) — SIN cambios |
| CI | **success** — run `30971926919`, headSha `c911d4c`, suite **73/73** + build verde. `https://github.com/aibanez82/Dashboard_seguroautoqualitas/actions/runs/30971926919` |

Un solo push, ya terminado. Fixture y contrato sin tocar.

## Los tres gaps — fix y rojo→verde (superficies REALES)

### (a) Positividad del helper — `-5`/`0` → 400 y CERO queries

`toCanonicalId` aceptaba `0` y negativos (`^-?\d+$`). Ahora **entero positivo estricto**:
regex `^\d+$` (sin signo) + `BigInt(s) > 0n`; el camino Number exige `Number.isInteger(x) && x > 0`.
Como el 400 de `/api/conversation` se emite antes del `try`, `lead_id=-5`/`0` cortan **antes de
cualquier `query`**.
· Regresión (spy sobre `query`): `lead_id=-5` → 400 con **0 llamadas**; `lead_id=0` y
  `cotizacion_id=0` → 400 con 0 llamadas. Rojo sobre `974a326` (4 lecturas + 200), verde con el fix.

### (b) Inbox — sin `parseInt`, bind exacto y cast `BIGINT`

`inbox.js:139` parseaba `?lead` con `parseInt` (redondeo >2^53) y el SQL casteaba `$1::integer`
(ni cubre el rango BIGINT). Ahora: selector como **string canónico** (`toCanonicalId`, presencia
explícita, no-numérico/no-positivo → 400) y **`$1::bigint`**. `$1` es el único consumidor en
`SQL_INBOX` (verificado). Con `?lead` ausente, `$1` es null → `l.id = NULL::bigint` no matchea
(comportamiento de deep-link intacto).
· Regresión: `?lead=9007199254740993` → bind exacto `"…993"` (string, nunca `…992`); el SQL
  contiene `$1::bigint` y **no** `::integer`; `?lead=abc` → 400. Rojas sobre `974a326`.

### (c) Retomar builder — comparación canónica y rechazo de candidata adyacente

`retomarBuilder.js:34,37` comparaba `Number(rowLead) !== Number(leadId)` — colapsa adyacentes
>2^53, dejando pasar una candidata VECINA. Ahora **`idEquals`** en ambas comparaciones (lead y
cotización): la candidata adyacente se **rechaza** como `conversation_contradiction`. El caller
`n8n-proactive-message.js` **no** parsea `lead_id` (lo pasa crudo del body → `buildRetomarWire` y
binds), así que el fix no queda derrotado aguas arriba.
· Regresión (builder real): `leadId="…993"` vs candidata `lead_id="…992"` → `conversation_contradiction`
  (y el simétrico por cotización); el caso coherente `"…993"`/`"…993"` sigue `ok:true`. Rojas
  sobre `974a326` (devolvían `ok:true`).

## Suite

**73 tests, 73 pass, 0 fail** (65 de r2–r5 intactos + 8 nuevos: 2 conversation r6a, 3 inbox r6b,
3 retomar r6c en `scripts/s1/test/retomar-canonical.test.js`). Build
`npm run build --workspace=operacion`: verde. Node 22 en CI.

## Notas de proceso

- **Cero acciones vivas:** toda la suite es stubs. Sin deploy, sin abrir Preview, sin BD real,
  sin secretos.
- **Preview Vercel auto-creado por el push** (efecto automático, declarado, sin acceso): no lo
  abrí ni lo cito.
- `stg` y `main` del Dashboard intactos; `claim.js` intacto; fencing preservado.
- Cambios acotados a los tres gaps: `lib/s1/ids.js`, `pages/api/inbox.js`,
  `lib/s1/retomarBuilder.js` + los dos ficheros de test. Nada fuera de este cierre.

Listo para reverificación sobre el árbol inmóvil `c911d4c`. Si PASS, quedo a la espera de que
Juan ejecute el smoke integrado con n8n `fb98f24`.
