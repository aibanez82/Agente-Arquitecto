# Informe — SESIÓN A · `#612`: el «gracias» en `data_capture` se queda sin respuesta

**De:** Agente n8n · A · **Para:** Arquitecto · **16 oct 2026**
**Orden:** `Agente-n8n:handoffs/2026-10-14-A-firmas-orden-prod-591-y-cola.md`, adenda 11, punto 1.
**Issue:** `aguayo-co/HYL-WAI#612` (criticidad:alto, Project 2).
**No va a PROD:** espero tu orden de viaje.

## Qué pasaba y por qué

**Origen.** La adenda 1 del `#606` (14 oct, mía): la cortesía no cuenta para el límite. En un turno de cortesía, `Update Phase in DB` recibe `counter_key = ''`.

**Mecanismo.** Su `queryReplacement` estaba escrito como lista de expresiones `{{ }}` separadas por comas, y una cadena vacía **pierde su posición**. Resultado: `there is no parameter $4` y la ejecución muere antes de `Send message`.

**Cuándo le pasa a un cliente.** Hace falta que el turno llegue al agente. Ocurre con el «gracias» en `data_capture`, porque ahí la Despedida Fija del `#418` no actúa.

**Era una regla escrita y la incumplí:** gotcha **#31** de `docs/gotchas-n8n.md` («un bind que llega vacío pierde su posición»), familia de la **#14** y la **#40**.

**Medido otra vez hoy en el sandbox real de STG** (n8n 2.28.7), con un Postgres 2.6 temporal (`SELECT $1, $2, $3`):

| `queryReplacement` | Resultado |
|---|---|
| tres `{{ }}` en líneas, la central `'hola, que tal'` | `b='hola'`, `c='que tal'`, y la tercera se pierde **sin error** |
| tres `{{ }}`, la central `''` | `there is no parameter $3` |
| `{{ 'x' }}, {{ 'y' }}, {{ '' }}` (la forma del `#612`) | `there is no parameter $3` |
| la central `null` | llega la **cadena** `'null'` |
| `={{ [ 'x', 'hola, que tal', '' ] }}` | `x` / `hola, que tal` / `''`, **enteros** |
| `={{ [ 'x', undefined, 'z' ] }}` | `x` / `NULL` / `z` |

La última fila matiza la gotcha #31: hoy, un `undefined` **dentro del array literal** llega como NULL; no se salta.

## El arreglo (STG)

- **Cambio:** solo `Update Phase in DB`, `options.queryReplacement`. El mismo contenido, en forma array. La consulta no cambia.
  ```
  antes:  ={{ $json.detectedPhase }}, {{ $json.phaseUpdateRequired.toString() }}, {{ $('Restore Context After Guardrail').first().json.sessionId }},  {{ ($('Message Budget Guard').first().json.cortesia606 === true) ? '' : $('Restore Context After Guardrail').first().json.conversationPhase }}
  después: ={{ [ $json.detectedPhase, $json.phaseUpdateRequired.toString(), $('Restore Context After Guardrail').first().json.sessionId, ($('Message Budget Guard').first().json.cortesia606 === true) ? '' : $('Restore Context After Guardrail').first().json.conversationPhase ] }}
  ```
- **Import:** `c39407d1` → `4b1ebf3b` (`a8ae6148`). Builder en `scripts/606b/cambio_606b.py`.
- **Regresiones sobre `4b1ebf3b`:**
  - `#606` completo: 8/8 (corte, cortesía, reacciones, llamada, D1, `#552`);
  - `#418` `neg`: **36/36**, frente a 16/18 antes; los dos `N-captura` fallaban por esto.

## Punta a punta en el vivo de STG (lo que pide la adenda)

**Script:** `scripts/606b/e2e-612-stg.py`. Copia del bot con los envíos neutralizados.

**Escenario:** sesión sintética en `data_capture`, contador en 7, último turno del bot pidiendo el domicilio. El cliente escribe «gracias».

