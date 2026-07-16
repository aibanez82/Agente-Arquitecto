# CLAUDE.md — Ecosistema IA Quálitas/Insurmind

> Fuente de verdad del Arquitecto-IA-Qualitas.
> Actualizado: 14 julio 2026 (limpieza — cronologías e ítems resueltos movidos a `docs/`).

---

## Identidad y rol

Soy el **Arquitecto-IA-Qualitas**, agente de Nivel 2 del ecosistema multiagente de Insurmind.

- Tengo visión transversal de TODOS los sistemas: Wagtail/Django, n8n, BBDD, Dashboard, GA4, Meta/WhatsApp.
- Mi trabajo es **DIAGNOSTICAR y PLANIFICAR**. No ejecuto nada.
- Cuando Alberto reporta un síntoma, razono sobre todos los sistemas juntos, identifico la causa raíz y entrego un plan concreto de qué archivo/sistema tocar.
- La ejecución la hacen los agentes ejecutores de Nivel 3.

**Regla de comunicación:** Los ejecutores nunca se hablan entre sí. Todo pasa por mí, a través de Alberto.

---

## Contexto del negocio

Ecosistema de conversión de leads de Google Ads en pólizas de seguro de auto en México, bajo la marca **Quálitas/Hylant**.

**Funnel completo:**
```
Google Ads → Landing (Wagtail/Django · Heroku)
→ Django crea lead + dispara webhook → n8n (Hostinger)
→ Claude (Haiku + Sonnet) conversa por WhatsApp
→ cliente da datos → póliza emitida → pago confirmado
```

**Tres canales de cierre:**
- Full web (Landing → pago online)
- Full WhatsApp (n8n → datos → póliza → pago)
- Mixto (web → WhatsApp → web)

**Colaborador clave:** Juan Aguayo (`juan.aguayo@aguayo.co`), co-fundador de aguayo-co, propietario del repo Django `aguayo-co/HYL-WAI`.

**Colaboradora clave:** Laura, de Hylant. Reporta manualmente (hoja Excel, día siguiente) las ventas/pagos confirmados — es la fuente para saber qué pólizas se pagaron de verdad, no un sistema. No depende de Juan.

---

## Arquitectura completa del sistema

```
Landing (Wagtail/Django · Heroku)
    ↓ formulario completado
Django → crea qualitas_lead + qualitas_cotizacion en Postgres
Django → dispara webhook → n8n
         ↓
    n8n (Hostinger)
    ├── Lee/escribe whatsapp_sessions → Postgres DIRECTO
    ├── Lee/escribe n8n_chat_histories → Postgres DIRECTO
    ├── Claude Haiku — jailbreak detection + intent router
    ├── Claude Sonnet — agente conversacional principal
    └── Meta Cloud API → WhatsApp → Lead

Dashboard (Next.js · Vercel)
    ├── Lee Postgres directamente (read-only, sin pasar por Django)
    └── Botón "Tomar conversación" → webhook n8n → INSERT n8n_chat_histories + Send WhatsApp

Observabilidad:
├── GA4 → visitas landing
├── Meta Business API → métricas WhatsApp (enviados/leídos/respondidos)
└── Dashboard → funnel completo
```

**Regla crítica de arquitectura:** Django y n8n comparten la misma BD Postgres.

Django **NO** dispara ningún webhook a n8n al crear el lead. Lo que realmente pasa: (a) Django genera el PDF de cotización; (b) manda el primer WhatsApp **directo vía Meta Graph API**, sin pasar por n8n; (c) hace un `INSERT INTO whatsapp_sessions` por SQL crudo — ahí nace el prefijo 57 vs 52 del Bug #2. Cronología completa: `docs/bugs/bug-02-prefijo-57.md`.

Aparte de esto, Django SÍ dispara **un webhook real** a n8n:
1. **Al confirmar el pago** — n8n actualiza `conversation_phase = 'completed'` y envía mensaje WA al cliente (`enviar_webhook_whatsapp` en `qualitas/views.py`, hacia el workflow "Payment Confirmation")

El Dashboard también puede escribir indirectamente a través del webhook n8n (solo para mensajes proactivos). Cada sistema escribe directamente en sus propias tablas. Los bugs en `whatsapp_sessions` y `n8n_chat_histories` son responsabilidad exclusiva de n8n — Django no controla esas tablas (salvo la creación inicial de `whatsapp_sessions`, ver corrección arriba).

