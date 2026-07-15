# Historial de pendientes de infraestructura ya resueltos

Movido desde `CLAUDE.md` al limpiar el archivo (14 jul 2026) — estos ítems ya no son
accionables, se conservan aquí solo como registro de qué pasó y cuándo.

## PAT fine-grained para repo `aguayo-co/HYL-WAI`

✅ Resuelto (9 jul 2026) — `gh auth` (scope `repo`) ya permitía clonar directo el repo de Juan,
sin necesidad de generar un PAT nuevo. El plan original asumía que hacía falta un token
fine-grained aparte; no fue el caso.

## Crear repo `Agente_n8n` en GitHub + confirmar nombre final

✅ Resuelto (8 jul 2026) — el repo terminó siendo `aibanez82/Agente-n8n` (con guion, no guion
bajo como el nombre de trabajo original). Clonado en local, push directo habilitado desde el
Arquitecto.

## Issue #74 (`aguayo-co/HYL-WAI`) — follow-up de 15 min dejó de enviarse desde 2026-06-30 ~21:11 UTC

✅ Resuelto — cerrado por Juan el **2 jul 2026** (confirmado independientemente vía
`gh issue view 74 --repo aguayo-co/HYL-WAI`, 11 jul), antes de que se documentara en este repo
como pendiente.

**Causa real:** el follow-up dependía del cron/trigger de n8n; Juan lo movió a un comando
idempotente de Django (`enviar_seguimientos_whatsapp`, usa n8n solo como fuente de actividad) +
un fix de inanición del scheduler (PR #77, commit `0c9a26f`).

**Hipótesis descartada:** en su momento se sospechó relación con las columnas de timestamp
tz-naive documentadas en `docs/architecture/timezone.md` — se investigó y **no** era la causa;
issue y timezone se resolvieron por vías independientes.
