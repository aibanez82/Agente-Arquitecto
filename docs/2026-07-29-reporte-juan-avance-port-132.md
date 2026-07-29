> Publicado como comentario en aguayo-co/HYL-WAI#132 el 29 jul 2026:
> https://github.com/aguayo-co/HYL-WAI/issues/132#issuecomment-5117634768
> (push directo al repo de Juan devolvió 403 — sin permiso de escritura; el canal real es el issue)

# Reporte del Arquitecto — port n8n de #132 COMPLETO de lado n8n (29 jul 2026)

> Del Arquitecto-IA-Qualitas (equipo Alberto) para Juan. Actualiza y supersede el reporte del
> 28 jul por la noche: lo que ahí figuraba "en vuelo" o "después" ya está terminado. Vimos tu
> PR #138 mergeado a `stg` — este reporte asume ese estado.
>
> Contexto autocontenido: "el port" es la transformación offline de los workflows n8n de STG
> (Main, Payment, Atención Humana, Metepec) para hacerlos dual-safe (multi-sesión por
> `session_id`, compatibles con tu hardening Django), con tests sobre un harness Postgres con
> el DDL real de STG en dos sabores: `actual` (STG hoy) y `objetivo` (sin el índice único de
> teléfono). Nada desplegado aún: el deploy va en una ventana coordinada.

## Estado: TODO el lado n8n terminado y certificado

**217 tests, 0 fallos en ambos sabores de schema**, reproducidos independientemente por el
Arquitecto (no solo por el ejecutor). Rama `feature/issue-132-port-dual-safe` de
`aibanez82/Agente-n8n`, HEAD `18a154f`. Resumen por bloque:

1. **Contrato cruzado C1-C3** — aplicado y certificado (ya reportado el 28).
2. **Atención Humana dual-safe** — webhooks de operador POST+headerAuth, claims con
   control_id/epoch y fencing, envío §10.4 con ledger e idempotencia, dedupe inbound por
   `wamid`. Tu precedencia §10.6 la implementa ya el grafo por construcción (caracterizada con
   tests); tu regla de "no simultanear control humano y Metepec sin transferencia explícita"
   sigue sin implementar — decisión de producto pendiente en el checkpoint.
3. **Metepec dual-safe** — la liberación pasó de GET sin auth + `WHERE phone_number` (apagaba
   TODAS las sesiones del número) a POST+headerAuth por `session_id` exacto con fencing por
   columna nueva `metepec_derived_at` (aditiva, dominio n8n, invisible para Django). La rama
   `metepec_derived` de Main ahora registra entrante y respuesta en el historial.
4. **Tus 3 gates — implementados completos:**
   - **Dedupe Payment por `event_id`**: tabla `n8n_payment_events` (event_id uuid PK,
     session_id, outcome, processed_at); replay → `duplicate`, cero mutación, cero re-envío de
     WhatsApp; tu contrato v1 (`schema_version`, `event_id`, `session_id`, `identity_status`,
     `amount` string) y el formato viejo se aceptan en paralelo — puedes desplegar tu Payment
     v1 hacia STG a tu ritmo, nuestro parser ya está listo.
   - **Máscara de teléfono** en todos los logs n8n (verificado con asserts sobre el código
     generado).
   - **Advisory lock transversal**: `pg_advisory_xact_lock(hashtext(telefono_canonico))` en
     los 11 writers n8n de `whatsapp_sessions`/`n8n_chat_histories` tocados por el port, con
     8 tests de concurrencia real (esperas de lock verificadas, barrera de mismo `event_id`
     → exactamente 1 procesada).

## Hallazgos técnicos de la noche (los que te afectan)

- **El lock serializa pero no re-valida (READ COMMITTED):** si un writer espera tu lock
  mientras tu archivado/reset muta la fila y commitea, al despertar EvalPlanQual solo
  re-chequea el WHERE del UPDATE — no los CTEs de validación previos (snapshot del inicio de
  la sentencia). Todos nuestros writers repiten ahora las condiciones de estado/fencing en el
  WHERE del UPDATE, con test "el holder muta antes de soltar". Si tu lado usa el patrón
  validar-en-CTE + actualizar, revísalo — a nosotros nos encontró un leak real bajo carrera.
- **CTEs data-modifying:** un SELECT hermano de un INSERT en el mismo `WITH` no ve las filas
  del INSERT (snapshot de sentencia); el canal válido entre hermanos es el `RETURNING`. Nos
  rompió el primer diseño del ledger de idempotencia; ya corregido en todo el port.
- **`NOW()` es estable por transacción** → `metepec_derived_at` se escribe con
  `date_trunc('milliseconds', NOW())` para que el fencing sobreviva el roundtrip
  JSON/`Date.toISOString()` (JS solo representa milisegundos).

## Lo que necesitamos de ti

1. **Canónico exacto de `hashtext()`** de tu archivado/reset. Nuestro supuesto, verificado con
   test de igualdad SQL/JS: forma `52` de 12 dígitos (ej. `525512345678`), la variante `521`
   se canoniza antes del hash. Si tu helper difiere en UN carácter, los locks no se cruzan y
   el gate 3 queda decorativo. Es el punto más importante de este reporte.
2. **`Postgres Chat Memory` (nodo LangChain) escribe SIN lock** — no es modificable por
   nosotros. Tu archivado/reset debe tolerar ese writer. (También quedó sin lock el legacy
   `Update Activity`, que solo toca `last_activity`.)
3. **Checkpoint pre-ventana** (proponemos agenda): (a) canónico hashtext; (b) §10.6 —
   ¿formalizamos la precedencia y qué semántica tiene la "transferencia explícita"?; (c) OK al
   retiro del índice único `idx_whatsapp_sessions_phone_number` con Django en `shadow` (ya
   comentado en #132); (d) rol read-only dedicado para `conciliacion_pagos` (#129/#130,
   prerrequisito del E2E conjunto); (e) rotación de `N8N_TOKEN` (#130) en la misma ventana;
   (f) un matiz de 3-B: el lock también se aplicó al ledger `dashboard_outbound_dispatch`
   (tabla que Django no toca) por uniformidad — removible si lo prefieres.

## Ventana de deploy (cuando la agendemos)

Artefactos listos: script de schema idempotente (crea `n8n_payment_events` + `ALTER TABLE …
metepec_derived_at`, dry-run/`--go`), los 5 JSONs transformados, y la rama del Dashboard
(`fix/operator-webhooks-post-headerauth`) que adapta los botones de operador al contrato nuevo
(POST + header `X-Operator-Auth`) — sin mergear hasta la ventana. Un solo secreto nuevo cubre
los 4 webhooks de operador. Orden propuesto: credencial+secreto → schema `--go` → import de
JSONs → merge Dashboard → E2E de humo (incluye replay de Payment con el mismo `event_id`).

## Referencias

`aguayo-co/HYL-WAI#132` · rama `aibanez82/Agente-n8n:feature/issue-132-port-dual-safe`
(reportes largos: `docs/2026-07-28-fase4-reporte-port-issue-132.md`,
`…fase5-…`, `…fase3b-…`) · checklist de ventana:
`aibanez82/Agente-Arquitecto:docs/iniciativas/2026-07-29-ventana-fase7-checklist.md`.
