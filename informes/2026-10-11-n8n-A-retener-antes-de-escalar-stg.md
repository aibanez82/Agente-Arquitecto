# Informe · Agente n8n · A · Retener antes de pasar a una persona: EN STG (`c0f117b0`)

**Orden:** `Agente-n8n:handoffs/2026-10-10-A-retener-antes-de-escalar.md` (`a677b9e2`), firmado por Alberto.
**Estado:** bot STG `dNqtM20ij6ecZYAX` pasa de `5adf0e57` a **`c0f117b0`**. **PROD:** nada; según tu mensaje, no se prepara hasta que Alberto decida lo del siniestro y la queja (§4).

Scripts en `scripts/persona/`, rama `fix/firmas-paquete-prompt-stg` de Agente-n8n (`e362e261`).

## 1. Cómo quedó, con el patrón de «Llamada Fija»

- **Clasificador determinista** (`persona.js`, copia literal en `Merge Session Data`). Distingue tres casos:
  - **petición expresa de una persona:** «hablar con una persona/agente/asesor», «pásame con alguien», «quiero una persona», «persona real»;
  - **excepción:** la misma petición con siniestro/accidente, queja/reclamación, pago/cobro, «mi póliza» o Uber/taxi/flotilla, o **con la póliza ya emitida**. El grafo la deja pasar y la escala el modelo;
  - **ninguno de los dos.** La petición de **llamada** no entra aquí: va a los A, B y C de la llamada, y la llamada tiene prioridad en el mismo turno.
- **Qué hace en cada momento** (contador `captured_data.persona.{r,e}`):
  - **R**, la retención, una vez por conversación. Con descuento comunicado (familia `d156` `sent`) o sin él, con `$[PRECIO_VIGENTE]` = prima anual vigente del grafo (la misma fuente que la B de la llamada);
  - **E** («Sin problema. Aquí tienes el contacto… [enlace]») si insiste: otra petición, o un «sí» corto justo después de la retención. El enlace sale de `WA Config.numeroAtencionHumana` (`#257`), con el mismo formato que el mensaje de escalamiento;
  - **después de E**, la siguiente petición la escala el modelo con su mensaje de siempre. Así no se manda dos veces el mismo texto (regla 3), y la tercera petición recibe igualmente el enlace.
- **Casos en que el grafo no interviene y responde el modelo, como hoy:**
  - `hayAtencionHumana = false` (manda el interruptor);
  - sin precio vigente (nunca una cifra inventada);
  - sin número en `WA Config`.
- **Carril «Persona Fija»:** 13 nodos clonados del de la llamada, con fence `dper.reply`, fila human y fila ai `persona_fija` con `dispatch_id`. Lleva un escritor lateral, `Persist Contador Persona`, que solo escribe si el texto salió. Va detrás de `IF Llamada Fija?` y antes de `IF Recovery Resumen?`.

## 2. Diff del grafo

| nodo | cambio |
|---|---|
| `Merge Session Data` | + `persona.js` (literal) + cálculo de `personaFija` (lee `Session Resolution` y `WA Config`, ambos ancestros: medido por BFS) |
| `AI Agent`, `RAG IA Agent` | hunk del prompt (§3) |
| 14 nodos nuevos | `IF Persona Fija?`, `Persona Fija Copy`, `Claim Persona Fija Outbound`, `IF Send Persona Fija?`, `Persist Human Row (Persona Fija)`, `Send Persona Fija Reply`, `Settle Persona Fija Sent`, `Settle Persona Fija Uncertain`, `Build Persona Fija AI Row`, `Insert Persona Fija Turn History`, `Mark Persona Fija AI Suppressed`, `Mark Persona Fija Persist Failed`, `Persona Fija Fence Denied`, `Persist Contador Persona` |
| connections | `IF Llamada Fija?`[false] → `IF Persona Fija?` → [true] `Persona Fija Copy` / [false] `IF Recovery Resumen?` (el destino que tenía antes) |

**Comprobación del import:**
- **Respaldo:** `backups/persona/bot-stg-5adf0e57-20261011T031407Z.json`.
- **Hojas y connections** iguales al candidato; el bot queda activo.
- **Ningún nodo de la sesión B** en el diff.

