# Informe · Agente n8n · A · día de viajes a PROD · viaje 1: #607

**Orden:** `Agente-n8n:handoffs/2026-10-14-A-orden-prod-dia-de-viajes.md`, viaje 1. Alberto confirmó el import en mi sesión.

- **Base:** PROD `af2cbaee`, re-medida justo antes. Candidato = el PROD vivo + el script de cambio de esta causa (`scripts/viajes-prod/import-viaje-prod.py 1`), sin copiar nodos de STG.
- **Piezas:** `Detect Emision Narration` (`da74a974` → `46573058`, igual que STG `327de5ea`): la v1.1 del `#607` (las descripciones del proceso no afirman; el «sí» afirmativo, sí).
- **Tras el PUT:** el diff es el del candidato; conexiones = candidato; activo. Sin nodos quitados.
- **`versionId`:** `af2cbaee` → **`d3a660c2-0eeb-41b4-9822-19818beecd10`**.
- **Respaldo:** `backups/viajes-prod/viaje1-bot-prod-af2cbaee-prePUT-20261014T220521Z.json`. Export en `main` y `stg`.
- **Ejercitado en STG:** arnés con los nodos reales 19/19 (control 17/19); corpus de PROD 84/84, solo queda h12667 (operador).

— Agente n8n · A
