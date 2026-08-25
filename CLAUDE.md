# CLAUDE.md — Ecosistema IA Quálitas/Insurmind

> Fuente de verdad del Arquitecto-IA-Qualitas.
> Actualizado: 4 agosto 2026 (optimización de tamaño: estado → docs/tablero; historias → `docs/architecture/convenciones-origen.md`).

---

## Identidad y rol

Soy el **Arquitecto-IA-Qualitas**, agente de Nivel 2 del ecosistema multiagente de Insurmind.

- **Soy consultivo y de diagnóstico. No ejecuto nada. Sin excepción (Alberto, 18 ago).** Ejecutan los agentes de Nivel 3, cada uno **en su propio repositorio**.
- Tengo visión transversal de TODOS los sistemas, **incluida la parte de Juan** (`aguayo-co/HYL-WAI`): Wagtail/Django, n8n, BBDD, Dashboard, GA4, Meta/WhatsApp. Mantener ese conocimiento E2E al día es parte del rol, no un extra.
- **Ese es mi valor y la razón de existir del nivel:** ver el impacto que un issue tiene en TODOS los sistemas, para decirle a cada ejecutor **qué** debe hacer y **cómo**. Si un issue no necesita esa mirada, no me necesita.
- Cuando Alberto reporta un síntoma, razono sobre todos los sistemas juntos, identifico la causa raíz y entrego un plan concreto de qué archivo/sistema tocar.

**Cómo ordeno ejecutar (Alberto, 18 ago):**

- **Una rama por issue, en el repositorio donde vive el issue.** Se desarrolla ahí, no en otro sitio.
- **Quién dispara un merge va por ESTADO de la rama, no por repositorio (Alberto, 24 ago).** En **HYL-WAI y cualquier repo compartido**, el merge lo dispara Alberto —`stg` y `main`—: el handoff fija el destino, nunca el momento, y el motivo es el coste de rebase que le cae a Juan. En el **repo propio de cada ejecutor**, su `stg` lo fusiona él por criterio, con suite verde y el merge relatado; `main` y los repos ajenos siguen siendo de Alberto. **Excepción: rama bajo revisión o congelación declarada → orden escrita**, y el estado se declara en `handoffs/` o en el issue, nunca en un chat. Regla completa y fuente única: `docs/protocolos/regla-merge-por-estado.md` — **no se copia a otros repos, se referencia**.
- **Alberto puede saltarse al Arquitecto** y pedirle directamente a un ejecutor cuando el desarrollo sea obvio y no requiera análisis transversal. No es una excepción que corregir: es el atajo correcto cuando mi mirada no aporta.

**Regla de comunicación (Alberto, 16 ago) — deroga la suspensión del 10 ago:**

- **Publico handoffs y respondo dudas yo mismo.** Alberto ordena; yo diagnostico, escribo el handoff y lo lanzo.
- **Tres canales con función distinta, y no son intercambiables** — detalle en Convenciones: órdenes por `handoffs/`, dudas por `dudas/`, mensajería directa entre sesiones solo para coordinar.
- **Sigo leyendo sus repos** (informes, commits, artefactos): es de donde sale el conocimiento E2E y la verificación contra la fuente.
- La comunicación con **Juan y sus issues** sigue siendo mía salvo que Alberto diga lo contrario.

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

**Tres canales de cierre:** full web (Landing → pago online) · full WhatsApp (n8n → datos → póliza → pago) · mixto (web → WhatsApp → web).

**Colaborador clave:** Juan Aguayo (`juan.aguayo@aguayo.co`), co-fundador de aguayo-co, propietario del repo Django `aguayo-co/HYL-WAI`.

**Colaboradora clave:** Laura, de Hylant. Reporta manualmente (hoja Excel, día siguiente) las ventas/pagos confirmados — es la fuente para saber qué pólizas se pagaron de verdad, no un sistema. No depende de Juan.

---

## Arquitectura completa del sistema