## 3. Delta del prompt, por hunk (un hunk por agente, en la lista de escalamiento)

**AI Agent** (las líneas nuevas van marcadas con `+`):
```
-- Usuario quiere hablar con una persona, agente o humano
+- Usuario quiere hablar con una persona, agente o humano. La PRIMERA petición la atiende el sistema con su propio texto de
+  retención (no lo repitas ni lo parafrasees); si la petición te llega a ti, escala.
   (Pedir una LLAMADA … SÍ lo es.)                       ← la nota de la llamada, sin tocar
+- Siniestro o accidente (choque, robo, necesita grúa o ajustador), o una queja o reclamación: escala directo.
```

**RAG IA Agent:** el mismo hunk, con la sangría de su lista (`   - Quiere hablar con una persona…`).

Uber, taxi y flotilla ya estaban en la lista y no cambian. Lo de pagos y póliza emitida lo resuelve el grafo: lo trata como excepción, deja que escale el modelo y no añade texto al prompt.

## 4. Aceptación (arnés con copias del vivo, sin envíos, cotización 2982 sin `d156`; N=5)

| caso | cambio (N=5) | control sin el cambio (N=3) |
|---|---|---|
| P1 «Quiero hablar con una persona», sin descuento → R sin descuento, $11,173.35, sin enlace, contador `{r}` | **5/5** | 0/3 (enlace a la primera) |
| P2 la misma con descuento comunicado (fila `d156` sembrada en la sesión) → R con descuento | **5/5** | — |
| P3 petición → R; «Sí, quiero una persona» → E con enlace; tercera petición → enlace del modelo, sin retener ni repetir E; contador `{r,e}` | **5/5** | 0/3 |
| P4a «Choqué y necesito ayuda» → escala directo | **5/5** | **0/3: hoy contesta el RAG con la KB** |
| P4b «Quiero poner una queja» → escala directo | **5/5** | **0/3: hoy contesta el RAG con la KB** |
| P4c «Mi auto es para Uber» → escala directo | **5/5** | — |
| P5 «Quiero que me llamen» → llamada B, no la retención | **5/5** | — |
| Regresión: `#418` D1, límite de 30 CASO A, llamada A, `#552` | **5/5 cada uno** | — |
| Pasada sobre el vivo `c0f117b0` (los 11) | 11/11 | |

**Batería offline** (`persona/bateria.js`): **41/41**. Incluye:
- los 8 mensajes reales de petición de persona de PROD (`n8n_chat_histories` h 14987, 9236, 8744, 5690, 5688, 5682, 4421 y 3631), todos clasificados;
- 5688 y 5690 (`payment_pending`, póliza emitida), que pasan a excepción;
- que llamada y persona no se pisan, en ninguno de los dos sentidos.

**Lo que hay que saber del control (P4a y P4b):** hoy, ante «choqué» y «queja», el RAG da información útil de la KB: el 911, no mover los vehículos, el canal «Quejas, Sugerencias y Denuncias» de qualitas.com.mx. Con la línea firmada, «escala directo», eso se sustituye por el enlace del agente. Lo consultas con Alberto; **la retención se queda en STG `c0f117b0` tal cual**. Si decide conservar la información, el cambio sería una línea por agente («da la información de la KB y, además, el enlace»), con otra tanda P4.

## 5. Sesión limpia para Alberto (STG)

- **`waq_2678_a1f397374890`**: su teléfono, cotización 2678 (Amplia anual **$15,072.85**, sin descuento ni póliza), fase `greeting`. Sin checkpoint, así que Django no manda seguimientos. Es la única active.
- **`waq_2983`** (su prueba de Recovery del `#551`) pasó a `open`, con respaldo en `backups/persona/sesiones-previas.json`. `sesion-alberto-persona-stg.py --restaurar` la devuelve a su estado.
- **Prueba sugerida:**
  1. «Quiero hablar con una persona» → retención sin descuento con $15,072.85;
  2. «Sí» → el contacto;
  3. otra petición → el enlace de siempre.

  «Choqué y necesito ayuda» → enlace (ver §4).

— Agente n8n · A
