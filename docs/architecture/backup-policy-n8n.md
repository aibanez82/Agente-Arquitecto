# Política de backup de workflows n8n

> Diseño Arquitecto-IA-Qualitas. Origen: pendiente #2 del 30 jun 2026 ("diseñar política de
> backups para n8n antes de más cambios al system prompt"), tras aplicar los cambios de
> caso-001 y caso-002 al system prompt del nodo AI Agent directamente en producción.

## Problema

Alberto edita el `systemMessage` del nodo AI Agent (y otros nodos) directamente en la UI de
n8n producción (Hostinger). n8n community self-hosted **no tiene versionado nativo confiable**
de workflows. Si un cambio rompe la conversación, no hay forma de volver atrás salvo memoria
manual de lo que decía antes. El repo `Agente-Arquitecto` solo tiene el export más reciente
(`docs/n8n-workflows/`), actualizado de forma manual e irregular — el último commit es del
30 jun 2026, pero ya quedó desactualizado en cuanto se aplicaron caso-001 y caso-002.

## Diseño

**Principio:** git en este repo se convierte en el historial de versiones real de los
workflows. Cada snapshot es un commit diffable; el rollback es "copiar el JSON de un commit
anterior y reimportarlo en n8n UI".

### 1. Backup automático programado

- Script que llama a la n8n API (`GET /api/v1/workflows/{id}` con header `X-N8N-API-KEY`)
  para los 3 workflows productivos:
  - Bot principal WhatsApp
  - Payment Confirmation
  - Retomar Conversación
- Corre como **GitHub Action** en el repo `aibanez82/Agente-Arquitecto`, con cron diario
  (p. ej. 06:00 `America/Mexico_City`) + `workflow_dispatch` para disparo manual.
- Compara el JSON obtenido contra el archivo existente en `docs/n8n-workflows/`. Si hay
  diferencia, hace commit automático: `chore: backup automático workflow n8n <nombre> (YYYY-MM-DD)`.
- Si no hay diferencia, no genera commit (evita ruido en el historial).

### 2. Regla operativa — backup pre-cambio

Antes de aplicar cualquier cambio al system prompt o a la lógica de un nodo en n8n UI,
Alberto dispara el backup manualmente (`workflow_dispatch` de la Action, o corre el script
en local) **antes** de tocar nada en producción. Así siempre hay un punto de rollback
inmediatamente anterior a un cambio riesgoso, no solo el snapshot diario.

### 3. Requisitos de implementación

| Requisito | Detalle |
|---|---|
| Secret GitHub Actions | `N8N_API_KEY` — ya existe como env var en Vercel, replicar como secret del repo `Agente-Arquitecto` en GitHub (Settings → Secrets and variables → Actions) |
| Endpoint n8n API | `https://n8n.srv1325340.hstgr.cloud/api/v1/workflows/{id}` |
| IDs de los 3 workflows | Pendiente de obtener (`GET /api/v1/workflows` lista todos con su id) |
| Script | Node o bash simple: fetch → normalizar JSON → comparar contra archivo local → escribir si difiere |
| Archivo YAML del workflow | `.github/workflows/backup-n8n.yml` en este repo |

### 4. Rollback

Si un cambio en producción rompe la conversación:
1. Ubicar el commit anterior al cambio en `docs/n8n-workflows/<workflow>.json` (git log / diff).
2. Copiar ese JSON.
3. En n8n UI: import workflow from JSON (o reemplazar el nodo afectado si el rollback es parcial).

## Estado: implementado y activo (1 jul 2026)

Plan de implementación detallado (TDD, tarea por tarea): `docs/superpowers/plans/2026-06-30-n8n-workflow-backup.md`.

- [x] Diseño de matching de workflows por nombre exacto contra `GET /api/v1/workflows` (`scripts/n8n-backup/select-workflows.mjs`)
- [x] Secret `N8N_API_KEY` en GitHub Actions del repo `Agente-Arquitecto`
- [x] Script de fetch + selección por nombre + escritura de archivo (`scripts/n8n-backup/backup.mjs`)
- [x] `.github/workflows/backup-n8n.yml` (cron diario 06:00 CDMX + workflow_dispatch, commit solo si `git status` detecta diff)
- [x] Ciclo completo probado: disparo manual → commit generado → diff correcto
- [x] Re-exportado el estado con los cambios caso-001/caso-002 (se resolvió solo, en la primera corrida)

### Incidente resuelto — PII filtrada por la n8n API (1 jul 2026)

La primera corrida (commit `d3bbae4`) escribió al repo **público** el JSON crudo de
`GET /workflows/{id}`, que incluye `shared.project.projectRelations[].user` con nombre, email
y respuestas de encuesta de onboarding del dueño del workflow en n8n — datos que un export
manual desde la UI nunca trae. Fix en `scripts/n8n-backup/to-export-format.mjs`
(`toExportFormat()`): whitelist estricta de los campos que sí trae un export manual
(`name, nodes, pinData, connections, active, settings, versionId, meta, id, tags`) antes de
escribir cualquier archivo. Verificado en el commit `51b3238`: cero PII, diff de solo 15 líneas
de contenido real.

**El commit `d3bbae4` con la PII sigue en el historial público de GitHub** — decisión explícita
de Alberto (1 jul 2026) de no reescribir el historial, solo mitigar hacia adelante.

**Pendiente:** rotar `N8N_API_KEY` — el valor se pegó en texto plano en una sesión de chat el
30 jun 2026 antes de configurarse como secret. Revocar esa key en n8n UI (Settings → n8n API) y
generar una nueva, luego `gh secret set N8N_API_KEY --repo aibanez82/Agente-Arquitecto`.

**Regla para cualquier script futuro que lea de la n8n API:** nunca escribir la respuesta cruda
de `GET /workflows/{id}` a un archivo — siempre pasar por un whitelist de campos como
`toExportFormat()`.

## 🔴 Estado real (verificado 18 jul 2026): deshabilitado, no solo desactualizado

Alberto preguntó por el estado del deploy RAG y, al verificar, se encontró que el workflow lleva
sin correr desde el 6 jul — no era solo que nadie hiciera commit manual.

Verificado vía `gh api repos/aibanez82/Agente-Arquitecto/actions/workflows`: la Action está
**`disabled_manually`**, `updated_at: 2026-07-06T16:48:44-06:00`. Los 3 runs anteriores a esa
fecha (4, 5, 6 jul) fallaron con `401 {"message":"unauthorized"}` — la `N8N_API_KEY` vencida (la
misma pendiente de rotar arriba, nunca rotada). Alguien deshabilitó la Action manualmente el
mismo día del 3er fallo consecutivo, y nadie la volvió a activar desde entonces.

**Consecuencia:** el único contenido de `docs/n8n-workflows/` desde entonces es un snapshot
manual puntual (commit `901347b`, 13 jul, "antes del despliegue del 14 jul") — ya desactualizado
otra vez: 61 nodos contra los 84 reales en PROD hoy (migración RAG, M33, M36/M38, fallbacks de
media/`doc_chunks`, ninguno reflejado).

**Para reactivar:** (1) rotar `N8N_API_KEY` en n8n UI, (2) `gh secret set N8N_API_KEY --repo
aibanez82/Agente-Arquitecto` con el valor nuevo, (3) `gh workflow enable backup-n8n.yml --repo
aibanez82/Agente-Arquitecto`, (4) disparar un `workflow_dispatch` manual para refrescar el
snapshot ya mismo en vez de esperar al cron de las 06:00.
