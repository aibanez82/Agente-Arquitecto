# Mensaje para Juan — App de Meta separada para staging de WhatsApp

> Contexto (para el Arquitecto/Alberto, NO enviar): necesitamos WhatsApp de staging **aislado de prod**. El webhook de Meta se configura **a nivel de App**, así que colgar un número nuevo de la App de prod mezclaría el inbound con prod (mismo problema que el Bug #12). Solución correcta: **App de Meta nueva y dedicada** → su producto WhatsApp da un número de prueba gratis (envía a hasta 5 números verificados, sin verificación de negocio). Fases: Juan crea App+WhatsApp+credenciales+añade el número de Alberto AHORA; el callback URL + verify token se los pasa Alberto después (dependen del trigger de staging, cuyo webhookId el Agente n8n regenerará antes de fijarlo).

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
   - **phoneNumberId** del número de prueba
   - **Access token** para enviar — idealmente un token de **System User permanente** con permiso `whatsapp_business_messaging`; si prefieres arrancar rápido, vale el temporal de 24 h.
4. **Añadir mi número de WhatsApp** (te lo paso) como **destinatario verificado** del número de prueba, para poder mandar el mensaje de “hola” de prueba.

Con la App creada y esos datos, yo configuro el resto por mi lado. **Te pasaré aparte el Callback URL del webhook + un verify token** para que los pongas en la App y suscribas el campo `messages` — te los mando en cuanto tenga el trigger de staging listo (es una URL de mi n8n de pruebas).

Gracias.

---

## Checklist de lo que recibes de Juan → a dónde va en staging n8n

| Dato de Juan | Credencial n8n staging | Nodo |
|---|---|---|
| phoneNumberId (test) + access token | `whatsAppApi` "WhatsApp Send STG" | Send message + reemplaza placeholder `STG_PHONE_NUMBER_ID_PENDING` |
| App Secret (+ verify token) | `whatsAppTriggerApi` "WhatsApp Trigger STG" | WhatsApp Message Trigger |

## Segunda fase (Alberto → Juan, después de que el Agente n8n regenere el webhookId)
- **Callback URL:** `https://n8n-xlqk.srv1810257.hstgr.cloud/webhook/<WEBHOOK_ID_REGENERADO>` (NO usar `18c1b498…`, que es el de prod/Bug #12; el Agente n8n lo regenera).
- **Verify token:** cadena que definimos y debe coincidir con el trigger de n8n.
- Suscribir el campo **`messages`** del objeto `whatsapp_business_account`.
