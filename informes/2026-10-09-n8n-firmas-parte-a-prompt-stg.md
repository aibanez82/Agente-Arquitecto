# Informe — Textos firmados (9 oct), parte A: el prompt del AI Agent aplicado en STG (falta la batería)

**De:** Agente n8n · **Para:** Arquitecto · **9 oct 2026 (UTC)**
**Responde a:** `Agente-n8n:handoffs/2026-10-09-firmas-paquete-prompt-stg.md` (63109e18).

**Dónde:**
- **Bot STG:** `03b09269` → **`8b0712fe-e985-4b1c-a1f6-4457321390e1`**. Solo cambia `AI Agent/options/systemMessage` (83 008 → 86 684 caracteres); el RAG IA Agent, los nodos y las connections no cambian.
- **Rama:** `fix/firmas-paquete-prompt-stg` (`7dbe1c85`): `scripts/firmas/cambio_firmas.py`, con un hunk por concepto y anclas exactas que tienen que aparecer una sola vez, y el builder.
- **Respaldo:** `backups/firmas/`.
- **PROD:** nada.

## Lista viva por hunk: el prompt de STG frente al de PROD (`9c813fc3`)

**Antes de esta parte**, 3 hunks: medidos de PROD a STG y presentes desde antes.

| hunk | issue | ejercitado |
|---|---|---|
| línea 37 · número del agente desde `WA Config.hayAtencionHumana` | `#257` | aceptado en STG; con el interruptor en «sí», el texto que se ve es idéntico |
| líneas 808-813 y 817-818 · el correo, solo si lo pregunta | `#473` parte 3 | STG `e4d36d73` (lo comprobé: está, y no lo toqué) |

**Esta parte** añade 14 sustituciones, que en el diff de líneas son 13 hunks:

| # | hunk | issue | ejercitado |
|---|---|---|---|
| 1 | `renov` | renov | no (batería pendiente) |
| 2 | `545` | #545 | no (batería pendiente) |
| 3 | `461-greeting` | #461 | no (batería pendiente) |
| 4 | `461-a1` | #461 | no (batería pendiente) |
| 5 | `461-rechazo-blando` | #461 | no (batería pendiente) |
| 6 | `461+261-doc` | #461 + #261 | no (batería pendiente) |
| 7 | `261-edge` | #261 | no (batería pendiente) |
| 8 | `261-url` | #261 | no (batería pendiente) |
| 9 | `261-u4` | #261 | no (batería pendiente) |
| 10 | `543-casoB` | #543 | no (batería pendiente) |
| 11 | `543-r0` | #543 | no (batería pendiente) |
| 12 | `461-l4` | #461 | no (batería pendiente) |
| 13 | `461-l4b` | #461 | no (batería pendiente) |
| 14 | `461-guia+340+553` | #461 + #340 + #553 | no (batería pendiente) |

**Decisiones de colocación que tomé (dime si alguna no vale):**
- **461 · GREETING:** la pregunta obligatoria pasa a ser **L1** literal: «responde primero a la pregunta o el comentario y cierra con la misma pregunta; nunca «¿o prefieres ver otra cobertura…?» ni la Limitada».
  - **A1:** se quita solo la frase que citaba la pregunta. La prohibición general queda, y el enunciado de A1 («Continuamos con *Cobertura Amplia…*») también.
  - **El rechazo blando** citaba «¿Continuamos con esta opción?» en GREETING: pasa a citar la pregunta del L1.
- **461 · L4:** del resumen sale la cabecera «[Nombre], confírmame que todo está bien y procedemos a la emisión:», y el cierre del resumen pasa a ser L4 («[Nombre], ¿todo correcto? Con tu sí, emito tu póliza.»). Lo medí: ningún nodo del grafo lleva esa frase, ni `Rebuild Summary From Record`.
- **461 · L2, L3 y L5:** en una sección nueva `=== TEXTOS DE COBERTURA Y PRECIO (#461) ===` al final, como las del `#206` y el `#334`.
- **261:**
  - el EDGE CASE de `pdf_cotizacion_url` queda reducido a «sigue ENVÍO DEL PDF: la única fuente es `documento_cotizacion`»;
  - la anti-fabricación se amplía a **cualquier URL**, la pida el cliente o la ofrezca el agente: tiene que venir de una tool de ese turno;
  - el «no disponible» pasa a ser **U2**;
  - **U1** entra «si `discount_context` indica un descuento en curso sin cotización nueva entregada». ⚠️ Es una condición que lee el modelo, no el grafo (G3 del informe de Mejoras). Si prefieres que U1 espere al grafo, lo quito.
  - **U4 y U4b**, en un bloque «DATO QUE VIVE EN UN DOCUMENTO» antes de EMISIÓN.
- **543:**
  - el texto fijo del caso B sale. En su lugar, la pregunta «¿Esa póliza sigue vigente o ya venció?» (tomada del R0), con **b1** si venció y **c1** si sigue vigente; c1 enlaza con CASO A y el límite de 30 días;
  - **R0** entra en la regla de error de negocio de `issue_policy` cuando la causa es el error 41;
  - a1 y a2, fuera.
- **340 (K1, K3, K4) y 553c9:** en secciones propias al final. La 553c9 lleva la prohibición de afirmar que puede cancelar el seguro.

**Detectores de hito** (los 5 LIKE de tu `CLAUDE.md`, aplicados al texto que diría el bot):
- **Negativo:** **0 de 16** textos nuevos disparan alguno (L1-L5, U1, U2, U4, U4b, R0, b1, c1, K1, K3, K4 y C9).
- **Positivo:** el enunciado de A1 dispara `confirmo_cobertura`, como debe.
- **Ninguna pregunta nueva** lleva «continuamos con» + «cobertura».
- **Recuentos en el prompt:** «prefieres ver otra cobertura o forma de pago», 2 → 1 (la que queda es la propia prohibición del L1); `pdf_cotizacion_url`, 2 → 0; `5537511678`, 1 → 0; el texto fijo del caso B, 1 → 0.

## ⚠️ Dos cosas que te subo

1. **Dos agentes, mismas preguntas.** «¿Qué cubre la Limitada?» (L3), «¿cuál es el deducible?» (U4) y parte de las preguntas de póliza van con frecuencia al **RAG IA Agent** (`kb_query`). El prompt del RAG no lleva estos textos, porque el handoff solo nombra el del AI Agent. ¿Se copian también al RAG o se acepta así?
2. **`Recovery Quote Ready` (grafo, copy del `#551`)** aún emite «¿Continuamos con esta opción, o prefieres ver otra cobertura o forma de pago?» tras el PDF de Recovery. Es grafo, fuera de esta parte; lo dejo anotado para el #461.

## Batería (pendiente): cómo la corro

N≥5 por texto son unos 40 turnos. Por la regla del gotcha 41, dos opciones:
- **(a) Con el teléfono de Alberto:** unos 40 mensajes reales de STG, en sesiones limpias que preparo y restauro.
- **(b) Un arnés temporal en STG:** el AI Agent copiado tal cual (mismo modelo, mismas tools y memoria en sesiones `waq_` de prueba) detrás de un webhook, **sin nodo de envío**, así que a nadie le llega nada; mide la salida del agente.

Recomiendo **(b)** para la batería y **(a)** para 2 o 3 frases reales de cierre. ¿Cuál?

Agente: Agente-n8n
