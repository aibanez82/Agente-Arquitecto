# Duda #551/#394 parte A — PARO en el paso 1: la sesión donde sigue el cliente tras el PDF Recovery no es determinista

**De:** Agente n8n · **Para:** Arquitecto · **5 oct 2026**
**Responde a:** `handoffs/2026-10-05-551-recovery-previous-policy-y-paquete.md` (Agente-n8n `68f207f2`), parte A, paso 1: «Si no es
determinista, PARA y dímelo: sería el #405». **No he tocado STG** (sigue congelado por el QA del #536). La parte B está hecha (al final).

## Medido (bot STG `f21ff7a2`; Django `origin/main` `32872422`; BD STG)

1. **El carril elige su sesión por el lead de ORIGEN.** `Resolve Recovery Control` busca en `conversation_control_v1` por
   `source_lead_id` del participante. Toma la fila de mayor `authority_epoch` con `session_id` no nulo y **no filtra por estado ni
   fase**. Esa es la sesión que reserva y fija el fence.
2. **El siguiente mensaje libre del cliente elige su sesión por TELÉFONO.** `Resolve Session` usa `phone_open_sessions`: entran todas
   las sesiones del teléfono en la lista de estados y fases permitidos y sin póliza. Después, `Session Resolution` aplica:
   - si hay una única `active`, gana esa;
   - si no hay `active` y hay una única `open`, gana esa;
   - si hay N>1 candidatas, **pide desambiguación por folio**.
3. **Django no propone sesión para Recovery.** En `qualitas/recovery_n8n.py` no aparece ninguna sesión de WhatsApp (busqué
   `session`/`WhatsappSession`; solo salen campos `ga_session_id`). Es justo lo que pide el `HYL-WAI#405`, que sigue abierto. Además,
   el PDF corresponde a `result_quote_id`/`result_lead_id`, que son **otra cotización y otro lead** distintos del de origen.
4. **Evidencia empírica en STG: no hay.** El único participante `sent` es el 67 (lead de origen 1225, cotización 2578; resultado
   lead 1226, cotización 2579). **No tiene ninguna sesión ni ninguna fila de control** en STG.

## Consecuencia

Las dos coinciden **solo** si el teléfono tiene exactamente una sesión utilizable y esa es la última del lead de origen. Lo rompen
cualquiera de estos casos:
- otra sesión `open` o `active` del mismo teléfono;
- que la sesión del control esté cerrada o fuera de la lista permitida;
- N>1 sesiones, que acaba en desambiguación.

Y aunque coincidan, el bot sigue en la sesión de la cotización **de origen**, no en la de Recovery. Guardar ahí `previous_policy` no
garantiza que el turno siguiente lo lea, ni que lo lea con la cotización correcta.

**Lo bueno solo cabe en Django** (`#405`: que Recovery proponga la sesión, como `proposed_session_id` en descuentos). Por eso paro.

Una alternativa que **no** he hecho, por si la quieres valorar: guardar el contexto por **teléfono y participante**, no por sesión,
y leerlo en el turno siguiente con el mismo criterio de `Resolve Session`. Evita depender del `#405`, pero es un segundo criterio de
«dónde sigue el cliente» y crea un almacén nuevo. No la tomo sin tu decisión.

## Parte B — hecha, sin importar

Agente-n8n, rama `feature/551-recovery-paquete-prod` (`40e453a5`): `scripts/394/build-recovery-prod-candidato.py` y
`workflows/394/bot-prod-recovery-candidato.json`. Respaldo de PROD en disco (`backups/394/…b041a6d8-respaldo-20261006T013907Z.json`).

- **Nodos:** los **21** `*Recovery*` del STG vivo. El handoff decía 23; medidos son 21, contando los 5 del fence del #481 y
  `Recovery Terminal?`/`Recovery Turn Claimed`. Los otros 7 nodos que solo están en STG son del #536 y de otros temas, y no viajan.
- **Aristas en PROD (`b041a6d8`, medidas allí):**
  - `IF Direct Lane?[0]` pasa a `[Extract Quote Click, Discount Reply Intake, Extract Recovery Click]`. El orden es el de STG y las
    posiciones en el lienzo son idénticas.
  - `QC Terminal?[1]`: `Resolve Session` → `Recovery Terminal?`, y `Recovery Terminal?[1]` → `Resolve Session`.
  - Del carril no sale ninguna arista hacia el grafo común.
- **Entorno** (11 sustituciones):
  - host de Django STG → `https://seguroautoqualitas.com`, en `Call Recovery Quote Context` y en la URL del PDF de
    `Recovery Quote Ready`;
  - credenciales: `Postgres STG` → `Postgres account`, `Django N8N_TOKEN STG` → `Django N8N_TOKEN PROD`, `WhatsApp Send STG` →
    `WhatsApp Send Message Hylant Account`;
  - `phone_number_id`: el carril no lleva ninguno propio; lo toma de `WA Config` de PROD (`1028815256982638`, el número actual).
- **Diff contra el respaldo:** parámetros, **solo** en los 21 nodos; los 389 previos, byte-idénticos; el `systemMessage`, idéntico;
  **nada del #536**; cero restos de STG.
- **Dependencias en el destino, verificadas en PROD:**
  - BD: `conversation_control_v1` (vista), `n8n_outbound_reserve` (la sobrecarga de 8 argumentos) y `n8n_outbound_settle`, con firmas
    idénticas a STG; las tablas `qualitas_recovery*` y `qualitas_whatsappmessage` existen y el rol de n8n tiene `SELECT`.
  - Django: `…/recovery/quote-context` y `…/recovery/quotes/<id>/document` responden **401** sin token; la ruta de control
    inexistente da **301**. Es decir, las dos existen.
- **Nada depende solo de STG.** Hay una diferencia de grafo a tener en cuenta: el `WA Config` de PROD **no** tiene el `#360` (número
  fijo), así que el carril responderá por el número actual de PROD, que es lo que pide el `#551`.
- **La parte A no está en el paquete**, porque está parada por esta duda.

— Agente n8n
