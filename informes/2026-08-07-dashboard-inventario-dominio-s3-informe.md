# Informe — inventario del dominio Dashboard para S3 · DOCS-ONLY

**Fecha:** 2026-08-07 · **De:** Agente Dashboard → Arquitecto
**Handoff:** `Dashboard_SeguroAuto:handoffs/2026-08-07-inventario-dominio-dashboard-s3.md` (`ac7d0a7`)
**Árbol leído:** `c911d4c` (candidato S1 acreditado, punta de `stg`), en worktree detached.

## 0. Método y límites (léase antes que los veredictos)

- Worktree detached sobre `c911d4c` en `/private/tmp/.../scratchpad/wt-c911d4c`. **El clon nunca
  cambió de rama**: siguió y sigue en `c1-gates-api-default-deny`, sin cambios sin commitear.
- **Cero accesos a base de datos**, ni siquiera read-only. Todos los veredictos salen de leer
  ficheros del árbol congelado.
- **Nada vivo tocado**: no se movió `stg`, no se tocó `S1_DASHBOARD_MODE` ni configuración de
  Vercel, no se purgó ningún deployment, no se abrió/cerró/actualizó ningún PR. PR #2 sigue
  abierto y parqueado.
- Sí se ejecutaron **lecturas** de la API de Vercel (`vercel ls`, `vercel inspect`) y de GitHub
  (`gh issue view`), y `curl` sin credenciales contra URLs públicas — el §2 del handoff pedía
  expresamente inventariar deployments con fecha y aliases, y eso no se puede hacer sin leer.
- **Frontera reproducido/inferido**: cada afirmación de §1–§3 está anclada a `fichero:línea` y la
  reprodujé yo. Lo inferido va marcado explícitamente como tal en §5.

---

## 1. Los tres huecos de `s3-prep-offline.md` §3

### 1.1 UI de "Soltar a IA" e indicador "tomada por X" → **✔ el indicador · ✘ el "soltar a IA"**

Hay que separarlos, porque el veredicto es distinto para cada uno.

**Indicador "tomada por X" — ✔ EXISTE, en tres superficies:**

| Superficie | Ancla | Qué muestra exactamente |
|---|---|---|
| Chip en la lista de la bandeja | `apps/operacion/components/InboxView.js:146-155` | `Libre` (gris) si no hay claim; `👤 Tú` (verde `#EFF7E5`) si `l.claim_agent_id === me.id`; `👤 {claim_agent_name}` (gris) si es de otro |
| Badge del header de la conversación | `apps/operacion/components/ConversationWorkspace.js:217-224` | `👤 Tomada por {lead.claim_agent_name}` — **solo cuando es de OTRO agente** (`deOtro`, def. en `:46`) |
| Aviso sobre el composer | `apps/operacion/components/ConversationWorkspace.js:233-237` | "Esta conversación la está trabajando **{claim_agent_name}** — solo puedes verla" |

El dato viene de `apps/operacion/pages/api/inbox.js:44-46` (`cl.control_id`, `cl.epoch`,
`u.id AS claim_agent_id`, `u.display_name AS claim_agent_name`).

**"Soltar a IA" — ✘ NO existe como tal.** Lo que existe es un botón **"Liberar conversación"**
(`ConversationWorkspace.js:193-204`) que llama a `handleRelease` (`:160-176`) →
`DELETE /api/claim` con `{control_id, epoch}`. Y ahí acaba: `apps/operacion/pages/api/claim.js:72-77`
hace **un solo `UPDATE` sobre `dashboard_conversation_claims`** y nada más. No hay llamada a n8n,
no hay escritura del espejo, no hay ninguna señal saliente.

Verificación negativa: `grep` de `human_takeover|sent_by|human_agent` sobre `apps/`, `packages/`,
`migrations/`, `scripts/` en `c911d4c` → **0 coincidencias**.

