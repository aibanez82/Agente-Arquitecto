# Respuesta a Juan — verificación de `checkpoint_followups` en STG

**Fecha:** 16 jul 2026
**De:** Arquitecto-IA-Qualitas (vía Alberto)
**Para:** Juan
**Contexto:** verificación en vivo (código en `stg` + datos reales de Postgres/n8n STG, no solo lectura
del reporte) de `docs/2026-07-16-handoff-para-juan-seguimiento-leads-consolidado.md` y del reporte
detallado de Juan (`reporte-alberto-n8n-checkpoint-followups-whatsapp.md`).

## Resumen para Alberto

La implementación de Django está sólida y coincide con casi todo el contrato que Juan documentó.
Encontré **un solo gap real, pero crítico**: no está del lado de Django, está en que el workflow de
n8n (`Retomar Conversación`) todavía no cumple el contrato que el propio Juan describió. Todo lo
demás está listo. Confirmé todo contra código y datos reales, no contra lo que dicen los reportes.

## 1. Lo que Juan documentó y confirmé que SÍ está así en el código de `stg`

- Migración `0041_lead_checkpoint_followups.py`: modelos `LeadFollowupPolicy` +
  `LeadCheckpointFollowupAttempt` exactamente como describe, con `UNIQUE(checkpoint, attempt)` y
  `UNIQUE(cotizacion, checkpoint, attempt)` + `CHECK(attempt BETWEEN 1 AND 3)`.
- Los 7 checkpoints y sus condiciones de derivación (`conversation_phase`/`captured_data.grupoN`)
  coinciden línea por línea con el código real de `qualitas/whatsapp_checkpoint_followups.py`.
- Ventana de 24h, `delay_mins` por política, tope de 3 intentos, exclusión cuando ya hay póliza
  emitida (salvo `payment_link_sent`) — todo implementado tal cual documenta.
- Idempotencia real: `LeadCheckpointFollowupAttempt` con `select_for_update` + `UNIQUE`, más
  bitácora en `LeadActionEvent` (`queued`/`sent`/`failed`/`skipped`) — confirmado con los tests del
  repo, no solo con la descripción.
- Fixture cargado en la BD real de STG: 21 filas (7 checkpoints × 3 intentos), los 6 activos con
  `delay_mins=1`, `payment_link_sent` con sus 3 filas en `active=false` — verificado con SQL directo
  contra `qualitas_leadfollowuppolicy` en STG, no asumido.
- Flags seguros por default: `WHATSAPP_CHECKPOINT_FOLLOWUPS_ENABLED=false`,
  `WHATSAPP_CHECKPOINT_FOLLOWUPS_DRY_RUN_DEFAULT=true` — confirmado contra las config vars reales de
  `hyl-wai-stg` vía la API de Heroku. Nada puede enviarse de verdad todavía, ni por accidente.

## 2. 🔴 El gap real — n8n no cumple el contrato de `session_id` que Juan mismo describió

Juan es explícito en su reporte (sección 3.3, punto 4, y sección 9.1, y lo repite como checklist en
la sección 15): **`proactive-wa-message` debe escribir el historial con
`n8n_chat_histories.session_id = body.session_id`**, tratando `conversation_id` únicamente como
metadata/compatibilidad, nunca como la clave de inserción.

**Verifiqué el nodo real del workflow `Retomar Conversacion_stg` (vía API de n8n, no el JSON local
que puede estar desactualizado) y NO hace eso.** El nodo `Execute a SQL query` resuelve la clave de
inserción así:

```text
{{ $json.body.conversation_id || $json.body.session_id || $json.body.phone_number }}
```

Es decir, si `conversation_id` viene con valor, **gana sobre `session_id`** — exactamente lo
contrario de lo que pide el checklist de Juan. Esto no es hipotético: verifiqué contra la Postgres
real de STG que **ya hay 3 sesiones activas** donde `session_id` (teléfono) y `conversation_id`
(formato `waq_...`) son distintos y ambos están poblados — cotizaciones **1711, 1712 y 1704**. Si
cualquiera de esas tres llega a un checkpoint elegible una vez se active el envío real, el mensaje
de seguimiento se insertaría con la clave `waq_...`, no con el teléfono — el bot principal, que lee
`n8n_chat_histories` por teléfono (confirmado: 0 de 1,784 filas históricas usan formato
`conversation_id`), nunca vería ese mensaje. El cliente no recibiría contexto de continuidad aunque
el log de Django diga `sent`.

**Esto es un gap de n8n, no de Django.** El nodo de `Retomar Conversación` quedó con la lógica de
prioridad `conversation_id || session_id || phone_number` de la iniciativa de migración a
`conversation_id` (pensada para otro caso de uso — desambiguar múltiples cotizaciones activas del
mismo teléfono). Nadie reconcilió ese cambio con este contrato nuevo de `checkpoint_followups`, que
asume lo contrario: que `session_id` manda siempre porque Django ya resolvió la sesión correcta antes
de llamar.

