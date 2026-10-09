# Informe — PROD viaje 3 (`#325` + `#463` + `#479` + `#570`, guardarraíl): aplicado

**De:** Agente n8n · **Para:** Arquitecto · **9 oct 2026, 00:13 UTC**
**Responde a:** `Agente-n8n:handoffs/2026-10-08-orden-prod-viaje-3-guardarrail.md` + adenda `5bad9b1c`. Acuse del viaje 1: `b9d6979`. GO de Alberto en mi sesión («Go»).

**Bot PROD `b7caf68b` (base re-medida) → `458024c6-a865-4244-81c6-fee250078862`.**

- **Respaldo:** `backups/prod-viaje3/PROD-BtOaZm7WlZT-24V7hqCnF-b7caf68b-pre-20261009T001323Z.json`.
- **Espejo:** `main` y `stg`.
- **Script:** `scripts/prod-viaje3/promote-viaje3-prod.py`, rama `chore/prod-viaje3`.

## Método: replay del diff acreditado

Cada issue reaplica sobre el PROD vivo el diff que su commit hizo en el export de STG, en orden:
`#325` 50c9111e → `#463` 12109660 → `#479` 7f26e790 → `#570` ed21033a.

- **Exigencia:** antes de tocarlo, el valor de PROD de cada hoja y conexión tiene que ser igual al que tenía STG antes del cambio. **0 conflictos.**
- **Nodos nuevos:** se copian con la credencial de PROD del mismo tipo.
- **Pasajero excluido:** `Haiku`/`cachedResultName`, que venía en el commit-espejo del #325. Es solo el nombre mostrado; el modelo `claude-haiku-4-5-20251001` es el mismo.
- **Control previo:** en la prueba sobre `fe9c5213`, cada nodo nuevo o tocado, y cada arista, coincidía con el STG acreditado tras el `#570` (`ed21033a`).

## Diff, verificado en el vivo tras el PUT

- **Nodos:** 407 → **416** (+9): `Guardrail Error Safe Reply`, `¿Jailbreak evaluado?`, `¿Sin texto del cliente?`, `IF Turno Guardarraíl?`, `Persist Human Row (Guardarraíl)`, `IF Turno Guardarraíl Enviado?`, `Build Guardarraíl AI Row`, `Insert Guardarraíl Turn History` y `Mark Guardarraíl Persist Failed`.
- **Tocados:**
  - `Detect Jailbreak`: `onError` continueErrorOutput, `retryOnFail`, `maxTries` y `waitBetweenTries`;
  - `PII Sanitization`/text, que pasa a ser solo el texto del cliente.
- **Connections (11 orígenes):** `Basic Input Sanitization`, `Detect Jailbreak`, `Guardrail Error Safe Reply`, `¿Jailbreak evaluado?`, `¿Sin texto del cliente?`, `Restore Main Reply Payload`, `Settle Main Reply Sent` y los 4 del `#570`.
- **Viaje 1:** **no toca ningún nodo ni arista suyo**, comprobado antes del PUT.
- **El resto:** los demás nodos, byte-idénticos; los `systemMessage`, intactos; cero residuos de STG; workflow activo.

## Pendiente

- **El primer caso real** de cada rama: fallo técnico del guardarraíl → respuesta segura; turno sin texto del cliente; memoria del turno del guardarraíl.
- **El #325 sigue «no acreditado» en vivo:** el modo de fallo real no se ha capturado nunca. Viaja porque el `#463` manda ahí su rama.

Agente: Agente-n8n
