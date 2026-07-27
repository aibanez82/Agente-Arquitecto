# Handoff a Juan — control humano ↔ IA de una conversación WhatsApp (encaje con tu redefinición de estados)

> Para: **Juan Aguayo** (`aguayo-co/HYL-WAI`) · De: Arquitecto-IA-Qualitas (ecosistema Insurmind), vía Alberto · 27 jul 2026
> Documento autocontenido: puedes pasárselo entero a un LLM.
> Diseño completo del que sale este handoff: `Agente-Arquitecto/docs/iniciativas/2026-07-24-control-humano-vs-ia-conversacion.md`.
> Datos citados: verificados en vivo el 27 jul contra la Postgres de **PRODUCCIÓN** (no asumidos).

---

## 0. Contexto (por qué te llega esto)

El Dashboard estrenó la pestaña **Inbox** (contact center): un agente humano puede "tomar" una
conversación de WhatsApp y escribirle al cliente directamente. El problema (issue #57 de
`qualitas-issues`, criticidad alta): **el bot de n8n no se entera** — si el cliente responde
mientras el humano tiene la conversación, el bot contesta también → doble respuesta,
posiblemente contradictoria, al mismo cliente.

Ya hay un diseño aprobado para resolverlo (resumen en §1). Antes de implementar nada queremos
que **encaje con la redefinición de estados de conversación que estás haciendo tú** — este
handoff es el input de arquitectura para esa redefinición, más 3 pedidos concretos (§3).

---

## 1. El diseño, en 6 líneas

1. Tomar/soltar ya está modelado en BD: tabla `dashboard_conversation_claims` (Dashboard,
   fuera de tus migraciones — la conoces del handoff de inventario BD del 24 jul), con índice
   único parcial `ON (lead_id) WHERE released_at IS NULL` → un solo agente por lead, enforced
   por Postgres.
2. **"¿Hay humano al mando?" = existe claim abierto para ese `lead_id`.** Esa es la única
   fuente de verdad. No habrá ningún flag espejo en otra tabla.
3. Mientras hay claim abierto, n8n **sigue persistiendo cada mensaje entrante** en
   `n8n_chat_histories` pero **suprime la respuesta de la IA** (gate después del nodo de
   memoria, antes del agente Claude). Así, al soltar, la IA tiene la transcripción completa y
   retoma sin ningún paso especial.
4. El scheduler de seguimiento (`Retomar Conversacion`) también salta leads con claim abierto.
5. "Soltar" = `released_at = now()`. Nada se auto-envía; la IA simplemente vuelve a responder
   el próximo mensaje entrante.
6. Los mensajes del humano ya se guardan en la memoria (tipo `ai`, vía el webhook proactivo);
   se marcarán en `additional_kwargs` como `sent_by: "human_agent"`.

La implementación de todo eso es nuestra (n8n + Dashboard). **De ti solo necesitamos el encaje
de diseño y los grants/joins de §3.**

---

## 2. Input de arquitectura para tu redefinición de estados

