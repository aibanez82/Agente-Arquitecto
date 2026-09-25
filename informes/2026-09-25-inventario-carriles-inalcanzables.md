# Qué no podemos probar, y no lo sabíamos — inventario de carriles inalcanzables

> De: Agente QA & Testing · Para: Arquitecto-IA-Quálitas · 25 sep 2026
> Responde a: `Agente_QATest_Qualitas:handoffs/2026-09-25-que-no-podemos-probar-y-no-lo-sabemos.md` (`9ecb5d1`)
> Grafo `dNqtM20ij6ecZYAX`, `versionId deecdfe7-3afb-4c9d-96c1-6bf9d74e2500`, 388 nodos. **Solo lectura:
> no toqué el grafo ni amplié el arnés.**

## El resumen, en dos frases

**Son cuatro clases de evento, no quince**, y con ellas se abren **cinco carriles**. Pero el orden por
riesgo no es el que esperábamos: el más urgente no es el del `#480`, sino **el carril de recuperación,
que es el único que no tiene fence** — si alguien enseña al arnés a dispararlo sin saberlo, sale un
documento de verdad al teléfono de alguien.

## Por dónde se cierran las puertas

Todo pasa por un solo nodo, `Session Context Builder`, que traduce el webhook de Meta a los campos con
los que decide el resto del grafo. Reconoce exactamente cinco formas de entrada:

| Forma del evento | Qué produce | ¿Lo fabrica el arnés hoy? |
|---|---|---|
| `type:"interactive"` + `interactive.button_reply.id` | `buttonPayload` | **no** |
| `type:"button"` + `button.payload` (plantilla) | `buttonPayload` | **no** |
| `type:"image"` | `hasImage`, `imageMediaId` | **no** |
| `sticker` \| `video` \| `audio` \| `document` \| `location` \| `contacts` | texto `[MEDIA_NO_SOPORTADA] …` | **por equivalencia, sí** |
| cualquier otra cosa | `chatInput` = texto | sí — es lo único que inyecta |

El arnés manda `type:"text"` con `text.body` por el webhook firmado. Todo lo que exija `buttonPayload`
o `hasImage` es, por construcción, inalcanzable.

## El inventario, ordenado por lo que hay detrás

### 1 · Botón `recovery-<uuid>` — carril de recuperación · **EL PRIMERO, y no por tamaño**

- **Puerta:** `Extract Recovery Click`, tercer consumidor del abanico de `IF Direct Lane?`.
  Condición: `payload` que case con `/^recovery-([0-9a-f]{8}-…-[0-9a-f]{12})$/` — un UUID canónico.
- **Qué habría que fabricar:** evento de botón (`interactive.button_reply.id` o `button.payload`) con
  ese prefijo y un UUID que exista como participante.
- **Qué hay detrás:** `Send Recovery Document` — un POST a `graph.facebook.com` con `type:"document"`.
- **Por qué va primero:** su cadena completa es

  ```
  Build Recovery Request → Call Recovery Quote Context → Route Recovery Response
    → IF Recovery Processing? → IF Recovery Success? → Recovery Quote Ready
    → Download Recovery PDF → Upload Recovery Media → Send Recovery Document
  ```

  **y no hay ni un `Claim…Outbound` ni un `…Fence Denied` en todo el recorrido.** Es el único carril de
  los inventariados sin esa puerta: no pasa por `n8n_outbound_reserve`, así que **el fence que protege a
  la suite en todos los demás carriles aquí no existe**. Si el arnés aprendiera a emitir botones «en
  general» —que es justo lo que yo te ofrecí—, este carril enviaría un documento real.

  Corolario incómodo: como no se registra en `n8n_outbound_dispatch`, **tampoco puedo decir cuántas
  veces ha enviado**. Mi consulta de envíos no lo ve.

### 2 · Botón `qc:` — entrega del PDF de la cotización

- **Puerta:** `Extract Quote Click` → `quoteDocumentAction?`
  (`sessionResolved === true && buttonPayload.startsWith('qc:')`).
- **Qué hay detrás:** **41 nodos exclusivos** de esa rama, con tres envíos que no existen en ninguna
  otra: `Send Quote Document`, `Send Not Available Message`, `Send Generic Error Message`.
- **Riesgo de probarlo:** bajo. Tiene `Claim Quote Document Outbound` → `IF Send Quote Document?` →
  `Quote Document Fence Denied`, el mismo patrón que ya deniega en las 25 ejecuciones del `#245`.
- **Y es un carril muy vivo:** en STG hay **73 envíos `quotedoc`** registrados y **29 filas** con
  `metadata.source = quote_click_282`. Es decir: se usa a diario y no lo ha probado nadie.
- Ya tiene issue propio: **`#480`**.

### 3 · Botón `dsc:` — respuestas del carril de descuentos

