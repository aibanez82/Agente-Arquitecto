# Control humano ↔ IA de una conversación WhatsApp (handoff sin interferencia)

> Iniciativa iniciada 24 jul 2026 por Alberto. Diseño del Arquitecto.
> Objetivo: que la intervención de un agente humano (botón "Tomar conversación" del Inbox)
> no interfiera con la IA, y que al devolver el control la IA retome con la conversación
> completa. **Debe encajar con la redefinición de estados de conversación que está haciendo
> Juan** (ver §6).

Estado: **diseño aprobado, sin implementar.** No promover nada a PROD hasta cerrar §6 con Juan.

---

## 1. Qué existe hoy y qué falta

El botón "tomar conversación" ya no es el `ProactiveModal` viejo — es la pestaña **Inbox**
(iniciativa `docs/iniciativas/2026-07-23-inbox-contact-center-login-individual.md`, desplegada
en STG). Trae ya el ciclo **claim → release** modelado:

- `dashboard_conversation_claims` — quién tomó qué lead, con `released_at` e índice único
  parcial (`WHERE released_at IS NULL`) que garantiza a nivel de BD **un solo agente por lead
  a la vez**.
- `dashboard_message_audit` — auditoría de mensajes enviados desde el Inbox.

**Implicación:** el botón "Soltar conversación a IA" que pide Alberto ya tiene su gancho
estructural — es poner `released_at`. No hay que inventar tabla.

**El hueco real (= la interferencia que se quiere resolver):** esas tablas son del Dashboard,
sin FK al schema de Django, y **n8n no sabe que existen**. Hoy, tomar una conversación en el
Inbox registra quién la tomó y audita lo que el humano manda, pero **no calla a la IA**:

- Si entra un mensaje del cliente mientras el humano teclea → el bot de n8n responde igual.
- El scheduler de `seguimiento-leads-estancados` puede disparar un recordatorio en medio de la
  conversación humana.

Nadie le dice a n8n "quieto, aquí manda una persona".

---

## 2. Reencuadre: dos dimensiones ortogonales

No es un estado más de la conversación. Son dos ejes independientes:

- **Fase** (progreso de negocio: greeting → data_capture → … → completed) → esto es lo que
  **Juan redefine**.
- **Quién controla** (IA / humano) → esto es lo nuevo. **No es una fase.**

