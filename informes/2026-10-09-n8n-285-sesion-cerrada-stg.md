# Informe — `#285`, parte de la sesión `closed`: aplicado en STG (falta el contacto en frío)

**De:** Agente n8n · **Para:** Arquitecto · **9 oct 2026 (UTC)**
**Responde a:** handoff `#285` + adenda `c06383df`; dudas `2026-10-09-n8n-285-*` y sus respuestas.

**Dónde:**
- **BD de STG:** migración `migrations/156/023-reserva-reactiva-sesion-cerrada.sql`, aplicada en una sola transacción. Al número lo corrijo: es la **023** y no la 018 que propuse, porque la 018 ya existe.
- **Bot STG:** `18073441` → **`a9555533-8e18-49c7-8c21-536fc4519a44`** (export en `stg`).
- **Rama:** `fix/285-reactivo-sesion-cerrada` (`2db91a4b`).
- **PROD:** nada.

## Qué hay

- **DDL:**
  - `n8n_inbound_turn(wamid PK, phone_canonical, received_at)` + índice por `received_at`;
  - `n8n_inbound_turn_use(wamid, carril)` como clave primaria: **un uso por turno y carril**;
  - `n8n_inbound_turn_purge()`: retención de 7 días; los usos caen en cascada; sin cron;
  - **`n8n_outbound_reserve(…8…, p_turno_wamid)`**, generada a partir de la definición viva de la de 8. El diff es **solo la puerta**: una sesión `closed` pasa si el wamid está en `n8n_inbound_turn`, es del mismo teléfono canónico, tiene ≤15 minutos y su `(wamid, carril)` no se ha usado. El carril se saca del `dispatch_id` quitando el hash. **La firma de 8 no se toca** (md5 de su definición idéntico antes y después).
- **Grafo:**
  - **`Register Inbound Turn`** (postgres, `continueRegularOutput`): rama lateral desde `Phone Number ID Guard`[0], colocada encima de `WA Config` para que corra primero (gotcha 38). Cada mensaje de Meta registra su wamid, así que quedan registrados todos los del lote del buffer.
  - **`Resolve Session`:** en `phone_open_sessions`, si el teléfono **no tiene ninguna candidata viva**, devuelve la `closed` más reciente.
  - **`Session Resolution`:** con esa única `closed`, `sessionResolved`, `modo_reactivo`, **`needsAffinityUpdate=false`** y `lookupMode=phone_closed_reactive`.
  - **Los 8 `Claim * Outbound` con la guarda:** pasan `NULLIF($2,'')` como noveno argumento; `$2` es el wamid con el que ya se calculaba el `dispatch_id`.

## Controles

| # | control | resultado |
|---|---|---|
| 1 | **E2E**: sesión `closed` sembrada (`waq_2609_<hex>`, cotización sintética 2609, teléfono sintético) + «hola, ¿mi cotización sigue vigente?» | exec **82648**, success: `Register Inbound Turn` corre antes que `WA Config`; `phone_closed_reactive`; `Claim Main Reply` → `reserved`, `puede_intentar=true`; uso `s1.reply`; envío intentado (número sintético: sin entrega). **Antes** (función vieja / consulta vieja): la consulta vieja devuelve 0 → `Fallback Flag` → `solicitud_invalida` → la guarda lanza. Medido en ROLLBACK (vieja 0, nueva 1) y en la exec 82643 del primer intento |
| 2 / 8 | proactivo sobre la `closed`, aunque tenga un wamid válido «robado» (firma de 8) | `sesion_no_elegible` (ROLLBACK). **Barrido de los 21 workflows de STG:** solo los 8 `Claim` del bot llaman a la de 9; Retomar, Payment, el poller y los otros carriles del bot siguen en la de 8 |
| 3 | la sesión sigue `closed` tras el turno; Django no la retoma | `status=closed`, `closed_at` puesto, `automation_gate=blocked` tras la exec 82648 |
| 4 | diff | bot: +1 nodo, 10 nodos tocados (`Resolve Session`, `Session Resolution` y los 8 `Claim`), solo cambian las connections de `Phone Number ID Guard`; `systemMessage` intactos |
| 6 | wamid de otro teléfono | `turno_reactivo_invalido` |
| 7 | wamid de hace 16 minutos | `turno_reactivo_invalido` |
| + | sin wamid / no registrado; mismo carril dos veces; **otro carril en el mismo turno** (respuesta + PDF); replay exacto; sesión elegible con la firma de 9 frente a la de 8; epoch distinto | invalido / invalido / `turno_reactivo_usado` / **pasa** / replay sin re-autorizar / **iguales** / `epoch_distinto`. **ROLLBACK 12/12** |

**Paridad de la resolución:**
- `Session Resolution`: 9/9 fuera de línea (una active, una open, dos open, ninguna, no recuperable, `payload_v2`: idénticos a la vieja).
- `Resolve Session` contra la BD de STG: con sesiones vivas y sin sesión, el resultado es byte-idéntico al de la vieja (md5).

**Lo sembrado se limpió por id exacto:** sesión, historial, dispatch e `inbound_turn` de la prueba.

**Nota sobre el `QA-SUITE-`:** una sesión con ese prefijo da `identity_mode=unknown` y `handoff_state=contradiction`, así que la reserva la rechaza aunque esté bien. Por eso la prueba usó `waq_2609_<hex>`.

## Pendiente

- **El contacto en frío** (teléfono sin ninguna sesión). Hoy sigue en la guarda: lo vi en la exec 82643, el primer intento, con el teléfono mal formado. Lo construyo ahora con el copy como constante única `[COPY FRÍO — PENDIENTE DE FIRMA]`, la reserva sin sesión (teléfono + wamid de `n8n_inbound_turn`) y el rastro solo en el dispatch, con el control 5.
- **Para PROD:** DDL + fence → firma aparte.

Agente: Agente-n8n
