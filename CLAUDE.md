# CLAUDE.md — Ecosistema IA Quálitas/Insurmind

> Fuente de verdad del Arquitecto-IA-Qualitas.
> Actualizado: 29 junio 2026 (v2 — botón "Tomar conversación").

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

**Regla crítica de arquitectura:** Django y n8n comparten la misma BD Postgres. Django dispara **dos webhooks** a n8n:
1. **Al crear el lead** — n8n inicia la conversación WhatsApp
2. **Al confirmar el pago** — n8n actualiza `conversation_phase = 'completed'` y envía mensaje WA al cliente

El Dashboard también puede escribir indirectamente a través del webhook n8n (solo para mensajes proactivos). Cada sistema escribe directamente en sus propias tablas. Los bugs en `whatsapp_sessions` y `n8n_chat_histories` son responsabilidad exclusiva de n8n — Django no controla esas tablas.

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
| Agente Mejoras Conv. | `aibanez82/Agente-MejorasConversacion` | Claude Code | Lee Postgres → analiza abandono por fase → genera informe Markdown con recomendaciones de copy para n8n |
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
| `NumeroPruebaWhatsapp` | Django | Teléfonos de prueba de Juan Aguayo |

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

**Segundo workflow — mensajes proactivos desde Dashboard:**

```
Webhook POST /webhook/proactive-wa-message
  { phone_number, message, session_id }
    ├── INSERT n8n_chat_histories
    │     { type: "ai", content: message, tool_calls: [],
    │       additional_kwargs: {}, response_metadata: {},
    │       invalid_tool_calls: [] }
    └── WhatsApp Business Cloud → Send message
          phoneNumberId: 1028815256982638
          credential: WhatsApp Send Message Hylant Account
```

**Reglas del workflow proactivo:**
- Si el INSERT falla → el WhatsApp NO se envía (stop-on-error)
- `phone_number` y `session_id` deben empezar con `52` (México)
- Si `last_activity > 24h` en `whatsapp_sessions` → Meta puede rechazar el mensaje (ventana cerrada)
- El mensaje se guarda como tipo `ai` para que Claude mantenga contexto en la siguiente respuesta del lead

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

## Bugs conocidos activos

Ver `BUGS_N8N.md` para detalle completo con evidencia SQL.

| # | Bug | Sistema | Criticidad |
|---|---|---|---|
| 1 | `n8n_chat_histories` vacío en ~76% de sesiones (medido 1 jul 2026: 154/203). Ojo: el historial existe casi solo cuando el humano responde (48/49) → gran parte del "vacío" es en realidad **leads que nunca respondieron**, no pérdida de datos. Afecta a la analítica, NO al motor de follow-up. | n8n | 🟡 Medio |
| 2 | Prefijo `57` (Colombia) en `session_id` en lugar de `52` (México) | Django | 🟠 Alto |
| 3 | TEST_EMAILS no filtrados en n8n — Meta cobra mensajes de prueba | n8n | 🟡 Medio |
| 4 | 4 leads reales sin `whatsapp_session` (IDs: 837, 834, 810, 802) | n8n | 🟡 Medio |
| 5 | `conversation_phase` siempre stuck en `greeting` | Django | 🟡 Medio |
| 6 | Regex placas rechaza 6 caracteres (`/^[A-Z0-9]{7}$/`) — Issue #2 abierto | n8n | 🟠 Alto |
| 7 | Django no escribe `estatus_pago = 'PAGADO'` al confirmar pago — solo dispara webhook a n8n | Django | 🟠 Alto |
| 8 | `_generar_bloque_492` no incluye teléfono celular en XML SOAP a Quálitas — campo queda vacío en póliza emitida | Django | 🟠 Alto |
| 9 | `POST /api/emitir-externo/` devuelve HTTP 400 recurrente — la emisión de pólizas falla y Django se traga la causa (mensaje genérico, sin logging). Detectado 1 jul 2026. | Django | 🔴 Crítico |
| 10 | AI Agent envía ciudad/estado en vez de VIN al llamar `Issue_Policy` — 3 de 5 pólizas emitidas hasta ahora tienen VIN incorrecto en Quálitas, una ya `PAGADO` (`7620096850`). Detectado 2 jul 2026. Issue `aguayo-co/HYL-WAI` #83. | n8n | 🔴 Crítico |