---

## Wagtail + Django — cómo se relacionan

Wagtail es un CMS construido sobre Django. **No son dos sistemas separados** — Wagtail es una aplicación Django más dentro del mismo proceso:

- Un solo proceso Python en Heroku
- Una sola base de datos Postgres (tablas de Wagtail + tablas de negocio `qualitas_*` conviven)
- Wagtail gestiona la landing: páginas, contenido, imágenes, panel CMS
- Django gestiona la lógica de negocio: leads, cotizaciones, pólizas, webhooks hacia n8n
- Un solo repo Git: `aguayo-co/HYL-WAI`
- Las visitas a la landing se miden con GA4

---

## Mapa de sistemas

| Sistema | Repo / URL | Stack | Notas |
|---|---|---|---|
| Landing + Backend | `aguayo-co/HYL-WAI` | Wagtail + Django, Heroku | CMS + API REST + lógica de negocio + BD |
| WhatsApp bot | n8n (Hostinger) | n8n workflows | ~2,087 líneas JSON, 3 nodos Claude |
| Base de datos | Heroku Postgres (addon) | PostgreSQL | Compartida entre Django y n8n |
| Dashboard | `aibanez82/Dashboard_seguroautoqualitas` | Next.js 14, Vercel | UI de leads en tiempo real |
| Agente QA | `aibanez82/Agente_QATest_Qualitas` | Claude Code | Tests end-to-end |
| Agente Mejoras Conv. | `aibanez82/Agente-MejorasConversacion` | Claude Code | Analiza abandono y tono/trato, propone copy — nunca modifica nada él mismo. Protocolo: `docs/protocolos/agente-mejoras-conversacion.md` |
| Agente n8n | `aibanez82/Agente-n8n` | Claude Code | Entiende workflows n8n, propone mejoras, modifica los JSON y sube a git — Alberto importa manualmente en n8n |
| Agente Conciliación | `aibanez82/Agente-Conciliacion` | Playwright + Postgres, cron GH Actions | Entra al portal de Quálitas (login simple, sin captcha) y verifica estatus de pago real por póliza — escribe en tabla propia `conciliacion_pagos`, nunca en `qualitas_polizaemitida`. 🆕 Repo creado 14 jul, sin lógica de scraping real todavía (falta URL/selectores del portal). Protocolo: `docs/protocolos/agente-conciliacion.md` |
| Arquitecto | `aibanez82/Agente-Arquitecto` | Este repo | Documentación transversal, workflows n8n, spec SOAP Quálitas |

**Accesos de Alberto:**
- Heroku: acceso como member a `hyl-wai-production`
- GitHub: acceso al repo `aguayo-co/HYL-WAI` (como colaborador externo — PAT pendiente)
- WhatsApp Business: acceso directo
- n8n: API key en Vercel como `N8N_API_KEY`

---

## Esquema de base de datos (tablas clave)

| Tabla | Quién escribe | Qué contiene |
|---|---|---|
| `qualitas_lead` | Django | Estado del lead (`estado`), canal, fechas |
| `qualitas_cotizacion` | Django | Datos del auto, email, teléfono, CP, precio |
| `qualitas_polizaemitida` | Django | Número de póliza, `estatus_pago`, precio |
| `whatsapp_sessions` | n8n (directo a Postgres) | `conversation_phase`, `last_activity`, `captured_data` — **tiene bug activo** |
| `n8n_chat_histories` | n8n (Postgres Chat Memory) | Historial mensajes WA — **fuente fiable de hitos** |
| ~~`NumeroPruebaWhatsapp`~~ | — | **Corregido 2 jul 2026: esta tabla NO existe en producción** (verificado contra `information_schema.tables`). No hay un mecanismo de números de prueba de Juan documentado que sea real — confirmar con él directamente si tiene un número dedicado para pruebas en producción. |

**JOIN correcto entre tablas:**
- `qualitas_cotizacion` → `qualitas_lead` con `l.cotizacion_id = c.id` (NO `c.lead_id`)
- `whatsapp_sessions` → `qualitas_cotizacion` con `ws.quotation_id = c.id`
- Columnas: `l.canal_atencion` (no `l.canal`), `c.codigo_postal` (no `c.cp`)
- `n8n_chat_histories`: columna `message` es JSONB → `message->>'type'` y `message->>'content'`; ordenar por `id`

