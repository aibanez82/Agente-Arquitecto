# Informe · Agente n8n · A · día de viajes a PROD · viaje 5: #580

**Orden:** `Agente-n8n:handoffs/2026-10-14-A-orden-prod-dia-de-viajes.md`, viaje 5. Alberto confirmó el import en mi sesión.

- **Base:** PROD `80fe1b49`, re-medida justo antes.
- **Candidato:** el PROD vivo + `scripts/580/cambio_580_prod.py`. En PROD no existe el `META_551` del `#551`, que en STG sustituía la red, así que la red general de fugas (`fuga-razonamiento.js`, copia literal) se **inserta justo antes de la red del límite de 30**, con su marca `fugaRazonamiento580` en el `return`. **Sin el bloque de la frase D** de la llamada (`#592`): comprobado que no está ni `msiAnualPorGrafo` ni el texto D.
- **Pieza:** `Outbound Leak Guard` (`f4a94771` → `1340b9ad`). Prompts intactos.
- **Tras el PUT:** el diff es el del candidato; conexiones = candidato; activo.
- **`versionId`:** `80fe1b49` → **`4b9eaf42-bf81-4c81-a2bd-fbfd3d0f1261`**.
- **Respaldo:** `backups/viajes-prod/viaje5-bot-prod-80fe1b49-prePUT-20261014T222356Z.json`. Export en `main` y `stg`.

**Medido antes del import**, sobre el candidato de esta base y con el nodo entero ejecutado offline (`prueba-olg-580.js`):

| prueba | control (vivo) | candidato |
|---|---|---|
| (a) positivos del `#580` (PROD 14649, 8591, STG 5136, 11710, arnés 85229) | 2/5 limpios | **5/5** |
| (b) **las 4.333 filas `ai` de PROD** | — | **1 sola cambia: h14649**, el caso real («El cliente sigue insistiendo… No debo dar precio…») |
| (c) límite de 30: las 30 fugas del arnés | — | salida igual al vivo 30/30 y ninguna línea de fuga 30/30 |

**Ojo con la salida del script:** pone «STG ai», pero el corpus de (b) es el de PROD.

— Agente n8n · A
