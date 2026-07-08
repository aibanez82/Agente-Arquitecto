# Handoff Arquitecto → Agente n8n — Bug #15: verificar payload crudo, no solo timestamps

> Autor: Arquitecto-IA-Qualitas · 7 jul 2026
> Ejecutor: **Agente n8n**.
> Responde a / corrige el alcance de: `docs/2026-07-07-handoff-agente-n8n-URGENTE-verificar-cruce-prod-stg.md`
> Copia canónica: `Agente-Arquitecto:docs/2026-07-07-handoff-agente-n8n-verificar-payload-crudo-bug15.md` — deja también copia en `Agente-n8n/handoffs/`. Alberto: confirma que se lo pasaste completo.

## Por qué este handoff (cambio de hipótesis)

Tu reporte anterior (13 ejecuciones en prod con timestamps casi idénticos a las de staging, mismo `phone_number_id`) apuntaba a que Meta estaba entregando el mismo evento de webhook a dos Apps. Verifiqué esto hoy directo contra la Graph API de Meta (con credenciales que me dio Alberto) y **el resultado contradice esa hipótesis**:

- WABA de staging (`27763806206640265`) → `subscribed_apps` muestra **un solo** App: `hyl-wai-stg` (id `4539428293006817`). Nada de producción.
- WABA de producción (`2418053602347168`) → `subscribed_apps` muestra **un solo** App: `Aguayo IA` (id `1559369318501243`). Nada de staging.
- Los IDs de WABA son distintos — no comparten cuenta.

A nivel de Meta, la configuración se ve limpia. No hay una suscripción cruzada visible que explique que el mismo evento llegue a las dos Apps. Esto **no significa que el problema no sea real** — sigo confirmando (por SQL directo) que el contenido de la prueba de Alberto de hoy apareció en `n8n_chat_histories` de producción. Lo que cambia es que ya no puedo asumir que la causa es "Meta duplica el webhook a nivel de infraestructura" — necesito evidencia más directa que la coincidencia de timestamps.

## Tarea

Para 2-3 de las 13 ejecuciones de PRODUCCIÓN que reportaste (workflow `BtOaZm7WlZT-24V7hqCnF`, ids 2162-2177), trae el **payload crudo de entrada** del trigger (`GET /api/v1/executions/{id}?includeData=true`, o desde la UI si es más rápido). El payload de un webhook de WhatsApp de Meta trae estos campos identificadores directo en el JSON:

```
entry[0].id                                    ← WABA ID
entry[0].changes[0].value.metadata.phone_number_id   ← phone_number_id real que originó el evento
```

Repórtame, para cada ejecución revisada:
1. **¿Qué `phone_number_id` y `WABA id` trae el payload crudo?** ¿Es el de staging (`1154577517746231` / `27763806206640265`) o el de producción (`1028815256982638` / `2418053602347168`)?
2. Si el payload trae el `phone_number_id`/WABA de **staging** llegando al webhook de **producción** — eso sí confirmaría un cruce real de Meta (aunque `subscribed_apps` se vea limpio, puede haber algo que no captura ese endpoint). Avísame de inmediato, es hallazgo grave.
3. Si el payload trae el `phone_number_id`/WABA de **producción** — significa que esas 13 ejecuciones son mensajes que genuinamente llegaron al número REAL de producción, no un cruce de infraestructura. En ese caso el origen más probable es que Alberto (u otra persona) le escribió directo al número real de producción con contenido similar/idéntico al de la prueba de staging, en threads de WhatsApp separados — no un bug de aislamiento.

## Qué NO hacer

No le mandes nada a Juan todavía ni le pidas que revise Meta Business Manager — quiero confirmar con el payload crudo antes de pedirle que investigue algo que podría no ser lo que parece. No toques ni borres la sesión `525551074144` de prod, sigue como evidencia.

## Reporte esperado

Los 2 campos (`phone_number_id`, WABA id) del payload crudo de cada ejecución revisada, con su id de ejecución. Con eso cierro si el Bug #15 es un problema de Meta/infraestructura real o si la explicación es otra.
