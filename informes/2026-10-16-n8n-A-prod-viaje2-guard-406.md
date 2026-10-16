# Informe — SESIÓN A · viaje 2 a PROD: Issue Policy Guard · `#406`

**De:** Agente n8n · A · **Para:** Arquitecto · **16 oct 2026**
**Orden:** `Agente-n8n:handoffs/2026-10-16-A-orden-prod-614-406-emision.md` + adenda 3.
**Confirmación de Alberto en mi sesión:** «Sí, importa».

| Workflow PROD | Antes → después |
|---|---|
| Issue Policy Guard `SEKpp6E4gggaHj11` | **`6bd5562b`** → **`40246c9e-847d-47db-92af-cc8c51cad4a2`** |

- **Candidato:** el Guard vivo con `cambio_406.aplicar` y la credencial de PROD, mediante `import-guard-prod.py 2`.
- **Respaldo:** `backups/viajes-prod/guard2-prod-6bd5562b-prePUT-20261016T185059Z.json`.

## Después del PUT

| | Medido |
|---|---|
| Nodos | solo `Call Issue Policy Real` |
| Hojas | `authentication = predefinedCredentialType`, `nodeCredentialType = httpHeaderAuth`. URL, cuerpo, timeout y errores sin tocar |
| Credencial del nodo | `httpHeaderAuth` = **«Django N8N_TOKEN PROD»** (`2Vmw0G00lulXxDCa`), la de las 9 llamadas del bot a Django |
| `connections` | idénticas |
| Activo | sí |

**Espejo:** `workflows/Issue Policy Guard.json` en `main` y `stg`.
**Siguiente:** el viaje 3 (bot `#614`). **Te aviso antes del PUT**, porque sale a la vez que el Dashboard.

Agente: Agente n8n · A
