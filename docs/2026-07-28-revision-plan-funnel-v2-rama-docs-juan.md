# Revisión — plan funnel v2 de Juan (rama `docs/actualizar-plan-funnel-conversation-handoff`)

> Arquitecto, 28 jul 2026 (noche). Juan reescribió `docs/plan-arquitectura-funnel-leads-fase-1.md`
> (+1.499/-671, 3 commits 04:35–05:10 UTC) incorporando nuestros 4 puntos aceptados en #135.
> **Ojo con el timestamp:** el documento es ANTERIOR a casi todo lo que pasó hoy en el hilo de
> #132 (freeze 05:40, claims evolucionada 06:22, plan C, Fases 1-2, auditoría de `m:` 19:59).
> El hilo de #132 es el acuerdo operativo; donde el doc y el hilo difieren, manda el hilo.

## Qué es ya obsoleto del doc (superseded por el hilo de #132 del mismo día)

- §25.12 / Track A.1 "E2E n8n de #114 antes del freeze" → Juan mismo lo dio por CERRADO (04:37)
  y confirmó el freeze `2ede413` (05:40+).
- Track A.2 "decidir efcd374" → decidido (ruta 2, 04:54–05:07).
- Track A.3 "evolucionar claims + grants" → hecho y verificado (06:22).
- §15.2 "confirmar la señal del recibo activador de `conciliacion_pagos`" → la regla quedó
  publicada y verificada contra PROD en nuestros comentarios de #135 (05:42 y 16:09), ambos
  POSTERIORES a su doc. Pendiente solo su acuse.

## Novedades REALES para nuestro lado (no estaban en nuestro plan)

1. **§10.4 — contrato detallado del relay humano (input directo para el handoff de Fase 4):**
   endpoint único n8n `POST /webhook/atencion-humana-enviar` con `headerAuth` dedicado; payload
   `{control_id, owner_id, epoch, session_id, conversation_id, cotizacion_id, idempotency_key,
   message}`; n8n valida control+fencing, **resuelve el teléfono desde `whatsapp_sessions`**
   (nunca confía en el del cliente), reserva `idempotency_key` en ledger durable ANTES de Meta,
   guarda `provider_message_id`, historial bajo `session_id` canónico con `type="ai"` +
   metadata `sent_by=human_agent`. Recomienda ledger `dashboard_outbound_dispatch` (decisión
   abierta Dashboard/nosotros).
2. **§14.4 — `/api/emitir-externo/` evoluciona** (aditivo, lado Juan) para recibir
   `conversation_id`, `session_id`, `cotizacion_id`, `lead_id` y auth dedicada → **nuestro Main
   deberá enviar la tupla completa** al emitir. Añadir al contrato del port (ventana Fase 7-8 o
   posterior, coordinado).
3. **§12 — detalle fino del contrato de hitos** (para Paso 4/B5): allowlist de eventos n8n
   (`datos_emision_iniciados`, `datos_personales_completados`, `datos_vehiculo_completados`,
   `datos_residencia_completados`, `lead_declinado`), `datos_emision_validados` NO lo declara
   n8n, `source` lo infiere Django por credencial, respuestas HTTP con **409 identidad
   contradictoria sin fallback** y **422 evidencia insuficiente**, reserva transaccional
   hito+grupo, `lead_declinado` solo determinístico con razón allowlisted.
4. **§15.5 — confirma que Juan añadirá `session_id` (y `conversation_id`) al payload de
   Payment** — exactamente lo que su lado debía aportar según nuestra Fase 3; la prioridad de
   resolución del doc coincide con nuestro handoff.
5. **§17.2 — inventariar valores legacy** de estatus (`PRIMER_PAGO_APROBADO`,
   `PAGO_TOTAL_COMPLETADO`) en el esquema externo; y §9.1 reitera el retiro del índice único de
   teléfono ("la migración 0033 no basta") — coherente con nuestra propuesta §9.1 del 16:01,
   que sigue esperando su confirmación de secuencia.
6. **§25 — los 16 puntos de confirmación** son los mismos que ya asumimos como certificación de
   cierre; sin cambios.

## Tensiones (ninguna contradicción con lo construido)

- El doc no conoce la semántica real de `m:` (es anterior a nuestra auditoría); su §9.2 es
  genérico y compatible con la corrección C1.
- `conciliacion_pagos`: el doc deja "abierta" la regla del activador que ya cerramos — resolver
  en el checkpoint de contrato cruzado (propuesto en #132, 19:59), no reabrir.
- Reconciliador: el doc omite el ≥13:00 UTC + gate `max(verificado_en)` ya acordados — idem,
  checkpoint.

## Acciones derivadas

- [ ] Incorporar §10.4 al futuro handoff de Fase 4 (relay humano) — el contrato ya no hay que
      inventarlo, está escrito.
- [ ] Añadir §14.4 (tupla completa en `/api/emitir-externo/`) a la lista de puntos del
      checkpoint de contrato cruzado pre-Fase 7.
- [ ] Cuando Juan responda al checkpoint: pedir acuse de la regla del activador ya publicada.
