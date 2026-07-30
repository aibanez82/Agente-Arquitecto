# CLAUDE.md — Ecosistema IA Quálitas/Insurmind

> Fuente de verdad del Arquitecto-IA-Qualitas.
> Actualizado: 28 julio 2026 (revisión de eficiencia — contradicciones corregidas, duplicados fusionados).

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
→ Django crea lead + manda 1er WhatsApp directo (Meta API)
→ cliente responde → n8n (Hostinger) → Claude (Haiku + Sonnet) conversa por WhatsApp
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
Django → 1er WhatsApp directo (Meta Graph API) + INSERT whatsapp_sessions (SQL crudo)
         ↓ cliente responde
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
├── Dashboard → funnel completo
└── n8n PROD "Monitor Qualitas SIO PROD" (18 jul) → chequeo cada 10 min contra el SOAP real de
    Quálitas, alerta por Telegram si cae (repetida mientras siga caído) y al recuperarse
```

**Reglas críticas de arquitectura:**
- Django y n8n comparten la misma BD Postgres.
- Django **NO** dispara webhook a n8n al crear el lead: genera el PDF de cotización, manda el primer WhatsApp **directo vía Meta Graph API** (sin n8n) y hace `INSERT INTO whatsapp_sessions` por SQL crudo (cronología: `docs/bugs/bug-02-prefijo-57.md`).
- El **único webhook real** Django→n8n es **al confirmar el pago**: n8n pone `conversation_phase = 'completed'` y envía WA al cliente (`enviar_webhook_whatsapp` en `qualitas/views.py` → workflow "Payment Confirmation").
- El Dashboard solo escribe indirectamente vía el webhook proactivo de n8n. Los bugs en `whatsapp_sessions` y `n8n_chat_histories` son responsabilidad de n8n — Django no controla esas tablas (salvo el INSERT inicial de `whatsapp_sessions`).

---

**Wagtail + Django:** no son dos sistemas — Wagtail (CMS de la landing) es una app Django más dentro del mismo proceso en Heroku, misma BD Postgres (tablas Wagtail + `qualitas_*`), mismo repo `aguayo-co/HYL-WAI`. Django lleva la lógica de negocio (leads, cotizaciones, pólizas, webhook de pago).

---

## Mapa de sistemas

| Sistema | Repo / URL | Stack | Notas |
|---|---|---|---|
| Landing + Backend | `aguayo-co/HYL-WAI` | Wagtail + Django, Heroku | CMS + API REST + lógica de negocio + BD |
| WhatsApp bot | n8n (Hostinger) | n8n workflows | 3 nodos Claude (ver estructura abajo) |
| Base de datos | Heroku Postgres (addon) | PostgreSQL | Compartida entre Django y n8n |
| Dashboard | `aibanez82/Dashboard_seguroautoqualitas` | Next.js 14, Vercel | UI de leads en tiempo real. Ejecutor Nivel 3 de código dashboard |
| Agente QA | `aibanez82/Agente_QATest_Qualitas` | Claude Code | Tests E2E; desde 8 jul lidera pruebas E2E en STG sin pasar por la landing y valida cambios de `systemMessage` |
| Agente Mejoras Conv. | `aibanez82/Agente-MejorasConversacion` | Claude Code | Analiza abandono (Postgres) y tono/trato (capturas WA), propone copy — nunca modifica nada él mismo. Protocolo: `docs/protocolos/agente-mejoras-conversacion.md` |
| Agente n8n | `aibanez82/Agente-n8n` | Claude Code | Entiende workflows n8n, propone mejoras, modifica los JSON y sube a git — Alberto importa manualmente en n8n. Protocolo: `docs/protocolos/agente-n8n.md` |
| Agente Conciliación | `aibanez82/Agente-Conciliacion` | Playwright + Postgres, cron GH Actions | ✅ Operativo (26 jul): scraping real del portal Q 360, cron diario. Verifica estatus de pago real por póliza — escribe solo en su tabla `conciliacion_pagos`, nunca en `qualitas_polizaemitida`. Protocolo: `docs/protocolos/agente-conciliacion.md` |
| Agente Conversión | — | ⏳ Futuro | Reintentos + seguimiento |
| Arquitecto | `aibanez82/Agente-Arquitecto` | Este repo | Documentación transversal, workflows n8n, spec SOAP Quálitas |

**Accesos de Alberto:**
- Heroku: member en `hyl-wai-production`
- GitHub: colaborador externo en `aguayo-co/HYL-WAI` (`gh auth` con scope `repo` basta)
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
| ~~`NumeroPruebaWhatsapp`~~ | — | No existe en producción y ya no importa: `normalize_whatsapp_phone` cae siempre a `52`. Bug #2 cerrado (`docs/bugs/bug-02-prefijo-57.md`) |

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

> Exportar y hacer commit aquí cada vez que se modifique un workflow en producción — es la única red de seguridad y la política permanente (el backup automático se descontinuó por decisión de Alberto el 29 jul; detalle: `docs/architecture/backup-policy-n8n.md`).

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

**El estado vigente de todos los bugs vive en `github.com/aibanez82/qualitas-issues` (privado) — NO en este archivo.** Cualquier agente (y Juan) puede abrir/comentar issues; solo el Arquitecto cierra/certifica. Convenciones en el `README.md` de ese repo. Van ahí los defectos técnicos (código, esquema, queries, regex, integraciones); las recomendaciones de copy/tono NO — esas siguen la tubería del Agente Mejoras Conversación (abajo).

**Regla de ruteo entre trackers (29 jul):** el fix decide el repo — fix en nuestros sistemas y sin acción de Juan → `qualitas-issues`; fix en Django de Juan, decisión suya o coordinación entre lados → issues de `aguayo-co/HYL-WAI` (Alberto SÍ puede abrir issues ahí; lo que no puede es pushear código). Transversales: UN issue canónico, el otro lado solo comentario-puntero — nunca dos issues con estado.

Los `docs/bugs/bug-NN-*.md` (aquí y en los repos de agentes) siguen siendo el cuaderno de investigación largo — cronología, SQL, decisiones — enlazado desde cada issue.

**`qualitas-issues` también es inbox de captura rápida (20 jul):** ideas/bugs dictados fuera de casa, prefijo `QUALITAS:`. Al iniciar sesión (o "revisa QUALITAS"): `gh issue list --repo aibanez82/qualitas-issues --state open` **+ barrido de issues que Juan nos abre en HYL-WAI** (`--assignee aibanez82` y menciones), triangular, cerrar con comentario de destino — nunca ejecutar trabajo de otro repo. Detalle: `docs/protocolos/qualitas-issues-inbox.md`.

**Workaround activo para Bug #7 en Dashboard** (documentado en detalle en `docs/bugs/bug-07-estatus-pago.md` y en el issue correspondiente):
```js
// Condición correcta para detectar póliza pagada
d.estatus_pago === 'PAGADO' ||
(d.conversation_phase === 'completed' && d.numero_poliza != null)
```
`conversation_phase = 'completed'` lo setea n8n al recibir confirmación verificada de la pasarela de pago — no es auto-declaración del usuario. El guard `numero_poliza != null` evita falsos positivos.

---

## Protocolos de ejecutores

Roles y enlaces a protocolos completos: ver tabla "Mapa de sistemas". Reglas operativas que sí viven aquí:

- **Tubería de copy (Mejoras y n8n NO se hablan entre sí):** Agente Mejoras Conversación propone el cambio de copy → **Arquitecto** valida, traduce a cambio EXACTO (qué frase, qué nodo) y chequea impacto transversal → **Agente n8n** aplica el cambio en el JSON y hace commit/push → Alberto lo importa en n8n.
- **Agente n8n nunca decide qué tocar de forma autónoma** — el Arquitecto diagnostica el bug/nodo, el Agente n8n ejecuta el cambio en el JSON.

---

## Entorno de pruebas / staging (iniciativa activa)

Staging end-to-end paralelo a prod (gitflow `stg`→`main`) para validar bug fixes antes de desplegar. Instancia n8n STG: `https://n8n-xlqk.srv1810257.hstgr.cloud`. **Principio rector:** cada componente de staging apunta SOLO a gemelos de staging, nunca a prod. Mapa completo prod→staging, credenciales, gotchas de import: `docs/iniciativas/entorno-pruebas-staging.md`.

