# Hallazgo Arquitecto → Agente Dashboard — canal LANDING explica leads "sin respuesta" con póliza emitida

> Autor: Arquitecto-IA-Qualitas · 7 jul 2026
> Ejecutor: **Dashboard Qualitas** (`aibanez82/Dashboard_seguroautoqualitas`, local `~/claude-projects/Dashboard_SeguroAuto`).
> Gobernanza: reportas al Arquitecto **a través de Alberto**. No hablas con otros agentes.
> Disparador: Alberto sospechó un bug — un lead aparecía con actividad ("contestan") en el dashboard sin ninguna respuesta visible en el modal de conversación, aunque la póliza sí se emitió.

## Resumen del hallazgo

**No es un bug de lectura del Dashboard ni pérdida de datos de n8n.** El lead investigado (id `1127`, Chevrolet Sonic 2016, tel. `7298858279`, póliza `7620098203`) cerró **100% por la landing web**, nunca conversó por WhatsApp. Verificado con datos en vivo (usando `DATABASE_URL` de `~/claude-projects/Dashboard_SeguroAuto/.env.local`):

| Hora (UTC) | Evento | Fuente |
|---|---|---|
| 18:18:56 | Django envía cotización inicial por WhatsApp (`whatsapp_initial_sent`) | `qualitas_leadactionevent` |
| 18:22:46 | Link de pago generado — **4 min después** | `qualitas_leadactionevent` |
| — | Póliza `7620098203` emitida | `qualitas_polizaemitida` |

`qualitas_asegurado` (formulario web) tiene datos completos — nombre, RFC, fecha de nacimiento, calle. `n8n_chat_histories` tiene **0 filas** para el `session_id` de esa cotización. El cliente llenó el formulario en la web, no en WhatsApp — el mensaje de WhatsApp que se ve en el modal es solo la cotización inicial que el cliente ignoró.

## Patrón confirmado con muestra de 13 leads con póliza emitida

`canal_atencion` distingue limpiamente dos poblaciones (399 vs 35 leads del total):

| `canal_atencion` | Patrón | Ejemplo |
|---|---|---|
| `LANDING` (399 leads) | `conversation_phase` siempre `'greeting'`, ~0 mensajes n8n. Cierran 100% por web. | leads 1127, 1129, 1074, 875, 731 |
| `WHATSAPP` (35 leads) | Conversaciones reales de 29-48 mensajes, `conversation_phase` avanza a `payment_pending`/`completed`. | leads 1121, 1011, 937, 926 |

Esto **reinterpreta el Bug #1** (CLAUDE.md: "76% de sesiones sin historial en n8n_chat_histories") con más precisión de la que se tenía: gran parte de ese "vacío" corresponde a leads `canal_atencion='LANDING'` que **nunca estuvieron destinados a conversar por WhatsApp** — no es una falla de captura, es la ausencia esperada de datos para ese canal.

**Bonus (no es bug de este hallazgo, corrobora el Bug #7 ya conocido):** los leads `WHATSAPP` con `conversation_phase='completed'` (pagado, confirmado por n8n) siguen con `l.estado = 'COTIZACION_INICIADA'` en Django — Django no actualiza su propio estado al confirmarse el pago.

## Qué pedimos que revise el Agente Dashboard

**1. La etiqueta "Contestan" — no reproducida en código, necesita verificación en vivo.**
Revisé `computeEstadoNegocio` (`components/FunnelV2.js:105-110`): chequea `l.numero_poliza` (→ `POLIZA_EMITIDA`) **antes** que la condición de `CONTESTAN` — un lead con póliza emitida no debería caer en el bucket "Contestan" por ese código. Tampoco until el `SQL_FUNNEL` (`pages/api/db-leads.js:86-89`, filtro `ws.conversation_phase != 'greeting'`) cuenta a este lead como "contestan" (su `conversation_phase` es `'greeting'`). **No pude reproducir dónde Alberto vio la etiqueta "Contestan" para este lead específico.** Pedimos: (a) confirmar con Alberto en qué vista/columna exacta la vio; (b) si existe otro punto de la UI que clasifique por un campo distinto (p. ej. `l.estado` de Django crudo, sin pasar por `computeEstadoNegocio`), identificarlo y ver si necesita el mismo guard de `numero_poliza`.

**2. Considerar usar `canal_atencion` explícitamente en la UI para leads `LANDING` sin conversación.**
Hoy estos leads dependen de la combinación `estado='POLIZA_EMITIDA' AND conversation_phase IN ('greeting', NULL)` para caer en el bucket "online" (`pages/api/db-leads.js:91-95`, `SQL_FUNNEL`). Es correcto, pero indirecto — dado que `canal_atencion` ya distingue esto de forma limpia (confirmado con la muestra de 13 leads), evaluar si conviene usarlo directamente como señal primaria en vez de inferirlo por ausencia de conversación. Menor, no bloqueante.

**3. Posible artefacto de timezone en `whatsapp_sessions.created_at`.**
`whatsapp_sessions.created_at` para este lead apareció ~6h después del envío real de Django (`qualitas_leadactionevent.occurred_at`) — el delta coincide exacto con el offset UTC-6 de CDMX. Hipótesis: la columna es `timestamp without time zone` (hora local CDMX) y el driver de Postgres del Dashboard la interpreta como UTC sin convertir, sumando 6h de más en cualquier comparación directa. **Esto es relevante para `pages/api/conversation.js:52-59`**, donde `sessionStart` (de `whatsapp_sessions.created_at`) se usa para anclar los mensajes de n8n (sin timestamp real) contra los mensajes de Django (con timestamp real) en el timeline del modal — si el offset es sistemático, el ancla podría estar desplazando el bloque de mensajes n8n 6h respecto a donde debería ir, para leads que **sí** tienen conversación. Pedimos: confirmar el tipo de columna (`\d whatsapp_sessions` o `information_schema.columns`) y, si se confirma `timestamp without time zone`, decidir si corregir en la query (`AT TIME ZONE 'America/Mexico_City'` o similar) o documentarlo como límite conocido.

## Fuera de alcance

No se tocó código ni BD — todo lo de arriba es solo lectura/diagnóstico. Cualquier cambio de código lo ejecuta el Agente Dashboard; cualquier cambio de infraestructura/schema pasa por Juan.
