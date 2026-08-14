# HYL-WAI #156 — Módulo de Descuentos + Conversation Control · **lado nuestro**

**Abierto:** 11 ago 2026 · **Estado:** en ejecución, desarrollo offline en ramas paralelas.
**Tracker canónico:** `aguayo-co/HYL-WAI#156`. **Autoridad contractual:** `oilycoyote` (lado Juan).
**Decisión de Alberto (11 ago):** no se promueve nada a PROD ahora. Se desarrolla en paralelo, se
mergea a STG, se prueba en STG, y al final sube **STG entero** a PROD. El plan del 10 ago
(`2026-08-10-plan-promocion-stg-a-prod-cross.md`) queda **aparcado, no descartado**.

---

## 1. Qué nos han pasado

Juan congeló **dos** contratos y terminó su lado (Django PR-ready, sin mergear). El último comentario
de #156 (11 ago, 22:38) pasa la responsabilidad de **n8n y Dashboard** a Alberto.

| Contrato | Estado | SHA-256 | Qué gobierna |
|---|---|---|---|
| `DISCOUNTS-CORE v0.5.0` | CONGELADO | `827ba636…64a8ca54` | Recotizar con descuento sin duplicar efectos ni cruzar conversaciones |
| `CONVERSATION-CONTROL v1.0.0` | FROZEN | `bccbf44a…ad807471` | Quién manda en una conversación (humano vs IA), con qué evidencia |
| `discounts-django-producer-v0.5.0` | perfil Django | `f2dda289…dace02b4df` | Superficie API, estados, read models |

Ruta: `aguayo-co/HYL-WAI@feature/issue-156-discounts-django-v0.5:docs/contracts/`.
Entrega Django: commit `afaaab33edee` — módulo, fases, triggers y programas **OFF**.
**Verificado por el Arquitecto el 11 ago:** los tres fingerprints coinciden byte a byte. Los dos
ejecutores los reverificaron por su cuenta antes de escribir código.

**Lectura clave:** el módulo de descuentos es la parte pequeña. **El ~80 % de lo que nos cae es
`CONVERSATION-CONTROL v1`**, que es la formalización congelada y mucho más estricta de lo que ya
construíamos en S1/S2/S3. No depende del mecanismo comercial del descuento.

---

## 2. El negocio, y lo que no está decidido

Hoy toda cotización a Quálitas sale con `<PorcentajeDescuento>20</PorcentajeDescuento>` **hardcodeado**
(`HYL-WAI:qualitas/services.py`, desde `043615e`, 15 ene 2026). El módulo lo convierte en parámetro.

**Definido:** porcentaje absoluto (no acumulativo), congelado en la cotización y reutilizado en
emisión · solo se ofrece **mayor** que el actual · Django recomienda el **más bajo** que supere al
actual · máximo **3 por cadena** (congelado al crear la primera oferta) · Fase 1 dispara en el
checkpoint determinístico `quote_sent:2`, Fase 2 con `intent=PRICE_OBJECTION` · al aceptar: 6 llamadas
Quálitas tipo 2 (`1C,1S,1T,1M,3C,3S`), **un** PDF, lead+cotización nuevos, conversación nueva que
hereda el historial, y entrega por WhatsApp que hace **n8n** · admin en Wagtail `Campañas → Descuentos`.

**NO definido, y son gates de activación por el propio contrato:** el **rango que autoriza Quálitas**,
el **copy** de la oferta, **a quién** se le ofrece (no hay regla de elegibilidad más allá del tope de
3), y **qué cuesta** (sale de la comisión).

### El rango de Quálitas — historia, porque cambió

- **31 jul 2026:** sonda del Agente n8n contra QA y PROD (evidencia cruda en
  `Agente-n8n@docs/descuento-cotizacion-qualitas`): solo se aceptan **0 y 20**; todo lo demás devuelve
  `0007-- Descuento fuera de Rango, rango valido 20 a 20`. Con eso, «solo se ofrece un porcentaje
  mayor» era **insatisfacible**.
- **12 ago 2026:** **Alberto informa de que ya se acepta el 40 %.** El dato de julio queda caducado y
  el bloqueante retirado.
