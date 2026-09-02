# Duda `#275f` — PARO del §6, y el defecto de tu §7 tiene mecanismo completo: la sesión está CLAVADA en un 400 por un `tool_result` huérfano en el borde de la ventana

**De:** Agente n8n · **Para:** Arquitecto · 2 sep 2026
**Estado del v3:** aplicado y verificado (STG `b29bdf71`, 307 nodos, solo `Parse Router Output`, +3
patrones, los 20 de la v2 intactos, factura fuera, `Intent Router` byte a byte; offline 12/12 con el
ancla que ratificaste). **La batería del §6 corrió y PARO por tus bloqueantes** — pero no por el
carril: por el defecto que en tu §7 apartaste como «otra familia». Tenías razón en apartarlo y ahora
tengo su mecanismo entero, medido.

## 1 · La batería, por turno (sesión 2316, un mensaje por turno)

| # | Frase | Intent medido | Quién contestó | Literal |
|---|---|---|---|---|
| 1 | «mi póliza está emitida?» | `policy_status` | **`Emitted Reply`** | «Sí, tu póliza 7620101919 está emitida. ¿Te ayudo con algo más?» ✅ |
| 2 | «entonces tengo póliza o no?» | `policy_status` | **`Emitted Reply`** | ídem, con el número ✅ |
| 3 | «entonces sí tengo póliza?» | `policy_status` | **`Emitted Reply`** | ídem ✅ |
| 4 | «mi factura ya está lista?» | `kb_query` | RAG → **error fallback** | «Tuvimos un problema…» — NO desmintió (cinturón), pero el modelo no llegó a contestar |
| 5 | «quiero cotizar un seguro» | `contracting` | AI Agent → **error fallback** | NO entró al carril ✅ — pero sin conversación normal |
| 6 | «cuánto cuesta mi cotización?» | `contracting` | AI Agent → **error fallback** | NO entró al carril ✅ — y el precio funcionaba hace una hora |

**El alcance del carril es correcto en los seis** (1-3 dentro con el número; 4-6 fuera). Lo que no se
puede evaluar en esta sesión es «conversación normal»: **todos los turnos de agente revientan**, y ya
lo hacían ANTES del v3 — tus execs 28224 y 28227 son el mismo fallo.

## 2 · El mecanismo, medido pieza a pieza

**El 400 literal del `Anthropic Chat Model`** (exec 28245):
> `messages.0.content.0: unexpected tool_use_id found in tool_result blocks: toolu_01GJpQ9K5cCmrk7ztco3qoji. Each tool_result block must have a corresponding tool_use block in the previous message.`

1. **La memoria guarda la traza agéntica entera** — filas `ai` con `tool_calls` y filas `tool` — desde
   el **19 de julio** (primera: id 949). No es de hoy.
2. **La ventana real es 120 mensajes, no 60**: `contextWindowLength: 60` acaba en
   `messages.slice(-this.k * 2)` — `@langchain/classic` **1.0.27** (la versión del catálogo de
   n8n 2.28.7), `dist/memory/buffer_window_memory.js:64`, del tarball de npm.
3. **La sesión 2316 tiene 123 filas → la ventana empieza en la 4ª: id `6071`, tipo `tool`** — un
   `tool_result` cuyo `tool_use` (fila 6070, pareja PERFECTA en la BD, del 31 de agosto) queda
   **fuera del corte**. El `toolu_…qoji` del 400 es exactamente el de la fila 6071.
4. **Y la trampa que lo hace permanente:** el turno roto no escribe memoria (el agente muere antes
   del save), el carril del `#275f` tampoco escribe, así que **el borde no se mueve: la sesión queda
   clavada en el mismo 400 en TODOS los turnos de agente, para siempre**. Por eso a Alberto le
   funcionó el carril y le falló todo lo demás, y por eso mi batería del `#293` funcionaba ayer por
   la tarde (121 filas: el borde caía en otro sitio) y hoy no.

**Esto alcanza a PROD:** mismo n8n, misma memoria, mismas filas `tool`. Cualquier sesión real cuyo
total de filas deje el corte de 120 sobre una fila `tool` queda muda de agente hasta que algo escriba
en su historial — y nada escribe, porque todo lo que escribiría muere en el mismo 400. (Ironía
medible: un clic del `#282` la desatascaría — inserta una `human` y mueve el borde 1.)

## 3 · Qué pido

1. **Tus bloqueantes 5-6:** el alcance del carril está medido y limpio (no entraron); la
   «conversación normal» es **NO EVALUABLE en esta sesión** por el defecto externo. Dime si te vale
   así o si quieres que repita 4-6 sobre una sesión sana (una cotización nueva del teléfono de
   prueba) — 3 mensajes más, aviso previo dado.
2. **La sesión 2316 está rota y no la toco** (datos rotos no se reparan): si quieres desatascarla
   para seguir probando, dos filas neutras mueven el borde a la 6073 (`human`) — decisión tuya.
3. **El defecto de fondo es tuyo de abrir** (tu §7): te dejo el mecanismo completo con citas. La
   pieza estructural probablemente sea filtrar filas `tool`/`tool_calls` al LEER la memoria (o no
   guardarlas), pero eso es diseño de tu lado — no propongo implementación sin tu handoff.

— Agente n8n
