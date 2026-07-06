# Evaluación de arquitectura — ¿Adoptar una plataforma/framework de conversación WhatsApp en vez de n8n artesanal?

> Autor: Arquitecto-IA-Qualitas · Fecha: 6 julio 2026
> Disparador: Alberto revisa **OpenWA** (gateway self-hosted no oficial) y plantea el dolor de fondo:
> "siento que tengo muchas cosas a mano en n8n (reintentos, qué pasa si es el mismo `session_id`,
> follow-ups)… alguien ha debido desarrollar ya algo que resuelva esto de manera probada."

---

## TL;DR (decisión)

- **OpenWA: descartado.** Es WhatsApp Web reverse-engineered (Baileys / whatsapp-web.js), NO la Meta Cloud API oficial. Riesgo de **ban existencial** justo cuando vamos a escalar volumen, sobre un negocio regulado bajo marca Quálitas/Hylant. El único beneficio (ahorro de fee por mensaje) es despreciable frente a perder la línea. Uso admisible: solo sandbox interno en número desechable, nunca la línea de producción.
- **Plataformas/frameworks de conversación: el instinto de Alberto es CORRECTO** — la fontanería que está cosiendo a mano ya está resuelta y probada. Pero **no migrar ahora**.
- **Diagnóstico raíz:** estamos usando n8n como *runtime de aplicación conversacional con estado*, y n8n es *glue/automatización*, no un motor de máquina de estados. Casi todos los bugs abiertos son síntomas de ese mismatch.
- **Camino recomendado:** (1) corto plazo — arreglar la capa de estado donde ya vive (tabla canónica `whatsapp_event`); (2) medio plazo — evaluar **Botpress** para el cerebro, manteniendo Claude + Django/Quálitas; (3) evitar por ahora — SaaS completo tipo Respond.io/WATI.
- **Bonus urgente:** Meta cambió su **política de IA en WhatsApp (enero 2026)** — las interacciones IA deben ser "task-specific". Revisar cumplimiento ANTES de escalar (otro camino a perder la línea).

---

## 1. Qué es OpenWA y por qué se descarta

| Aspecto | OpenWA | Lo que hoy corremos |
|---|---|---|
| Conexión | WhatsApp Web **no oficial** (Baileys / whatsapp-web.js) | **Meta Cloud API oficial** (`phoneNumberId 1028815256982638`) |
| Licencia | MIT, gratis, self-hosted | Fee por mensaje Meta |
| Riesgo de ban | **Alto** — Meta detecta y banea automatización no oficial, sobre todo con volumen nuevo | Bajo (canal legítimo, número verificado marca) |
| Compliance | Viola ToS de WhatsApp | Cumple |