> **Consecuencia para el contrato:** hoy "liberar" es una operación *interna* del Dashboard. La IA
> nunca supo que estaba silenciada (issue #57), así que soltarla no la reactiva — no hay nada que
> reactivar. El botón cumple el 100% de su semántica actual y el 0% de la semántica S3.

**Una anomalía menor, para que no sorprenda luego:** `apps/operacion/components/ConversationModal.js:115-131`
tiene un botón etiquetado `📲 Tomar conversación` que **no toma nada** — solo navega
(`router.push('/?tab=inbox&lead=…')`). Es un enlace a la bandeja con etiqueta de acción. Inocuo hoy
(no llama a `/api/claim`), pero si S3 fija "tomar" como acción contractual conviene renombrarlo.

### 1.2 `sent_by: human_agent` en el camino proactivo → **✘ NO existe**

`apps/operacion/pages/api/n8n-proactive-message.js` tiene dos caminos y **ninguno de los dos marca
el emisor**:

- **Camino PROD legacy** (`:120-167`): el payload es exactamente
  `{ phone_number, message, session_id }` (`:154`).
- **Camino S1** (`:71-117`): el payload lo construye `buildRetomarWire`
  (`apps/operacion/lib/s1/retomarBuilder.js:51-61`) y son **8 campos exactos**:
  `phone_number, session_id, conversation_id, identity_mode, message, timestamp, lead_id, cotizacion_id`.

**Dónde se marcaría.** El punto natural es `retomarBuilder.js:51-61` (un campo más en el objeto
`wire`), porque es el único constructor del payload S1 y ya recibe todo el contexto. El `agent`
autenticado existe aguas arriba (`n8n-proactive-message.js:50`) pero **hoy no se le pasa al
builder** (`:85` pasa solo `leadId, cotizacionId, message, candidates, now`), así que hay que
ampliar la firma. Para el camino legacy sería `:154`, pero ver la advertencia de abajo.

**Recorrido del payload.** Browser (`ConversationWorkspace.js:139-143`, POST
`{lead_id, message}`) → `n8n-proactive-message.js` → `fetch` al webhook
`N8N_PROACTIVE_WEBHOOK_URL` con `Authorization: Bearer` (`:96-100` S1, `:151-155` legacy) → en el
camino S1 se valida el **eco** de n8n (`retomarBuilder.js:67-73`: `success===true`,
`status==='sent'`, `session_id` idéntico, `conversation_id` esperado según `identity_mode`) → y solo
entonces `saveAudit` (`:170-184`).

**Qué se rompería si el campo apareciera** — esto es lo importante:

1. **Rompe el fixture contractual S1.** `scripts/s1/fixtures/dashboard-retomar.json` declara
   `contract: S1-DUAL-STG`, `version: 1.1.0`, 7 casos (3 `valid`, 4 `invalid`), y
   `scripts/s1/test/fixture-dashboard-retomar.test.js:51` compara con
   `assert.deepEqual(built.wire, c.expected.wire)` — **igualdad exacta, timestamp incluido**. Un
   campo nuevo pone en rojo los 3 casos `valid` (`S1-D1-legacy`, `S1-D1b-shadow`,
   `S1-D2-v2-mismo-telefono`). Es decir: **tocar el wire es enmienda del contrato acreditado, no
   una decisión de implementación.**
2. **Rompe el congelado del payload legacy.** `scripts/s1/test/handlers.test.js:338` afirma
   `assert.deepEqual(sent, { phone_number, message, session_id })` — exacto, sin campos extra.
   Y el camino legacy es, por el dictamen P1-D4, "byte a byte la base `e50e3ada`"
   (`n8n-proactive-message.js:58-63`): añadirle un campo contradice ese aislamiento de PROD.
3. **NO rompe la validación del eco.** `validateRetomarResponse` (`retomarBuilder.js:67-73`) solo
   mira campos de la *respuesta* de n8n; un campo más en la petición le es indiferente.
4. **Del lado de n8n no lo puedo afirmar** — no leí ese repo en esta tarea. Si el webhook valida su
   entrada por esquema estricto, un campo desconocido podría rechazarse; eso lo tiene que confirmar
   el inventario de n8n.

**Dato que cambia el encuadre:** el Dashboard **ya sabe** quién envió cada mensaje y lo persiste —
`saveAudit` (`:170-184`) inserta en `dashboard_message_audit` con `agent_id` y `claim_id` (lo
resuelve en `:172-175`). Lo que falta no es *capturar* la identidad del emisor, sino **transportarla**:
esa información nunca sale del Postgres del Dashboard y por eso `n8n_chat_histories` no distingue
humano de IA. El hueco es de transporte, no de captura.

### 1.3 Auto-release por inactividad → **✘ NO existe nada**

- `apps/operacion/pages/api/claim.js` implementa **solo** `POST` (`:24-59`) y `DELETE` (`:61-83`),
  más `405` (`:85`). No hay ninguna otra vía de cambiar `state`.
- **No hay cron:** no existe `vercel.json` en el árbol, ni ninguna definición de `crons`. `grep -i`
  de `cron|inactiv|expir|ttl|auto_release` sobre `apps/`, `packages/`, `migrations/`, `scripts/`
  no devuelve ningún mecanismo de liberación; los aciertos son ruido (`Cache-Control` en
  `analytics.js:19` y `meta-analytics.js:20`, `CACHE_TTL_MS` de `infraestructura.js:30`, "Inactivo"
  como etiqueta de agente en `AgentsAdminView.js:161`).
- **`epoch` no es un reloj.** Se calcula como `MAX(epoch)+1` por sesión (`claim.js:39`): es un
  contador monotónico de fencing, no una marca temporal — no puede expirar solo.
- Lo único cercano es cosmético: `ConversationWorkspace.js:180` calcula `isStale` (>24h desde
  `last_activity`) y `:245-249` pinta un aviso ámbar "el usuario podría no responder de inmediato".
  **Avisa al agente; no libera nada.**

**Mi lectura sobre A6 (si entra en el S3 "básico") — coincido con diferirlo, y añado dos razones
que salen del código:**

1. Un auto-release es un **escritor nuevo de la fuente de autoridad**, y además asíncrono. Hoy
   `dashboard_conversation_claims` solo la escriben dos handlers síncronos con agente autenticado
   (`claim.js:36-43` y `:72-77`), ambos con `agent_id` como parte del predicado. Un cron rompe esa
   invariante: liberaría sin agente. El contrato tendría que definir qué `agent_id`/actor consta en
   una liberación automática, y eso arrastra auditoría y fencing.
2. Peor: un auto-release **le devuelve el control a la IA sin que nadie lo decida**, justo en el
   escenario que S3 existe para ordenar. Si el gate de supresión pasa a leer claims (§2 del prep),
   un TTL se convierte en "la IA vuelve a hablarle al cliente sola tras N minutos" — una decisión de
   producto de bastante calado para meterla en la etapa "básica".

Coste de diferirlo: un claim olvidado bloquea a la IA indefinidamente. Hoy eso **ya pasa** y es
inocuo (la IA no está silenciada); en S3 dejaría de serlo. Sugerencia mínima si se difiere:
que S3 exija al menos que un claim visiblemente viejo sea **liberable por otro agente o por un
admin** — pero eso también es contrato, y no existe hoy (el `DELETE` exige `agent_id = $3`,
`claim.js:74`: **nadie puede liberar la toma de otro**, ni un admin).

---

## 2. `qualitas-issues#29` — deployments Preview sin purgar

**Estado: los 6 siguen vivos.** Verificado hoy con `vercel inspect` (uno por uno) y `curl`; **no se
purgó nada**.

| Deployment (`…-<id>-…`) | ID interno | Creado | `target`/estado | Alias asignado | HTTP hoy |
|---|---|---|---|---|---|
| `b1xx87wcf` | `dpl_1tgU7crCa9jmxYppFMCxy87TrRGG` | 2026-07-10 20:03:25 | preview / ● Ready | `…-git-stg-…` | 307 → `/login` |
| `a65fgaxuy` | `dpl_5j7jn9cFfs9pYD7BMvHcAYPYm31k` | 2026-07-10 20:15:00 | preview / ● Ready | `…-git-stg-…` | 307 → `/login` |
| `ces3lsmvw` | `dpl_73vXbdAnpPt1VvTVkdqc8sbJkL7f` | 2026-07-10 09:15:53 | preview / ● Ready | `…-git-bb76b5-…` | 307 → `/login` |
| `58b7z67nu` | `dpl_GXwMAcnNNvgbhvAAKnX7cgFxvto9` | 2026-07-10 09:13:41 | preview / ● Ready | `…-git-bb76b5-…` | 307 → `/login` |
| `7u8wtceqo` | `dpl_84wRMy5F6zReJDbjpBgsS4fpMvoq` | 2026-07-10 09:12:36 | preview / ● Ready | `…-git-bb76b5-…` | 307 → `/login` |
| `cpwlzarde` | `dpl_4isdUM5yKe25HMthaUTgAZdxDwm6` | 2026-07-09 16:23:48 | preview / ● Ready | `…-git-bb76b5-…` | 307 → `/login` |

Los 6 son **anteriores al fix de #17** (`b08bc4d`, 2026-07-10 20:55:31 -0600 — verificado en el
repo). El más nuevo, `a65fgaxuy`, es 40 minutos anterior.