**Workaround activo para Bug #7 en Dashboard:**
```js
// Condición correcta para detectar póliza pagada
d.estatus_pago === 'PAGADO' ||
(d.conversation_phase === 'completed' && d.numero_poliza != null)
```
`conversation_phase = 'completed'` lo setea n8n al recibir confirmación verificada de la pasarela de pago — no es auto-declaración del usuario. El guard `numero_poliza != null` evita falsos positivos.

**Detalle Bug #8:**
- Trazabilidad confirmada: el dato llega correctamente hasta `_generar_bloque_492` en `qualitas/services.py`
- El método no llama a `d.get('telefono')` — campo nunca se añade al XML
- Fix: agregar `<ConsideracionesAdicionalesDA NoConsideracion="40"><TipoRegla>86</TipoRegla><ValorRegla>{telefono}</ValorRegla></ConsideracionesAdicionalesDA>` en `_generar_bloque_492`
- `TipoRegla 86` confirmado en spec oficial SOAP de Quálitas
- Issue abierto: `aguayo-co/HYL-WAI` #70

**Detalle Bug #9 (emisión 400):**
- El nodo `Issue Policy` en n8n hace `POST https://seguroautoqualitas.com/api/emitir-externo/` (endpoint de Django, no Quálitas directo).
- Django responde `400 {"status":"error","msg":"Experimentamos intermitencias…"}` — mensaje enlatado genérico.
- Buscando por `request_id` en Papertrail **no hay más líneas**: la vista no loguea el fault real ni el campo que falla. `service=708ms` sugiere rechazo en validación de Django, no caída de Quálitas.
- El error **no se guarda en BD** (`qualitas_cotizacionrespuestaxml` es de cotización, no de emisión; `qualitas_leadactionevent` no registra fallos de emisión).
- Probablemente **no** es el Bug #8 (teléfono ausente daría emisión con campo vacío, no 400).
- Pista para Juan: `QUALITAS_AMBIENTE_FLAG = 0` (verificar si es el valor correcto para emisión en vivo).
- Petición doble a Juan: (a) causa raíz del campo que falla; (b) **observabilidad** — loguear el fault de Quálitas y devolver la causa en un campo `detail`.
- Repetido al menos 2 veces el 1 jul 2026 (12:49:32 y 13:05:15 CDMX). request_id ejemplo: `f00e2d0d-927b-33a1-66dc-e6193db0a1f1`.

**Detalle Bug #10 (VIN↔ciudad/estado en Issue_Policy):**
- Auditoría completa de las 5 emisiones históricas vía `n8n_chat_histories` (`Calling Issue_Policy` + regex sobre `parameters18_Value`): 3 de 5 con valor incorrecto (`Hidalgo`, `Ciudad de México`, `Ciudad General Escobedo` en vez del VIN).
- En los 2 casos auditados a fondo, el VIN se capturó y validó correctamente en la conversación (`Validate_Personal_Data` sin error) — el error ocurre solo al construir la llamada `Issue_Policy`.
- Causa: el parámetro `serie` (`parameters18_Value`) está intercalado en medio de 5 campos de domicilio consecutivos (`...colonia → serie → placas...`); el AI Agent "sigue el patrón" de domicilio y mete ciudad/estado ahí en vez del VIN.
- Fix propuesto: reordenar `bodyParameters` del nodo `Issue Policy` en n8n para agrupar `serie` + `placas` justo después de los datos personales, separados del bloque de domicilio. No requiere cambios en Django.
- `qualitas_cotizacion.serie_vehiculo` y `whatsapp_sessions.captured_data` NO son fuente del VIN — ambos quedan `NULL`/`{}` en los casos revisados; el dato viaja directo de la conversación al tool call, sin pasar por columna dedicada en Postgres.
- Póliza `7620096850` ya está `PAGADO` con VIN incorrecto — requiere corrección/reemisión directa con Quálitas, gestión separada del fix de n8n.
- Issue abierto: `aguayo-co/HYL-WAI` #83.
- **Fix validado end-to-end en staging (2 jul 2026):** entorno de pruebas montado en Heroku `hyl-wai-stg` + copia STAGING del workflow en n8n (folder separado, credenciales propias de Postgres/WhatsApp). Se sembró una conversación de prueba en `n8n_chat_histories` con VIN reconocible (`TESTVIN1234567890`) y se corrió manualmente vía "Execute workflow" con datos fijados ("pin") en el trigger, evitando depender del webhook real de Meta (bloqueado por la restricción de "un solo trigger de WhatsApp por Facebook App"). Resultado: `parameters18_Value` (serie) llegó correcto a `Issue_Policy`, Django/Quálitas sandbox respondió `"serie":"TESTVIN1234567890"`. Fix aplicado y confirmado en producción (`docs/n8n-workflows/WhatsApp Insurance Quotation Bot.json`) el mismo día — pendiente que Alberto lo replique en el nodo `Issue Policy` del workflow real en n8n producción.

