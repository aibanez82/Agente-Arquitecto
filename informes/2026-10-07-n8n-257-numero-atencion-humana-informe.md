# Informe #257 — el número de atención humana, en un solo sitio y con interruptor (STG)

**De:** Agente n8n · **Para:** Arquitecto · **7 oct 2026**
**Responde a:** `Agente-n8n:handoffs/2026-10-07-257-numero-de-atencion-humana-en-un-solo-sitio.md`.
**Estado:** aplicado en STG y aceptado **4/4**, con render idéntico byte a byte. **PROD no está tocado**: toca los dos
`systemMessage`, así que va a la firma de Alberto.

## Censo (medido en STG `affd10b4`)

El número **ya no es** `525634352430`: el #517 lo cambió a **`525537511678`**. **11 apariciones en 9 nodos**:
- 1 en el `systemMessage` del `AI Agent`;
- **2** en el del `RAG IA Agent` (el fallback de la KB y el mensaje de escalamiento);
- 1 en cada uno de `Issue Policy` (descripción), `Get Quotation Data` (descripción), `Send Generic Error Message` (`textBody`),
  `Message Budget Guard`, `KB Budget Guard`, `Apply Guardrail Result` y `Rebuild Summary From Record` (nuevo desde el #536);
- 1 en la red del #517 de `Outbound Leak Guard`, que reescribe el número viejo al nuevo.

**Después: 0 escritas a mano fuera de la fuente.** Las 11 leen de ella.

## La fuente: `WA Config`

**Por qué ahí:**
- es el nodo de configuración de entorno: ya fija `waPhoneNumberId`, el número por el que contesta el bot (#360);
- corre al principio de **todos** los caminos del webhook, y los 6 nodos de envío ya lo leen por `$('WA Config')`;
- no es `$env` (bloqueado) ni una `dataTable`, que exigiría un nodo de lectura en cada camino.

**Lo que añade:** `numeroAtencionHumana = '525537511678'` y `hayAtencionHumana = true`, con el aviso de no activar el `false`
sin el texto firmado.

**Cómo leen los sitios:**
- **Campos de expresión** (los dos prompts, las dos descripciones de tool, `textBody`): el tramo que promete a una persona pasa
  a `{{ hay ? <texto de hoy con el número de la fuente> : '[COPY SIN HUMANO — PENDIENTE DE FIRMA]' }}`.
  - Las descripciones de `toolWorkflow` sí resuelven expresiones. Medido en el código fuente de n8n:
    `ctx.getNodeParameter('description', 0)`.
  - Las tres que eran texto plano pasan a expresión. Antes comprobé que no contenían `{{` que pudiera cambiar al evaluarse.
- **Nodos de código:** leen `$('WA Config').first().json` y envuelven la frase de la promesa con el interruptor. La red del #517
  reescribe al número de la fuente.
- **El «no» no está activado.** El hueco está marcado y el texto sin humano lo redacta Mejoras y lo firma Alberto.

## versionId y diff

**Bot STG:** `affd10b4` → **`f2c599f1`**. Respaldo: `backups/257/bot-stg-affd10b4-20261008T003732Z.json`.

**Diff contra el respaldo:**
- hojas: exactamente los 10 campos de los 9 sitios y `WA Config/jsCode`;
- el resto de nodos idénticos; connections idénticas;
- censo literal fuera de la fuente = 0; el workflow activo.

**Código:** rama `fix/257-numero-atencion-humana-una-fuente`, `scripts/257/`.

## Aceptación

| # | Resultado | Evidencia |
|---|---|---|
| 1 | **PASS** | Censo: 11 escritas a mano → **0**, y 11 leyendo de `WA Config`. |
| 2 | **PASS 10/10** | **Render idéntico byte a byte con «sí»** (`scripts/257/equivalencia-render.js`). Cada campo, viejo y nuevo, renderizado con el mismo contexto: los dos prompts completos, las dos descripciones y el `textBody` (expresiones evaluadas), más los nodos de código **ejecutados**. Las dos guardas de presupuesto y la de emisión ejercen el número; también se ejecutan el resumen técnico y la red del #517. **Con «no»:** todos muestran el hueco y ningún número. |
| 3 | **PASS en vivo** | Teléfono de Alberto, sesión `waq_2285_080e953f9997` con el contador de `greeting` sembrado a 50. «hola» → **81043**: `WA Config` = {número `525537511678`, hay = true} → `Message Budget Guard` excedida → llegó «…te invitamos a hablar con uno de nuestros agentes especializados: https://api.whatsapp.com/send?phone=525537511678&text=…2285…». **El mismo número que hoy.** |
| salud | **PASS** | Los prompts ahora leen la fuente, así que comprobé que los dos agentes siguen funcionando en vivo: **81045** y **81046** (`RAG IA Agent`) y **81048** (`AI Agent`), sin error y con respuesta `sent`. |
| 4 | **PASS** | Diff: arriba. |

**Sesión de la prueba:** la fijé como `active`, le **devolví el `rate_limit_data` previo** y la **cerré**.

## Fuera de este viaje (lo anoto)

- **Error Handler** (`Apologize To Client`): lleva el número **en otro workflow**, que no puede leer el `WA Config` del bot. El día
  del «no» habrá que tocarlo también, o darle su propia fuente. No estaba en el handoff.
- **El historial:** 243 mensajes antiguos de PROD llevan el número viejo. La red del #517 sigue cubriéndolos, ahora con el
  número de la fuente.

— Agente n8n
