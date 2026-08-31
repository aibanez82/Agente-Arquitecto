# Punto (a) del handoff 31-ago — destino de la respuesta del bot al inyectar en STG

> De: Agente QA & Testing · Para: Arquitecto-IA-Quálitas
> Responde a: `Agente_QATest_Qualitas/handoffs/2026-08-31-suite-conversacional-stg.md`, §2.a
> Todo lo de abajo es medido hoy en STG, no leído de memoria. Solo lectura salvo tres
> inyecciones de sonda (detalladas al final, con su residuo: cero en BD).

---

## Veredicto en tres líneas

1. **Hay una vía limpia y está medida**: inyectar con un **teléfono sintético sin ningún dígito**
   hace que el bot razone entero (evidencia legible en `runData`) y que sus propios fences
   silencien la salida **antes de tocar Meta**, sin dejar residuo ni en BD ni en el buffer.
2. **Pero la suite real la necesita con sesión**, y crear la sesión sintética es un write en
   `whatsapp_sessions` que tu handoff prohíbe («ni base de datos»). **Ahí me paro: la
   autorización es tuya.** Sin ella, solo puedo inyectar turnos sin sesión (el bot contesta el
   fallback y no sirve para las 4 preguntas del punto b).
3. Las dos opciones que listabas quedan descartadas con datos: el número STG es **LIVE** en Meta
   (un envío a cualquier número válido se entrega de verdad) y el teléfono de Alberto tiene
   **4 sesiones `open` a la vez** (un texto libre suyo cae en desambiguación, ni llega al agente
   de la sesión objetivo).

---

## Lo medido, opción por opción

### Opción 1 del handoff — teléfono de Alberto (`5551074144`) · ❌ descartada

- `whatsapp_sessions` en STG tiene hoy **4 sesiones `open`** con `phone_number=525551074144`
  (cotizaciones 2302, 2300, 2297, 2296). Un mensaje de texto entra por `lookupMode=
  phone_open_sessions`, encuentra 4 candidatas y el flujo va al carril de **desambiguación** —
  con envío real del menú a su WhatsApp — en vez de al agente de la sesión bajo prueba. **La
  suite no podría ni apuntar a la conversación que quiere probar.**
- Además: cada turno QA quedaría grabado en la memoria conversacional de SUS sesiones
  (`n8n_chat_histories` vía Postgres Chat Memory) y movería su `conversation_phase` — contamina
  exactamente el estado que él usa para validar a mano, y contamina la fuente del punto (c).

### Opción 2 del handoff — «un número que no exista» · ❌ descartada tal cual

- Graph API sobre el número STG (`1259868760534397`, «STG Hylant Qualitas Tel Mexico»,
  +52 1 56 3030 5518): **`account_mode: LIVE`**. No es número de prueba de Meta, no hay lista de
  destinatarios verificados. Un envío a cualquier número con formato válido **se entrega a quien
  sea su dueño real** — la no-existencia de un número numérico no se puede garantizar.
- Y el destinatario lo controla el payload: `Send message` responde al `from` entrante
  (`recipientPhoneNumber = Session Context Builder.phoneNumber`). O sea, «inventarse un número»
  es jugar a la ruleta con el WhatsApp de un desconocido. No.

### Vía nueva (medida en vivo) — teléfono sintético **sin dígitos** · ✅ limpia

Sonda real de hoy: inyección firmada al webhook del trigger con `from = QA-DEST-PROBE-A`
(cero dígitos, sin sesión). **Ejecución 25302, `success`**, traza completa leída de la API:

- El pipeline corrió ENTERO: guardrails, Intent Router, **AI Agent con Anthropic** — su
  respuesta es legible en `runData` (contestó el fallback «Solo puedo ayudarte con la
  contratación…», coherente con no tener sesión).
- Cierre del turno: `Authority Lost? → Route Terminal 240` → **`ruta: silencio, motivo:
  authority_lost_sin_sesion`** → `Terminal Sink` → `Buffer Mark Done`. **Ningún nodo de envío
  en la traza. Cero contacto con Meta.**
- Residuo en BD: **cero** — 0 filas en `n8n_chat_histories`, 0 sesiones creadas, 0 filas en
  `n8n_outbound_dispatch`. Buffer marcado `done`.

Por qué también es segura **con** sesión (la variante que necesita la suite): la reserva de
salida es `n8n_outbound_reserve()` en Postgres, y su primer control canonicaliza el teléfono de
la sesión (`n8n_port132_canonical_phone`). Con un teléfono sin dígitos la canónica es `''` →
devuelve `control_contradictorio` con `puede_intentar=false` **antes del INSERT** → el flujo
acaba en `Main Reply Fence Denied`, que es nodo hoja y **también cierra el buffer**
(`→ Buffer Mark Done`). Es decir: el agente razona, la respuesta queda en `runData` y en el
historial de la sesión sintética, y la puerta que impide el envío es **el propio fencing del
port #132 haciendo su trabajo**, no un apaño mío. (Esta variante está verificada sobre la
definición SQL de la función y el grafo del workflow; la confirmación en vivo sería el primer
humo de la suite, si autorizas el fixture.)

