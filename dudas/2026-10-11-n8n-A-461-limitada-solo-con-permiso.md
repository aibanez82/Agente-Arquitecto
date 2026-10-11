# Duda de diseño · Agente n8n · A · #461: la Limitada solo con permiso (la parte del grafo)

**Orden:** `Agente-n8n:handoffs/2026-10-10-A-noche-486-461-475.md`, punto 2 (orden de Alberto: «si, lánzalo todo»).
Solo lectura y diseño. No he hecho ningún import, no he tocado el prompt ni PROD, y no he llamado al modelo.

**Fuentes:**
- bot PROD `BtOaZm7WlZT-24V7hqCnF` en `c31d2687`;
- Quotation Data Guard de PROD (`wYLcBiEuS3Jq4rZT`, `b06966a4`, el sub-workflow de `get_quotation_data`);
- BD de PROD solo con `SELECT`: `n8n_chat_histories`, `n8n_limitada_observation`, `whatsapp_sessions` y `qualitas_cotizacion`.

Todas las fechas van en UTC. El último mensaje de `n8n_chat_histories` es del **9 oct, 23:33**.

---

## 1. Lo que hay hoy en el grafo

| Pieza | Qué hace con la Limitada |
|---|---|
| `Get Quotation Data` (tool de los **dos** agentes, AI y RAG) → Quotation Data Guard | Devuelve `opciones_cotizacion` con **todos** los paquetes y sus precios en cada llamada. `Project Data Field` solo reproyecta `body.data` y no filtra nada. La tool solo recibe `cotizacion_id`. |
| `Discount Intent Classifier` / `Parse Discount Classification` (**sesión B**) | Detecta `COVERAGE_DOWNGRADE` («quiero la limitada», «RC», «la más básica») y lo traduce a `PRICE_OBJECTION` con `signal: coverage_downgrade` para el carril de descuentos. No abre ningún permiso. |
| `IF Limitada Observada?` → `Build Limitada Alerta` → `Persist Limitada Observation` | La fase 1: solo observa. Va en rama lateral tras `Restore Main Reply Payload`, en paralelo al `Outbound Leak Guard`, así que **corre después de decidir el envío**. Su condición es esta: `/\blimitada\b/i` en la salida **Y** que el `chatInput` **de ese turno** no contenga `/(limitad\|cobertura\|opcion\|paquete\|plan)/i`. |
| Prompt | La regla «LA LIMITADA NO SE OFRECE SOLA (#206)» y los textos firmados L2, L3 y L5 (viaje 6). Desde el viaje 6, la plantilla L1 («¿Te la dejo lista para contratar?») sustituye a la vieja «¿Continuamos con esta opción, o prefieres ver otra cobertura o forma de pago?». |

**De dónde saca el modelo el precio de la Limitada:** el `[CTX:]` no lo lleva (`Merge Session Data` no la menciona), así que la **única** fuente es `get_quotation_data`. `Resolve Session` lee los XML de la Limitada solo para el conjunto de cifras permitidas del `#500`.

---

## 2. Medición en PROD

### Método
- **Mensajes del bot:** filas `ai` de las sesiones que alguna vez mencionaron la Limitada o una invitación a cambiar. Excluyo las filas heredadas (`inherited`) y las que son llamadas a tools (`Calling …`).
- **Mensajes del cliente:** extraigo el texto entre `=== USER INPUT STARTS BELOW ===` y `=== USER INPUT ENDS ABOVE ===`, para no leer el `[CTX:]`. Las filas humanas heredadas **sí** cuentan como historial.

| Clase del mensaje del bot | Patrón (literal) |
|---|---|
| **tabla o precio** | `Limitada[^\n]{0,80}\$\s?[\d,]+` · `Limitada:?\*?\s*\n[^\n]{0,40}\$\s?[\d,]+` · `\$\s?[\d,]+[^\n.]{0,40}Limitada` |
| menciona (sin precio) | `(?<!i)\blimitada\b` |
| invitación genérica | `(otra\|otras) (cobertura\|coberturas\|opci[oó]n\|opciones)\|otros? planes?\|otro paquete` |

| Permiso del cliente | Regla (en este orden) |
|---|---|
| `paquete_3_web` | `qualitas_cotizacion.paquete = '3'`: eligió la Limitada en la web. |
| pidió explícitamente (en el turno / antes en la sesión) | `limitad\|b[aá]sic\|terceros\|\brc\b\|responsabilidad civil\|m[ií]nim\|da[ñn]os a terceros` |
| más barato, opciones u objeción (en el turno / antes) | `otr[oa]s? (tipo de )?(cobertura\|opci\|plan\|paquete)\|cambiar[^.\n]{0,30}cobertura\|qu[eé] (otras )?coberturas\|barat\|econ[oó]mic\|\bcar[oa]s?\b\|descuent\|m[aá]s bajo\|menos\|otras? opci\|otros? planes\|\bplanes\b\|opciones\|promoci\|presupuesto\|alcanza\|rebaj\|precio m[aá]s` |
| **sin permiso** | ninguna de las anteriores |

### Resultados

**Desde el 23 sep (día siguiente a la medición del issue):**
- 1.069 mensajes del bot en 197 sesiones;
- 57 de esos mensajes, en 35 sesiones, tocan la Limitada o invitan a cambiar.

| Clase | sin permiso | más barato u objeción (turno / antes) | pidió explícitamente (turno / antes) | paquete 3 en la web |
|---|---|---|---|---|
| **tabla o precio** | **6** | 1 / 3 | 4 / 0 | 3 |
| menciona | 4 | 1 / 1 | 7 / 3 | 4 |
| invitación genérica | 17 | 1 / 2 | 0 / 0 | 0 |

He revisado a mano los 10 «sin permiso» que no son invitación genérica:
- **7 son ofertas reales sin permiso, en 6 sesiones:** los 6 de tabla o precio y el 13245, que ofrece «Amplia o Limitada» sin precio. `waq_3740` y `waq_3744` son la misma conversación heredada.
- **3 son respuestas informativas**, no ofertas: 13297, 13846 y 14157, sobre cobertura en EUA o sobre «¿es la mayor?».

**Desde el viaje 6 (9 oct, 18:46):**
- **0 ofertas** de ninguna clase en 48 mensajes del bot y 10 sesiones;
- **0 invitaciones genéricas.** Las 17 de antes eran la plantilla vieja del greeting, que el viaje 6 sustituyó por L1.

Son unas 5 horas de tráfico. **No ejercitado:** no lo cuento como prueba de que el problema haya desaparecido.

**En todo el histórico disponible** (filas desde el 10 jul; las anteriores a la 5230 no tienen fecha): 373 mensajes del bot en 215 sesiones tocan la Limitada o invitan a cambiar. Por clase y permiso:

| Clase | Sin permiso | Con permiso |
|---|---|---|
| tabla o precio | 16 | 44 |
| invitación genérica | 99 | — |

El issue midió 67 de 81 antes del 22 sep con otra definición (tabla `*Cobertura Limitada:*` y solo el turno previo), así que las cifras no son comparables una a una.

**Dato que cambia el diseño:**
- **5 de las 7 ofertas reales son de cotizaciones con `paquete` nulo**, y desde el 23 sep **187 de 239 sesiones** (78 %) tienen la cotización con `paquete` nulo o vacío.
- En esos casos el modelo lee las dos opciones como igual de válidas. Ejemplo, 13235: «Tu cotización aún no tiene una cobertura seleccionada… tienes la Amplia ($8,649.88) y también la Limitada ($6,129.94)».
- La regla de Alberto (30 ago) dice «**siempre Amplia, salvo que lo pida el lead**», y el grafo no la aplica cuando `paquete` es nulo.

### Ejemplos

Sin PII: `session_id` truncado y sin nombres, teléfonos, VIN ni placas.

| id | sesión | El cliente escribe | El bot responde |
|---|---|---|---|
| 12881 | `waq_3709_…` | «Pago a meses» | La tabla de formas de pago de la Amplia **y** «*Limitada:* • Anual: $4,066.25 MXN…» |
| 13570 | `waq_3763_…` | «Ok» | «…Cobertura Amplia en pago anual queda en $16,923.23 MXN. También tienes la opción de Cobertura Limitada anual en $12,062.87 MXN si buscas algo más económico.» |
| 14337 | `waq_4343_…` | «Hola» | «Tengo disponible Cobertura Amplia… y la Cobertura Limitada desde $6,840.64 MXN anual.» |
| 13342 | `waq_3744_…` | «Y cuánto aumentaría si le agregas cobertura en Estados Unidos» | «¿Seguimos mientras tanto con tu cotización actual (Amplia $6,880.95 o Limitada $4,990.99 anual)?» La observación **no** lo registró: el `chatInput` contiene «cobertura». |
| 14772 (control) | `waq_4380_…` | «Para esta tiene a meses sin intereses ?» | Responde sobre la Limitada. El cliente la había pedido el turno anterior («En cobertura básica tiene ?»). Es la fila 30 de la observación, un **falso positivo**. |

### Qué vale la observación de la fase 1

He cruzado cada una de sus 30 filas con el mensaje del bot (misma sesión, ±3 min):

| Clasificación | Filas | Cuáles |
|---|---|---|
| Oferta real sin permiso | **7** | 7 (`waq_3638`, el caso del issue), 13, 18, 19, 20, 23 y 26 |
| Informativas | 3-4 | 1, 5, 25 y 29 |
| El cliente la había pedido | ≈ 9 | En el turno («Basico», «Me interesa una cotización básica», «Quiero solo el de Responsabilidad civil»: el regex del IF no ve `básic` ni `RC`) o antes en la sesión (8, 30) |
| `paquete` 3 en la web | 6 | 11, 14, 15, 16, 27 y 28 |
| Objeción de precio antes en la sesión | 4 | 17, 21, 22 y 24 |

Y **al menos un falso negativo** (13342).

**Conclusión:**
- Con su condición actual, la observación **no puede decidir la fase 2**: más de la mitad de sus filas son falsos positivos, porque mira solo el turno y no la sesión, el `paquete` ni `básica`/`RC`.
- Desde el arreglo del `#496` solo tiene 1 fila, y es un falso positivo.
- Lo útil que tiene es `reply_sha256`, que casa con `n8n_chat_histories`, y el `chat_input` completo.

---

## 3. Diseño

### (a) Dónde se detecta «el cliente la pidió»

**Propuesta:** un estado de **permiso por sesión y cotización** que se calcula en `Merge Session Data` y se persiste con un escritor lateral.

- **Por qué `Merge Session Data`:**
  - ya es el `Code` en serie que alimenta a los dos agentes y es ancestro de ambos (BFS sobre `c31d2687`);
  - ya tiene a mano lo necesario: `chatInput`, `prevAiTexto` (el último turno del bot, que usa el `#418`), `sessionData.capturedData` y el paquete de la cotización (`Resolve Session` ya lee `qc.paquete`).
- **Cálculo:**
  ```
  permitida = capturedData.limitada_permiso?.quotation_id === quotationId
            || paquete === '3'
            || pideLimitada(chatInput)
            || (respondeSiA_L3(chatInput, prevAiTexto))
  ```
  - `pideLimitada` va con patrones deterministas, los de la tabla de la sección 2 refinados con el corpus.
  - `respondeSiA_L3` cubre el «sí» del cliente justo después del texto firmado L3 («¿Quieres saber cuánto te costaría?»). Sin él, L3 invita a una pregunta que el grafo después no deja contestar.
- **Por qué hace falta guardarlo:** el permiso es **pegajoso**. Desde el 23 sep hay 8 tablas o precios con permiso dado por texto, y en 3 de ellas (13154, 13406 y 13772) el permiso venía de un turno anterior. El escritor lateral (`UPDATE whatsapp_sessions SET captured_data = jsonb_set(…, '{limitada_permiso}', {quotation_id, motivo, at})`) se ancla en `Merge Session Data` (ancestro) y va en **rama lateral, nunca en serie**.
- **Lo que no uso, y por qué:**
  - **Leer `COVERAGE_DOWNGRADE` de `Parse Discount Classification`.** Es ancestro en el grafo, pero es un nodo de la **sesión B**: depender de su salida ata mi pieza a su contrato. Además no he comprobado que corra en **todos** los caminos que llegan al agente (botones, carriles fijos). Un `$()` sobre un nodo que no ha corrido lanza un error. Si el Arquitecto prefiere reutilizarlo, la forma limpia es que B publique la señal en un campo que el escritor lea, y no que yo lea su nodo.
  - **Leer lo que devolvió `get_quotation_data` en turnos anteriores.** Es el canal `ai_tool` y `$()` no lo ve.

**Lo que queda abierto, y es de B:**
- L2 permite la Limitada ante «más barato» **cuando ya hubo descuento o no hay descuento disponible**.
- Esa condición es estado del carril de descuentos.
- **Pregunta:** ¿el permiso por objeción de precio lo abre B (publicando «descuento agotado o no disponible») o queda fuera del primer corte, que solo cubriría la petición explícita, la respuesta a L3 y el `paquete` 3?

### (b) Qué hace el grafo si el modelo la ofrece sin permiso

| Opción | Cómo | A favor | En contra |
|---|---|---|---|
| **1. Cerrar el dato** (la propuesta del issue) | `Get Quotation Data` pasa `limitada_permitida` desde `Merge Session Data` como segundo input. `Project Data Field` del Quotation Data Guard quita de `opciones_cotizacion` los paquetes Limitada si es `false`. | Sin precio no hay tabla ni cifra. Cubre los **dos** agentes (AI y RAG llaman a la misma tool). Ataca las 6 ofertas reales con precio: todas lo sacaron de la tool. La séptima, 13245, nombra la Limitada sin precio. Es independiente de cómo redacte el modelo. | Sigue pudiendo nombrarla sin precio (13245: «¿Amplia o Limitada?»). Toca un workflow aparte (Quotation Data Guard), que es un import más. Hay que comprobar que `Save Quotation Selection` y `Cambiar Cotizacion` no dependen de ver la Limitada en el payload cuando el permiso está abierto. |
| 2. Recortar en el `Outbound Leak Guard` | Quitar el bloque de la Limitada de la salida. | Va en la ruta de envío y es determinista. | La prosa en línea no se recorta limpia (la propia alerta de la fase 1 lo clasifica como «fail-open con alarma»). Riesgo de dejar un mensaje roto o una cifra suelta. |
| 3. Sustituir el mensaje por L1 | Si hay oferta sin permiso, se manda el texto firmado L1. | Determinista y firmado. | Se pierde la respuesta a lo que preguntó el cliente: en 12881 preguntaba por el pago a meses, y L1 no se lo contesta. |
| 4. Reintento del agente con una nota | Segunda pasada. | — | Sigue decidiendo el modelo, con más latencia y coste. Es lo que el issue descarta. |

**Recomiendo la 1 como mecanismo único.** Con el dato cerrado, lo que queda es una mención sin precio, que es poco daño y no se puede recortar sin riesgo. Ahí no pongo control nuevo hasta que el corpus lo muestre (criterio de admisión, `#179`).

**Defecto concreto que atrapa la 1:** las 6 tablas o precios sin permiso desde el 23 sep (12881, 13235, 13342, 13334, 13570 y 14337), todas con el precio sacado de `opciones_cotizacion`.

**Efecto lateral buscado:** con `paquete` nulo, el modelo deja de ver dos opciones iguales y ve solo la Amplia. Así se aplica la regla «siempre Amplia» en el 78 % de cotizaciones que llegan sin paquete.

**Invitación genérica:** no propongo control del grafo. La fuente era la plantilla, y el viaje 6 la quitó (0 en 48 mensajes desde entonces, pero sin ejercitar). Si reaparece en el corpus, entra con su caso.

### (c) Qué datos de la observación de la fase 1 sirven

- **Para decidir el diseño: ninguno por volumen.** Solo hay 1 fila posterior al `#496`, y es un falso positivo. Esta medición sale de `n8n_chat_histories`.
- **Para la aceptación:** sirven `chat_input` y `reply_sha256`, porque permiten casar cada alerta con el texto exacto enviado.
- **Recomendación:** cuando exista el permiso, la condición de `IF Limitada Observada?` debería leer `limitadaPermitida` de `Merge Session Data` en vez del regex del turno. Es una **modificación** de un control que ya existe, no instrumentación nueva. Hoy produce más falsos positivos que casos. Si no se cambia, propongo retirarlo cuando la opción 1 viaje: la condición actual da rojo sin defecto detrás (filas 8, 9, 10, 11, 14-17, 21, 22, 24, 27, 28 y 30), así que cumple la regla de salida del `#179`.

### Lo que roza a la sesión B

- **Ningún nodo de B en el diseño.**
  - Toca: `Merge Session Data`, un escritor lateral nuevo, `Get Quotation Data` (solo `workflowInputs`), `Project Data Field` del Quotation Data Guard e `IF Limitada Observada?`.
  - Leo de B: nada.
- **Hay dos contactos:**
  - el permiso por objeción de precio depende del estado de descuentos (sección 3a), y
  - B ya clasifica `COVERAGE_DOWNGRADE`, así que **habría dos detectores de «pidió la Limitada»** (el suyo, de modelo, para el carril de descuentos; el mío, determinista, para el permiso). Si divergen, el cliente podría pedir la Limitada, recibir el carril de descuentos de B y que el agente no tenga el precio. Para la aceptación propongo una tabla de frases donde los dos coincidan.

---

## 4. Preguntas para el Arquitecto

1. ¿Adoptas **cerrar el dato** (opción 1) como único mecanismo del grafo, sin recorte en el Leak Guard?
2. ¿Qué abre el permiso en el primer corte? Propongo `paquete = '3'`, la petición explícita y la respuesta afirmativa a L3. ¿La objeción de precio tras el descuento (L2) espera a que B publique la señal?
3. ¿El permiso es **por sesión y cotización** (si cambia de cotización se cierra) o por sesión?
4. ¿Cambio la condición de la observación para que lea el permiso, o la retiro cuando viaje la opción 1?
5. **Aceptación propuesta** (la del issue, más esto):
   - fail-first con las 6 conversaciones reales de la sección 2, reproducidas en STG;
   - los negativos del issue con tolerancia cero;
   - el «sí» a L3;
   - una cotización con `paquete` nulo que ya no muestra la Limitada;
   - la regresión: con el permiso abierto, la selección y la emisión de la Limitada siguen igual.

— Agente n8n · A
