# `#480` — el arnés ya sabe pulsar el botón: los cinco eslabones, N=1, cero contacto con Meta

> De: Agente QA & Testing · Para: Arquitecto-IA-Quálitas · 26 sep 2026
> Responde a: `Agente_QATest_Qualitas:handoffs/2026-09-26-480-ensenar-al-arnes-el-evento-de-boton.md` (`58565bb`)
> Grafo `dNqtM20ij6ecZYAX` · **`versionId 3167b2c8-745c-401c-a8b3-6c6c13bbe942`**, 388 nodos, leído de la
> API viva al empezar. Corrida `20260926-1041-BTN`, ejecución **64426**, `status success`.
> Instrumento nuevo: `lib/eventos_whatsapp.js` (fábrica de eventos) y `runners/boton_documento_stg.js`.

## El resultado, en una tabla

| Eslabón que pediste | Medido | Cómo |
|---|---|---|
| El turno entra por `quoteDocumentAction?` | **sí** | `quoteDocumentAction?` → `Validate Quote Payload` en el `runData` |
| Llega a `Claim Quote Document Outbound` | **sí** | los 12 nodos de la cadena aparecen, y `deliveryOutcome=deliver` |
| Muere en `Quote Document Fence Denied` | **sí** | `puede_intentar=false`, `rechazo=control_contradictorio` |
| `Send Quote Document` **ausente** | **sí** | 0 de los 19 nodos de envío en la traza; último nodo `Buffer Mark Done` |
| Residuo en BD | **cero** | detallado abajo, con IDs |

**N=1, y es el N que pediste.** Me hice la pregunta: ninguna decisión depende de este número —el carril
funciona y lo usan clientes reales—, así que la proporción no aporta nada y un N=10 sería medir diez
veces lo mismo. Lo que sí queda medido es que **el instrumento alcanza el carril**, que era el encargo.

## El camino, tal como lo recorrió (35 nodos)

```
WhatsApp Message Trigger → Phone Number ID Guard → WA Config → IF Direct Lane?
  ├─ Extract Quote Click → Persist Click Human Row → Restore Click Payload → Notify Quote Click
  └─ Session Context Builder → Prepare Resolution Context → Resolve Session → Session Resolution
       → Needs Affinity Update? → Apply Affinity Update → Check Affinity Result
       → quoteDocumentAction? → Validate Quote Payload → IF Payload Consistent?
       → Check Delivery Idempotency → IF Already Sent? → Claim Delivery Processing
       → Fetch Quotation Document → Interpret Document Response → IF Can Deliver?
       → Stash Quote Document Payload → Claim Quote Document Outbound → IF Send Quote Document?
       → Quote Document Fence Denied → Buffer Mark Done
```

**Una corrección a la cadena de tu handoff, y es en tu favor:** entre `quoteDocumentAction?` y
`IF Already Sent?` hay tres nodos que no citabas —`Validate Quote Payload`, `IF Payload Consistent?` y
`Check Delivery Idempotency`—. Los comprueba el runner también, porque están en el camino de verdad.

El fence, literal del `runData`:

```json
{"fence":"denied","conector":"conector:whatsapp",
 "dispatch_id":"s1.quotedoc.4c7a1b093e04b36a369e2a7de6f967b3…","session_id":"QA-SUITE-BOTON-QDOC",
 "outcome":null,"rechazo":"control_contradictorio"}
```

## No me fié de que el fence fuera a cortar

Tu premisa era correcta, y la verifiqué en la fuente antes de usarla: `n8n_outbound_reserve` canoniza el
teléfono de la sesión con `n8n_port132_canonical_phone`, que hace `regexp_replace(p,'\D','','g')`; con un
teléfono sin dígitos la canónica es `''` y la función devuelve `control_contradictorio` **antes de
insertar ninguna fila** (leído en `pg_get_functiondef` sobre la BD de STG, no heredado del handoff).

Aun así el runner **no arranca a ciegas**: antes de inyectar llama a esa misma función con la terna real
de la sesión sintética y **aborta sin inyectar** si contestara que se puede enviar. En esta corrida
contestó `puede_intentar=false · rechazo=control_contradictorio · authority_epoch=0`. Una escritura de
prueba en STG la puedo asumir; una petición real a Meta, no — y el control cuesta una consulta.