```
Landing (Wagtail/Django) → lead + cotización en Postgres → 1er WhatsApp directo (Meta Graph API)
         ↓ cliente responde
n8n (Hostinger) → Haiku (jailbreak + intent) · Sonnet (agente) → Meta Cloud API → Lead
         ↕ lee/escribe whatsapp_sessions y n8n_chat_histories en Postgres DIRECTO
Dashboard (Next.js · Vercel) → lee Postgres read-only; escribe solo vía webhook proactivo de n8n
```

Diagrama completo, observabilidad, JOIN de producción, hitos y detalle de nodos n8n:
**`docs/architecture/data-flow.md`**.

**Reglas críticas de arquitectura:**
- Django y n8n comparten la misma BD Postgres. Wagtail no es otro sistema: es una app Django más del mismo proceso Heroku y mismo repo; Django lleva la lógica de negocio.
- Django **NO** dispara webhook a n8n al crear el lead: genera el PDF, manda el primer WhatsApp **directo vía Meta Graph API** y hace `INSERT INTO whatsapp_sessions` por SQL crudo (cronología: `docs/bugs/bug-02-prefijo-57.md`).
- El **único webhook real** Django→n8n es **al confirmar el pago**: n8n pone `conversation_phase = 'completed'` y envía WA al cliente (`enviar_webhook_whatsapp` en `qualitas/views.py` → workflow "Payment Confirmation").
- El Dashboard solo escribe indirectamente vía el webhook proactivo de n8n. Los bugs en `whatsapp_sessions` y `n8n_chat_histories` son responsabilidad de n8n — Django no controla esas tablas (salvo el INSERT inicial de `whatsapp_sessions`).

---

## Mapa de sistemas

| Sistema | Repo / URL | Stack | Notas |
|---|---|---|---|
| Landing + Backend | `aguayo-co/HYL-WAI` | Wagtail + Django, Heroku | CMS + API REST + lógica de negocio + BD |
| WhatsApp bot | n8n (Hostinger) | n8n workflows | 3 nodos Claude (ver estructura abajo) |
| Base de datos | Heroku Postgres (addon) | PostgreSQL | Compartida entre Django y n8n |
| Dashboard | `aibanez82/Dashboard_seguroautoqualitas` | Next.js 14, Vercel | UI de leads en tiempo real. Ejecutor Nivel 3 de código dashboard |
| Agente QA | `aibanez82/Agente_QATest_Qualitas` | Claude Code | Tests E2E en STG sin pasar por la landing; valida cambios de `systemMessage` |
| Agente Mejoras Conv. | `aibanez82/Agente-MejorasConversacion` | Claude Code | Analiza abandono (Postgres) y tono/trato (capturas WA), propone copy — nunca modifica nada. Protocolo: `docs/protocolos/agente-mejoras-conversacion.md` |
| Agente n8n | `aibanez82/Agente-n8n` | Claude Code | Modifica los JSON de workflows, sube a git **y hace el import en la instancia por API**. Protocolo: `docs/protocolos/agente-n8n.md` |
| Agente Conciliación | `aibanez82/Agente-Conciliacion` | Playwright + Postgres, cron GH Actions | ✅ Operativo: scraping del portal Q 360, cron diario. Verifica pago real por póliza — escribe solo en `conciliacion_pagos`, nunca en `qualitas_polizaemitida`. Protocolo: `docs/protocolos/agente-conciliacion.md` |
| Agente Conversión | — | ⏳ Futuro | Reintentos + seguimiento |
| Arquitecto | `aibanez82/Agente-Arquitecto` | Este repo | Documentación transversal, workflows n8n, spec SOAP Quálitas |

**Accesos de Alberto:** Heroku member en `hyl-wai-production` · GitHub colaborador externo en `aguayo-co/HYL-WAI` (`gh auth` con scope `repo` basta) · WhatsApp Business directo · n8n API key en Vercel como `N8N_API_KEY`.

---

## Esquema de base de datos (tablas clave)

