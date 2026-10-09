# Informe — PROD viaje 1 (`#563` + `#472` + `#348`): aplicado

**De:** Agente n8n · **Para:** Arquitecto · **9 oct 2026, 00:11 UTC**
**Responde a:** `Agente-n8n:handoffs/2026-10-08-orden-prod-viaje-1-vin-de-foto.md` (16518f28). GO de Alberto en mi sesión («go»).

**Bot PROD `fe9c5213` → `b7caf68b-103b-4548-9164-c5eff9832e80`.**

- **Respaldo:** `backups/prod-viaje1/PROD-BtOaZm7WlZT-24V7hqCnF-fe9c5213-pre-20261009T001134Z.json`.
- **Espejo:** `main` y `stg`.
- **Script:** `scripts/prod-viaje1/promote-viaje1-prod.py`, rama `chore/prod-viaje1`.

## Método

**La tabla de tu orden es la autoridad.** Para cada nodo de la tabla, el diff PROD `fe9c5213` ↔ STG `18073441` tenía que ser **exactamente** las hojas listadas (si no, parada), y esas hojas toman el valor de STG.

- **Precondiciones:** PROD en `fe9c5213`, STG en `18073441`, y presentes `Inject Serie Note`, `Check Typed VIN`, `Restore After Typed VIN`, `Claim Normal Guard Outbound`, `WA Config`, `Persist Guard VIN` y `Provide Required Data`.
- **Revisión:** antes del PUT revisé, línea a línea, el diff textual de cada hoja.

## Diff, verificado en el vivo tras el PUT

| hoja / nodo | contenido |
|---|---|
| `Discount Normal Guard`/query | + `serie_foto_value` y `serie_foto_status` |
| `Route Normal Guard`/jsCode | + `reglaConfirmacion` v2 + la rama del VIN de foto en `pending_data` |
| `Detect Confirmation`/jsCode | la misma `reglaConfirmacion` (byte a byte); `__fotoConfirm` pasa a ser `yes`/`no`/`ambiguo` |
| `Promote Foto VIN`/query | + `AND $1 IN ('yes', 'no')` |
| `Save Group2 Progress`/query | + `aviso_serie` en el `RETURNING` |
| `Extract VIN Vision`/jsonBody · /options/timeout | modelo desde `WA Config`, `max_tokens` 6000, prompt del lector (B) · 20000 → 90000 |
| `Parse VIN Extraction`/jsCode | lee el primer bloque `text` + el comentario-puntero `HYL-WAI#477` |
| `WA Config`/jsCode | **solo el bloque de `visionModel`** |
| **nodo nuevo** `Persist Guard Foto VIN` | credencial Postgres de PROD; aristas `Persist Guard VIN → Persist Guard Foto VIN → Claim Normal Guard Outbound` |

- **Nodos:** 406 → 407. El resto, byte-idénticos.
- **Connections:** solo `Persist Guard VIN` y el nodo nuevo.
- **`WA Config`:**
  - nada del `#257`;
  - la línea de `waPhoneNumberId` (con el fallback de PROD) queda idéntica;
  - el bloque de `visionModel` son **3 líneas físicas**: 2 de comentario y la asignación. La orden decía «dos líneas (comentario + asignación)»: es el mismo bloque de STG, con el comentario partido en dos.
- **Sin tocar:**
  - `Provide Required Data`, que conserva la URL de PROD;
  - la credencial de `Extract VIN Vision` (la de PROD);
  - los dos `systemMessage`.
- **Residuos de STG en lo tocado:** cero.
- **Workflow:** activo.

## Pendiente

- **La aceptación de verdad:** la primera foto real de PROD; la mides tú.
- **El viaje 3:** espera tu acuse con este `versionId` como base nueva. Entonces repito el dry-run contra él y compruebo que no pisa ninguna hoja de este viaje.
- **STG:** la sesión de prueba de Alberto (`waq_2984_…`) sigue `active`. Cuando digas, restauro el resto de sus sesiones a como estaban y la cierro.

Agente: Agente-n8n
