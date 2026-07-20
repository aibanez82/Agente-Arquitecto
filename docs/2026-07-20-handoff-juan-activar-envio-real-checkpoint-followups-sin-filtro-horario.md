# Handoff — activar envío real de `checkpoint_followups` hoy, SIN filtro de horario todavía

> De: Arquitecto. Decisión de Alberto (20 jul): activar hoy con monitoreo manual, aceptando el
> riesgo de que el filtro de horario (9am-8pm CDMX) todavía no está construido — en vez de esperar
> a construirlo primero.

## Contexto

`checkpoint_followups` lleva corriendo en dry-run seguro en PROD desde el 19 jul
(`WHATSAPP_CHECKPOINT_FOLLOWUPS_ENABLED=true`, `DRY_RUN_DEFAULT=true`), Scheduler cada 5 min
(Advanced), detectando candidatos elegibles correctamente. Detalle completo:
`docs/iniciativas/seguimiento-leads-estancados.md`.

**Riesgo conocido y aceptado explícitamente por Alberto:** no existe todavía el filtro de horario.
Si un lead califica de noche/madrugada, el envío real saldría igual — mismo riesgo del
casi-incidente del 19 jul (8 leads a punto de recibir un mensaje a las 11pm).

## Qué hacer

1. **Juan** — en `hyl-wai-production`, cambiar `WHATSAPP_CHECKPOINT_FOLLOWUPS_DRY_RUN_DEFAULT` de
   `true` a `false`. `ENABLED` ya está en `true`, no tocar.
2. **Alberto / Agente n8n** — monitorear en vivo durante el día: revisar cada corrida del
   Scheduler (logs de Heroku, `enviar_seguimientos_whatsapp --message-key checkpoint_followups`)
   y las conversaciones reales que reciban el recordatorio, para validar que los reintentos se
   comportan como se diseñó (delay_mins 5/5/10, copy correcto, no se manda a sesiones cerradas).
3. **Obligatorio — revertir antes de que oscurezca:** volver a poner `DRY_RUN_DEFAULT=true` **antes
   de las 8pm hora CDMX**, sin excepción, mientras el filtro de horario no exista. No dejarlo en
   `false` durante la noche bajo ninguna circunstancia — es exactamente el escenario que casi pasó
   el 19 jul.
4. Si algo se ve mal durante el día (copy raro, envío a sesión que no debía, error repetido),
   revertir `DRY_RUN_DEFAULT=true` de inmediato, no esperar a la noche.

## Pendiente de fondo, sin cambio

El filtro de horario sigue sin construirse — este handoff no lo reemplaza, solo pospone su
construcción un día más por decisión explícita de Alberto. Sigue siendo el primer paso pendiente
de esta iniciativa apenas se pueda.
