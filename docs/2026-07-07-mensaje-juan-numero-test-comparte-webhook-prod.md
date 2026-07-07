# Mensaje para Juan — el número de WhatsApp de test comparte webhook con producción

> Contexto (para el Arquitecto/Alberto, NO enviar): el App de Meta que Juan creó para staging
> (`docs/2026-07-06-mensaje-juan-meta-app-staging.md`) no logró el aislamiento esperado. Confirmado
> hoy (7 jul) con datos de ejecución de ambas instancias de n8n: el mismo evento de webhook llega
> a producción Y a staging al mismo tiempo. Bug #15 en `CLAUDE.md`.

---

## Mensaje (copiar/pegar a Juan)

Hola Juan,

Encontramos un problema con el número de WhatsApp de prueba que configuraste: **está entregando sus mensajes también al bot de producción**, no solo al de staging.

Hoy hice una prueba end-to-end en staging (número de prueba `17377323515`) y confirmé, cruzando los logs de ejecución de las dos instancias de n8n, que **cada mensaje generó una ejecución en staging Y una ejecución casi simultánea (mismo timestamp, diferencia de ~100ms) en producción**, ambas con el mismo `phone_number_id` (`1154577517746231`).

Consecuencia real: el número de prueba escribió datos en la base de datos de **producción** (`n8n_chat_histories` y `whatsapp_sessions`) — conversación de prueba mezclada con datos reales. Por suerte no llegó a emitir ninguna póliza real ni a llamar a Quálitas producción (el flujo de prod falló antes, porque el `quotation_id` de prueba no existe en tu Django de producción) — pero el riesgo es real: si algún día el `quotation_id` de una prueba coincidiera con uno real, podría emitir una póliza real por error.

**Lo que necesito:** que el número de prueba (`17377323515`) tenga su **propio `phone_number_id`, completamente aislado**, sin que producción reciba ninguno de sus webhooks. Por lo que veo, el App nuevo que creaste no llegó a desacoplarse del todo del número/App de producción — ¿puedes revisar en Meta Business Manager si el número de prueba quedó registrado bajo la misma WABA/App que el de producción, o si hay alguna suscripción de webhook cruzada entre las dos Apps?

Mientras tanto, vamos a pausar todas las pruebas en staging para no seguir generando ruido en la base de producción.

Gracias.
