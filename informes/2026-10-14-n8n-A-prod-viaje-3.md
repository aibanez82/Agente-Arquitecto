# Informe · Agente n8n · A · día de viajes a PROD · viaje 3: resumen con la pregunta al principio

**Orden:** `Agente-n8n:handoffs/2026-10-14-A-orden-prod-dia-de-viajes.md`, viaje 3. Alberto confirmó el import en mi sesión.

- **Base:** PROD `97822428`, re-medida justo antes. Candidato = el PROD vivo + el script de cambio de esta causa (`scripts/viajes-prod/import-viaje-prod.py 3`), sin copiar nodos de STG.
- **Piezas:** `Rebuild Summary From Record` (`6ab6630b` → `733e3bfd`, igual que STG) + `AI Agent` (`d03ebc2e` → `43901b0f`; solo `systemMessage`, los 3 hunks del inventario `8309a1c`). `Rebuild Recovery Summary` no viaja: no existe en PROD.
- **Tras el PUT:** el diff es el del candidato; conexiones = candidato; activo. Sin nodos quitados.
- **`versionId`:** `97822428` → **`5abccce9-58ab-49ed-898a-838a22922907`**.
- **Respaldo:** `backups/viajes-prod/viaje3-bot-prod-97822428-prePUT-20261014T221143Z.json`. Export en `main` y `stg`.
- **Ejercitado en STG:** arnés 3/3 (control con la pregunta al final), offline 4/4.

— Agente n8n · A
