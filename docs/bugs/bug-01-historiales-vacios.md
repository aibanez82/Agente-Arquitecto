# Bug #1 — Historiales vacíos en ~76% de sesiones

**Sistema:** n8n · **Estado:** ✅ Resuelto (11 jul) — no era un bug, decisión de Alberto

**Cierre (11 jul):** confirmado que no hay problema de arquitectura ni de desarrollo, ni leads sin respuesta perdidos. Es un malentendido de métrica: 399 de ~434 leads son canal `LANDING` y cierran 100% por la web sin tocar WhatsApp nunca (por eso 0 mensajes en n8n y `conversation_phase` en `greeting` — no porque algo falle, sino porque el cliente nunca escribió). Los 35 leads de canal `WHATSAPP` sí tienen conversación real (29-48 mensajes), y cuando el humano responde el historial se guarda en 48/49 casos. Solo afecta a cómo se interpreta la métrica "% de sesiones con historial" sin filtrar por canal — no afecta al motor de follow-up ni pierde datos. Alberto decidió marcarlo resuelto tras esta aclaración.

## Fila de la tabla original

| 1 | `n8n_chat_histories` vacío en ~76% de sesiones (medido 1 jul 2026: 154/203). Ojo: el historial existe casi solo cuando el humano responde (48/49) → gran parte del "vacío" es en realidad **leads que nunca respondieron**, no pérdida de datos. Afecta a la analítica, NO al motor de follow-up. **Precisión 7 jul:** `canal_atencion` distingue esto limpiamente — leads `LANDING` (399 de ~434) cierran 100% por la web sin tocar WhatsApp (`conversation_phase` siempre `greeting`, 0 mensajes n8n, datos en `qualitas_asegurado` vía formulario web); leads `WHATSAPP` (35) sí tienen conversación real de 29-48 mensajes. Detalle: `docs/2026-07-07-hallazgo-agente-dashboard-canal-landing-vs-whatsapp.md`. | n8n | 🟡 Medio |