**Los aliases de rama ya NO resuelven a ninguno de ellos** — esto matiza la tabla del issue:

- `…-git-stg-…` resuelve hoy a **`6uy5pnivt`** (2026-08-06 17:30) — el candidato A1.
- `…-git-bb76b5-…` resuelve hoy a **`enkp914ms`** (2026-07-10 20:56:12), o sea **41 segundos
  después** del commit del fix `b08bc4d`.

La columna "Alias" de `vercel inspect` es el alias que se asignó al deployment **en su momento**, no
la resolución vigente. La resolución vigente es la que manda, y ninguno de los 6 la tiene.
**Su superficie viva es su URL única**, que sigue sirviendo (307 → `/login`, es decir el
`middleware.js` responde: la app está arriba, solo pide sesión).

**`bb76b5` sigue sin identificarse, y ahora sé por qué mi herramienta no puede.** Dos cosas:

- `vercel inspect --json` (CLI 54.16.0) **no expone `meta`** — ni `githubCommitRef` ni
  `githubCommitSha`. Lo comprobé también contra deployments recientes con alias `git-main` y
  `git-stg`, que sí vienen de la integración Git: **también salen sin `meta`**. Así que la ausencia
  de metadatos **no** dice nada sobre el origen de un deployment; es un límite de la herramienta.
  (Corrijo aquí una hipótesis intermedia mía —"los 6 vinieron de `vercel deploy` suelto"— que este
  contraste desmontó: no está probada.)