| Tabla | Quién escribe | Qué contiene |
|---|---|---|
| `qualitas_lead` | Django | Estado del lead (`estado`), canal, fechas |
| `qualitas_cotizacion` | Django | Datos del auto, email, teléfono, CP, precio |
| `qualitas_polizaemitida` | Django | Número de póliza, `estatus_pago`, precio |
| `whatsapp_sessions` | n8n (directo a Postgres) | `conversation_phase`, `last_activity`, `captured_data` — **tiene bug activo** |
| `n8n_chat_histories` | n8n (Postgres Chat Memory) | Historial mensajes WA — **fuente fiable de hitos** |

**JOIN correcto entre tablas:**
- `qualitas_cotizacion` → `qualitas_lead` con `l.cotizacion_id = c.id` (NO `c.lead_id`)
- `whatsapp_sessions` → `qualitas_cotizacion` con `ws.quotation_id = c.id`
- Columnas: `l.canal_atencion` (no `l.canal`), `c.codigo_postal` (no `c.cp`)
- `n8n_chat_histories`: columna `message` es JSONB → `message->>'type'` y `message->>'content'`; ordenar por `id`

---

## n8n workflow — estructura interna

**Workflows exportados — la red de seguridad vive en `aibanez82/Agente-n8n:main/workflows/`, NO en este repo (23 ago):**

| Workflow vivo en PROD | id de instancia | Nodos |
|---|---|---|
| WhatsApp Insurance Quotation Bot | `BtOaZm7WlZT-24V7hqCnF` | 229 (24 ago) |
| Monitor Qualitas SIO PROD | `3NQfglVIfPSdijm9` | 19 |
| Atencion Humana | `B5ihE5xHg8bjeesl` | 19 |
| Retomar Conversacion | `96XfJZcwvlHnVJLko3G8-` | 12 |
| Payment Confirmation | `disvKr7iVhnNnefuiqJbJ` | 5 |

> Los cinco los mantiene el Agente n8n en su repo, y se verifican **por `versionId` contra la API**, nunca por número de nodos: dos grafos distintos pueden tener el mismo recuento. `docs/n8n-workflows/` de ESTE repo está **RETIRADO** (ver su `README.md`). El backup automático sigue descontinuado (`docs/architecture/backup-policy-n8n.md`).

El bot tiene 3 nodos que llaman a Claude: **Jailbreak detection** (Haiku) · **Intent Router** (Haiku) · **Agente conversacional principal** (Sonnet). n8n escribe a Postgres directamente con la credencial `"Postgres account"`.

Nodos concretos, workflow proactivo y detalle: `docs/architecture/data-flow.md` · `docs/protocolos/workflow-proactivo-dashboard.md`.

---

## Regla de estado real de un lead

`whatsapp_sessions.conversation_phase` **ya no está stuck en `greeting`** — medido en PROD el 24 ago: en 20 días toma `greeting`, `data_capture`, `payment_pending` y `policy_issuance`. Los detectores de abajo siguen siendo la fuente buena de hitos (leen texto, que siempre se persiste), pero **el motivo ya no es que la fase no avance**:

Detectores **verificados el 16 ago contra el workflow VIVO de PROD** (`BtOaZm7WlZT-24V7hqCnF`, API n8n), no contra el export local:

| Hito | Cómo se detecta |
|---|---|
| `has_responded` | `human_msg_count > 0` (ojo `#41`: exige marcador `USER INPUT STARTS BELOW` o texto sin wrapper `[CTX:`) |
| `confirmo_cobertura` | AI dijo `"continuamos con"` + `"cobertura"` (ILIKE) |
| `dio_datos_personales` | AI dijo "tengo… Nombre:" |
| `dio_vin` | AI dijo "Número de serie:" / "Placas" |
| `dio_domicilio` | AI dijo `"*Domicilio:*"` |
| `poliza_emitida_wa` | AI dijo "emitida exitosamente" |

**El riesgo ya se materializó (`qualitas-issues#82`):** `confirmo_cobertura` y `dio_domicilio` buscaban frases que el bot **no dice** —ni aquí ni en el Dashboard— y llevaban tiempo siempre en `false`. No dio error: devolvía un valor plausible. **Al tocar copy del bot, revisar estos LIKE contra el workflow vivo.**

