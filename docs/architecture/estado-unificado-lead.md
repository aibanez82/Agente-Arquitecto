# Propuesta: Estado Unificado del Lead

> Documento técnico para el equipo de Django / admin de base de datos.
> Contexto: sistema Django con leads que pueden avanzar por dos canales (WhatsApp y Web/Landing).

---

## Contexto y problema actual

El sistema tiene dos tablas que reflejan el avance del lead de forma independiente:

| Tabla | Campo | Qué refleja |
|---|---|---|
| `qualitas_lead` | `estado` | Estado de negocio desde Django |
| `whatsapp_sessions` | `conversation_phase` | Estado conversacional del bot (n8n) |

Esto funciona bien mientras un lead avanza por un solo canal. El problema aparece cuando:

1. **El lead avanza por web sin responder WhatsApp** → `qualitas_lead.estado` avanza a `DATOS_EMISION_INICIADOS` o `POLIZA_EMITIDA`, pero `conversation_phase` se queda en `greeting`. Para saber que ese lead cerró por web hay que cruzar ambas tablas e inferirlo.

2. **Desincronización de estados** → El lead 696 (confirmado en producción) llegó a `PAGO_APROBADO` según Google Sheets, pero `qualitas_lead.estado` quedó en `DATOS_EMISION_COMPLETADOS`. El estado real del lead es ambiguo sin investigar los dos registros.

3. **Queries complejas** → Cualquier reporte sobre el estado real de un lead requiere un JOIN entre `qualitas_lead`, `qualitas_cotizacion` y `whatsapp_sessions`, más lógica condicional para decidir cuál tabla "gana".

---

## Regla de negocio actual (documentada)

Mientras no se cambie el esquema, el estado real de un lead se determina con esta prioridad:

```
SI conversation_phase = 'completed'
  → Lead PAGADO (independientemente de qualitas_lead.estado)

SI qualitas_lead.estado = 'POLIZA_EMITIDA'
  Y conversation_phase = 'greeting' o NULL
  → Lead ONLINE (cerró por web sin pasar por WhatsApp)

SI conversation_phase IN ('data_capture', 'summary_confirmation', 'policy_issuance', 'payment_pending')
  → Lead en flujo WhatsApp activo

SI conversation_phase = 'greeting'
  Y qualitas_lead.estado = 'COTIZACION_INICIADA'
  Y fecha_creacion < NOW - 48h
  → Lead ABANDONADO

SI conversation_phase = 'greeting'
  Y qualitas_lead.estado = 'COTIZACION_INICIADA'
  Y fecha_creacion >= NOW - 48h
  → Lead EN ESPERA
```

Esta lógica está centralizada en `lib/metrics.js` del dashboard y es la única fuente de cálculo de KPIs.

---

## Propuesta: columnas `estado_unificado` y `canal_final` en `qualitas_lead`

### Qué agregar

```sql
ALTER TABLE qualitas_lead
  ADD COLUMN estado_unificado VARCHAR(50),
  ADD COLUMN canal_final       VARCHAR(20);
```

### Valores de `estado_unificado`

| Valor | Significado |
|---|---|
| `LEAD` | Formulario completado, cotización enviada por WA |
| `EN_ESPERA` | Recibió WA, no ha respondido (< 48h) |
| `CONTESTAN` | Respondió al WhatsApp, dando datos |
| `DATOS_CONFIRMADOS` | Confirmó todos los datos, pendiente de emitir |
| `POLIZA_EMITIDA` | Póliza emitida, pago pendiente |
| `PAGADO` | Pago confirmado. Venta cerrada |
| `ONLINE` | Cerró por web sin pasar por WhatsApp |
| `ABANDONADO` | Sin respuesta más de 48h |

### Valores de `canal_final`

| Valor | Significado |
|---|---|
| `WHATSAPP` | El lead avanzó y cerró por WhatsApp |
| `WEB` | El lead avanzó y cerró por la landing/web |
| `NULL` | Aún no se ha determinado (lead reciente) |

### Cuándo actualizar estos campos

El sistema Django debería actualizar `estado_unificado` y `canal_final` en estos momentos:

```
Al crear un lead (COTIZACION_INICIADA):
  → estado_unificado = 'LEAD', canal_final = NULL

Al registrar respuesta en WhatsApp (data_capture):
  → estado_unificado = 'CONTESTAN', canal_final = 'WHATSAPP'

Al avanzar en web (DATOS_EMISION_INICIADOS sin respuesta WA):
  → estado_unificado = 'CONTESTAN', canal_final = 'WEB'

Al completar datos (summary_confirmation / DATOS_EMISION_COMPLETADOS):
  → estado_unificado = 'DATOS_CONFIRMADOS'

Al emitir póliza (POLIZA_EMITIDA / payment_pending):
  → estado_unificado = 'POLIZA_EMITIDA'

Al confirmar pago (completed / PAGO_APROBADO):
  → estado_unificado = 'PAGADO'

Por job nocturno (leads > 48h sin actividad en greeting):
  → estado_unificado = 'ABANDONADO'
```

---

## Implementación recomendada (bajo impacto)

### Fase 1 — Inmediata (sin cambios en producción)
✅ Ya implementado: lógica centralizada en `lib/metrics.js` del dashboard.
El dashboard calcula el estado unificado en memoria al leer los datos.

### Fase 2 — Corto plazo (bajo riesgo)
Agregar las dos columnas a `qualitas_lead` como `NULLABLE` (sin valor por defecto).
No rompe nada existente. El sistema puede poblarlas gradualmente.

```sql
-- Migración segura, reversible, sin downtime
ALTER TABLE qualitas_lead
  ADD COLUMN IF NOT EXISTS estado_unificado VARCHAR(50),
  ADD COLUMN IF NOT EXISTS canal_final       VARCHAR(20);

-- Índice para queries del dashboard
CREATE INDEX IF NOT EXISTS idx_lead_estado_unificado
  ON qualitas_lead(estado_unificado);
```

### Fase 3 — Medio plazo
Actualizar el código Django para mantener estas columnas en cada transición de estado.
El dashboard pasa a leer `estado_unificado` directamente en vez de calcular con JOINs.

---

## Caso de uso que motivó esta propuesta

**Lead 696 — Soraida Varas (15 jun 2026)**

| Fuente | Estado registrado |
|---|---|
| `qualitas_lead.estado` | `DATOS_EMISION_COMPLETADOS` |
| `whatsapp_sessions.conversation_phase` | (sin sesión activa) |
| Google Sheets (job exportar_leads) | `PAGO_APROBADO` |

El estado real es ambiguo. Con `estado_unificado`, este lead debería tener `PAGADO` y ese valor no cambiaría aunque `qualitas_lead.estado` retroceda por algún bug.

---

## Beneficios esperados

- **Una sola query** para el estado de cualquier lead, sin JOINs complejos
- **Resistencia a desincronizaciones** — el estado unificado es la fuente de verdad
- **Trazabilidad de canal** — sabes exactamente si el lead cerró por WA o por web
- **Dashboard más simple** — `lib/metrics.js` desaparece casi completamente
- **Facilita agentes** — un agente que reacciona a cambios de estado solo necesita leer una columna

---

*Documento generado el 22 jun 2026. Autor: equipo dashboard Qualitas/Hylant.*
*Para preguntas técnicas, contactar con el admin de Django.*
