# Informe · Agente n8n · A · Petición de llamada en STG, y diff del #591 v2

**Órdenes:**
- `Agente-n8n:handoffs/2026-10-10-peticion-de-llamada-stg.md`, con su adenda de la noche (D se queda en STG y queda bloqueado para PROD).
- Tu respuesta sobre el `#591 v2`: «importa en STG, en su propio import… pásame el diff y el informe; PROD, con orden de Alberto».

Son dos imports separados y seguidos en el bot STG `dNqtM20ij6ecZYAX`:
- `e8f861f1 → 44404c10`: el `#591 v2`;
- `44404c10 → 5adf0e57`: la llamada.

Todo vive en la rama `fix/firmas-paquete-prompt-stg` de Agente-n8n (`origin`).

---

## 1. Petición de llamada — EN STG (`5adf0e57`)

### Qué entró
- **Carril fijo «Llamada Fija»:** 13 nodos, gemelo del `#552`/límite de 30. Lleva fence (`dllam.reply`), Send, Settle Sent/Uncertain y fila AI con `source='llamada_fija'`.
- **Escritor lateral `Persist Contador Llamada`:** escribe `captured_data.llamada.{a|b|c}`. Por eso cada texto sale **una sola vez** por sesión.
- **Textos firmados:** A, B, B sin descuento y C, tal cual.
- **Prompt:** regla de llamada en los dos agentes, añadida tras la viñeta de «hablar con una persona».
- **D:**
  - `Resolve Session` calcula la prima anual vigente leyendo el XML de la cotización;
  - `Merge Session Data` calcula `msiAnual` solo si el mensaje habla de semestral, trimestral, mensual o meses;
  - el `[CTX:]` lleva `| msi_anual=`;
  - una línea D en cada prompt;
  - **red del grafo** en el `Outbound Leak Guard`: si la respuesta a la pregunta de fraccionado no trae las cifras, inserta la frase D firmada antes de la pregunta final (flag `msiAnualPorGrafo`).
- **Comprobación del import:** respaldo `backups/llamada/bot-stg-44404c10-20261010T235147Z.json`. Hojas y connections iguales al candidato, y el bot queda activo.
- **Nodos de la sesión B:** ninguno en el diff.

### Aceptación (arnés, sin envíos), con la secuencia real de `waq_4379`
| | candidato sobre `e8f861f1` (3 pasadas) | vivo `5adf0e57` (1 pasada) |
|---|---|---|
| A una vez · B una vez · C ante «no me quiere responder» | 3/3 | 1/1 |
| ningún enlace del agente ante «quiero llamar / que me llamen» | 3/3 | 1/1 |
| nada repetido palabra por palabra | 3/3 | 1/1 |
| contador a+b+c en `captured_data` | 3/3 | 1/1 |
| «quiero hablar con un agente» sigue escalando | 3/3 | 1/1 |
| regresión `#418` D1 / límite 30 CASO A | 3/3 · 3/3 | 1/1 · 1/1 |
| **D con las cifras exactas** | **2/3** | 1/1 |

**D:**
- La primera versión salió 2/3: el modelo se saltó las cifras una vez.
- Con la línea D en los prompts, la tanda dirigida dio **10/10**, sobre `44404c10` + cambio: `scripts/llamada/aceptacion-llamada-D-44404c10.json`.
- **Las 10 cifras las puso el modelo.** La red del grafo está montada pero **no se ha ejercitado** en el arnés. Tu pregunta era si D depende del modelo: hoy sí, y por eso el grafo hace de red.

**Tu ruta:** el mensaje habla de la secuencia 14841-14885; el handoff, de 14859-14886. Usé los mensajes de cliente de esa conversación tal cual, con un cambio: **el teléfono del cliente estaba en el script y en los resultados** (commit `462e2a0d`), y en `50cf144f` lo sustituí por uno sintético. La historia no la he reescrito: el número sigue en `462e2a0d`. Si hay que purgarlo, lo decides tú.

### Estado para PROD
- **A, B y C:** listos para viajar cuando se ordene.
- **D: en STG, bloqueado para PROD por el `#592`.** Al cortar el paquete de PROD salen estas tres piezas, salvo que para entonces D lleve la condición (12 MSI solo con un descuento de la cotización vigente ≤ 30 %):
  1. las líneas D de los dos prompts (AI antes de «MSI Y PAGO FRACCIONADO…» y RAG «5.bis»);
  2. `| msi_anual=` del `[CTX:]`, junto con su cálculo en `Resolve Session` y `Merge Session Data`;
  3. el bloque del `Outbound Leak Guard`.
