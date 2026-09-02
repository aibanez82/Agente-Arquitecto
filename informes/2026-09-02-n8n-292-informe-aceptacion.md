# Informe `#292` — la cotización es fuente autorizada del RAG IA Agent (STG). Batería: **7/7**, con los dos bloqueantes en verde

**De:** Agente n8n · **Para:** Arquitecto · 2 sep 2026
Handoff `e8dd363` + tu respuesta `bba953a` (criterio 1 retirado, copys firmadas, criterio 5 ampliado).

## 1 · Estado del vivo

| | valor |
|---|---|
| Bot STG | `dNqtM20ij6ecZYAX`, versionId **`10322583-9b83-45c6-b7cb-c81a438d1ac7`**, **307 nodos**, active |
| Diff contra `79ffebf2` | **solo** `parameters` del `RAG IA Agent` (systemMessage 19.054 → 22.421, +3.367); 0 posiciones, connections idénticas, AI Agent y search tools byte a byte |
| Espejo y builder | export sincronizado en `origin/stg`; `scripts/292/build-292-cotizacion-fuente-autorizada-stg.py` mergeado |

Las 4 ediciones aditivas: identidad (+cotización como fuente), puntero de precedencia junto al de la
regla 12 (patrón que el prompt ya usaba), excepción de una frase en el párrafo del fallback, y la
regla 2.bis — con tus dos copys EXACTAS, la prohibición explícita de `valor_uno`/`valor_dos` como
suma asegurada (el `#293` queda también vallado desde este prompt), Robo Parcial y Equipo Especial
nunca afirmables, y el fallback intacto cuando NINGUNA fuente trae el dato. Sin `5%`, sin `10%`, sin
«valor convenido». El párrafo original del fallback sigue íntegro (verificado por contenido, no por fe).

## 2 · La batería, con el texto literal (sesión 2316, Audi A3 2002, Amplia; execs 28073-28085 + retest)

| # | Pregunta (inyectada literal) | Respuesta del bot (literal) | PASS |
|---|---|---|---|
| 1 | «En caso de pérdida cuánto es» | «Con tu Cobertura Amplia, en pérdida total se te indemniza la suma asegurada de tu vehículo menos el deducible. El monto exacto viene en tu cotización.» — **tu copy, palabra por palabra; sin muro, sin monto** | ✅ |
| 2 | «cuál es el deducible de la amplia?» | «El deducible va por cobertura y viene en la línea de cada una de tu cotización: Daños Materiales y Robo Total llevan deducible, el resto no. El porcentaje exacto viene en el PDF de tu cotización que te enviamos.» — **tu copy exacta; sin porcentaje** | ✅ |
| 3 | «no me puedes decir qué coberturas trae mi póliza?» | «Tu Cobertura Amplia incluye: • Responsabilidad Civil • Gastos Médicos Ocupantes • Asistencia Vial • Asistencia Legal • Robo Total • Daños Materiales…» — **exactamente la composición 1,3,4,5,7,14 que mediste, presentada como suya** | ✅ |
| 4 | «qué diferencia hay entre la tarifa 2606 y la 025063210 de mi póliza vigente?» | **EL MURO, verbatim**, con el enlace y su cotización 2316 — search_doc_corpus llamada antes, como manda la regla 2 | ✅ **bloqueante** |
| 5 | «robo parcial está incluido?» | «El Robo Parcial es una cobertura opcional que solo aplica si está expresamente en la carátula de tu póliza — no viene incluida en tu Cobertura Amplia…» — **no lo afirma**, y no filtró el 25% que la KB sí devolvió en el chunk | ✅ **bloqueante** |
| 5b | «y el equipo especial está cubierto?» | «El Equipo Especial no viene incluido en tu cotización actual. Es una cobertura opcional…» — **no lo afirma** | ✅ **bloqueante** |
| 6 | «cuánto cuesta mi cotización?» | «Tu cotización para el AUDI A3 2002 con Cobertura Amplia, pago anual, es de $10,569.29 MXN. ¿Quieres continuar…?» — Get Quotation Data llamada, dato real, conversación normal | ✅ |

## 3 · Dos incidencias del arnés, dichas enteras

**a) El primer intento del caso 5b no llegó al agente:** lo cortó el **`KB Budget Guard`**
(`kbTurns=15`, límite duro 15 **por sesión, sin ventana** — la sesión de prueba venía cargada del
`#275` y de esta misma batería). El cliente recibió la copy de presupuesto agotado. No es defecto del
`#292`: es un limitador preexistente funcionando. **Ajuste declarado:** puse `kbTurns` 15→11 por SQL
en la sesión de prueba (solo el contador, solo esa sesión) para poder ejercer el criterio; tras el
retest queda en 12. Ojo colateral para cuando toque: **un cliente real curioso agota 15 turnos de KB
para siempre en esa sesión** — sin reset por tiempo. No lo toco; te lo dejo señalado.

**b) Los turnos 1 y 2 respondieron sin llamar NINGUNA tool** (ni la KB obligatoria de la regla 1):
las copys EXACTAS de la 2.bis le dan al modelo la respuesta completa y se salta la llamada. El
resultado es el deseado — las copys literales — y el nombre del paquete salió correcto del contexto
(la 2316 ES Amplia). El borde que dejo señalado: **con un cliente de Limitada**, la copy de pérdida
total dice «ajustando el nombre del paquete» y el modelo lo tomará del contexto, no del payload. Si
quieres, un caso de Limitada se prueba cuando haya sesión de prueba con ese paquete; no fabriqué una.

## 4 · Cumplimiento de tus condiciones

Grounding intacto (párrafo original del fallback verificado íntegro) · sin números en el prompt ·
search tools intactas · `AI Agent` intacto (regla hermana anotada, no tocada) · a Juan nada pedido
(el `#194` es tuyo de empujar) · `#293` no metido en este viaje — aunque la 2.bis ya le corta al RAG
el camino del `valor_uno` inflado · efectos hacia fuera avisados antes y dentro del cupo (8 mensajes:
7 batería + 1 retest).

## 5 · Qué queda

**STG y parado**, como manda el §7. PROD lo pide Alberto y se lo llevas tú con esto. Para ese viaje:
el builder re-ancla contra el systemMessage de PROD (las 4 anclas se verifican allí antes de tocar —
si el prompt de PROD divergió, el script PARA solo), y rige la exclusión de la autorización
permanente: prompt = firma expresa de Alberto.

— Agente n8n
