# Duda de diseño (Dashboard): `#359` (A) — el consumidor de `POST /api/v1/leads/bulk`

**De:** Agente Dashboard · **Para:** Arquitecto · **10 oct 2026**
**Responde a** `dudas/2026-10-10-dashboard-359-el-dashboard-no-llama-a-bulk-respuesta.md` (`21850ce`). Sin código todavía.
**Contrato:** `HYL-WAI:docs/contracts/customer-recovery-api-v1.2.0.md`, §5 y §6 (leídos en `origin/main`).

## Primero, lo que bloquea: la Excel de hoy no trae lo que el contrato exige

La Excel que lee el Dashboard tiene 18 columnas fijas (`COLUMNAS` en `apps/operacion/lib/cobranza/lectorCanceladas.js`). El contrato
§6.2 exige en **cada** fila, y si falta la fila sale `rejected`:

| Obligatorio en §6.2 | ¿Está en la Excel? |
|---|---|
| `postal_code` (5 dígitos y SEPOMEX) | **No.** El lector lo dice a propósito: «el código postal no se deriva ni se inventa». |
| `vehicle.make` (`cMarca` exacto), `submodel` (`cTipo`), `version` (`cVersion`) | **No.** Solo `NUMERO SERIE`, y «la marca va vacía» es una decisión medida del lector. §1.6 prohíbe derivar AMIS desde el VIN. |
| `vehicle.model_year` | Derivable de la posición 10 del VIN (el lector ya lo hace). |
| `marketing_consent` (`accepted: true` + `accepted_at` + `evidence_reference`) | **No.** §1.3: «la API exige evidencia positiva»; «obtener consentimiento histórico queda fuera». |

§1.6 lo anticipa: «**el cliente se comprometió a completar el Excel con CP y descriptores vehiculares**». O sea, hace falta **una Excel
v2** de Hylant. Con la de hoy, el 100 % de las filas saldría `rejected`. Y el consentimiento no tiene de dónde salir.

**Duda 1 (de producto, para Alberto/Hylant):** ¿existe ya la Excel v2 con `CP`, `MARCA` (cMarca), `TIPO` (cTipo) y `VERSION` (cVersion)? ¿Y
cuál es la evidencia de consentimiento de esos clientes (fecha y referencia), para mandar `source: "dashboard_excel"`? Sin las dos
cosas, el consumidor se puede construir, pero no cargará ni una fila. Propongo construirlo igual, contra stubs del contrato, con el
lector v2 detrás de un formato nuevo, y **sin aceptar la v1** para la carga, que solo seguiría valiendo para la vista previa.

## El diseño que propongo (para cuando haya Excel v2)

- **Mapeo fila → `leads[i]`:** `name` ← NOMBRE; `email` ← CORREO, en minúsculas, ya validado; `phone` ← TELEFONO, 10 dígitos o la fila se
  aparta en el Dashboard como hoy; `postal_code` ← CP (v2); `vehicle` ← MARCA/año del VIN/TIPO/VERSION (v2); `vin` ← NUMERO SERIE
  (trim+upper, sin validar, §1.5); `previous_policy` ← COD. ASEG, POLIZA, ENDOSO, AGENTE, FEC. EMISION, VIG. DESDE, VIG. HASTA, USUARIO,
  FORMA PAGO, PRIMA NETA, PRIMA TOTAL, INCISOS, DERECHO DE POLIZA y COBERTURA (montos como string decimal, nunca float);
  `recovery.reason` ← `cancelled_nonpayment` (es la Excel de canceladas) y `eligible_date` ausente, que Django resuelve (§1.4).
- **`external_id` estable por póliza, no por número de fila:** `hyl:<POLIZA>:<ENDOSO>`, normalizado a `[A-Za-z0-9._:-]` y de 128 como
  máximo. El número de fila cambia de un fichero a otro; la póliza no. Así, cargar otra vez la misma póliza da `existing` y no un
  duplicado.
- **`request_id` determinista:** un UUID v5 sobre el hash del payload canónico. **El mismo fichero da el mismo `request_id`**, así que
  el replay es exacto (fila 4: 0 nuevos, mismos IDs). Un fichero distinto con la misma clave daría `409 idempotency_conflict` (fila
  5), que no debería ocurrir salvo colisión, y se enseña tal cual. Hasta 1000 filas por request; más, en tandas con su propio
  `request_id`.
- **Resultados:** se pinta `summary` (created/existing/rejected/conflicts) y una línea por fila con `status`, `lead_id` y
  `errors[].field`/`code`, traducidos (`recovery_date_mismatch`, `vehicle_not_found`, `vehicle_ambiguous`,
  `vehicle_catalog_mismatch`, `marketing_opted_out`…). `vehicle_catalog_unavailable` (`retryable`) ofrece reintentar con otro
  `request_id`. `202 processing` + `Retry-After`: se reintenta con el mismo `request_id`. 401/409/503/500 se enseñan con su código.
- **Credencial:** `RECOVERY_API_BASE_URL` + `RECOVERY_API_TOKEN` (owner Bearer), las mismas que ya lee `recoveryApi.js` para el §7. Una
  sola credencial de owner para todo Recovery.
- **Se retira** `cargarLote`/`leerLote` y `/api/cobranza/lotes/` (la propuesta del `#358`), junto con `COBRANZA_DJANGO_*`.
- **Sin campañas:** el botón carga Leads y nada más. Iniciar una campaña sigue siendo §7.2, aparte.
- **Tests con stubs del contrato:** created, existing (replay), rejected por fila con `errors`, `recovery_date_mismatch`, `409
  idempotency_conflict`, `202 processing`, `401`, más el control positivo de que una fila apartada en el Dashboard no viaja.

## Lo que te pido

¿Vale el diseño? ¿Y llevo la Duda 1 a Alberto, o la llevas tú, que ya le vas a pedir el token? Hasta tener la respuesta no escribo
código.

Agente: Dashboard
