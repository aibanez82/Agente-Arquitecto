# Duda `#297` — los tres caminos, medidos. Recomendación: la (c) primero, la (a) después con Juan, la (b) descartada

**De:** Agente n8n · **Para:** Arquitecto · 2 sep 2026 · Handoff `7a1fc62`. Nada construido; solo medición.
(En paralelo: viaje 1 de la promoción desplegado y esperando el clic de Alberto — esto no lo toca.)

## 0 · Dos números nuevos que cambian el peso de la decisión

- **PROD: 323 de 483 sesiones ya llevan filas `tool` dentro de sus últimas 120.** La (a) sola no las
  desarma: aunque dejemos de escribir trazas hoy, esas minas viven en el historial hasta que +120
  filas limpias las empujen fuera de la ventana — meses de dado cargado.
- **La racha máxima de filas `tool` consecutivas es 1 en STG y en PROD** (no hay tool-calls paralelos
  en la práctica). Tras una fila `tool` siempre viene una `ai`. **Una sola fila de reparación sana
  cualquier borde roto.** Esto hace a la (c) barata y determinista.

## 1 · Camino (a) — que las trazas no vivan en la memoria

**Quién las escribe (medido en la fuente de n8n 2.28.7):** `saveToMemory` en
`utils/agent-execution/memoryManagement.ts` — guarda `AIMessage(tool_calls)+ToolMessage` SIEMPRE que
el `chatHistory` tenga `addMessages` (Postgres lo tiene). **No hay opción de nodo para apagarlo.** El
dato jugoso: su propio fallback (cuando no hay `addMessages`) es un formato de TEXTO inofensivo —
`[Used tools: …]` dentro del output — o sea, el propio n8n trata las trazas como prescindibles.

**Cómo sin fork:** un `TRIGGER BEFORE INSERT` en `n8n_chat_histories` (BD, versionable como
migración): descartar filas `type='tool'` y limpiar `tool_calls` de las `ai`. **Esto es
exactamente tu §3: dejar de escribir en tabla compartida → Juan ANTES.** (Sus lecturas medidas
filtran `type='human'` — `n8n_whatsapp_activity`, `checkpoint_followups` — así que no le rompe nada,
pero el contrato del archivo nombra la tabla y la palabra es suya.)

**Qué pierde el modelo:** los resultados crudos de tools en contexto (15% de filas). La doctrina ya
dice que lo que el agente deba saber va en el `content` de las `ai` (gotchas 33/34, los marcadores
del `#180`). **Cero carriles n8n leen filas `tool`** (medido en todos los exports) y Django tampoco.

**El matiz que la haría peligrosa a medias:** quitar las filas `tool` DEJANDO el `tool_calls` de las
`ai` fabrica el huérfano INVERSO (`tool_use` sin `tool_result`) — el mismo 400 por el otro lado. Si
va la (a), van las dos cosas juntas. El texto «Calling…» como content sí es inofensivo.

## 2 · Camino (b) — que el corte respete las parejas: **DESCARTADO**

El `slice(-k*2)` vive en `BufferWindowMemory` de `@langchain/classic` y `MemoryPostgresChat` elige la
clase en código cerrado (`memClass = … BufferWindowMemory`, línea 104) sin punto de inyección. **Solo
se puede tocando la librería o manteniendo un nodo custom — un fork con otro nombre.** Tu regla lo
descarta y la comparto.

## 3 · Camino (c) — la red: detectar el 400 y reparar+reintentar

**La medición que lo hace seguro:** en las CINCO ejecuciones rotas (28224, 28227, 28241, 28243,
28245) **ningún nodo de herramienta llegó a correr** — el 400 salta en la PRIMERA llamada al modelo,
antes de generar nada. **Un reintento no puede duplicar `Issue_Policy` ni `Ensure_Payment_Link`
porque el intento fallido jamás los ejecutó.** Determinista, no probabilístico.

**Mecánica sin fork:** el carril de error de los agentes YA existe (`Stash Agent Error Fallback`).
Detector: el mensaje contiene `unexpected tool_use_id found in tool_result`. Reparación: **INSERT de
UNA fila `ai` neutra** (marcador estilo #180, content plano) en la sesión → el borde avanza 1 → tras
una `tool` siempre hay una `ai` (racha máx 1, medido) → ventana sana. Reintento UNA vez, con bandera
anti-bucle. Escribir una `ai` en la tabla es lo que ya hacen los carriles de guarda (precedente
`Insert Guard Turn History`).

**Qué conversación lee distinto el modelo:** una fila-marcador más, de la misma clase que las del
`#180`. **Y de regalo: la (c) DESBRICKEA las sesiones ya minadas** en su siguiente inbound — las
323/483 de PROD incluidas, sin migración.

## 4 · Recomendación, y por qué las otras no

**La (c) primero** (red inmediata: sin Juan, reversible, cubre las minas EXISTENTES y las futuras) y
**la (a) después, con Juan** (la raíz: trigger + decidir si migración retroactiva de trazas viejas).
La (a) sola no: deja 323 sesiones de PROD con el dado cargado durante meses. La (b) no: fork.

**Acreditación sobre el ejemplar (tu §4):** la (c) se acredita haciendo llegar UN turno de agente a
la 2316 (ese día, con tu escrito: reactivarla temporalmente o entrar por `payload_v2`); el ciclo
error→reparación→reintento le AÑADIRÁ filas — **la acreditación consume el ejemplar por diseño**, y
por eso es lo último que se ejecuta, con tu orden expresa. Hasta entonces, 123 y congelada.

— Agente n8n
