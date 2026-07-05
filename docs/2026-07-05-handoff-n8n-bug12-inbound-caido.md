# Handoff al Agente n8n — Bug #12: reactivar la ingesta de mensajes entrantes de WhatsApp

> Autor: Arquitecto-IA-Qualitas (Nivel 2)
> Ejecutor: Agente n8n (Nivel 3)
> Fecha: 5 julio 2026
> Origen: Bug #12 (ver `docs/2026-07-05-mensaje-arquitecto-inbound-n8n-caido.md`)
> Criticidad: 🔴 Crítico — leads reales conversando sin quedar registrados
> Regla de oro: este handoff pasa por el Arquitecto; el Agente Dashboard y tú NO os habláis directamente.

---

## ⚠️ Diagnóstico hecho EN VIVO contra la API de n8n (no sobre copia local)

Consultado el **estado vivo** en `https://n8n.srv1325340.hstgr.cloud/api/v1/` (con `X-N8N-API-KEY`).
Hechos confirmados — NO son suposiciones sobre el export local:

| Hecho | Evidencia (API en vivo, 5 jul) |
|---|---|
| El workflow de producción **está ACTIVO** | `GET /workflows` → `WhatsApp Insurance Quotation Bot` id **`BtOaZm7WlZT-24V7hqCnF`** → `active: true`, `updatedAt: 2026-07-02T23:27:11Z` |
| El nodo trigger está **bien configurado** | `WhatsApp Message Trigger` (`n8n-nodes-base.whatsAppTrigger`, webhookId `18c1b498-024e-4803-8088-56ccf9812f33`), `updates: ["messages"]`, credencial `whatsAppTriggerApi` = `WhatsApp Hylant Account` (id `bUWR11VM0seHo63P`) |
| **La ingesta se cortó en seco el 2026-07-03 22:38:53 UTC** | `GET /executions?workflowId=BtOaZm7WlZT-24V7hqCnF` → última ejecución `mode: webhook, status: success` es la **id 2059 @ 2026-07-03T22:38:53Z**. **CERO ejecuciones desde entonces (~2 días).** |
| El corte **no fue un error interno** | El último `status: error` (id 1996) fue a las **17:26 UTC del 03-jul, ANTES** del corte → no relacionado. No hay ejecuciones fallidas en el momento del corte: simplemente dejaron de llegar. |

### Lectura del Arquitecto (qué descarta esta evidencia)

- ❌ **NO** es "workflow desactivado" → está `active: true`.
- ❌ **NO** es un error de nodo / credencial de Postgres / bug de código → la última ejecución fue
  `success`; el corte es la **ausencia total de ejecuciones**, no ejecuciones que fallan.
- ✅ **SÍ** es que **Meta dejó de entregar al webhook** de n8n. El bot está activo y escuchando, pero
  Meta no le está haciendo POST. El fallo vive en el **borde Meta → registro del webhook de n8n**,
  no dentro del workflow.

> Esto casa con el reporte del Dashboard (último capturado `n8n_chat_histories.id 4693`, lead 1045,
> ~22:30 UTC): el último POST entrante que n8n procesó fue 22:38:53 UTC del 03-jul.

---

## Causas probables (borde Meta → webhook), en orden de sospecha

1. **La suscripción del webhook en Meta se invalidó / el registro del webhook de n8n se perdió.** El
   `whatsAppTrigger` de n8n registra su callback URL con Meta al activar el nodo. Si la instancia de
   Hostinger **se reinició** ~22:38 UTC del 03-jul y no re-registró el webhook, o si Meta revocó la
   suscripción, los POST dejan de llegar aunque el workflow figure activo. **Sospecha principal.**
2. **Un workflow duplicado/staging robó y luego liberó el webhook.** Hay MUCHAS copias en la
   instancia (`..._STG`, `..._stg`, `..._BCK_2jul`, `... copy`). Si alguna comparte el mismo
   `path`/`webhookId` y se activó→desactivó, pudo des-registrar el webhook de producción. (Las copias
   `_STG` se tocaron el 04-jul, *después* del corte — menos probable como disparador, pero hay que
   descartarlo.)
3. **Token/credencial de Meta caducado** (`WhatsApp Hylant Account`, id `bUWR11VM0seHo63P`). Nota: en
   Pendientes de infra ya figura "Regenerar token Meta Business API" como urgente. Un token vencido
   suele romper el *envío*, pero según cómo esté montada la suscripción también puede tumbar la
   entrega entrante.

---

## Tareas (en orden)

### 1. Confirmar la causa exacta del borde Meta→webhook

- **Instancia:** ¿hubo un **reinicio / redeploy de Hostinger** alrededor de las 22:38 UTC del
  03-jul? (logs del contenedor n8n / panel Hostinger). Es la hipótesis #1.
