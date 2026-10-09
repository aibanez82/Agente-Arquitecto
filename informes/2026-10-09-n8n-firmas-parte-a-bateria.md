# Informe — Firmas, parte A: RAG, Recovery y batería N=5 en el arnés sin envíos

**De:** Agente n8n · **Para:** Arquitecto · **9 oct 2026 (UTC)**
**Responde a:** tus respuestas (1)-(3) a `informes/2026-10-09-n8n-firmas-parte-a-prompt-stg.md`.

**Bot STG**, PUT a PUT y un hunk por PUT (respaldo de cada uno en `backups/firmas/`):

| versión | hunk |
|---|---|
| `8b0712fe` | prompt del AI Agent, parte A |
| `e189ab0f` | **RAG:** L3, U4 y U4b en una sección `=== TEXTOS FIRMADOS PARA PREGUNTAS DE COBERTURA (#461, #261) ===` |
| `8d3e29e0` | **`Recovery Quote Ready`:** la pregunta prohibida pasa a ser L1 («¿Te la dejo lista para contratar?»). Hunk de grafo |
| **`b89efa75`** | **RAG + L2:** la batería enseñó que «¿tienes algo más barato?» va al RAG |

Rama `fix/firmas-paquete-prompt-stg`.

## Lista viva por hunk (el prompt frente a PROD `9c813fc3`)

| hunk | issue | ejercitado (batería N=5) |
|---|---|---|
| línea 37, número del agente | `#257` | aceptado en STG |
| bloque del correo | `#473` p3 | STG `e4d36d73` |
| `renov` | renov | **no ejercitado** (no hubo caso de renovación en la batería) |
| `545` plantilla RFC | `#545` | **RFC 1/5** (ver abajo) |
| `461-greeting` / `461-a1` / `461-rechazo-blando` | `#461` | **L1 5/5** (AI Agent) |
| `461+261-doc` (U2; U1 condicionado) | `#461 #261` | **U2 5/5** (AI); U1 **no ejercitado** |
| `261-edge` / `261-url` | `#261` | U2 sin URL inventada 5/5 |
| `261-u4` (AI) + U4/U4b (RAG) | `#261` | **U4 5/5** (las 5 en el **RAG**, todas con el % de `coberturas_detalle` y sin URL); U4b no ejercitado |
| `543-casoB` / `543-r0` | `#543` | **no ejercitado:** R0 necesita un error 41 real de Quálitas |
| `461-l4` / `461-l4b` (cierre del resumen) | `#461` | no medido aparte |
| `461` guía (AI) + L3/L2 (RAG) | `#461` | **L3 5/5** (las 5 en el RAG, sin precio) · **L2 3/5** (RAG) |
| `340` K1/K3/K4 | `#340` | **no ejercitado** |
| `553` C9 | `#553` | **C9 5/5** (AI: «revisa con tu financiera», sin afirmar que puede cancelar) |
| `Recovery Quote Ready` | `#461` | no ejercitado (necesita el flujo Recovery) |

## Batería

**Arnés** (`scripts/firmas/arnes-firmas-stg.py`): una copia temporal del bot STG vivo.
- **Sin envíos:** los 20 nodos de envío con credencial de WhatsApp y el de Telegram pasan a ser Code con un id falso. **No salió nada a Meta ni a Telegram.**
- **Trigger:** un webhook, con un Code que da la misma forma de salida.
- **Descuentos apagados,** para que el Poller real no envíe nada.
- **Sesiones** sembradas sobre la cotización 2982 (Captiva 2022, sin paquete elegido) y borradas por id exacto.
- **El workflow temporal** se borró (GET 404).
- **Resultados** en `scripts/firmas/bateria-n5-resultados.json`.

| caso | resultado | agente | lo que pasa |
|---|---|---|---|
| L1 «hola, buenas tardes» | **5/5** | AI | «Ya tengo tu cotización para tu *CHEVROLET CAPTIVA 2022*: Cobertura Amplia, pago anual de *$11,173.35 MXN*. ¿Te la dejo lista para contratar?», sin «otra cobertura» ni Limitada |
| L2 «¿tienes algo más barato?» | **3/5** | **RAG** | El contenido es correcto en las 5 (Limitada con precio y la diferencia). Las 2 que fallan solo cambian el cierre: «¿Te interesa?» en vez de «¿Cuál prefieres?» |
| L3 «¿qué cubre la limitada?» | **5/5** | **RAG** | coberturas, sin precio |
| U2 «no me llegó el PDF» | **5/5** | AI | ninguna URL inventada |
| U4 «¿cuál es el deducible?» | **5/5** | **RAG** | el % de `coberturas_detalle`, sin URL |
| C9 «me lo puso la agencia» | **5/5** | AI | el texto firmado; no dice que puede cancelar |
| **RFC** «Juan Prado Gómez», 3 turnos (serie → factura → homoclave) | **1/5** | AI | ⚠️ ver abajo |

**El RFC es un hallazgo real, no un fallo del arnés.**
- **Con la plantilla nueva en el prompt, el modelo sigue calculando mal la base:** PRGJ en 2 pasadas, PGJU en 1 y la correcta PAGJ921203 en 1. Otra pasada no llegó al RFC, por ruido de la sesión sembrada.
- **La emisión no se ve afectada:** usa la base que calcula el grafo (`Calcular Base RFC`, `#545`, ya en PROD).
- **Pero el bot le enseña al cliente un RFC equivocado en el resumen y le pide confirmarlo.**
- **Propuesta (grafo, parte B o un issue aparte):** que la base que calcula el grafo llegue al contexto del turno, y que el prompt diga «usa la base que te da el sistema; no la calcules tú».

**No ejercitados**, y lo digo como tales:
- R0, b1 y c1 (necesitan un error 41 real o un flujo de renovación);
- K1, K3 y K4 (no entraron en la batería);
- U1 y U4b;
- renov;
- L4 (cierre del resumen);
- `Recovery Quote Ready`.

**Detectores:** sin cambios respecto al informe anterior (0/16 + A1 positivo). Los textos que van al RAG son los mismos.

**Pendiente:**
- tus 2 o 3 frases reales para el teléfono de Alberto;
- decidir si el L2 3/5 (solo el cierre) vale;
- el camino del RFC.

Agente: Agente-n8n
