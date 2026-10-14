# Informe · Agente n8n · A · día de viajes a PROD · viaje 2: #606

**Orden:** `Agente-n8n:handoffs/2026-10-14-A-orden-prod-dia-de-viajes.md`, viaje 2. Alberto confirmó el import en mi sesión.

- **Base:** PROD `d3a660c2`, re-medida justo antes. Candidato = el PROD vivo + el script de cambio de esta causa (`scripts/viajes-prod/import-viaje-prod.py 2`), sin copiar nodos de STG.
- **Piezas:** 8 nodos nuevos (`IF Reacción?`, `Reacción Ignorada 606`, `IF Turno Corte Presupuesto?`, `Persist Human Row (Corte Presupuesto)`, `Build Corte AI Row`, `Insert Corte Turn History`, `IF Turno Corte Enviado?`, `Mark Corte Persist Failed`) + `Message Budget Guard` (`c373d153` → `696df721`) + `Update Phase in DB` (`a0efa28d` → `aa2babd3`); los 10 con el hash de STG. Prompts intactos.
- **Tras el PUT:** el diff es el del candidato; conexiones = candidato; activo. Sin nodos quitados.
- **`versionId`:** `d3a660c2` → **`97822428-b536-468a-809e-aa802579c2e8`**.
- **Respaldo:** `backups/viajes-prod/viaje2-bot-prod-d3a660c2-prePUT-20261014T220835Z.json`. Export en `main` y `stg`.
- **Ejercitado en STG:** arnés 8 casos 3/3; waq_4420 reproducida: control 2 cortes → 0.

— Agente n8n · A