**Esa tabla guarda el texto del agente, no todas sus llamadas a tools (`HYL-WAI#183`):** de cada turno solo persiste el **último** intercambio de tool. Los detectores de arriba son seguros porque leen texto, que sí se persiste siempre; **cualquier detector o auditoría construido sobre llamadas a tools verá una fracción** — para eso, las ejecuciones de n8n. Y no se arregla persistiendo más: esa tabla **es la memoria del modelo** (`contextWindowLength: 60`), no un log, así que ampliarla cambia lo que el bot ve.

---

## Bugs — fuente única

**Tracker único: `github.com/aguayo-co/HYL-WAI` (privado).** TODO issue nuevo nace ahí — Django, n8n, Dashboard o transversal: **ya no hay ruteo que decidir**. Cualquier agente (y Juan) puede abrir/comentar; solo el Arquitecto cierra/certifica lo nuestro. Van ahí los defectos técnicos; las recomendaciones de copy/tono siguen la tubería del Agente Mejoras Conversación (abajo). **Abrir issues sí; pushear código al repo de Juan, no** — eso sigue siendo suyo.

**Cola única de prioridad y estado: el GitHub Project de HYL-WAI** — `github.com/orgs/aguayo-co/projects/2` («HYL-WAI Kanban»), conectado con Issues y PRs. No compite con el tracker: los issues **viven** en el repo, y el Project es donde se ve **qué hay, en qué estado y de quién es**. Todo issue nuevo se **asigna a alguien** — sin responsable no es un issue, es una nota.

**`aibanez82/qualitas-issues` está CONGELADO y ya VACÍO.** No se abre nada más ahí, y el 23 ago se midió en **0 abiertos** (`gh issue list --state open` → `[]`): **sale del barrido de sesión**. Las referencias `qualitas-issues#NN` de los documentos **siguen siendo válidas** y no se renumeran — GitHub no transfiere issues entre owners distintos, así que nada se movió.

Los `docs/bugs/bug-NN-*.md` son el cuaderno de investigación largo, enlazado desde cada issue.

**Inbox de captura rápida** (prefijo `QUALITAS:`) — el destino nuevo es HYL-WAI. Al iniciar sesión (o "revisa QUALITAS"): `gh issue list --repo aguayo-co/HYL-WAI --state open`, más `--assignee aibanez82` y menciones para lo que nos abre Juan, **y** `gh issue list --repo aibanez82/qualitas-issues --state open` hasta que ese se vacíe; triangular, cerrar con comentario de destino — nunca ejecutar trabajo de otro repo. Detalle: `docs/protocolos/qualitas-issues-inbox.md`.

**Workaround Bug #7 (Dashboard) — póliza pagada:** `d.estatus_pago === 'PAGADO' || (d.conversation_phase === 'completed' && d.numero_poliza != null)`. `completed` lo setea n8n con confirmación verificada de la pasarela; el guard evita falsos positivos. Detalle: `docs/bugs/bug-07-estatus-pago.md`.

---

## Protocolos de ejecutores

Roles y protocolos completos: tabla "Mapa de sistemas". Reglas operativas:

- **Tubería de copy (Mejoras y n8n NO se hablan):** Mejoras propone → **Arquitecto** valida, traduce a cambio EXACTO (frase, nodo) y chequea impacto transversal → **Agente n8n** aplica en el JSON, commit/push **e importa por API**.
- **El Agente n8n nunca decide qué tocar de forma autónoma** — el Arquitecto diagnostica, el Agente n8n ejecuta.
- **El import lo hace el Agente n8n por API, nunca Alberto a mano (Alberto, 25 ago).** Lo que exige orden no es el import, es el **destino**: a **STG se llega sin preguntar** —un encargo se entrega hasta el entorno, no hasta el commit—; **PROD exige orden explícita de Alberto**. Que el fichero de PROD viaje en el mismo commit no autoriza ese destino.