---

## n8n workflow — estructura interna

**Workflows exportados (fuente de verdad local):**

| Workflow | Archivo en este repo |
|---|---|
| Bot principal WhatsApp | `docs/n8n-workflows/WhatsApp Insurance Quotation Bot.json` |
| Confirmación de pago | `docs/n8n-workflows/WhatsApp Insurance Quotation Bot - Payment Confirmation.json` |
| Mensajes proactivos (Retomar conversación) | `docs/n8n-workflows/Retomar Conversacion.json` |

> Exportar y hacer commit aquí cada vez que se modifique un workflow en producción.
> Mientras el backup automático (`docs/architecture/backup-policy-n8n.md`) no esté
> implementado, este export manual es la única red de seguridad ante cambios rotos.

El bot tiene 3 nodos que llaman a Claude:
1. **Jailbreak detection** — Claude Haiku
2. **Intent Router classifier** — Claude Haiku
3. **Agente conversacional principal** — Claude Sonnet

n8n escribe a Postgres directamente (credencial `"Postgres account"` en el workflow):
- `Check Session Exists` → SELECT en `whatsapp_sessions`
- `Load Session` → SELECT completo de la sesión
- `Update Activity` → UPDATE `whatsapp_sessions.last_activity`
- `Postgres Chat Memory` → lee/escribe `n8n_chat_histories`

**Workflow proactivo (Dashboard → WhatsApp):** segundo workflow que recibe `POST /webhook/proactive-wa-message` del Dashboard, hace INSERT en `n8n_chat_histories` y envía el WhatsApp. Detalle completo (payload, reglas): `docs/protocolos/workflow-proactivo-dashboard.md`.

---

## Regla de estado real de un lead

`whatsapp_sessions.conversation_phase` tiene un bug activo (siempre stuck en `greeting`). Los hitos reales se leen de `n8n_chat_histories` con BOOL_OR + LIKE:

| Hito | Cómo se detecta |
|---|---|
| `has_responded` | `human_msg_count > 0` |
| `confirmo_cobertura` | AI dijo "Procederemos con Cobertura…" |
| `dio_datos_personales` | AI dijo "tengo registrado… Nombre:" |
| `dio_vin` | AI dijo "Número de serie:" |
| `dio_domicilio` | AI dijo "domicilio registrado es" |
| `poliza_emitida_wa` | AI dijo "fue emitida exitosamente" |

**Riesgo:** si cambia el copy del bot, los LIKE dejan de funcionar.

---

## Bugs — fuente única

**A partir del 11 jul 2026, el estado vigente de todos los bugs vive en `github.com/aibanez82/qualitas-issues` (privado) — NO en este archivo.** Cualquier agente del ecosistema (y Juan) puede abrir/comentar issues ahí directamente; solo el Arquitecto cierra/certifica. Convenciones completas en el `README.md` de ese repo.

**Por qué se movió:** mantener una tabla de bugs aquí Y en otros 4 repos generaba desincronización real (detalle del incidente que lo disparó: `docs/architecture/pendientes-resueltos-historial.md`). Un solo tracker con estado evita que vuelva a pasar.

**Qué SÍ va en `qualitas-issues`:** defectos técnicos (código, esquema, queries, regex, integraciones). **Qué NO va ahí:** recomendaciones de copy/tono — esas siguen la tubería normal (ver "Agente Mejoras Conversación" abajo).

Los `docs/bugs/bug-NN-*.md` de este repo (y equivalentes en los otros repos de agentes) siguen existiendo como el cuaderno de investigación largo — cronología, SQL, decisiones — cada issue del tracker enlaza al suyo. No se borró nada.

**Workaround activo para Bug #7 en Dashboard** (documentado en detalle en `docs/bugs/bug-07-estatus-pago.md` y en el issue correspondiente):
```js
// Condición correcta para detectar póliza pagada
d.estatus_pago === 'PAGADO' ||
(d.conversation_phase === 'completed' && d.numero_poliza != null)
```
`conversation_phase = 'completed'` lo setea n8n al recibir confirmación verificada de la pasarela de pago — no es auto-declaración del usuario. El guard `numero_poliza != null` evita falsos positivos.

---

## Agente Mejoras Conversación — protocolo de uso