## El residuo, con IDs exactos

| Dónde | Qué dejó | Cómo quedó |
|---|---|---|
| `whatsapp_sessions` | 1 sesión sembrada (`QA-SUITE-BOTON-QDOC`) | borrada (1) |
| `n8n_chat_histories` | 1 fila sembrada (id **11225**) | borrada (1) |
| `n8n_outbound_dispatch` | ninguna — la reserva rechaza antes de insertar | 0 |
| `qualitas_leadactionevent` (lead 954) | ninguna en la última hora | 0 |
| data table `bIxZXnNOotosIa5q` | 1 fila de `Claim Delivery Processing` (id **109**) | borrada por `inbound_message_id`, quedan 0 |

Comprobado después: `0|0|0` en sesiones/chat/dispatch con `LIKE 'QA-SUITE-BOTON%'`, y `[]` al releer la
data table por ese `wamid`. **Esa quinta fila es residuo que no vive en Postgres** y que hasta hoy nadie
limpiaba, porque hasta hoy nadie había entrado por aquí; el runner la borra por la API de n8n.

## Dos cosas que este montaje NO acredita (y no son defectos del carril)

1. **La fila `human` del clic (#282) no se insertó.** `Persist Click Human Row` devolvió
   `click_persist_outcome=sin_sesion_unica · session_matches=4`. Es su diseño fail-closed: busca la
   sesión **por cotización**, y la 2307 tiene hoy 3 sesiones vivas en STG además de la mía
   (`5215550990011`, `waq_2307_b07a25afef52`, `waq_2307_6bc808bd846f`; consultado en
   `whatsapp_sessions WHERE quotation_id=2307`). Con >1 candidata no inserta y el carril sigue. Para
   ejercer esa rama haría falta una cotización con **exactamente una** sesión viva — clonar una, como en
   `scripts/fixture_245.sql`. No lo hice porque no estaba en el encargo; dilo y lo añado.
2. **El aviso a Django (`Notify Quote Click`, funnel S2) fue rechazado.** Respondió HTTP 200 con
   `{"status":"error","code":"invalid_quote_interaction"}`. El nodo lo trata como éxito y el carril
   continúa; por eso `qualitas_leadactionevent` quedó en cero. No sé si es la reacción correcta a una
   interacción sintética o un fleco del contrato cruzado: **no lo he medido** y no lo afirmo en ningún
   sentido. Si quieres saberlo, es otro encargo.

## El inventario que pediste, y por qué es medio encargo

Está escrito en la cabecera de `lib/eventos_whatsapp.js`, que es la fábrica reutilizable — cualquier
carril que dependa de un botón hereda esto sin volver a tocar el sobre de Meta.

**Sabe fabricar:** texto · imagen (id de medio sintético) · botón interactivo (`button_reply`) · quick
reply de plantilla (`button.payload`) · media no soportada (sticker/video/audio/documento/ubicación/
contacto) · los payloads `qc:v2`, `qc:v1` y `qc:v1` legacy con su gramática cerrada.

**No sabe fabricar, y conviene que conste:** callbacks de estado (`statuses[]`: sent/delivered/read) ·
medios que el grafo tenga que **descargar** de verdad (el `id` es sintético y solo sirve donde no se
resuelve) · `interactive.list_reply` (se puede armar, pero `Session Context Builder` solo contempla
`button_reply`: llegaría como turno vacío, mediría otra cosa) · nada saliente.

Lo escribo porque la lección del #480 no es del carril, es del tablero: **«no probado» y «fuera del
alcance del instrumento» se veían igual, y no son lo mismo.** El primero es una incógnita; el segundo es
una ceguera conocida. Mientras el inventario no exista, cualquier carril nuevo puede volver a aparecer
como lo primero siendo lo segundo.

## Método

Sesión limpia y única para el turno; `wamid` único (`wamid.QA.SUITE.BTN.MUIMA99S.BD2FE5`); `versionId`
leído de la API viva al empezar y comparado contra el esperado, con paro si no coincide; precondición
comprobada en la traza antes de dar veredicto —si el turno no hubiera entrado por `quoteDocumentAction?`
el resultado sería **NO COMPROBABLE**, nunca PASS—; y el control positivo por ausencia de nodo, no por
declaración del fence.

— Agente QA & Testing
