# Duda · Agente n8n · A · mensaje de emisión determinista (diseño, sin código)

**Contexto:** respuesta `db81d1f` a la duda de detectores con Sonnet 5.5. El texto lo firma Alberto, conserva «emitida exitosamente» y va
a PROD con su orden. Va **después** del `#591` (STG `e8f861f1`), del que depende.

## Lo que condiciona el diseño (medido)
1. **El grafo no puede leer la salida de `Issue Policy`.** `$()` no ve el canal `ai_tool` (gotcha `#261a`: además, leer el agente con
   `intermediateSteps` colgó el runner 300 s). La respuesta de la tool (número, monto, link) **no está al alcance** del grafo.
2. **`policy_data` de la sesión no sirve de fuente:** lo escribe el modelo con `save_policy_data` (`$fromAI`), que es justo lo que no
   queremos depender.
3. **Lo que sí es de fiar:** `qualitas_polizaemitida`, que escribe Django al emitir. Por cotización tiene `numero_poliza`, `precio_total`,
   `primer_pago`, `monto_subsecuente`, `subsecuentes_count`, `paquete`, `forma_pago`, `fecha_limite_pago` y `fecha_emision`. **No** tiene
   el link `/pagar/…`: ese lo da Django por la API que ya consulta `Ensure Payment Link` (STG `/pagar/<uuid>/`).
4. **Con el `#591`, el grafo ya sabe** si el mensaje del modelo afirma una emisión (`afirmaEmision`) y si sus números existen para la
   cotización (`Validate Emision Against DB`).

## Propuesta
- **Dónde:** tras `Apply Guardrail Result`, cuando la narración **se valida** (`exists_real = true`) **y** afirma una emisión. Es el mismo
  patrón que `Rebuild Summary From Record` con el resumen: el texto del modelo se sustituye por el del grafo. Si no se valida, sale el
  respaldo técnico de hoy, sin cambios.
- **De dónde sale cada dato:**
  - nombre: `grupo1.nombre`;
  - vehículo: el `vehiculo` de Merge Session Data;
  - cobertura (`paquete`), póliza (`numero_poliza`) y montos (`precio_total`, `primer_pago`): la fila de `qualitas_polizaemitida` de la
    cotización, la más reciente por `fecha_emision` (o la del número afirmado, si el mensaje trae uno);
  - link: una llamada del grafo a la **misma** API de link de pago que usa `Ensure Payment Link`, con la misma credencial y el mismo
    criterio fail-closed.
- **El texto (lo firma Alberto):** la plantilla que ya está en el prompt («Ejemplo de mensaje final»), literal. Conserva «emitida
  exitosamente», «*Resumen de tu póliza:*», «Póliza:» y «Monto total:».
- **Variantes que hacen falta, y que Alberto tendría que firmar:**
  - (a) **pago fraccionado:** «Monto total» más una línea «Primer pago: $X», o solo el primer pago. La plantilla de hoy no lo distingue;
  - (b) **sin link disponible** (la API no lo da): el prompt dice que `link_pago` «con frecuencia es null aunque la emisión sí haya sido
    exitosa». Propongo la frase de la pasarela caída que ya está firmada (viaje 7), o una nueva.
- **Lo que no cambia:**
  - el modelo sigue llamando a `issue_policy` y a `save_policy_data`, como hoy;
  - solo se sustituye el **texto** al cliente;
  - el detector `poliza_emitida_wa` queda garantizado sea cual sea el modelo.

## Aceptación (cuando se construya)
- En el arnés, con la emisión simulada (como en la medición de 5.5): N=10 por variante (contado, fraccionado y sin link), con **«emitida
  exitosamente» 10/10** y las cifras iguales a las de `qualitas_polizaemitida`, con Sonnet 5 y con 5.5.
- Control: con el nodo actual, una narración sin «exitosamente» sale tal cual.
- Regresión del `#591` y del respaldo técnico.

## Preguntas
1. ¿El link lo pide el grafo a la API (propuesta) o se omite y se manda aparte? Pedirlo es una llamada más a Django en el turno de la
   emisión.
2. Variantes (a) y (b): ¿las preparo para la bandeja de firma de Alberto?
3. ¿Va solo cuando el modelo **narra** la emisión (propuesta), o también cuando `issue_policy` emitió y el modelo no lo narró? Esto último
   necesitaría saber que hubo emisión en el turno, lo que pide leer la BD después del agente aunque el texto no la mencione.

Agente: Agente n8n · A
