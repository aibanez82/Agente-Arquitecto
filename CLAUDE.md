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
| Agente n8n | `aibanez82/Agente_n8n` (nombre a confirmar) | Claude Code | Entiende workflows n8n, propone mejoras, modifica los JSON y sube a git — Alberto importa manualmente en n8n |
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
| 10 | AI Agent envía ciudad/estado en vez de VIN al llamar `Issue_Policy`. Detectado 2 jul 2026. Issue `aguayo-co/HYL-WAI` #83. | n8n | 🔴 **SIGUE ACTIVO EN PROD (evidencia 5 jul: 4 de las últimas 7 emisiones con ciudad en vez de VIN — `Gómez Palacio`/`Ciudad General Escobedo`/`Ciudad de México`/`Hidalgo`).** Fix construido pero SIN desplegar (vive en `stg`). **Hallazgo 5 jul: la rama `stg` NO está lista tal cual — conserva ~4 menciones "5-20 caracteres" junto a las VIN-17 → inconsistente con el gate Django (loop muerto). Falta reconciliar a "exactamente 17" (Capa 3a) antes de desplegar.** Handoff de despliegue en lockstep (n8n + Django juntos): `docs/2026-07-05-handoff-despliegue-bug10-vin.md`. **ES EL bloqueo #1 para escalar ventas el lunes.** **✅ LADO n8n LISTO (5 jul, verificado por Arquitecto contra git): rama `stg` reconciliada (commit `d370365` — 0 "5-20" reales, 8 "exactamente 17"); diff anti-divergencia PASA (prod no divergió del baseline, el PUT toca solo los 3 nodos del Bug#10: AI Agent, Issue Policy, Validate); script `Agente-n8n:scripts/deploy-bug10-prod.sh` (`5eaf351`, dry-run OK) que hace PUT→activate→verifica webhookId+name. Decisión Arquitecto: `docs/2026-07-05-decision-arquitecto-deploy-bug10.md`.** Pendiente para desbloquear: (1) Juan despliega gate Django `stg`→prod (mensaje: `docs/2026-07-05-mensaje-juan-deploy-validacion-vin.md`); (2) Alberto dispara `deploy-bug10-prod.sh --go` en lockstep + valida en prod (hola inbound + serie mala→re-pregunta 2-3×); (3) merge `stg`→`main` + re-export a `docs/n8n-workflows/`. |
| 11 | Sesiones pegadas a la 1ª cotización al recotizar — leads reales caen fuera del funnel WhatsApp. Detectado 4 jul 2026 por el Dashboard agent (9/9 verificado: 46 enviados, solo 37 en funnel). | n8n | 🟠 Alto — **registrado, en pausa (Alberto lo piensa).** Ver detalle abajo. |
| 12 | Inbound Meta→n8n caído: los mensajes ENTRANTES de WhatsApp no se guardan en `n8n_chat_histories`. **Confirmado en vivo por API n8n (5 jul):** bot `BtOaZm7WlZT-24V7hqCnF` está `active:true` con trigger OK, pero la última ejecución webhook fue id `2059 @ 2026-07-03T22:38:53 UTC` — cero desde entonces. NO es desactivación ni error interno → **Meta dejó de entregar al webhook**. **Causa raíz identificada (escaneo API 5 jul): 4 workflows comparten el mismo `webhookId 18c1b498`** (producción `BtOaZm7...` activo + 3 duplicados `_STG`/copy inactivos). Al activar→desactivar un duplicado, n8n des-registra la ruta compartida y deja producción huérfana (`active:true` sin webhook). Corroborado: la copia `CPcP1...` recibió webhooks reales de Meta el 01–02 jul. **Fix durable = borrar/regenerar el webhookId de los 3 duplicados**, ningún staging debe compartir el de prod. Dashboard lo detectó: 0/48 captura vs ~30% baseline, último `n8n_chat_histories.id 4693` (lead 1045). Leads afectados ~1046–1103 (rescate). **2º apagón silencioso en una semana** (cf. Issue #74). **✅ INGESTA REACTIVADA (5 jul 20:09 UTC) por el Arquitecto vía API: desactivar→activar `BtOaZm7...` re-registró la ruta; confirmado E2E con "hola" → ejecución nueva id `2060` success (tras la 2059 del corte). Token Meta OK.** **✅ CONSOLIDACIÓN EJECUTADA (5 jul ~20:11 UTC): 12 duplicados borrados vía API; instancia = solo los 3 workflows de prod, todos activos → colisión de webhookId eliminada, no puede recaer por esta vía.** Pendiente: (1) alerta de inbound caído; (2) **rescate leads 1046–1103 — PLAN LISTO** (58 leads/49 tel únicos, 15 dentro de ventana 24h Meta + 34 fuera→requieren plantilla, solo 1 ya re-enganchó; `docs/2026-07-05-rescate-leads-1046-1103.md`); (3) re-exportar los 3 de prod a `docs/n8n-workflows/`; (4) NO borrar rama `stg` de git hasta mergear Bug #10. Ver `docs/2026-07-05-consolidacion-workflows-n8n.md`. | n8n | 🟢 **Servicio restaurado + fix estructural hecho; pendiente alerta + rescate.** Ver `docs/2026-07-05-handoff-n8n-bug12-inbound-caido.md`. |
| 13 | Follow-up de cotización (Django, 15 min) puede enviar al cliente el precio de una **forma de pago distinta** a la que eligió en la conversación. Detectado por el Agente Conversaciones (caso `2026-07-07-caso-001`): Tsuru 2012, Cobertura Amplia, **Pago Mensual** cotizado en conversación a $8,666.78 MXN (10:45); seguimiento ~24h después ofrece "$8,050.33 MXN" — diferencia ~$616 (~7%), coincide casi exacto con el "Recargo por forma de pago fraccionada" que documenta Quálitas (`docs/qualitas-api/AnalisisDeEsquemaDeSistemasUsuarios.md`) → **no es una tarifa que varió, son dos productos de pago distintos** (mensual-con-recargo vs. anual-contado-sin-recargo). **Causa raíz:** la forma de pago que el cliente elige en la conversación de WhatsApp vive solo en el contexto del AI Agent (n8n) — no hay evidencia de que se escriba a `qualitas_cotizacion.forma_pago` en Postgres antes de `issue_policy`. El follow-up de 15 min (`qualitas/whatsapp_followups.py` → `resolver_opcion_cotizacion_whatsapp` en `qualitas/quote_helpers.py`, repo `aguayo-co/HYL-WAI`) lee `forma_pago` de la BD; si está vacío (cliente no llegó a confirmar/emitir), cae a un default conservador "C" (anual contado) y renderiza el monto real de ESA opción — correcto en sí mismo, pero no corresponde al plan que el bot ya le había cotizado verbalmente al cliente. **Hallazgo secundario:** el timing observado (~24h, no los 15 min default) coincide con `WHATSAPP_FOLLOWUP_MAX_CANDIDATE_AGE_MINUTES` (default 1440 min) — el candidato pudo haber quedado en cola casi hasta expirar, posible relación con la fiabilidad del scheduler de follow-up (Issue #74). **Para confirmar con certeza:** consultar `qualitas_cotizacion.forma_pago` de esa cotización al momento del follow-up, y `metadata.rule_key`/`template_name` del `WhatsappMessage` de seguimiento. **Candidatos de fix:** (a) persistir `forma_pago` en cuanto el cliente la elige en conversación, no solo al emitir; (b) que el follow-up se omita si `forma_pago` no está confirmada en BD, en vez de asumir un default; (c) que el mensaje de seguimiento aclare explícitamente a qué plan de pago corresponde el monto mostrado. Investigado por fork del Arquitecto 7 jul (no se leyó BD en vivo, solo código). | Django + n8n | 🟠 Alto — mensaje real pero de otro plan puede erosionar la confianza del cliente en la cotización |

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
- `qualitas_cotizacion.serie_vehiculo` y `whatsapp_sessions.captured_data` NO son fuente del VIN — ambos quedan `NULL`/`{}` en los casos revisados; el dato viaja directo de la conversación al tool call, sin pasar por columna dedicada en Postgres.
- Issue abierto: `aguayo-co/HYL-WAI` #83.

**Historia del fix fallido (2 jul 2026) — hipótesis original DESCARTADA:**
- Hipótesis original: el AI "seguía el patrón" del domicilio porque `serie` estaba intercalado entre campos de domicilio (`...colonia → serie → placas...`). Fix aplicado: reordenar `bodyParameters` para agrupar `serie`+`placas` tras `telefono`, separados del domicilio.
- El fix se validó en staging con VIN reconocible `TESTVIN1234567890` y se desplegó a producción. **Pero la validación era engañosa:** un token obviamente-VIN es inconfundible; el modelo lo colocaba bien por falta de ambigüedad, no porque el reorden funcionara.

**Recurrencia 3 jul 2026 y CAUSA RAÍZ REAL (confirmada por comparación controlada):**
- Nueva póliza en prod con `serie/VIN = "Gómez Palacio"` (ciudad de Durango). El fix del reorden NO resolvió.
- **El reorden era cosmético:** cambió la posición en el array `bodyParameters`, pero los identificadores `$fromAI` siguen siendo `parameters18_Value` (serie) y `parameters19_Value` (placas) — numéricamente *después* del bloque domicilio (13–17). El esquema que ve el modelo no cambió.
- **Causa real: la descripción del campo `serie` en `$fromAI` no define QUÉ es el campo.** Dice `` `From **user input** (captured in Group 2), NOT from quotation API` `` — una nota de *procedencia*, no de *contenido*. Todos los demás campos SÍ definen contenido (`teléfono 10 dígitos`, `placas 7 alfanuméricos`, `CP 5 dígitos`). Sin saber que debe ser un VIN, el modelo agarra otro string del usuario del Grupo 2 → la ciudad del domicilio.
- **Comparación controlada que lo confirma:** `serie` (param 18) y `placas` (param 19) son adyacentes, con el mismo reorden y la misma vecindad. La única diferencia es la descripción. `placas` (con descripción de contenido) sale bien (`GAL126D`); `serie` (sin ella) sale mal. → la posición/reorden NO es la causa; la descripción SÍ.

**Fix correcto (pendiente de aplicar — handoff a Agente n8n):**
- Nodo `Issue Policy`, campo `serie` (`parameters18_Value`). Cambiar la descripción `$fromAI` de la nota de procedencia a una definición de contenido, p. ej.: `Número de serie / VIN del vehículo capturado del usuario en Grupo 2: 5-20 caracteres alfanuméricos, SIN espacios, NUNCA un nombre de ciudad/estado/colonia (NO es un dato de domicilio).`
- Ojo: el bot acepta **5-20 caracteres alfanuméricos** para serie (así lo define el system prompt), NO estrictamente un VIN de 17. Una validación defense-in-depth debe ser `^[A-Za-z0-9]{5,20}$` (sin espacios) — rechaza "Gómez Palacio" (tiene espacio, y suele exceder/variar) pero acepta series cortas legítimas. No usar regex de VIN-17.
- **IMPORTANTE — el layout `$fromAI` real:** los campos del tool son claves opacas (`parameters1_Value`…`parameters21_Value`) ordenadas por número; `serie`(18) queda justo tras `colonia`(17). El "reorden" del 2 jul cambió el array pero NO los números `$fromAI`, así que el layout que ve el modelo no cambió → confirma que el reorden fue inútil y que la descripción es la única palanca.

**⚠️ Estado de validación (3 jul 2026) — causa raíz REFINADA y por qué un fix de solo-descripción NO es certificable:**

Se montó un harness de reproducción (system prompt real + schema real con claves opacas `parametersN_Value` en orden numérico real) y se corrió Claude Sonnet con descripción VIEJA vs NUEVA:
- **Ronda 1-2 (escenarios sintéticos, 48 muestras):** 48/48 VIN correcto, VIEJA y NUEVA por igual. No reprodujo.
- **Ronda 3 (transcript REAL de la sesión fallida `528717955153`, 12 muestras):** 12/12 VIN correcto. **NO reprodujo el fallo ni con la conversación exacta que produjo `serie="Gómez Palacio"` en producción.**
- **Total: 60 muestras, 0 fallos.**

**Por qué el harness no reproduce (comprobado contra el workflow real):** el nodo `Anthropic Chat Model` (AI Agent) corre `claude-sonnet-4-5-20250929` a **`temperature: 0.7`**, maxTokens 2000. El harness usa Sonnet 4.6 a temperatura efectiva baja. Dos diferencias decisivas:
1. **Temperature 0.7 sobre una tarea de tool-call/extracción estructurada** — el fallo es un evento de cola de muestreo (raro, estocástico). No se puede fijar 0.7 en los subagentes → no se reproduce la tirada mala.
2. **Modelo 4.5 vs 4.6** — 4.6 sigue instrucciones mejor y evita la confusión; 4.5 a temp alta a veces mete el token de ubicación sobrante.

**Anatomía del fallo real (sesión `528717955153`, póliza `7620098065` — otra afectada, PAGADA):** VIN `3N1CN8AE40531V` capturado, validado y mostrado en el resumen correctamente. En `Issue_Policy`: `parameters17`(colonia)=`"Gómez Palacio Centro"`, `parameters18`(serie)=`"Gómez Palacio"` (la ciudad). Disparador: el CP 35000 devolvió colonia≈ciudad casi idénticas ("Gómez Palacio Centro" / "Gómez Palacio"); el modelo llenó colonia y metió el token de ciudad sobrante en `serie`(18), que va justo después con clave opaca y descripción que no dice "VIN".

**Causa raíz multi-factor (la descripción era solo 1 de 3-4 factores):**
- (a) **Temperature 0.7** en una extracción de tool-call — el factor dominante y el más barato de arreglar. Debería ser **0** (o ~0.1). Este solo cambio elimina casi toda la aleatoriedad que causa la substitución.
- (b) Descripción de `serie` pobre (solo procedencia) — reduce probabilidad pero no la elimina.
- (c) Clave opaca `parameters18_Value` pegada al bloque domicilio (17=colonia) — estructural; el reorden del 2 jul no lo tocó.
- (d) Modelo 4.5 (opcional: 4.6 acertó 100% en pruebas).

**Conclusión clave — un fix de prompt/descripción NUNCA es "certificable a 100%":** sobre un modelo estocástico a temp 0.7, cualquier fix de texto solo *baja la probabilidad*, no la garantiza; y no se puede medir la mejora por replay porque el entorno de test no reproduce la tirada mala. Lo único que **garantiza** que una ciudad no llegue a Quálitas es un **guard determinista** antes de emitir:
- Rechazar `serie` si contiene espacios o no cumple `^[A-Za-z0-9]{5,20}$`, o si `serie == colonia`/`ciudad`. "Gómez Palacio" tiene espacio → bloqueado deterministamente. Esto SÍ es testeable/certificable con casos unitarios.

**Plan recomendado (orden de prioridad):**
1. **`temperature: 0`** en el nodo AI Agent (cambio de un campo; el mayor y más fiable lever para un tool-call). Probablemente EL fix.
2. **Descripción de `serie`** → definición de contenido (defense-in-depth, baja más la probabilidad).
3. **Guard determinista** (Code node en n8n antes de `Issue_Policy`, e idealmente validación en Django `/api/emitir-externo/`) — lo único que da certeza real.
4. (Opcional) subir el modelo del AI Agent a Sonnet 4.6.

- El reorden del 2 jul fue inútil (no cambió las claves `$fromAI`). Póliza `7620098065` (Sandra Luz Hernández, PAGADA) se suma a `7620096850` en la lista de reemisión manual con Quálitas.

**Corrección de arquitectura (4 jul, hallada por el Agente n8n):** `Issue Policy`, `Validate Personal Data`, `Get Quotation Data`, `Search Colony` NO son nodos en serie — son **tools colgadas del AI Agent** (`ai_tool`), invocadas por el modelo cuando decide. Implicaciones:
- No hay un "antes de Issue Policy" lineal donde meter un Code node. La validación determinista de la serie en la ruta de emisión vive en **Django** (que ya está desplegado y ES el único gate de emisión).
- `Validate Personal Data` e `Issue Policy` son tool calls **independientes**, cada una con su propia extracción `$fromAI`. Endurecer `Validate` NO caza la divergencia observada (Validate recibió el VIN, Issue Policy re-extrajo la ciudad) — solo rechaza en captura. El gate de emisión es Django.
- No existe hoy ningún store determinista y referenciable del VIN: `whatsapp_sessions.captured_data` está `{}` (Bug #5). El VIN solo vive en la conversación y llega a las tools vía IA.

**Decisión (4 jul): Opción A (cierre seguro ya) + Opción B diferida.**
- **Opción A (✅ ejecutada por Agente n8n, rama `stg`, commit `591569f` — pendiente validación en staging):** (1) prompt del bot → VIN-17 (4 menciones de longitud actualizadas; echoes `[SERIE]` intactos); (2) manejo del `400 invalid_vehicle_serie` a nivel prompt — se verificó el ruteo: `Issue Policy` es un `ai_tool`, su 400 vuelve al Agent como resultado de tool; sin excepción caía en el mensaje genérico (dead-end), corregido en el prompt para re-preguntar según `details.reason`; (3) regex de serie dentro de `Validate Personal Data` endurecida a la canónica + normalización (defensa temprana). Django es el backstop que garantiza que ninguna ciudad se emita.
- **Set de pruebas ejecutado desde aquí (4 jul, sin staging) sobre el JSON modificado del Agente n8n:** Nivel 1 — gate Django `vehicle_series.py` **certificado 31/31** contra corpus adversarial (determinista). Nivel 2 — **paridad total** regex `Validate Personal Data` ↔ Django (byte-idéntica). Nivel 4 — lógica IA del prompt **9/9** (manejo del 400 re-pregunta por `reason`; serie de 14 chars rechazada). **Nivel 3 — HALLAZGO:** el tool `Issue Policy` tiene `options:{}` (sin `neverError`) → un 400 lanza error genérico y el body con `code:"invalid_vehicle_serie"` probablemente NO llega al Agent → la lógica del 400 (correcta) queda como código muerto. **Fix pendiente Agente n8n:** activar "Never Error" (`options.response.response.neverError=true`) en `Issue Policy`; verificar que otros errores (no-serie) sigan disparando `[api_error:issue_policy]`. Freebie opcional: actualizar la descripción `$fromAI` de `serie` en `Issue Policy` a VIN-17.
- **3 checkpoints a validar en staging antes de prod:** (1) **crítico** — confirmar que el `httpRequestTool` de `Issue Policy` pasa el BODY del 400 (con `code`/`details.reason`) al AI Agent; si no, la excepción de C3a no puede leer el código y cae en dead-end (probar forzando `matches_geographic_field`). (2) El manejo del 400 es prompt-level → probabilístico (temp 0.7); correr 2-3 veces. Peor caso = emisión atascada, nunca póliza mala (Django es el gate). (3) Django `stg`→prod y n8n suben juntos.
- **✅ Bug #10 COMPLETO del lado n8n (rama `stg`, 5 commits: `829f469` baseline → `591569f` Opción A → `9d54c35` naming `_stg`+inactive → `a5da2e2` neverError+freebie → `2570dea` línea load-bearing de detección desde body).** Cadena: neverError→body siempre vuelve→detección (`link_pago`=éxito / `status:error`|`code`=fallo)→ruteo (`invalid_vehicle_serie`=re-pregunta / otro=`[api_error:issue_policy]`)→`details.reason`. Validado sin staging: gate 31/31, paridad regex, prompt 9/9. **Pendiente único: validación runtime E2E en staging, luego merge `stg`→`main` junto con Django.** **Verificación final del JSON v3 (4 jul, sin staging): estática 100% (neverError, línea load-bearing verbatim, VIN-17, regex canónica, `_stg`/inactive) + comportamiento IA 12/12 en las 5 ramas de clasificación del resultado de issue_policy (éxito→link / error genérico→`[api_error]` / 400 geo→re-pregunta / 400 vin→re-pregunta / captura 14ch→rechaza). Staging pasó de 'descubrir' a 'confirmar'.**
- **Opción B (diferida — tarea de arquitectura aparte):** persistir el VIN validado en `whatsapp_sessions.captured_data` y que `Issue Policy` lo lea deterministamente vía `={{ $('Load Session').first().json.captured_data.serie }}` (patrón precedente — `Issue Policy` ya referencia `Load Session` con éxito). Saca a la IA del mapeo final (satisface el principio de Alberto "mapeo sin interpretación de IA") y de paso arregla el Bug #5. Es un mini-proyecto, no un cambio mínimo.
- **Rollout:** Django `stg`→prod y los cambios de n8n suben JUNTOS (o Django después de que n8n maneje el 400), o habrá emisiones atascadas.

**✅ RESOLUCIÓN (4 jul 2026) — plan definitivo de defensa en capas + decisión de formato:**
- **Decisión de negocio (Alberto):** `serie` debe ser **exactamente 17 caracteres (VIN completo)**; el bot rechaza todo lo que no cumpla. Quálitas requiere el VIN completo → la regex estricta es correcta.
- **Regex canónica (Django y n8n deben coincidir):** `^[A-HJ-NPR-Z0-9]{8}[0-9X][A-HJ-NPR-Z0-9]{8}$` (17 chars, sin espacios/guiones/acentos, sin I/O/Q, 9º carácter dígito o X). Normalizar antes: `String(serie).trim().toUpperCase()`.
- **Capa 1 — Django (Juan, ✅ hecho, rama `stg`):** autoridad final. Valida serie + `matches_geographic_field` (rechaza colonia/ciudad/municipio/estado) + contrato de error `400 {code:"invalid_vehicle_serie", reason: empty|matches_geographic_field|invalid_vin_format}`. Guía: `aguayo-co/HYL-WAI:docs/guia-n8n-validacion-serie-vin.md`.
- **Capa 2 — n8n mapeo rígido (Agente n8n, ⏳):** `Issue_Policy.serie`/`placas` leen el valor ya validado (reutilizar el de `Validate Personal Data`), NO un `$fromAI` nuevo. El valor emitido = el validado por construcción.
- **Capa 3 — n8n consistencia + validación cliente (Agente n8n, ⏳):** (a) actualizar el systemMessage del AI Agent: serie = exactamente 17 chars VIN (no "5-20"), coach al usuario; (b) Code node determinista antes de `Issue_Policy` que normaliza + valida con la regex; si falla, re-preguntar, NO llamar a Django; (c) manejar `400 invalid_vehicle_serie` → parar, re-preguntar, re-validar, sin auto-reintento.
- **Temperatura:** se queda en 0.7. Con el mapeo rígido + validación determinista, la correctitud no depende del muestreo — no hace falta tocarla.
- **INCONSISTENCIA a corregir en lockstep:** el prompt del bot decía "5-20 caracteres"; DEBE pasar a "exactamente 17" o el bot aceptará series que Django rechaza (loop muerto). Parte de Capa 3(a).
- **Pólizas con serie inválida a reemitir con Quálitas:** `7620096850` (VIN=ciudad) y `7620098065` (Sandra Luz, serie `3N1CN8AE40531V` = 14 chars, VIN incompleto). Auditar el resto con la regex.

**✅ ENTORNO DE STAGING E2E LISTO (6 jul 2026) — vía para validar el fix antes de prod:** el workflow con el fix (rama `stg` de `aibanez82/Agente-n8n`) fue **importado a una instancia n8n de staging separada** (`n8n-xlqk.srv1810257.hstgr.cloud`, aislada de prod → cierra también el Bug #12) por el Agente n8n y **verificado por el Arquitecto contra la API viva**: workflow `WhatsApp Insurance Quotation Bot_stg` id `dNqtM20ij6ecZYAX`, inactivo, VIN-17 presente, `{5,20}`=0, 0 refs a prod, Django→`hyl-wai-stg`, creds Postgres/Anthropic de staging. **Único bloqueador para el E2E: 2ª Meta App + número de test** (tarea de Alberto) → crea las 2 credenciales WhatsApp + phoneNumberId real + activación. Detalle e historia: `docs/iniciativas/entorno-pruebas-staging.md`, handoff `docs/2026-07-06-handoff-agente-n8n-import-staging-bug10.md`, reporte del ejecutor `Agente-n8n:docs/2026-07-06-resultado-import-staging.md`.

**Pólizas afectadas — pendiente re-auditar:**
- Confirmadas históricas (2 jul): 3 de 5 con valor incorrecto (`Hidalgo`, `Ciudad de México`, `Ciudad General Escobedo`).
- Póliza `7620096850` ya `PAGADO` con VIN incorrecto — reemisión manual directa con Quálitas.
- Nueva del 3 jul (`serie = "Gómez Palacio"`) — identificar número de póliza y añadir a la lista de reemisión manual.
- Correr la auditoría SQL sobre `n8n_chat_histories` (ver más abajo) para el conteo total actualizado tras esta recurrencia.

---

**Detalle Bug #11 (sesión pegada a la 1ª cotización al recotizar) — REGISTRADO, EN PAUSA (Alberto lo piensa):**
- **Síntoma (Dashboard agent, 4 jul):** el funnel "VÍA WHATSAPP" pierde leads — 46 enviados hoy, solo 37 en el funnel; los 9 faltantes recibieron el mensaje y varios conversan activamente, pero el dashboard no los ve. 9/9 verificado.
- **Causa raíz:** `whatsapp_sessions` es **única por teléfono** (`session_id='52'+telefono`). Al recotizar (común: 2-4 cotizaciones por número), se crea cotización nueva pero la fila de sesión ya existe y **su `quotation_id` NO se actualiza** → queda pegado a la 1ª cotización. El join del dashboard (`whatsapp_sessions.quotation_id = qualitas_cotizacion.id`) no encuentra la cotización nueva → lead fuera del funnel.
- **Dónde vive el fix (evidencia):** el bot de conversación NUNCA escribe `quotation_id` (solo lo lee de la BD; comentario en el código: "quotation_id is NOT extracted from message — it comes from DB"). El `quotation_id` se asigna **solo al crear la sesión**, en **el workflow del webhook de "lead creado" de Django** (envía 1er mensaje + crea sesión). **Ese workflow NO está exportado** en `docs/n8n-workflows/` (gap de fuente de verdad — hay ≥1 workflow más). El fix va ahí: **UPSERT del `quotation_id`** (si la sesión existe, actualizarla a la cotización nueva), no insert-si-no-existe.
- **Arquitectura — NO "sesión por cotización":** WhatsApp = un hilo por número, y `n8n_chat_histories` (memoria) se llavea por `session_id=teléfono`. Lo correcto: una sesión por teléfono apuntando a la cotización **más reciente** → UPSERT de `quotation_id`.
- **DECISIÓN PENDIENTE de Alberto:** al actualizar `quotation_id`, ¿(a) resetear a `greeting` + limpiar `captured_data` (recotización = conversación fresca; recomendado, porque el historial y `captured_data` arrastran contexto/serie del auto anterior y si recotiza otro auto quedan mal), o (b) mantener fase/captured_data y solo cambiar `quotation_id`? Depende de por qué recotiza la gente (mismo auto más barato vs otro auto).
- **Prerrequisitos para el handoff al Agente n8n:** (1) exportar el workflow de creación de sesión; (2) decisión (a)/(b).
- **Mitigación dashboard (aprobada como interina):** asociar la sesión por teléfono al lead más reciente + reetiquetar "Recotizaciones" en UI. El arreglo limpio es upstream (n8n).
- **Relación:** encaja con el proyecto CSF (el `captured_data` debe resetear en recotización) y con Bug #4 (leads sin whatsapp_session).

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

**Cómo se ejecutan las recomendaciones — tubería Mejoras → Arquitecto → Agente n8n (NO lateral):**

Las recomendaciones de copy se traducen en cambios al `systemMessage` del nodo **AI Agent** en n8n. El **Agente n8n es el ejecutor** de ese cambio (no Mejoras, no Alberto a mano). Pero **Mejoras y n8n NO se comunican directamente** (regla de oro: los ejecutores no se hablan). La tubería es:

```
Agente Mejoras Conversación  → analiza abandono, propone cambios de copy (informe)
        ↓
Arquitecto (yo)              → valida, traduce a cambio EXACTO (qué frase, qué nodo)
                               y CHEQUEA IMPACTO TRANSVERSAL antes de aprobar
        ↓
Agente n8n                   → aplica el cambio en el JSON, commit/push
        ↓
Alberto                      → importa en n8n
```

**Por qué el Arquitecto en medio no es burocracia — el systemMessage tiene dependencias cruzadas que Mejoras no ve:**
- **Hitos por LIKE:** los hitos (`confirmo_cobertura`, `poliza_emitida_wa`, etc.) se detectan con `BOOL_OR + LIKE` sobre frases EXACTAS del bot. Si Mejoras propone cambiar justo esas frases, arregla el abandono pero **rompe la analítica de hitos** (de la que él mismo depende). El Arquitecto lo detecta y pide al Agente n8n actualizar TAMBIÉN el patrón LIKE.
- **Bug #10 / manejo de errores:** el systemMessage (~24K chars) contiene las instrucciones de serie VIN-17, el manejo del `400 invalid_vehicle_serie`, la línea load-bearing de detección desde body. Un cambio de copy puede chocar con ellas.
- Es el mismo patrón usado para el Bug #10 (diagnóstico → prompt para el Agente n8n → ejecución). El punto de encuentro de los dos ejecutores es el Arquitecto, nunca el otro agente.

**Limitación activa — Bug #1:**
~76% de sesiones no tienen historial en `n8n_chat_histories` (medido 1 jul 2026: 154/203). El agente lo detecta y lo anota, pero el análisis de copy solo cubre el ~24% de conversaciones con datos. Nota: gran parte de ese "vacío" son leads que nunca respondieron (ver Bug #1 reinterpretado), no pérdida de datos. Los resultados son válidos pero parciales.

---

## Agente n8n — protocolo de uso

**Repo:** `aibanez82/Agente_n8n` (nombre a confirmar cuando se cree)
**Rol:** Ejecutor Nivel 3, especializado en workflows n8n. Yo (Arquitecto) diagnostico y le paso el bug/nodo a tocar; Agente n8n ejecuta el cambio en el JSON. Nunca decide qué tocar de forma autónoma.

**Flujo v1 (handoff manual, sin clonar repos entre sí):**
```
Arquitecto diagnostica → identifica workflow + nodo exacto a modificar
    ↓
Alberto baja la última versión del JSON
  (docs/n8n-workflows/ en este repo, o export fresco de n8n)
    ↓
Alberto se lo pasa a Agente n8n desde una carpeta local
    ↓
Agente n8n analiza, propone mejora, modifica el JSON
    ↓
Agente n8n hace commit/push a su propio repo
    ↓
Alberto importa el JSON manualmente en n8n (producción)
    ↓
Alberto actualiza docs/n8n-workflows/ en Agente-Arquitecto
  con la versión final importada (mantener fuente de verdad sincronizada)
```

**Punto de atención:** como Agente n8n no tiene clonado este repo, el JSON que modifica vive solo en su propio repo hasta que Alberto lo reimporta a producción y lo vuelve a traer aquí. Si se salta el último paso, `docs/n8n-workflows/` en este repo queda desactualizado respecto a lo que corre en producción — mismo riesgo que ya existía con el backup manual (ver `docs/architecture/backup-policy-n8n.md`).

**Pendiente:** confirmar nombre final del repo en GitHub una vez creado, para actualizar la tabla de "Mapa de sistemas".

---

## Entorno de pruebas / staging (iniciativa activa)

Staging end-to-end para replicar bug fixes antes de prod (gitflow `stg`→`main`). Objetivo inmediato: validar el fix del **Bug #10** (VIN/serie) E2E antes de mergear. Detalle vivo: `docs/iniciativas/entorno-pruebas-staging.md`.

**Principio rector:** stack paralelo completo; cada componente de staging apunta SOLO a gemelos de staging, nunca a prod (riesgo #1 = staging escribiendo/disparando contra prod).

**Mapa prod → staging:**

| Componente | Staging | Estado |
|---|---|---|
| Backend/landing | `hyl-wai-stg` (`https://hyl-wai-stg-d1085ad74dbf.herokuapp.com`, deploy desde rama `stg`) | ✅ existe |
| Base de datos | Addon Postgres propio de `hyl-wai-stg` | ✅ (`STG_DATABASE_URL`) |
| n8n (bot WA) | **Instancia SEPARADA** en Hostinger `https://n8n-xlqk.srv1810257.hstgr.cloud` (servidor `srv1810257` ≠ prod `srv1325340`; BD/encryption key propias) | ✅ viva, API habilitada. Decisión clave: instancia separada para NO recaer en el Bug #12 (webhookId compartido) |
| Número WhatsApp | 2ª Meta App + número de test (Cloud API) | ❌ **bloqueador — Juan** |
| Quálitas | Sandbox QA (`QUALITAS_URL`→`qa.qualitas.com.mx`; el switch es la URL, NO `QUALITAS_AMBIENTE_FLAG`) | ✅ credenciales QA + `QUALITAS_AMBIENTE_FLAG=0` (valor de prueba) ya en Heroku `hyl-wai-stg` — confirmado por Alberto 7 jul |
| Dashboard | Vercel Preview → BD stg | ⏳ Fase 2 |

**Hecho y verificado por el Arquitecto (6 jul):**
- Instancia n8n stg aislada + API (`N8N_STG_API_KEY` en `.env.local`).
- Credencial **Postgres STG** `5wlLe3gD07CLIM7U` + **Anthropic STG** `aHI51VvnRnPixCx5`.
- Workflow del bot **con el fix Bug #10 importado** (desde `aibanez82/Agente-n8n` rama `stg`): `WhatsApp Insurance Quotation Bot_stg` id **`dNqtM20ij6ecZYAX`**, **inactivo**, 61 nodos, 0 refs a prod, VIN-17 presente, Django→`hyl-wai-stg`. Ejecutado por el Agente n8n vía API, verificado contra la instancia viva.

**Bloqueador único del E2E: 2ª Meta App de test (Juan).** De ella salen las 2 credenciales WhatsApp + phoneNumberId + la autorización OAuth2 + la activación. Mensaje listo: `docs/2026-07-06-mensaje-juan-meta-app-staging.md`.

**Fase E2E ya especificada (handoff v2, modelo OAuth2 nativo):** el trigger `whatsAppTrigger` de n8n es **OAuth2** (`clientId`=App ID / `clientSecret`=App Secret); `whatsAppApi` (Send) pide `accessToken`+`businessAccountId` (WABA). Modelo A (nativo) elegido porque prod usa ese trigger → staging debe ser gemelo fiel. Requiere: 6 secretos de Juan (`STG_WA_ACCESS_TOKEN`, `STG_WA_BUSINESS_ACCOUNT_ID`, `STG_WA_APP_ID`, `STG_WA_APP_SECRET`, `STG_WA_PHONE_NUMBER_ID`), whitelist de la redirect URL OAuth de n8n en la App, y un **"Connect" OAuth2 manual de Alberto** en la UI (la API no lo hace). Handoff: `Agente-n8n:handoffs/2026-07-06-fase-e2e-staging-bug10.md` (canónico en `docs/2026-07-06-handoff-agente-n8n-fase-e2e-staging-bug10.md`).

**Convención de handoffs (aprendida 6 jul):** todo handoff a un ejecutor se deja en el repo de ESE ejecutor (`<repo>/handoffs/`) y se comunica con la **ruta absoluta completa** + ubicación git. Nunca solo en el repo del Arquitecto.

**Gotchas de import por API n8n (reutilizables):** (1) reducir el export a `{name,nodes,connections,settings}` (rechaza `active`/`id`/`tags`/`shared`/`activeVersion`/`pinData`); (2) filtrar `settings` a claves válidas — `binaryMode`/`availableInMCP` dan 400; (3) el import heredó el `webhookId 18c1b498` de prod (Bug #12) → regenerar en la fase E2E.

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
| `n8n_chat_histories` sin columna de timestamp (confirmado por el Dashboard agent: 855 filas, `additional_kwargs`/`response_metadata` vacíos, sin `created_at` — hora real inexistente). **Fix = migración de BD por Juan/dueño del rol `DATABASE_URL`, NO el agente n8n (es DDL, y `DEFAULT now()` no requiere tocar el workflow).** DDL correcta en **dos pasos** (para que el histórico quede NULL/honesto en vez de horas falsas): `ALTER TABLE n8n_chat_histories ADD COLUMN created_at timestamptz;` y luego `ALTER TABLE n8n_chat_histories ALTER COLUMN created_at SET DEFAULT now();`. ⚠️ NO usar `NOT NULL DEFAULT now()` en un solo paso: rellenaría las 855 filas viejas con horas idénticas falsas (reintroduce "colapsado a una hora"). Aplicar igual a `_archive` y que el archivado **preserve** `created_at` (no regenerar con `now()`). Grants: no hace falta nuevo GRANT (columna nueva hereda el SELECT de la tabla). Dashboard ya aplicó parche interino y **está desplegado en prod** (commit `05576eb` en `main`): mensajes n8n sin reloj, "hora aproximada"; solo Django pinta hora exacta vía `sent_at`. **Columna vs JSON zanjado con evidencia del workflow:** hay 3 puntos de escritura — 2 nodos stock LangChain `memoryPostgresChat` (bot principal, la mayoría de mensajes, SIN hook para el JSON) + 1 Postgres custom `executeQuery` (workflow proactivo). La opción JSON solo cubriría los proactivos → inconsistente; la columna `DEFAULT now()` cubre los 3 por igual. | ⏳ Pendiente externo (Juan) — **issue [`aguayo-co/HYL-WAI#87`](https://github.com/aguayo-co/HYL-WAI/issues/87)** con DDL + verificaciones + evidencia; ver también `docs/estrategia/2026-07-01-conversacion-completa-wa-n8n-django.md` |
| Issue #74 (`aguayo-co/HYL-WAI`) — follow-up 15 min dejó de enviarse desde 2026-06-30 ~21:11 UTC | ⏳ Causa raíz sin determinar. Requiere acceso Heroku (config vars, releases, scheduler) — Alberto va a dar token OAuth read-only vía Vercel env Plain |
| Propuesta arquitectura BD — tabla canónica `whatsapp_event` (dual-write desde n8n/Django/Dashboard, reemplaza joins frágiles y LIKE de hitos) | 💡 Documentada como plan de destino, sin decisión de implementar aún |
| Alerta de emisión fallida (Bug #9) — workflow `Bot Error Handler` en n8n + tarjeta "Emisión falló" en Dashboard | ⏸️ En pausa — implica desarrollo de n8n (Error Workflow + extracción de datos de la ejecución fallida). Spec lista en `docs/estrategia/2026-07-02-alerta-emision-fallida-quálitas.md` |
| Crear repo `Agente_n8n` en GitHub + confirmar nombre final | 🆕 En construcción — ver protocolo en sección "Agente n8n" |
| `N8N_TOKEN` con valor real hardcodeado como default en `qualitas/views.py:905` (rama `stg`) | ⚠️ Seguridad — hallazgo del 6 jul al auditar config vars de `hyl-wai-stg`. Mover a solo-env y rotar el token — pedir a Juan. Ver `docs/iniciativas/entorno-pruebas-staging.md` |
| Revisar cumplimiento de la política de IA de WhatsApp de Meta (enero 2026, interacciones deben ser "task-specific") | ⏳ Pendiente — priorizar sobre el escalado de volumen. Ver `docs/estrategia/2026-07-06-evaluacion-plataformas-conversacion-whatsapp.md` |
| Cómo saber con certeza si un cliente pagó la póliza — la doc oficial SOAP de Quálitas (`docs/qualitas-api/`: WsEmision, WsTarifas, WsImpresion, Matriz de Captura) **no documenta ningún endpoint ni campo de consulta de estatus de pago** (verificado 7 jul). Solo cubre `FormaPago` (método/frecuencia) y los recibos generados al emitir — nada sobre si un recibo/link de pago fue efectivamente pagado. Hoy la única señal automatizada es `qualitas_polizaemitida.estatus_pago`, que depende de un webhook externo de Quálitas hacia Django no documentado en su spec (ver Bug #7 y su workaround). Detectado por Alberto al revisar una conversación con póliza emitida y link de pago enviado, sin forma de confirmar el pago desde ahí. **No es dependencia de Juan** — la resolución probable es manual: Laura (Hylant) reporta ventas/pagos confirmados en una hoja Excel al día siguiente. | 💡 Sin investigar — definir si conviene formalizar el reporte de Laura como fuente de verdad (p. ej. cargarlo al Dashboard) en vez de perseguir un mecanismo automático de Quálitas |

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
   │ APIs    │       │ • Agente n8n            │
   │         │       │ • Agente Conversión (⏳) │
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
| Agente n8n | Entiende workflows n8n, propone mejoras, modifica JSON | 🆕 En construcción |
| Agente Conversión | Reintentos + seguimiento | ⏳ Futuro |

---

## Variables de entorno clave (Vercel)

`DATABASE_URL` · `GOOGLE_SERVICE_ACCOUNT_EMAIL` · `GOOGLE_PRIVATE_KEY` · `GA4_PROPERTY_ID` · `META_WABA_ID` · `META_ACCESS_TOKEN` · `META_PHONE_NUMBER_ID` · `DASHBOARD_PASSWORD` · `GITHUB_ISSUES_TOKEN` · `N8N_API_KEY` · `N8N_PROACTIVE_WEBHOOK_URL` · `PROACTIVE_MESSAGE_PASSWORD`

⚠️ Solo environments **Production** y **Preview** — no Development.

---

## Convenciones

- **Persistencia entre máquinas — NUNCA usar memoria local:** Alberto trabaja desde al menos 3 laptops. La carpeta de memoria del agente (`.claude/…/memory/`) es **local a cada máquina y no se sincroniza** → se pierde al cambiar de equipo. Por tanto, TODA iniciativa, plan, backlog o cualquier cosa que deba conservarse se guarda **en git** (en `docs/iniciativas/` para iniciativas/backlog, o el `docs/` que corresponda) y se hace commit+push. Nunca en memoria.
- **Git:** siempre `user.email = a.ibanez@gmail.com` / `user.name = aibanez82`
- **Timezone (estándar de consistencia):** almacenar SIEMPRE el instante absoluto en `timestamptz` (UTC interno); convertir a `America/Mexico_City` (UTC-6, sin horario de verano desde 2023) SOLO en presentación (dashboard), nunca en la BD ni antes. Nunca usar `timestamp without time zone` ni comparar tz-naive con tz-aware. Verificado 4 jul: Django ya cumple (`TIME_ZONE="UTC"` + `USE_TZ=True` → todos los `DateTimeField` son `timestamptz`); el `created_at` nuevo de `n8n_chat_histories` es `timestamptz`. **⚠️ HALLAZGO CONFIRMADO (4 jul, auditoría information_schema):** Django `qualitas_*` todas `timestamptz` ✅, PERO `whatsapp_sessions` y `whatsapp_sessions_archive` tienen sus 6 columnas de tiempo (`created_at`/`last_activity`/`updated_at`) como **`timestamp without time zone` (NAIVE)**. n8n les escribe `NOW()` → el valor queda en la zona de la sesión de n8n; al compararse con timestamptz de Django o con el scheduler de follow-up → desfase ±6h. **Candidato fuerte a causa del Issue #74** (follow-up de 15 min caído). **Zona confirmada (4 jul): n8n escribe en UTC** (last_activity máx 21:06 solo es un pasado coherente si es UTC; sería futuro si fuese México). DDL de migración (Juan): `ALTER TABLE whatsapp_sessions ALTER COLUMN created_at TYPE timestamptz USING created_at AT TIME ZONE 'UTC', ALTER COLUMN last_activity TYPE timestamptz USING last_activity AT TIME ZONE 'UTC', ALTER COLUMN updated_at TYPE timestamptz USING updated_at AT TIME ZONE 'UTC';` — idem `whatsapp_sessions_archive`. n8n no requiere cambios (sigue escribiendo `NOW()`). Verificar Issue #74 tras migrar (probable fix del desfase del scheduler). DDL final en issue #87. Query de auditoría: `SELECT table_name, column_name, data_type FROM information_schema.columns WHERE table_schema='public' AND (data_type LIKE 'timestamp%' OR column_name ~ '(_at$|last_activity|fecha|occurred|sent|queued)') ORDER BY data_type, table_name;` — cualquier `timestamp without time zone` es bandera.
- **GitHub Issues:** labels con caracteres exactos incluyendo acentos (e.g. `crítico`)
- **DB:** usar siempre `lib/db.js` del Dashboard — nunca conexiones directas ad-hoc
- **n8n API:** `https://n8n.srv1325340.hstgr.cloud/api/v1/` con header `X-N8N-API-KEY`