**Razón de descarte:** estamos a punto de escalar ventas (Bug #10 = "bloqueo #1 para escalar el lunes"). La detección anti-spam de Meta se dispara justo con alto volumen y patrones nuevos. Migrar a canal no oficial antes de subir volumen = receta para perder el WhatsApp del negocio. Un número baneado = se cae todo el funnel de una aseguradora regulada. El coste de ese fallo supera cualquier ahorro por mensaje.

**Trampa de la ventana 24h:** OpenWA no tiene ventana 24h ni fricción de plantillas — tentador para el rescate de leads fuera de ventana (Bug #12, `docs/2026-07-05-rescate-leads-1046-1103.md`). Pero re-engagement masivo fuera de 24h es *exactamente* el patrón que Meta marca como spam; hacerlo sobre canal no oficial solo acelera el ban. La ventana 24h no es un bug a sortear, es la regla que te mantiene vivo.

---

## 2. El dolor real: n8n usado como máquina de estados conversacional

El síntoma ("tengo todo a mano: reintentos, dedup de session_id, follow-ups") no es casualidad. **El estado de la conversación lo estamos cosiendo a mano sobre Postgres crudo.** Casi todos los bugs abiertos son el mismo problema, no problemas separados:

| Bug / Issue | Síntoma | Es en realidad… |
|---|---|---|
| **Bug #11** | sesión pegada a la 1ª cotización al recotizar | falta dedup/**upsert** de sesión |
| **Bug #5** | `conversation_phase` stuck en `greeting` | máquina de estados artesanal sobre Postgres |
| **Bug #12** | inbound caído 2× en una semana (colisión `webhookId`) | transporte gestionado a mano |
| **Issue #74** | follow-up de 15 min dejó de enviarse | scheduler de follow-up hand-rolled |
| **Hitos por LIKE** | detección de hito por frase exacta del bot | no hay máquina de estados real → detección frágil |

**Conclusión:** todos son síntomas de "el estado lo coso yo". Eso ya está resuelto y probado en el mercado — el instinto de Alberto es correcto.

---

## 3. Qué existe ya (por capas, de menos a más disruptivo)

**Frameworks de conversación/agente (el "cerebro" + estado):**
- **Botpress** — el más cercano a lo que tenemos: soporta **Claude** nativo, "Autonomous Nodes" (el LLM decide la ruta), memoria, flujos multi-paso, no atado a un solo LLM. API-first. = "alguien ya implementó los patrones de conversación" SIN tirar la lógica Claude.
- **Rasa** — más control y robustez de máquina de estados, más pesado.
- Frameworks de agentes stateful (LangGraph y similares) — checkpoint/resume de estado, pero son librerías, no llave en mano para WhatsApp.

**Plataformas todo-en-uno (transporte + estado + inbox + handoff humano):**
- **Respond.io** — BSP oficial, AI Agent integrado, **User Takeover** (el humano entra y la IA se para en seco) = justo el botón "Tomar conversación"/Kommo pero de fábrica. Multi-canal.
- **WATI / Twilio Conversations / Gupshup / 360dialog** — sesión, ventana 24h, reintentos y dedup nativos.

---

## 4. El "pero" que ninguna plataforma resuelve

La **fontanería** (estado, reintentos, dedup, ventana 24h, follow-up) está resuelta. La **lógica de negocio no**, y es la parte cara:
- Emisión SOAP a Quálitas (`/api/emitir-externo/`, bloque 492, VIN gate del Bug #10)
- Postgres compartido con Django (dual-write)
- Dashboard + analítica de funnel

**Ninguna plataforma da eso.** Migrar entero = re-integrar las joyas de la corona en el runtime de otro, y mover justo lo que nos diferencia a una caja con menos control. El trade real no es "plumbing gratis", es "plumbing gratis a cambio de meter la lógica bespoke en su modelo".

---

## 5. Recomendación del Arquitecto

**Ahora, con el escalado bloqueado y viniendo de dos apagones esta semana: NO migrar.** Una migración de plataforma en medio de un incendio es cómo se pierden negocios.

La decisión real no es "n8n vs plataforma", es **"dónde vive el estado de la conversación"**. En orden de prioridad:

1. **Corto plazo (estabilizar):** arreglar la capa de estado donde ya está. La tabla canónica **`whatsapp_event`** (ya documentada como destino en CLAUDE.md / Pendientes de infraestructura) mata joins frágiles, LIKE de hitos y dedup de sesión de un golpe. Fix de raíz de Bugs #11/#5, sin migrar nada. **Es lo barato y lo que desbloquea.**
2. **Medio plazo (proyecto deliberado, ya estables):** evaluar **Botpress** en serio para el *cerebro* — mantiene Claude Haiku+Sonnet, quita los patrones de conversación artesanales, deja n8n como glue y Django/Quálitas intactos. El que de verdad quita el dolor sin tirar el diferenciador.
3. **Evitar por ahora:** SaaS completo (Respond.io/WATI). Se tragaría el funnel bespoke y re-introduce todo el trabajo de integración Quálitas. Solo tendría sentido si el valor futuro se define como operación humana + inbox en vez de bot automatizado.

---

## 6. Bonus crítico — Política de IA de WhatsApp (enero 2026)

Meta cambió su política: las interacciones con IA deben ser **"task-specific"** (propósito definido: asistencia de compra, soporte, agendado, etc.). Un bot que cotiza y emite seguros encaja, pero **hay que revisar cumplimiento antes de escalar volumen** — un incumplimiento de política sobre el canal oficial y bajo marca Quálitas es el *otro* camino a perder la línea. **Registrar como pendiente y priorizar sobre el escalado.**

---

## Fuentes
- Respond.io — Best WhatsApp Chatbots 2026: https://respond.io/blog/best-whatsapp-chatbots
- Twilio — WhatsApp Bot with Session Management: https://www.twilio.com/code-exchange/whatsapp-session-bot
- Respond.io — Twilio vs MessageBird vs Respond.io (incl. Botpress): https://respond.io/blog/twilio-vs-messagebird-vs-respondio
- Turn.io — WhatsApp 2026 AI Policy: https://learn.turn.io/l/en/article/khmn56xu3a-whats-app-s-2026-ai-policy-explained
- Alibaba Cloud — WhatsApp AI Policy 2026 guide: https://www.alibabacloud.com/help/en/chatapp/use-cases/whatsapp-ai-policy-2026-guide
- OpenWA docs: https://docs.openwa.dev/ (evaluado vía traducción)
