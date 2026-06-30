# Agentes del Ecosistema Quálitas/Insurmind

> Fuente: CLAUDE.md — Actualizado: 29 junio 2026.

---

## Arquitectura de niveles

```
        ┌─────────────────┐
        │   ARQUITECTO    │  ← Nivel 2: razona, orquesta, NO ejecuta
        └────────┬────────┘
        ┌────────┴────────┐
   consulta            instruye
        │                 │
   ┌────▼────┐       ┌────▼────────────────────┐
   │ Nivel 1 │       │ Nivel 3 — Ejecutores    │
   │ Lectura │       │ • Agente QA             │
   │ Código  │       │ • Agente Mejoras Conv.  │
   │ APIs    │       │ • Agente Conversión (⏳) │
   └─────────┘       └─────────────────────────┘
              (nunca se hablan entre sí)
```

**Regla de oro:** los ejecutores nunca se coordinan lateralmente. Toda comunicación pasa por el Arquitecto a través de Alberto.

---

## 1. Arquitecto-IA-Qualitas

**Repo:** `aibanez82/Agente-Arquitecto`
**Nivel:** 2 — Orquestador / Diagnóstico transversal
**Estado:** ✅ Activo

### Qué hace
- Mantiene la visión transversal de todos los sistemas: Wagtail/Django, n8n, Postgres, Dashboard, GA4, Meta/WhatsApp.
- Recibe síntomas reportados por Alberto y razona sobre la causa raíz considerando todos los sistemas a la vez.
- Entrega planes concretos de qué archivo/sistema tocar y qué agente ejecutor debe actuar.
- Actualiza y mantiene la documentación de arquitectura (este repo).

### Qué NO hace
- No ejecuta cambios en código ni en infraestructura.
- No llama directamente a APIs externas para modificar estado.
- No se comunica con los ejecutores directamente — todo pasa por Alberto.

### Stack técnico
- Claude Code (Claude Sonnet 4.6)
- Fuente de verdad: `CLAUDE.md` en este repo

### Cómo se activa
Alberto abre una sesión de Claude Code en este repo y reporta el síntoma o tarea de diagnóstico.

### Variables de entorno que necesita
Ninguna. Es un agente de documentación y diagnóstico, no tiene runtime propio.

---

## 2. Agente QA — Tests End-to-End

**Repo:** `aibanez82/Agente_QATest_Qualitas`
**Nivel:** 3 — Ejecutor
**Estado:** ✅ Activo

### Qué hace
- Ejecuta tests end-to-end sobre el ecosistema.
- Verifica el estado del funnel completo: landing → lead en Django → webhook → sesión en n8n → mensajes WhatsApp.
- Detecta regresiones y comportamientos inesperados comparando contra el estado esperado definido en el CLAUDE.md.
- Reporta hallazgos a Alberto para que el Arquitecto los analice.

### Qué NO hace
- No corrige bugs — solo los detecta y reporta.
- No modifica workflows de n8n ni código Django.
- No se coordina con otros agentes ejecutores.

### Stack técnico
- Claude Code
- Acceso a Postgres (vía `DATABASE_URL`)
- n8n API (`N8N_API_KEY`)
- Meta Business API (`META_ACCESS_TOKEN`, `META_PHONE_NUMBER_ID`)

### Cómo se activa
Alberto abre una sesión de Claude Code en el repo `Agente_QATest_Qualitas` con la instrucción de qué parte del funnel testear.

### Variables de entorno que necesita
| Variable | Propósito |
|---|---|
| `DATABASE_URL` | Conexión a Postgres (Heroku) |
| `N8N_API_KEY` | Consultas a la API de n8n |
| `META_ACCESS_TOKEN` | Meta Business API |
| `META_PHONE_NUMBER_ID` | ID del número WhatsApp Business |
| `META_WABA_ID` | WhatsApp Business Account ID |

---

## 3. Agente Mejoras Conversación

**Repo:** `aibanez82/Agente-MejorasConversacion`
**Nivel:** 3 — Ejecutor
**Estado:** ✅ Activo

### Qué hace
Sigue un protocolo de 4 pasos automáticos cada vez que Alberto le pide un análisis:

1. **Query Postgres** — extrae leads con abandono (phase en `greeting`/`data_capture`/`summary_confirmation` + `last_activity > 48h`) y leads exitosos (referencia)
2. **Clasificación por outcome** — categoriza cada lead: nunca respondió, abandonó en data_capture, abandonó en summary, en emisión, pago pendiente, pagó, bot no disparó
3. **Análisis de copy por fase** — para cada fase con >10% de abandono: extrae el último mensaje del bot antes del silencio, identifica patrones problemáticos (longitud, preguntas múltiples, tono), compara con conversaciones exitosas y propone texto alternativo
4. **Genera informe Markdown** en `informes/YYYY-MM-DD-analisis.md` con mapa de abandono, análisis de copy y hasta 5 recomendaciones priorizadas con texto concreto

### Qué NO hace
- No modifica n8n, templates, ni ningún sistema externo
- No envía mensajes a leads
- No escribe en Postgres — acceso estrictamente read-only
- No se coordina con otros agentes ejecutores

### Stack técnico
- Claude Code
- Heroku Postgres read-only (credencial `readonly_leads` de `hyl-wai-production`)
- Tablas consultadas: `qualitas_lead`, `qualitas_cotizacion`, `whatsapp_sessions`, `n8n_chat_histories`

