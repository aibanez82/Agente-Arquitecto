# Handoff Arquitecto → Agente n8n — Fase E2E de staging (activar bot + validar Bug #10)

> Autor: Arquitecto-IA-Qualitas · 6 jul 2026
> Ejecutor: **Agente n8n** (end-to-end vía API).
> Gobernanza: reportas resultados al Arquitecto **a través de Alberto**. No hablas con otros agentes.
> Depende de: fase de import ya completada (`handoffs/` / `Agente-n8n:docs/2026-07-06-resultado-import-staging.md`).
> Copia canónica del Arquitecto: `Agente-Arquitecto:docs/2026-07-06-handoff-agente-n8n-fase-e2e-staging-bug10.md`.

## Objetivo

Dejar el workflow de staging **activo y funcional** para validar el fix del Bug #10 (VIN/serie) end-to-end con un número de WhatsApp de prueba, sin tocar producción.

## Estado de partida (verificado por el Arquitecto)

- Instancia staging: `https://n8n-xlqk.srv1810257.hstgr.cloud` (aislada de prod).
- Workflow: `WhatsApp Insurance Quotation Bot_stg` · id **`dNqtM20ij6ecZYAX`** · **inactivo** · 61 nodos.
- Creds ya listas: Postgres STG `5wlLe3gD07CLIM7U` (9 nodos) + Anthropic STG `aHI51VvnRnPixCx5` (4 nodos).
- Los 2 nodos WhatsApp (`WhatsApp Message Trigger`, `Send message`) están **sin credencial** a propósito.
- `Send message` tiene el placeholder `STG_PHONE_NUMBER_ID_PENDING` en el phoneNumberId.
- Django ya reescrito a `hyl-wai-stg-d1085ad74dbf.herokuapp.com`.

## Precondición (te la da Alberto cuando Juan entregue la App de Meta de staging)

Alberto pondrá en el `.env.local` de ESTE proyecto (Agente-n8n) los secretos de la App de test:
- `STG_WA_ACCESS_TOKEN` — access token para enviar.
- `STG_WA_PHONE_NUMBER_ID` — phoneNumberId del número de prueba.
- `STG_WA_APP_SECRET` — App Secret (para el trigger).
- `STG_WA_VERIFY_TOKEN` — verify token (Alberto lo define; debe coincidir con lo que ponga Juan en Meta).
- (ya tienes) `N8N_STG_API_KEY`.

No arranques hasta tener estos valores.

## Tareas (orden estricto)

**1. Regenerar el `webhookId` del `WhatsApp Message Trigger`.**
El importado conserva `18c1b498-024e-4803-8088-56ccf9812f33` — **es el webhookId de PROD (Bug #12)**. Aunque en instancia separada no colisiona, hay que regenerarlo por higiene y para que el callback URL de staging sea propio. Genera un UUID v4 nuevo, ponlo en `nodes[].webhookId` de ese nodo, y actualiza el workflow por API. El **callback URL resultante** será:
`https://n8n-xlqk.srv1810257.hstgr.cloud/webhook/<NUEVO_WEBHOOK_ID>`
→ **Reporta este URL a Alberto** (se lo pasa a Juan para el webhook de Meta).

**2. Crear las 2 credenciales WhatsApp** (consulta primero el esquema: `GET /api/v1/credentials/schema/whatsAppApi` y `.../whatsAppTriggerApi`, como se hizo con postgres):
- `whatsAppApi` → nombre "WhatsApp Send STG" · usa `STG_WA_ACCESS_TOKEN` (+ businessAccountId si el esquema lo pide).
- `whatsAppTriggerApi` → nombre "WhatsApp Trigger STG" · usa `STG_WA_ACCESS_TOKEN` + `STG_WA_APP_SECRET` según el esquema.

**3. Cablear las credenciales a sus nodos** en el workflow `dNqtM20ij6ecZYAX`:
- `WhatsApp Message Trigger` → `whatsAppTriggerApi` "WhatsApp Trigger STG".
- `Send message` → `whatsAppApi` "WhatsApp Send STG".

**4. Reemplazar el placeholder del phoneNumberId:** `STG_PHONE_NUMBER_ID_PENDING` → `STG_WA_PHONE_NUMBER_ID` en el nodo `Send message` (y en cualquier otro sitio donde aparezca).

**5. Verify token del trigger:** confirma qué verify token usa/espera el `WhatsApp Message Trigger` de n8n y alinéalo con `STG_WA_VERIFY_TOKEN`. Reporta el valor exacto a Alberto (Juan debe poner el mismo en Meta).

**6. Activar el workflow** (`active: true` vía API). ⚠️ **La activación registra el webhook y es lo que permite que n8n responda el handshake de verificación de Meta** — por eso debe estar activo ANTES de que Juan verifique el webhook en la App. Confirma `active=true` por API.

## Coordinación con Meta (secuencia, para que Alberto sepa el orden)

1. Agente n8n hace tareas 1–6 → reporta a Alberto: **callback URL final + verify token + ids de creds**.
2. Alberto pasa a Juan: callback URL + verify token → Juan los pone en la App, suscribe el campo `messages`, y añade el número de Alberto como destinatario verificado.
3. Meta verifica el webhook contra el endpoint **activo** de n8n staging.

## Validación E2E del Bug #10 (tú verificas ejecuciones por API; Alberto manda los mensajes)

Tras configurar Meta, Alberto envía desde su número verificado:
1. **"hola"** → debe dispararse una ejecución. Verifica con `GET /api/v1/executions?workflowId=dNqtM20ij6ecZYAX` que corrió `success`.
2. **Serie inválida** (p. ej. `"Gómez Palacio"` con espacio, o una de 14 chars) → el bot debe **re-preguntar**, NUNCA emitir. El gate de Django (`hyl-wai-stg`) devuelve `400 invalid_vehicle_serie`. **Repetir 2–3 veces** (el manejo del 400 es prompt-level a temperature 0.7 → probabilístico).
3. **Serie válida de 17 (VIN completo)** → debe proceder. Confirmar que a Quálitas sandbox llega el VIN, no una ciudad.

Criterio de éxito: 0 emisiones con ciudad en `serie`; toda serie no-17 se re-pregunta o la rechaza Django.

## Reporte final (al Arquitecto vía Alberto)
- Nuevo webhookId + callback URL.
- ids de las 2 credenciales WhatsApp.
- Confirmación `active=true`.
- Resultado de las 3 pruebas E2E (con ids de ejecución).
- Cualquier gotcha (como el de `settings` en el import).

## Fuera de alcance de este handoff
- Los otros 2 workflows (Payment Confirmation, Retomar Conversacion) — fase aparte; el de pago necesita la cred `httpHeaderAuth` (token `N8N_TOKEN` de `hyl-wai-stg`).
- Sandbox Quálitas (endpoints/credenciales QA) — depende de Juan (mensaje aparte).
- Merge `stg`→`main` + re-export a `docs/n8n-workflows/` — cuando el E2E pase.
