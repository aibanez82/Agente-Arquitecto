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

## Qué falta para activarlo

Plan de implementación detallado (TDD, tarea por tarea): `docs/superpowers/plans/2026-06-30-n8n-workflow-backup.md`.

- [x] Diseño de matching de workflows: en vez de hardcodear IDs, el script busca por nombre
      exacto contra `GET /api/v1/workflows` — evita depender de IDs que podrían cambiar
- [ ] Agregar secret `N8N_API_KEY` en GitHub Actions del repo `Agente-Arquitecto` (Alberto, vía `gh secret set`)
- [ ] Escribir el script de fetch + selección por nombre + escritura de archivo
- [ ] Escribir `.github/workflows/backup-n8n.yml` (cron + workflow_dispatch, commit solo si `git status` detecta diff)
- [ ] Probar un ciclo completo: disparo manual → commit generado → diff correcto
- [ ] Re-exportar y commitear el estado actual (caso-001 y caso-002 ya aplicados en prod,
      el repo todavía no los refleja) — se resuelve solo en la primera corrida manual del
      script (ver pendiente #1 del 30 jun 2026)

Esto requiere acceso de escritura a GitHub Actions secrets, que Alberto debe hacer manualmente
(el Arquitecto no tiene acceso a esa UI). El Arquitecto redacta el script y el YAML.