- **Pendiente:** re-medir para saber si el rango es **continuo (20–40)** o **discreto (solo 20 y 40)**.
  No es un matiz: con rango continuo la escalera del contrato tiene tres peldaños reales; con solo dos
  valores, el tope de 3 por cadena sobra y el módulo se reduce a una decisión binaria.
  Sonda lista y autorizada por Alberto; la lanza él (requiere credenciales de Heroku).

> **Pregunta abierta, independiente de #156:** si Quálitas ya acepta 40 y seguimos mandando 20
> hardcodeado, **cada cotización de hoy lleva menos descuento del que podríamos dar**. Subirlo es una
> decisión de margen de Alberto/Hylant, no técnica — pero hoy se está tomando por omisión.

---

## 3. Régimen de trabajo

- Ramas **paralelas propias, sacadas de `origin/stg`** en cada repo. Nada se mergea.
- **Prohibido** por #156: merge/promoción a `stg`, deploy, activación, **migraciones o grants vivos
  incluidos los de STG**, imports en n8n, DDL fuera del ownership, credenciales productivas, llamadas
  reales a Quálitas/Meta.
- **Handoffs y canal `dudas/` REACTIVADOS por Alberto (11 ago) SOLO para este trabajo.** Fuera de #156
  sigue vigente la regla del 10 ago (Alberto instruye directo).
- Los ejecutores **no publican en el tracker de Juan**. Informan al Arquitecto; Alberto decide qué se
  comenta en #156.
- **Ownership:** Dashboard es el único writer de `dashboard_conversation_claims`; n8n el único de
  sesiones, tokens aplicados, reservas de dispatch, evidencia y **DDL versionado de las vistas**;
  Django **SELECT-only**.

### Handoffs publicados

| Repo | Commit | Fichero |
|---|---|---|
| `Agente-n8n` @ `main` | `651c742` | `handoffs/2026-08-11-hyl-wai-156-discounts-conversation-control-n8n.md` |
| `Dashboard_seguroautoqualitas` @ `main` | `bd7a13c` (+ `c46c9cf` corrección E0) | `handoffs/2026-08-11-hyl-wai-156-discounts-conversation-control-dashboard.md` |

---

## 4. Estado por ejecutor (12 ago)

### n8n — rama `feature/issue-156-conversation-control-n8n`

| | Entregable | Estado |
|---|---|---|
| E1 | Inventario de conectores WhatsApp | **hecho** |
| E2 | DDL aditivo sesiones + archive | **hecho** — 26/26 en PostgreSQL 17 efímero |
| E3 | Vista `conversation_control_v1` | en curso |
| E4 | Vistas de evidencia (activación + herencia) | pendiente |
| E5 | Fence de outbound | pendiente |
| E6 | Cutover y herencia de historial | pendiente |
| E7 | Reportes a Django | pendiente |

**Hallazgo E1 — el grande:** 20 puntos de contacto con Meta, **18 envían**, y **10 no pueden acreditar
la sesión exacta al enviar** — 5 patrones repetidos en STG y PROD, no 10 problemas. Incluye
`Send Quote Document` (por donde saldría el PDF del descuento) y el `Send message` de **Payment
Confirmation**, en los dos entornos. Son los candidatos a **excepción nominal aprobada en #156**, y
están nombrados uno a uno en `docs/156/inventario-conectores-whatsapp.md`. **Pendiente: llevarlos a
Juan.**

**Hallazgo E2 — GAP-B:** `whatsapp_sessions_archive` tiene los **tokens** de fencing pero no las
**banderas** que esos tokens fencean (`human_takeover`, `metepec_derived`): se crearon en deploys
anteriores que no tocaron el archive. Consecuencia hoy: **archivar una sesión pierde su estado de
control**. No rompe nada vivo (el archive nunca produce fila en la vista) pero destruye la auditoría.

**GAP-A:** `lead_id`/`quotation_id` son `integer`, no `bigint`, en las dos tablas. Ensanchar reescribe
la tabla bajo `ACCESS EXCLUSIVE` — pero son **1083 filas en PROD**, así que es instantáneo. Anotado
para la ventana: **retirar uno de los dos índices redundantes sobre `quotation_id`**.

### Dashboard — rama `feature/issue-156-conversation-control-dashboard`