---

## Kommo CRM — integración en curso

Kommo es el CRM de escalada humana del ecosistema. Ya está parcialmente integrado: cuando el bot decide derivar, envía un mensaje WA al lead con un link a Kommo.

**Plan activo:** Base ($15/user/mes). Incluye API v4 completa.

**Feature en diseño — botón "Pasar a Kommo" en el Dashboard:**

Caso de uso: Alberto ve en el dashboard un lead caliente que no está respondiendo al bot y quiere intervenir manualmente como humano.

Flujo propuesto:
```
Modal del lead en Dashboard
    ↓ click "Pasar a Kommo"
    ↓
Next.js → Kommo API v4 POST /leads/complex
    ↓
Crea contacto + lead en Kommo con:
  - Nombre (si el bot ya lo capturó)
  - Teléfono
  - Vehículo + precio cotizado
  - Nota con link a conversación WA
    ↓
Alberto atiende el lead directamente desde Kommo
```

**Pendiente para implementar:**
- Subdominio Kommo de Alberto
- API token Kommo (Ajustes → Integraciones → API → Token largo)
- Nombre del pipeline y etapa destino en Kommo
- Agregar `KOMMO_API_TOKEN` y `KOMMO_SUBDOMAIN` a Vercel

**Repo donde se implementa:** `aibanez82/Dashboard_seguroautoqualitas`
**Archivo clave:** nuevo endpoint `pages/api/kommo-lead.js` + botón en modal del dashboard

---

## Agente Mejoras Conversación — protocolo de uso

**Repo:** `aibanez82/Agente-MejorasConversacion`
**Credencial DB:** `readonly_leads` en Heroku `hyl-wai-production` (read-only, no puede modificar nada)

> **Patrón de permisos `readonly_leads`:** cada tabla nueva que crea Django NO tiene permiso para
> `readonly_leads` hasta que el dueño de la BD ejecute un `GRANT SELECT` específico. Cuando el
> Dashboard/reporting quiera leer una tabla nueva y dé `permission denied`, la solución es
> `GRANT SELECT ON <tabla> TO readonly_leads;` — **nunca** el grant masivo `ON ALL TABLES`
> (expondría `auth_user` con hashes de contraseñas). El rol dueño es el de `DATABASE_URL`
> (puede granear). Grants aplicados 1 jul 2026: `qualitas_whatsappmessage`, `qualitas_leadactionevent`.
**Output:** archivos en `informes/YYYY-MM-DD-analisis.md`

**Cómo activarlo:** Alberto abre el proyecto en Claude Code y dice:
> "Analiza las conversaciones del [fecha inicio] al [fecha fin]"

**Qué produce (4 pasos internos automáticos):**
1. Query A — leads con abandono (phase en greeting/data_capture/summary_confirmation + last_activity > 48h)
2. Query B — leads exitosos (referencia de conversaciones que llegaron a póliza)
3. Clasificación por outcome + análisis del último mensaje del bot antes del silencio
4. Informe Markdown con mapa de abandono + análisis de copy + hasta 5 recomendaciones concretas de cambio de texto en n8n

**Cómo interpreta el Arquitecto el informe:**
- Las recomendaciones de copy se traducen en cambios al `systemMessage` del nodo **AI Agent** en el workflow productivo de n8n
- El Arquitecto identifica el nodo exacto; la ejecución la hace Alberto directamente en n8n

