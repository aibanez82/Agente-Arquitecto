# Informe — SESIÓN A · Adenda 12: la emisión determinista ya no borra una liga buena

**De:** Agente n8n · A · **Para:** Arquitecto · **16 oct 2026**
**Orden:** `Agente-n8n:handoffs/2026-10-14-A-firmas-orden-prod-591-y-cola.md`, adenda 12 + la nota del 16 oct.
**Caso:** STG exec **99341**, sesión `waq_5578_cdfebe72c277`, póliza `7620104359`.
**PROD:** nada. La emisión determinista sigue sin viajar.

## Import

| Workflow STG | Antes → después | Nodos |
|---|---|---|
| Bot `dNqtM20ij6ecZYAX` | `2cf93cb6` → **`119ea850`** | `Lee Poliza Emitida` (query), `IF Hay Poliza Del Turno?` (condición), `Compone Mensaje Emision` (code) |

- **Verificación:** hojas y `connections` iguales al candidato; activo; export sincronizado a `stg`.
- **Respaldo:** `backups/emision-a12/`.
- **Código:**
  - `scripts/emision/cambio_emision_b.py`: sustituye enteros esos tres valores.
  - `cambio_emision.py`: actualizado para que un viaje desde cero salga igual.
  - `emision.js` + `ligaDelTurno`: batería 32/32.

## El arreglo (los puntos 1 a 3 de la adenda)

1. **La fuente primera es la liga del turno.**
   - **Qué devuelve.** `Lee Poliza Emitida` devuelve, además, `liga_turno`: la `link_pago` del mensaje `tool` **de este turno** (posterior a la marca de agua) que trae el número de la póliza.
   - **Cuál prefiere.** La salida de `issue_policy` antes que la de `save_policy_data`.
   - **Qué acepta.** Solo si es `https://` y `/pagar/<token>` del **dominio público** (`seguroautoqualitas.com`, que es lo que se ve en PROD: 15 de 15 en los mensajes `tool`) o del **Django de Heroku** (`hyl-wai-*.herokuapp.com`, lo que se ve en STG).
   - **Dónde vive la validación.** En la SQL, para el ruteo, y en `ligaDelTurno` de `emision.js`, para la composición. Son dos copias de la misma lista blanca, a sabiendas.
   - **Comprobado sobre el caso real** con la SQL tal cual, en solo lectura:
     - con la marca de agua de antes del turno → `7620104359` + `https://hyl-wai-stg-…/pagar/<uuid>/`;
     - con una posterior → nada, así que un turno siguiente no recompone.
2. **La API, de respaldo.** `IF Hay Poliza Del Turno?` llama a `Pide Liga Emision` **solo si el turno no trae liga**.
   - `Compone` usa `ligaDelTurno(fila.liga_turno)`, luego `ligaDeRespuesta(API)` y, si no hay ninguna, **b1**.
   - El rastro lleva `fuente_liga: turno | api | null`.
3. **`URL Fidelity Guard`:** sin tocar. En todas las corridas, `url261 = intacto`.

**La fuente que descarté:** `qualitas_polizaemitida.url_pasarela_pago` no sirve. Para `7620104359` en STG está **vacía**, y en PROD tiene valor en 49 de 88 filas, pero **ninguna** es una URL `/pagar/`.

## Aceptación

Arnés `scripts/emision/aceptacion-emision-stg.py`. Guard simulado: la **3005 trae `link_pago`** en la emisión y la 5539 no, para ejercitar la API.

| Caso | Cambio, N=3 | Vivo `119ea850`, N=1 | Control (vivo `2cf93cb6`, sin el arreglo) |
|---|---|---|---|
| **99341:** liga del turno + API **503** → plantilla con la liga del turno | 3/3 (`fuente_liga: turno`) | 1/1 | **0/2**: `contado_sin_liga` (b1, sin liga). **Regresión reproducida** |
| Liga del turno + API disponible → la del turno (la API ni se llama) | 3/3 | 1/1 | 0/2 (usaba la de la API) |
| Sin liga del turno + API disponible → la de la API (fraccionado) | 3/3 (`fuente_liga: api`) | 1/1 | — |
| Sin liga del turno + API 202 → b1 | 3/3 | 1/1 | — |
| API real de STG (3005) → la del turno, sin llamar a la API | 3/3 | 1/1 | — |
| Control: pregunta después de emitir → no recompone | 3/3 | 1/1 | — |

**Como pide tu nota:** la variante «con liga de la API» **solo está probada con la API simulada**, no con una emisión real de STG.

## Punto 4: por qué `ensure` da `temporarily_unavailable` (medido y leído; nada tocado)

- **Medido en STG.** La póliza `7620104359` (id 2377) se emitió a las 16:03:48. Su `PolicyPaymentSummary` estaba a las **16:03:51** en `valid_complete`, `active`, `paid_in_full`, `projection_quality=known` y `pending_count=0`. La `polizaemitida` quedó en `PAGADO` por `provider_poll`. El turno se escribió a las 16:03:55.
  - **Pagada antes** de la llamada a `ensure`, como dice tu nota.
- **El código** (`qualitas/on_demand_payment_links.py`, `_accredit_local_ledger`, en `origin/stg` de HYL-WAI):
  - **`already_paid`** solo sale con autoridad **`V2_KNOWN_FRESH`** y `summary_id` igual al del resumen;
  - **con autoridad heredada válida**, una póliza pagada caería en **`not_available`**, no en un 503;
  - **el 503** sale cuando `current_effect_authority` **no** está en `{LEGACY_AUTHORITATIVE, LEGACY_OUT_OF_SCOPE, V2_KNOWN_FRESH}`, o cuando el resumen no cuadra. **El resumen sí cuadra.**
- **Mi lectura.** La hipótesis se sostiene: una póliza **pagada al instante** (Quálitas QA) cuya autoridad de efecto **todavía no es «fresca»** da 503 en vez de `already_paid`.
  - Encaja con las 10 llamadas reales de STG sobre la 3005, también pagada: 10 de 10 dieron 503.
  - **No probado:** la rama exacta depende del valor de `current_effect_authority` en ese instante, que solo está en los logs de Heroku. **Para Juan.**
- **En PROD:** no lo he medido. Llamar a `ensure` sobre una póliza real tiene efectos y nada lo autoriza. En PROD los pagos no son instantáneos, así que el caso «pagada a los 3 s» es probablemente propio de Quálitas QA.

Agente: Agente n8n · A
