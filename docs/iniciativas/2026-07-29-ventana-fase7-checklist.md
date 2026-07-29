# Ventana Fase 7 — checklist consolidado (port HYL-WAI#132)

> Consolidado por el Arquitecto la noche del 28-29 jul 2026, al cierre de Fases 4/5/3-B
> (todas ejecutadas y certificadas — ver `2026-07-28-plan-ejecucion-132-135-lado-nuestro.md`).
> La Fase 7 es la ÚNICA fase que toca sistemas reales. Requiere a Alberto presente y
> coordinación con Juan. Nada de esta lista se ejecuta sin luz verde explícita.

## Artefactos listos (rama `feature/issue-132-port-dual-safe` de Agente-n8n, HEAD `18a154f`)

1. **Script de schema STG** — `scripts/create-fase3b-payment-events-schema-stg.py`
   (dry-run por defecto, `--go` para aplicar; idempotente). Crea `n8n_payment_events`
   (event_id uuid PK, session_id, outcome, processed_at) Y el
   `ALTER TABLE whatsapp_sessions ADD COLUMN IF NOT EXISTS metepec_derived_at timestamptz`
   de Fase 5 — una sola corrida cubre ambos. Sin backfill necesario.
2. **JSONs transformados** (build del transform, ambos verificados por suites):
   Main (125 nodos), Payment (6), Atención Humana (19), Metepec Liberar (2),
   Metepec Registrar (7). Todos cambian respecto a lo importado hoy en STG.
3. **Suites**: 217 tests, 0 fallos ambos flavors, certificadas por el Arquitecto.

## Pasos de la ventana (orden propuesto)

1. Crear en n8n STG la credencial `httpHeaderAuth` **"Atencion Humana Header Auth STG"**
   (UN solo secreto: cubre los 3 webhooks de Atención Humana + `metepec-liberar`).
   Decisión pendiente del Arquitecto/Alberto: nombre del header (propuesta: `X-Operator-Auth`).
2. Provisionar el mismo secreto al Dashboard (env var en Vercel, Preview+Production cuando
   toque PROD; en la ventana STG solo el entorno que corresponda).
3. Correr el script de schema con `--go` contra STG.
4. Importar los 5 JSONs transformados en n8n STG (export previo de seguridad, como siempre).
5. Desplegar la rama del Dashboard con las llamadas POST+header (preparada la noche del 28,
   ver abajo) — SOLO tras 1-4.
6. E2E de humo: tomar/enviar/liberar conversación desde el Dashboard, derivar/liberar Metepec,
   replay de Payment con mismo `event_id` (→ `duplicate`, sin re-envío WA).

## Lado Dashboard (✅ preparado la noche del 28-29 jul, SIN merge)

Rama **`fix/operator-webhooks-post-headerauth`** (commit `7273605`, base `origin/main`
`60ec67b`, build en verde), handoff con la tabla de contrato completa en
`Dashboard:handoffs/2026-07-29-fase7-webhooks-post-headerauth.md`. Clon local:
`~/claude-projects/Dashboard_SeguroAuto` (ojo: carpeta ≠ nombre del repo).

- **Hallazgo del fork:** en `main` el Dashboard NO llamaba a ningún webhook de atención humana —
  el claim era solo BD, nadie seteaba `human_takeover` desde el Dashboard, y liberar solo ponía
  `released_at` sin `state='released'` (n8n valida claims por `state`). Ambos gaps cerrados en
  la rama.
- Cliente compartido tolerante a entorno sin configurar (Preview no rompe); `operator-send` con
  `idempotency_key` + auditoría; `metepec-liberar` como endpoint listo sin UI.
- **Env vars nuevas en Vercel:** `N8N_OPERATOR_WEBHOOK_BASE_URL` + `N8N_OPERATOR_WEBHOOK_SECRET`.
- **Supuesto clave:** header `X-Operator-Auth` — la credencial n8n de la ventana debe crearse
  con ese nombre exacto (o cambiar la constante del cliente).
- **NO mergear hasta la ventana** (contra el n8n actual rompería los botones de operador);
  verificar antes que `dashboard_conversation_claims` de PROD tiene `control_id/epoch/state`.

## Agenda del checkpoint con Juan (previo a la ventana)

1. **Canónico de `hashtext()`**: nuestro supuesto verificado con test (forma `52`, 12 dígitos,
   igualdad SQL/JS). Contrastar con su helper — si difiere en un carácter, los locks no se cruzan.
2. **`Postgres Chat Memory` escribe SIN lock** (LangChain, no modificable) — su archivado/reset
   debe tolerarlo. También `Update Activity` (legacy, solo `last_activity`) quedó sin lock;
   si lo quiere lockear, es fase nueva.
3. **§10.6**: formalizar (o no) la precedencia como regla explícita; y su regla de "no
   simultanear control humano y Metepec sin transferencia explícita" — sin implementar por
   nadie, decisión de producto.
4. **Retiro del índice único `idx_whatsapp_sessions_phone_number`** — ventana 7→8 con Django
   en `shadow` (ya comentado en #132).
5. **Su Payment v1 hacia STG** (event_id/session_id reales) — nuestro parser ya acepta ambos
   formatos, puede desplegar a su ritmo.
6. **Desacuerdo suave de 3-B**: el lock del ledger `dashboard_outbound_dispatch` (tabla que
   Django no toca) se mantuvo por uniformidad — removible en mutación pequeña si prefiere.
7. **Prerrequisito E2E**: rol read-only dedicado para `conciliacion_pagos` (#129/#130).
8. **Rotación `N8N_TOKEN`** (#130) — coordinar en la misma ventana si es posible.
