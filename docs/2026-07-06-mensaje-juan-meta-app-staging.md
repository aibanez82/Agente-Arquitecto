# Mensaje para Juan — App de Meta separada para staging de WhatsApp

> Contexto (para el Arquitecto/Alberto, NO enviar): necesitamos WhatsApp de staging **aislado de prod**. El webhook de Meta se configura **a nivel de App**, así que colgar un número nuevo de la App de prod mezclaría el inbound con prod (mismo problema que el Bug #12). Solución correcta: **App de Meta nueva y dedicada** → su producto WhatsApp da un número de prueba gratis (envía a hasta 5 números verificados, sin verificación de negocio).
> **v2 (modelo OAuth2 nativo):** el trigger de n8n es `whatsAppTrigger` OAuth2 (`clientId`/`clientSecret`), verificado contra la instancia viva. Por eso: (a) Juan da también **WABA ID** y **App ID** (además de App Secret, access token, phoneNumberId); (b) Juan **whitelistea la redirect URL de OAuth de n8n** en la App en vez de pegar un callback URL manual; (c) **no hay verify token**; (d) Alberto completa el "Connect" OAuth2 en la UI de staging. Ver `Agente-n8n:docs/2026-07-06-fase-e2e-hallazgos-esquema-wa.md` y el handoff v2.

---

## Mensaje (copiar/pegar a Juan)

Hola Juan,

Estoy montando un **entorno de staging** para probar el bot de WhatsApp antes de subir cambios a producción (empezando por el fix del VIN/serie). Necesito que el WhatsApp de staging quede **totalmente aislado de producción** — que un mensaje de prueba nunca toque el número real de Quálitas ni el n8n de prod.

Como el webhook de Meta se configura a nivel de App (todos los números de una App entregan al mismo webhook), **no** sirve colgar un número nuevo de la App de prod: se mezclaría el inbound con producción. Lo que necesito es una **App de Meta NUEVA, dedicada a staging**. En concreto:

1. **Crear una App nueva** en developers.facebook.com, dedicada a staging/test.
2. **Añadirle el producto “WhatsApp”** → Meta da un **número de prueba gratis** con su `phoneNumberId` (envía a hasta 5 números verificados; no requiere verificación de negocio).
3. **Pasarme estos datos:**
   - **App ID**
   - **App Secret**
   - **WhatsApp Business Account ID (WABA ID)**
   - **phoneNumberId** del número de prueba
   - **Access token** para enviar — idealmente un token de **System User permanente** con permiso `whatsapp_business_messaging`; si prefieres arrancar rápido, vale el temporal de 24 h.
4. **Whitelistear la redirect URL de OAuth de mi n8n** en la App (Facebook Login → Settings → *Valid OAuth Redirect URIs*):
   `https://n8n-xlqk.srv1810257.hstgr.cloud/rest/oauth2-credential/callback`
   (mi n8n usa la integración nativa de WhatsApp, que es OAuth2 — por eso necesita esto en vez de un callback manual).
5. **Suscribir el campo `messages`** del objeto `whatsapp_business_account` en el webhook de la App.
6. **Añadir mi número de WhatsApp** (te lo paso) como **destinatario verificado** del número de prueba, para el mensaje de “hola” de prueba.

Con eso yo termino la conexión desde mi lado (autorizo la app en mi n8n y activo). No hace falta que pegues ningún callback URL ni verify token manual — la integración nativa lo gestiona sola.

Gracias.

---

## Checklist de lo que recibes de Juan → a dónde va en staging n8n (modelo OAuth2 nativo)

| Dato de Juan | Env var (`Agente-n8n/.env.local`) | Credencial n8n / uso |
|---|---|---|
| access token | `STG_WA_ACCESS_TOKEN` | `whatsAppApi.accessToken` (Send) |
| **WABA ID** | `STG_WA_BUSINESS_ACCOUNT_ID` | `whatsAppApi.businessAccountId` (Send) |
| **App ID** | `STG_WA_APP_ID` | `whatsAppTriggerApi.clientId` (Trigger OAuth2) |
| App Secret | `STG_WA_APP_SECRET` | `whatsAppTriggerApi.clientSecret` (Trigger OAuth2) |
| phoneNumberId (test) | `STG_WA_PHONE_NUMBER_ID` | param del nodo `Send message` (reemplaza `STG_PHONE_NUMBER_ID_PENDING`) |

> **Nota (por qué NO hay callback URL ni verify token):** el nodo `whatsAppTrigger` de n8n es **OAuth2 nativo**. n8n gestiona la suscripción del webhook con Meta al autorizar y activar; no se pega callback URL ni verify token en el panel de Meta. Por eso Juan solo whitelistea la **redirect URL de OAuth** (paso 4 arriba). Alberto completa el "Connect" en la UI de staging y el Agente n8n activa. El `webhookId 18c1b498` heredado se regenera por higiene (Bug #12), pero no se comparte con Juan.
