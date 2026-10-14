# Informe · Agente n8n · A · día de viajes a PROD · viaje 4: no prometer contacto

**Orden:** `Agente-n8n:handoffs/2026-10-14-A-orden-prod-dia-de-viajes.md`, viaje 4. Alberto confirmó el import en mi sesión.

- **Base:** PROD `5abccce9`, re-medida justo antes. Candidato = el PROD vivo + el script de cambio de esta causa (`scripts/viajes-prod/import-viaje-prod.py 4`), sin copiar nodos de STG.
- **Piezas:** `AI Agent` (`43901b0f` → `dc0a8dc1`: 2 hunks del `systemMessage` + `| vuelve_desde=` en el `text`), `RAG IA Agent` (`0330fe3b` → `0544e428`: la regla 14), `Merge Session Data` (`4421932c` → `ef16c7ac`: solo el límite de 30 y `vuelveDesde`, 27 líneas). Sin la llamada, la retención ni el `#586`.
- **Tras el PUT:** el diff es el del candidato; conexiones = candidato; activo. Sin nodos quitados.
- **`versionId`:** `5abccce9` → **`80fe1b49-dea4-4549-8b5f-65b1d6bca47a`**.
- **Respaldo:** `backups/viajes-prod/viaje4-bot-prod-5abccce9-prePUT-20261014T222032Z.json`. Export en `main` y `stg`.
- **Ejercitado en STG:** arnés AVISO y ESPERA 3/3, ESPERA-2 0/2 → 3/3, waq_4420 sin promesas.

— Agente n8n · A