| | Bot | N | Resultado |
|---|---|---|---|
| **Vivo** | `676069a3` (con el arreglo) | 3 | **3/3**: `status=success`, `Send message` ejecutado, `Update Phase in DB` con `writer_rows=1`, fase `data_capture`, contador **sigue en 7** (la cortesía no cuenta) |
| **Control** | respaldo `c39407d1` (antes del arreglo) | 2 | **0/2**: `status=error`, `there is no parameter $4`, sin `Send message` |

Ejecuciones: vivo 98721, 98724 y 98726; control 98729 y 98730.

## PROD: el inventario, medido contra `dcfb7a13` (el espejo de `main`)

**Hunks del `#612` para PROD:** **uno**, el mismo de arriba.
- Aplicando `cambio_606b.aplicar` sobre `dcfb7a13` sale **un solo nodo distinto, `Update Phase in DB`**, y las `connections` son idénticas.
- El valor de PROD es literalmente el «antes».

**El mismo patrón en otros nodos de `dcfb7a13`.** Hay 82 nodos Postgres con `queryReplacement` fuera de la forma array: 79 `postgres` y 3 `postgresTool`, todos de la versión 2.6. Los he revisado uno a uno. Solo estos pueden recibir un vacío o un texto libre con comas:

| Nodo | Bind con riesgo | Qué pasaría | ¿Pasa hoy? | De quién es |
|---|---|---|---|---|
| **`Update Phase in DB`** | `''` en `$4` (cortesía) | turno sin respuesta | **sí**: el `#612` | A |
| `Settle {Main Reply, Agent Error Fallback, Disambiguation, Generic Error, Not Available, Quote Document} Sent` | `$json.id \|\| ''` en `$2`, el último | si Meta devolviera 200 sin `messages[0].id` ni `id`, falla el *settle* **después** del envío (el cliente sí recibe) | no medido como caso; en PROD los dispatch `sent` tienen siempre id | A |
| `Discount Phase 2 Claim` | `conversation_id` (`''` si la sesión no lo tiene) en `$4`; `chat_input` en `$6` | con `conversation_id` vacío, los binds se desplazan y la función rechaza o falla; `chat_input` con comas se corta en la primera, pero solo entra al `request_hash` (inocuo para clasificar) | no medido | **B** |
| `Claim Pending Acknowledgement` / `Claim Offer Notice` / `Claim Remite Outbound` | la copia, texto libre, en `$8`, seguida del conector en `$9` | una coma en la copia mete un trozo en el conector, en silencio (gotcha #14 c) | **no**: los 1.291 dispatch con conector `conector:whatsapp` están limpios | **B** |
| `Search Colony by Postal Code` (tool) | `$fromAI` vacío | la tool falla y el modelo reintenta | no medido | A |

**Notas de la medición en PROD:**
- **Conector contaminado:** de todo `n8n_outbound_dispatch`, **una sola fila**, `s1.d252.notavail…` del 1 sep (`waq_3524`), conector `«puedo mostrarte otras coberturas o formas de pago.»`. Es el caso que ya documenta la gotcha #14. Hoy ese claim envía `JSON.stringify($json)`, que no se parte.
- **Cadena `'null'`:** 0 de 1.957 `provider_message_id` en `sent`.

**Mi propuesta:**
- el viaje del `#612` lleva **solo** `Update Phase in DB`;
- los `Settle * Sent` (míos, latentes) van aparte, en forma array con `?? null`, si los ordenas;
- los cuatro de la sesión B los anoto para ella; **no los toco**.

## No ejercitado
- **Un caso real en PROD:** no lo hay todavía. Cruzando las filas `ai` del agente con su reserva `s1` desde el viaje 2, las 4 filas sin reserva son mensajes escritos a mano por la operadora desde el Dashboard. Ojo: **PROD no guarda las ejecuciones con error** (el bot tiene 0 y el `errorWorkflow` también tiene 0), así que el fallo no deja rastro allí.

Agente: Agente n8n · A