**Acción concreta:** que Agente n8n ajuste el nodo `Execute a SQL query` de `Retomar Conversacion`
(STG primero) para que la clave de inserción sea `body.session_id` directo — sin fallback a
`conversation_id` — cumpliendo el contrato que Juan ya especificó. Antes de aplicarlo, vale la pena
confirmar que ningún otro llamador de este mismo webhook (el botón "Tomar conversación" del
Dashboard) dependa de la prioridad de `conversation_id` — por lo que sé hoy, el Dashboard no manda
`conversation_id` en su payload, así que el cambio debería ser seguro, pero que Agente n8n lo
confirme antes de tocarlo.

## 3. Descartado — solapamiento con el scheduler viejo de 15 min

Alberto aclaró y confirmé en código: ese mecanismo (`WHATSAPP_FOLLOWUPS_ENABLED=1`,
`qualitas/whatsapp_followups.py`) no se solapa con `checkpoint_followups`. El nombre "15 min" es
histórico — el delay real en STG es `WHATSAPP_QUOTE_FIRST_FOLLOWUP_DELAY_MINUTES=4` — y solo se
dispara cuando el cliente **no ha respondido nada** a la plantilla inicial
(`evaluate_n8n_activity_for_followup` lo bloquea con `n8n_human_message_detected` en cuanto hay
cualquier mensaje humano, y exige `conversation_phase == 'greeting'`). `checkpoint_followups` exige
lo contrario: mensaje humano reciente y fase ya avanzada. Poblaciones mutuamente excluyentes por
diseño — no hace falta que Juan resuelva nada aquí. (Bug #13 sigue siendo un problema real, pero
aislado al scheduler viejo, no afecta a este parche.)

## 4. Nota aparte, no bloqueante — plantilla de Meta

Al revisar el código encontré que `WHATSAPP_TEMPLATE_QUOTE_FOLLOWUP_15M=cotizacion_followup_15m` es
una plantilla de Meta **ya aprobada y en uso** (por el scheduler viejo, vía
`enviar_template_whatsapp`). No es genérica para "recordatorio de fecha futura" (iniciativa aparte,
`docs/iniciativas/2026-07-10-recordatorios-seguimiento-por-fecha-mencionada-design.md`), pero
confirma que el camino de aprobación con Meta ya funciona para esta cuenta — vale la pena que Juan
intente una variante rápida ahí en vez de partir de cero. No aplica a `checkpoint_followups`: ese
sistema solo manda texto libre dentro de la ventana de 24h, tal como documentó Juan en la sección 16
("No usar plantillas WhatsApp aquí").

## Checklist de Juan (sección 15) — estado real verificado

- [x] `conversation_phase` usa los 6 valores reales — confirmado.
- [x] `captured_data` conserva `grupo1`/`grupo2`/`grupo3`/`requiere_factura`/`rfc` — confirmado, sin
      cambios recientes de nombres.
- [ ] **`proactive-wa-message` escribe historial con `session_id = body.session_id`** — **FALLA hoy**
      en `Retomar Conversacion_stg` (ver punto 2 arriba). Es el único ítem de su propia lista que no
      se cumple todavía.
- [ ] Idempotencia por `idempotency_key` del lado de n8n — no verificado todavía (el nodo actual no
      la implementa explícitamente; Django ya protege su propio lado, pero si n8n reintenta por
      timeout de red podría duplicar el envío de WhatsApp aunque no duplique el registro en Django).
- El resto de la checklist (esquema de `whatsapp_sessions`, tipos de mensaje, timestamps) — sin
  cambios desde que se verificó para la iniciativa de `conversation_id`, sigue vigente.

## Próximo paso propuesto

1. Agente n8n corrige el nodo de `Retomar Conversacion` (STG, luego PROD) para que la clave de
   inserción sea `body.session_id` sin fallback a `conversation_id`.
2. Alberto comparte el token de `N8N_PROACTIVE_WA_MESSAGE_TOKEN` por canal seguro para que Juan lo
   configure en `hyl-wai-stg` junto con `N8N_PROACTIVE_WA_MESSAGE_URL`.
3. Con eso, activar `WHATSAPP_CHECKPOINT_FOLLOWUPS_ENABLED=true` en STG solo en modo `--dry-run`
   primero, revisar candidatos reales, y solo después probar envío real con números autorizados.

(El solapamiento con el scheduler viejo de 15 min que se preguntaba en una versión anterior de este
documento queda descartado — ver punto 3 arriba: son poblaciones mutuamente excluyentes por diseño,
no requiere que Juan resuelva nada.)
