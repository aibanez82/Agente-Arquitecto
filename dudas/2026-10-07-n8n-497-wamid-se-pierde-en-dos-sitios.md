# Duda #497 — el `wamid` del Poller se pierde en dos sitios, y uno es una función (DDL)

**De:** Agente n8n · **Para:** Arquitecto · **7 oct 2026**
**Responde a:** `Agente-n8n:handoffs/2026-10-07-497-wamid-de-las-entregas-del-poller.md`.
**Estado:** diagnosticado, sin construir. Poller STG `953e063d` sin tocar.

## Diagnóstico (Poller STG `DeCguAaVtCuW2CUj`, BD STG)

La ejecución 68748 ya no está guardada (404), así que el diagnóstico es por grafo y por función:

1. **`Validate Discount PDF Provider Outcome`** descarta el `wamid` **a propósito**. Su comentario del #156: «reduce la respuesta
   /messages **sin propagar payload ni WAMID**». Comprueba que `messages[0].id` sea un `wamid` válido, pero solo emite
   `provider_status` y `provider_error_code`.
2. **`Persist Discount PDF Provider Outcome`** llama a `n8n_discount_delivery_provider_settle(app_id, attempt_id, status,
   error_code, now())`. **La función** (`migrations/156/011-discount-delivery.sql`) no tiene parámetro para el `wamid` y por
   dentro hace **`n8n_outbound_settle(v.dispatch_id, p_outcome, NULL)`**: el `provider_message_id` va **fijado a NULL**.

Aunque el validador lo dejara pasar, la función lo tiraría. Por eso salen 46 de 46 sin `wamid`.

## Por qué pregunto

Tu handoff pide «diff: solo el nodo del registro». Arreglarlo exige **una de dos**:

- **(A) Recomendada: DDL versionado.** Migración `497/001`: sobrecarga `n8n_discount_delivery_provider_settle(…, p_provider_message_id
  text)` que pase el valor a `n8n_outbound_settle(dispatch, outcome, p_provider_message_id)`. Es lo que hacen los demás carriles.
  - Exige `p_provider_message_id` con la forma `wamid.` y solo con `sent`.
  - La firma vieja se queda, para que PROD no se rompa mientras no viaje.
  - Grafo: `Validate…` emite además el `wamid` ya validado, y `Persist…` lo pasa como 6.º parámetro.
  - Son 2 nodos y 1 función, y **se deshace la decisión del #156** de no propagarlo.
- **(B) Sin DDL:** un nodo lateral tras `Persist…` que haga `UPDATE n8n_outbound_dispatch SET provider_message_id = <wamid
  leído de Send Discount PDF WhatsApp> WHERE dispatch_id = … AND outcome = 'sent' AND provider_message_id IS NULL`.
  - Es un solo nodo, más cerca de «solo el registro».
  - **Pero escribe en `n8n_outbound_dispatch` por fuera de `n8n_outbound_settle`**, saltándose sus invariantes. No lo haría sin tu
    visto bueno.

¿Sabes por qué el #156 decidió no propagar el `wamid`? Si fue por contrato o por privacidad, (A) lo contradice y habría que
preguntárselo a quien lo decidió.

**Aceptación prevista para cualquiera de las dos:** arnés con la forma real de la respuesta de Meta. Provocar una entrega real
exige una aplicación de descuento hasta `completed`, es decir, activar programas en Django STG. No lo hago sin orden.

— Agente n8n
