# Spec — Detectar y visibilizar fallas de emisión de póliza (Bug #9, causa externa a Quálitas)

> Autor: Arquitecto-IA-Qualitas · Fecha: 2 julio 2026
> Repos destino: n8n (workflow nuevo) + `aibanez82/Dashboard_seguroautoqualitas`
> Origen: Bug #9 — `POST /api/emitir-externo/` devuelve HTTP 400 recurrente ("Experimentamos
> intermitencias con el sistema de la aseguradora"). Causa raíz probablemente del lado de
> Quálitas (intermitente) — no es corregible desde aquí. Lo que sí es controlable: enterarnos
> cuando pasa, para no depender de que el cliente le dé clic al link de escalamiento a un agente
> humano que ya manda el bot.

## Problema

Cuando `Issue_Policy` falla, el system prompt del AI Agent ya maneja el caso: muestra al cliente
un mensaje de respaldo con link de escalamiento, y agrega la marca `[api_error:issue_policy]` en
su respuesta (queda en `n8n_chat_histories`). Pero nadie lo monitorea activamente — no hay
alerta, no hay registro en tabla dedicada, no aparece en el Dashboard. Si el cliente no le da
clic al link, el lead se pierde en silencio.

## Diseño — dos piezas

### 1. n8n — workflow de error dedicado

Nuevo workflow (ej. `Bot Error Handler`), conectado como **Error Workflow** del workflow
principal (`WhatsApp Insurance Quotation Bot` → Settings → "Error Workflow (to notify when this
one errors)", hoy en "- No Workflow -").

Nodos:
1. **Error Trigger** (`n8n-nodes-base.errorTrigger`) — se dispara automáticamente cuando
   cualquier nodo del bot principal falla. Recibe `execution.id`, `workflow.name`, info del error.
2. **HTTP Request** → `GET https://n8n.srv1325340.hstgr.cloud/api/v1/executions/{{$json.execution.id}}?includeData=true`
   con header `X-N8N-API-KEY` — trae el detalle completo de la ejecución fallida.
3. **Code** — extrae `quotation_id`/`session_id` del output del nodo `Merge Session Data` o
   `Load Session` dentro de esa ejecución (la forma exacta de extracción hay que ajustarla una vez
   que se vea el JSON real que devuelve el endpoint de ejecuciones — puede variar según qué nodo
   alcanzó a correr antes de la falla).
4. **Postgres** → `INSERT INTO qualitas_leadactionevent (lead_id, event_type, source, created_at, metadata)
   VALUES ($1, 'policy_issuance_failed', 'n8n', NOW(), $2)` — reusa el patrón de eventos que ya
   existe ahí (`whatsapp_initial_sent`, `whatsapp_followup_15m_sent`, etc.). `metadata` guarda el
   nodo que falló y el mensaje de error, para diagnóstico posterior.
5. *(Opcional, recomendado)* Notificación inmediata — Slack, email, o WhatsApp a Alberto — para
   seguimiento manual del lead sin esperar a que alguien revise el Dashboard.

No requiere cambios en Django ni en el workflow principal más allá de apuntar el campo
"Error Workflow" a este nuevo workflow.

### 2. Dashboard — tarjeta "⚠️ Emisión falló"

Ubicación: al lado de la tarjeta/caja existente de **"No contestan"**, mismo estilo visual.

**Alcance: solo casos activos** — no un acumulado histórico. Un lead sale de esta tarjeta en
cuanto consigue una póliza emitida en un reintento posterior (igual que "No contestan" refleja
estado actual, no un conteo que solo crece).

**Query sugerida:**
```sql
SELECT COUNT(DISTINCT lae.lead_id) AS leads_con_emision_fallida
FROM qualitas_leadactionevent lae
WHERE lae.event_type = 'policy_issuance_failed'
  AND NOT EXISTS (
    SELECT 1
    FROM qualitas_polizaemitida p
    JOIN qualitas_cotizacion c ON p.cotizacion_id = c.id
    JOIN qualitas_lead l ON l.cotizacion_id = c.id
    WHERE l.id = lae.lead_id
      AND p.numero_poliza IS NOT NULL
  );
```

Para listar los leads afectados (si la tarjeta es clickable, como las demás):
```sql
SELECT DISTINCT lae.lead_id, lae.created_at AS fecha_falla, lae.metadata
FROM qualitas_leadactionevent lae
WHERE lae.event_type = 'policy_issuance_failed'
  AND NOT EXISTS (
    SELECT 1 FROM qualitas_polizaemitida p
    JOIN qualitas_cotizacion c ON p.cotizacion_id = c.id
    JOIN qualitas_lead l ON l.cotizacion_id = c.id
    WHERE l.id = lae.lead_id AND p.numero_poliza IS NOT NULL
  )
ORDER BY lae.created_at DESC;
```

### Criterios de aceptación

1. Cuando `Issue_Policy` falla en producción, aparece un nuevo registro
   `event_type='policy_issuance_failed'` en `qualitas_leadactionevent` en cuestión de segundos.
2. La tarjeta del Dashboard muestra el conteo de leads activos con emisión fallida, junto a
   "No contestan".
3. Un lead desaparece de la tarjeta automáticamente en cuanto tiene una póliza emitida
   (`qualitas_polizaemitida.numero_poliza` no nulo) — no hace falta marcarlo manualmente como
   resuelto.
4. La tarjeta no depende de que el cliente haya usado el link de escalamiento — se activa
   directo desde la falla técnica.

### Nota

Actualizar `docs/architecture/estado-unificado-lead.md` para incluir este nuevo estado
(`policy_issuance_failed` sin póliza posterior) en la tabla de fuentes de verdad por campo.