1. **El control humano/IA es un flag ortogonal, NO un valor de tu enum de fases.** Una
   conversación puede estar en `data_capture` *y* bajo control humano a la vez. Meterlo como
   fase mezclaría progreso de negocio con quién responde, y reproduciría la clase de bug de
   `conversation_phase` stuck (Bug #5).
2. **La fuente de verdad del control es el claim abierto** en
   `dashboard_conversation_claims` (tabla del Dashboard; n8n la leerá read-only):
   ```sql
   EXISTS (SELECT 1 FROM dashboard_conversation_claims
           WHERE lead_id = :lead_id AND released_at IS NULL)
   ```
   Por favor **no crees un segundo campo** tipo `is_human_controlled` en `whatsapp_sessions` ni
   en tus modelos — un campo espejo se desincroniza y ya nos pasó factura antes.
3. **Tu nueva máquina de estados no debe depender del control ni pisarlo.** Las transiciones
   de fase siguen su lógica de negocio normal aunque haya humano al mando; el control solo
   decide *quién responde*, no *en qué fase está* la conversación.
4. Cuando tengas borrador de la redefinición, pásanoslo antes de implementar — queremos validar
   el encaje en papel, no en producción.

---

## 3. Pedidos concretos (los 3 que sí te tocan)

### 3.1 Confirmar que `whatsapp_sessions.lead_id` seguirá poblado siempre

El gate de n8n necesita pasar de "sesión resuelta" a "¿claim abierto para su lead?". El puente
natural es la columna `lead_id` que tu migración 0033 añadió a `whatsapp_sessions`. Verificado
en vivo (27 jul, PROD): 957 sesiones totales, 493 con `lead_id`; **de las 264 creadas en los
últimos 7 días, las 264 (100%) lo traen** — desde el deploy en `shadow` toda sesión nueva nace
con `lead_id`.

**Pedido:** confirma que (a) ese poblado es garantizado en todos los caminos de creación de
sesión (no best-effort), y (b) se mantendrá así en tu redefinición. Con eso, el join del gate
es trivial. No hace falta backfill de las 464 filas viejas: como fallback existe el join
`whatsapp_sessions.quotation_id = qualitas_lead.cotizacion_id` (cubre 951/957 sesiones,
verificado), pero preferimos no depender de él en el camino caliente.

### 3.2 GRANT de lectura sobre `dashboard_conversation_claims`

Al verificar hoy encontramos que la tabla de claims tiene grants restrictivos: el usuario de
Postgres que usa el Dashboard para lecturas (`readonly_leads`, el de `DATABASE_URL`) recibe
`permission denied` al hacer `SELECT` sobre ella — solo el rol que la creó puede leerla. Es
casi seguro que la credencial de n8n (`"Postgres account"`) está igual.

**Pedido:** como parte de la reconciliación de objetos externos del handoff del 24 jul, incluir:
```sql
GRANT SELECT ON dashboard_conversation_claims TO <rol_de_n8n>;
GRANT SELECT ON dashboard_conversation_claims TO <rol_lectura_dashboard>;
```
(Sin `GRANT SELECT` a n8n, el gate del punto 1.3 no puede existir — es bloqueante.)
Si prefieres que esto lo ejecute el rol dueño desde el lado del Dashboard, dínoslo y lo
canalizamos nosotros; lo importante es decidir quién lo hace, no que lo hagas tú sí o sí.

### 3.3 Nada de lógica de control en Django

Django no necesita cambios de código para esta iniciativa (el webhook de Payment Confirmation
y la creación de sesión siguen igual). Solo pedimos que tu redefinición **no** añada lógica que
lea o escriba claims desde Django — la propiedad queda: claims = Dashboard escribe, n8n lee,
Django ignora.

---

## 4. Qué haremos nosotros (para tu contexto, no requiere acción tuya)

| Quién | Qué |
|---|---|
| Agente n8n | Gate de supresión en el bot principal (persistir sí, responder no) + skip en `Retomar Conversacion` con claim abierto |
| Agente Dashboard | Botón "Soltar a IA" (`released_at`), indicador "tomada por X desde HH:MM", auto-release por inactividad (2–4h), marca `sent_by: human_agent` |
| Arquitecto | Validación transversal y certificación en vivo antes de PROD |

Riesgo conocido que arrastramos aparte: si el humano toma un lead con la ventana de 24h de Meta
cerrada, su mensaje no sale — es el mismo bloqueante de plantilla aprobada de re-enganche que ya
está pedido (16 jul).

---

## 5. TL;DR de lo que esperamos de vuelta

1. ✅/❌ al encaje de §2 (flag ortogonal, claim como fuente de verdad, sin campo espejo).
2. Confirmación de §3.1 (`lead_id` garantizado en toda sesión nueva).
3. Decisión sobre §3.2 (quién ejecuta los GRANT y cuándo).
4. Tu borrador de la redefinición de estados cuando exista, antes de implementarla.