Una conversación puede estar en `data_capture` *y* bajo control humano a la vez. Meter "control
humano" como un valor del enum de fases de Juan sería un error: mezcla dos cosas y reproduce la
clase de bug de `conversation_phase` (Bug #5, stuck).

**Recomendación de arquitectura (input para Juan):** el control es un **flag ortogonal**, no un
estado de su máquina. **Fuente de verdad de "¿hay humano al mando ahora?":**

```sql
EXISTS (SELECT 1 FROM dashboard_conversation_claims
        WHERE lead_id = :lead_id AND released_at IS NULL)
```

No crear un segundo flag que se pueda desincronizar (regla de `estado-unificado-lead.md`: nunca
un campo espejo que derive mal).

---

## 3. El insight clave: soltar sale gratis si tomar se hace bien

El requisito "al soltar, la IA lee la conversación completa" **se cumple solo si — y solo si —
durante el control humano se sigue escribiendo cada mensaje en `n8n_chat_histories`.**

- Mensajes que el humano **envía**: ya se guardan (van por el webhook proactivo, tipo `ai` para
  que Claude mantenga contexto). ✓ Ver `docs/protocolos/workflow-proactivo-dashboard.md`.
- Mensajes que el cliente **responde** durante ese rato: son el riesgo. Llegan al webhook del
  bot principal. Si callamos a la IA cortando el workflow **antes** del nodo de memoria, esos
  entrantes **no se guardan** → al soltar, a la IA le falta media conversación.

**Regla de oro:** mientras el humano manda, n8n **sigue persistiendo cada mensaje entrante en la
memoria**, pero **suprime la respuesta de la IA**. Si eso se cumple, soltar no necesita ningún
"re-leído" especial: la transcripción ya está completa y el próximo mensaje del cliente lo
contesta la IA con todo el contexto. **El trabajo real está en la fase de tomar, no en la de
soltar.**

---

## 4. Las dos transiciones, concretas

### Tomar (IA → humano)
1. Insertar claim abierto — *ya hecho* por el Inbox.
2. **n8n (cambio nuevo):** ante mensaje entrante, si hay claim abierto para ese lead →
   persistir en `n8n_chat_histories` y **no** generar/enviar respuesta IA. (Gate temprano en el
   bot principal, después del nodo de memoria, antes del nodo Claude Sonnet.)
3. **Scheduler `seguimiento-leads-estancados` (cambio nuevo):** saltar leads con claim abierto
   — mismo patrón que el guard de `status` cerrado que ya tiene.

### Soltar (humano → IA)
1. `released_at = now()` (botón "Soltar a IA").
2. **No** auto-enviar nada. La IA vuelve a ser quien responde el próximo mensaje entrante.
3. Opcional: resetear contadores/checkpoints del scheduler para ese lead, para que no dispare
   un seguimiento viejo justo al soltar.

---

## 5. Decisiones/riesgos a cerrar

| # | Tema | Propuesta |
|---|---|---|
| 1 | **Join `lead_id` ↔ identidad conversacional de n8n** | n8n keyea por `conversation_id`/`phone_number`/`session_id`; el claim keyea por `lead_id`. El gate de n8n necesita un join fiable. Engancha con `docs/iniciativas/conversation-id-whatsapp-n8n.md`. **Bloqueante técnico** del punto 4.2. |
| 2 | Humano que se olvida de soltar → IA muda para siempre en ese lead | Auto-release por inactividad del agente (proponer 2–4h) + indicador visible "tomada por X desde HH:MM" en el Inbox. |
| 3 | Etiquetado del mensaje humano (hoy tipo `ai`) | Marcar en `additional_kwargs` (`sent_by: "human_agent"`, email) para que el system prompt le diga a la IA "algunos turnos previos los mandó un colega humano, respeta sus compromisos". Barato, mejora la reentrada. Tipo sigue siendo `ai`. |
| 4 | Ventana 24h de Meta | Si el humano toma un lead frío, su mensaje puede chocar con la ventana cerrada → mismo bloqueante de plantilla aprobada que ya arrastramos (Pendientes de infraestructura, CLAUDE.md). |
| 5 | Concurrencia 2 agentes | Ya resuelto por el índice único parcial. ✓ |

---

## 6. Dependencia con Juan (redefinición de estados) — bloqueante de coordinación

Todo lo anterior debe encajar con la redefinición de estados de conversación de Juan. **Input
del Arquitecto para él:**

1. El control humano/IA es un **flag ortogonal**, no un valor de su enum de fases.
2. La fuente de verdad del control es el claim abierto en `dashboard_conversation_claims`
   (Dashboard-owned, ya con concurrencia enforced en BD). n8n lo lee read-only.
3. Su nueva máquina de estados **no** debe pisar ni depender del control humano — son ejes
   distintos.
4. Necesitamos el join `lead_id` ↔ `conversation_id` sólido (punto 5.1).

**Pendiente de arranque:** confirmar con Alberto si ya hay borrador escrito de la redefinición
de Juan o si el Arquitecto lo arranca vía handoff. De aquí cuelga el resto.

---

## 7. Reparto por ejecutor (cuando se apruebe §6)

- **Agente n8n** — gate de supresión de IA en el bot principal (persistir sí, responder no) +
  skip en el scheduler `Retomar Conversacion` cuando hay claim abierto.
- **Agente Dashboard** — botón "Soltar a IA" (set `released_at`), indicador "tomada por X
  desde…", auto-release por inactividad, marca `sent_by: human_agent` en el payload proactivo.
- **Juan (HYL-WAI)** — encaje de la redefinición de estados (§6), join `lead_id`↔`conversation_id`.
- **Arquitecto** — diagnóstico, validación transversal, handoffs; no ejecuta.