**Seguimiento automático de leads estancados:** 7 checkpoints, hasta 3 reintentos. ✅ **ENVIANDO EN REAL en PROD desde el 20 jul** (171 envíos al 30 jul; verificado en `n8n_chat_histories`, `metadata.source='django_checkpoint_followup'`). El filtro de horario 9am-8pm sigue SIN construir; **decisión de Alberto (30 jul): se acepta el envío sin filtro** (residuo fuera de horario ~1-3/día en los bordes) — el filtro pasa de bloqueante a mejora deseable. En STG están apagados/dry-run por la contención del port #132. Detalle: `docs/iniciativas/seguimiento-leads-estancados.md`.

**Conversation ID (Issue #21):** identidad conversacional de n8n movida de `phone_number` a `conversation_id`. **Ya desplegado en PROD** en modo `shadow` (Django `WHATSAPP_CONVERSATION_ID_MODE=shadow`, nodos `Resolve Session`/`Session Router` en n8n PROD). Pendiente: mergear a `main` la rama del Dashboard (`fix/conversation-id-whatsapp-n8n`) y decidir con Juan el paso a `dual`. Detalle: `docs/iniciativas/conversation-id-whatsapp-n8n.md`.

**Recordatorios por fecha mencionada (handoff a Juan 16 jul):** cliente da fecha para no contratar todavía → Haiku extrae, Python calcula, se envía vía el webhook proactivo existente. **Bloqueante:** plantilla de Meta para re-enganche fuera de ventana 24h (ver Pendientes). Detalle: `docs/iniciativas/2026-07-10-recordatorios-seguimiento-por-fecha-mencionada-design.md`, handoff: `docs/2026-07-16-handoff-juan-recordatorios-fecha-mencionada.md`.

---

## Pendientes de infraestructura

| Item | Estado |
|---|---|
| Rotar service account key Google Cloud (`ba36b46f377b...`) | 🟡 Desprioritizado por Alberto (29 jul) — no lo ve urgente; no volver a proponer salvo señal de exposición |
| Regenerar token Meta Business API | 🟡 Todo lo de Meta lo ejecuta JUAN (decisión Alberto 29 jul) — coordinar con él, junto con la plantilla de re-enganche |
| Bug #7 / Issue #69 `HYL-WAI` — fix es lado n8n (IA emite `[phase:completed]`, se guarda sin pago verificado) | 🔴 **Nuestro** desde 2 jul → Agente n8n |
| Corrección Bug #8 en Django — Juan Aguayo (Issue #70 `aguayo-co/HYL-WAI`) | ⏳ Pendiente externo |
| Propuesta arquitectura BD — tabla canónica `whatsapp_event` | 💡 Plan de destino, sin decisión de implementar. Detalle: `docs/architecture/whatsapp-event-canonico-propuesta.md` |
| `N8N_TOKEN` hardcodeado como default en `qualitas/views.py:1291` (`enviar_webhook_whatsapp`; el validador `:1041` ya es env-only) | 🔴 **Issue #130 `HYL-WAI`** (27 jul): quitar default, rotar, coordinar con Alberto el cambio simultáneo en credenciales n8n |
| Qué hacer con pólizas `VENCIDO`/`CANCELADO` que detecta el Agente Conciliación | 💡 Sin decisión. Ver `docs/architecture/estatus-pago-qualitas.md` |
| Plantilla de Meta aprobada para re-enganche fuera de ventana 24h | ⚠️ Bloqueante para "Recordatorios por fecha mencionada" (arriba) y rescates tipo Bug #12. Pedida a Juan 16 jul, no sometida aún |
| Exponer `fecha_inicio` en emisión — Issue #114 `HYL-WAI` | ✅ Django en PROD 27 jul (PR #125, v331). **E2E n8n STG validado 28 jul** (pólizas reales, +0 y +30 exacto). Falta: fix prompt límite 30d (`qualitas-issues#66`, define SHA de freeze de #132) y promoción n8n a PROD. Desbloquea M47/M48 |
| `/api/emitir-externo/` no distingue causa del 400 — Issue #119 HYL-WAI (=#9) | ⏳ En curso — Juan (rider aceptado en la autorización de B3, 29 jul) |
| Monitor horario de actividad de Juan (rutina cloud `trig_013gQWu8gqfDh5c8QQWzTAbM`, 6-23h CDMX → issue `JUAN:` en qualitas-issues) | ⚠️ Creado 29 jul pero CIEGO: el entorno cloud no tiene credencial GitHub (corrida de prueba no creó el issue de control "JUAN-monitor activo"). Falta: Alberto añade PAT como `GH_TOKEN` en el environment Default de claude.ai/code |

Ítems resueltos: archivados en `docs/architecture/pendientes-resueltos-historial.md` — ya no son accionables.

---

## Flujo de trabajo y arquitectura de agentes

Alberto trabaja desde **Claude Code** sobre repos clonados en `~/claude-projects/` (acceso Git directo, arranque: `cd ~/claude-projects/<repo> && claude`):

- `Agente-Arquitecto` ← este repo, fuente de verdad
- `Dashboard_seguroautoqualitas` · `Agente-MejorasConversacion` · `HYL-WAI`
- `Agente-n8n` · `Agente_QATest_Qualitas` · `Agente-Conciliacion` — push directo habilitado desde el Arquitecto

**Arquitectura de 3 niveles (regla de oro — diagnóstico arriba, ejecución abajo):** Nivel 1 = lectura (código, APIs); Nivel 2 = Arquitecto (razona, orquesta, NO ejecuta); Nivel 3 = ejecutores (QA, Mejoras Conv., n8n, Conciliación, Dashboard — ver Mapa de sistemas), que **nunca se coordinan lateralmente**. Diagrama: `docs/diagrama-agentes.svg`.

**Documentación Quálitas:** fuente autoritativa en `aguayo-co/HYL-WAI:docs/qualitas-documentacion-webservices/` (PDFs + markdown + CSV catálogos, empezar por `AI_GUIDE.md`). Cubre cotización/emisión/tarifas/impresión — **no** el webservice de pago (OPL). `docs/qualitas-api/` local queda superseded.

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

> **Disciplina de CLAUDE.md:** este archivo se carga completo en cada turno — tamaño máximo **23 KB**. Aquí solo viven hechos estables y reglas operativas: sin cronologías, sin historia de decisiones ("como decía antes…"), sin ítems resueltos. El estado de bugs vive en `qualitas-issues`; cronologías, evidencia e investigaciones van a `docs/` (crear el archivo si no existe); lo resuelto se archiva en `docs/architecture/pendientes-resueltos-historial.md`. Verificar `wc -c CLAUDE.md` tras cada edición.
