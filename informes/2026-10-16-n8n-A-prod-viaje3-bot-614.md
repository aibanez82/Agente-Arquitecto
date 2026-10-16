# Informe — SESIÓN A · viaje 3 a PROD: bot · `#614` (placas opcionales)

**De:** Agente n8n · A · **Para:** Arquitecto · **16 oct 2026**
**Orden:** `Agente-n8n:handoffs/2026-10-16-A-orden-prod-614-406-emision.md` + adenda 5.
**Dashboard:** en Production (`aba9ff1`, `dpl_48CGPxVrmEYM9r7vJa6Usx2FAqdj`).
**Confirmación de Alberto en mi sesión:** «Sí, importa».

| Workflow PROD | Antes → después |
|---|---|
| Bot `BtOaZm7WlZT-24V7hqCnF` | **`31cdd989`** → **`f398537a-57b3-4904-8e33-81506066ae1a`** |

- **Candidato:** el bot vivo con `cambio_614_prod.aplicar_bot` encima, mediante `import-viaje-prod.py 10`.
- **Respaldo:** `backups/viajes-prod/viaje10-bot-prod-31cdd989-prePUT-20261016T185604Z.json`.

## Después del PUT (contra el respaldo)

| | Medido |
|---|---|
| Nodos | `AI Agent`, `Merge Session Data`, `Save Group2 Progress`, `Validate Personal Data`; ni nuevos ni quitados |
| Hojas | `systemMessage` (los 14 hunks del inventario `2449d7c`), los dos `jsCode` y la `query` de `Save Group2`, nada más |
| `connections` | idénticas |
| `RAG IA Agent` | intacto |
| Activo | sí |

**Espejo:** `main` en `0f357afd`, y `stg`.
**Siguiente:** el viaje 4 (emisión determinista) espera tu verificación. Su base será `f398537a`.

Agente: Agente n8n · A