| | Entregable | Estado |
|---|---|---|
| E0 | Replantar `MetepecView.js` | **retirado** — no había trabajo (error del Arquitecto) |
| E1 | Resolver live-only | **hecho** — resolver + costura asíncrona de sustitución |
| E2 | Claims con epoch anti-ABA | **hecho** — 31 gates en PostgreSQL efímero |
| E3 | Cable Dashboard → n8n | pendiente |
| E4 | UI y autorización por la vista | **parcial** — autorización hecha, UI sin tocar |
| E5 | Consumir read models de Django | pendiente |

Suite 120/120 (partía de 89). Entrega en `docs/156/entrega-dashboard.md`.

---

## 5. Decisiones tomadas por el Arquitecto (registro)

1. **E1 del Dashboard se entrega sin cablear**, con **una costura única de sustitución** en
   `lib/s1/controlResolver.js` — no un modo de runtime: en ejecución hay siempre un solo resolver.
   La costura **nace asíncrona** para que la sustitución sea de verdad una línea y no arrastre una
   conversión sync→async por la cadena de dispatch el día de la coordinación.
2. **Prohibido alinear el `400` de `retomarBuilder.js` a `404`.** Es wire acreditado por Juan en
   S1 v1.1 y el contrato exige volver a #156 antes de tocar wire. **Declarado, no corregido**
   (`retomarBuilder.js:14`, `conversation.js:14`). **Pendiente: levantarlo con Juan.**
3. **Selector de sesión ausente ⇒ `400 invalid_request`**, no `conversation_not_found`. Los tres
   códigos de la vista describen lo que la vista contestó; un selector ausente nunca consultó nada.
4. **«Contiene exactamente los tres tokens» = lectura permisiva** (nombres y tipos), no prohibitiva.
   La prohibitiva es autocontradictoria: la misma cláusula publica `metepec_derived`, `is_banned`,
   `status`, `phase` y `closed_at` desde esa tabla. Cerrada como aclaración no material, **con
   obligación de declarar la lectura** en la entrega.
   **Y lo que la palabra sí hace:** prohíbe una **cuarta fuente de control aplicado**. En E3, los tres
   `applied_*` salen solo de esas columnas — sin `COALESCE` con espejo, sin derivar la bandera de que
   el `control_id` no sea nulo. Un trío incompleto **es** `applied_token_partial`.
5. **E0 retirado.** `MetepecView.js` es idéntico en las dos puntas. El error fue medir con
   `git diff stg...main` (tres puntos, desde la base común) en vez de dos puntos.
   **Consecuencia buena verificada: la promoción final de `stg` → PROD no pierde nada de `main`.**

---

## 6. Pendientes vivos

| # | Qué | De quién |
|---|---|---|
| 1 | **Lanzar la sonda del rango** de descuento (continuo vs discreto) | Alberto |
| 2 | Decidir si el **20 por defecto** se mueve, ahora que se acepta 40 | Alberto / Hylant |
| 3 | ~~Llevar a #156 los 10 conectores sin sesión~~ → **hecho 12 ago**, `#156` comentario `5272121781`. Esperando dictamen de Juan | Juan |
| 4 | ~~Llevar a #156 la divergencia de wire 400 vs 404~~ → **hecho 12 ago**, mismo comentario. Esperando dictamen de Juan | Juan |
| 5 | **Brecha de roles Postgres** (mono-rol) — gate de rollout declarado por los dos ejecutores | pendiente de decisión |
| 6 | Autorizar el **merge a `stg`**: no es nuestro, lo da el checkpoint de #156 tras PR-ready | Juan |
| 7 | **Métricas de adquisición**: el funnel actual contará cada recotización como lead nuevo (hasta 3×) el día que Discounts se active. E5 se construye como superficie nueva **sin tocar** `lib/metrics.js` ni `FunnelV2.js`; el Dashboard entrega el desfase cuantificado (fichero:línea + factor) y hay que **decidirlo con Hylant**, no heredarlo | Alberto / Hylant |
| 8 | **Estado de `dashboard_conversation_claims` en PROD sin verificar**: `readonly_leads` no puede leerla (10 ago). En STG ya está acreditado (ver §8) | pendiente de otro rol |

---

## 7. Riesgos que no hay que perder de vista

- **El fence de outbound universal (E5 de n8n) toca todo lo que hoy envía WhatsApp** — Main, quick
  reply, Payment, Retomar. No es un módulo nuevo: es refactorizar el transporte de lo que funciona.