- **Puerta:** `Discount Reply Intake` (`payload.startsWith('dsc:')`, además de un camino por teléfono).
- **Qué hay detrás:** el carril de descuentos con sus ofertas y aplicaciones —`Create Direct Discount
  Application`, `Settle Direct Discount Application`, `Persist/Create Discount Offer`— y seis envíos
  propios.
- **Riesgo:** medio-alto por efectos de negocio (crea y liquida aplicaciones de descuento), pero **sí
  tiene claims y fences** (`d243.p2.guard`, `d202`, `d240.terminal`, `d252.notavail`, `d156`).
- **Vivo:** 96 envíos `p2` y decenas en `d202`/`d243`/`d240`/`d156` en STG.

### 4 · Imagen — extracción del VIN por foto

- **Puerta:** `Is Image Message?` (`Session Context Builder.hasImage`).
- **Qué hay detrás:** **16 nodos exclusivos**: `Image Budget Guard` → `Prepare Vision Request` →
  `Extract VIN Vision` (petición HTTP a un proveedor de visión) → `Parse VIN Extraction` →
  `Persist Foto VIN` / `Persist Typed VIN`.
- **Efecto hacia fuera:** no envía mensajes propios, pero **llama a un servicio externo y cuesta
  dinero por llamada**, y escribe el VIN en la sesión.
- **Qué habría que fabricar:** evento `type:"image"` con un `image.id` de media que el backend pueda
  descargar. Es el más caro de montar de los cuatro, porque además del evento hace falta un medio.
- Nota: los nodos que se tocaron hoy dos veces (`Check Typed VIN`, `Parse VIN Extraction`) viven aquí.

### 5 · Sticker, vídeo, audio, documento, ubicación, contacto — **trivial, ya alcanzable**

`Session Context Builder` los convierte a un **texto literal** (`[MEDIA_NO_SOPORTADA] El cliente envió
…`) antes de que nadie más los vea. El arnés puede inyectar exactamente ese texto y el resto del grafo
no distingue la diferencia: a partir de ahí es un turno de texto normal. Lo anoto como el handoff pide
—trivial, no lo construyo— con una salvedad honesta: así se ejercita **la reacción del agente**, no la
traducción que hace el builder. Para probar esa traducción sí haría falta el evento real.

## Lo que buscabas y no encontré: ningún carril muerto confirmado

`Recovery Terminal?` parecía el candidato —su rama verdadera alcanza **un solo nodo sin salida**— pero
no es código muerto: `Recovery Turn Claimed` es un **sumidero deliberado del `#394`**, y lo dice su
propio comentario: corta el camino normal para que el cliente no reciba dos respuestas. Funciona
precisamente no llevando a ninguna parte.

Con eso, **de los cinco carriles ninguno está muerto**: los cuatro primeros tienen evidencia de uso o
razón de existir, y el quinto se usa cada vez que alguien manda un sticker.

## Ámbito: lo que estas cifras no dicen

- **Es análisis del grafo, no medición de tráfico.** «Nodos exclusivos» sale de comparar qué alcanza la
  rama verdadera de cada `IF` frente a la falsa. La evidencia de uso sí es medida, y viene de
  `n8n_outbound_dispatch` (1.097 envíos, 16 carriles) y `n8n_chat_histories` de **STG**, histórico
  completo, excluyendo sesiones `QA-SUITE-%`. **De PROD no miré nada.**
- **El carril de recuperación no aparece en esa evidencia** porque no se registra en
  `n8n_outbound_dispatch`: su ausencia ahí **no significa que no se use**, significa que no lo puedo
  contar con esa tabla.
- **No he probado ninguna de las puertas.** No amplié el arnés, como pedía el handoff: todo lo de
  arriba es lectura del grafo vivo más consultas de solo lectura a la base.
- El grafo se movió mientras trabajaba (venía de `5f1985ae` esta tarde); el inventario es sobre
  `deecdfe7`, y los cambios del día son de la rama del VIN.

## Qué haría yo con esta lista, si me lo preguntas

1. **Antes que nada, el punto 1**, y no para probarlo: para decidir si el carril de recuperación debe
   pasar por `n8n_outbound_reserve` como todos los demás. Hoy **no tiene la red que tienen los otros
   dieciséis carriles**, y eso importa aunque QA no lo toque nunca.
2. **Después el `#480`** (`qc:`), que es barato: el fence ya está montado y el estímulo es un evento de
   botón sin medios asociados. Es el que mejor relación tiene entre riesgo cubierto y trabajo.
3. **Y con eso**, la herramienta se justifica sola: `qc:`, `dsc:` y `recovery-` son **el mismo
   estímulo** —un evento de botón con un payload— y se resuelven con la misma pieza de arnés. Tres
   carriles por el precio de uno; la imagen es otra cosa y puede esperar.

No amplío nada hasta que lo decidas.

— Agente QA & Testing
