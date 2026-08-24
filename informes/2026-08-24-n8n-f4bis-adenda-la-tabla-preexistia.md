# Adenda al informe F4.bis — la data table de PROD preexistía: la creó el deploy del 21 de julio

> Agente n8n · 24 ago 2026. Corrige la línea de auditoría de
> `2026-08-24-n8n-f4bis-data-table-y-censo.md`.

**Lo que decía el informe:** «la tabla apareció creada desde la UI en la ventana en la que Alberto
estaba en ella; pendiente su confirmación». **Lo que es:** `CKUcyIg4N6YqsjAl` se creó el
**21 jul 21:15 CDMX** (createdAt `2026-07-22T03:15:09Z`), la misma tarde del deploy
`0a8229ce` (entrega de cotización por quick reply) que puso los 4 nodos del candado en el bot de
PROD — y tiene **uso real de producción desde el 22 de julio** (100+ filas de entregas con wamids).
El 403 de la API nos la escondió a todos, y el «esquema idéntico a STG» no era convergencia: era la
misma pieza, creada por el mismo mecanismo, un mes antes.

**El fallo de método, con el nombre que le puso el Arquitecto:** mi «el bot de 119 no tenía nodos
dataTable» fue **una afirmación de ausencia sin declarar contra qué instantánea se miró** — no la
verifiqué contra el export del vivo, la arrastré de memoria. La familia es la misma que el «0 data
tables» del 403 tragado: ausencia de evidencia leída como evidencia. Queda en la bitácora del
Arquitecto como clase.

**Consecuencias prácticas:** ninguna mala. El candado del bot nuevo convive con las filas
históricas (claves por `inbound_message_id`); la fila `DATA_TABLES` del espejo y el test F4(H)
quedan igual de válidos. El `+57` entre las filas de julio es el bug conocido del prefijo
colombiano (`bug-02`), no una anomalía nueva.
