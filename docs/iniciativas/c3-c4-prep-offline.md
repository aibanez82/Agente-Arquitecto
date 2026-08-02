# C3 / C4 — prep offline (lado Arquitecto)

> **Nuestra preparación de ingeniería**, no la spec canónica (esa la fija el monitor v4 + Juan en #132: C3/C4 def `5160112633`, enmienda C4 `5160209145`).
> Grounded en las fuentes reales (rama `feature/issue-132-port-dual-safe` de `Agente-n8n` + `HYL-WAI`). Cuando el monitor publique su manifest C3/C4, esto es el material contra el que lo cruzo.
> Estado: C2 en corrección (FAIL P1 `5160184249`); C3/C4 se preparan offline, **no se ejecutan** hasta C3 cerrada + 7 condiciones.

---

## C3 — gap exacto pre-dual (contrato + schema + readiness)

**Definición canónica (Juan `5160112633`):** cerrar el payload real (`l:`/`m:` con `m=message_token`) y toda incompatibilidad pre-dual; DDL de n8n solo aditivo/idempotente; prueba aislada PG17; inventario/fingerprints + readiness verde. Sin DDL remoto ni acción viva sin checkpoint + PASS.

### 3.1 Contrato de payload — estado: **ya cerrado en la rama, verificar en el SHA C3**
- **Django construye** (`HYL-WAI:qualitas/whatsapp_conversations.py`):
  - v2: `qc:v2:cv:{conversation_id}:l:{lead}:c:{cotizacion}:m:{token}` (`:245`) — solo si `mode_uses_conversation_id_session(mode)` **y** hay `conversation_id`.
  - v1: `qc:v1:l:{lead}:c:{cotizacion}:m:{token}` (`:249`). Orden real de claves = `l, c, m`.
  - `m:` = `message_token` = `secrets.token_hex(6)` **independiente** (`:271-273`); ningún caller lo pasa → siempre nuevo. **No** confundir con `wptoken`/`QUALITAS_WPTOKEN` (token de plantilla, `services.py:792…`).
  - `cv:` = `waq_{cotizacion}_{token_hex(12)}` (`generate_conversation_id`, `:209-222`); su hex es OTRO token, distinto del de `m:`.
- **n8n parsea** (`Agente-n8n:scripts/port-132/steps/resolve-session-port.js`):
  - Gramática CERRADA full-match (`:98-100`): `QC_V2_RE`, `QC_V1_RE`, `QC_V1_LEGACY_RE` (`qc:v1:c:{cot}` sin lead).
  - `m:` se valida **solo por formato** (12 hex minúsculas), **nunca por igualdad** (`:130`, `:148-152`, comentario C1 `:136-141`). Un `qc:` que no calce → terminal `qc_payload_estructura_invalida`.
  - **Fix de contrato cruzado ya aplicado** (`docs/2026-07-28-correcciones-contrato-cruzado-reporte.md`): antes un check `match[2]!==m` mataba TODO clic v2 real en `dual`; reemplazado por check de formato. **Gap si se pierde este fix → dual roto.** Verificar presente en el SHA C3.

### 3.2 Schema — **el ÚNICO bloqueante duro pre-dual**
- **Retirar `idx_whatsapp_sessions_phone_number` (UNIQUE)**. Está en `db/schema/actual/01_whatsapp_sessions.sql:41`; **retirado** en `db/schema/objetivo/01_whatsapp_sessions.sql:48-50`. Razón (cabecera objetivo `:1-10`): el upsert de Django usa `ON CONFLICT (session_id)`; con el índice de teléfono puesto, el 2º INSERT del mismo teléfono en `dual` (sesión legacy + v2 concurrentes) **revienta**. Retiro real vía **migración Django 0053** (ref. `scripts/port132_schema_readiness.py:121`), en ventana Fase 7→8.
- ⚠ **Nota crítica STG (contraste con nuestra verificación previa):** el schema de STG que verifiqué read-only para C2 **ya NO tenía** el índice único de teléfono → STG ya está en schema **objetivo** para `whatsapp_sessions`. Confirmar si 0053 ya corrió en STG o si el índice sigue en PROD; **es el hecho que decide si C3 tiene trabajo de schema pendiente en STG o solo readiness.**
- Todo lo demás es **aditivo/idempotente** (`IF NOT EXISTS`), en `scripts/create-port132-window-schema-stg.py`: `n8n_chat_histories.wamid` (`:93-94`); `whatsapp_sessions.metepec_derived_at` (`:96`), `human_takeover_control_id`/`human_takeover_epoch` (`:108-111`), `metepec_op_lock_id`/`metepec_op_locked_at` (`:126-128`); paridad en `*_archive` (`:114-116,131-136`). Migración `0033` introdujo `conversation_id`/`lead_id`/`status` (aditivo).

### 3.3 Readiness — gates automatizados existentes
- `scripts/port132_schema_readiness.py` — `check_phone_uniqueness_retired` (`:163`), `check_schema_ready` (`:221`), paridad archive (`:264-267`).
- `scripts/port132_trigger_readiness.py` — readiness del trigger de lock.
- `docs/preflight/2026-07-30-preflight-pre-window.json` — 30+ checks; **2 WARN = los gates pre-dual pendientes:** `dual_schema_readiness: missing_v2_archive_columns` (columnas v2 aún no en `*_archive` del STG vivo — el script de ventana las añade idempotente) y `conciliation_readiness: conciliation_role_is_write_capable` (no bloqueante).

### 3.4 Flag de modo — contexto (no es trabajo de C3, es de C5)
- `WHATSAPP_CONVERSATION_ID_MODE` ∈ `{legacy, shadow, dual, enforced}` (`whatsapp_conversations.py:22,27`). `dual`/`enforced` → `session_id = conversation_id`; `shadow` genera+almacena `conversation_id` pero la clave sigue siendo `phone_number` (`:326`). STG/PROD hoy = `shadow`. El salto a `dual` es C5, no C3.

### Checklist C3 (nuestro, para cruzar contra el manifest del monitor)
- [ ] Confirmar estado del índice único de teléfono en STG **y** PROD (¿0053 corrida dónde?).
- [ ] Verificar que el fix de contrato cruzado (`m:` por formato) está en el SHA C3.
- [ ] Resolver el WARN `missing_v2_archive_columns` (columnas v2 en `*_archive`).
- [ ] Prueba aislada PG17 del DDL objetivo (aditivo/idempotente, re-ejecutable sin efecto).
- [ ] Inventario/fingerprints de los nodos de resolución (Session Context Builder `356465ea…`, Resolve Session, Session Resolution, Session Router `36ba4991…`) verdes.

---

## C4 — canario determinista `shadow → dual → shadow` (enmienda `5160209145`: SIN espera de pared)

**Secuencia:** `precondiciones → shadow→dual → 2 pruebas funcionales → verificación → dual→shadow → cleanup`. Termina **obligatoriamente en `shadow`**. STG es cerrado y sin tráfico orgánico → evidencia por pruebas sintéticas deterministas, no por esperar.

### Prueba funcional 1 — identidad y afinidad
Dos conversaciones sintéticas `waq_*`, **mismo teléfono**, cotizaciones distintas; selección v1/v2 y **dos mensajes concurrentes**. Acreditar:
- cada payload llega a **su** conversación exacta;
- **cero cruce**;
- **máximo una** sesión `active`;
- ningún update afecta **> 1 fila**.

### Prueba funcional 2 — Payment exacto + replay
Un evento Payment sintético para una conversación exacta + **replay del mismo `event_id`**. Acreditar:
- primer evento: **exactamente una** actualización;
- replay: outcome **`duplicate`**, sin segunda actualización;
- **cero** llamada real a Meta/Payment/conectores.

### Verificación + drill obligatorios
1. cero claims/derivaciones/conectores reales/drift;
2. **CAS/drill `dual → shadow`**;
3. preflight de rollback verde;
4. sesiones e historiales **conservados**;
5. cleanup exacto del run-id sintético.

**STOP + rollback exacto** ante: cruce, `updated_count>1`, >1 `active`, conector real, claim/derivación, drift, salida no-cero o `uncertain`. **No retry silencioso.**

### Notas de implementación (nuestras)
- Reutilizable del andamiaje C2 (cuando sea operativo): fixtures `waq_*`, run-id atómico, verifier GET/SELECT, cleanup por lista exacta. C4 añade el eje **modo** (`shadow→dual→shadow`) que C2 no ejerce.
- La prueba 1 (concurrencia real, cero cruce, ≤1 `active`) depende del mismo motor de concurrencia real (PG17, 2 requests sincronizadas) que el FAIL C2 exige — **C4 hereda esa pieza de C2**. No arrancar C4 hasta que C2 tenga concurrencia real acreditada.
- El eje `dual`: requiere `WHATSAPP_CONVERSATION_ID_MODE=dual` en el plano STG del canario (CAS reversible), con retorno garantizado a `shadow`.

### Checklist C4 (nuestro)
- [ ] Fixtures: 2× `waq_*` mismo teléfono, cotizaciones distintas; 1 evento Payment + su replay.
- [ ] Asserts prueba 1: ruteo exacto, cero cruce, ≤1 `active`, updates ≤1 fila.
- [ ] Asserts prueba 2: 1 update / replay `duplicate` / cero Meta real.
- [ ] CAS `shadow→dual` y drill `dual→shadow` reversible; preflight rollback verde.
- [ ] STOP taxonomía completa + rollback por run-id + RTO.
- [ ] Cleanup exacto del run-id sintético; sesiones/historiales preexistentes intactos.
