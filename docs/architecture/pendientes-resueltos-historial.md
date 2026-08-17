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

## Migración KB del bot a RAG real (pgvector + OpenAI embeddings)

✅ Resuelto — completa y cerrada en PROD desde **18 jul 2026**. `kb_chunks` (119 filas) +
fallback `doc_chunks` (152 filas). E2E real confirmado para RAG general, M36/M38,
`kb_chunks.id=38` y el fallback de `doc_chunks` (Cláusula 8ª, verificado contra el PDF). Guard
defensivo de tool-call crudo desplegado en PROD/STG (issue #47, cerrado). Sin pendientes
urgentes al cierre. Detalle: `docs/iniciativas/2026-07-17-migracion-rag-kb-pgvector-design.md`.

## Cómo saber con certeza si un cliente pagó la póliza

✅ Resuelto (26 jul 2026) — Agente Conciliación operativo: scraping real del portal Q 360
(Playwright, login simple sin captcha), cron diario en GH Actions, escribe en su tabla propia
`conciliacion_pagos`. Certificado 26 jul, reporte en `docs/`. Queda como pendiente aparte qué
hacer con los estatus `VENCIDO`/`CANCELADO` que detecta (sigue en la tabla de Pendientes de
CLAUDE.md). Detalle: `docs/architecture/estatus-pago-qualitas.md`.

## Rotar `N8N_API_KEY` de n8n PROD (expuesta en chat el 30 jun + vencida)

✅ Resuelto (29 jul 2026) — Alberto revocó la key vieja en n8n UI y generó una nueva; script
one-shot del Arquitecto la verificó contra la API (HTTP 200) ANTES de instalarla, la reemplazó
en Vercel (production+preview, rol de almacén — el Dashboard no la consume en código) y en el
`.env.local` del Arquitecto, todo vía portapapeles sin que el valor apareciera jamás en chat ni
en historial. El secret de GitHub Actions ya no existe (backup automático descontinuado ese
mismo día). Pendiente residual por laptop: los `.env.local` de las otras máquinas se actualizan
copiando de Vercel cuando toque.

## Monitor horario de actividad de Juan (rutina cloud) — RESUELTO POR DISEÑO (4 ago 2026)
Rutina `trig_013gQWu8gqfDh5c8QQWzTAbM` **apagada** por decisión de Alberto tras análisis: era
redundante con el barrido de arranque de sesión del Arquitecto (GitHub es el registro durable;
la rutina solo copiaba a un buzón que nadie leía antes de abrir sesión, y no podía leer HYL-WAI
—privado— con un PAT fine-grained scopeado a qualitas-issues; hacerla funcional exigía un token
clásico `repo` de amplio alcance). Valor residual descartado: notificación móvil (Alberto no la
usa) y captura forense de comentarios editados in situ. Issues de control #70/#71 cerrados.
Si algún día se quiere el "avísame al móvil": rearmarla con token clásico sabiendo el trade-off.

## Retirados de `CLAUDE.md` en la higiene del 16 ago 2026 (fase verde)

Verificados uno a uno contra su fuente antes de retirarlos — no de memoria:

| Ítem | Verdad comprobada |
|---|---|
| Bug #8 en Django (`HYL-WAI#70`) — «⏳ Pendiente externo — Juan» | **Cerrado el 2 jul 2026.** Llevaba mes y medio figurando como pendiente. Era el teléfono celular del asegurado que no se enviaba a la API SOAP de Quálitas |
| `fecha_inicio` en emisión (`HYL-WAI#114`) | **Cerrado el 24 jul 2026.** De aquella fila solo seguía vivo lo que ahora queda listado aparte: `qualitas-issues#66` y la promoción de n8n a PROD |
| Promoción STG → PROD (iniciativa) | **Cerrada el 13 ago.** Acta y lecciones en `docs/iniciativas/2026-08-12-plan-promocion-stg-a-prod-v2.md` |
| Plantilla Meta re-enganche fuera de ventana 24h | No retirada: estaba **duplicada**. Vive donde importa, en la iniciativa «Recordatorios» que bloquea |

**La lección, que es el motivo del protocolo:** un pendiente resuelto no se anuncia solo. Se queda
en el fichero pareciendo trabajo vivo hasta que alguien lo verifica, y mientras tanto ensucia cada
decisión que lo lee. Dos de estos llevaban meses. Detalle del método:
`docs/protocolos/higiene-claude-md.md`.
