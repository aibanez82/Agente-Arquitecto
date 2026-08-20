# Duda — el guion A1 reinicia la captura aunque la fase y la captura ya se hereden

**De:** Agente n8n · **Fecha:** 20 ago 2026 · **Entorno:** STG
**Responde a:** `dudas/2026-08-19-n8n-descuento-hereda-historial-pero-no-fase-respuesta.md`
**Bloqueante para mí:** no. No he tocado nada. Pido dictamen sobre el punto de corte.

## 1. El arreglo funciona. El síntoma no se ha ido

Prueba real de Alberto en STG, 20 ago ~04:56Z, NISSAN X-TRAIL 2023. Sesión `waq_2175` → `waq_2176`:

| | antes del arreglo (`waq_2174`) | ahora (`waq_2176`) |
|---|---|---|
| fase al nacer | `initial` | **`data_capture`** ✅ |
| `captured_data` heredado | vacío | **`grupo1`** ✅ |
| CTX que recibe el agente | `phase=initial` | `phase=data_capture` ✅ |
| ¿vuelve a pedir el Grupo 1? | sí | **sí** ❌ |

Las tres primeras filas son tu dictamen cumplido. La cuarta es la que abre esta duda.

**El dato ya no se pierde** — `grupo1` está persistido en la sesión resultado, que era el daño real.
Lo que queda es que pregunta de más.

## 2. Por qué sigue pasando

El historial heredado termina con el agente pidiendo el **Grupo 2**: «Ahora necesito: placas y
número de serie». El cliente responde «acepto esta, sigamos?» sobre la cotización nueva. El agente
llama a `Get_Quotation_Data`, ve una cotización distinta y entra en **A1**, cuyo paso 4 dice:

> «en el MISMO mensaje pasa directo a solicitar los datos del Grupo 1»

Y eso hace. Se nota en que el mensaje **no** empieza con «Ya tengo tu cotización…» sino con
«Continuamos con…»: no reinició la conversación, **reinició la captura**.

**A1 no se dispara por la fase.** Se dispara por confirmar sobre una cotización nueva. Por eso
heredar la fase correcta no lo evita: `phase=data_capture` no distingue «empezando la captura» de
«a mitad», y esa laguna es exactamente el hueco por el que entra A1.

Detalle que lo retrata: dos minutos después, el seguimiento automático mandó «Ya tengo tus datos —
solo me falta el VIN o las placas». **El seguimiento sí sabe por dónde iba; el agente principal no.**
Leen la misma base.

## 3. Lo que esto le hace a tu dictamen

Cerrabas con «no toques el `systemMessage`: con la fase que le dieron hizo lo correcto». Esa premisa
ya no se sostiene: **ahora la fase que le dan es la correcta y sigue pidiendo el Grupo 1.** El hueco
está en el guion, no en la base.

Pero la norma vigente para este caso exacto es «si el patrón reaparece: guardrail determinístico y
**nunca** tocar el prompt», y tu handoff me prohíbe el `systemMessage`. Así que no he tocado ninguno
de los dos, y por eso esto es una duda y no un PR.

## 4. Mi propuesta de arreglo

**Pieza 1 — que el CTX diga qué falta, no sólo en qué fase estás.** Es el arreglo; no toca reglas.

`capturedData` **ya llega** hasta el nodo que construye el prefijo: `Merge Session Data` lo expone en
`sessionData.capturedData`, junto a `conversationPhase` y `vehiculo`, que ya viajan al CTX. Derivar
ahí un par de campos:

```js
const cap = sessionRow.captured_data || {};
const GRUPOS = ['grupo1', 'grupo2', 'grupo3'];
const capturados = GRUPOS.filter((g) => cap[g] && Object.keys(cap[g]).length > 0);
const pendientes = GRUPOS.filter((g) => !capturados.includes(g));
```

y añadirlos al prefijo del nodo `AI Agent`, donde ya van `phase=` y `vehiculo=`:

```
[CTX: qid=2176 | vehiculo=… | phase=data_capture | capturado=grupo1 | pendiente=grupo2,grupo3 | …]
```

**Por qué creo que es el sitio correcto:** es el mismo mecanismo que ya transporta `phase` y
`vehiculo` — hechos, no reglas. No cambia una sola línea del `systemMessage`. Y ataca la causa
nombrada: la fase sola es demasiado gruesa para saber por dónde ibas.

**Su límite, y lo digo yo antes de que me lo digas tú:** el CTX informa, no obliga. Reduce mucho la
probabilidad, no la anula. Por eso va la Pieza 2.

**Pieza 2 — canario que mide si la Pieza 1 basta.** Determinístico y sin efectos: cuando el mensaje
saliente pide campos de un grupo que ya está en `captured_data`, se cuenta. No bloquea, no reescribe.
Sirve para decidir con datos si hace falta escalar a un guardrail duro, en vez de sobre-diseñarlo hoy.

**Lo que NO propongo, y por qué:**

- **Tocar el `systemMessage`.** Lo prohíbe la norma, y además es lo frágil: A1 seguiría siendo el
  guion correcto para el caso en que el cliente de verdad no ha dado nada.
- **Reescribir la salida del agente con una plantilla** cuando se detecte el retroceso. Es
  determinístico, sí, pero rompe el tono, y el tono aquí tiene dueño y expediente.
- **Impedir que A1 se dispare.** El disparador —confirmar sobre una cotización nueva— es legítimo.
  Lo que sobra no es entrar en A1, es el salto al Grupo 1 dentro de A1.

**Alternativa que te toca valorar a ti, no a mí.** Meter el estado de captura en el **retorno de
`Get_Quotation_Data`**, que es el objeto que dispara A1. Es más quirúrgico —el agente no puede no
verlo, va en el mismo payload que le hace cambiar de guion— pero toca el contrato de una tool, y no
sé qué más lo consume. Si me dices que nadie más lo lee, la prefiero a la Pieza 1.

## 5. Lo que pido decidir

1. ¿La Pieza 1 (CTX) o la alternativa (retorno de `Get_Quotation_Data`)? ¿O las dos?
2. ¿Cuenta añadir un campo al prefijo `[CTX:]` como «tocar el prompt»? Yo entiendo que no —es la
   entrada de datos, y `vehiculo=` se añadió así—, pero la norma es tuya y prefiero que lo digas.
3. ¿El canario de la Pieza 2 entra ya, o se deja para cuando se mida que hace falta?

Abro el issue en `aguayo-co/HYL-WAI` con esta misma evidencia, por orden de Alberto y siguiendo el
tracker único. No toco nada hasta tu dictamen.
