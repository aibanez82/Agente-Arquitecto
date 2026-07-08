# Mensaje para Juan — el número de WhatsApp de test comparte webhook con producción

> Contexto (para el Arquitecto/Alberto, NO enviar): el App de Meta que Juan creó para staging
> (`docs/2026-07-06-mensaje-juan-meta-app-staging.md`) no logró el aislamiento esperado. Confirmado
> hoy (7 jul) con datos de ejecución de ambas instancias de n8n: el mismo evento de webhook llega
> a producción Y a staging al mismo tiempo. Bug #15 en `CLAUDE.md`. Profundizado el mismo día vía
> Graph API directa (con `STG_META_ACCESS_TOKEN` y `STG_META_APP_SECRET`, guardados en
> `Agente-Arquitecto/.env.local`, gitignored): prod tiene override de webhook a nivel de número,
> test no; `/subscriptions` de la App de test está vacío. No se pudo confirmar la WABA del número
> de test sin su ID — hipótesis de trabajo: comparte WABA con producción.

---

## Mensaje (copiar/pegar a Juan)

Hola Juan,

Encontramos un problema con el número de WhatsApp de prueba que configuraste: **está entregando sus mensajes también al bot de producción**, no solo al de staging.

Hoy hice una prueba end-to-end en staging (número de prueba `17377323515`) y confirmé, cruzando los logs de ejecución de las dos instancias de n8n, que **cada mensaje generó una ejecución en staging Y una ejecución casi simultánea (mismo timestamp, diferencia de ~100ms) en producción**, ambas con el mismo `phone_number_id` (`1154577517746231`).

Consecuencia real: el número de prueba escribió datos en la base de datos de **producción** (`n8n_chat_histories` y `whatsapp_sessions`) — conversación de prueba mezclada con datos reales. Por suerte no llegó a emitir ninguna póliza real ni a llamar a Quálitas producción (el flujo de prod falló antes, porque el `quotation_id` de prueba no existe en tu Django de producción) — pero el riesgo es real: si algún día el `quotation_id` de una prueba coincidiera con uno real, podría emitir una póliza real por error.

**Lo que necesito:** que el número de prueba (`17377323515`) tenga su **propio `phone_number_id`, completamente aislado**, sin que producción reciba ninguno de sus webhooks.

Ya adelanté parte del diagnóstico consultando directo la Graph API (con el access token y el App Secret que me diste):
- El número de **producción** (`1028815256982638`) SÍ tiene un override de webhook explícito a nivel de número, apuntando correctamente solo a nuestro n8n de producción.
- El número de **test** (`1154577517746231`, App `hyl-wai-stg`, id `4539428293006817`) **NO tiene ningún override de webhook a nivel de número**.
- La lista de suscripciones a nivel de App (`GET /4539428293006817/subscriptions`) está **vacía**.

Esto descarta que la App de test tenga una suscripción de Webhooks producto mal apuntada a prod (se vería ahí). Mi sospecha es que el número de test quedó registrado bajo la **misma WABA** que producción, y por eso hereda su configuración de webhook a nivel de cuenta — pero necesito el ID de esa WABA para confirmarlo (`GET /{waba-id}/subscribed_apps`) y no lo tengo. ¿Puedes revisar en Meta Business Manager bajo qué WABA quedó el número de test, y si comparte cuenta con el de producción?

Mientras tanto, vamos a pausar todas las pruebas en staging para no seguir generando ruido en la base de producción.

Gracias.