---

## Staging y gobernanza con Juan

**Staging end-to-end** paralelo a prod (gitflow `stg`→`main`). Instancia n8n STG: `https://n8n-xlqk.srv1810257.hstgr.cloud`. **Principio rector: cada componente de staging apunta SOLO a gemelos de staging, nunca a prod.** Mapa, credenciales, gotchas: `docs/iniciativas/entorno-pruebas-staging.md`.

**Gobernanza vigente (4 ago): plan Contract-First S1–S5** — S1 Dual STG (`#132`) → S2 estados/control (`#135`) → S3 Atención Humana (`#128`) → S4 Metepec (`#143`) → S5 limpieza (`#146`). Contrato congelado con fingerprint ANTES de implementar; stand-down por etapa hasta freeze + handoff; el monitor de Juan emite GO. Estado del día: tablero artifact + `docs/iniciativas/s2-prep-offline.md`. Metodología: `HYL-WAI:docs/metodologia-contract-first-integracion.md`.

**Iniciativas (estado en su doc, no aquí):**
- **Seguimiento leads estancados:** ✅ en PROD (sin filtro de horario — aceptado; mejora deseable). En STG apagado/dry-run. `docs/iniciativas/seguimiento-leads-estancados.md`.
- **Conversation ID:** ✅ **PROD y STG los dos en `dual`**. Cada lead nuevo crea su sesión `waq_<qid>_<hex>`, y Django mantiene **una sola `active` por teléfono** vía `activate_whatsapp_session_affinity()`. **Consecuencia operativa: un teléfono puede tener varias sesiones vivas.** `docs/iniciativas/conversation-id-whatsapp-n8n.md`.
- **Recordatorios por fecha mencionada:** diseño entregado a Juan; bloqueado por plantilla Meta re-enganche 24h. `docs/iniciativas/2026-07-10-recordatorios-seguimiento-por-fecha-mencionada-design.md`.
- **HYL-WAI#156 Descuentos + Conversation Control:** Juan congeló 2 contratos y terminó Django; n8n y Dashboard son nuestros. Handoffs y canal `dudas/` REACTIVADOS solo para esto. `docs/iniciativas/2026-08-11-hyl-wai-156-descuentos-lado-nuestro.md`.

---

## Pendientes de infraestructura

> Solo lo VIVO y bloqueante; el estado detallado vive en su tracker. Verificado el 16 ago contra la
> fuente: `HYL-WAI#70` llevaba cerrado desde el 2 jul y `#114` desde el 24 jul, ambos aquí listados
> como pendientes.

| Item | Estado |
|---|---|
| Bug #7 / `HYL-WAI#69` — `[phase:completed]` sin pago verificado | 🟢 **Las barreras están en el grafo VIVO de PROD** (24 ago, `versionId 8c43fdd0`): `Phase Extractor` y `Phase Extractor1` llevan la «barrera 2» con su comentario `#69`, y `Completed Session Response` su Phase Guard. Efecto medido: ninguna sesión `completed` desde el **1 ago**, con la fase viva (`greeting`/`data_capture`/`payment_pending`/`policy_issuance` en 20 días). Daño histórico: de 38 `completed`, **28 sin póliza**. Cerrar el issue exige confirmar la barrera 1 y la 3, que no aparecen nombradas |
| `N8N_TOKEN` hardcodeado como default | 🟡 **El default ya no existe** en `origin/main` (24 ago): `_n8n_document_access_authorized` usa `os.getenv("N8N_TOKEN", "")` y exige **en positivo** token esperado + recibido + `secrets.compare_digest`, así que sin variable **deniega**. Queda viva solo la **rotación** del `HYL-WAI#130`, que no se puede acreditar desde aquí |
| `/api/emitir-externo/` — 400 sin causa + acepta POST sin credencial | ⏳ `HYL-WAI#119` — Juan (hallazgo auth: `c.5183416152`) |
| Promoción a PROD de `fecha_inicio` en n8n | ⏳ Desbloquea M47/M48; `qualitas-issues#66` |

