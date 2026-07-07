# Handoff Arquitecto → Agente n8n — Fase E2E de staging (activar bot + validar Bug #10) — v2

> Autor: Arquitecto-IA-Qualitas · 6 jul 2026 · **v2: corregido a OAuth2 nativo** tras el hallazgo de esquemas del Agente n8n (`Agente-n8n:docs/2026-07-06-fase-e2e-hallazgos-esquema-wa.md`, verificado por el Arquitecto contra la instancia viva).
> Ejecutor: **Agente n8n** (end-to-end vía API, con un paso manual de Alberto en la UI).
> Gobernanza: reportas al Arquitecto **a través de Alberto**. No hablas con otros agentes.
> Copia canónica: `Agente-Arquitecto:docs/2026-07-06-handoff-agente-n8n-fase-e2e-staging-bug10.md`.

## Decisión de diseño (Arquitecto): Modelo A — OAuth2 nativo

El trigger `whatsAppTrigger` de n8n es **OAuth2** (`clientId`/`clientSecret`), no webhook manual. Usamos el modelo **A (nativo)**, NO el B (webhook genérico). **Razón decisiva:** prod usa el `whatsAppTrigger` nativo; staging debe ser gemelo fiel o el E2E no valida lo que corre en prod. n8n auto-gestiona el webhook con Meta → sin verify token manual ni callback URL que pegar en el panel de Meta.

## Esquemas reales (verificados en la instancia viva)

| Credencial | Nodo | Campos requeridos |
|---|---|---|
| `whatsAppApi` | `Send message` | `accessToken`, `businessAccountId` (WABA ID) |
| `whatsAppTriggerApi` | `WhatsApp Message Trigger` | `clientId` (= App ID), `clientSecret` (= App Secret) — OAuth2 |

## Estado de partida (verificado por el Arquitecto)

- Instancia: `https://n8n-xlqk.srv1810257.hstgr.cloud` (aislada de prod).
- Workflow: `WhatsApp Insurance Quotation Bot_stg` · id **`dNqtM20ij6ecZYAX`** · **inactivo** · 61 nodos.
- Creds listas: Postgres STG `5wlLe3gD07CLIM7U` + Anthropic STG `aHI51VvnRnPixCx5`.
- 2 nodos WhatsApp sin credencial (a propósito). `Send message` con placeholder `STG_PHONE_NUMBER_ID_PENDING`.

## Precondición — secretos (Juan entrega → Alberto pone en `Agente-n8n/.env.local`)

| Env var | Va a | Origen (Meta) |
|---|---|---|
| `STG_WA_ACCESS_TOKEN` | `whatsAppApi.accessToken` | access token (System User ideal) |
| `STG_WA_BUSINESS_ACCOUNT_ID` | `whatsAppApi.businessAccountId` | **WhatsApp Business Account ID (WABA)** |
| `STG_WA_APP_ID` | `whatsAppTriggerApi.clientId` | **App ID** de la Meta App de test |
| `STG_WA_APP_SECRET` | `whatsAppTriggerApi.clientSecret` | App Secret |
| `STG_WA_PHONE_NUMBER_ID` | param `phoneNumberId` del nodo `Send message` | phoneNumberId del número de test |

(Ya tienes `N8N_STG_API_KEY`. **No** hace falta verify token en modelo A.) No arranques sin estos valores.

## Tareas

**Por API (Agente n8n):**
1. **Regenerar el `webhookId`** del `WhatsApp Message Trigger` (conserva `18c1b498…`, el de prod/Bug #12) → UUID v4 nuevo, antes del Connect. Higiene.
2. **Crear `whatsAppApi` "WhatsApp Send STG"**: `accessToken`=`STG_WA_ACCESS_TOKEN`, `businessAccountId`=`STG_WA_BUSINESS_ACCOUNT_ID`.
3. **Crear el cascarón `whatsAppTriggerApi` "WhatsApp Trigger STG"**: `clientId`=`STG_WA_APP_ID`, `clientSecret`=`STG_WA_APP_SECRET`. (Queda creada pero **sin autorizar** — el OAuth2 lo completa Alberto en la UI.)
4. **Cablear** credenciales a nodos: `WhatsApp Message Trigger`→Trigger STG; `Send message`→Send STG.
5. **Reemplazar** `STG_PHONE_NUMBER_ID_PENDING` → `STG_WA_PHONE_NUMBER_ID` en `Send message`.

**Manual en la UI de staging (Alberto), tras tarea 3 y tras el whitelist de Juan:**
6. **Completar el "Connect" OAuth2** de la credencial "WhatsApp Trigger STG" (login Facebook + autorizar). La API pública no puede hacerlo.

**Por API (Agente n8n), tras el Connect:**
7. **Activar el workflow** (`active:true`). La activación deja el trigger en escucha y n8n gestiona la suscripción del webhook con Meta.

## Qué necesita Juan en Meta (para el modelo A)
- Whitelistear la **redirect URL de OAuth de n8n** en la App (Valid OAuth Redirect URIs):
  `https://n8n-xlqk.srv1810257.hstgr.cloud/rest/oauth2-credential/callback`
- Suscribir el campo **`messages`** del objeto `whatsapp_business_account`.
- Añadir el **número de Alberto** como destinatario verificado del número de test.
- (NO hay que pegar callback URL ni verify token manual — lo gestiona n8n.)

## Secuencia de coordinación
1. Agente n8n: tareas 1–5 (crea el cascarón del trigger). Reporta a Alberto: ids de creds, listo para Connect.
2. Juan: whitelistea la redirect URL + suscribe `messages` + añade el número de Alberto.
3. Alberto: "Connect" OAuth2 en la UI de staging.
4. Agente n8n: tarea 7 (activar). Confirma `active=true`.

## Validación E2E del Bug #10 (Agente n8n verifica ejecuciones por API; Alberto manda mensajes)
1. **"hola"** → ejecución `success` (`GET /api/v1/executions?workflowId=dNqtM20ij6ecZYAX`).
2. **Serie inválida** (`"Gómez Palacio"` con espacio, o 14 chars) → el bot **re-pregunta**, NUNCA emite; Django (`hyl-wai-stg`) devuelve `400 invalid_vehicle_serie`. **Repetir 2–3×** (prompt-level, temp 0.7).
3. **Serie válida de 17** → procede; a Quálitas sandbox llega el VIN, no una ciudad.
Éxito = 0 emisiones con ciudad en `serie`.

## Reporte final (al Arquitecto vía Alberto)
Nuevo webhookId; ids de las 2 creds WhatsApp; confirmación de Connect + `active=true`; resultado de las 3 pruebas (ids de ejecución); gotchas.

## Fuera de alcance
Otros 2 workflows (pago necesita `httpHeaderAuth`); sandbox Quálitas (Juan); merge `stg`→`main` + re-export a `docs/n8n-workflows/` cuando pase el E2E.
