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

- [ ] Re-test caso +49 días ("15 de septiembre") en STG — **bloqueado por #67**.
- [ ] Si pasa: comentar en HYL-WAI#132 el **SHA de freeze = `2ede413`** y declarar `stg` congelada
      (no más push hasta que exista la rama del port).
- [ ] Cerrar etapa 1 de `qualitas-issues#66` (etapa 2 = guard determinístico, va dentro del port, Fase 2).
- [ ] Acusar recibo en #132 de la corrección de reparto (todo n8n nuestro).

Ejecuta: Arquitecto (comentarios) + Alberto (re-test manual por WhatsApp STG).

## Paso 2 — Contratos pendientes que Juan espera (no bloqueados, paralelos)

### 2a. Contrato de `conciliacion_pagos` (para #129 / §15.2 de #135)
Juan necesita saber cómo identifica la tabla el **recibo inicial/activador** (`numero_recibo`,
`tipo_movimiento` u otra regla) antes de escribir el reconciliador, y coordinar su ejecución
después del cron Q360.
- [ ] Arquitecto revisa esquema real de `conciliacion_pagos` + `docs/architecture/estatus-pago-qualitas.md`
      y el protocolo del Agente Conciliación; si falta la semántica de recibo, handoff al Agente Conciliación.
- [ ] Publicar el contrato en #135 (columnas, regla del recibo activador, hora del cron para
      encadenar el reconciliador).

### 2b. Evolución de `dashboard_conversation_claims` (gate de Fase 4 del port)
#128/#135 fijan: Dashboard escribe, n8n lee, Django lee (schedulers). Contrato mínimo §10.2:
`control_id`, `lead_id`, `session_id` exacto, `conversation_id`, cotización, owner, `epoch`
monotónico, `state`, timestamps. Juan preguntó quién coordina: **nosotros** (Agente Dashboard).
- [ ] Arquitecto redacta handoff al Agente Dashboard: DDL de evolución del claim + constraints
      (un control activo por hilo) + `GRANT SELECT` a los roles de n8n y Django (primero STG).
- [ ] Confirmar schema/grants en #132/#135 — es precondición de los tests SQL de la Fase 4.

## Paso 3 — Port dual-safe (#132) — Agente-n8n, handoff del Arquitecto

Sobre el freeze `2ede413`. Orden = fases del issue; lo no-conversacional puede arrancar ya.

- **Fase 0:** export fresco de los 4 workflows vivos STG (Main, Payment, Atención Humana,
  Metepec), drift check contra git, registrar hashes/IDs/webhookIds/credenciales. Crear rama
  del port desde el freeze. *(no bloqueada por #67)*
- **Fase 1:** transform reproducible con precondiciones (aborta si cambió lo que va a tocar);
  adaptar `RESOLVE_SESSION_QUERY` conservando `human_takeover` y `metepec_derived`;
  expectativas Main 118→126 nodos, Payment 6→6; usar `75e1de3` y `efcd374` SOLO como referencia.
- **Fase 2:** Main — identidad/afinidad estrictas, fail-closed, `affinity_updated === 1`,
  folio exacto. Incluye el **guard determinístico de 30 días** (etapa 2 de #66).
- **Fase 3:** Payment exacto (prioridad `conversation_id → session_id → cotización+teléfono`,
  `candidate_count = 1`, siempre `outcome`/`updated_count`).
- **Fase 4:** Atención Humana dual-safe contra `dashboard_conversation_claims` (gate: paso 2b).
  POST + headerAuth, fencing/epoch, idempotencia durable pre-Meta, historial bajo `session_id`
  canónico, dedupe por `wamid`, retirar GETs mutables.
- **Fase 5:** Metepec dual-safe (liberación POST autenticada por `session_id` exacto).
- **Fase 6:** suites offline + Postgres 17 local con concurrencia. *(no bloqueada por #67)*
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