Repo: `aibanez82/Agente-MejorasConversacion`. Analiza abandono (Postgres) y tono/trato (capturas de pantalla de WhatsApp), propone cambios de copy — nunca modifica nada él mismo. Protocolo completo (los 2 modos de entrada, riesgos transversales que el Arquitecto valida antes de aprobar un cambio de tono): `docs/protocolos/agente-mejoras-conversacion.md`.

**Tubería (regla de oro — Mejoras y n8n NO se hablan entre sí):** Agente Mejoras Conversación propone el cambio de copy → **Arquitecto** valida, traduce a cambio EXACTO (qué frase, qué nodo) y chequea impacto transversal → **Agente n8n** aplica el cambio en el JSON y hace commit/push → Alberto lo importa en n8n.

---

## Agente n8n — protocolo de uso

Repo: `aibanez82/Agente-n8n` (clonado en `~/claude-projects/Agente-n8n`, push directo habilitado desde el Arquitecto). Ejecutor Nivel 3 especializado en workflows n8n — el Arquitecto diagnostica el bug/nodo a tocar, el Agente n8n ejecuta el cambio en el JSON y nunca decide qué tocar de forma autónoma. Protocolo completo (flujo v1 de handoff manual, puntos de atención): `docs/protocolos/agente-n8n.md`.

---

## Entorno de pruebas / staging (iniciativa activa)

Staging end-to-end paralelo a prod (gitflow `stg`→`main`) para validar bug fixes antes de desplegar. Instancia n8n STG: `https://n8n-xlqk.srv1810257.hstgr.cloud`. **Principio rector:** cada componente de staging apunta SOLO a gemelos de staging, nunca a prod. Mapa completo prod→staging, credenciales, gotchas de import: `docs/iniciativas/entorno-pruebas-staging.md`.

**Seguimiento automático de leads estancados (15-16 jul):** 7 checkpoints derivados en vivo, hasta 3 reintentos, sin campo de estado nuevo. Django implementado y verificado en STG (16 jul). **Gap de `session_id`/`conversation_id` en n8n:** fix mínimo ya aplicado y verificado; Juan mandó plan más estricto (falla si falta `session_id`, sin fallback a teléfono, + idempotencia + 4 pruebas), handoff en curso. (Descartado: el scheduler de 15 min real es de 4 min y solo aplica si el cliente no respondió nada — sin solapamiento.) Detalle: `docs/iniciativas/seguimiento-leads-estancados.md`.

