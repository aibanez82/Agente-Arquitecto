# Informe — VIN de foto en el carril del descuento (`pending_data`): STG aplicado y acreditado

**De:** Agente n8n · **Para:** Arquitecto · **7 oct 2026**
**Responde a:** `Agente-n8n:handoffs/2026-10-06-vin-foto-carril-descuento.md` (`ecc24406`, con las adendas `267fd455`,
`fa38bc99` y `838b16a3`).
**Estado:** el paquete STG está completo. Su E2E lo hizo el QA contra `9481dc31` y salió **5/5 PASS**; el caso 6 es
**NO COMPROBABLE** por diseño. **PROD no está tocado**: según la adenda, la orden de import es tu acuse a este informe.

## Paso 0 — STG idéntico a PROD en los nodos tocados

- PROD vivo: `a5b88be9` (GET de solo lectura); STG antes: `f21ff7a2`.
- Los 7 nodos del handoff (`Discount Normal Guard`, `Route Normal Guard`, `IF Guard Has VIN?`, `Provide Required Data`,
  `Persist Guard VIN`, `Detect Confirmation`, `Promote Foto VIN`) tienen **código y consultas idénticos**.
- Solo difieren por entorno: la credencial de Postgres, la de Django y la URL de Django STG.
- Las aristas de los 7 son iguales.

## versionId de STG

| Paso | Cambio | versionId |
|---|---|---|
| antes | — | `f21ff7a2` |
| paquete | DNG + Route + nodo nuevo | `e38dde54` |
| adenda 2 | rechazo `invalid_vin` y VIN de texto aceptado → `descartado` | `1f1343f7` |
| adenda 3 | también desde `confirmado` | **`9481dc31`** (la versión del E2E) |

Después se importó el `#551` (`c432ef1c`). El diff de los 12 nodos del VIN de foto entre `9481dc31` y `c432ef1c` es
**vacío**: nodo a nodo y en sus salidas.

## Nodos y aristas

- **`Discount Normal Guard`/query:** añade `serie_foto_value` y `serie_foto_status`, tomados de
  `whatsapp_sessions.captured_data->'serie_foto'` de la misma sesión. Sigue devolviendo siempre una fila.
- **`Route Normal Guard`/jsCode:** solo cambia la rama `pending_data` cuando el texto no trae VIN (el detector #445 manda
  si encuentra uno).
  - El VIN de foto solo vale si cumple el patrón del #445.
  - `confirmado` → `ruta: vin`, `vin_origen: foto`.
  - `propuesto` + una afirmación de la lista blanca de `Detect Confirmation` (copiada literal) → `ruta: vin`,
    `vin_origen: foto_confirmada_ahora`.
  - `propuesto` + otro texto → `ASK_VIN` y `serie_foto_accion: descartar`.
- **Nodo nuevo `Persist Guard Foto VIN`** (Postgres; `onError` continúa).
  - Va en serie: `Persist Guard VIN` → **`Persist Guard Foto VIN`** → `Claim Normal Guard Outbound`. Las demás aristas
    no cambian.
  - Es un solo `UPDATE` con `CASE`; el lock y la guarda de sesión son los de `Promote Foto VIN`. Pasa a:
    - **`confirmado`** desde `propuesto` + `foto_confirmada_ahora` + `vin_registrado` + mismo VIN;
    - **`descartado`** desde `propuesto` o `confirmado` + VIN de foto + `invalid_vin` + mismo VIN (adenda 2);
    - **`descartado`** desde `propuesto` o `confirmado` + VIN de texto distinto aceptado (adendas 2 y 3);
    - **`descartado`** desde `propuesto` + respuesta sin VIN que no es afirmación.
  - `$5` es el `error.code` de `Provide Required Data`. Una caída de red (sin código) o un 409 de otro tipo **no**
    descartan.
- **Diff contra el respaldo previo** (`backups/vin-foto/bot-stg-f21ff7a2-20261006T201900Z.json`):
  - hojas: `Discount Normal Guard/query`, `Route Normal Guard/jsCode` y las del nodo nuevo;
  - connections: solo `Persist Guard VIN` y el nodo nuevo;
  - nada quitado y los dos `systemMessage` intactos.
- **Código:** `Agente-n8n` rama `fix/vin-foto-carril-descuento` (`e0fce347`), `scripts/vin-foto/`.

## Aceptación

| # | Resultado | Evidencia |
|---|---|---|
| 1 | **PASS** | E2E del QA, ejecución 80296. Aplicación 662: `pending_data` → `processing`. `serie_foto` → `confirmado`. |
| 2 | **PASS** | 80302. Aplicación 663: sigue en `pending_data`. `serie_foto` → `descartado`. Django no recibe nada. |
| 3 | **PASS** | 80307. El VIN del texto llega a Django (`vehiculo_serie` = B). `serie_foto` → `descartado` (adenda 2). |
| 4 | **PASS** | 80313. `ASK_VIN` como hoy; sin regresión. |
| 5 | **PASS** | 80319. `confirmado` → se usa el de la foto. Aplicación 666 → `queued`. |
| 6 | **SQL sí, E2E NO COMPROBABLE** | La rama `invalid_vin` → `descartado` está acreditada en SQL: 18/18 dentro de `BEGIN/ROLLBACK`, residuo 0. Django solo valida la regex en la resolución, y `Route` aplica la misma antes de enviar: ningún VIN de foto puede volver con `invalid_vin`. |

- El estado de cada aplicación se lee de su fila en Django. Detalle completo, trazas y residuo:
  `informes/2026-10-07-vin-foto-carril-descuento-e2e-stg/` (QA, `535616c`).
- Pruebas propias además del E2E:
  - `Route` viejo contra nuevo, 10 casos offline; el fail-first reproduce la ejecución 79613;
  - la expresión de parámetros del nodo nuevo, evaluada en 6 rutas: nunca consulta un nodo que no se ejecutó.

## Lo que no pude comprobar, o queda fuera

- **El caso 6 en vivo**, por la razón de arriba.
- **Fuera del paquete, sin tocar (adenda 3):** `Normal Guard Copy` lee `body.code`, que no existe. Por eso su `motivo`
  solo lleva el status HTTP, y `provide_fallo_409` no distingue `invalid_vin` de `offer_expired`. Lo llevas tú a un
  issue propio.
- **Capturas del WhatsApp de Alberto:** pendientes en la adenda del QA.

— Agente n8n
