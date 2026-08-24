# Informe F4.bis — la Data Table de PROD, su fila, y el censo que cierra la clase

> Agente n8n · 24 ago 2026 · Handoff `2026-08-24-f4bis-data-table-de-prod-y-fila-en-el-espejo.md`
> (corregido en `851e9bf`) + tu respuesta a la duda del 403 (`f9ffee4`). GO dado por Alberto en el
> chat de mi sesión. **Resultado: COMPLETO.** `stg@f966e24` (PR #89).

## La tabla en PROD

- **id `CKUcyIg4N6YqsjAl`**, nombre `quote_document_deliveries`, **seis columnas string idénticas
  a las de STG** (`conversation_id`, `delivery_method`, `inbound_message_id`,
  `provider_message_id`, `quotation_id`, `status`) — **leída por `GET /api/v1/data-tables` de la
  instancia de PROD**, no de la UI ni del fichero. PROD tiene exactamente **1** data table (ahora
  sí es una medición: HTTP 200, no un 403 tragado).
- **Auditoría de creación**: la tabla apareció creada desde la UI en la ventana en la que Alberto
  estaba en ella generando la key; le he pedido confirmación explícita de que fue él. La key es
  el otro dato de auditoría: `N8N_API_KEY_DT`, **adicional** (la vieja sigue intacta para
  Dashboard y drift, como pediste), creada por Alberto e instalada en su `.env` por su shell.
- **El 403, resuelto y explicado**: era **scopes de la key** — con la key nueva, 200; con las dos
  viejas, 403 en `/data-tables` y 200 en `/workflows`/`/executions`. Tu opción 1, con tu matiz de
  no rotar.

## La fila y el builder

`DATA_TABLES` en `entornos.js` con columna por entorno, y `aplicarEntorno()` traduce los
`dataTableId` — **abortando** si un nodo referencia una tabla sin fila o si la columna destino es
`null` («un espejo que traduce a nada no es un espejo»).

## El test que vale más que las tres filas juntas — F4(H), censo de recursos de instancia

La pregunta que implementa no es «qué categorías conozco» sino **«qué recursos viven en la
instancia y no en el grafo»**: para cada candidato y entorno, enumera TODA referencia a recurso de
instancia — credenciales, `toolWorkflow`/`executeWorkflow`, `dataTable` — y exige que cada una
tenga su fila con la columna de ese entorno; además, ninguna columna muerta. El «8 de 9» pasa a
ser una aserción que la suite recalcula sola.

**Censo actual: 91 nodos con referencia · 9 recursos distintos · 9 con fila. Los dos números que
pediste iguales, son iguales — por construcción.**

**Prueba por mutación** (tu criterio de verificación): columna `prod` a `null` → **3 rojos** (el
F4(H), el C del espejo y la reproducibilidad, porque el builder aborta la emisión); restaurada →
**301/301 verde**. El PR nació además en rojo a propósito con la columna null, así que la mutación
está probada en las dos direcciones y consta en la historia de la rama.

## El candidato regenerado

| artefacto | sha256 |
|---|---|
| `main-candidato-prod.json` | **`167c5c18e9a0cc97d3f53497fd4b40aa15c174e5191eda04e52a180a96cfde81`** |
| `main-candidato.json` (STG) | `45b9c183…` — **intacto**, sin cambio |

Ausencia cruzada: **0** apariciones de `bIxZXnNOotosIa5q` en el candidato PROD (4 de
`CKUcyIg4N6YqsjAl`); **0** del id de PROD en el de STG (4 del suyo).

## Límites

El bot vivo de 119 **no se tocó** y sigue respondiendo. No se reimportó nada. Una sola data table
creada (y no por mí ni por API: desde la UI). Ninguna variable de entorno tocada por mí (la
`N8N_API_KEY_DT` la añadió Alberto a su `.env`). Nada en STG salvo lecturas. Al regenerar no
apareció ninguna sexta referencia — el censo lo habría dicho.

**F4 queda listo para reintentarse cuando lo ordenes**: candidato `167c5c18` con la tabla de PROD,
el guard, las URLs y la red de error — y un test que rompe la suite si aparece un décimo recurso
sin fila.
