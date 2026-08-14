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
| G3 | **El descuento de n8n no está en nuestro repo** | `aibanez82/Agente-n8n@feature/…-n8n` = `383f6c2` (solo Conversation Control, E1–E7). El módulo vive **solo en el fork** `oilycoyote/Agente-n8n` = `d3a6387`: **365 commits y +16.494 líneas** por encima de nuestra punta — `main-candidato.json` (+3.153), `discount-application-worker-candidato.json`, 14 nodos `discount-*.njs`, y toca `retomar-normalize-validate.njs` y `wire.js`. El fork **sí contiene** nuestro trabajo (fast-forward posible). **La autoría git no acredita nada**: los 365 commits llevan `a.ibanez@gmail.com` como autor *y* committer, así que la revisión tiene que ser por contenido | Arquitecto + Agente n8n |
| G4 | **Conflicto real en el Dashboard** | `git merge-tree stg ↔ rama156` da **CONFLICT en `apps/operacion/pages/api/claim.js`**, que es justo el fichero que la Fase 4 de Atención Humana acaba de promover a PROD. La rama 156 no lleva los 4 commits de Fase 4 ni `next 14.2.35` (que existe **solo en `main`**: `stg` y la rama siguen en `14.2.3`, o sea el gate de dependencias de Juan sigue abierto en la línea `stg`) | Dashboard |
| G5 | **La rama 156 del Dashboard toca `FunnelV2.js` y `lib/metrics.js`** | +23/−… y +48/−… frente a `stg`, dentro de los 4 commits de Pi Coding Agent posteriores a la entrega (`060e858` → `997c34b`). Es la superficie que mira Hylant y el **pendiente 7** la excluía expresamente de esta rama. Mergear tal cual mete en STG un cambio de conteo que nadie ha decidido | Alberto / Hylant |
| G6 | **DDL vivo en STG** | 5 migraciones n8n (`001`–`005`) + `2026-08-11-claims-epoch-anti-aba.sql`. Es una ventana con guardas, no un merge; y arrastra la **brecha de roles Postgres** (pendiente 5), declarada gate de rollout por los dos ejecutores | ventana |
| G7 | **Sin dictamen de Juan** | Los 10 conectores sin sesión (el fence cubre **8 de 18**) y la divergencia de wire 400 vs 404. Reclamados hoy en #156 | Juan |

### Orden obligado

1. **G1 + G2 juntos** — un comentario en #156 pidiendo el GO y el PR de Django a `stg`. Django primero: es el productor.
2. **n8n** — traer `d3a6387` del fork a una **rama de integración** en el upstream, revisar por contenido, y solo entonces merge a `stg`. **Sin importar workflows en la instancia STG.**
3. **Dashboard** — merge de `stg` en la rama 156, resolver `claim.js` **contra el código de Atención Humana que ya corre en PROD**, subir `next` a `14.2.35` en la línea `stg`, y decidir G5 antes de mergear.
4. **Ventana de DDL en STG** (G6), idempotente y con guardas.
5. **Import de workflows en STG con todo OFF** y matriz E2E sintética.

### El riesgo que no hay que perder de vista

El conflicto de G4 es sobre `claim.js`, es decir sobre **«Tomar conversación»**, que llevaba roto desde
el 28 de julio y se acaba de arreglar en producción. Una resolución de conflicto descuidada en STG es la
forma más barata que tenemos hoy de volver a romperlo.
