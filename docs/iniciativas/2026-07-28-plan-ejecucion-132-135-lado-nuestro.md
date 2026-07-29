# Plan de ejecución — lo que nos toca de HYL-WAI #132 y #135

> Elaborado: 28 jul 2026. Fuentes: cuerpos y comentarios de `aguayo-co/HYL-WAI#132` y `#135`,
> `qualitas-issues#66` y `#67`, estado real de `origin/stg` de Agente-n8n.
> Este documento ordena SOLO el trabajo de nuestro lado (Alberto + agentes Nivel 3).
> El detalle técnico de cada fase vive en los issues; aquí está el orden, el reparto interno
> y los gates.

---

## Reparto final (corregido por el owner del proyecto, último comentario de #132)

| Lado | Alcance |
|---|---|
| Juan / HYL-WAI | SOLO Django: hardening en `fix/issue-132-whatsapp-dual-safe-port`, funnel B0–B4, contrato cruzado, criterios de aceptación. No toca `Agente-n8n`. |
| **Nosotros** | **TODO el desarrollo n8n de #132**: transform, tests n8n, composición/supersesión de `efcd374`, port sobre export vivo, deploy STG, sync Git. Además: evolución de `dashboard_conversation_claims` (Dashboard), contrato de `conciliacion_pagos` (Conciliación), outbox de funnel y filtro de horario lado n8n (#135). |

Decisiones ya registradas en #132: **ruta 2** (freeze de `origin/stg`; `efcd374` solo referencia,
la Fase 4 lo supersede contra `dashboard_conversation_claims`). E2E #114 validado con emisión
real (pólizas 7620099607/08). Fase 8 = `pin data + Execute Workflow`, etiquetada como
integración STG, no E2E Meta.

---

## Bloqueante transversal: incidente `qualitas-issues#67`

Workspace Anthropic al tope de gasto → **STG y PROD sin IA hasta 2026-08-01 00:00 UTC**,
salvo que Alberto suba el límite en la console de Anthropic. Bloquea el re-test de #66 y
toda prueba conversacional. **Decisión de Alberto: subir límite ahora o esperar al 1-ago.**
Todo lo no-conversacional de este plan (pasos 2, 3 y Fase 0–1 y 6 del port) NO está bloqueado.

---

## Paso 1 — Cerrar el freeze (qualitas-issues#66 → HYL-WAI#132)