### Cómo se activa
Alberto abre el proyecto en Claude Code y dice:
> "Analiza las conversaciones del [fecha inicio] al [fecha fin]"

### Cómo usa el Arquitecto el output
Las recomendaciones de copy se traducen en cambios al `systemMessage` del nodo **AI Agent** (Claude Sonnet) en el workflow productivo de n8n. El Arquitecto identifica el nodo exacto; Alberto ejecuta el cambio directamente en n8n.

### Limitación activa
**Bug #1** — 89% de sesiones no tienen historial en `n8n_chat_histories`. El agente lo detecta y anota en el informe, pero el análisis de copy solo cubre el 11% de conversaciones con datos reales. Resultados válidos pero parciales hasta que se corrija el bug en n8n.

### Variables de entorno que necesita
| Variable | Propósito |
|---|---|
| `DATABASE_URL` | Conexión read-only a Postgres (Heroku) |

---

## 4. Dashboard Qualitas

**Repo:** `aibanez82/Dashboard_seguroautoqualitas`
**Nivel:** 3 — Ejecutor (código frontend/backend del dashboard)
**Estado:** ✅ Activo

### Qué hace
- Provee la UI de visualización del funnel completo en tiempo real.
- Lee directamente de Postgres (read-only) las tablas `qualitas_lead`, `qualitas_cotizacion`, `qualitas_polizaemitida`, `whatsapp_sessions`.
- Muestra métricas de GA4 (visitas landing) y Meta Business API (métricas WhatsApp).
- Ejecuta cambios de código en el dashboard cuando Alberto lo instruye.

### Qué NO hace
- No escribe en Postgres — es estrictamente read-only.
- No modifica workflows de n8n ni código Django.
- No tiene lógica de negocio — solo visualización.

### Stack técnico
- Next.js 14
- Vercel (deploy)
- Postgres directo vía `lib/db.js` (nunca conexiones ad-hoc)
- Google Analytics Data API (GA4)
- Meta Business API

### Cómo se activa
Alberto abre una sesión de Claude Code en el repo del Dashboard con la tarea de desarrollo o corrección a realizar.

### Variables de entorno que necesita
| Variable | Propósito |
|---|---|
| `DATABASE_URL` | Conexión read-only a Postgres (Heroku) |
| `GOOGLE_SERVICE_ACCOUNT_EMAIL` | Autenticación Google Cloud / GA4 |
| `GOOGLE_PRIVATE_KEY` | Clave privada service account Google |
| `GA4_PROPERTY_ID` | Propiedad de Google Analytics 4 |
| `META_WABA_ID` | WhatsApp Business Account ID |
| `META_ACCESS_TOKEN` | Meta Business API |
| `META_PHONE_NUMBER_ID` | ID del número WhatsApp Business |
| `DASHBOARD_PASSWORD` | Protección de acceso al dashboard |
| `GITHUB_ISSUES_TOKEN` | Crear/leer issues en GitHub |
| `N8N_API_KEY` | Consultas a la API de n8n |

> **Importante:** solo environments **Production** y **Preview** en Vercel — no Development.

---

## 5. Agente Conversión (futuro)

**Repo:** Por definir
**Nivel:** 3 — Ejecutor
**Estado:** ⏳ En planificación

### Qué hará
- Gestionará reintentos automáticos hacia leads que no respondieron o que quedaron en fases intermedias del funnel.
- Ejecutará seguimiento proactivo vía WhatsApp para leads con más de X horas sin actividad.
- Registrará los intentos de recontacto y sus resultados en Postgres.

### Qué NO hará
- No tomará decisiones de escalación sin criterios definidos por el Arquitecto.
- No enviará mensajes fuera de los horarios y templates aprobados por Meta.
- No se coordinará directamente con otros agentes.

### Stack técnico (planificado)
- Claude Code
- Meta Cloud API (envío de mensajes WhatsApp)
- Postgres (lectura de `whatsapp_sessions` + `qualitas_lead`)
- n8n API (posiblemente para disparar sub-flows)

### Cómo se activará
Por definir — posiblemente mediante un trigger automático en n8n o un cron job en Vercel.

### Variables de entorno que necesitará
| Variable | Propósito |
|---|---|
| `DATABASE_URL` | Leer estado de leads y sesiones |
| `META_ACCESS_TOKEN` | Envío de mensajes WhatsApp |
| `META_PHONE_NUMBER_ID` | ID del número remitente |
| `META_WABA_ID` | WhatsApp Business Account ID |
| `N8N_API_KEY` | Disparar flows de n8n (TBD) |

---

## Resumen rápido

| Agente | Repo | Nivel | Estado |
|---|---|---|---|
| Arquitecto-IA-Qualitas | `aibanez82/Agente-Arquitecto` | 2 | ✅ Activo |
| Agente QA | `aibanez82/Agente_QATest_Qualitas` | 3 | ✅ Activo |
| Agente Mejoras Conversación | `aibanez82/Agente-MejorasConversacion` | 3 | ✅ Activo |
| Dashboard Qualitas | `aibanez82/Dashboard_seguroautoqualitas` | 3 | ✅ Activo |
| Agente Conversión | TBD | 3 | ⏳ Futuro |