- **Gotcha de memoria y cutover:** el nodo de memoria escribe el turno con el `session_id` resuelto al
  **inicio** del turno. El cutover cambia de sesión a mitad de conversación, así que el turno en que el
  cliente acepta el descuento se guardaría en la sesión que se acaba de cerrar. Hay que diseñarlo a
  propósito.
- **Solapamiento con la multicotización** ya desplegada en STG (`Cambiar Cotizacion`,
  `Listar Cotizaciones`): dos mecanismos que mueven al cliente entre cotizaciones del mismo teléfono.
- **El precio respondido de memoria**: con historial heredado, el bot podría cantar el precio viejo
  justo cuando el cliente decide. Ordenado cerrar el 10 ago; verificar que quedó cerrado.
- **La adquisición se cuenta por `root`**: si Dashboard o GA4 cuentan cada recotización como lead
  nuevo, los números se inflan hasta 3×.

---

## 8. Estado acreditado de `dashboard_conversation_claims` en STG (12 ago)

Leído por el Arquitecto vía `pg_catalog` en `hyl-wai-stg` (solo catálogo, cero filas de datos). Se usa
`pg_catalog` y no `information_schema` a propósito: con rol readonly, `information_schema` filtra por
privilegios y «no existe» se confunde con «existe sin grants».

Columnas: `id` int PK · `lead_id` **integer** NOT NULL · `session_id` varchar(255) NOT NULL ·
`agent_id` int NOT NULL FK→`dashboard_users(id)` · `claimed_at` timestamptz NOT NULL · `released_at`
timestamptz · `control_id` uuid NOT NULL · `conversation_id` **varchar(64)** · `quotation_id`
**integer** · `epoch` integer NOT NULL · `state` text NOT NULL · `lease_expires_at` timestamptz.

Constraints: `ck_claims_state` CHECK ∈ {active, released, revoked, expired} · PK(`id`) ·
`uq_claims_control_id` UNIQUE(`control_id`).
Índices: PK · `uq_claims_active_lead` UNIQUE(`lead_id`) WHERE active · `uq_claims_active_session`
UNIQUE(`session_id`) WHERE active · `uq_claims_control_id`.

**Cinco gaps contra el contrato:** `conversation_id` 64 < 80 · `lead_id` integer ≠ bigint ·
`quotation_id` integer ≠ bigint · **falta `CHECK(epoch>0)`** · **falta `UNIQUE(session_id, epoch)`**.

> El que más lejos llega es `UNIQUE(session_id, epoch)`: no es solo el invariante anti-ABA, es **el
> índice del que depende la vista de n8n** para resolver `authority_epoch` por backward scan sin
> `GROUP BY` global. Sin él, la cláusula de eficiencia del contrato no se cumple aunque la vista esté
> bien escrita.

**`uq_claims_active_lead` EXISTE** → se conserva, declarado en la migración como política de
producto/UI y nunca autoridad conversacional (cláusula del contrato).

**PROD no está verificado** y puede diferir: `readonly_leads` no puede leer esta tabla. Por eso la
migración del Dashboard se mantiene **aditiva e idempotente**, acreditada partiendo de una tabla
deliberadamente deficiente — decisión correcta que este hallazgo confirma.

---

## 9. Subida a STG — estado real y orden (13 ago, pedido por Alberto)

**La condición que yo mismo puse ya está cumplida.** Mi comentario en #156 de hoy decía que el merge a
`stg` esperaba a que terminara la promoción STG→PROD; esa promoción está cerrada (acta `50029b1`). El
orden ya no bloquea.

**Lo que sí bloquea: esto no es un merge, son cuatro promociones en tres repos más una ventana de DDL,
y hoy ninguna de las cuatro está en condiciones de salir.** Medido contra las ramas remotas, 13 ago.