Estado real: el refuerzo del límite 30 días YA está en `origin/stg` (`8950106`, toolDescription
de Issue Policy; el systemMessage ya lo tenía de #114) y aplicado al workflow vivo de STG.
HEAD actual de `origin/stg`: `2ede413` (los 2 commits post-fix son solo scripts/docs).

- [x] #67 cerrado 28-jul (Alberto subió el límite; verificado API 200 + bot PROD responde).
- [x] Re-test caso +49 en STG (28-jul): **FALLO** — el guard de prompt volvió a aceptar +49.
      Etapa 1 declarada insuficiente; etapa 2 (guard determinístico) va en Fase 2 del port.
      Evidencia en `qualitas-issues#66`. Hallazgo colateral: `qualitas-issues#68` (Intent Router
      rutea "tengo póliza con GNP" a kb_query → RAG responde sin contexto) — también al port.
- [x] **Freeze confirmado en HYL-WAI#132: SHA `2ede413`** (28-jul). `stg` congelada — no más push
      hasta que exista la rama del port. Reparto corregido acusado en el mismo comentario.
- [ ] `qualitas-issues#66` queda abierto hasta la etapa 2 (dentro del port).

Ejecuta: Arquitecto (comentarios) + Alberto (re-test manual por WhatsApp STG).

## Paso 2 — Contratos pendientes que Juan espera (no bloqueados, paralelos)

### 2a. Contrato de `conciliacion_pagos` — ✅ publicado en #135 (28-jul)
Regla del activador verificada contra PROD: ordinal `1-` + `tipo_movimiento='POLIZA'` +
`estado='PAGADO'` + `fecha_pago IS NOT NULL` (22/22 pagados cumplen). Caso borde: endosos
`Adicional` con su propio `1-` (póliza 7620098864) → el reconciliador los reporta como conflicto.
Cron GH Actions 06:00 CDMX; reconciliador ≥13:00 UTC + gate por `max(verificado_en)`.
✅ `conciliacion_pagos` creada en STG (28-jul) con fixture sintético de los 4 casos del contrato
(versionado en `Agente-Conciliacion:fixtures/stg-conciliacion-pagos-fixture.sql`, confirmado a
Juan en #135). GRANT = no-op en STG mono-rol; real en PROD con credenciales dedicadas.

### 2b. Evolución de `dashboard_conversation_claims` — ✅ handoff entregado (28-jul)
Verificado en STG: tabla existe con esquema mínimo (sin control_id/epoch/state, session_id NULL,
6 filas); en PROD no existe. Handoff completo (DDL aditiva, backfill, índices de control activo
único, grants, endpoints Tomar/Liberar con fencing, doble escritura con `human_takeover`) en
`~/claude-projects/Dashboard_SeguroAuto/handoffs/2026-07-28-evolucion-dashboard-conversation-claims.md`
(rama `stg` del repo Dashboard). ✅ **Ejecutado y certificado (28-jul):** esquema completo con
fencing en STG, zombis saneados, endpoints por `control_id`+`epoch`; corrección del Arquitecto
(released_at en revoked + drop índice legacy). STG es mono-rol → grants = no-op hasta credenciales
dedicadas (ventana #130). Gate de Fase 4 confirmado a Juan en #132. Hallazgo: `human_takeover` lo
escribe solo n8n vía GET por teléfono → evidencia en `qualitas-issues#57`, se resuelve en Fase 4.

## Paso 3 — Port dual-safe (#132) — Agente-n8n, handoff del Arquitecto

Sobre el freeze `2ede413`. Orden = fases del issue; lo no-conversacional puede arrancar ya.

- **Fase 0:** ✅ (28-jul) rama `feature/issue-132-port-dual-safe` desde `2ede413`; exports
  frescos de los 6 workflows vivos, drift check LIMPIO (verificado independientemente por el
  Arquitecto, 6/6), snapshot `docs/2026-07-28-fase0-snapshot-pre-port.md` (commit `b829b53`).
  Main 118 nodos / Payment 6, webhookIds y credenciales registrados.
- **Fase 1:** 🟡 parcial certificada (28-jul, commit `4db0f02`, 22/22 tests verificados por el
  Arquitecto): infra completa del transform (fingerprint/precondiciones/allowlist-diff/
  idempotencia) + garantía verificada de flags en la lógica actual. **Bloqueo:** `75e1de3` y
  `efcd374` no existen en ninguna ref remota ni clon de esta máquina (solo clones locales de
  otra máquina) → el port real de `Resolve Session` (118→126) espera la referencia. **Plan C activado (28-jul):**
  búsqueda de clones agotada en todas las máquinas y Juan sin responder → se reconstruye desde
  la spec (handoff `2026-07-28-fase1c-resolve-session-desde-spec.md`; anunciado en #132 — el
  material de Juan, si llega, pasa a ser contraste de revisión).
- **Fase 1-C ✅ (28-jul, `82c01c4`):** Resolve Session portado desde la spec — 118→123 nodos
  (+5 justificados), 62/62 tests en ambos flavors **reproducidos por el Arquitecto**, diff
  canónico limpio. 5 decisiones de diseño documentadas en #132 para contraste de Juan.
- **Fase 2 ✅ (28-jul, `5d7c685`):** guards y folio — **78/78 reproducidos por el Arquitecto en
  ambos flavors** (actual: 75 pass + 3 skip; objetivo: 77 pass + 1 skip). Guard 30 días (etapa 2
  de #66): `Issue Policy` convertido a `toolWorkflow` → sub-workflow `Issue Policy Guard (STG)`
  (5 nodos, fuera de Main; Main sigue 118→123), "hoy" siempre CDMX en código, el jsCode del nodo
  es literalmente el `fn.toString()` de las funciones testeadas offline. #68 dos capas: ejemplo
  GNP en Intent Router (validación conversacional → Fase 8) + contexto de sesión y regla 13 en
  RAG IA Agent (cero nodos nuevos). Folio: consumido como selección, nunca llega crudo al agente;
  entrada con pinta de folio pero ajena a este teléfono = terminal. ⚠️ Para contraste de Juan: el
  shape del error de negocio del guard es aproximación razonada (nunca se capturó un body real de
  Django). Reporte: `Agente-n8n:docs/2026-07-28-fase2-reporte-guards-y-folio.md`. `#66` sigue
  abierto hasta deploy (Fase 7) + re-test.
- **Fase 3 ✅ (28-jul, `1b26d79`):** Payment exacto — **111/111 reproducidos por el Arquitecto
  en ambos flavors** (actual: 108 pass + 3 skip; objetivo: 110 pass + 1 skip) + verificación
  estructural independiente (6→6, los 3 mutados declarados, 3 byte-idénticos, webhookIds/
  credenciales/conexiones intactos). SQL: una sola sentencia `WITH…UPDATE…RETURNING` con `ctid`,
  tiers que estructuralmente no degradan, sin fallback por teléfono solo, 4 outcomes, guard
  `status IS DISTINCT FROM 'completed'` (aprobado: un retry no pisa `closed_at`), outcome final
  derivado del `updated_count` real (perdedor de carrera reporta `no_candidate`, nunca `updated`
  falso). Notificación WA se envía siempre (default acordado; Django no reintenta webhooks de
  pago en la práctica). Reporte: `Agente-n8n:docs/2026-07-28-fase3-reporte-port-issue-132.md`.
  **Siguiente en la rama:** correcciones de contrato cruzado C1-C3 (`49049ad`, sin empezar) —
  C1 bloqueante para Fase 7.
- **Correcciones de contrato cruzado (28-jul, handoff `2026-07-28-correcciones-contrato-cruzado-django.md`,
  commit `49049ad` — ejecutar tras Fase 3):** auditoría del Arquitecto sobre el Django real de
  `origin/stg` HYL-WAI. **C1 BLOQUEANTE Fase 7:** `m:` del payload v2 es `message_token`
  (`secrets.token_hex(6)`) independiente del hex de `cv:` — nuestro check de igualdad habría
  matado todo clic v2 en `dual`; se cambia a validación de formato. **C2:** shape real del error
  de negocio encontrado en `views.py` (`status/code/field/msg/details.reason`) — el guard 30d se
  alinea. **C3 menor:** v1 real lleva `l:` y `m:`. Confirmado además el body real de Payment
  (sin `session_id` hoy — la prioridad queda inerte hasta que Juan lo añada; `transaction_id`
  hardcodeado `txn_test_001` lado Juan). Contraste publicado en #132 + propuesta de checkpoint
  de contrato cruzado pre-Fase 7. **✅ C1-C3 aplicadas y certificadas (28-jul, `9a27ef5`;
  112 tests: actual 109+3 skip, objetivo 111+1 skip, 0 fallos, reproducidos por el Arquitecto;
  verificado en el output generado: check de igualdad `m:` eliminado → formato 12-hex, shape
  `status/code/field` en el guard). C3 documentada como no viable sin mutar `Session Context
  Builder` congelado (v1 no expone `leadId`) — aceptado.**
- **Fase 4:** 🔵 handoff entregado (28-jul, `Agente-n8n:handoffs/2026-07-28-fase4-atencion-humana-dual-safe.md`,
  commit `d3d27c9`; ejecutar tras C1-C3) — Atención Humana dual-safe contra
  `dashboard_conversation_claims` (gate paso 2b ✅). 3 webhooks GET sin auth → POST+headerAuth
  (mismos webhookIds), mutación solo por `session_id` con claim validado (control_id+epoch),
  liberar con fencing anti-stale, envío §10.4 (teléfono desde la fila, ledger
  `dashboard_outbound_dispatch` con reserva pre-Meta, `provider_message_id`, historial canónico
  con `sent_by=human_agent`), dedupe inbound por `wamid` (única mutación de Main), precedencia
  humano/Metepec/terminal. Resuelve `qualitas-issues#57`. Ventana Fase 7 necesitará: credencial
  headerAuth nueva + secreto al Dashboard + tabla en STG.
- **Fase 5:** 🔵 handoff entregado (28-jul, `Agente-n8n:handoffs/2026-07-28-fase5-metepec-dual-safe.md`,
  commit `87ef6eb`; ejecutar tras Fase 4) — Metepec dual-safe. Verificado contra exports de
  Fase 0: la derivación ya marca por `session_id`; el infractor es `Metepec Liberar` (GET sin
  auth, limpia por teléfono → todas las sesiones). Liberación POST+headerAuth (credencial
  compartida con Fase 4) por `session_id` exacto con opcionales compatibles y 521/52 como
  verificación secundaria; fencing con columna nueva `metepec_derived_at` (aditiva, dominio
  nuestro); historial de la rama `metepec_derived` de Main bajo `session_id` canónico.
  Suma a la ventana Fase 7: `ALTER TABLE` de la columna.
- **Fase 3-B:** 🔵 handoff entregado (28-jul noche, `2026-07-28-fase3b-contrato-payment-v1-y-advisory-locks.md`,
  commit `b4bc3f5`; T3 se incorpora en Fase 4/5 si siguen abiertas, resto tras Fase 5). Origen:
  **checkpoint Django de Juan en #132 (22:12)** — su hardening terminado (PR oscuro, sin deploy),
  validó su payload contra nuestro código real de `1b26d79` y **confirmó `m:` aleatorio (C1
  correcta) y la secuencia del índice telefónico (nuestra propuesta adoptada)**. Sus 3 gates
  aceptados: dedupe Payment por `event_id` (contrato v1: `session_id`/`event_id`/`identity_status`,
  `amount` string; replay → `duplicate` sin re-envío WA; legacy compatible), máscara de teléfono
  en logs, `pg_advisory_xact_lock(hashtext(canonical_phone))` en todos los writers n8n
  (Chat Memory queda sin lock — flag al checkpoint). ⚠️ Escalado a Alberto: su readiness
  rechazará el rol compartido de STG para `conciliacion_pagos` → rol read-only dedicado
  (#129/#130) pasa a prerrequisito real del E2E.
- **Fase 6:** 🟡 adelanto certificado (28-jul, commit `be4bd50`, 33/33): harness PG17 local con
  DDL real de STG, fixtures, concurrencia determinística y baseline de caracterización.
  **Inventario §9.1 completado:** `idx_whatsapp_sessions_phone_number UNIQUE` es el único
  bloqueador físico del multi-sesión (los índices objetivo ya existen en STG); retiro propuesto
  en la ventana Fase 7→8 con Django en `shadow` (comentado en #132). Bug 521/52 confirmado con
  datos. Suites completas cuando existan Fases 2-5.
  **Fase 6b (28-jul, `fbf02ca`):** dos sabores de schema — `actual/` (DDL real STG) y `objetivo/`
  (sin el índice único de teléfono; diff verificado por el Arquitecto: es el ÚNICO cambio),
  fixture "dos sesiones mismo teléfono" ejercitando la desambiguación real (match_count=2),
  detección de flavor en runtime vía pg_indexes. 34 tests (33 pass + 1 skip por flavor).
- **Fase 7:** re-descarga inmediata pre-deploy, transform sobre contenido vivo, PUT
  `{name, nodes, connections, settings}`, verificar webhookIds intactos, GET posterior → git.
  Main y Payment coordinados, sin ventana larga de contratos distintos.
- **Fase 8:** integración pinneada STG (matriz de §19; reportar como integración, no E2E) →
  sign-off conjunto en #132 → **Juan** pasa Django STG a `dual`. E2E de trigger Meta real en
  ventana controlada/app aislada queda como gate antes de PROD.

Certificación al cierre: los **16 puntos de §25 de #135**, uno a uno con evidencia (compromiso
ya adquirido en el comentario de revisión de #135).

## Paso 4 — Compromisos de #135 que se activan después del cierre de #132

- **Outbox n8n (`n8n_funnel_event_outbox`, §12.7):** ledger durable con
  `UNIQUE(session_id, event_type)`, reserva transaccional junto al guardado de
  `grupo1/2/3`, worker de entrega con `event_id` estable. Precondición de B5; solo sobre el
  workflow ya endurecido.
- **B5:** emisión de hitos n8n→Django (`datos_emision_iniciados`, bloques, `lead_declinado`)
  contra `POST /api/internal/n8n/lead-funnel-events/v1/`.
- **Horario 9:00–20:00 CDMX:** Juan lo mete en los motores Django; nosotros añadimos la
  re-validación lado n8n antes de Meta (proactive/Retomar Conversación — ya decidido desde el
  casi-incidente del 19 jul, sin construir). Fuera de horario se difiere sin consumir intento.
- **`N8N_FUNNEL_EVENTS_TOKEN`:** credencial nueva y distinta; se provisiona en la ventana de
  #130 que coordina Juan (junto con quitar el default de `qualitas/views.py:1291` y rotar
  `N8N_TOKEN`). No usar el token expuesto para el contrato nuevo.

---

## Secuencia resumida

```
(#67: decidir límite Anthropic — Alberto)
Paso 2a contrato conciliacion_pagos  ┐ paralelos, sin bloqueo
Paso 2b claims Dashboard + grants    ┘
Paso 1 re-test +49 → freeze 2ede413 en #132   (necesita IA → #67)
Paso 3 Fases 0–1, 6 (offline)                  (pueden arrancar ya)
Paso 3 Fases 2–5 → 7 (deploy STG) → 8 (integración pinneada)
sign-off conjunto → Django STG dual (Juan)
Paso 4: outbox + B5 + horario n8n + token funnel (ventana #130)
E2E Meta real en ventana controlada → PROD (aprobación posterior)
```

## Reparto interno (Nivel 3, vía handoffs del Arquitecto)

| Tarea | Ejecutor |
|---|---|
| Comentarios/contratos en #132/#135, freeze, certificación §25 | Arquitecto |
| Re-test +49, decisión límite Anthropic, importes/ventanas | Alberto |
| Port completo (Fases 0–8), guard 30 días, outbox funnel, horario n8n | Agente n8n |
| Evolución `dashboard_conversation_claims` + grants | Agente Dashboard |
| Semántica recibo activador en `conciliacion_pagos` | Agente Conciliación |
| Matriz de integración pinneada STG (§19) | Agente QA |
