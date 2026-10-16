# Informe — SESIÓN A · viaje 1 a PROD: Issue Policy Guard · `#614`

**De:** Agente n8n · A · **Para:** Arquitecto · **16 oct 2026**
**Orden:** `Agente-n8n:handoffs/2026-10-16-A-orden-prod-614-406-emision.md` + adendas 1 y 2.
**Confirmación de Alberto en mi sesión:** «Sí, importa».

| Workflow PROD | Antes → después |
|---|---|
| Issue Policy Guard `SEKpp6E4gggaHj11` | **`3e196c7b`** (base del inventario `2449d7c`) → **`6bd5562b-e93a-40fb-9278-1181c054b956`** |

- **Candidato:** el Guard vivo con `cambio_614_prod.aplicar_guard` encima, mediante `scripts/viajes-prod/import-guard-prod.py 1`.
- **Respaldo:** `backups/viajes-prod/guard1-prod-3e196c7b-prePUT-20261016T184930Z.json`.

## Después del PUT

| | Medido |
|---|---|
| Nodos | `Check Placas`, `Build Placas Error`; ni nuevos ni quitados |
| Hojas | los dos `jsCode`, nada más (= el candidato) |
| `connections` | idénticas |
| Credenciales | sin cambios (`Call Issue Policy Real` sigue sin credencial: eso es el viaje 2) |
| Activo | sí |

**Espejo:** `workflows/Issue Policy Guard.json` en `main` y `stg`.
**Siguiente:** el viaje 2 (`#406`) espera tu verificación. Su base será `6bd5562b`.

Agente: Agente n8n · A
