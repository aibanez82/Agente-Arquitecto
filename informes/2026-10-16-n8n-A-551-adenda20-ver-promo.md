# Informe — SESIÓN A · `#551` adenda 20: el cliente que no ve «Ver promo». El bot puede pedir él el PDF

**De:** Agente n8n · A · **Para:** Arquitecto · **16 oct 2026**
**Orden:** `Agente-n8n:handoffs/2026-10-16-A-551-recovery-a-prod.md`, adenda 20, más `handoffs/2026-10-16-AB-presupuesto-pruebas-ia.md`.

**Estado:** nada importado, ni en STG ni en PROD.
- Rama `feature/551-ver-promo-por-texto` (`7de52cd8`), sin mergear.
- **Llamadas a modelo en este trabajo: 0** después de la orden de presupuesto. Antes de ella, el E2E fallido hizo 2 ejecuciones, cada una con una llamada a Haiku que falló por la cuota.

## 1. ¿Puede n8n pedir la cotización con PDF sin el botón? **Sí**

**Contrato** (`HYL-WAI:docs/contracts/recovery-quote-context-v2.md`):
- «`request_quote_pdf` exige `recovery-<participant_uuid>`».
- «puede ser directo o posterior al texto».

**Código Django** (HYL-WAI `main` `c6a8459`, `qualitas/recovery_n8n.py:604-611`). Para `request_quote_pdf` comprueba dos cosas:
- `quick_reply_payload == f"recovery-{participant.public_id}"`;
- el **outbound** de la campaña lleva ese `button_payload`.

**No** exige que el mensaje entrante sea un botón: `inbound_message_id` solo se valida como cadena (`:366`).

**Matiz, para Juan:** esto cumple la letra del contrato, pero su espíritu es «el botón crea la cotización». Conviene que Juan lo sepa.

## 2. El cambio (`scripts/551vp/cambio_551vp.py`)

**Cuándo actúa:** cuando `Parse Router Output` decide `recoveryVerPromo`, es decir, sesión solo-contexto y el cliente quiere contratar, pide la liga o habla de renovar.

**Antes:** salía `Recovery Ver Promo Copy` («toca el botón *Ver promo*…»).

**Ahora:**
1. `Recovery Ver Promo Lookup` (postgres, solo lee): saca el participante de la interacción cuya `proposed_session_id` es la sesión.
2. `Recovery Ver Promo Click` (code): construye el mismo objeto que `Extract Recovery Click`, con `quickReplyPayload='recovery-'+pid`, el `wamid` del texto, `from` y `timestamp`.
3. `IF Recovery Ver Promo Pide PDF?`:
   - **[0] → `Recovery Inbound`**: desde ahí corre el carril del BOTÓN entero, sin cambios (Resolve Identity → `request_quote_pdf` → Activate → IF Pide PDF? → Download/Upload/Send).
   - **[1] → `Recovery Ver Promo Copy`**: el respaldo, que es lo de hoy (sin fila o con error del Lookup).

**Tres nodos del carril corregidos:** `Recovery Quote Ready`, `Claim Recovery Outbound` y `Recovery Fence Denied` leían `$('Extract Recovery Click')`. Pasan a `$('Recovery Inbound')`, la entrada única, que ya lleva los mismos campos con botón o con texto. Sin esto, la entrada por texto se rompería en la rama del PDF.

**No se repite:** con `request_quote_pdf`, `Activate Recovery Session` pone `recovery_solo_contexto=false`. Es el mismo caso que hoy «escribe y luego pulsa».

**Alcance del cambio:**
- No toca el systemMessage ni lo del `#543` y el `#285`.
- **Entra igual en STG `606da14f` y en PROD `1265f994`.**

## 3. Acreditación SIN modelo (`scripts/551vp/offline-551vp.py`): **29/29**

**Lookup** (STG con `BEGIN READ ONLY … ROLLBACK`; PROD solo lectura):
- con sesión → su participante;
- sin interacción → 0 filas;
- `__NULO__` → 0 filas;
- `waq_4507` en PROD → 1 participante.

**CORREGIDO durante la medición:** esperaba que `waq_2983` diera el participante 115, que fue el que escribió. Da el **105**: la sesión pertenece a la interacción 34 del 105, porque Django reutiliza la `success` del contacto («origen A, resultado C»). **El Lookup devuelve el participante EFECTIVO de la sesión.** Para `request_quote_pdf` eso es válido: el 105 tiene su propio outbound con su payload. La consecuencia es que el evento queda atribuido al 105 y no al 115. **En PROD, hoy, cada sesión tiene exactamente un participante** (19 interacciones, 19 participantes, 19 sesiones), así que ahí no hay ambigüedad.

**Click** (en node):
- con pid válido → `ok`, con payload, `wamid` y `from` correctos;
- sin fila, con pid que no es uuid, o sin `wamid` → `ok=false`, es decir, el respaldo;
- las claves son las mismas que las de `Extract Recovery Click`.

**Cableado** (sobre STG `606da14f` y PROD `1265f994`):
- IF VP?[0] → Lookup → Click → IF; IF[0] → `Recovery Inbound` e IF[1] → Copy; la rama [1] de IF VP? queda intacta;
- **cada `$()` de los nodos nuevos y de los tres corregidos lee un ancestro** (BFS), y ninguno lee un nodo inexistente.

## 4. Medido en PROD (solo lectura)

**Ámbito:** todo `n8n_chat_histories`, mensajes `ai` que empiezan por «Para darte tu precio con la promoción, toca el botón *Ver promo*».

**Resultado:** **1 sesión** lo recibió, la `waq_4507`, **4 veces**, y no tiene PDF. Hay 14 sesiones Recovery en total.

## 5. Lo que falta, cuando haya cuota

**Un E2E con N=1** contra Django STG: 2 turnos, unas 4-6 llamadas.
- **Hace falta un participante limpio.** El 115 no sirve: Django lo resolvió a la interacción vieja del 105 (`waq_2983`, `payment_pending`), donde no aplica Ver Promo.
- **El participante lo pide Alberto.**

**Efecto del intento fallido, para que conste:** `Activate Recovery Session` (por diseño) pasó a `open` otras 25 sesiones del teléfono de Alberto en STG, `waq_5582` incluida.

**Privacidad:** el teléfono de Alberto entró unos segundos en el primer commit de la rama (`62be2ddd`). Lo sustituí por uno sintético y reescribí ese commit (`7de52cd8`) antes de que nadie lo revisara. El objeto antiguo puede seguir accesible en GitHub por SHA hasta su limpieza.

Agente: Agente n8n · A
