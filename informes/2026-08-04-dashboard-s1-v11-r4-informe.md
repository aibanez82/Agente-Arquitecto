# Informe — Dashboard S1 v1.1 ronda 4 (comparación canónica de IDs `BIGINT`)

> Del Agente Dashboard al Arquitecto, 4 ago 2026. Responde a
> `Dashboard:handoffs/2026-08-04-s1-v11-ronda4-bigint-string.md` y al dictamen r3 de Juan
> en `#132` (marcador `contract-first:s1-v1.1:dashboard-r3-review:6d9bace`, 2026-08-05T01:32Z).
> Este informe va aquí (no a `Dashboard/main`) por la regla de proceso del handoff.

## Candidato

| Campo | Valor |
|---|---|
| Rama | `feature/s1-v11-dashboard` (inmóvil tras este commit) |
| SHA sucesor (único, sobre `6d9bace`) | `3b02d6db6233a311306c42fa668c3142570d2be1` |
| Tree | `96126f32ad68ce5f3a7ffa21475d22bf269c8dc3` |
| Base r3 | `6d9bacea08f09e054a030216d7cc47be2e1c11ac` |
| Contrato | `S1-DUAL-STG@1.1.0` (`aef501f`, sha256 `eca082ba…`) — SIN cambios |
| CI | **success** — run `30967535556`, headSha `3b02d6d`, suite **62/62** + build verde. `https://github.com/aibanez82/Dashboard_seguroautoqualitas/actions/runs/30967535556` |

Un solo push, ya terminado. Fixture y contrato sin tocar.

## El P1 y el fix (verificado contra los canarios PostgreSQL-like)

**Diagnóstico (confirmado por el Arquitecto):** `qualitas_cotizacion.id` es `BIGINT` (OID 20)
y `pg` se usa SIN `setTypeParser` para ese OID → devuelve los BIGINT como **STRING**
(`quotation_id: "81003"`). El request se parsea con `parseInt` (Number `81003`). Los dos
gates de contradicción introducidos en r3 comparaban con `!==` → `Number !== String` es
SIEMPRE desigual → **todo par válido `lead_id`+`cotizacion_id` devolvía 409** contra Postgres
real (la vista de conversación entera). Los tests de r3 no lo detectaron porque los stubs
usaban IDs numéricos, no la semántica de `pg`.

**Fix:** nuevo helper `apps/operacion/lib/s1/ids.js`:

- `idEquals(a, b)` **null-safe**: normaliza ambos lados al string canónico de dígitos vía
  `BigInt` (`String(BigInt(x))` — exacto en todo el rango BIGINT; `Number` pierde precisión
  sobre 2^53) y devuelve `false` sin lanzar si algún lado es null/no numérico.
- Aplicado en los **DOS gates**: camino vivo (`conversation.js` ~128,
  `reqCotId` vs `liveSession.quotation_id`) y camino archive (~106, `reqCotId` vs la
  cotización real del lead). Los binds SQL **no se tocan** (`pg` castea en el servidor); el
  chequeo de `session_id` (strings ambos lados) **tampoco**. Los guardas `!= null` previos se
  conservan para no disparar contradicción cuando el request no trae `cotizacion_id`.

## Rojo → verde de los canarios (handler REAL, filas PostgreSQL-like)

Filas stub con los IDs como STRING, como los entrega `pg` sin parser OID 20:

- **LIVE válido** `request 91003&81003` · fila `quotation_id:"81003"`: rojo sobre `6d9bace`
  (**409**, `Expected 200 !== 409`) → verde con el fix (**200**, llega a leer mensajes Django).
- **ARCHIVE válido** `lead.cotizacion_id:"81003"` + request `81003`: rojo sobre `6d9bace`
  (**409**) → verde (**200**, no corta).
- **Contradictorio** `request 81002` vs fila `"81003"`: **409** antes de toda lectura (sigue
  verde; asertado por captura de SQL: no consulta `n8n_chat_histories` ni
  `qualitas_whatsappmessage`).

Tests nuevos: 3 en `scripts/s1/test/handlers.test.js` (sobre el handler real vía el seam de
runtime) + 5 en `scripts/s1/test/ids.test.js` (unit de `idEquals`/`toCanonicalId`: Number↔String
del mismo BIGINT, distintos, null-safe sin lanzar, y **exactitud sobre 2^53** donde `Number`
colapsaría). Los tests numéricos previos de r3 quedan intactos — **ambos formatos pasan**.

Suite completa: **62 tests, 62 pass, 0 fail** (54 previos + 3 r4 + 5 unit). Build
`npm run build --workspace=operacion`: verde. Node 22 en CI.

## Notas de proceso

- **Cero acciones vivas:** ninguna conexión a PROD ni STG; toda la suite es stubs. Sin deploy,
  sin abrir Preview, sin BD real, sin secretos.
- **Preview Vercel auto-creado por el push** (efecto automático de plataforma, declarado, sin
  acceso): no lo abrí ni lo cito como evidencia.
- `stg` y `main` del Dashboard intactos; `claim.js` intacto; fencing de claims preservado.
- Cambios acotados EXCLUSIVAMENTE a este cierre: `apps/operacion/lib/s1/ids.js` (nuevo),
  `apps/operacion/pages/api/conversation.js` (import + 2 gates), y los dos ficheros de test.
  Nada fuera del P1.

Listo para reverificación sobre el árbol inmóvil `3b02d6d`.
