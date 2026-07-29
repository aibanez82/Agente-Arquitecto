# Reporte para Juan — estado del lado n8n de HYL-WAI#132 (28 jul 2026, noche)

> Del Arquitecto-IA-Qualitas. Autocontenido para pegar en tu IA: "el port" es nuestra
> transformación offline de los workflows n8n de STG (Main, Payment, Atención Humana, Metepec)
> para hacerlos dual-safe (multi-sesión por `session_id`, compatibles con tu hardening Django),
> con tests sobre un harness Postgres local con el DDL real de STG en dos sabores de schema:
> `actual` (STG hoy) y `objetivo` (sin el índice único de teléfono). Nada desplegado aún: todo
> es transform + tests offline; el deploy real va en una ventana coordinada (nuestra "Fase 7").

## Qué está TERMINADO (verde, ambos sabores de schema)

1. **Contrato cruzado C1-C3 aplicado y certificado** — tras tu validación del payload contra
   nuestro código real: `m:` tratado como aleatorio independiente (sin check de igualdad,
   formato 12-hex) y shape de error 400 alineado con Django (`status/code/field`). C3 (exponer
   `leadId`) documentada como no viable sin mutar un nodo congelado — aceptado.
2. **Atención Humana dual-safe (nuestra Fase 4)** — 157 tests, 0 fallos, sin flakiness:
   - Los 3 webhooks del Dashboard pasan de GET sin auth a POST + headerAuth (mismos webhookIds).
   - Tomar/liberar conversación por claim contra `dashboard_conversation_claims` con fencing
     (control_id + epoch) — mutación SIEMPRE por `session_id`, nunca por teléfono. Esto
     resuelve el hallazgo de que `human_takeover` se escribía vía GET por teléfono.
   - Envío humano según tu §10.4: teléfono desde la fila, ledger `dashboard_outbound_dispatch`
     con reserva pre-Meta y `provider_message_id`, historial canónico con `sent_by=human_agent`.
   - Dedupe inbound por `wamid` en Main.
   - **Precedencia (tu §10.6):** caracterizada con tests — el grafo real YA implementa tu orden
     (pago/terminal → Metepec → control humano → IA) por construcción. Tu regla de "no
     simultanear control humano general y derivación Metepec sin transferencia explícita" NO
     está implementada por nadie — punto de decisión para el checkpoint.
3. **Hallazgo técnico que te afecta si usas CTEs data-modifying:** un SELECT hermano de un
   INSERT dentro del mismo `WITH` ve el snapshot del inicio de la sentencia (no ve las filas
   del INSERT). Nos rompió el primer diseño del ledger de idempotencia bajo carrera real;
   el patrón válido es condicionar en el `RETURNING` del CTE del INSERT, no en re-leer la tabla.

## Qué está EN VUELO ahora mismo

**Metepec dual-safe (Fase 5):** liberación pasa de GET sin auth + limpieza por teléfono
(apagaba TODAS las sesiones del número) a POST + headerAuth por `session_id` exacto, con
fencing vía columna nueva `metepec_derived_at` (aditiva, dominio n8n, invisible para Django).
Incorpora ya tu gate 3: `pg_advisory_xact_lock(hashtext(telefono_canonico))` en sus writers.

## Qué va DESPUÉS (Fase 3-B = tus 3 gates, aceptados)

1. **Dedupe Payment por `event_id`** — parser acepta tu contrato v1 (`schema_version`,
   `event_id`, `session_id`, `identity_status`, `amount` string) y el formato viejo en
   paralelo; replay → `duplicate` sin re-envío de WhatsApp; tabla nuestra `n8n_payment_events`.
2. **Máscara de teléfono en logs** (todos los `console.log` nuestros).
3. **Advisory lock transversal** en todos los writers n8n de `whatsapp_sessions`/
   `n8n_chat_histories`. ⚠️ Excepción que DEBES saber: el nodo `Postgres Chat Memory`
   (LangChain) no es modificable por nosotros — la memoria del agente escribe SIN el lock.
   Tenlo en cuenta en tu archivado/reset atómico.

## Qué puedes AVANZAR tú en paralelo (nada nuestro te bloquea)

1. **Publicar/confirmar el canónico exacto de `hashtext()`** que usa tu archivado/reset.
   Nuestro supuesto: forma `52` (12 dígitos, ej. `525512345678`), la variante `521` se
   canoniza antes del hash. Si tu helper difiere en un solo carácter, los locks no se cruzan.
2. **Aterrizar tu contrato Payment v1 hacia STG** (hoy el body real no lleva
   `session_id`/`event_id` y `transaction_id` va hardcodeado `txn_test_001`) — nuestro parser
   ya estará listo para ambos formatos, así que puedes desplegar a tu ritmo.
3. **Rol read-only dedicado en Postgres para `conciliacion_pagos`** (#129/#130): tu readiness
   rechazará el rol compartido de STG — es prerrequisito real del E2E conjunto.
4. **Decisiones para el checkpoint pre-deploy:** (a) ¿formalizamos tu regla §10.6 de no
   simultaneidad humano/Metepec, y con qué semántica de "transferencia explícita"?; (b) OK al
   retiro del índice único `idx_whatsapp_sessions_phone_number` en la ventana de deploy con
   Django en `shadow` (ya comentado en #132); (c) agenda de la ventana coordinada: secreto
   headerAuth al Dashboard, `n8n_payment_events` + `ALTER TABLE … metepec_derived_at` en STG,
   y la rotación de `N8N_TOKEN` (#130).

## Referencias

Issue: `aguayo-co/HYL-WAI#132`. Trabajo n8n: rama `feature/issue-132-port-dual-safe` de
`aibanez82/Agente-n8n` (reporte largo de Atención Humana:
`docs/2026-07-28-fase4-reporte-port-issue-132.md` en esa rama).
