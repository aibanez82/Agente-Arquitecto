# C1 — Auditoría primaria (reconstrucción forense desde artefactos)

> **SRC-ALBERTO-C1-002** · Supersede la integridad de SRC-ALBERTO-C1-001 · Autor: Agente-Arquitecto · 2026-08-03
>
> **Método:** dos barridos independientes de evidencia primaria — (1) API de GitHub: issue `aguayo-co/HYL-WAI#140` (53 comentarios) y `#132` (272 comentarios), búsqueda en `aibanez82/qualitas-issues` (0 resultados C1); (2) git local read-only de `Agente-n8n`, `Agente-Arquitecto` y `HYL-WAI`. Formato de referencia: `c.NNNNNNNNNN` = comentario de GitHub con timestamp UTC; SHAs con fecha de autor (offset −06:00 salvo indicado). Prefijos: `HECHO` (artefacto citado) · `ESTIMACIÓN` (base explícita) · `UNKNOWN`. Toda fila de tabla lleva su referencia y cuenta como HECHO.
>
> **Alcance:** "Caso C1" = fase C1 (contención: barreras A/B, plano vivo default-deny + 7 clones aislados) del núcleo Dual / port-132, planificada y ejecutada entre 2026-07-30 y 2026-08-02.

---

## A. Origen y alcance

### A1. Petición original

**HECHO** — El origen escrito de C1 es el plan "opción C" publicado por `oilycoyote` en GitHub: `#140 c.5137216437 2026-07-30T23:12:37Z` ("Plan de trabajo revisado — opción C"), donde C1 aparece como fase del "Carril A — núcleo Dual, camino crítico: C0 → C1 → C2 → C3 → C4 → C5". Definición literal (§5, "C1 — contención técnica mínima"):

> "Esta fase bloquea toda prueba viva y produce **dos barreras independientes**; no certifica Humano/Metepec."
> — **A. Contención del plano vivo:** "Todos los ingress activos inventariados de Main, Payment, Retomar, Atención Humana, Metepec y subworkflows tendrán gates server-side default-deny […] Dashboard aplica el mismo default-deny a take/dispatch/Metepec y responde 403 estructurado […] Un inventario recursivo […] demuestra sobre el artefacto efectivo: `real_connector_calls=0`, `new_claims=0`, `new_derivations=0`."
> — **B. Aislamiento del plano de prueba:** "Desde los exports congelados se generan clones inactivos […] Sinks deterministas sustituyen WhatsApp, Gmail, Quálitas/Django, Payment, Anthropic/OpenAI […]"

**HECHO** — Aceptación por ambas partes: `#140 c.5137223537 2026-07-30T23:13:48Z aibanez82` ("Aprobación de @aibanez82 […] OPCIÓN C") y `#140 c.5137954763 2026-07-31T01:02:03Z oilycoyote` ("confirmamos que estamos de acuerdo con la opción C"). Precursor: `#140 c.5136826715 2026-07-30T22:16:02Z oilycoyote` (recomendación de la opción C). Canal: GitHub issues, en ambos casos.

**HECHO** — Primer artefacto C1 en git: handoff del Arquitecto al ejecutor `handoffs/2026-07-31-c1-contencion-gates-plano-aislado.md`, commit `fe0ec01 2026-07-30T23:10:03−06:00` (rama `feature/issue-132-port-dual-safe` de Agente-n8n) — 2 minutos antes de la publicación del plan en #140 (23:10:03−06:00 = 05:10Z del 31; el plan es de 23:12Z del 30; el handoff se commiteó ~6h DESPUÉS del plan en tiempo absoluto).

**UNKNOWN** — Si existió una petición conversacional previa al plan escrito (sesión de chat Alberto↔Arquitecto o Alberto↔Juan): los logs de sesión no son recuperables.

### A2. Primera definición escrita de "terminado" (DoD)

**HECHO** — Criterio de salida de C1 en el propio plan (`#140 c.5137216437 2026-07-30T23:12:37Z`, §5): *"**Salida:** tests fail-first de gates, sinks, inventario y alcanzabilidad; cualquier conector real alcanzable es NO-GO."* El §12 "Definition of Done" del mismo comentario define DoD para el cierre de #132 y #140, **no** una DoD operativa específica de C1.

**HECHO** — La condición de cierre *operativo* de C1 se construyó después, principalmente en `#140 c.5149044773 2026-08-01T02:09:39Z` (aceptación offline + 9 requisitos del checkpoint operativo) y las enmiendas posteriores (ver A3).

### A3. Cambios de alcance / DoD (cronológico)