**Limitación activa — Bug #1:**
~76% de sesiones no tienen historial en `n8n_chat_histories` (medido 1 jul 2026: 154/203). El agente lo detecta y lo anota, pero el análisis de copy solo cubre el ~24% de conversaciones con datos. Nota: gran parte de ese "vacío" son leads que nunca respondieron (ver Bug #1 reinterpretado), no pérdida de datos. Los resultados son válidos pero parciales.

---

## Pendientes de infraestructura

| Item | Estado |
|---|---|
| Rotar service account key Google Cloud (`ba36b46f377b...`) | ⚠️ Urgente |
| Regenerar token Meta Business API | ⚠️ Urgente |
| Corrección Bug #7 en Django — Juan Aguayo (Issue #69 `aguayo-co/HYL-WAI`) | ⏳ Pendiente externo |
| Corrección Bug #8 en Django — Juan Aguayo (Issue #70 `aguayo-co/HYL-WAI`) | ⏳ Pendiente externo |
| Política de backup automático de workflows n8n | ✅ Activo (`.github/workflows/backup-n8n.yml`, cron diario 06:00 CDMX + disparo manual). Rotar `N8N_API_KEY` de GitHub Actions — se pegó en texto plano en una sesión de chat el 30 jun 2026, hay que revocarla en n8n y generar una nueva |
| Tab 2.0 del Dashboard | ⏳ Instrucciones ya dadas al Code Agent |
| PAT fine-grained para repo `aguayo-co/HYL-WAI` | ⏳ Pendiente (`gh` CLI funciona para issues; PAT necesario para acceso a código) |
| Reconectar Notion al workspace `aguayo` | ⏳ Pendiente |
| Subir `BUGS_N8N.md` al repo Dashboard | ⏳ Pendiente |
| Integración Kommo — botón "Pasar a Kommo" en Dashboard | ⏳ Pendiente (falta subdominio + API token + pipeline de Alberto) |
| `n8n_chat_histories` sin columna de timestamp — pedir a Juan `ALTER TABLE n8n_chat_histories ADD COLUMN created_at timestamptz NOT NULL DEFAULT now();` | ⏳ Pendiente externo — mensaje redactado, ver `docs/estrategia/2026-07-01-conversacion-completa-wa-n8n-django.md` |
| Issue #74 (`aguayo-co/HYL-WAI`) — follow-up 15 min dejó de enviarse desde 2026-06-30 ~21:11 UTC | ⏳ Causa raíz sin determinar. Requiere acceso Heroku (config vars, releases, scheduler) — Alberto va a dar token OAuth read-only vía Vercel env Plain |
| Propuesta arquitectura BD — tabla canónica `whatsapp_event` (dual-write desde n8n/Django/Dashboard, reemplaza joins frágiles y LIKE de hitos) | 💡 Documentada como plan de destino, sin decisión de implementar aún |

---

## Flujo de trabajo con Claude Code

A partir del 29 junio 2026, Alberto trabaja desde **Claude Code** sobre repos clonados en `~/claude-projects/`. Esto permite acceso directo a Git sin tokens manuales.

Repos clonados:
- `~/claude-projects/Agente-Arquitecto` ← este repo, fuente de verdad
- `~/claude-projects/Dashboard_seguroautoqualitas`
- `~/claude-projects/HYL-WAI` (requiere PAT — pendiente)

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
   │ APIs    │       │ • Agente Conversión (⏳) │
   └─────────┘       └─────────────────────────┘
              (nunca se hablan entre sí)
```

**Regla de oro:** diagnóstico arriba, ejecución abajo. Los ejecutores nunca se coordinan lateralmente.

| Proyecto Claude | Rol | Estado |
|---|---|---|
| **Agente-Arquitecto** (este) | Diagnóstico transversal | ✅ Activo |
| Dashboard Qualitas | Ejecutor código dashboard | ✅ Activo |
| Agente QA | Tests end-to-end | ✅ Activo |
| Agente Mejoras Conversación | Análisis abandono + recomendaciones copy n8n | ✅ Activo |
| Agente Conversión | Reintentos + seguimiento | ⏳ Futuro |

---

## Variables de entorno clave (Vercel)

`DATABASE_URL` · `GOOGLE_SERVICE_ACCOUNT_EMAIL` · `GOOGLE_PRIVATE_KEY` · `GA4_PROPERTY_ID` · `META_WABA_ID` · `META_ACCESS_TOKEN` · `META_PHONE_NUMBER_ID` · `DASHBOARD_PASSWORD` · `GITHUB_ISSUES_TOKEN` · `N8N_API_KEY` · `N8N_PROACTIVE_WEBHOOK_URL` · `PROACTIVE_MESSAGE_PASSWORD`

⚠️ Solo environments **Production** y **Preview** — no Development.

---

## Convenciones

- **Git:** siempre `user.email = a.ibanez@gmail.com` / `user.name = aibanez82`
- **Timezone:** siempre `America/Mexico_City` (UTC-6, sin horario de verano desde 2023)
- **GitHub Issues:** labels con caracteres exactos incluyendo acentos (e.g. `crítico`)
- **DB:** usar siempre `lib/db.js` del Dashboard — nunca conexiones directas ad-hoc
- **n8n API:** `https://n8n.srv1325340.hstgr.cloud/api/v1/` con header `X-N8N-API-KEY`
