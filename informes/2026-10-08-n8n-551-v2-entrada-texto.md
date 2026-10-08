# Informe — `#551` v2: entrada por texto construida en STG (falta el E2E, que necesita tu SÍ)

**De:** Agente n8n · **Para:** Arquitecto · **8 oct 2026 (UTC)**
**Responde a:** `dudas/2026-10-08-n8n-551-v2-entrada-texto-y-restriccion-tools-respuesta.md` (dfdb536).

## Dónde está

- **Bot STG** `dNqtM20ij6ecZYAX`: 69b62fbb (botón v2) → **`ff4e26c2-6508-4350-94c6-bd294ab1a90b`**. Tiene 465 nodos (+19). El respaldo previo está en `backups/551v2/bot-stg-69b62fbb-20261008T211735Z.json`.
- **Export** en `stg` de Agente-n8n: `279adce3`.
- **Scripts y pruebas** en `fix/551-recovery-contrato-v2` (`origin`, `39c9547e`): `scripts/551v2/cambio_texto.py`, `fix-551v2-texto-stg.py`, `focal-texto.js` y `claim-texto-rollback.sql`.
- **PROD:** nada.
- **Comprobación del PUT:** cambian 8 hojas en nodos existentes, que son las previstas. Los nodos y las connections son los del candidato. El resto queda idéntico. El `systemMessage` del AI Agent y del RAG no cambia y el workflow sigue activo.

## Qué hace

1. **`Recovery Text Claim`** (postgres, solo lee, fail-open). Va entre `Recovery Terminal?`[falso] y `Resolve Session`.
   - **Con referencia:** reclama si `context.id` es el outbound de un participante `sent` con el mismo teléfono canónico.
   - **Sin referencia:** reclama si hay **un** único participante así, sin par activado y sin ninguna conversación `open`/`active` en el teléfono.
   - **Control humano:** bloquea los dos casos.
   - **«Par activado»:** existe una `whatsapp_sessions` con el `proposed_session_id` de una interacción del participante, en cualquier estado.
   - **Si no reclama,** `Recovery Text Resume` devuelve el contexto de `Prepare Resolution Context` y el turno sigue por el camino regular de hoy.
2. **`Recovery Inbound`** es la entrada única del carril.
   - El botón da `request_quote_pdf`.
   - El texto da `prepare_context`, con `quick_reply_payload: null` y `reply_to_message_id` igual al `context.id` de Meta, o `null`.
   - Resolve Identity, Build, Validate y Activation Denied leen de aquí. El `event_id` lleva la acción.
3. **Respuesta `context_ready`.**
   - `Route` la deja pasar.
   - `Quote Ready` no hace copy ni PDF.
   - `Validate` exige el estado de **su** acción: `success` para el botón, `context_ready` con `quote: null` para el texto.
   - `Activate` guarda las 14 claves y el marcador `recovery_solo_contexto: true`.
   - `IF Recovery Pide PDF?` falso devuelve el turno a `Resolve Session`, que contesta **una vez**.
4. **Si falla el carril de texto** (terminal o activación denegada), el turno vuelve al camino regular. En el botón sigue siendo una hoja muda, como hoy.
5. **`Parse Router Output` con el marcador.**
   - `contracting` (con sus overrides de precio) **o** la petición de liga del `#552` → `recoveryVerPromo`.
   - `renovacion` y `policy_status` → `kb_query`, es decir, al RAG IA Agent.
   - `identity`, `qualitas_parameter` y `out_of_scope` quedan igual.
6. **Carril «Ver promo».**
   - `IF Recovery Ver Promo?` va entre `IF Liga Sin Póliza?`[falso] e `IF Identity Intent?`.
   - Son 13 nodos calcados de los vivos del `#552`: fence propio `d551.verpromo`, fila human (#342) y fila ai (`recovery_ver_promo_551`) tras `Settle Sent`.
   - El texto es el literal firmado.

## Evidencia (offline)

- **`focal-texto.js`: 37/37** contra los fixtures v2 de HYL-WAI (`stg` b4010d3a):
  - el DTO de texto es igual al `request` de `prepare-context`, y el del botón sigue igual al de `request-quote-pdf`;
  - `created` y `replayed` dan ok;
  - los cruces acción↔estado se rechazan;
  - las 10 combinaciones de marcador × intent;
  - el texto literal de «Ver promo».
- **`claim-texto-rollback.sql`: 17/17** en ROLLBACK sobre la BD de STG:
  - por referencia, también con el `from` en forma 521;
  - referencia ajena, y referencia de otro teléfono;
  - no es texto (imagen o botón);
  - control humano con y sin referencia;
  - par activado (aunque esté cerrado);
  - propuesta sin sesión, que sigue siendo candidato;
  - tres participantes sin referencia → no; con su referencia → sí.
- **Coste:** unos 70 ms por turno en STG, ida y vuelta incluida.

## Decisiones mías que declaro (dime si alguna no vale)

- **D1 · `renovacion` con el marcador → RAG, no «Ver promo».** No es `contracting`, y no quise ampliar la detección sin ti. «Quiero renovar» es plausible en esta campaña. Si lo quieres en «Ver promo», es añadir una palabra.
- **D2 · La petición de liga del `#552` con el marcador → «Ver promo»** en vez de «Aún me faltan algunos datos…». Reutiliza la detección existente; no hay regex nueva. Con el `#552` el texto sería falso: no faltan datos, falta tocar el botón.
- **D3 · Solo se reclama `type: text`.** Imagen, audio y botones ajenos siguen el camino regular.
- **D4 · Huecos que el marcador NO cubre** (no los toqué):
  - el carril de descuentos (`Discount Phase 2 Claim`, por donde entra todo texto libre desde `#156`), que puede actuar sobre el borrador;
  - los carriles de imagen/VIN.
  Los apunto por si quieres cerrarlos.
- **D5 · Dos textos seguidos antes de activar:** los dos reclaman y llaman a `prepare_context` (`event_id` distintos). Django devuelve el mismo par según el fixture (`replayed`), y la segunda activación es `activada_existente`.
- **D6 · Sin ventana de tiempo.** Un participante `sent` antiguo reclama igual si se cumplen las condiciones. El plan no fija ninguna ventana.

## El E2E: necesita tu SÍ (efectos hacia fuera)

En STG solo hay un participante útil: el **105**, que es el teléfono de Alberto. Propuesta, en este orden:

1. Un texto con referencia al outbound de 105 → `prepare_context` → activación → respuesta del RAG.
2. «quiero contratar» → «Ver promo».
3. Botón → PDF.
4. Un texto regular de otro teléfono → camino de hoy.

**Efectos:**
- mensajes de WhatsApp de STG al teléfono de Alberto;
- **Django STG crea el lead y la cotización resultado de 105** (`create_result_identity`), lo que deja la interacción en `pending`.

Si 105 es el participante que Juan va a usar para el punto 1 del gate conjunto (botón directo → PDF), mi paso 1 le cambia el punto de partida. Por eso no lo he lanzado. Alternativa: que Juan cree otro participante enviado en STG.

Agente: Agente-n8n
