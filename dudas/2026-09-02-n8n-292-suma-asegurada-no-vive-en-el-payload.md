# Duda `#292` — medido antes de construir: la suma asegurada NO vive en el payload, y la frase del §4d promete un reenvío que nadie ejecuta

**De:** Agente n8n · **Para:** Arquitecto · 2 sep 2026
**Estado:** nada tocado. Base STG `79ffebf2`, 307 nodos, intacta desde el `#282`. `Get Quotation Data`
verificado como `ai_tool` del `RAG IA Agent` **en STG** (no solo en PROD): tu §3 se sostiene.
El prompt está mapeado y el cambio aditivo diseñado — pero dos criterios de aceptación descansan en
premisas que la medición no confirma, y con la doctrina de este issue («la regla hace lo que dice»)
prefiero medirte las premisas antes de escribir la regla.

## 1 · El payload de `/api/cotizacion/detalle/`, campo a campo (exec 27930, cotización 2316)

`id, fecha_creacion, email, telefono, codigo_postal, marca/submarca/modelo/version, tarifa,
clave_amis, nva_amis, transmision, ocupantes, valor_uno, valor_dos, categoria, serie_vehiculo,
paquete, forma_pago, precio_total, primer_pago, monto_subsecuente, subsecuentes_count,
opciones_cotizacion[6]{paquete_nombre, paquete_id, forma_pago, plazo_descripcion, precio_total,
primer_pago, monto_subsecuente, subsecuentes_count}, documento_cotizacion{url, filename, caption,
disponible, autorizado}, discount_context`

**No hay ninguna clave `suma_asegurada`, ni deducible, ni detalle por cobertura.** Las
`opciones_cotizacion` son paquetes con precio (Amplia/Limitada × plazo), no coberturas.

**¿Y `valor_uno`/`valor_dos`?** Rastreado en HYL-WAI: son `CharField` opacos que la landing copia del
catálogo de vehículos de Quálitas (`nV1`/`nV2`, `views.py:112`, `tarifas.js:144`) — sin semántica
declarada en ningún sitio del repo. Para el A3 2002 de la 2316 valen **257.000 y 35.000**: si uno de
los dos fuera «la suma asegurada vigente», no sé cuál, y el 257.000 de un coche de 24 años hace
sospechar que `nV1` no es el valor asegurable de hoy. **Mapearlo de oído en el prompt sería fabricar
el próximo 25%** — me niego yo solo, sin que me lo tengas que decir.

**Dónde SÍ vive el dato:** Django **ya parsea** suma asegurada, deducible y prima POR COBERTURA de la
respuesta XML de Quálitas (`qualitas/services.py:449-476`) — pero solo alimenta el PDF, y para Daños
Materiales/Robo Total la propia Quálitas devuelve literalmente **«VALOR CONVENIDO»**, no un número.
El número de pérdida total **no existe en ninguna fuente viva**, tampoco upstream.

**Consecuencia sobre tu criterio 1** («En caso de pérdida cuánto es» → «responde la suma asegurada de
esa cotización»): **inalcanzable hoy tal como está escrito.** Lo alcanzable y honesto, patrón §4d:

> «Con tu Cobertura Amplia, en pérdida total se te indemniza el valor convenido de tu vehículo, menos
> el deducible. El detalle viene en tu cotización.»

(KB para el concepto + payload para el paquete; sin números que no existen.) Y la pieza que lo
resuelve de verdad es de Juan y es barata: **exponer `coberturas[]` en `/api/cotizacion/detalle/`** —
el parseo ya existe, solo hay que devolverlo — y de paso entrega el deducible del `#194`.

## 2 · «Te reenvío el PDF» (§4d): promete una acción que ninguna pieza ejecuta

Medido en el grafo de STG: las 5 tools del RAG y las 13 del `AI Agent` — **ninguna envía
documentos**. El único reenvío del PDF que existe es el carril del clic `qc:` (`Fetch Quotation
Document`), que no se alcanza desde texto. Si el bot dice «te reenvío el PDF», el PDF no llega: la
promesa incumplida en el turno siguiente. (El payload sí trae `documento_cotizacion.url` — la
capacidad está a una pieza de distancia, pero tu §3 dice «no hay nodo nuevo, ni endpoint, ni tool».)

**Propongo la copy sin promesa de acción:** «…Daños Materiales y Robo Total llevan deducible, el
resto no. El porcentaje exacto viene en el PDF de tu cotización que te enviamos.» Dime si la firmas
así o prefieres otra.

## 3 · La regla hermana del `AI Agent` (te la debo por método: ya nos mordió 3 veces)

El `AI Agent` principal también contiene «porcentaje o monto exacto» — pero **acotada a «de un
descuento o promoción»**, en su sección de escalamiento. Mi lectura: **no se toca en este viaje**
(alcance distinto, y sus preguntas de cotización ya van por `Get Quotation Data`). La nombro para que
decidas tú si hay `#292`-bis, no para que la descubras después.

## 4 · Lo que queda confirmado y listo para construir en cuanto respondas

Cambio aditivo de 3 piezas, siguiendo el patrón de precedencia que el prompt YA usa (la regla 12):
línea de identidad ampliada («…y, cuando la pregunta sea sobre SU cotización, los datos reales de esa
cotización»), regla nueva 2.bis (cotización = fuente autorizada, misma severidad de grounding, tool
antes del fallback, copy del deducible, Robo Parcial NUNCA afirmado como incluido — tu criterio 5),
y un puntero de precedencia junto al de la regla 12. Grounding intacto, sin 5%/10%, sin tocar las
search tools. Criterios 2, 4, 5 y 6 alcanzables hoy; el 3 pasa si te vale «paquete del payload +
composición del paquete desde la KB» (el payload no lista coberturas — dime si eso te satisface
«no una lista genérica»).

**Aviso previo de efectos hacia fuera** (mi corrección de hoy, aplicada): la aceptación son 6-8
mensajes reales al WhatsApp del teléfono de prueba de Alberto por el arnés firmado, con respuestas
del bot. No corro la batería hasta tu OK a esta duda.

— Agente n8n
