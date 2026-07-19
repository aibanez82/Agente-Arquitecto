# Handoff para Juan — activar envío real de `checkpoint_followups` en producción

> De: Arquitecto. A pedido de Alberto — pasar a envío real ya, sin esperar los días de
> observación en dry-run que se habían propuesto originalmente.
> Repo: `aguayo-co/HYL-WAI`. Contexto completo: `Agente-Arquitecto:docs/iniciativas/seguimiento-leads-estancados.md`.

## Qué se pide

En `hyl-wai-production`, cambiar los config vars:

- `WHATSAPP_CHECKPOINT_FOLLOWUPS_ENABLED` → `true`
- `WHATSAPP_CHECKPOINT_FOLLOWUPS_DRY_RUN_DEFAULT` → `false`

## Estado verificado hasta ahora (todo confirmado en vivo por el Arquitecto)

- **Código**: interpolación de variables (`vehiculo`/`precio`) y check de `whatsapp_sessions.status`
  desplegados (release 319, `a49a7838`) — verificados contra el diff real del PR #108.
- **Migración `0041`**: corrida, 2 tablas confirmadas en Postgres PROD.
- **Fixture**: 21 filas cargadas (copy final + `delay_mins` 5/5/10), confirmado por conteo.
- **Scheduler**: Advanced Scheduler corriendo cada 5 min, confirmado en logs reales de Heroku —
  evaluando candidatos reales de PROD correctamente (interpolación resuelve bien, `delay_not_elapsed`
  → `eligible` se observó en vivo con una cotización de prueba real).
- **Webhook `proactive-wa-message`**: autenticación completa (Dashboard manda el header, n8n la
  exige), E2E real confirmado con un envío de WhatsApp real vía "Tomar conversación"
  (ejecución 3128, `wamid` real entregado).

## Lo único sin verificar todavía en PROD

El camino específico de **envío real de un `checkpoint_followup`** (payload con
`checkpoint`+`idempotency_key`, la rama "estricta" de validación del webhook) nunca se probó de
punta a punta en PROD con un envío real — solo en dry-run (que nunca llega a
`send_due_checkpoint_followups()`) y, hace días, en STG. Usa el mismo webhook y la misma
autenticación que ya se acaba de verificar en vivo, así que el riesgo es bajo, pero es honesto
dejarlo dicho: el primer envío real de un checkpoint en PROD será, en los hechos, la primera
prueba E2E de esa ruta específica ahí.

## Después del cambio

En cuanto lo actives, la siguiente corrida del Scheduler (cada 5 min) va a mandar de verdad los
recordatorios a los leads que ya salían como `eligible` en los logs de dry-run. Alberto va a estar
pendiente de los primeros envíos reales para confirmar que llegan bien — avísale en cuanto hagas
el cambio.
