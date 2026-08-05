# Runbook — acreditación y checkpoint STG de S1 (lado Alberto)

> **5 ago 2026, ~00:20 CDMX.** Preparado en stand-down (DOCS-ONLY) para ejecutar en minutos
> cuando el liderazgo dé el gate en `#140`. Fuente: contrato congelado
> `aef501f:docs/contracts/s1-dual-stg-v1.1.md` §9 (transición/rollback), §10.2 (procedimiento
> STG, 13 pasos), §10.3 (fixtures), §10.4 (consultas) — citado, no sustituido: **ante cualquier
> diferencia prevalece el contrato**. Cada paso vivo requiere su propio checkpoint/GO; este
> runbook NO autoriza nada.

## Estado de partida (consolidado `#132 c.5187384874`)

Acreditados e inmóviles: Seguroauto `78970ec` · Dashboard `c911d4c` (`feature/s1-v11-dashboard`)
· Agente-n8n `fb98f24` (`feature/s1-dual-stg`). Smoke integrado PASS, `outbound_real=0`.
Pendiente ÚNICO: decisión humana del gate en `#140`.

## Secuencia (orden §9; pasos nuestros marcados 🔵, de Juan 🟠, del operador 🟢)

| # | Acción | Actor | Requiere |
|---|---|---|---|
| 0 | Decisión del gate | liderazgo `#140` | — |
| 1 | Checkpoint de esquema (solo si el gate lo ordena; DDL aditivo) | 🟠 Juan | checkpoint propio |
| 2 | **Importar a n8n STG los workflows efectivos del build `fb98f24`** (Main, Payment, Retomar) y acreditar root/`activeVersion` (§6.3.10) | 🔵 Alberto (exports ya versionados en la rama; import manual, política vigente) | autorización separada |
| 3 | Deploy Django compatible, `WHATSAPP_CONVERSATION_ID_MODE=shadow` intacto | 🟠 Juan | checkpoint |
| 4 | **Acreditar POR LECTURA `S1_DASHBOARD_MODE=blocked` en Vercel (Preview `stg`)** y desplegar el candidato `c911d4c` bloqueado | 🔵 Alberto | checkpoint |
| 5 | **Controles negativos**: GET sensible→503 `s1_dashboard_blocked`, POST proactivo→403 `s1_proactive_blocked`, cero DB/red | 🔵/🟢 | mismo checkpoint |
| 6 | **`S1_DASHBOARD_MODE=read_only`** con el comando exacto del checkpoint; GET sintético OK, POST sigue 403 | 🔵 Alberto | checkpoint separado |
| 7 | Preflight shadow (`--expect-mode shadow`, exit 0) + control negativo del validador (`--expect-mode dual`, exit ≠0) | 🟠 Juan (heroku run) | — |
| 8 | Snapshots read-only A/B (§10.4: sesiones, historial, ledger por `PAYMENT_EVENT_ID`) | 🟢 operador | — |
| 9 | **`heroku config:set WHATSAPP_CONVERSATION_ID_MODE=dual --app hyl-wai-stg`** + preflight dual exit 0, Dashboard sigue `read_only` | 🟠 Juan | checkpoint propio + GO |
| 10 | **Corrida ÚNICA con `run-id`**: `S1-F1`→`S1-F4` por pin data + Execute Workflow (§10.3); tras cada fixture, releer Postgres + detalle n8n con verificador distinto | 🟢 operador | run-id publicado |
| 11 | Observación F1/F2: GET read-only `/api/db-leads`, extraer SOLO A/B; sin claim/toma/envío | 🟢 operador | — |
| 12 | PASS → estado final: Django `dual` + Dashboard `read_only`. FAIL/STOP/duda → **rollback §9** y cierre sin reintento | todos | — |

**Outbound esperado por fixture (§10.2.12): F1=2 · F2=1 · F3=1 · F4=0** — solo al alias
allowlisted; la evidencia sale del detalle GET de la ejecución n8n, nunca del autorreporte.

## Rollback exacto (§9, memorizar ANTES de empezar)

1. `S1_DASHBOARD_MODE=blocked` en el Preview STG → verificar 503/403 con cero DB/red;
2. si Django llegó a `dual`: `heroku config:set WHATSAPP_CONVERSATION_ID_MODE=shadow --app hyl-wai-stg` → `observed_mode=shadow`;
3. conservar candidato en `blocked`, Retomar compatible, DDL aditivo y datos v2 (NO restaurar `e50e3ada`);
4. inventariar y cerrar sin reintento. Repetición = checkpoint + autorización + `run-id` nuevos.
   Antes de activar: acreditar que ambas palancas de rollback existen y apuntan a STG.

## Qué publica el checkpoint de Juan (esperar, no inventar)

IDs sintéticos (`QUOTE/LEAD/CONVERSATION` A y B, `PHONE_ALLOWLISTED`, `PAYMENT_EVENT_ID`),
aliases redactados de destinos allowlisted (valores reales por canal autorizado, jamás en
GitHub), comandos exactos de cambio de modo, y el `run-id`.

## Nuestro pre-trabajo YA listo / notas

- Candidatos inmóviles con CI verde: nada que construir.
- **Operador de fixtures (§6.5)**: propuesta — el **Agente QA** (`Agente_QATest_Qualitas`), cuyo
  rol es exactamente E2E en STG vía pin data + Execute Workflow sin pasar por la landing.
  Decisión de Alberto+gate; alternativa: Alberto manual con este runbook.
- Vercel: cambios de `S1_DASHBOARD_MODE` SOLO en environment del Preview `stg` (convención:
  Production/Preview, nunca Development). El deploy del candidato es acción viva: nada se
  ejecuta sin su checkpoint.
- Gotcha conocido de STG: 1 solo trigger real de Meta por Facebook App — por eso TODO va por
  pin data (memoria `project_staging_environment_n8n`).
- Los registros de la corrida NO se borran (§10.2.13); limpieza = acción separada futura.