- **Meta App:** en **Meta → WhatsApp → Configuration → Webhooks**, verificar que la **Callback URL**
  apunta al webhook de n8n (`.../webhook/18c1b498-024e-4803-8088-56ccf9812f33` o la ruta del
  `whatsAppTrigger`), que está **verificada** y que el campo **`messages`** sigue suscrito. Usar
  "Test"/reenviar un evento de prueba desde Meta y ver si n8n lo recibe.
- **Duplicados:** listar workflows que contengan un `whatsAppTrigger` con el **mismo webhookId
  `18c1b498...`** y confirmar que solo el de producción lo usa (que ningún staging lo pisó).
  `GET /workflows` ya está disponible vía API para auditarlo.

**Entrega:** una línea de causa raíz + evidencia (reinicio a tal hora / captura de la config de
webhook en Meta / duplicado que compartía el path).

### 2. Reactivar la ruta de ingesta

Según la causa:

- **Re-registrar el webhook con Meta** — la vía estándar en n8n: **desactivar y volver a activar** el
  workflow `BtOaZm7WlZT-24V7hqCnF` (o re-guardar el nodo `WhatsApp Message Trigger`), lo que fuerza a
  n8n a re-suscribir la callback URL en Meta. Si eso no basta, re-configurar la suscripción
  directamente en la Meta App.
- Si fue **token caducado** → renovar la credencial `WhatsApp Hylant Account` (lo ejecuta Alberto;
  tú diagnosticas y avisas).
- Si fue un **duplicado** pisando el path → corregir el path/quitar el trigger duplicado del
  workflow que no debe tenerlo.

**Verificación OBLIGATORIA antes de cerrar (medible por API):**
- Enviar un WhatsApp entrante de prueba y confirmar:
  - Aparece una **ejecución nueva** con `startedAt > 2026-07-03T22:38:53Z` en
    `GET /executions?workflowId=BtOaZm7WlZT-24V7hqCnF`.
  - Aparece una **fila nueva** en `n8n_chat_histories` con `id > 4693`.
  - El AI Agent **responde** al mensaje (no solo que se guarda).

### 3. Alerta de "inbound caído" (2º apagón silencioso en una semana)

Segundo apagón silencioso en 7 días (el 1º: follow-up de 15 min, Issue #74). Añadir monitoreo para
no volver a descubrirlo por casualidad:

- **Mínimo viable:** workflow de n8n programado (cron cada 30–60 min) que consulte "¿cuántas
  ejecuciones webhook / filas nuevas en `n8n_chat_histories` en la última hora?" y, si es **0**
  durante la franja diurna CDMX con envíos salientes activos, notifique a Alberto
  (WhatsApp / email / Slack).
- **Recomendado además:** apuntar el campo **"Error Workflow"** del bot (hoy en "- No Workflow -") a
  un handler de errores — reutiliza el patrón de
  `docs/estrategia/2026-07-02-alerta-emision-fallida-quálitas.md`.
- **Umbral correcto:** la captura NO es 100% (~30% de sesiones tienen historial; muchos leads nunca
  responden — Bug #1). La señal fiable NO es "tasa baja" sino **"0 ejecuciones webhook entrantes
  mientras hay outbound activo"**. Este apagón concreto se habría cazado en <1h con esa regla.

---

## Al terminar (cierre del ciclo)

1. Exporta el workflow (si lo modificaste) y actualiza `docs/n8n-workflows/` en Agente-Arquitecto —
   el export actual es del 3 jul y ya se demostró que puede divergir del vivo.
2. Reporta al Arquitecto: causa raíz (tarea 1), qué reactivaste con la evidencia de la ejecución
   `startedAt > 22:38:53Z` e `id > 4693` (tarea 2), y qué alerta quedó montada (tarea 3).
3. El Arquitecto avisa al Agente Dashboard para el **rescate de los leads ~1046–1103**.

---

## Fuera de alcance de este handoff

- El **rescate** de los leads afectados (lo coordina el Arquitecto con el Dashboard).
- La renovación del **token de Meta** si resulta ser la causa (la ejecuta Alberto).

---

## Apéndice — comandos API usados para el diagnóstico (reproducibles)

```bash
BASE="https://n8n.srv1325340.hstgr.cloud/api/v1"
# Estado del workflow (active) + updatedAt
curl -s -H "X-N8N-API-KEY: $N8N_API_KEY" "$BASE/workflows?limit=50"
# Última ejecución (corte): id 2059 @ 2026-07-03T22:38:53Z, cero después
curl -s -H "X-N8N-API-KEY: $N8N_API_KEY" \
  "$BASE/executions?workflowId=BtOaZm7WlZT-24V7hqCnF&limit=20"
# Config viva del trigger
curl -s -H "X-N8N-API-KEY: $N8N_API_KEY" "$BASE/workflows/BtOaZm7WlZT-24V7hqCnF"
```