| # | Referencia | Qué cambió | ¿Invalida trabajo previo (según el propio texto)? |
|---|---|---|---|
| 1 | #132 c.5137997287 2026-07-31T01:08:42Z aibanez82 | Re-scope de #132: "El alcance canónico de #132 pasa a ser el núcleo Dual" | No lo dice |
| 2 | #140 c.5138861034 2026-07-31T03:15:59Z oilycoyote | Cierre de C0 y "GO específico de C1" ("Declaro por escrito el cierre de C0 y emito el GO específico de C1 […] - Oilycoyote, humano.") | — |
| 3 | #140 c.5139480586 2026-07-31T05:07:27Z oilycoyote | Delimitación del GO: "autorizada para construcción y revisión no operativa […] **No existe autorización viva** para STG/PROD, consultas incluso read-only, deploy…" | No; acota el GO |
| 4 | #140 c.5147782653 2026-07-31T21:52:45Z oilycoyote | Dictamen NO-GO con criterios de re-revisión nuevos (FAKE de bypass, SQL dinámico, semántica `ai_*`, sinks por contrato, `run.log`; Dashboard `next>=14.2.25`, claim propio) | Sí: "C1 offline NO aceptada. No abrir checkpoint vivo y no integrar las ramas" |
| 5 | #140 c.5149044773 2026-08-01T02:09:39Z oilycoyote | Aceptación offline + **9 requisitos nuevos** del checkpoint operativo; "dejar C2 explícitamente fuera" | "Cierra el NO-GO offline anterior, pero no declara C1 operativamente instalada/cerrada" |
| 6 | #132 c.5152112808 2026-08-01T15:36:33Z oilycoyote | Gate humano/RACI: "la autodenominación de Alberto como 'accountable' no sustituye al A canónico" — exige suplente o enmienda RACI | "No hace falta otro push ni otra auditoría" |
| 7 | #140 c.5153952626 2026-08-01T23:19:17Z oilycoyote | Enmienda RACI: operador único @aibanez82 + 6 controles compensatorios; ventana "3-ago 09:30 CDMX" | No |
| 8 | #140 c.5153977172 2026-08-01T23:26:10Z oilycoyote | "STG usa sincronización inmediata, no ventanas calendarizadas" | Reemplaza la ventana de la fila 7 |
| 9 | #132 c.5154440416 2026-08-02T01:32:12Z oilycoyote | Enmienda al GO: criterio 3f pasa de sonda autenticada `403 GATE_DENIED` a acreditación de configuración (opción A de c.5154417314) | "Modifica **únicamente** el criterio 3f de esta corrida" |
| 10 | #132 c.5154563080 2026-08-02T02:02:16Z oilycoyote | Tras el STOP de la corrida 1: "Ruta mínima segura" con 6 requisitos nuevos (guardas invariantes a la pausa, persistir desenlaces de B, verifier GET-only, regresión integrada, simulación post-pausa, regenerar manifests) | "No hay reintento: la excepción y GO anteriores quedaron consumidos" |
| 11 | #140 c.5154662330 2026-08-02T02:24:22Z oilycoyote | Enmienda mayor: 7 condiciones objetivas de autorización condicional; delegación de PASS/FAIL al monitor; re-run C1 preautorizado; aplicada a #132 en c.5154663793 | "Reemplaza los criterios incompatibles anteriores únicamente en los puntos expresos" |
| 12 | #132 c.5155066043 2026-08-02T03:46:59Z oilycoyote | "NO PASS / SHA retirado — C1 vuelve a `e7f3a78`" (retira `fdc4ed6`) | Sí: retira ese SHA como identidad C1 |
| 13 | #132 c.5157632531 2026-08-02T11:48:27Z oilycoyote | Cierre de C1 aceptando la desviación declarada, "como excepción única" | — |

**HECHO** — Total: 13 cambios de alcance/criterio documentados en ~36h, 12 de ellos introducidos por `oilycoyote` (accountable/monitor), 1 por `aibanez82` (re-scope inicial).

---

## B. Timeline y actores

### B1. Timeline completo

