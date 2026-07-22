# Handoff — activar envío real de `checkpoint_followups` esta noche, SIN filtro de horario

> De: Arquitecto. Decisión de Alberto (21 jul, 20:48 CDMX): activar ahora, de noche, fuera de la
> ventana 9am-8pm, aceptando explícitamente el mismo riesgo del casi-incidente del 19 jul (leads
> recibiendo un recordatorio automático a deshoras). Confirmado dos veces antes de proceder.

## Contexto

`checkpoint_followups` sigue en dry-run seguro en PROD (`ENABLED=true`, `DRY_RUN_DEFAULT=true`,
confirmado en vivo hoy vía Heroku API). El filtro de horario 9am-8pm CDMX sigue sin construirse
(handoff aparte: `docs/2026-07-21-handoff-juan-filtro-horario-checkpoint-followups.md`, todavía
pendiente de que lo apliques). Detalle completo: `docs/iniciativas/seguimiento-leads-estancados.md`.

## Riesgo aceptado explícitamente

Sin el filtro de horario, cualquier lead que califique mientras `DRY_RUN_DEFAULT=false` esté
activo recibe el mensaje real, sin importar la hora — el Scheduler corre cada 5 min (Advanced) sin
parar. Es el mismo escenario que casi manda 8 recordatorios reales a las 11pm el 19 jul.

## Qué hacer

1. **Juan** — en `hyl-wai-production`, cambiar `WHATSAPP_CHECKPOINT_FOLLOWUPS_DRY_RUN_DEFAULT` de
   `true` a `false`. `ENABLED` ya está en `true`, no tocar.
2. **Recomendación del Arquitecto para acotar el riesgo esta noche** (Alberto decide si la sigue):
   en vez de dejar el Scheduler automático mandando a todos los candidatos elegibles sin
   supervisión, correr una vez manual y acotada —
   `python manage.py enviar_seguimientos_whatsapp --message-key checkpoint_followups --limit 1` (o
   el límite que Alberto prefiera) — y revisar el resultado antes de dejar correr el Scheduler
   automático sin vigilancia.
3. **Alberto — monitorear en vivo** mientras `DRY_RUN_DEFAULT=false` esté activo: logs de Heroku de
   cada corrida del Scheduler y las conversaciones reales que reciban el recordatorio.
4. **Obligatorio — revertir a `DRY_RUN_DEFAULT=true` en cuanto termine la prueba/monitoreo de esta
   noche**, no dejarlo en `false` sin vigilancia activa ni un solo ciclo del Scheduler. Si algo se
   ve mal (copy raro, envío a sesión que no debía, error repetido), revertir de inmediato.

## Pendiente de fondo, sin cambio

El filtro de horario sigue sin construirse — este handoff no lo reemplaza. Sigue siendo el primer
paso pendiente para que el envío real quede sostenido sin necesitar revertir manualmente cada vez.
