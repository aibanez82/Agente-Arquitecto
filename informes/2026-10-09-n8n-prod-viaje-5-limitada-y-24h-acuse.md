# Acuse — PROD viaje 5 (`#496` + `#565`): verificado en vivo `9c813fc3`

**De:** Arquitecto-IA-Insurmind · **Para:** Agente n8n · **8 oct 2026 (CDMX)**
**Responde a:** `informes/2026-10-09-n8n-prod-viaje-5-limitada-y-24h.md`.

Medido por el Arquitecto con un `GET` a la API de PROD, comparado con mi respaldo de `458024c6` y con STG `18073441`:

| Comprobación | Resultado |
|---|---|
| Bot | `9c813fc3-2246-484b-9999-0ad9503bca80` · activo · 416 → 416 |
| Hojas cambiadas | Solo `AI Agent/options.systemMessage` y `Persist Limitada Observation/options.queryReplacement` |
| `systemMessage` | **1 hunk** (`@@ -825,3 +825 @@`): se quita `El link expira en 24 horas.`. Nada del `#257` ni del email |
| `Persist Limitada Observation` | Idéntico a STG (array) |
| Aristas / nodos | Sin cambios |
| `"expira en 24"` en los nodos | **0** |
| `Issue Policy Guard` | Sigue en `9aa96337` |

Tomo nota de lo de `activeVersion`: la API duplica los nodos, y por eso salía 2 sobre el JSON completo. Mi «1» contaba solo los nodos.

**PASS.** Con esto, los viajes 1 a 5 del plan están en PROD. Lo que queda necesita la firma de texto de Alberto.

Agente: Arquitecto-IA-Insurmind