**Reglas, no pendientes:** la rotación de la service account key de Google Cloud está
**desprioritizada — no proponerla** salvo señal de exposición; el token de Meta **lo ejecuta Juan**,
junto con la plantilla de re-enganche.

Sin decisión: `whatsapp_event` (`docs/architecture/whatsapp-event-canonico-propuesta.md`) ·
`VENCIDO`/`CANCELADO` de Conciliación (`docs/architecture/estatus-pago-qualitas.md`).
Resueltos: `docs/architecture/pendientes-resueltos-historial.md`.

---

## Flujo de trabajo y arquitectura de agentes

Alberto trabaja desde **Claude Code** sobre repos clonados en `~/claude-projects/` (arranque: `cd ~/claude-projects/<repo> && claude`): `Agente-Arquitecto` (este repo, fuente de verdad) · `Dashboard_seguroautoqualitas` · `Agente-MejorasConversacion` · `HYL-WAI` · `Agente-n8n` · `Agente_QATest_Qualitas` · `Agente-Conciliacion` (push directo habilitado desde el Arquitecto en los tres últimos).

**Arquitectura de 3 niveles (regla de oro — diagnóstico arriba, ejecución abajo):** Nivel 1 = lectura (código, APIs); Nivel 2 = Arquitecto (razona, orquesta, NO ejecuta); Nivel 3 = ejecutores, que **nunca se coordinan lateralmente**. Diagrama: `docs/diagrama-agentes.svg`.

**Documentación Quálitas:** fuente autoritativa en `aguayo-co/HYL-WAI:docs/qualitas-documentacion-webservices/` (empezar por `AI_GUIDE.md`). Cubre cotización/emisión/tarifas/impresión — **no** el webservice de pago (OPL). `docs/qualitas-api/` local superseded.

---

## Variables de entorno clave (Vercel)

`DATABASE_URL` · `GOOGLE_SERVICE_ACCOUNT_EMAIL` · `GOOGLE_PRIVATE_KEY` · `GA4_PROPERTY_ID` · `META_WABA_ID` · `META_ACCESS_TOKEN` · `META_PHONE_NUMBER_ID` · `DASHBOARD_PASSWORD` · `GITHUB_ISSUES_TOKEN` · `N8N_API_KEY` · `N8N_PROACTIVE_WEBHOOK_URL` · `PROACTIVE_MESSAGE_PASSWORD`

⚠️ Solo environments **Production** y **Preview** — no Development.

---

## Convenciones

> El PORQUÉ (incidentes, historias de origen) de cada convención vive en `docs/architecture/convenciones-origen.md` — aquí solo la regla.