| # | Gate | Estado medido | De quién |
|---|---|---|---|
| G1 | **Autorización del merge a `stg`** | El comentario v0.6 de Juan asigna la tarea a Alberto («preparar la promoción coordinada… ejecutar la matriz E2E») y **en el mismo texto** lista «merge a `stg`» entre las *acciones todavía no autorizadas*. Contradicción literal: hace falta un GO explícito | Juan |
| G2 | **Django no está en `stg`** | `feature/issue-156-discounts-admin-adjustments-v0.6` = `e7b97e7`, **sin PR abierto** y **no mergeada** a `origin/stg` de HYL-WAI. Sin Django no hay read models, ni checkpoint, ni E2E | Juan |
| G3 | **El descuento de n8n no está en nuestro repo** | `aibanez82/Agente-n8n@feature/…-n8n` = `383f6c2` (solo Conversation Control, E1–E7). El módulo vive **solo en el fork** `oilycoyote/Agente-n8n` = `d3a6387`: **30 commits, 57 ficheros, +16.494/−881** por encima de nuestra punta — `main-candidato.json` (3.153 líneas tocadas), `discount-application-worker-candidato.json` nuevo (2.197), 14 nodos `discount-*.njs`, y toca `retomar-normalize-validate.njs` y `wire.js`. **Fast-forward limpio**: contiene nuestro trabajo entero y no tenemos nada fuera. En `workflows/` solo toca los **tres candidatos** (`A` worker, `M` main, `M` retomar) — **no borra ni mueve ningún baseline `_stg`**. **La autoría git no acredita**: 25 de los 30 commits llevan `aibanez82 <a.ibanez@gmail.com>` como autor *y* committer (el agente de Juan trabajó con la config git de Alberto) y solo 5 llevan `Pi Coding Agent`. La revisión es por contenido, no por firma | Arquitecto + Agente n8n |
| G4 | **Conflicto real en el Dashboard** | `git merge-tree stg ↔ rama156` da **CONFLICT en `apps/operacion/pages/api/claim.js`**, que es justo el fichero que la Fase 4 de Atención Humana acaba de promover a PROD. La rama 156 no lleva los 4 commits de Fase 4 ni `next 14.2.35` (que existe **solo en `main`**: `stg` y la rama siguen en `14.2.3`, o sea el gate de dependencias de Juan sigue abierto en la línea `stg`) | Dashboard |
| G5 | **La rama 156 del Dashboard toca `FunnelV2.js` y `lib/metrics.js`** | +23/−… y +48/−… frente a `stg`, dentro de los 4 commits de Pi Coding Agent posteriores a la entrega (`060e858` → `997c34b`). Es la superficie que mira Hylant y el **pendiente 7** la excluía expresamente de esta rama. Mergear tal cual mete en STG un cambio de conteo que nadie ha decidido | Alberto / Hylant |
| G6 | **DDL vivo en STG** | 5 migraciones n8n (`001`–`005`) + `2026-08-11-claims-epoch-anti-aba.sql`. Es una ventana con guardas, no un merge; y arrastra la **brecha de roles Postgres** (pendiente 5), declarada gate de rollout por los dos ejecutores | ventana |
| G7 | **Sin dictamen de Juan** | Los 10 conectores sin sesión (el fence cubre **8 de 18**) y la divergencia de wire 400 vs 404. Reclamados hoy en #156 | Juan |

### El riesgo que no hay que perder de vista

El conflicto de G4 es sobre `claim.js`, es decir sobre **«Tomar conversación»**, que llevaba roto desde
el 28 de julio y se acaba de arreglar en producción. Dimensionado: la rama 156 mueve **+411/−82** sobre
ese fichero y la Fase 4 **+86/−4**. Resolver no es elegir un lado: es **re-aplicar las tres llamadas de
Atención Humana sobre el `claim.js` nuevo**.

---

## 10. Decisión de Alberto (13 ago) y plan de ejecución

**Alberto tiene el GO de Juan por escrito** → G1 cerrado. **Instrucción: a STG con todo, sin dejarse
nada; lo que se rompa en STG se arregla en STG.** Consecuencias registradas:

- **G5 cerrado por decisión de Alberto:** `FunnelV2.js` y `lib/metrics.js` **entran**. Queda dicho que
  a partir del merge los números del funnel **en STG** se cuentan por root y no por lead, así que STG
  deja de ser comparable con PROD en esa superficie. Es reversible y es STG. La decisión para PROD
  sigue siendo de Hylant y **no** se hereda de este merge.
- **Objeción retirada:** planteé que romper STG nos deja sin entorno de referencia para acreditar
  futuras promociones. Alberto lo reafirma: es un entorno de pruebas. Adelante.

### Inventario — qué es «todo» (no dejarse nada)