- La regla de llamada sí toca los dos `systemMessage`, así que **el viaje a PROD necesita la firma de Alberto**.

**Scripts:** `scripts/llamada/`:
- `llamada.js` y `bateria.js` (20/20 y la secuencia real);
- `cambio_llamada.py`;
- `aceptacion-llamada-stg.py` con sus JSON;
- `fix-llamada-stg.py`.

Commits `462e2a0d` y `50cf144f`.

---

## 2. `#591 v2` — EN STG (`44404c10`), solo la consulta

**Qué cambia:**
- Solo `Validate Emision Against DB`: `query` y `queryReplacement`.
- `Detect Emision Narration` queda igual que en la v1. El cambio está en el commit `03c10510`.

**El diff** (`scripts/591/cambio_591.py`, `030d84d9..03c10510`):

```diff
-     n AS (SELECT x FROM json_array_elements_text(COALESCE(NULLIF($2::text, ''), '[]')::json) AS x)
+     n AS (SELECT x FROM json_array_elements_text(COALESCE(NULLIF($2::text, ''), '[]')::json) AS x),
+     dados AS (SELECT n.x FROM n WHERE EXISTS (SELECT 1 FROM n8n_chat_histories h WHERE h.session_id = NULLIF($4::text, '__NULO__')
+                 AND h.message->>'type' = 'human' AND regexp_replace(COALESCE(h.message->>'content', ''), '[^0-9]', '', 'g') LIKE '%' || n.x || '%')
+              OR n.x = (SELECT regexp_replace(COALESCE(ws.captured_data->'previous_policy'->>'policy_number', ''), '[^0-9]', '', 'g')
+                          FROM whatsapp_sessions ws WHERE ws.session_id = NULLIF($4::text, '__NULO__'))),
+     inex AS (SELECT n.x FROM n WHERE NOT EXISTS (SELECT 1 FROM p WHERE p.numero_poliza = n.x))
 SELECT (SELECT count(*) FROM p)::int AS polizas,
-       (... n WHERE NOT EXISTS p ...) AS inexistentes,
-       CASE WHEN EXISTS (n WHERE NOT EXISTS p) THEN false
-            WHEN $3::text = 'true' AND NOT EXISTS (SELECT 1 FROM p) THEN false
+       (SELECT COALESCE(json_agg(x), '[]'::json) FROM inex) AS inexistentes,
+       (SELECT COALESCE(json_agg(x), '[]'::json) FROM dados) AS dados_por_el_cliente,
+       CASE WHEN $3::text = 'true' AND (EXISTS (SELECT 1 FROM inex) OR NOT EXISTS (SELECT 1 FROM p)) THEN false
+            WHEN EXISTS (SELECT 1 FROM inex WHERE inex.x NOT IN (SELECT x FROM dados)) THEN false
             ELSE true END AS exists_real;
-QR = [quotationId, JSON(numerosAfirmados), afirmaEmision]
+QR = [quotationId, JSON(numerosAfirmados), afirmaEmision, sessionId || '__NULO__']
```

**La regla, en una frase:** un número que **escribió el cliente** en la sesión, o la póliza anterior del contexto, no cuenta como póliza afirmada por el bot. Hay una excepción: **si el mensaje afirma la emisión**, se comprueba igual.

**Aceptación** (arnés con nodos reales sobre la BD de STG y una sesión sembrada real; 8 casos × 5):

| caso | esperado | v1 (`e8f861f1`) | v2 |
|---|---|---|---|
| 76201 real de la cotización | pasa | 5/5 | 5/5 |
| 76201 inexistente | bloquea | 5/5 | 5/5 |
| 76202 inexistente | bloquea | 5/5 | 5/5 |
| «emitida» sin número, cotización sin póliza | bloquea | 5/5 | 5/5 |
| la misma frase, cotización con póliza | pasa | 5/5 | 5/5 |
| teléfono de 10 dígitos | pasa | 5/5 | 5/5 |
| **renovación: el bot repite la póliza que escribió el cliente (PROD 5962)** | pasa | **0/5 (falso bloqueo)** | 5/5 |
| el bot **afirma emitida** la póliza que escribió el cliente (no existe) | bloquea | 5/5 | 5/5 |

**Resultado:** 7/8 → **8/8**. Contra tu medición de PROD, los 56 casos pasan, incluidos los 6 falsos positivos de renovación: **0 falsos bloqueos**.

**PROD:** pendiente de la orden de Alberto. Viajan los dos nodos del `#591`: `Detect Emision Narration` (v1) y `Validate Emision Against DB` (v2).

— Agente n8n · A
