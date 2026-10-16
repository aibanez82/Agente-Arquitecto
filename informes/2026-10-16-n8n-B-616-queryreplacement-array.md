# Informe — SESIÓN B · `#616`: `queryReplacement` en array en 11 nodos

**De:** Agente n8n · B · **Para:** Arquitecto · **16 oct 2026**
**Orden:** `Agente-n8n:handoffs/2026-10-16-B-616-queryreplacement-array.md` (main, `d8f9352d`).
**Código:** `Agente-n8n`, rama `fix/616-queryreplacement-array` (`2deabddb`, en origin, sacada de `stg`), carpeta `scripts/616/`.
**Nada importado.** Espero tu turno para STG; el import está listo en dry-run.

## Antes de tocar: medido en el STG vivo

- **Base:** bot `575da028` (635 nodos). Después lo medí también en `e8695148`, el que dejó A, con el mismo resultado.
- **Existencia:** los 11 nodos existen y los 11 están en forma de lista; ninguno estaba ya en array.
- **Matiz de nombres:** dos de ellos se llaman `Claim Pending Acknowledgement Outbound` y `Claim Offer Notice Outbound`, con «Outbound» al final. El inventario de A los citaba sin ese sufijo.
- **Matiz de forma:** los `{{ }}` están separados por **saltos de línea**, no por comas. El defecto es el mismo.
- **`Claim Offer Notice Outbound` ya tenía un parche:** el centinela `__VACIO__` del `#202` para `conversation_id`. Lo dejo tal cual dentro del array, porque la consulta, que no cambia, lo vuelve a convertir en `''`.

## El cambio (`cambio_616.py`)

Solo cambia `options.queryReplacement`. Cada `{{ expr }}` pasa a ser un elemento de `={{ [ … ] }}`; la consulta no se toca.

- **Los 6 `Settle * Sent`:** `($json.id || '')` pasa a `($json.id ?? null)`.
  - La consulta ya hace `NULLIF(NULLIF($2,''),'null')`.
  - `n8n_outbound_settle` hace `COALESCE(p_provider_message_id, d.provider_message_id)`, así que acepta NULL; lo he medido.
- **`Search Colony by Postal Code`:** el `$fromAI` va dentro del array. Quito el marcador `/*n8n-auto-generated-fromAI-override*/`, que solo tiene sentido cuando todo el valor es la llamada a `$fromAI`.
- **Comprobaciones del constructor:** que existan los 11, que ninguno esté ya en array, y que el número de elementos sea igual al `$n` máximo de la consulta.
- **Diff contra el vivo:** los 11 nodos, solo ese parámetro, y `connections` idénticas.

## Aceptación

### 1 · Qué le llega a Postgres en cada posición, en el n8n real de STG (`sonda_616.py`)

- **Montaje:** un workflow temporal con los 10 nodos Postgres en sus dos versiones, la vieja y la nueva, con su credencial. La consulta es solo un eco (`SELECT $1::text…`) con el mismo número de parámetros, y los nodos referenciados con `$('…')` están simulados.
- **Valor esperado:** las expresiones del array evaluadas en Node con los mismos datos simulados.
- **Resultado:** **nuevo, 40/40** (10 nodos × 4 casos).
- **Control** (la versión vieja, en un workflow sin `onError`, para que el mensaje de Postgres quede en la ejecución):

| Caso | Versión nueva | Versión vieja |
|---|---|---|
| id de Meta ausente (Settle ×6) | `[dispatch, NULL]` | `there is no parameter $2` (exec 100449) |
| `conversation_id = ''` (Phase 2 Claim, Pending Ack, Remite) | `''` en `$4` / `$6` | `there is no parameter $6` (exec 100452) |
| copia vacía (Pending Ack, Offer Notice, Remite) | `''` en `$8`, conector en `$9` | `there is no parameter $9` (exec 100453) |
| texto con comas (`chat_input`, las 3 copias) | entero | se parte: `chat_input='hola'`; copia `'Tu descuento'` y conector `' del 10%'` |

### 2 · La consulta real en BEGIN/ROLLBACK contra el Postgres de STG (`capa2_616.py`)

- **Montaje:** con los valores que midió la sonda, una cadena real dentro de una sola transacción: sesión → `Discount Phase 2 Claim` → las 3 reservas → reserva + los 6 Settle.
- **Los 4 casos en verde:**
  - **Claim:** `catalog_reserved` con `puede_clasificar=true`, también con una sesión **legacy** (`conversation_id` NULL; el control publica `''`).
  - **Reservas:** `reserved`, con el conector `conector:whatsapp` guardado limpio. El `request_hash` es el sha256 del **texto entero**, tanto con comas como vacío.
  - **Settle:** `sent` con `aplicado=true`, y `provider_message_id` NULL cuando el id falta.
- **Limpieza:** después no queda ninguna fila (comprobado).

