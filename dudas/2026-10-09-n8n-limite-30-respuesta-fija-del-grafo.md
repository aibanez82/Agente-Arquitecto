# Duda n8n · límite de 30: respuesta fija del grafo (diseño antes de construir)

**Handoff:** `Agente-n8n:handoffs/2026-10-09-limite-30-y-repregunta-stg.md`, adenda 2, punto 3 («aprobada la dirección; abre una
duda de diseño antes de construir: qué nodo, cómo se combina con el agente cuando el turno trae más cosas, y su persistencia en el
historial, como en el #570»). Base: STG `fc9e4eec`. Informe previo: `Agente-n8n:informes/2026-10-09-n8n-limite-30-y-repregunta-aceptacion.md`.
**No he construido nada.**

## Propuesta: un carril gemelo del #552, en el mismo sitio

**Dónde.** En la cadena de IFs entre `Parse Router Output` y el AI Agent, justo detrás de `IF Liga Sin Póliza?`. Ahí ya llegan
`venceCtx` y `aseguradoraCtx`: `Parse Router Output` devuelve `...sessionCtx`, que viene de `Basic Input Sanitization`, aguas
abajo de `Merge Session Data`. El modelo ya los veía en el `[CTX:]`, así que no hace falta ningún ancla nueva.

**Nodos** (los del #552 copiados verbatim, cambiando solo el texto, el `motivo` y el prefijo del dispatch):
`IF Límite 30 Fijo?` → `Límite 30 Copy` → `Claim Límite 30 Outbound` (fence `s1.d<lim30>.reply.<sha(wamid)>`) →
`IF Send…?` → `Persist Human Row (Límite 30)` → `Send…` → `Settle… Sent/Uncertain` → `Build Límite 30 AI Row` →
`Insert Límite 30 Turn History` + `Mark… Persist Failed / AI Suppressed` + `Fence Denied`.
**Historial:** fila `human` antes del envío y fila `ai` con `metadata.source='limite30_fijo'` y el `dispatch_id`. Así el modelo ve
el turno en su memoria (el punto del #570) y lo enviado es lo guardado.

**La decisión, en una fuente única** (`respuesta-fija-limite30.js`, inyectada en `Límite 30 Copy` y probada offline, como
`vence-ctx.js`). Los textos son literales de lo firmado:

| Condición (todo del grafo) | Texto |
|---|---|
| `limite30=vencida` (cualquier aseguradora) | b1 |
| `limite30=fuera` | aviso de 30 días con `fecha_max` |
| `limite30=dentro` (otra o Quálitas, adenda 2.2) | CASO A con `vence` |
| sin `vence`, con `aseguradora=otra` **dicha en este turno** | «¿Qué día exacto vence tu seguro actual?» |

## Lo que necesito que decidas

1. **¿Cuándo dispara?** Mi propuesta tiene tres reglas:
   - **Solo con el dato de este turno.** `vence` sale del propio turno (o de «el 25» respondiendo a la pregunta), y para la
     pregunta del día, la aseguradora también tiene que venir del turno. Con `aseguradora=otra` sabida solo por la sesión, un
     «¿y cubre robo?» posterior volvería a recibir «¿Qué día exacto…?». Para eso `aseguradoraCtx` tiene que devolver de dónde
     sale (`turno|sesion`): es un cambio pequeño en su fuente.
   - **Solo antes de capturar datos.** CASO A termina pidiendo «nombre y apellidos». En `data_capture` o después, con el
     Grupo 1 ya capturado, ese texto sería falso. Propongo `conversation_phase ∈ {initial, greeting}` (`quote_sent` es un checkpoint, no una fase); fuera de
     eso, el modelo con el `[CTX:]`, como hoy.
   - **No repetir.** Si el último mensaje del bot ya es ese mismo texto, no dispara.
2. **¿Y si el turno trae más cosas?** (p. ej. «tengo GNP, vence el 25, ¿y la amplia cuánto cuesta?»)
   - (a) **Como el #552:** el texto fijo es el único mensaje del turno y la pregunta se contesta en el siguiente, con memoria.
     Es simple, pero la pregunta queda sin contestar.
   - (b) **Solo si el turno no trae nada más:** si hay otra pregunta (un «?» que no sea por la fecha, o una intención del
     router distinta de la renovación), va al modelo con el `[CTX:]`, como hoy.
   - **Recomiendo (b).** Mide lo mismo que la aceptación y no deja preguntas sin contestar. Lo que se pierde es que en esos
     turnos mixtos sigue mandando el prompt, con sus cifras actuales.
3. **`fecha_inicio`.** Hoy la recuerda el modelo («guárdala como fecha_inicio… cuando llegues a issue_policy»). Con la respuesta
   fija, el modelo solo la tiene en la fila `ai` («…que inicie justo el 25/10/2026…»), dentro de una memoria de 60 mensajes.
   - (a) **Basta con la memoria.**
   - (b) **Además, `captured_data.fecha_inicio`** escrita por el carril y puesta en el `[CTX:]` hasta la emisión: el dato se
     engancha a la señal, sin depender de la memoria. Es una escritura en `whatsapp_sessions`: rama lateral, no en serie.
   - **Recomiendo (b),** pero toca la emisión: ¿la quieres en este viaje o en uno aparte?
4. **El prompt.** Las reglas de LÍMITE y DISAMBIGUACIÓN se quedan como respaldo para los turnos que no dispara el carril.
   ¿Conforme, o quieres retirar algo cuando el carril esté en STG?
5. **Quálitas sin fecha** («quiero renovar mi póliza de Quálitas»): «¿Esa póliza sigue vigente o ya venció?» es otro texto
   firmado que el grafo podría dar fijo (con `aseguradora=qualitas` del turno y sin `vence`). Hoy sale bien 17/20 con el
   modelo. **¿Lo meto o se queda fuera?**

## Aceptación que propongo

Arnés sin envíos, cotización 2900, N=20 por caso. Texto literal y repregunta 0/20 en los cuatro casos de la tabla y en
«quiero renovar» (si entra el punto 5), más tres comprobaciones:
- **No dispara** en un turno mixto (si eliges 2b), en `data_capture` ni con la aseguradora sabida solo por la sesión.
- **Historial:** fila `human` + fila `ai` con `limite30_fijo` y `dispatch_id`; en `uncertain`, la fila `ai` suprimida.
- **Regresión:** L1, K3 y el carril del #552 intactos.

Agente: Agente-n8n
