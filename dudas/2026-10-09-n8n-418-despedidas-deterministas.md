# Duda n8n · #418: despedidas con respuesta fija del grafo (diseño antes de construir)

**Handoff:** `Agente-n8n:handoffs/2026-10-09-418-despedidas-deterministas-stg.md` (`22261499`). Base: bot STG `6be69202`. **No he
construido nada** salvo el prototipo del detector (`scripts/418/despedida.js`, rama `fix/firmas-paquete-prompt-stg`).

## Propuesta

**1. Quién decide: un detector determinista, sin modelo y sin categoría nueva en el Intent Router.**
`clasificaDespedida(texto, ultimoBot)` devuelve `definitiva`, `pausa`, `despedida` o nada:
- **nada** si es el primer mensaje (no hay turno anterior del bot, G2), si lleva «?/¿», cifras de 3 o más dígitos o correo
  (trae un dato), si acaba cortado («Gracias y», «…pero»), si empieza por «no» (es el **rechazo blando** del #461, que ya tiene su
  flujo en el prompt) o si quiere seguir («sí, gracias, seguimos», «gracias, quiero la amplia»);
- **acuse → nada** si el último turno del bot es una espera («en cuanto esté lista te la mando», «ahorita te cuento»…). El turno
  sigue como hoy;
- **definitiva:** «ya conseguí / contraté / compré…»;
- **pausa:** «lo checo / lo pienso / lo reviso…», «déjame ver», «estamos comparando»…;
- **despedida:** si, quitando el vocabulario de cierre («gracias», «agradezco la atención», «más adelante me pongo en contacto»,
  «en cuanto me decida», «me espero», «era una cotización», «por lo pronto»…), no queda ninguna palabra con contenido.

**Medido:**
- Con las frases de la tabla del informe, más 6 negativos míos: **19/19**.
- Sobre las **749** frases `human` de STG con su turno previo: marca **11**, todas revisadas a mano:
  - 3 pausas (todas correctas);
  - 7 despedidas plausibles: tras la cotización, tras el PDF, tras la póliza emitida (daría D4) y tras una explicación;
  - **1 dudosa (5366):** un «gracias» justo cuando el bot acababa de pedir el domicilio en `data_capture` (pregunta 2).
- **El falso positivo de PROD lo mides tú** con `despedida.js`.

**2. Dónde:** un carril gemelo del #552 / `limite30_fijo` en la misma cadena de IFs (`IF Despedida Fija?`), con fence, fila
`human`, fila `ai` `despedida_fija` con su `dispatch_id` y marcas de fallo. La decisión la calcula `Merge Session Data`, como
`limite30Fijo`. Ya tiene lo necesario: `prevAiTexto`, la fase, la póliza en `sessionData.policyData`, `grupo1.nombre` y
`captured_data`.

**3. Qué texto** (los firmados, literales; sin nombre se quita «, [NOMBRE]»):
- `definitiva` → **D5**;
- `pausa` → **D2**, el gancho literal de `MANEJO DE PAUSA`. La primera vez lo escribe el carril y deja
  `captured_data.gancho_pausa_usado = true` (escritor lateral); la segunda pausa recibe **D1**;
- `despedida`:
  - **D4** si la póliza está emitida (`numero_poliza`, o fase `payment_pending` / `completed`);
  - **D3** si el último turno del bot fue una **derivación** (lleva el enlace `api.whatsapp.com/send` o «agente especializado»);
  - **D1** en el resto.

**4. Carril de descuento:** el veto del #494 en `Parse Discount Classification` gana una clase más, «despedida/pausa/definitiva»
según el mismo detector, con el mensaje anterior del bot que ya recibe el clasificador. Se convierte en `no_match`, y el turno
llega al carril de despedidas en vez de abrir un descuento (filas 14455 y 12723 de PROD).

**5. Tras D5, ningún recordatorio:** depende de Django (#577, abierto y de Juan; #567, abierto). **Lo anoto y no lo construyo.**

## Lo que necesito que decidas

1. **¿Detector determinista sin categoría en el router?** Los tres intentos anteriores fueron por prompt; el router es otro modelo,
   con su propio margen de error.
2. **La 5366:** ¿un «gracias» suelto cuando el último turno del bot **pidió un dato** en `data_capture` es despedida (D1) o lo dejo
   al modelo? Propongo dejarlo al modelo, para no cerrar a mitad de la captura de datos con «tu cotización queda guardada».
3. **«No, gracias»:** ¿se queda en el flujo de rechazo blando del prompt (#461), como propongo?
4. **D3 por «consulta ajena»:** solo sé detectar la derivación (el enlace). ¿Basta con eso, y el resto va a D1?
5. **D5:** ¿el carril además **cierra la sesión** (como la tool `Mark Session Closed`)? ¿O eso espera a la pausa de recordatorios de
   Juan?

## Aceptación

La del handoff: N=10 por texto con las frases reales del informe (texto literal 10/10) y 0 respuestas fijas en los negativos
(pregunta, dato, primer mensaje, acuse, cortado y rechazo blando). Más la regresión de L1, CASO A y el carril del #552, y el
segundo D2 → D1.

Agente: Agente-n8n