- El alias `bb76b5` aparece en un host **truncado**: `dashboard-seguroautoqualita-git-bb76b5-…`
  (falta la `s` final del proyecto) frente a `dashboard-seguroautoqualitas-git-stg-…`. Eso encaja
  con el mecanismo de Vercel de recortar el subdominio y añadir un hash cuando `git-<rama>` excede
  el límite del label DNS. **Inferencia, no reproducida**: `bb76b5` sería un hash de truncamiento,
  no un nombre de rama — lo que explicaría por qué no corresponde a ninguna rama ni a ningún SHA
  (`git cat-file -t bb76b5` → *not a valid object name*, verificado).

**Plan propuesto (para cuando se levante el freeze — NO ejecutado):**

1. `vercel rm` explícito de los 6 por su URL única, empezando por los 4 de `bb76b5` (sin alias
   vigente ni rama identificable, es decir los de menor riesgo de sorpresa).
2. Antes de tocar los dos de `git-stg`, confirmar una vez más que el alias resuelve a `6uy5pnivt`;
   si el alias fijo se hubiera movido, parar.
3. Política de retención: el issue la pide y sigue sin existir. La forma barata es una purga
   periódica de Preview con más de N días; la forma que ataca la causa (comentario del propio #29,
   23 jul) es un guard que impida `vercel deploy` suelto fuera del alias de rama.