**Conversation ID (Issue #21):** identidad conversacional de n8n movida de `phone_number` a `conversation_id`. **Ya desplegado en PROD** (verificado 16 jul: Django en `hyl-wai-production` con `WHATSAPP_CONVERSATION_ID_MODE=shadow`, n8n PROD ya tiene los nodos `Resolve Session`/`Session Router`) — no solo en STG como decía esta línea hasta el 15 jul. Pendiente real: mergear a `main` la rama del Dashboard (`fix/conversation-id-whatsapp-n8n`, bajo riesgo mientras siga en `shadow`) y decidir con Juan el paso a `dual`. Detalle: `docs/iniciativas/conversation-id-whatsapp-n8n.md`.

**Recordatorios por fecha mencionada (16 jul, handoff a Juan):** cuando el cliente da fecha para no contratar todavía (vencimiento, quincena, o fecha explícita tipo "el sábado 18" — caso real: lead 1385/cotización 2837), Haiku extrae, Python calcula, se envía vía el webhook proactivo existente. **Bloqueante:** falta plantilla de Meta aprobada para re-enganche fuera de la ventana 24h (fila en Pendientes de infraestructura). Detalle: `docs/iniciativas/2026-07-10-recordatorios-seguimiento-por-fecha-mencionada-design.md`, handoff: `docs/2026-07-16-handoff-juan-recordatorios-fecha-mencionada.md`.

---

## Pendientes de infraestructura

| Item | Estado |
|---|---|
| Rotar service account key Google Cloud (`ba36b46f377b...`) | ⚠️ Urgente |
| Regenerar token Meta Business API | ⚠️ Urgente |
| Corrección Bug #7 en Django — Juan Aguayo (Issue #69 `aguayo-co/HYL-WAI`) | ⏳ Pendiente externo |
| Corrección Bug #8 en Django — Juan Aguayo (Issue #70 `aguayo-co/HYL-WAI`) | ⏳ Pendiente externo |
| Política de backup automático de workflows n8n | ✅ Activo (`.github/workflows/backup-n8n.yml`, cron diario 06:00 CDMX + disparo manual). Rotar `N8N_API_KEY` de GitHub Actions (se pegó en texto plano en un chat el 30 jun) |
| Tab 2.0 del Dashboard | ⏳ Instrucciones ya dadas al Code Agent |
| Reconectar Notion al workspace `aguayo` | ⏳ Pendiente |
| Subir `BUGS_N8N.md` al repo Dashboard | ⏳ Pendiente |
| Integración Kommo — botón "Pasar a Kommo" en Dashboard | ⏳ Pendiente (falta subdominio + API token + pipeline de Alberto). Detalle: `docs/iniciativas/kommo-crm.md` |
| Propuesta arquitectura BD — tabla canónica `whatsapp_event` | 💡 Plan de destino, sin decisión de implementar. Detalle: `docs/architecture/whatsapp-event-canonico-propuesta.md` |
| Alerta de emisión fallida (Bug #9) — workflow `Bot Error Handler` en n8n + tarjeta "Emisión falló" en Dashboard | ⏸️ En pausa. Spec: `docs/estrategia/2026-07-02-alerta-emision-fallida-quálitas.md` |
| `N8N_TOKEN` con valor real hardcodeado como default en `qualitas/views.py:905` (confirmado también en `main`, 16 jul — no es solo `stg`) | ⚠️ Seguridad — mover a solo-env y rotar el token, pedir a Juan. Ver `docs/iniciativas/entorno-pruebas-staging.md` |
| Revisar cumplimiento de la política de IA de WhatsApp de Meta (interacciones deben ser "task-specific") | ⏳ Pendiente — priorizar sobre el escalado de volumen. Ver `docs/estrategia/2026-07-06-evaluacion-plataformas-conversacion-whatsapp.md` |
| Cómo saber con certeza si un cliente pagó la póliza | ⏳ En construcción — Agente Conciliación (creado 14 jul). Ver `docs/architecture/estatus-pago-qualitas.md` y `docs/protocolos/agente-conciliacion.md` |
| Plantilla de Meta aprobada para re-enganche fuera de ventana 24h | ⚠️ Bloqueante para "Recordatorios por fecha mencionada" (arriba) y rescates tipo Bug #12. Pedida a Juan 16 jul, no sometida aún |

Ítems ya resueltos (PAT de HYL-WAI, creación del repo Agente-n8n, columnas de timestamp en
`n8n_chat_histories`/`whatsapp_sessions`, Issue #74 de HYL-WAI) se archivaron en
`docs/architecture/pendientes-resueltos-historial.md` — ya no son accionables.

---

## Flujo de trabajo con Claude Code

A partir del 29 junio 2026, Alberto trabaja desde **Claude Code** sobre repos clonados en `~/claude-projects/`. Esto permite acceso directo a Git sin tokens manuales.

Repos clonados:
- `~/claude-projects/Agente-Arquitecto` ← este repo, fuente de verdad
- `~/claude-projects/Dashboard_seguroautoqualitas`
- `~/claude-projects/Agente-MejorasConversacion`
- `~/claude-projects/Agente-n8n` (push directo habilitado desde el Arquitecto, 8 jul)
- `~/claude-projects/Agente_QATest_Qualitas` (push directo habilitado desde el Arquitecto, 8 jul)
- `~/claude-projects/HYL-WAI` (✅ clonado 9 jul — `gh auth` con scope `repo` ya alcanzaba, no hizo falta PAT nuevo)
- `~/claude-projects/Agente-Conciliacion` (🆕 creado 14 jul, push directo habilitado desde el Arquitecto)

Comando de arranque: `cd ~/claude-projects/<repo> && claude`

---

## Arquitectura de agentes (3 niveles)

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
   │ APIs    │       │ • Agente n8n            │
   │         │       │ • Agente Conciliación   │
   └─────────┘       └─────────────────────────┘
              (nunca se hablan entre sí)
```

**Regla de oro:** diagnóstico arriba, ejecución abajo. Los ejecutores nunca se coordinan lateralmente.

| Proyecto Claude | Rol | Estado |
|---|---|---|
| **Agente-Arquitecto** (este) | Diagnóstico transversal | ✅ Activo |
| Dashboard Qualitas | Ejecutor código dashboard | ✅ Activo |
| Agente QA | Tests end-to-end · nuevo objetivo (8 jul): liderar pruebas E2E en STG sin pasar por la landing, y validar cambios de `systemMessage` | ✅ Activo |
| Agente Mejoras Conversación | Análisis abandono (Postgres) + análisis de tono/trato (capturas WA) → recomendaciones de copy/tono para n8n | ✅ Activo |
| Agente n8n | Entiende workflows n8n, propone mejoras, modifica JSON | ✅ Activo |
| Agente Conciliación | Verifica estatus de pago real por póliza contra el portal de Quálitas (Playwright, sin AI en el loop de scraping) | 🆕 En construcción |
| Agente Conversión | Reintentos + seguimiento | ⏳ Futuro |

---

## Variables de entorno clave (Vercel)

`DATABASE_URL` · `GOOGLE_SERVICE_ACCOUNT_EMAIL` · `GOOGLE_PRIVATE_KEY` · `GA4_PROPERTY_ID` · `META_WABA_ID` · `META_ACCESS_TOKEN` · `META_PHONE_NUMBER_ID` · `DASHBOARD_PASSWORD` · `GITHUB_ISSUES_TOKEN` · `N8N_API_KEY` · `N8N_PROACTIVE_WEBHOOK_URL` · `PROACTIVE_MESSAGE_PASSWORD`

⚠️ Solo environments **Production** y **Preview** — no Development.

---

## Convenciones

- **Persistencia entre máquinas — NUNCA usar memoria local:** Alberto trabaja desde al menos 3 laptops. La carpeta de memoria del agente (`.claude/…/memory/`) es **local a cada máquina y no se sincroniza** → se pierde al cambiar de equipo. Por tanto, TODA iniciativa, plan, backlog o cualquier cosa que deba conservarse se guarda **en git** (en `docs/iniciativas/` para iniciativas/backlog, o el `docs/` que corresponda) y se hace commit+push. Nunca en memoria.
- **Git:** siempre `user.email = a.ibanez@gmail.com` / `user.name = aibanez82`
- **Timezone (estándar de consistencia):** almacenar SIEMPRE el instante absoluto en `timestamptz` (UTC interno); convertir a `America/Mexico_City` SOLO en presentación (dashboard), nunca en la BD ni antes. Nunca usar `timestamp without time zone` ni comparar tz-naive con tz-aware. Hallazgo completo (auditoría `information_schema`, tablas afectadas, DDL de migración, query de auditoría reutilizable): `docs/architecture/timezone.md`.
- **GitHub Issues:** labels con caracteres exactos incluyendo acentos (e.g. `crítico`)
- **DB:** usar siempre `lib/db.js` del Dashboard — nunca conexiones directas ad-hoc
- **n8n API:** `https://n8n.srv1325340.hstgr.cloud/api/v1/` con header `X-N8N-API-KEY`
- **Convención de handoffs (aprendida 6 jul):** todo handoff a un ejecutor se deja en el repo de ESE ejecutor (`<repo>/handoffs/`) y se comunica con la **ruta absoluta completa** + ubicación git. Nunca solo en el repo del Arquitecto.
- **Revisión periódica del tracker (desde 11 jul):** el Arquitecto revisa `github.com/aibanez82/qualitas-issues` periódicamente para (a) detectar issues duplicados entre agentes, (b) verificar en vivo contra el sistema real cualquier issue que alguien marque como resuelto antes de cerrarlo, y (c) reabrir si un cierre resulta ser falso. No es solo del Arquitecto detectar bugs — es mantener el tracker mismo honesto.

> **Disciplina de CLAUDE.md:** este archivo se carga completo en cada turno — tamaño máximo **23 KB** (subido desde 15 KB el 14 jul 2026, tras la limpieza de ese día — el límite anterior databa del 29 jun, cuando el ecosistema tenía menos agentes). Aquí solo viven hechos estables y reglas operativas. El estado de bugs vive en `qualitas-issues` (ver arriba), no aquí. Cronologías, evidencia e investigaciones de cualquier tema van a `docs/` (crear el archivo que corresponda si no existe). Verificar `wc -c CLAUDE.md` tras cada edición.
