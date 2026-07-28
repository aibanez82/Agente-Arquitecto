# Revisión del Plan de arquitectura de funnel Fase 1 — HYL-WAI #135

**Fecha:** 27 jul 2026 (issue creado por Juan el 28 jul 03:55 UTC)
**Issue:** https://github.com/aguayo-co/HYL-WAI/issues/135 (asignado a `aibanez82`)
**Comentario de revisión publicado:** https://github.com/aguayo-co/HYL-WAI/issues/135#issuecomment-5099816758

## Qué es

Juan publicó la versión actualizada del "Plan de arquitectura de funnel de leads — Fase 1"
(`docs/plan-arquitectura-funnel-leads-fase-1.md` en su rama local de HYL-WAI, cuerpo completo
en el issue, ~57 KB) y pidió revisión formal a Alberto como responsable operativo de n8n.
**No autoriza nada ejecutable:** ni `dual`/`enforced`, ni migraciones, ni despliegues en PROD.
HYL-WAI #132 sigue siendo el bloqueante formal de `dual`.

Issues relacionados: #69, #122, #128, #130, #132.

## Idea central del plan

Separar dimensiones hoy mezcladas:

| Dimensión | Dónde vive |
|---|---|
| Etapa comercial | `Lead.estado` — estados nuevos `LEAD_CREADO → COTIZACION_GENERADA → DATOS_EMISION_EN_PROCESO → DATOS_EMISION_COMPLETADOS → POLIZA_EMITIDA → PAGO_PENDIENTE → PAGO_CONFIRMADO` (expand/contract, choices legacy conviven) |
| Resultado comercial | `Lead.situacion` = ABIERTO/GANADO/PERDIDO/DESCARTADO (nuevo, aditivo) |
| Historial auditable | `LeadFunnelEvent` — ledger idempotente por `event_id` UUID; servicio central `qualitas/lead_funnel.py` (n8n reporta hechos, Django decide transiciones) |
| Identidad de hilo | `conversation_id`/`session_id` (tuple exacto, fallo cerrado, nunca degradar a teléfono) |
| Control humano | Claims en dominio Dashboard (`dashboard_conversation_claims` evolucionado, con epoch/fencing) — ortogonal a fase y funnel |
| Pago | **observado** (redirect) vs **confirmado** (callback servidor, conciliación o manual auditado). Redirect nunca confirma |

Contrato n8n→Django: `POST /api/internal/n8n/lead-funnel-events/v1/` — n8n solo puede emitir
`datos_emision_iniciados`, `datos_personales/vehiculo/residencia_completados` y `lead_declinado`
(determinístico, nunca inferencia libre de la IA). Emisión tras persistir cada `grupoN`.

Tracks: **A** = hardening conversacional + `dual` (#132, camino crítico, casi todo lado
Alberto/Agente-n8n) · **B** = funnel Django (B0–B6, detrás de flags) · **C** = rollout de
identidad (STG shadow → E2E → STG dual → PROD shadow → PROD dual → enforced como iniciativa aparte).

## Veredicto del Arquitecto

Sólido y muy alineado con nuestras posiciones históricas:

- `completed` solo lo produce el sistema de pago — nuestro diagnóstico del Bug #7/Issue #69, ahora prerrequisito del track n8n.
- Redirect ≠ pago confirmado — la razón de ser del Agente Conciliación, reconocida como fuente autorizada.
- Los 7 checkpoints se conservan tal cual; `payment_link_sent` sigue desactivado; doble validación pre-envío (control humano, Metepec, lead cerrado).
- Rollback de identidad vuelve primero a `shadow`, nunca a `legacy`.
- §21.3 recoge la eliminación de defaults de tokens (Issue #130).

## Los 4 puntos planteados en el comentario (pendientes de respuesta de Juan)

1. **§15.2/§16 — Agente Conciliación como fuente `conciliation`:** ya opera en PROD (cron diario, tabla `conciliacion_pagos`); el reconciliador de Django debería leerla directamente como evidencia de `PAGO_CONFIRMADO`. La pieza ya existe, el plan no la nombra.
2. **§11.2 — filtro de horario ausente:** la cadena de elegibilidad de recordatorios valida la ventana de 24h de Meta pero no el horario permitido de envío (9am–8pm CDMX) — lección del casi-incidente del 19 jul.
3. **§12.6 — `event_id` estable en n8n:** el contrato exige el mismo `event_id` en reintentos, pero n8n no tiene hoy almacén para persistirlo (¿`captured_data`? ¿tabla propia?). Es LA pregunta técnica a resolver antes de comprometer la Fase B5.
4. **§12.1 + #130 — una sola ventana de rotación:** la credencial nueva del endpoint de funnel debe coordinarse con la rotación de `N8N_TOKEN` para no hacer dos cambios de secretos en n8n.

## Compromiso adquirido

Conformidad con los 12 puntos de §25 ("Puntos de revisión específicos para Alberto"),
a confirmar **uno a uno con evidencia como parte del cierre de #132** — que sigue siendo
el paso previo a cualquier trabajo de B5 (emisión de hitos desde n8n) en nuestro lado.
§24.2 nos asigna: port de #132 sobre export vivo, relay humano POST/idempotente, Metepec
exacto, dedupe por `wamid`, Payment exacto, sincronía raíz/`activeVersion`, E2E STG y
evidencia de rollback.

## Seguimiento

- #135 queda como issue de revisión del plan; seguimiento manual junto con #132 (ninguno de los dos aparece completo en el barrido automático — #135 sí está asignado, #132 no).
- Próximo movimiento nuestro: nada de B5 hasta cerrar Track A/#132. Las respuestas de Juan a los 4 puntos pueden alterar el diseño del endpoint y la ubicación del `event_id`.
