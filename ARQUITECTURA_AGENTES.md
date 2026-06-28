# Arquitectura de Agentes — Ecosistema IA Quálitas/Insurmind

> Decisión estratégica de arquitectura multi-agente.
> Definido: 27 junio 2026. Actualizado: 28 junio 2026.

---

## Principio rector

**Diagnóstico arriba, ejecución abajo.** Un cerebro razona con visión completa del ecosistema; los ejecutores actúan sobre planes ya validados.

---

## Los 3 niveles

### Nivel 1 — Sistemas de lectura (read-only)

El Arquitecto lee directamente estos sistemas:

- **Django / HYL-WAI** — Backend en Heroku. Fuente de lógica de negocio.
- **Postgres** — BD compartida en Heroku entre Django y n8n.
- **n8n** — Workflows de WhatsApp en Hostinger. Acceso vía API REST (`https://n8n.srv1325340.hstgr.cloud/api/v1/`). API key guardada en Vercel como `N8N_API_KEY`.
- **Dashboard** — Next.js en Vercel. Repo conectado como GitHub knowledge.
- **Meta Business API / GA4** — APIs externas de tráfico y WhatsApp.

### Nivel 2 — Arquitecto (orquestador)

El cerebro. **NO ejecuta código.** Recibe la petición, consulta las fuentes del Nivel 1, integra las respuestas y entrega un diagnóstico con el plan de qué tocar y dónde.

**Capacidades directas del Arquitecto (sin pasar por Alberto):**
- Leer todos los sistemas del Nivel 1
- Abrir, etiquetar y cerrar GitHub Issues en `aibanez82/Agente-Arquitecto` vía API (token `GITHUB_ISSUES_TOKEN` en Vercel)

### Nivel 3 — Ejecutores (write)

Agentes que actúan sobre los sistemas. Reciben planes validados del Arquitecto a través de Alberto.

- **Agente QA** — tests automáticos end-to-end (`aibanez82/Agente_QATest_Qualitas`)
- **Agente Conversión** — análisis de conversaciones y reintentos *(futuro)*

---

## Regla de oro de comunicación

**Los ejecutores NO se hablan entre sí. Solo comunican hacia arriba, con el Arquitecto, a través de Alberto.**

Si una tarea necesita coordinación entre QA y Conversión, sube al Arquitecto — nunca se coordinan lateralmente. Esto evita el fallo más común de los sistemas multi-agente: dos agentes con permiso de escritura tomando decisiones contradictorias sin supervisión.

---

## Protocolo de comunicación — flujo completo
