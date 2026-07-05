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

### 🥇 Sospecha PRINCIPAL — colisión de webhookId con workflows duplicados (CONFIRMADA por API, 5 jul)

**Escaneé los 15 workflows de la instancia. CUATRO comparten el mismo `webhookId`
`18c1b498-024e-4803-8088-56ccf9812f33` (la misma ruta de webhook):**

| active | Workflow | id |
|---|---|---|
| ✅ **true** | `WhatsApp Insurance Quotation Bot` (producción) | `BtOaZm7WlZT-24V7hqCnF` |
| ❌ false | `WhatsApp Insurance Quotation Bot_stg` | `0KX6Tg0ljmpIVtFslubUA` |
| ❌ false | `WhatsApp Insurance Quotation Bot` (copia) | `CPcP1m8sURQIOAGgCN8s0` |
| ❌ false | `WhatsApp Insurance Quotation Bot_STG` | `DFg__oxPp2x2uaXkhvj44` |

Los 3 duplicados nacieron de copiar el workflow de producción — n8n **no regenera el `webhookId` al
duplicar**, así que heredan la misma ruta.

**Mecánica del fallo:** la ruta del webhook se deriva del `webhookId`. Si se **activa y luego
desactiva** cualquiera de esas copias que comparte `18c1b498`, al desactivarla n8n **borra el
registro de esa ruta** del webhook. Producción queda **huérfana**: `active:true` pero sin webhook
registrado. Meta hace POST a una ruta que ya no existe → **cero ejecuciones, en silencio, sin
errores**. Encaja al 100% con lo observado (corte seco 22:38:53 UTC, sin ejecución fallida). Y
explica por qué es el **2º apagón silencioso en una semana**: cada toque a un `_STG` que colisiona
tumba producción. (El `updatedAt` 04-jul de las copias no lo descarta: activar/desactivar NO
actualiza `updatedAt`.)

**Corroboración por API:** el duplicado `CPcP1m8sURQIOAGgCN8s0` **recibió ejecuciones `mode:webhook`
reales de Meta el 01–02 jul** (ids 1953–1961) — prueba de que la ruta compartida `18c1b498`
efectivamente se turnó entre workflows (Meta POSTeaba a la copia cuando estaba activa). Los otros dos
duplicados (`0KX6...`, `DFg__...`) no tienen ejecuciones: consistente con activarse→desactivarse sin
llegar a recibir un mensaje, des-registrando la ruta sin dejar rastro. La colisión no es teórica: ya
ocurrió.

### Sospechas secundarias (descartar si la #1 no cuadra)

2. **Reinicio de Hostinger ~22:38 UTC del 03-jul sin re-registrar el webhook.** Verificar logs de la
   instancia / panel Hostinger.
3. **Token/credencial de Meta caducado** (`WhatsApp Hylant Account`, id `bUWR11VM0seHo63P`). En
   Pendientes de infra ya figura "Regenerar token Meta Business API" como urgente.

---

## Tareas (en orden)

### 1. Confirmar la causa (la #1 ya está medio confirmada; cerrarla)

- **Colisión de webhookId (sospecha #1, ya evidenciada):** el hecho está confirmado (4 workflows con
  `18c1b498`). Lo que falta es correlacionar con el toggle: revisar el **historial de ejecuciones de
  los 3 duplicados** (`0KX6...`, `CPcP1...`, `DFg__...`) — si alguno tiene una ejecución o cambio de
  estado cerca del 03-jul 22:38 UTC, es la pistola humeante. `GET /executions?workflowId=<id>`.
- **Secundaria — instancia:** ¿reinicio / redeploy de Hostinger ~22:38 UTC del 03-jul? (logs n8n /
  panel Hostinger).
- **Secundaria — Meta App:** en **Meta → WhatsApp → Configuration → Webhooks**, verificar que la
  **Callback URL** apunta a la ruta del `whatsAppTrigger` (`.../webhook/18c1b498-...`), que está
  **verificada** y que **`messages`** sigue suscrito.

**Entrega:** una línea de causa raíz + evidencia.

### 2. Reactivar la ruta de ingesta + eliminar la colisión (fix durable)

**(a) Reactivar producción:** **desactivar y volver a activar** el workflow `BtOaZm7WlZT-24V7hqCnF`
(o re-guardar el nodo `WhatsApp Message Trigger`) → fuerza a n8n a re-registrar la ruta del webhook.
Si no basta, re-configurar la suscripción en la Meta App.

**(b) ⚠️ Eliminar la colisión — SIN esto, se vuelve a caer:** los 3 duplicados que comparten
`18c1b498` (`0KX6...`, `CPcP1...`, `DFg__...`) son una bomba de relojería: el próximo toque a
cualquiera vuelve a des-registrar producción. Para cada uno, elegir UNA:
   - **Borrarlo** si ya no sirve (hay `_BCK_2jul`, `copy`, y varios `_STG` — consolidar).
   - Si debe conservarse (staging real), **regenerar su `webhookId`** para que NO colisione con
     producción — en la UI: abrir el nodo `WhatsApp Message Trigger` del duplicado y regenerar el
     webhook (o borrar y recrear el nodo trigger), de modo que reciba una ruta propia distinta de
     `18c1b498`.
   - **Ningún workflow de staging debe compartir el `webhookId` de producción.** Es la causa
     estructural de los apagones repetidos.

**(c) Si fue token caducado** → renovar la credencial `WhatsApp Hylant Account` (lo ejecuta Alberto).

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
