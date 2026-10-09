# Informe — PROD viaje 4 (`#545`, la base del RFC la calcula el grafo): aplicado

**De:** Agente n8n · **Para:** Arquitecto · **9 oct 2026, 00:21 UTC**
**Responde a:** `Agente-n8n:handoffs/2026-10-08-orden-prod-viaje-4-rfc-base.md` (e62e7166). Confirmación del import de Alberto en mi sesión («go»).

**Issue Policy Guard PROD `SEKpp6E4gggaHj11`: `533ba7be` → `9aa96337-327e-409f-ad1c-a72cc6f9cc51`.** El bot **no se toca**: sigue en `458024c6`, comprobado antes y después del PUT.

- **Respaldo:** `backups/prod-viaje4/PROD-SEKpp6E4gggaHj11-533ba7be-pre-20261009T002113Z.json`.
- **Espejo:** `workflows/Issue Policy Guard.json` en `main` y `stg`.
- **Scripts:** `scripts/prod-viaje4/` (`promote-viaje4-prod.py`, `paso0.js`), rama `chore/prod-viaje4`.

## Paso 0: el `jsCode` literal del vivo `b431ad23` (por GET), ejecutado fuera de n8n

Ese código es idéntico byte a byte al de mi rama (`rfc-base.js` + `nodo-calcular-base-rfc.js`).

| prueba | resultado |
|---|---|
| corpus real (88) | **0 excepciones** · 82 coincide · 4 sustituye · 2 `fecha_distinta_no_es_titular` sin tocar (1896, 1914) |
| 9 bordes | 9/9 |
| entradas degeneradas: sin RFC, sin `grupo2`, `rfc` null, nombre vacío, todo null, `captured_data` null o ausente, `grupo1` null, fecha basura, `rfc` objeto | **10/10 vuelven intactas** (solo se añade `_rfc_545`); 0 excepciones |

**81 frente a 82, reconciliado y aceptado por ti:**
- 81 es el algoritmo solo, comparando únicamente la columna `rfc`.
- El 1900 tiene la base partida entre `rfc` y `homoclave`; unida, como lo hace el nodo, coincide.

## Import, verificado en el vivo

- **Precondiciones:**
  - IPG PROD en `533ba7be` (17 nodos), STG en `b431ad23` (18);
  - **el resto de nodos de PROD son iguales a los de STG**, salvo `Call Issue Policy Real`, donde **solo** difiere la `url`;
  - el resto de connections, iguales;
  - PROD con `Read Emission Record → Build Emission Record`.
- **Diff:**
  - nodos 17 → 18 (`Calcular Base RFC`, idéntico al de STG en parámetros y propiedades, sin credenciales ni `onError`, como en STG);
  - connections: solo `Read Emission Record → Calcular Base RFC → Build Emission Record`;
  - el resto, byte-idéntico;
  - `Call Issue Policy Real`/url, la de PROD, intacta; ni rastro de `hyl-wai-stg`;
  - workflow activo.
- **No viaja:** la línea contradictoria del `systemMessage`; el bot no se toca. Queda para la firma de Alberto.

## Pendiente

**La primera emisión real de PROD**, que mides tú. Se verá en `_rfc_545` de `Build Emission Record`: `aplicada`, `desacuerdo` o el `motivo` por el que no se tocó.

Agente: Agente-n8n
