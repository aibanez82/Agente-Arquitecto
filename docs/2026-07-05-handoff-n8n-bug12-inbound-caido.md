# Handoff al Agente n8n — Bug #12: reactivar la ingesta de mensajes entrantes de WhatsApp

> Autor: Arquitecto-IA-Qualitas (Nivel 2)
> Ejecutor: Agente n8n (Nivel 3)
> Fecha: 5 julio 2026
> Origen: Bug #12 (ver `docs/2026-07-05-mensaje-arquitecto-inbound-n8n-caido.md`)
> Criticidad: 🔴 Crítico — leads reales conversando sin quedar registrados
> Regla de oro: este handoff pasa por el Arquitecto; el Agente Dashboard y tú NO os habláis directamente.

---

## Contexto en una frase

Desde el **2026-07-03 ~22:30 UTC** los mensajes **entrantes** de WhatsApp dejaron de guardarse en
`n8n_chat_histories`. Django y el envío saliente funcionan bien → el fallo está **acotado a la ruta
de ingesta de n8n** (Meta Cloud API → trigger de n8n → memoria Postgres). Último mensaje capturado:
`n8n_chat_histories.id = 4693` (lead 1045).

---

## Workflow y nodos implicados

**Workflow:** `WhatsApp Insurance Quotation Bot`
(export local: `docs/n8n-workflows/WhatsApp Insurance Quotation Bot.json` — ⚠️ export del 3 jul,
puede NO reflejar el estado vivo en producción; verifica contra n8n en vivo).

| Nodo | Tipo | id | Rol en la ingesta |
|---|---|---|---|
| `WhatsApp Message Trigger` | `n8n-nodes-base.whatsAppTrigger` | `80dccf45-763c-48d4-92fa-4fdf1925bfd4` | **Punto de entrada** de los mensajes entrantes de Meta. webhookId `18c1b498-024e-4803-8088-56ccf9812f33`. **Principal sospechoso.** |
| `Postgres Chat Memory` | `@n8n/n8n-nodes-langchain.memoryPostgresChat` | `3769734b-...` | Escribe el historial en `n8n_chat_histories` (memoria del AI Agent). |
| `Postgres Chat Memory1` | `@n8n/n8n-nodes-langchain.memoryPostgresChat` | `8fd23ae6-...` | Segundo punto de escritura de memoria. |

> Nota: en el export local el workflow figura `active: true`, pero eso es del 3 jul (antes/durante el
> corte). El estado que importa es el **vivo en n8n**. No asumas que está activo.

---

## Tareas (en orden)

### 1. Diagnóstico — ¿qué pasó a las ~22:30 UTC del 2026-07-03?

Revisa el **log de ejecuciones** del workflow `WhatsApp Insurance Quotation Bot` alrededor de esa
hora (Executions en la UI, o `GET /api/v1/executions?workflowId=...&includeData=true`). Busca:

- ¿El workflow se **desactivó** (active=false) en ese instante? ¿Hay un release / import / edición
  que coincida con la hora?
- ¿Hay ejecuciones **fallando** en el `WhatsApp Message Trigger` o justo después (error de webhook,
  de credencial de Meta, de conexión Postgres)?
- ¿Dejaron de **entrar ejecuciones** por completo desde las ~22:30 UTC? (Si no hay ninguna ejecución
  entrante desde esa hora → el webhook de Meta ya no está llegando: apunta a suscripción de Meta
  caída o webhook de n8n despublicado, no a un error interno.)
- Revisa también reinicios/caídas de la instancia Hostinger a esa hora.

**Entrega:** una línea de causa raíz (qué se rompió y por qué) + evidencia (id de ejecución, captura
del error, o "sin ejecuciones desde HH:MM").

### 2. Reactivar la ruta de ingesta

Según lo que encuentres en (1):

- Si el workflow quedó **inactivo** → reactivarlo.
- Si el **webhook de Meta** dejó de apuntar a n8n / se despublicó → re-registrar la suscripción del
  `WhatsApp Message Trigger` (re-guardar/re-activar el nodo republica el webhook) y verificar en
  **Meta → WhatsApp → Configuration → Webhooks** que la Callback URL y los campos suscritos
  (`messages`) siguen correctos y verificados.
- Si fue un **error de credencial** (token de Meta expirado) → renovar. Ojo: en Pendientes de infra
  ya figura "Regenerar token Meta Business API" como urgente — puede ser la causa.

**Verificación de que quedó arreglado (obligatoria antes de cerrar):**
- Enviar un mensaje de prueba entrante y confirmar que aparece una **fila nueva** en
  `n8n_chat_histories` con `id > 4693`.
- Confirmar que el AI Agent **responde** al mensaje entrante (no solo que se guarda).

### 3. Alerta de "inbound caído" (2º apagón silencioso en una semana)

Este es el **segundo apagón silencioso en 7 días** (el 1º: follow-up de 15 min, Issue #74). No
queremos volver a enterarnos por casualidad. Añadir monitoreo:

- **Mínimo viable:** un workflow de n8n programado (cron, p. ej. cada 30–60 min) que consulte
  "¿cuántas filas nuevas entraron en `n8n_chat_histories` en la última hora?" y, si es **0** durante
  la franja de actividad (horario diurno CDMX), dispare una **notificación a Alberto**
  (WhatsApp / email / Slack).
- **Recomendado además:** apuntar el campo **"Error Workflow"** del `WhatsApp Insurance Quotation
  Bot` a un handler de errores (reutiliza el patrón ya especificado en
  `docs/estrategia/2026-07-02-alerta-emision-fallida-quálitas.md`, sección "n8n — workflow de error
  dedicado"). Hoy está en "- No Workflow -", por eso los fallos son mudos.

**Umbral de la alerta:** ojo con el baseline — la captura NO es 100%: ~30% de sesiones tienen
historial (muchos leads nunca responden, Bug #1). Por eso la señal fiable NO es "tasa baja" sino
**"0 filas nuevas durante una franja con envíos salientes activos"**. Usa "cero entrante mientras hay
outbound" como condición, no un porcentaje.

---

## Al terminar (cierre del ciclo)

1. Exporta el workflow modificado y actualiza `docs/n8n-workflows/` en este repo (mantener la fuente
   de verdad sincronizada — hoy el export es del 3 jul).
2. Reporta al Arquitecto: causa raíz (tarea 1), qué reactivaste (tarea 2, con la evidencia de
   `id > 4693`), y qué alerta quedó montada (tarea 3).
3. El Arquitecto avisa al Agente Dashboard para el **rescate de los leads ~1046–1103** (revisar en
   WhatsApp Business quiénes respondieron durante el apagón y retomarlos).

---

## Fuera de alcance de este handoff

- El **rescate** de los leads afectados (lo coordina el Arquitecto con el Dashboard, no es cambio de
  workflow).
- La renovación del **token de Meta** si resulta ser la causa (la ejecuta Alberto; tú diagnosticas y
  avisas).
