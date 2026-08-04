# Informe — Dashboard S1 v1.1 ronda 2 (corrección FAIL P0/P1)

> Del Agente Dashboard al Arquitecto, 4 ago 2026. Responde a
> `Dashboard:handoffs/2026-08-04-s1-v11-correccion-r2.md` y al dictamen `#132 c.5185027837`.
> Este informe va aquí (no a `Dashboard/main`) por la regla de proceso 1 del handoff.

## Candidato

| Campo | Valor |
|---|---|
| Rama | `feature/s1-v11-dashboard` |
| SHA sucesor (único, sobre `f2d8250`) | `7996c8e186d78e659b3eaff343dbc45b66b70e87` |
| Tree | `6afeebcaba53c208457374a1814b919a75a1c10d` |
| Base | `stg@e50e3adaf6f646df0b4f9b990daeb00a5b2eccc7` |
| Contrato | `S1-DUAL-STG v1.1.0 @ aef501f` (hash `eca082ba…` verificado, ahora pinneado en el repo) |
| CI | **success** — run `30956488457`, headSha `7996c8e`, suite **51/51** + build verde. `https://github.com/aibanez82/Dashboard_seguroautoqualitas/actions/runs/30956488457` |

Sin pushes intermedios presentados: la rama se pusheó una sola vez, ya terminada.

## Mapa dictamen → fix (con evidencia en la suite)

**P0-D1 — `/api/conversation` mezclaba A/B.** Ahora resuelve la fila viva SIEMPRE server-side por
lead/cotización (`lib/s1/resolve.js::resolveForView`, reglas §7.1: elegibilidad, cardinalidad,
contradicción) y deriva `session_id` de ESA fila. El `session_id` del cliente ya no es selector:
si llega y no coincide con el resuelto → `conversation_contradiction` 409 sin datos. Se preserva
el camino archive legacy (recotización). `ConversationModal.js`/`ConversationWorkspace.js` mandan
solo `lead_id`+`cotizacion_id`.
· Tests (handler REAL): cliente manda session A con fila resuelta B → 409 y **no** lee historial;
contradicción de identidad → 409; dos sesiones distintas → 409 ambiguous; caso feliz → objeto
lógico correcto e historial leído por la sesión resuelta B (nunca A).

**P1-D1 — validación de identidad/transporte/lead/cotización.** `identity.js`: legacy exige
`session_id` de dígitos; el `<cotizacion_id>` embebido en un `conversation_id` v2 debe coincidir
con la cotización de la fila. `retomarBuilder.js`: valida `phone_number` (dígitos, no vacío) y la
consistencia `lead_id`/cotización de la fila resuelta. Los 4 canarios del dictamen quedan
rojos→verdes (casos 1-2 en `identity.test.js`, casos 3-4 en `fixture-dashboard-retomar.test.js`).

**P1-D2 — superficies reales, no simulaciones.** Nueva `scripts/s1/test/handlers.test.js` importa
y ejecuta los **handlers reales** de `pages/api/{conversation,db-leads,inbox,n8n-proactive-message}`
vía un seam de runtime (`apps/operacion/lib/runtime.js`) que sustituye `query`/`getAgentFromRequest`
sin cambiar el comportamiento de producción (overrides null en prod), con `fetch` espiado. Cambios
acreditados: `/api/conversation` devuelve el objeto lógico (`conversation_id`, `identity_mode`,
`phone_number`, `status`, `closed_at`); `/api/db-leads` expone el nombre contractual `lead_id`;
los errores S1 conservan `{ok:false,error,code}`; el wire se compara **EXACTO con timestamp**
(reloj inyectado, el fixture lo prevé).

**P1-D3 — fingerprint y baseline reales.** La suite pinnea y verifica el SHA-256 del **contrato**
(`eca082ba…`, copia congelada en `scripts/s1/fixtures/s1-dual-stg-v1.1.md`) además del fixture. Los
fail-first ejecutan el **código REAL de `e50e3ada`** extraído con `git show e50e3ada:<path>`
(`scripts/s1/test/_baseLoader.js`): el `splitDuplicates` inline de la base y el handler proactivo
base — no réplicas manuales. CI con `fetch-depth: 0` para que el commit base esté en el clon.

**P1-D4 — aislamiento PROD.** La adaptación S1 (resolución exacta + wire v1.1 + validación de eco)
corre SOLO bajo el gate de ambiente (Preview `stg`, donde el proactivo ya responde 403). Fuera de
ese gate (`s1Mode===null`: PROD y cualquier otro entorno) el camino es **byte a byte** la base
`e50e3ada`. Test en modo `production`: el body enviado es `{phone_number:session_id, message,
session_id}` (identidad=transporte de la base), **sin** campos v1.1 → PROD no cambia.

## Evidencia por superficie (resumen)

- **API** `db-leads`/`inbox`: A/B (mismo teléfono, cotizaciones distintas) devueltas como dos filas
  con `session_id` distinto e `identity_mode` correcto; `lead_id` contractual presente.
- **modal/conversation**: cada lead abre su sesión exacta; sin fallback telefónico; cruce imposible.
- **funnel**: `splitDuplicates` (extraído a módulo, mismo comportamiento) conserva A/B con sesión
  propia; el bug #8 original (doble-envío sin sesión) sigue colapsando.
- **runtime modes**: `blocked`→GET 503/POST 403; `read_only`→GET ok/POST 403; cero DB/red en los
  rechazos (query/fetch no invocados, verificado por espías).
- **fail-first**: base real de `e50e3ada` colapsa A/B y rechaza `waq_*` por prefijo / manda
  `phone_number=session_id`; el candidato no.

Conteo: **51 tests, 51 pass, 0 fail**. Build `npm run build --workspace=operacion`: verde.

## Notas de proceso (dictamen / ADENDA)

- **Cero accesos vivos** en esta ronda: ninguna conexión a PROD ni STG; toda la suite es stubs.
- **Preview Vercel auto-creado por el push** (efecto automático de plataforma, declarado, sin
  acceso): al pushear `7996c8e` Vercel generó un nuevo deployment Preview
  (`…-5ingak71y-…`, visible solo por `vercel ls`, sin abrirlo ni configurarlo). No lo toqué.
- `stg` y `main` del Dashboard intactos; `claim.js` intacto; fencing de claims preservado.
- Node: la suite requiere los handlers ESM bajo `node --test` gracias a la detección de sintaxis de
  módulos (Node ≥22.7) y `require(ESM)` (≥22.12); CI fija `node 22` (última 22.x). Reproducción
  del Arquitecto: `node --test scripts/s1/test/*.test.js` desde la raíz, con un clon que incluya
  `e50e3ada` (para los `git show`).

Listo para reverificación sobre el árbol inmóvil `7996c8e`.