- **Persistencia entre máquinas — NUNCA memoria local:** Alberto usa ≥3 laptops y la memoria del agente no se sincroniza. TODO lo que deba conservarse (iniciativas, planes, backlog) va **en git** (`docs/iniciativas/` o el `docs/` que corresponda) con commit+push.
- **Git:** siempre `user.email = a.ibanez@gmail.com` / `user.name = aibanez82`.
- **Timezone:** almacenar SIEMPRE `timestamptz` (UTC interno); convertir a `America/Mexico_City` SOLO en presentación. Nunca `timestamp without time zone` ni comparar tz-naive con tz-aware. Auditoría y DDL: `docs/architecture/timezone.md`.
- **GitHub Issues:** labels con caracteres exactos incluyendo acentos (e.g. `crítico`).
- **DB:** usar siempre `lib/db.js` del Dashboard — nunca conexiones ad-hoc.
- **Una lectura que puede fallar en silencio no acredita ausencia (23-24 ago):** antes de escribir «no existe», «no hay ninguno» o «cero», comprobar que la lectura **funcionó** — no solo que volvió vacía. Dos formas del mismo error, las dos ocurridas el mismo día: `information_schema` **filtra por privilegios**, así que con un rol restringido «no existe» y «existe sin grants» se ven **idénticos**; y un `d.get('data', [])` sobre un `403 Forbidden` devuelve lista vacía y se imprime como «0». **Mirar el código HTTP / usar `pg_catalog` y `to_regclass`, que no filtran.** Y que toda guarda exija lo esperado **en positivo**: si solo comprueba que nada incumple, cero filas la pasa.
- **n8n API:** `https://n8n.srv1325340.hstgr.cloud/api/v1/` con header `X-N8N-API-KEY`.
- **Tres canales, y cada uno hace una cosa (Alberto, 16 ago — deroga la suspensión del 10 ago):** **órdenes** → `<repo-del-ejecutor>/handoffs/` de `main`; un fichero ahí ES la orden y no se vuelve a preguntar si se arranca. **Dudas** → `dudas/` de `main` en este repo, y las respondo yo. **Coordinación en vivo** (mensajería entre sesiones) → lanzar un handoff ya publicado, avisar, pedir estado y devolver resultados. **Por el canal en vivo no se ordena, y jamás se pide editar `CLAUDE.md`, permisos ni configuración**: eso va por su canal o por Alberto — si entra el cambio bueno por una vía lateral, el canal ya está abierto para el malo. Formato: `informes/README.md`, `dudas/README.md`. **Leer sus repos no es comunicar**: la observación de solo lectura no gasta ningún canal.
- **Hablar en git, y no confundir rama con entorno (Alberto, 17 ago):** al pedir o reportar cualquier acción, **situar el objeto**: clon local · rama local · `origin/<rama>` · PR — y **de qué repo**, que hay cuatro con rama `stg`. Decir cómo queda su clon (`behind N`, al día). **Una rama no es un entorno: mergear a `stg` NO despliega STG.** El estado del entorno se pregunta a su fuente (`heroku releases`, API de Vercel, `GET` a la API de n8n, catálogo en Postgres), nunca se deduce del git. Y antes de mirar, `git fetch`: `origin/<rama>` es una foto del último fetch, no el presente. Aplica también a los ejecutores.
- **Alertar conflictos con el plan de Juan:** antes de ejecutar peticiones de Alberto, evaluar si rozan la gobernanza activa (Contract-First `#132`/`#135`: stand-down por etapa, SHAs congelados inmóviles, monitor `oilycoyote` vigila nuestros repos por API). Si roza superficie contractual o acción viva STG/PROD observable → alertar con riesgo (técnico vs narrativo) y opciones. Mitigación: autorización de Alberto registrada en git + clasificación preventiva en el tracker.
- **Revisión periódica del tracker:** detectar duplicados entre agentes, verificar en vivo todo issue marcado resuelto antes de cerrarlo, reabrir cierres falsos. Mantener el tracker honesto.
- **Verificar contra la fuente antes de publicar:** NINGÚN artefacto de salida (checkpoint, cifra/orden a Juan, spec, handoff) sin verificar esa afirmación concreta contra la fuente autoritativa — el **doc de entrega** del ejecutor (no solo su código), el runbook, el grafo real. Nunca de memoria ni de segunda mano — **y un hecho MEDIDO por un ejecutor, con su tabla de evidencia, sigue siendo segunda mano**: si dictamino o escalo encima, lo mido yo.
- **Toda afirmación de ausencia lleva el ámbito donde se buscó:** «no existe», «no aparece», «no hay ninguno» **no valen sin decir dónde se miró** — qué ruta, qué refs, qué fichero, qué rango. Un «no existe» sin ámbito no lo puede refutar nadie, y por eso sobrevive. Vale igual para la búsqueda estrecha (falso negativo) y para la cita amplia (falso positivo): las dos se sienten igual de concluyentes desde dentro.
- **Una retractación solo existe si se escribe en el mismo canal que el error:** corregirse en conversación o en memoria no alcanza a quien ya actúa sobre el fichero publicado. Mientras el original siga sin marca, es la verdad operativa. Marcar el original y publicar la corrección **en su canal**, el mismo día.
- **Tablero "Dual Rollout — STG": RETIRADO (Alberto 9 ago).** No se actualiza ni se republica. El artifact existente queda como foto histórica. Estado del día → `#132` y los docs de iniciativa.
- **Gitflow en TODOS los repos, no solo en el de Juan (14 ago):** el código se desarrolla en `feature/…`, `fix/…` o `docs/…` (kebab-case) **sacadas de `stg`**, y entra a `stg` **por merge**, nunca por commit directo. `main` describe lo que corre en PROD y solo se toca por promoción desde `stg`. Commits pequeños y revisables, árbol limpio, SHA publicado, y gates verdes **antes** de integrar. Aplica a `Agente-n8n`, `Dashboard_seguroautoqualitas`, `Agente-Arquitecto` y `HYL-WAI`. **Única excepción, y es de canal no de código:** `handoffs/`, `dudas/` e `informes/` van directos a `main` porque ahí los vigilan los monitores de los ejecutores — mover eso rompería la comunicación, no la mejora.
- **El trabajo para un repo nuestro vive en una rama nuestra (13 ago):** si un colaborador externo sin escritura produce código para nuestros repos, se trae al upstream **el mismo día**, a una rama nuestra. Un fork ajeno no es almacén válido: no lo vemos ni entra en nuestros respaldos.
- **Nunca `checkout` en un clon que otra sesión pueda estar usando (16 ago):** quien necesite otra rama monta un **`git worktree`** y lo retira al acabar (`prune` si quedó huérfano). Avisar solo protege si ambos miran a la vez; el worktree siempre.
- **Respaldos/housekeeping de ejecutores: rama propia SIEMPRE** (`backup/…` o `docs/…`), nunca la rama en la que esté parado el clon; ramas congeladas/candidatas de una revisión Contract-First no se mueven aunque el push esté autorizado — la autorización de contenido no es autorización de destino. Instaurada por handoff en n8n y Dashboard (4 ago).
- **Cambiar una convención = actualizar su herramienta en el acto:** si cambia dónde/cómo entregan los ejecutores, actualizar de inmediato el monitor/tooling que lo vigila. Un canal nuevo sin monitor es un punto ciego.
- **Publicar no es ordenar (9 ago, vigente):** un documento publicado es **contenido**; la orden es que alguien con autoridad lo lance, y esa autoridad es Alberto. Él me encarga, yo publico el handoff y lo lanzo — y el ejecutor verifica el fichero antes de tocar nada, porque **la orden es el fichero, no el mensaje que lo anuncia**.
- **Manual de migración a STG — documento VIVO (Alberto 8 ago):** `docs/architecture/manual-migracion-stg-aprendizajes.md` se alimenta con cada aprendizaje útil **hasta que S1 cierre en STG** (trampa técnica, error de método, práctica que evitó daño) — en el momento, no al final. Antes de planificar otra migración, responder **en vivo** su tabla de reconocimiento de entorno §1 **antes de congelar contrato**.

> **Disciplina de CLAUDE.md:** este archivo se carga completo en cada turno — tamaño máximo **30 KB**
> (Alberto, 16 ago; 23 KB desde el 14 jul, 15 KB desde el 29 jun). **El techo sube para acomodar
> REGLA OPERATIVA, nunca estado, cronología ni narrativa**: si lo que aprieta es eso, la respuesta es
> higiene, no más techo. Y el techo no decide por mí — comprimir una convención existente para meter
> otra, eligiendo por cuál se recorta más rápido, es peor que pasarse de largo un día.
> Procedimiento, test de imprescindibilidad y registro: `docs/protocolos/higiene-claude-md.md`. Aquí solo hechos estables y reglas operativas: sin cronologías ni ítems resueltos. Estado de bugs → `qualitas-issues`; estado de iniciativas → su doc + tablero artifact (aquí solo puntero); convención nueva entra SIN narrativa (la historia va a `docs/architecture/convenciones-origen.md`); lo resuelto → `docs/architecture/pendientes-resueltos-historial.md`. Verificar `wc -c CLAUDE.md` tras cada edición.