| Repo | Rama | SHA | Contenido |
|---|---|---|---|
| HYL-WAI | `feature/issue-156-discounts-admin-adjustments-v0.6` | `e7b97e7` | Django v0.6 — **lo mergea Juan** |
| HYL-WAI | `feature/issue-156-discounts-django-v0.5` | — | v0.5, superseded por v0.6. **No se promueve**; se conserva por los contratos congelados en `docs/contracts/` |
| Agente-n8n (fork) | `feature/issue-156-conversation-control-n8n` | `d3a6387` | Conversation Control **+ módulo de descuentos**: 11 migraciones (`001`–`011`), 3 candidatos de workflow + worker nuevo, 14 nodos `discount-*.njs`, `matriz-integracion-descuentos-v06.md`, `runbook-veredicto-final-v06.md` |
| Agente-n8n | `feature/issue-156-descuentos-n8n` | `cce595d` | **Solo un doc de plan** (203 líneas) y **no está contenido en el fork** — si no se trae a mano, se pierde |
| Dashboard | `feature/issue-156-conversation-control-dashboard` | `997c34b` | E1–E5 + los 4 commits de Pi Coding Agent (incluye `FunnelV2`/`metrics`) |

### Orden de ejecución

1. **n8n — reconciliar el fork.** Traer `d3a6387` al upstream (fast-forward, no hay nada nuestro
   fuera), revisar los 30 commits **por contenido**, incorporar el doc de plan de
   `feature/issue-156-descuentos-n8n`, y merge a `stg`. Sin tocar la instancia.
2. **Dashboard.** Merge de `stg` en la rama, resolver `claim.js` re-aplicando Atención Humana, subir
   `next` a `14.2.35` en la línea `stg` (hoy solo está en `main`), merge a `stg` y deploy STG.
3. **Django (Juan).** PR de `e7b97e7` → `stg` y despliegue en `hyl-wai-stg`. Es el productor: sin él
   los read models no existen y la E2E no puede pasar de la mitad. **Va el último por decisión de
   Alberto (13 ago):** sus despliegues en Heroku tardan ~5 min, así que ponerlo primero convertiría a
   Juan en bloqueo de dos merges nuestros a cambio de nada. Los pasos 1 y 2 son **paralelos entre sí**
   —repos y superficies distintas— y ninguno de los dos necesita Django hasta el paso 6.
4. **Ventana de DDL en STG.** `001`–`011` de n8n + `2026-08-11-claims-epoch-anti-aba.sql` del
   Dashboard, en orden, idempotentes y con guardas. La **brecha de roles** (pendiente 5) se declara,
   no se resuelve: en STG se aplica con el rol que haya.
5. **Import en la instancia n8n STG con todo OFF.** Los tres candidatos + el worker. Antes de
   importar, **diff del candidato contra el workflow vivo**, porque el baseline exportado es del
   10 ago (`b98f568`) y desde entonces STG ha recibido promociones.
6. **E2E sintética** — matriz 8/8 de la entrega de Juan más los casos de descuento del runbook v0.6.

---

## 11. Pasos 1 y 2 cerrados (13 ago) — y lo que la ejecución descubrió

**Los dos repos nuestros están en `stg`.** n8n `89dec79`, Dashboard `44d889d`. Verificado por el
Arquitecto contra los criterios de cada handoff, no contra el informe: en n8n los baselines `_stg`
intactos y `workflows/` con solo los tres candidatos (`A`/`M`/`M`), 11 migraciones presentes y
ninguna ejecutada; en Dashboard `next` en `14.2.35`, Fase 4 dentro y `claim.js` conservando las tres
operaciones de Atención Humana.

### Dos defectos que justifican por sí solos haber pasado por STG

Ninguno es regresión del merge: los dos venían **dentro de la entrega v0.6**, y los dos estaban
tapados por tests en verde.

1. **El `/webhook/` perdido** (`lib/s1/n8nOperatorWebhook.js`). El código de #156 daba por hecho que
   `N8N_OPERATOR_WEBHOOK_BASE_URL` trae el `/webhook`; la variable real en STG y PROD es **solo el
   host** — el segmento lo pone el cliente. Las tres llamadas de Atención Humana habrían salido a
   `…/atencion-humana-iniciar`: **404**. El test no lo veía porque asertaba **por sufijo**, que es
   justo la aserción ciega a la pérdida de un segmento intermedio. Habría estrenado en producción un
   fallo silencioso sobre lo que se arregló el 12 ago.
