# Informe #496 — la observación de la Limitada guarda los textos sin truncar (STG)

**De:** Agente n8n · **Para:** Arquitecto · **7 oct 2026**
**Responde a:** `Agente-n8n:handoffs/2026-10-07-496-observacion-limitada-truncada.md`.
**Estado:** aplicado en STG y aceptado **2/2**, con fail-first. **PROD no está tocado.**

## Cambio y diff

**Bot STG:** `12bdbba8` → **`faa1da51`**. Respaldo: `backups/496/bot-stg-12bdbba8-20261008T001827Z.json`.

- `Persist Limitada Observation`/`options/queryReplacement`: pasa de cadena con un valor por línea a **array**, como manda el gotcha 40:
  `{{ [ sessionId, quotationId, leadId, chatInput, texto de la alerta, output ] }}`. La consulta no cambia.
- **Diff contra el respaldo:**
  - hojas: **solo esa**;
  - connections idénticas; el workflow activo.
- **Código:** rama `fix/496-observacion-limitada-sin-truncar`, `scripts/496/`.

## Aceptación

| # | Resultado | Evidencia |
|---|---|---|
| 1 | **PASS, con fail-first** | En `BEGIN/ROLLBACK` no se reproduce: el corte lo hace n8n al pasar los parámetros. Lo probé con un **arnés temporal en STG** que ejecuta el nodo real, copiado byte a byte, en dos versiones: la vieja y la nueva. Entrada con comas y cifra con miles: «Hola, quiero la limitada, pero con grúa, ¿cuánto sale?». Respuesta: «…$10,117.62 MXN, e incluye RC, gastos médicos, y asistencia vial.». Resultados de la ejecución **81018** en la tabla de abajo. |
| 2 | **PASS** | Diff: arriba. |

| Versión | `chat_input` | `reply_excerpt` | `reply_sha256` |
|---|---|---|---|
| **Vieja** | «Hola», **truncado** | «quiero la limitada»: el **2.º trozo del mensaje del cliente** | ≠ sha256 de la respuesta |
| **Nueva** | completo, con comas | la alerta completa, con `$10,117.62` | **= sha256 de la respuesta entera** |

La versión vieja no solo truncaba: **desplazaba los campos**. Lo que llegaba como «alerta» era un trozo del mensaje del cliente.
Filas del arnés borradas (266 y 267) y workflow borrado (GET 404).

## Las 13 filas anteriores no se reparan

Las filas que ya hay en `n8n_limitada_observation` **no se tocan**: están truncadas y probablemente con campos desplazados.
**La observación empieza de nuevo desde este arreglo** (STG `faa1da51`). Cualquier medición sobre esa tabla tiene que filtrar por
fecha posterior al import.

— Agente n8n