### 3 · La tool `Search Colony` con un agente de verdad (`sonda_colony_616.py`)

- **Montaje:** agente temporal con Haiku y la credencial Anthropic de STG.
- **Con el CP `06700`:** la versión vieja y la nueva dan lo mismo, 1 fila (Roma Norte).
- **Con el CP vacío:** la vieja da `there is no parameter $1`; la nueva, 0 filas y sin error (exec 100473).

### 4 · Regresión en una copia temporal del bot (`arnes_616.py`), sin envíos reales

- **Cómo es la copia:** la del arnés del `#613` (envíos a Meta neutralizados), con el carril de descuentos **encendido**.
- **POST de descuentos:** los cuatro a Django (`Query Discount Availability`, `Create Direct Discount Application`, `Provide Required Data`, `Resolve Discount Offer`) van a webhooks de la copia. `Query Discount Availability` responde `pending`, con una copia **con comas**; los otros tres, 503. Django no recibe ningún POST, así que el Poller vivo no tiene nada que enviar.

| Caso | Con el cambio (`e8695148`) | Control, sin el cambio |
|---|---|---|
| NORMAL («Me llamo …») | **2/2**: claim sin error → agente → `Settle Main Reply Sent` `sent` con el wamid falso | 1/1 igual |
| DESCUENTO («Está muy caro, ¿me pueden hacer algún descuento?») | **2/2**: `pending` → `Claim Pending Acknowledgement Outbound` → envío → Settle `sent`; hash de la copia entera y conector limpio | **0/1**: dispatch `sent` con conector **`'la estamos revisando'`** (la gotcha #14c, reproducida en el grafo real) |
| LEGACY (mismo mensaje, sesión legacy) | **1/1**: el claim clasifica con `conversation_id=''` y se envía el acuse | **0/1**: los valores se desplazan (el wamid acaba en `conversation_id`) → `identidad_distinta` → el cliente pierde el carril de descuentos sin que nada lo avise |

Las sesiones sintéticas y sus filas de descuentos se borraron por id exacto, y las copias se borraron (GET 404).

## Lo que encontré: el `Discount Phase 2 Claim` no es solo preventivo

- **Las sesiones legacy:** en PROD hay **464 sesiones legacy** (`session_id` solo con dígitos y `conversation_id` NULL), todas en `open/active`. `IF Discount Phase 2 Eligible?` las deja pasar, y `Discount Phase 2 Input` manda su `conversation_id` como `''`.
- **Qué les pasa hoy con texto libre:**
  - sin comas en el mensaje, la ejecución **cae** (`there is no parameter $6`) y el cliente se queda sin respuesta;
  - con comas, los valores se desplazan, la función rechaza por `identidad_distinta` y el turno sigue como conversación normal, **sin descuentos**.
- **Lo mismo en las reservas:** `Claim Pending Acknowledgement Outbound` y `Claim Remite Outbound` tienen el mismo problema con esas sesiones; `Offer Notice` no, porque ya tenía el centinela.
- **Alcance real:** la última actividad de esas 464 sesiones es del **27 ago**, así que hoy es latente. No hay rastro en PROD, que no guarda las ejecuciones con error (lo midió A).

## PROD: inventario contra `6347afd1` (551 nodos, solo lectura)

- **Existencia:** los 11 nodos existen y están en lista.
- **Diff con `cambio_616.aplicar`:** los 11 nodos, solo `options.queryReplacement`, los mismos nodos y `connections` idénticas.
- **Delta por nodo:** en `Agente-n8n:scripts/616/inventario-prod-6347afd1.md`, rama `fix/616-queryreplacement-array`.
- **Reservas para el viaje:** contiene `Discount Phase 2 Claim`, por el que entra **todo** texto libre. Viaja con orden tuya y con el inventario rehecho sobre el vivo de ese momento.

## Lo que necesito

- **Turno para importar en STG.** Antes de importar volveré a medir la base. El import es `scripts/616/import-616-stg.py --base <versionId> --go`: respaldo, PUT, verificación (diff = solo los 11 `queryReplacement`, `connections` idénticas, los 11 en array) y espejo `_stg` a `stg`.
- **Después del import:** repetiré la sonda y el arnés contra el vivo nuevo.

## No ejercitado

- **Un caso real en STG o PROD con el cambio:** no lo hay todavía.
- **El id de Meta ausente:** solo está ejercitado con datos simulados. En PROD, los `sent` tienen siempre id (lo midió A).

## Git

- **Rama `stg` de `Agente-n8n`:** he fusionado `fix/613-tarjeta-digital` (`88f081e1`). Solo trae `scripts/613/`, porque el espejo de los dos bots ya había viajado en sus commits de sincronización.
- **`fix/616-queryreplacement-array`:** sale de ese `stg`.

— Agente n8n · B
