# C0 — Baseline y freeze (opción C, HYL-WAI#140)

> Preparado por el Arquitecto, 30 jul 2026 noche, autorizado por Juan ("Puedes empezar con C0")
> y Alberto ("lanza la preparación de C0"). TODO read-only. Pendiente de la FIRMA de Alberto y
> los nombramientos del RACI para cerrar C0. Aprobaciones de C: ambas registradas en #140.

## 1. Freeze de SHAs y artefactos

| Componente | Valor congelado |
|---|---|
| Django STG (`hyl-wai-stg`) | código `34d7d6b1` (release v209) + config v210 (flags contención) |
| Rama port n8n | `feature/issue-132-port-dual-safe` — código funcional `63bc453`; tip docs `2e3d8ab` |
| Export vivo STG (git) | `stg@40fe572` (Main+Payment reparados) sobre `acef1a9` (los 6) |
| Dashboard | `main@60ec67b`; rama operador `fix/operator-webhooks-post-headerauth` |
| Schema STG | BD `dei0jssp8kr5kv` @ RDS, fingerprint target-guard `074fffb71fc19f0c` |
| BD PROD | `d779dc6ojpjvn5` @ ec2-100-58-48-157 (compartida Django/n8n/Dashboard) |

## 2. Workflows n8n STG (GET vivo 30 jul ~19:15 CDMX; todos `active=true`)

| ID | Workflow | Nodos | updatedAt |
|---|---|---|---|
| dNqtM20ij6ecZYAX | WhatsApp Insurance Quotation Bot_stg | 128 | 30-jul 21:50:17Z (reparado) |
| Ob5JYHYbc23SLp0A | …Payment Confirmation_stg | 6 | 30-jul 21:50:27Z (reparado) |
| HAMIxqhZd2TEy6NB | Atencion Humana (STG) | 19 | 30-jul 18:10 |
| PuogahK4qv9YOiF4 | Issue Policy Guard (STG) — sub | 5 | 30-jul 18:10 |
| liBCn3yBegedmYuR | METEPEC - Registrar Lead (STG) | 13 | 30-jul 18:10 |
| biWlbwq4NQdZadwg | Metepec Liberar (STG) | 2 | 30-jul 18:11 |
| nYRaRzU83qDLuEWI | Retomar Conversacion_stg | 12 | 16-jul (pre-port, sin tocar) |

Ejecuciones en vuelo: **0** (últimas: 871-873, las del E2E del mediodía).

## 3. Flags congelados

- **STG:** `WHATSAPP_CONVERSATION_ID_MODE=shadow`; followups general/checkpoint `false`,
  checkpoint dry-run `true`; payment writes/outbox/reconciliation/funnel-v2 `false`.
  Preflight vigente: 25 PASS · 0 FAIL · 2 WARN.
- **PROD:** conversation-id en `shadow`; **followups checkpoint ACTIVOS en real** (decisión de
  Alberto 30 jul, sin filtro de horario — aceptado). Sin columnas/tablas del port en el lado
  n8n; workflows n8n de PROD pre-port.

## 4. Inventario operativo (C0.5, read-only 30 jul noche)

| Qué | PROD | STG |
|---|---|---|
| `dashboard_conversation_claims` | **15 filas, 8 abiertas** (desde 24 jul; ids 1-5,11,12,14) | 6 filas, 2 abiertas (restos de pruebas) |
| `dashboard_message_audit` | 17 filas, 2 agentes | — |
| `dashboard_outbound_dispatch` | no existe | 0 filas |
| Sesiones `metepec_derived` | columna no existe | 0 |
| Ejecuciones n8n en vuelo | no verificable (API key PROD rotada 29 jul → 401 con la vieja del `.env`) | 0 |
| Followups enviados | 171 (20→30 jul, real) | apagados |

Notas de acceso descubiertas en el inventario:
- El rol `readonly_leads` (Dashboard `.env.local` local) NO tiene GRANT sobre las tablas
  `dashboard_*` de PROD — "permission denied", no "no existe". El Vercel de producción usa
  otra credencial (su `DATABASE_URL` es Sensitive, no extraíble por CLI). Coherente con #134.
- La API key de n8n PROD del `.env` del Agente-n8n quedó obsoleta con la rotación del 29 jul —
  actualizar cuando se necesite (no urge: PROD congelado para el port).

## 5. Fixtures y destinos allowlisted (C0.6, propuesta)

- **Prefijo sintético:** `E2E-` en session_id/phone/conversation_id (convención ya probada);
  teléfonos NO numéricos para imposibilitar entrega accidental; `quotation_id` ≥ 990001.
- **Destino de prueba candidato (si C1/C4 llegaran a autorizar una prueba Meta real, que hoy
  NO):** `5215551074144` (ALBERTO_PROD_TEST_PHONE, ya en el `.env` del agente). El correo de
  prueba `insurmindmetepec@gmail.com` queda como candidato para el track Metepec.
- Por defecto C1-C4: **cero red** — sinks deterministas y clones inactivos según §C1.B del plan.

## 6. Para cerrar C0 (pendiente de humanos)

1. **Alberto:** nombrar operador n8n STG, operador DB STG y dos operadores HYL-WAI STG
   (suplentes con acceso probado) — el RACI no permite cerrar C0 sin nombres.
2. **Alberto:** firmar este freeze (o corregirlo) en #140.
3. Re-scope formal: comentario en #132 (hecho por el Arquitecto), actualización de #135 (lado
   Juan), confirmación de #128 y apertura del tracker Metepec (borrador del Arquitecto,
   canal a decidir por Alberto — regla: no abrir issues en HYL-WAI sin OK).