| Timestamp (UTC) | Evento | Actor origen | Actor destino | Artefacto/referencia |
|---|---|---|---|---|
| 07-30T23:12:37 | Plan opción C; C1 definida | oilycoyote | ambos | #140 c.5137216437 |
| 07-30T23:13:48 | Aprobación opción C | aibanez82 | oilycoyote | #140 c.5137223537 |
| 07-31T01:08:42 | Re-scope #132 → núcleo Dual | aibanez82 | tracker | #132 c.5137997287 |
| 07-31T03:15:59 | Cierre C0 + **GO C1** | oilycoyote | aibanez82 | #140 c.5138861034 |
| 07-31T05:07:27 | Delimitación: GO solo construcción no operativa | oilycoyote | aibanez82 | #140 c.5139480586 |
| 07-31T05:10:03 | Handoff C1 al ejecutor (git) | Arquitecto | ejecutor n8n | Agente-n8n `fe0ec01` |
| 07-31T06:13:48 | Primer commit de código C1 (gates + plano aislado) | ejecutor n8n | — | `ad85149` (hora local 00:13−06:00) |
| 07-31T06:15:17 | Entrega C1 offline: rama candidata `ad85149`, 71/71 | aibanez82 | oilycoyote | #140 c.5139921305 |
| 07-31T06:30:46 | Evidencia conjunta: n8n `ad85149` + Dashboard `07324f4`; 88/88, gates 6/6 | aibanez82 | oilycoyote | #140 c.5140031183 |
| 07-31T21:09–21:26 | Incidente paralelo: PRs #141/#142 mergeados a `stg` sin checkpoint; escalación | oilycoyote (monitor) | oilycoyote (A) | #140 c.5147501167 / c.5147553808 / c.5147608218 |
| 07-31T21:42:47 | Desajuste de identidad del candidato (head movido); candidato = `b76a5469` | oilycoyote | aibanez82 | #140 c.5147718871 |
| 07-31T21:52:45 | **Dictamen NO-GO C1 offline** (n8n: 5 bloqueantes; Dashboard: 2 P0 + 1 P1) | oilycoyote | aibanez82 | #140 c.5147782653 |
| 07-31T22:49:15 | Re-entrega: n8n `fe456b014` + Dashboard PR #2 | aibanez82 | oilycoyote | #140 c.5148108549 |
| 08-01T00:56:01 | Re-revisión: Dashboard apto; n8n mantiene 1 P1 | oilycoyote | aibanez82 | #140 c.5148715706 |
| 08-01T01:21:14 | Entrega `b2c89ba15` | aibanez82 | oilycoyote | #140 c.5148827114 |
| 08-01T01:31:48 | "P1 cerrado; queda un P2 de redacción" | oilycoyote | aibanez82 | #140 c.5148866994 |
| 08-01T01:57:02 | Entrega `4e2118c39` | aibanez82 | oilycoyote | #140 c.5148961363 |
| 08-01T02:09:39 | **C1 aceptada offline** (147/147; Dashboard congelado `1373d1ab`) + 9 requisitos de checkpoint | oilycoyote | aibanez82 | #140 c.5149044773 |
| 08-01T02:13:48 | Borrador checkpoint operativo "NO ejecutable" | aibanez82 | oilycoyote | #132 c.5149097301 |
| 08-01T02:20:10 | "NO-GO operativo; corregir offline" | oilycoyote | aibanez82 | #132 c.5149165789 |
| 08-01T02:57–06:30 | Rondas B2–B6 de checkpoint: `86a9c093`, `601a845`, (sin SHA), `464dbd497`, `7c877a717`/`871221400` — todas FAIL | ambos | ambos | #132 c.5149463414…c.5150210658 |
| 08-01T12:10:12 | Monitor detecta head `1c30a00b6` "avanzó silenciosamente" | oilycoyote | aibanez82 | #132 c.5151359011 |
| 08-01T12:42–15:21 | Rondas B7–B13: `1c30a00b6`, `78442a4`, `4e8acea4`, `8b2c8c2`, `d651b22` FAIL; `944cd96` **PASS**; `5fcc060` **PASS** | ambos | ambos | #132 c.5151470952…c.5152051722 |
| 08-01T15:35:20 | Datos definitivos del operador (ventana 3-ago) | aibanez82 | oilycoyote | #132 c.5152108294 |
| 08-01T15:36:33 | Bloqueo gate humano/RACI ("no falta código") | oilycoyote | oilycoyote (A) | #132 c.5152112808 |
| 08-01T18:35:20 | Solicitud de enmienda RACI (operador único) | aibanez82 | oilycoyote | #132 c.5152822925 |
| 08-01T23:19:17 | Enmienda RACI aceptada | oilycoyote | aibanez82 | #140 c.5153952626 |
| 08-01T23:26:10 | Enmienda: sincronización inmediata (sin ventana calendarizada) | oilycoyote | ambos | #140 c.5153977172 |
| 08-01T23:51:53 | "Alberto listo para C1 ahora" | aibanez82 | oilycoyote | #132 c.5154060859 |
| 08-02T00:01:22 | **GO operativo C1** — corrida única; identidad `5fcc06099`; hashes de `comandos-ventana.json` y `plan-instalacion.json` pinneados | oilycoyote | aibanez82 | #132 c.5154091214 |
| 08-02T00:49:36 | Preflight Hostinger PASS (`PRECHECK_OK: version=2.28.7 mode=sincrona`) — ejecutado por Juan en el VPS STG | oilycoyote | aibanez82 | #132 c.5154268653 |
| 08-02T01:26:21 | Prechecks 3a–3e verdes; 3f no producible; HOLD | aibanez82 | oilycoyote | #132 c.5154417314 |
| 08-02T01:32:12 | Enmienda 3f; reanudar desde paso 4 | oilycoyote | aibanez82 | #132 c.5154440416 |
| 08-02T01:49:01 | **Corrida 1: STOP fail-closed en barrera B** (run-ids `c1-20260802T014026-c975` pausa / `c1-20260802T014148-21a0` instalación); "cero clones creados, cero PUT"; restore 7/7; excepción consumida | aibanez82 | oilycoyote | #132 c.5154508007 |
| 08-02T02:02:16 | "FAIL P1 confirmado — `pausa → B` es imposible en `5fcc060`"; ruta mínima (a) | oilycoyote | aibanez82 | #132 c.5154563080 |
| 08-02T02:24:22 | Enmienda #140: autorización condicional (7 condiciones) + re-run C1 preautorizado | oilycoyote | ambos | #140 c.5154662330 (a #132: c.5154663793) |
| 08-02T02:27:12 | Cierre de #140 (planificación completada, implementación → #132) | oilycoyote | — | #140 c.5154673785 |
| 08-02T03:20–04:57 | Rondas D1–D7: `415ee46` FAIL; `e7f3a78` sin cambio; `46500d2` PASS focal; `fdc4ed6` retirado; `161d6913` FAIL; `2b9096a` FAIL; `416d1987` **"PASS técnico consolidado C1"** (356/356) | ambos | ambos | #132 c.5154925188…c.5155482965 |
| 08-02T05:01:55 | Handoff de ventana: guardas frescas + disponibilidad | aibanez82 | oilycoyote | #132 c.5155509842 |
| 08-02T05:05:19 | Monitor publica "condiciones de autorización humana satisfechas"; transfiere la corrida única | oilycoyote (monitor) | aibanez82 | #132 c.5155529675 |
| 08-02T05:14:00 | **Corrida 2 EJECUTADA — verde**: pausa `c1-20260802T050946-7aa3` (7/7) + instalación B→A **`c1-20260802T051054-0453`**; "7 clones `C1-AISLADO` […] contención instalada y acreditada en STG" | aibanez82 | oilycoyote | #132 c.5155576499 |
| 08-02T05:25:13 | HOLD de cierre: "núcleo 7+7 verde; falta evidencia de los productores/prechecks ejecutados" | oilycoyote | aibanez82 | #132 c.5155631752 |
| 08-02T05:31:16 | "DECLARACIÓN DE OMISIÓN": el tramo `OK 1b/2/2b/3a` "NO se ejecutó durante esta corrida" | aibanez82 | oilycoyote | #132 c.5155662487 |
| 08-02T05:34:27 | "STOP por desviación del checkpoint — corrida consumida; decisión al A humano" | oilycoyote | oilycoyote (A) | #132 c.5155678719 |
| 08-02T11:48:27 | **CIERRE DE C1**: "acepto la desviación declarada […] y cierro C1 […] como excepción única" | oilycoyote | ambos | #132 c.5157632531 |
| 08-02T11:49:30 | Monitor aplica el cierre; "transición a C2 exclusivamente offline" | oilycoyote | — | #132 c.5157638154 |
| 08-02T14:07:07–16 | Huella de la corrida en el espejo git: 4 commits `sync: drift detectado` con los nodos `C1 Gate —` | ejecutor (detect-drift) | — | Agente-n8n `stg` `d4f8ab3`→`3981362` (08-02T08:07−06:00) |

