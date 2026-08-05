# Informe — Dashboard S1 v1.1 ronda 3 (cierre P0 contradicción `lead_id`/`cotizacion_id`)

> Del Agente Dashboard al Arquitecto, 4 ago 2026. Responde a
> `Dashboard:handoffs/2026-08-04-s1-v11-ronda3-contradiccion-lead-cotizacion.md` y al
> dictamen r2 de Juan en `#132` (marcador `contract-first:s1-v1.1:r2-admission:7996c8e:fb98f24`).
> Este informe va aquí (no a `Dashboard/main`) por la regla de proceso del handoff.

## Candidato

| Campo | Valor |
|---|---|
| Rama | `feature/s1-v11-dashboard` (inmóvil tras este commit) |
| SHA sucesor (único, sobre `7996c8e`) | `6d9bacea08f09e054a030216d7cc47be2e1c11ac` |
| Tree | `28bd64c653f5df052a3af362da1f2cb76b3fd3bd` |
| Base r2 | `7996c8e186d78e659b3eaff343dbc45b66b70e87` |
| Contrato | `S1-DUAL-STG@1.1.0` (`aef501f`, sha256 `eca082ba…`) — SIN cambios |
| CI | **success** — run `30965938346`, headSha `6d9bace`, suite **54/54** + build verde. `https://github.com/aibanez82/Dashboard_seguroautoqualitas/actions/runs/30965938346` |

Un solo push, ya terminado. Fixture y contrato sin tocar.

## El P0 y el fix (verificado contra el canario del dictamen)

**Diagnóstico (confirmado por el Arquitecto):** en
`apps/operacion/pages/api/conversation.js`, cuando `lead_id` y `cotizacion_id` llegaban
juntos, el `cotizacion_id` del request nunca se comparaba con la fila resuelta:
`if (cotId == null) cotId = candidates[0]?.quotation_id` solo rellenaba el ausente. Un
`cotId` presente y contradictorio se conservaba y contaminaba (a) la consulta Django
`lead_id = $1 OR cotizacion_id = $2` con el valor del request, y (b) el camino archive.

**Regla implementada (coherencia de selectores, §7.1):** todo selector del cliente
(`lead_id`, `cotizacion_id`, `session_id`) debe pertenecer a LA MISMA fila resuelta.

1. **Captura inmutable** del `cotizacion_id` del request (`reqCotId`) antes de que `cotId`
   se reescriba con la fila resuelta.
2. **Camino vivo:** en cuanto se resuelve la fila, si `reqCotId != null` y difiere de
   `quotation_id` de la fila → `409 conversation_contradiction` (shape `{ok:false, error,
   code}`) **antes** de leer historial n8n, auditoría, mensajes Django o archive. Tras
   pasar el gate, `cotId` se fija a `quotation_id` de la fila resuelta → la consulta Django
   bindea SIEMPRE la cotización resuelta, nunca un valor del request sin verificar (elimina
   el OR contaminante).
3. **Camino archive:** sin sesión viva pero con `lead_id`, se resuelve la cotización REAL
   del lead; si `reqCotId` difiere de ella → 409 **sin tocar** el archive.

El chequeo previo de `session_id` de cliente vs fila resuelta (P0-D1 de r2) se conserva
intacto.

## Rojo → verde del canario (handler REAL)

Canario del dictamen: `lead_id=91003, cotizacion_id=81002` → fila resuelta
`quotation_id=81003`.

- **Rojo sobre `7996c8e`** (handler base, test nuevo presente): el handler devuelve
  **HTTP 200** (binds `[91003, 81002]`) — `Expected 200 !== 409`. Reproducido revirtiendo
  solo el handler y corriendo `--test-name-pattern='P0 r3'`.
- **Verde sobre `6d9bace`:** 409 `conversation_contradiction`, y las aserciones confirman
  que **no** se consultó `n8n_chat_histories`, `qualitas_whatsappmessage`,
  `dashboard_message_audit` ni `whatsapp_sessions_archive`.

Tres tests nuevos en `scripts/s1/test/handlers.test.js`, todos sobre el handler real vía el
seam de runtime (sin Next.js, sin BD, sin red):
1. **Canario contradictorio (vivo)** → 409 antes de toda lectura (asertado por captura de
   SQL: ninguna de las 4 tablas de lectura se consulta).
2. **Simétrico coherente** `lead_id=91003 + cotizacion_id=81003` → 200 y la consulta Django
   bindea `[91003, 81003]` (cotización resuelta, sin OR contaminante).
3. **Contradicción en camino archive** (sin sesión viva, `cotizacion_id` ≠ cotización real
   del lead) → 409 sin tocar archive ni mensajes Django.

Suite completa: **54 tests, 54 pass, 0 fail** (51 previos intactos + 3 nuevos). Build
`npm run build --workspace=operacion`: verde. Node 22 en CI.

## Notas de proceso

- **Cero acciones vivas:** ninguna conexión a PROD ni STG; toda la suite es stubs. Sin
  deploy, sin abrir Preview, sin BD real, sin secretos.
- **Preview Vercel auto-creado por el push** (efecto automático de plataforma, declarado, sin
  acceso): no lo abrí ni lo cito como evidencia.
- `stg` y `main` del Dashboard intactos; `claim.js` intacto; fencing de claims preservado.
- Cambios acotados EXCLUSIVAMENTE a este cierre: `apps/operacion/pages/api/conversation.js`
  y `scripts/s1/test/handlers.test.js`. Nada fuera del P0.

Listo para reverificación sobre el árbol inmóvil `6d9bace`.