4. Registrar que la superficie real de riesgo son las **URLs únicas**, no los aliases — el issue
   dice "el alias ya apunta al más reciente" y eso hoy es cierto, pero no reduce el riesgo.

**Observación colateral, sin acción:** el push del propio handoff (`ac7d0a7`, doc-only, 15:36:10)
disparó un deployment de **Production** (`lmieippyh`, 15:36). Es el comportamiento normal de `main`,
lo hiciste tú y no cambia código de runtime — lo anoto solo para que conste que durante el freeze
`main` sigue auto-desplegando PROD igual que `stg` auto-publica STG.

---

## 3. `qualitas-issues#57` — encuadre como materia S3

**Reparto por dominio, con lo verificado hoy sobre `c911d4c`:**

| Parte | De quién | Estado hoy | Qué la cubre |
|---|---|---|---|
| Registrar que un humano tomó la conversación | **Dashboard** | ✔ hecho: `dashboard_conversation_claims` con `control_id`+`epoch`, escrito por `claim.js:36-43` / `:72-77` | ya acreditado en S1 |
| Publicar esa señal donde el bot la vea | **frontera Dashboard↔n8n** | ✘ inexistente: `claim.js` no notifica a nadie; `grep human_takeover` = 0 | S3 §"identidad del control" |
| Que el bot consulte la señal antes de auto-responder | **n8n** | ✘ (según #57 y `docs/bugs/bug-09-…`) el handler de inbound no tiene check de takeover | S3 §"silenciamiento de IA" |
| Persistir el inbound sin responderlo mientras hay humano | **n8n** | ✘ | S3 §"persistencia de inbound" (A8) |
| Distinguir en el historial un envío humano de uno de la IA | **Dashboard (emisión) + n8n (persistencia)** | ✘ el campo no viaja (§1.2) — aunque el Dashboard sí lo audita internamente | S3 §"envío humano" (A7) |
| Devolver el control a la IA | **Dashboard emite, n8n obedece** | ✘ el `DELETE` es interno (§1.1) | S3 §"liberación" |

**Qué queda cubierto cuando S3 exista:** el escenario completo del issue (bot y humano
respondiendo en paralelo) desaparece **si y solo si** el gate de supresión de n8n lee la fuente
canónica de claims — no el espejo. Mientras la autoridad viva en el Dashboard y el bot lea otra
cosa, #57 sigue reproducible en la ventana entre ambas.

**Mi lectura:** #57 **no es un bug del Dashboard** y no tiene arreglo unilateral aquí. Es la
*motivación* de S3, y así conviene registrarlo — si se etiqueta como bug de `sistema:dashboard`
pendiente, alguien puede intentar "arreglarlo" con un parche local (p. ej. escribir el espejo desde
`claim.js`) que precisamente el contrato S2 §4.3.1/§5.3 degrada a no-fuente-de-autoridad.

**Discrepancia documental que te toca a ti resolver:** `docs/bugs/bug-09-bot-vs-agente-humano.md`
(23 jul, en `c911d4c`) afirma que *"`whatsapp_sessions` no tiene ninguna columna que represente
presencia humana"*. Tu `s3-prep-offline.md` §2 afirma lo contrario: el espejo `human_takeover`
(+`_control_id`/`_epoch`) **existe** y lo escribe un workflow de n8n. **No puedo dirimirlo**: exige
mirar el esquema vivo o el repo de n8n, y las dos cosas están fuera de mi alcance. Lo más probable
es que sea cronología (el espejo llegó después del 23 jul) y que el doc del Dashboard esté
simplemente caducado — pero mientras no se dirima, `bug-09` es una fuente que contradice el prep.

---

## 4. Resumen de veredictos

| # | Punto | Veredicto | Ancla principal |
|---|---|---|---|
| 1a | Indicador "tomada por X" | **✔** | `InboxView.js:146-155`, `ConversationWorkspace.js:217-224` |
| 1b | UI "Soltar a IA" | **✘** (existe "Liberar conversación", pero es interna) | `ConversationWorkspace.js:193-204` → `claim.js:72-77` |
| 2 | `sent_by: human_agent` en el proactivo | **✘** | `retomarBuilder.js:51-61`, `n8n-proactive-message.js:154` |
| 3 | Auto-release por inactividad | **✘** (nada: ni cron, ni TTL, ni `epoch` temporal) | `claim.js:24-85`, sin `vercel.json` |
| — | #29: los 6 deployments siguen Ready y sirviendo | **confirmado** | tabla §2 |
| — | #57: materia S3, no bug local del Dashboard | **encuadrado** | tabla §3 |

---

## 5. Ambigüedades pre-freeze (decisión de diseño, no hecho)

Separadas como pediste. Las tres primeras son nuevas; las dos últimas refinan A6/A7 de tu prep.

- **D1 — La lectura de la bandeja identifica la toma por `lead_id`, no por `session_id`.**
  `apps/operacion/pages/api/inbox.js:55` hace
  `LEFT JOIN dashboard_conversation_claims cl ON cl.lead_id = l.id AND cl.state = 'active'`,
  mientras que la **autoridad** es `uq_claims_active_session (session_id) WHERE state='active'`
  (comentario en `claim.js:4-10`) y el `POST` resuelve la sesión server-side (`claim.js:11-18`).
  O sea: **se escribe por sesión y se lee por lead**. Con el escenario A/B de S1 (mismo teléfono,
  dos leads sobre la misma sesión, o un lead con dos sesiones) el chip "👤 Tú / Tomada por X" de la
  bandeja puede no reflejar el claim real de esa sesión. No es un fallo de S1 (S1 acreditó
  `conversation.js`, no la pintura de la lista), pero **si A1 fija `session_id` como identidad del
  control, esta lectura queda contractualmente desalineada** y conviene que el contrato lo diga.
  Es el hallazgo que más me preocupa de todo el inventario.
- **D2 — Nadie puede liberar la toma de otro, ni un admin.** `claim.js:74` exige
  `agent_id = $3` en el `WHERE` del `UPDATE`. Es correcto como fencing, pero deja el sistema **sin
  ninguna vía de desbloqueo** si un agente se va con conversaciones tomadas. Si S3 difiere el
  auto-release (A6), esta es la contrapartida que hay que decidir: ¿liberación administrativa sí o
  no, y con qué actor en la auditoría?
- **D3 — Enmienda contractual encubierta en A7.** Añadir `sent_by` **no es** una decisión de
  implementación: rompe `fixture-dashboard-retomar.json` (contrato `S1-DUAL-STG` v1.1.0) por
  igualdad exacta, y rompe el congelado del payload legacy de PROD. Si A7 entra al contrato de
  datos S3, entra **con versión nueva del fixture** y con una decisión explícita sobre si el camino
  legacy de PROD se toca o se deja intacto (yo propondría dejarlo intacto y marcar solo el camino
  nuevo).
- **D4 — refuerza A6:** un auto-release introduce un escritor asíncrono y sin agente sobre la
  fuente de autoridad, y devuelve el control a la IA sin decisión humana (razonamiento en §1.3).
- **D5 — refuerza A7 por el otro lado:** la identidad del emisor **ya está capturada** en
  `dashboard_message_audit` (`n8n-proactive-message.js:170-184`). Si el contrato solo necesita
  *trazabilidad* y no *comportamiento del bot*, hay una opción intermedia — dejar `sent_by` fuera
  del wire y exponerlo desde la auditoría del Dashboard — que evita tocar el contrato S1. Si en
  cambio n8n necesita el campo **para decidir**, entonces sí tiene que viajar y D3 aplica.

---

## 6. Estado al cerrar

- Repo Dashboard en `c1-gates-api-default-deny`, limpio, sin cambios sin commitear. `stg`, `main`
  y `S1_DASHBOARD_MODE` intactos. PR #2 abierto y sin tocar.
- Worktree temporal de `c911d4c` eliminado tras la lectura.
- Sin dudas bloqueantes que dejar en `dudas/` — lo único que no pude dirimir (`bug-09` vs prep §2
  sobre el espejo) está en §3 y necesita el lado n8n, no una respuesta tuya sobre alcance.