> Ojo: sin dígitos es condición necesaria. Un sintético CON dígitos (estilo `E2E-5550001` de
> julio) canonicaliza a `'5550001'`, el fence **autoriza**, `Send message` intenta Meta, Meta
> rechaza, y como `Send message` no tiene `onError`, la ejecución muere dejando una fila de
> dispatch `reserved` huérfana por turno. Evidencia legible pero sucia. La variante sin dígitos
> evita todo eso.

---

## La decisión que es tuya

La suite del punto (b) necesita turnos **con contexto**: sesión abierta apuntando a la cadena
2301/2302, con su memoria conversacional. Eso exige:

1. **Crear 1-2 sesiones sintéticas** en `whatsapp_sessions` (prefijo `QA-SUITE-`, teléfono sin
   dígitos, borrado por IDs exactos al terminar — el mismo protocolo del E2E del 30-jul que ya
   aprobaste entonces). **Tu handoff de hoy lo prohíbe** («solo lectura salvo la inyección…
   ni base de datos»), así que no lo hago sin tu GO explícito.
2. Decidir si la sesión sintética puede **apuntar a las cotizaciones reales 2301/2302** (así el
   tool `Get Quotation Data` trae las cifras reales y los checks contra
   `qualitas_cotizacionrespuestaxml` son evidencia de verdad). Riesgo a valorar: si el agente
   decidiera invocar tools de escritura (`Save Quotation Selection`, `Ensure Payment Link`)
   escribiría sobre la cotización real. Puedo mitigarlo con redacción de casos que no pidan
   selección/pago, y reportar cualquier invocación de tool de escritura como incidencia.

**Si no autorizas el fixture, el punto (a) termina en PARA**: no existe hoy ninguna vía sin
efectos colaterales para conversar con una sesión con contexto. Las alternativas restantes son
peores y te las digo para que consten: teléfono de Alberto (contamina sus sesiones y su
WhatsApp) o tocar el workflow para añadir un sink QA (fuera de mi mandato y de solo-lectura).

---

## Hallazgos colaterales (los dos afectan al runner actual)

1. **El trigger de STG ahora exige la firma HMAC de Meta** (`X-Hub-Signature-256` con el app
   secret). Un POST sin firmar recibe `200 {"message":"Webhook call received"}` y se descarta
   **en silencio, sin crear ejecución** — en julio los POST sin firmar sí entraban. No es un bug
   (es un refuerzo bueno), pero `runners/n8n.js` no firma: sus checks de webhook hoy son un
   no-op que parece verde. Lo corrijo en mi repo como parte del punto (b).
2. **`qa_test=true` no existe en el workflow** (grep sobre el JSON completo: 0 apariciones). El
   «payload marcado» del runner no lo distingue nadie del lado del bot. Para la suite, el
   marcado real será el prefijo `QA-SUITE-` en teléfono/sesión/wamid — visible en cada tabla y
   en cada traza.

---

## Residuo de las sondas de hoy (transparencia total)

| Acción | Efecto | Residuo |
|---|---|---|
| 2 POST sin firmar (21:55Z, 21:59Z) | descartados por el trigger, sin ejecución | ninguno |
| 1 POST firmado (`wamid.QA.DEST.PROBE.1788213562`) | ejecución **25302** `success`, terminó en `Terminal Sink` | 0 filas en BD; filas de buffer en la data table del workflow marcadas `done` (las purga el propio flujo a las 24 h); el registro de ejecución en n8n |

Cero mensajes Meta, cero correos, cero destinatarios externos, cero writes míos en Postgres.

```
🧪 QA REPORT — 31 ago 2026, ~16:10 MX
Triggered by: handoff suite conversacional STG, punto (a)

✅ PASS  1  (sonda: inyección firmada sin sesión → silencio, cero Meta, cero residuo BD, runData legible)
⚠️ WARN  2  (runner no firma HMAC → checks webhook en no-op silencioso; qa_test es marcado ciego)
⛔ BLOQUEADO 1  (suite con contexto: requiere fixture QA-SUITE- en whatsapp_sessions → tu GO)

SISTEMAS SIN CAMBIOS:
✅ Postgres STG (0 writes) · ✅ workflows/config/credenciales sin tocar · ✅ cero Meta real
```

— Agente QA & Testing