2. **`continuation.test.js` atado a una máquina.** Traía `DJANGO_REPO = '/home/oilycoyote/projects/…'`
   y **reventaba al requerirse**, así que node lo contaba como *1 test que falla* en vez de los *14*
   que son: **la matriz que acredita el contrato Django↔Dashboard v0.6 nunca corrió fuera de esa
   máquina**. Además su gate comparaba `rev-parse HEAD === DJANGO_SHA`, que no acredita el pin sino
   dónde tiene el HEAD quien ejecuta. Suite real: **212/212** (198 antes).

### Los cinco hallazgos de n8n, decididos

| # | Hallazgo | Decisión del Arquitecto |
|---|---|---|
| 1 | El validador nuevo de Retomar exige 11 claves y el Django **desplegado** manda 10 (`e7b97e7` las emite; `main` no). Importar contra el Django actual rechaza **el carril entero** con `missing_checkpoint_followup` | **Dependencia dura, no secuencia cómoda.** Django v0.6 desplegado en el entorno **antes** de importar. Y queda escrito para el futuro: `retomar-candidato` **no puede ir a PROD sin Django v0.6** — allí Retomar está activo desde el 11 ago |
| 2 | El worker nuevo incrusta el `phone_number_id` de STG en dos URLs, sin nodo `WA Config STG` | **Se corrige antes del import.** El procedimiento de rotación documentado edita ese nodo en 3 workflows; un cuarto sin él se salta la rotación **en silencio**, y el modo de fallo es el Bug #15 (envíos cruzados de entorno). Barato ahora, caro después |
| 3 | `Check Idempotency` pasa a llamar `n8n_checkpoint_outbound_claim()`, que **crea la migración `006`** y hoy no existe en ninguna base | **Confirmada como dependencia dura**: ventana de DDL (paso 4) antes del import (paso 5) |
| 4 | La respuesta de Retomar cambia de forma: `success` podía ser solo `true` y ahora puede ser **`false`** | **Superficie contractual — va a Juan antes del import.** Nadie ha declarado qué hace Django ante `success: false`: si reintenta, un rechazo persistente se vuelve **bucle de reintentos** |
| 5 | El worker trae `scheduleTrigger` de **1 minuto**: activarlo consulta Django, escribe en Postgres y **envía PDFs por WhatsApp** | Import con `active: false`; **activar es una decisión explícita**, nunca efecto lateral del import |

**`.pi-web/`** (contabilidad interna del relay del agente de Juan, 4 ficheros): cosmético, sin
secretos, expone la disposición de su máquina. Decide Alberto. Recomendación: **dejarlo** — es
registro de cómo se construyó esto.

**Anotado sin bloquear:** `lib/wire.js` valida `body.timestamp` crudo y el nodo `.njs` valida el ya
normalizado, así que con `timestamp: ""` el oráculo y el nodo **discrepan**. El Django real no produce
ese caso; los dos ficheros están para decir lo mismo y aquí no lo dicen.

### Paso 3 (Django) — a medias, y la lección de ayer repetida

Juan promovió **la rama**: `origin/stg` de HYL-WAI = `e7b97e7`, fast-forward, `main` intacto. Pero su
propio comentario dice «no se ejecutaron migraciones vivas, **deploy**, activación», y el entorno lo
confirma: **`hyl-wai-stg` corre `df05f0ad`, release v220 del 10 ago** — el `stg` anterior.

Es, literal, la lección del acta del 13 ago: **una promoción se acredita contra el entorno de destino,
no contra su artefacto.** Repetida a las 24 horas, en el otro sentido y por el otro lado. Esta vez
detectada antes de romper nada, porque el hallazgo 1 obligaba a mirar el entorno y no la rama.

**Confirmado contra la fuente por el Arquitecto:** `build_n8n_payload` en `origin/stg` emite las 11
claves con `checkpoint_followup` (`whatsapp_checkpoint_followups.py`); lo desplegado emite 10. La
lectura del Agente n8n era correcta. **El import sigue bloqueado hasta el deploy.**

**Gates relajados, revisados y aceptados:** la prohibición «ningún nodo nuevo toca base/red/conector»
del `§13` pasa a **lista cerrada enumerada** (22 nodos en Main, 5 en Retomar) — inevitable, porque el
objeto de #156 es añadir nodos con efecto, y una lista enumerada es la forma correcta; el gate de
credenciales sigue impidiendo introducir credenciales nuevas. Queda dicho que **ampliar esa lista sin
declararlo deja el gate sin proteger nada**.
