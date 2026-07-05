# Playbook post-migración de timestamps (para cuando Juan corra las DDLs del issue #87)

> **Trigger:** Alberto dice *"Juan ya hizo los cambios"*.
> Guardado en git (no memoria local) para que persista entre laptops/sesiones.
> Contexto completo: issue `aguayo-co/HYL-WAI#87` + Bug #1/#10/#74 en `CLAUDE.md`.

## Paso 0 — Confirmar qué migró Juan

Las dos migraciones son independientes; preguntar cuál(es) corrió:
1. `n8n_chat_histories.created_at` (2 pasos) → habilita **Acción A** (dashboard hora exacta).
2. `whatsapp_sessions`(+archive) naive → `timestamptz` (`AT TIME ZONE 'UTC'`) → habilita **Acción B** (verificar Issue #74).

## Acción A — Reactivar hora exacta en el dashboard (ejecutor: Agente Dashboard; Alberto dispara + deploya)

Mensaje a relayar al Agente Dashboard:

> Ya existe la columna `n8n_chat_histories.created_at` (`timestamptz`, UTC) — n8n sella cada mensaje NUEVO con su hora real. En el visor de conversaciones:
> 1. Leer `created_at` para los mensajes de n8n (eliminar cualquier resto de estimación por `id`).
> 2. Mostrar hora exacta para los mensajes n8n que tengan `created_at`; los históricos con `created_at IS NULL` siguen bajo "hora aproximada" (NO inventar hora — NULL es "desconocida" por diseño, no un error).
> 3. Ordenar n8n (`created_at`) + Django (`sent_at`) en un ÚNICO hilo cronológico por su `timestamptz` real (ambos son instantes absolutos UTC → comparación directa; convertir a `America/Mexico_City` SOLO al mostrar).

Alberto: disparar al agente → él codea → deploy en Vercel. No tocar código a mano.

## Acción B — Verificar Issue #74 (follow-up de 15 min)

Hipótesis (Arquitecto): el follow-up dejó de dispararse (desde 2026-06-30 ~21:11 UTC) por el desfase ±6h al comparar `last_activity` naive contra `NOW()`. Con `whatsapp_sessions.last_activity` ya `timestamptz`, la comparación del scheduler es tz-safe → debería volver a disparar.

Verificación (diseñar la query exacta al momento — necesita identificar la firma del follow-up: template en `qualitas_whatsappmessage` o mensaje "retomar" en `n8n_chat_histories`):
- Confirmar si empiezan a salir follow-ups DESPUÉS de la migración (contar envíos de follow-up por día; ver si resumen).
- Si resumen → causa raíz confirmada (tz), cerrar #74.
- Si NO resumen → el desfase no era la (única) causa; escalar. Ojo: el fix real de #74 puede requerir acceso Heroku (config vars/releases/scheduler).

## Nota

Ambas acciones dependen de que Juan confirme la migración correspondiente. Nada que hacer antes.