### B2. Esperas >1h (línea combinada #140+#132)

| Desde | Hasta | Duración | Quién esperaba a quién | Esperando QUÉ (literal) | Refs |
|---|---|---|---|---|---|
| 07-31T03:21:33 | 07-31T05:07:27 | 1,76 h | ejecutores ← accountable | delimitación del GO: "aclara quién puede empezar ya y hasta dónde llega la autorización existente" | #140 c.5138901100 → c.5139480586 |
| 07-31T05:14:19 | 07-31T06:15:17 | 1,02 h | oilycoyote ← aibanez82 | primera entrega C1 n8n | #140 c.5139522703 → c.5139921305 |
| 07-31T06:30:46 | 07-31T21:52:45 | **15,37 h** | aibanez82 ← oilycoyote | dictamen de la "Evidencia conjunta C1 […] quedamos a la revisión conjunta del accountable" (con incidentes de gobernanza paralelos en medio) | #140 c.5140031183 → c.5147782653 |
| 07-31T22:49:15 | 08-01T00:56:01 | 2,11 h | aibanez82 ← oilycoyote | re-revisión de `fe456b014`/Dashboard PR #2 | #140 c.5148108549 → c.5148715706 |
| 08-01T06:35:32 | 08-01T12:10:12 | 5,58 h | oilycoyote ← aibanez82 | "subir un único SHA nuevo" tras FAIL (el head apareció y el monitor lo detectó "silenciosamente") | #132 c.5150210658 → c.5151359011 |
| 08-01T15:36:33 | 08-01T18:35:20 | 2,98 h | oilycoyote (A) ← aibanez82 | resolución del bloqueo suplente/RACI | #132 c.5152112808 → c.5152822925 |
| 08-01T18:37:03 | 08-01T23:19:17 | 4,70 h | aibanez82 ← oilycoyote (A humano) | decisión del A sobre la enmienda RACI | #132 c.5152829869 → #140 c.5153952626 |
| 08-02T05:34:27 | 08-02T11:48:27 | **6,23 h** | ambos ← oilycoyote (A humano) | "decidir expresamente la disposición de [las corridas]: aceptar o no la desviación" | #132 c.5155678719 → c.5157632531 |

**HECHO** — Suma de esperas >1h medibles en los issues: **39,75 h** (nota: varias son solapadas con trabajo offline u horario nocturno; los issues no registran qué hacía cada actor durante el gap). Corroboración por gaps de commits en Agente-n8n (ventana C1): 9,3 h (`ad85149`→`6f1d394`), 5,8 h (`e473e38`→`1fc321c`), 10,4 h (`5b00929` 08-01T09:24−06:00 → `c2d6dea` 19:50−06:00; el doc de auditoría interna del Arquitecto la anota como "~7,7 h de espera humana" RACI/GO — Agente-n8n `docs/2026-08-02-ai-delivery-audit-caso-1-c1.md`, commit `bd24074`).

### B3. Clasificación de handoffs

**HECHO** — Tres canales distintos operaron en C1:

1. **Alberto/Arquitecto ↔ Juan/monitor (GitHub, #140/#132):** 24 rondas candidato→dictamen (ver E) + decisiones humanas (GO, enmiendas, cierre) + acuses. Es el canal de autorización.
2. **Arquitecto ↔ ejecutor n8n (agente↔agente, vía git):** **35 handoffs C1** (34 en `main` de Agente-n8n desde `9a41092 07-31T15:54−06:00` hasta `293377f 08-01T23:00−06:00`, + 1 original en rama, `fe0ec01`) y **28 informes** de respuesta del ejecutor en `docs/`. De los 34: 6 son órdenes "RE-CONGELAR", 2 congelaciones y 1 congelación-PASS — es decir, 9 de 34 (26 %) son gestión de estado del candidato, no contenido técnico nuevo.
3. **Humano ↔ agente (sesiones):** las instrucciones de Alberto a sus agentes en sesión. **UNKNOWN** en número y contenido — no quedan logs recuperables.

**HECHO** — Handoffs con re-explicación o corrección de contexto ya comunicado (citas literales en los artefactos):
- `7a1e995 07-31T21:56−06:00` "actualización ronda 5": "candidato restaurado a 86a9c09, camino PUT movido a cuarentena — sincroniza tu clon (reset a origin) y no re-pushees la candidata".
- `f4bfa85 07-31T22:02−06:00` "estándar de rigor": *"Esta fase se está alargando por fallos evitables —de mi lado y del tuyo—… Construiste el camino `PUT` 5 min después de que mi handoff en `main` lo prohibiera… El '8 nodos con webhookId → en realidad 16' y el orden 'periferia primero' (que resultó **invertido**) fueron afirmaciones dadas antes de verificar."*
- Primer handoff de PR con valores pre-fix: *"Valores esperados eran pre-fix; el PR tuvo que explicar cada delta (sinks 24→22, gates 43→54)"* (Agente-n8n `docs/2026-08-02-ai-delivery-audit-caso-1-c1.md` §4, commit `bd24074`).
- Incidente doble de canal: dos handoffs commiteados en la **rama candidata** en auditoría (`6242007`; aviso `5dea09e 07-31T19:23−06:00`: "los handoffs están entrando en la rama del candidato C1 — y el de esta ronda solo existe ahí"); tercera vez evitada con worktree (`9fa6e14`). Regla resultante en CLAUDE.md del Arquitecto: commit `67b8816`.

---

## C. Artefactos

### C1. Repos, ramas, PRs y SHAs

| Repo | Rama/PR | SHAs clave | Estado final |
|---|---|---|---|
| Agente-n8n | `feature/c1-contencion-gates-plano-aislado` (= PR Agente-n8n#3) | primer `ad85149 07-31T00:13−06:00`; final **`416d1987` 08-01T22:47−06:00** (42 commits en la rama) | **NO mergeada** — congelada como referencia del PASS ("un push invalida el PASS", handoff `293377f`). La instalación en STG fue **por API en la corrida**, no por merge |
| Agente-n8n | `c1-put-path-preparado` | `7c64156 07-31T21:34−06:00` | Cuarentena del build prematuro del PUT; no mergeada |
| Agente-n8n | `feature/issue-132-port-dual-safe` | último `6f1d394 07-31T09:29−06:00` | Sin actividad tras 07-31; no mergeada (contiene el handoff C1 original `fe0ec01`) |
| Agente-n8n | `stg` (espejo de exports) | `d4f8ab3`→`3981362 08-02T08:07−06:00` ("sync: drift detectado […] -- revisar") | Activa — contiene la huella viva de la corrida C1 (nodos `C1 Gate —`) |
| Agente-n8n | `feature/c1-cabeza-viva-invariante-a-la-pausa` | `02fd9ec` (citada en `cff33f7`) | Ref borrada; `02fd9ec` sobrevive dentro de la candidata |
| Dashboard | PR #2 | congelado `1373d1ab` | Apto offline (#140 c.5148715706); **UNKNOWN** estado del PR hoy (requiere `gh pr view`) |
| HYL-WAI | PR #145 (`c373ab11`, tooling CAS) | — | "NO forma parte de instalar C1 — permanece sin merge" (checkpoint del Arquitecto); sigue sin merge a 03-ago |
| HYL-WAI | `stg` | `4f0e7416` (congelado en checkpoint) | Referencia de la ventana |

### C2. ¿Contrato de interfaz escrito ANTES de implementar?

**HECHO** — **Sí a nivel de entregables**: el plan (`#140 c.5137216437 2026-07-30T23:12Z`, §7 "Artefactos ejecutables obligatorios") fija el contrato ANTES de la primera implementación (`ad85149`, 07-31): *"Los nombres siguientes son el contrato de entrega. Hoy no todos existen; la ausencia de cualquiera en su gate es NO-GO"* (incluye `build-isolated-core.js --manifest manifests/dual-core-test.json`, `verify-isolation.js`, `restore-manifest-stg.py`).

**HECHO** — **No a nivel de instalación**: `scripts/c1/manifests/plan-instalacion.json` aparece por primera vez en `86a9c09 07-31T20:40:36−06:00`, **junto con** la implementación de las barreras A/B (`109edf4`/`86df8cc`, 20:39–20:40 del mismo día) y 12 revisiones después hasta `416d198`. Los gates se implementaron 20 h antes que su manifest de instalación. Los 9 requisitos del checkpoint operativo (`#140 c.5149044773`) preceden al primer borrador de checkpoint por 4 minutos.

**HECHO** — Primeras incompatibilidades de interfaz documentadas (con su corrección): (a) el borrador de checkpoint atribuyó alcance vivo a un artefacto que solo instala la barrera B y citó el importador del Bug #10 — "error del Arquitecto", NO-GO operativo `#132 c.5149165789 08-01T02:20Z`, cabecera del propio borrador (`docs/iniciativas/c1-checkpoint-operativo-borrador.md`); (b) "el '8 nodos con webhookId → en realidad 16' y el orden 'periferia primero' (que resultó invertido)" (`f4bfa85`). **UNKNOWN** — coste en horas de cada corrección (no hay registro horario; las rondas B1–B13 que siguieron duraron en conjunto ~13 h de reloj, #132 c.5149097301→c.5152051722, pero incluyen más causas que estas dos).

### C3. Validaciones

**HECHO** — **Misma suite repetida (creciendo): 19 menciones registradas** de la suite offline n8n, todas consultables hoy: 71/71 (#140 c.5139921305) · 124/124 (c.5148066039) · 143/143 (c.5148827114) · 147/147 (c.5148961363, c.5149044773) · 219/219 (#132 c.5149876716) · 231/231 (c.5150052424) · 248/248 (c.5150183935) · 260/260 (c.5151470952) · 279/279 (c.5151680686) · 291/291 (c.5151822875) · 298/298 (c.5151883251) · 305/305 (c.5151951037) · 312/313 (c.5152030384) · 313/315 (c.5152051722) · 338/338 (c.5154925188) · 340/340 (c.5154997235) · 349/349 (c.5155176112) · 351/351 (c.5155289240) · 356/356 (c.5155455127, c.5155482965, c.5157632531).

**HECHO** — **Validaciones distintas registradas** (~15): gates n8n 43/43 (#140 c.5139921305); Dashboard 88/88 + gates 6/6 (c.5140031183), 89/89 (c.5148715706), congelado `1373d1ab` PASS (c.5149044773); Django SQLite "880 passed, 26 skipped" y manifest PG17 "83 passed" (c.5139480586); CI PR #145 verde (c.5149029086); canarios focales 9/9 (#132 c.5155482965); preflight Hostinger `PRECHECK_OK` (c.5154268653); prechecks 3a–3e con 3c "7/7" (c.5154417314); corrida 1: anti-TOCTOU 7/7, restore 7/7, 0/7 pausados post-restore (c.5154508007); corrida 2: pausa 7/7, B 7 POST, A 7 PUT, GET-only 7+7, cardinalidad 14 (c.5155576499); journal `errores:0` (c.5155662487); runner "56 → 0, cleanup 0" (c.5155482965).

**UNKNOWN** — Cuántas ejecuciones de validación existieron **solo en sesión** (sin registro): los journals y `build/` de las corridas están git-ignorados desde `28e6a16 07-31T14:04−06:00`; toda ejecución local no publicada en un comentario o informe es irrecuperable.

---

## D. Bloqueo final

### D1. Causa de no llegar a STG

**HECHO** — **La premisa es falsa: C1 SÍ llegó a STG.** Cinco artefactos: (1) corrida 1 viva con pausa real de los 7 ingress y restore 7/7 (#132 c.5154508007; el monitor precisa "Hubo 7 `deactivate` y 7 `activate`", c.5154563080); (2) corrida 2 "EJECUTADA — verde completo, contención instalada y acreditada en STG" con run-id `c1-20260802T051054-0453` (c.5155576499); (3) verificación del monitor "cardinalidad final 14, todos inactivos" (c.5155631752) y "estado final seguro/fail-closed" (c.5155678719); (4) cierre accountable citando la corrida (c.5157632531); (5) huella git en el espejo: 4 commits `sync: drift` del 08-02 con los nodos `C1 Gate —` (91+27+10+9 ocurrencias en los 4 exports, Agente-n8n `stg@3981362`).

**HECHO** — Lo que sí existió es un bloqueo del **cierre operativo limpio**, y su causa exacta fue **falta de evidencia** (clasificación del encargo): el tramo de productores/prechecks (`OK 1b/2/2b/3a`) del checkpoint no se ejecutó durante la corrida 2 (declaración de omisión, c.5155662487) → STOP del monitor ("corrida consumida; decisión al A humano", c.5155678719) → resuelto 6,23 h después por **decisión humana** del accountable aceptando la desviación "como excepción única" (c.5157632531). El monitor explicitó: "C1 no se cierra operativamente por el monitor" — el cierre fue humano.

### D2. Estado funcional HOY (2026-08-03)

**HECHO** — **Operativo (contención viva en STG)** según los artefactos disponibles: los 4 exports del espejo `stg` contienen los nodos `C1 Gate —` (default-deny) con `active:false` en los 4 workflows (commits `sync` del 08-02, verificados de nuevo el 08-02T20:23Z por el monitor: "los cuatro blobs de `3981362` tienen `active=false` […] fingerprints […] coinciden exactamente con `scripts/c1/manifests/plan-instalacion.json`", #132 c.5160178408). Los 7 clones `C1-AISLADO` quedaron como material de C2 (manifest C2 pinnea `"corrida_c1_observada": "c1-20260802T051054-0453"`, Agente-n8n `91e96cf`). Estado declarado en cierre: "plano vivo STG contenido default-deny + 7 clones aislados, todos active=false. Sin PROD tocado" (Arquitecto `004308a`).
**UNKNOWN** — Verificación independiente EN VIVO a fecha de esta auditoría (GET actual a la API de n8n STG): no ejecutada dentro de este trabajo.

### D3. Dictámenes finales (texto disponible)

**HECHO** — Declaración de omisión del Arquitecto (#132 c.5155662487 08-02T05:31:16Z, fragmento): el tramo de productores/prechecks "NO se ejecutó durante esta corrida"; journal `errores:0`, "0 incierto sin resolver".
**HECHO** — STOP del monitor (#132 c.5155678719 08-02T05:34:27Z, fragmento): "STOP por desviación del checkpoint — corrida consumida; decisión vuelve al A humano […] El estado final declarado es seguro/fail-closed: 0 activos, 7 vivos contenidos y 7 clones inactivos".
**HECHO** — Cierre del accountable (#132 c.5157632531 08-02T11:48:27Z, fragmento literal): "Por decisión directa de `@oilycoyote`, A humano, **acepto la desviación declarada en `5155662487` y cierro C1**. […] Se acepta como excepción única porque: 1. los ingress ya estaban desactivados antes de los POST/PUT; […] 4. repetir, completar retroactivamente o hacer rollback ahora añadiría más riesgo. […] La aceptación no convierte la comprobación posterior en precondición ni crea precedente para C2+".
Los textos completos viven en esos tres comentarios de `aguayo-co/HYL-WAI#132` (consultables hoy).

---

## E. Descomposición del esfuerzo

### E1. Construcción nueva vs retrabajo

**HECHO** — Iteraciones totales: **24 rondas candidato→dictamen** (4 de entrega offline A1–A4, 13 de checkpoint operativo B1–B13, 7 de re-run D1–D7) **+ 2 corridas vivas**. Dictámenes FAIL/NO-GO/NO-PASS: **18**; PASS: 6. (Detalle SHA-a-SHA con referencias: tablas de la sección 5 del barrido GitHub, transcritas en B1.)

**ESTIMACIÓN** (base: clasificación de los 42 commits de la rama candidata por su propio mensaje) — Construcción nueva: ~9 commits (`ad85149` gates+plano; `109edf4`/`86df8cc`/`86a9c09` barreras A/B+manifests; `7c64156`/`efd3c60` PUT; `464dbd4` CLI viva; `e7f3a78` runbook; `601a845` pin 2.28.7). Corrección/hardening en respuesta a dictámenes: ~33 commits (mensajes "fix(c1)… (FAIL/P1/STOP c.NNNN)" — lista completa en la cronología). Ratio ≈ **1:3,7 construcción:corrección por commits**. En **horas**: UNKNOWN — no existe registro horario por commit; los timestamps solo acotan.

**HECHO** — Retrabajo declarado explícitamente en los artefactos (selección literal): "el checker se auto-validaba: demostrado" (`944cd96`/informe `7df5d89`); "la 340/340 anterior no era hermética" (`161d691`); "las líneas vivas generadas dejan de ser un DRY-RUN verde" (`416d198`); "el defecto también afectaba a la barrera A (latente)" (`cff33f7`); "pusheé al candidato 5 min después del freeze por no re-fetchear" (`88b1d27`); "construiste el camino PUT 5 min después de que mi handoff lo prohibiera" (`f4bfa85`); "el sed anterior no acertó" (Arquitecto `0b07495`); "omití el tramo de productores/prechecks (error del Arquitecto)" (Arquitecto `6527cbd`).

### E2. El momento donde C1 se torció (único evento irreversible según artefactos)

**HECHO** — El único evento declarado **irreversible** por el propio proceso fue el STOP de la corrida 1 (08-02T01:49:01Z, #132 c.5154508007): "la excepción y GO anteriores quedaron **consumidos**" (c.5154563080) — obligó a nueva ruta mínima, nuevo ciclo de 7 rondas (D1–D7), nueva enmienda de autorización (c.5154662330) y segunda corrida. Causa técnica confirmada por el monitor: "`pausa → B` es imposible en `5fcc060`" — la guarda anti-TOCTOU del artefacto miraba `active`, que la propia pausa acababa de cambiar (fix: `02fd9ec` "la guarda anti-TOCTOU del FUENTE deja de mirar `active`").
**HECHO** — Qué información faltaba en ese instante: que el orden pausa→instalación invalidaba la precondición de la guarda — un defecto de interacción **solo observable en vivo** (los 315 tests offline del candidato eran verdes; el informe `cff33f7` añade que "el defecto también afectaba a la barrera A (latente)").
**UNKNOWN** — Si alguien tenía esa información antes de la corrida: ningún artefacto la muestra anticipada por ninguno de los actores (ni dictámenes, ni handoffs, ni tests la cubrían).

---

## F. Contrafactual asistido (root causes del resumen previo vs evidencia)

**F1a. "Ausencia de Change transversal" → CONFIRMADO con matiz.** 13 cambios de alcance/criterio en ~36 h (tabla A3), 12 introducidos por el lado accountable, varios DESPUÉS de entregas conformes al criterio anterior (filas 4, 5, 10). El matiz: cada cambio está escrito, fechado y acusado — el proceso de cambio existió y fue trazable; lo que no existió es estabilidad del criterio (la DoD operativa se terminó de definir 26 h después del GO de construcción — c.5138861034 → c.5149044773).

**F1b. "Integración tardía" → CONFIRMADO.** Todo el ciclo A/B/D fue offline por diseño (delimitación del GO, c.5139480586); el primer contacto del artefacto con el entorno real fue la corrida 1 (08-02T01:49Z), que falló por un defecto de interacción invisible offline (E2) tras 17 rondas y 315 tests verdes. El único precheck vivo previo (Hostinger, c.5154268653) fue 1 h antes de la corrida.

**F1c. "Handoffs no verificables" → MATIZADO.** Los handoffs SÍ quedaron en git (35 + 28 informes, todos consultables — sección B3): el canal es verificable. Lo que la evidencia confirma son **fallos de fidelidad y de sincronía del canal**: valores pre-fix en el primer handoff (`bd24074` §4), afirmaciones relayadas sin verificar ("8→16 nodos", orden "invertido", `f4bfa85`), un handoff leído tarde (PUT construido "5 min después" de prohibirse), y 2 handoffs contaminando la rama auditada (`5dea09e`, `6242007`).

**F1d. "Estado fragmentado" → CONFIRMADO.** Evidencia: candidato restaurado a `86a9c09` tras build prematuro (`7a1e995`); 6 órdenes RE-CONGELAR + 2 congelaciones + 1 congelación-PASS (26 % de los handoffs son gestión de estado); "head avanzó silenciosamente" detectado por el monitor (c.5151359011); push post-freeze "por no re-fetchear" (`88b1d27`); un SHA retirado (`fdc4ed6`, c.5155066043); una rama de trabajo borrada sin ref (`feature/c1-cabeza-viva…`); journals de corrida solo en la máquina del operador (git-ignorados, `28e6a16`).

---

## G. Integridad de esta auditoría

### G1. Preguntas con UNKNOWN y artefacto necesario

| # | UNKNOWN | Artefacto que lo resolvería |
|---|---|---|
| 1 | Petición conversacional previa al plan escrito (A1) | Logs de sesión de Claude Code (no persistidos entre máquinas) |
| 2 | Horas-persona de desarrollo y de cada corrección (C2, E1) | Registro horario que nunca existió; los timestamps de commit solo acotan |
| 3 | Validaciones ejecutadas solo en sesión (C3) | Journals/`build/` locales (git-ignorados desde `28e6a16`) en la máquina del operador |
| 4 | Verificación en vivo del estado STG hoy (D2) | GET actual a la API de n8n STG (`https://n8n-xlqk.srv1810257.hstgr.cloud`) |
| 5 | Número/contenido de interacciones humano↔agente en sesión (B3) | Logs de sesión |
| 6 | Origen del "377/377" y "14/14" atribuidos a C1 | Son cifras de la era C2 (suite C1 ampliada a 377 dentro de la rama C2; 14/14 = gate negativo C2, `d90eb8e`); el artefacto que las mezcló con C1 sería el resumen previo |
| 7 | Estado actual de los PR Agente-n8n#3 y Dashboard#2 como objetos | `gh pr view` de ambos |
| 8 | Historia exacta de la rama borrada `feature/c1-cabeza-viva-invariante-a-la-pausa` | Reflog remoto (no disponible) |
| 9 | Desglose P0/P1/P2 uniforme de cada FAIL de fases B/D | Transcripción completa de cada dictamen (los cuerpos existen en #132; no todos fueron transcritos aquí) |
| 10 | Contenido del Handbook / texto íntegro de SRC-ALBERTO-C1-001 | El propio Handbook (no accesible desde este entorno; esta auditoría trabajó contra las 7 cifras citadas en el encargo) |

### G2. Discrepancias con las cifras del resumen previo

| Cifra previa | Hallazgo reproducible | Veredicto |
|---|---|---|
| "30 h duración" | Plan→cierre: 07-30T23:12Z → 08-02T11:48Z = **60,6 h**; GO→cierre = 56,5 h; primer artefacto git→cierre = 54,6 h. La cifra "~31h" aparece en el doc de cierre del Arquitecto (`004308a`: "FIN DE LA MARATÓN C1: ~31h (28 jul #132 → 2 ago 11:48…)") — pero su propio paréntesis abarca 5,4 días; la base de cálculo de ese "~31h" es UNKNOWN. Probable origen de la cifra del resumen | **No reproducible** como duración calendario |
| "20 h desarrollo" | Sin registro horario. Ventana de commits de la candidata: 07-31T00:13 → 08-01T22:47 (−06:00) = 46,6 h de calendario con 42 commits | **No reproducible**; UNKNOWN |
| "11 h espera" | Esperas >1h medibles en issues: **39,75 h** (8 episodios, B2); una sola espera (dictamen conjunto) fue de 15,4 h | **Discrepante** (sub-cuenta ~3,6×) |
| "23 iteraciones" | **24 rondas** candidato→dictamen + 2 corridas vivas (18 FAIL, 6 PASS), todas con SHA y referencia | **Aproximadamente correcta** (−1) |
| "26 handoffs" | **35 handoffs C1** + 28 informes de respuesta (git, `main` de Agente-n8n) | **Discrepante** (sub-cuenta) |
| ">60 validaciones" | **34+ registradas** (19 repeticiones de la misma suite + ~15 distintas); si se cuentan las ejecuciones locales no publicadas la cifra podría superarse, pero eso es irrecuperable (G1.3) | **No reproducible** tal cual; registradas: 34+ |
| "sin despliegue final a STG" | **REFUTADA** con 5 artefactos (D1): la corrida 2 instaló y acreditó la contención en STG; el cierre fue por excepción aceptada, no un no-despliegue. Matiz que pudo originarla: la rama candidata NO se mergeó (la instalación fue por API) y el cierre no fue un PASS operativo limpio del monitor | **Falsa** |

### G3. Autoevaluación

Método de conteo: etiquetas `HECHO`/`ESTIMACIÓN`/`UNKNOWN` explícitas del cuerpo + filas de las 7 tablas de evidencia (cada fila lleva ≥1 referencia y computa como hecho). Referencias únicas citadas: comentarios `c.NNNNNNNNNN` de GitHub + SHAs de git + ficheros nombrados.

- Hechos etiquetados y filas de tabla con referencia: **~145** (34 HECHO etiquetados + ~111 filas de tabla).
- Estimaciones: **1** (E1, ratio construcción:corrección por commits, base explícita).
- UNKNOWN: **10** declarados (G1) + 4 en línea (A1, C2, C3, D2/E2).
- Referencias únicas citadas: **~130** (≈75 comentarios de GitHub distintos + ≈50 SHAs/ficheros).
- **Respaldado por artefactos: ~97 %** del contenido afirmativo; el resto es la estimación E1 (marcada) y los UNKNOWN (que no afirman).

Limitación principal declarada: los cuerpos completos de los 24 dictámenes no se transcribieron íntegros (sí sus identidades, fechas, resultados y fragmentos clave); y ninguna cifra de HORAS-persona es reproducible — solo el calendario lo es.

```yaml
audit:
  source_id: SRC-ALBERTO-C1-002
  supersedes_integrity_of: SRC-ALBERTO-C1-001
  author: Agente-Arquitecto
  date: 2026-08-03
  facts_count: 145
  estimates_count: 1
  unknowns_count: 14
  artifacts_cited: 130
  reproducible_from_artifacts: 97%
```
