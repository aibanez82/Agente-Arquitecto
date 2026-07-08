# Mensaje para Juan — el número de WhatsApp de test comparte webhook con producción

> Contexto (para el Arquitecto/Alberto, NO enviar): el App de Meta que Juan creó para staging
> (`docs/2026-07-06-mensaje-juan-meta-app-staging.md`) no logró el aislamiento esperado. **Confirmado
> con certeza (7 jul) por el Agente n8n vía payload crudo:** el `wamid` (id único de Meta) es idéntico
> entre ejecuciones de staging y de producción — es el mismo mensaje entregado dos veces, no
> coincidencia. Se descartó la hipótesis de WABA compartida (son WABAs distintas, `subscribed_apps`
> limpio en ambas). Bug #15 en `CLAUDE.md`. Listo para enviar.

---

## Mensaje (copiar/pegar a Juan)

Hola Juan,

Encontramos un problema con el número de WhatsApp de prueba que configuraste: **está entregando sus mensajes también al bot de producción**, no solo al de staging.

Hoy hice una prueba end-to-end en staging (número de prueba `17377323515`) y confirmé, cruzando los logs de ejecución de las dos instancias de n8n, que **cada mensaje generó una ejecución en staging Y una ejecución casi simultánea (mismo timestamp, diferencia de ~100ms) en producción**, ambas con el mismo `phone_number_id` (`1154577517746231`).

Consecuencia real: el número de prueba escribió datos en la base de datos de **producción** (`n8n_chat_histories` y `whatsapp_sessions`) — conversación de prueba mezclada con datos reales. Por suerte no llegó a emitir ninguna póliza real ni a llamar a Quálitas producción (el flujo de prod falló antes, porque el `quotation_id` de prueba no existe en tu Django de producción) — pero el riesgo es real: si algún día el `quotation_id` de una prueba coincidiera con uno real, podría emitir una póliza real por error.

**Lo que necesito:** que el número de prueba (`17377323515`) tenga su **propio `phone_number_id`, completamente aislado**, sin que producción reciba ninguno de sus webhooks.

Ya investigamos bastante de nuestro lado antes de pasártelo, para que no tengas que empezar desde cero:

- Confirmamos con el `wamid` (el ID único que Meta asigna a cada mensaje) que es **el mismo mensaje entregado dos veces** — no es una coincidencia ni un reintento nuestro. El payload trae el `phone_number_id` del número de **test** (`1154577517746231`), pero llegó también al webhook de **producción**.
- Descartamos que compartan WABA: la de staging (`27763806206640265`) y la de producción (`2418053602347168`) son distintas, y en `subscribed_apps` cada una muestra un solo App — `hyl-wai-stg` en la de staging, `Aguayo IA` en la de producción. Nada cruzado visible ahí.

Así que el cruce es real, pero **no se ve en el nivel que normalmente revisaríamos** (App Webhooks / WABA subscribed_apps). Sospechamos que puede ser algo como: un System User con permisos sobre las dos WABAs, una suscripción vieja que no aparece en ese endpoint, o algo a nivel de Business Manager que agrupa las dos cuentas. **Lo que necesito de ti:** que revises directo en el dashboard de la App de producción el **log de entregas de webhook** (Meta Business Manager → tu App de producción → WhatsApp → Configuration → Webhooks → ver el historial/log de eventos entregados) para ese `phone_number_id` de test y veas qué suscripción o permiso está causando que también le llegue a producción.

Mientras tanto, vamos a pausar todas las pruebas en staging para no seguir generando ruido en la base de producción.

Gracias.
