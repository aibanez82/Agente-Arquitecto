# AI Delivery Audit — Caso de Estudio #1

**Contención C1 / port-132 "Dual" — instalador default-deny de plano vivo (barreras A/B)**

> Auditor: Arquitecto-IA-Qualitas (rol de Engineering Auditor / Platform Engineering para este documento).
> Fecha del informe: 2026-08-02.
> Alcance: **cómo fluye realmente un cambio** por el ecosistema de delivery multi-agente — tiempos, contexto, handoffs, esperas, retrabajo, bugs, quién espera a quién, qué información faltó. NO es un análisis de funcionalidad.
> Base: solo evidencia leída (repos, commits, ramas, docs, handoffs, comentarios de issues). Lo indeterminable se marca **"no determinable"**.
> Este es el primer capítulo de una serie "AI Delivery Audit" que alimenta un futuro "AI Delivery Standard".

---

## 0. Justificación de la selección del caso

Prioridad de selección aplicada (la del enunciado):

1. **Cambio abierto más largo actualmente.** #132 abierto el 2026-07-28T03:12:27Z por `oilycoyote`; el sub-caso concreto del instalador default-deny arrancó el 2026-07-31 ~21:52Z (primer NO-GO de Juan `5147782653`) y **sigue abierto** al cierre de este informe (2026-08-02 04:06Z, HOLD esperando el PASS del monitor v3 sobre `161d6913`). ~30 h de operación intensiva continua; el issue madre lleva ~5 días. Es el cambio vivo más largo del ecosistema.
2. **Más repos afectados.** Toca 4 repos simultáneamente: `aibanez82/Agente-n8n` (artefacto principal), `aibanez82/Dashboard_seguroautoqualitas` (guarda default-deny), `aibanez82/Agente-Arquitecto` (checkpoints, runbook, cronología) y `aguayo-co/HYL-WAI` (Django #145 adyacente + issues de gobernanza #132/#140).
3. **Más iteraciones Alberto↔Juan.** ~18 rondas FAIL/PASS offline del monitor de Juan + ~5 hitos vivos (GO, STOP, 3 enmiendas de gobernanza). Ningún otro cambio del ecosistema se acerca.
4. **Más representativo del proceso normal.** Ejercita entero el modelo: Arquitecto (N2) orquesta, ejecutores (N3) construyen, monitor de Juan audita, humanos (Alberto R / Juan A) deciden los gates. Es el caso canónico del modelo de delivery, no un outlier.

**Conclusión:** cumple las 4 prioridades. Es el caso correcto para el primer capítulo.

---

## 1. Información general

| Campo | Valor |
|---|---|
| **Nombre** | Contención C1 (barreras A/B) del rollout "Dual" — instalador/verificador default-deny del plano vivo n8n |
| **Objetivo funcional** | Antes de habilitar el modo "Dual" (Django+n8n operando la conversación WhatsApp en paralelo con hand-off humano/Metepec), **contener** el plano n8n vivo de STG: barrera A = poner el plano vivo en *default-deny* (0 conectores alcanzables sin gate) sin cambiar su identidad; barrera B = crear 7 clones aislados (`active:false`) para probar Dual sin tocar los 7 workflows vivos. Objetivo de negocio: no romper el bot de conversión de leads (funnel Google Ads → póliza) al desplegar Dual. |
| **Business capability afectada** | Conversión de leads por WhatsApp (los 7 workflows n8n vivos: Main, Payment, Retomar, Atención Humana, Metepec Liberar/Registrar, Issue Policy Guard) |
| **Fecha de inicio** | Sub-caso instalador A/B: 2026-07-31 ~21:52Z (primer NO-GO). Issue madre #132: 2026-07-28. |
| **Estado actual (2026-08-02 04:06Z)** | **Abierto, HOLD.** Una única corrida viva ejecutada (2 ago 01:40–01:41Z): pausa verde, barrera B → STOP fail-closed. STG restaurado. SHA correctivo `161d6913` entregado y verificado (hermético 349/349). Esperando PASS consolidado del monitor v3 → "condiciones satisfechas" (pre-autorización `5154662330`) → segunda corrida. **Ningún despliegue llegó a STG.** |
| **Personas** | Alberto (`aibanez82`) — operador, R (responsible). Juan (`oilycoyote`) — A (accountable), guardia/STOP, dueño de `aguayo-co/HYL-WAI`. |
| **Agentes** | Arquitecto-IA (N2, orquesta + verifica + redacta checkpoints); Agente n8n (N3, construye el instalador); Agente Dashboard (N3, construye la guarda); "monitor v2/v3" de Juan (auditor automático PASS/FAIL). |
| **Repos** | `Agente-n8n`, `Dashboard_seguroautoqualitas`, `Agente-Arquitecto`, `aguayo-co/HYL-WAI`. |

---

## 2. Repositorios afectados

### 2.1 `aibanez82/Agente-n8n` — artefacto principal (instalador A/B)
- **Motivo:** contiene el instalador/verificador de las barreras A y B (`scripts/c1/`), el runner offline, la suite de tests y el runbook de ventana.
- **Owner:** Alberto (repo); construido por el Agente n8n bajo dirección del Arquitecto.
- **Ramas:** `feature/c1-contencion-gates-plano-aislado` (candidato del PR #3), `feature/c1-cabeza-viva-invariante-a-la-pausa` (fix del STOP, luego fast-forward), `feature/c2-matriz-nucleo-dual` (C2 en rama aparte), `c1-put-path-preparado` (cuarentena del PUT prematuro `7c64156`), `main` (informes/handoffs).
- **PR:** `Agente-n8n#3` (base `stg`, head `feature/c1-contencion-gates-plano-aislado`, abierto 2026-07-31T22:37:09Z, **OPEN**). Merge-base verificado `stg@40fe572`.
- **Cadena de SHA candidatos (relevantes):** `ad85149`/`b76a546` → `fe456b0` → `b2c89ba` → `4e2118c` → `86a9c09` → (`7c64156` cuarentena) → `28167b6` → `601a845` → `464dbd4` → `7c877a7` → `871221400` → `1c30a00` → `78442a4` → `4e8acea` → `8b2c8c2` → `d651b22` → `944cd96` → **`5fcc06099` (2º PASS técnico → base del GO)** → `02fd9ec` → `415ee46` → `e7f3a78` → **`161d6913` (actual)**. ≈23 SHAs candidatos.
- **Estado:** PR abierto, candidato congelado en `161d6913`, HOLD.
- **Dependencias:** consume identidad/fingerprints de los 7 workflows vivos de STG; depende de la versión n8n fijada (2.28.7, tag `955be3ef`); barrera A (PUT) contingente a decisión A/B de Juan.

### 2.2 `aibanez82/Dashboard_seguroautoqualitas` — guarda default-deny
- **Motivo:** el Dashboard es un producer/escritor indirecto hacia n8n (webhook proactivo). C1 exige acreditar que sus gates (`GATE_TAKE/DISPATCH/METEPEC`) están default-deny.
- **Owner:** Alberto.
- **Rama:** `c1-gates-api-default-deny`.
- **PR:** `Dashboard_seguroautoqualitas#2` (OPEN, abierto 2026-07-31T22:04:22Z). SHA candidato **`1373d1a`** (congelado; PASS técnico de Juan). Cadena: `07324f4` (gates iniciales) → `1373d1a` (fix P0: `next@14.2.35` GHSA-f82v-jwr5-mffw + claim propio antes de fetch) → `46500d2` (doc-only, corrige overreach del mensaje que el monitor v3 marcó FAIL `5154995082`).
- **Estado:** **PASS técnico, congelado en `1373d1a`, prohibido cualquier push**. El default-deny *efectivo* (403 GATE_DENIED autenticado) NO se pudo acreditar offline (ver Bug 5.8).
- **Dependencias:** deployment Vercel Preview inmutable `dpl_E5yQGegYSXZqbNy38TBi4j69U2gK` (projectId `prj_CU5Qqp3BK2B31HVytLeEOBuSlnrU`, org `team_MyB7xWdzJZcEPzeK7rlHMFe8`); `DATABASE_URL` NO scopeada a este Preview → login 500 (raíz del bloqueo 3f).

### 2.3 `aibanez82/Agente-Arquitecto` — gobernanza, checkpoints, runbook
- **Motivo:** aloja la cronología play-by-play, los checkpoints operativos (`c1-checkpoint-operativo-AB-v2.md`, `c1-checkpoint-operativo-borrador.md`), el baseline freeze (`c0-baseline-freeze-opcion-c.md`), el runbook C2 (`c2-matriz-nucleo-dual-runbook-borrador.md`) y el plan de ejecución (`2026-07-28-plan-ejecucion-132-135-lado-nuestro.md`).
- **Owner:** Alberto / Arquitecto.
- **Estado:** activo. **Hallazgo de gobernanza:** el monitor de Juan **lee este repo casi en tiempo real** (citó `Agente-Arquitecto@01eea1c`, comentario `5147924496`) → todo commit aquí es comunicación pública de facto hacia el lado de Juan.

### 2.4 `aguayo-co/HYL-WAI` — Django + issues de gobernanza (adyacente)
- **Motivo:** issues #132 (C1, autor Juan), #140 (decisión de rollout, CLOSED 2026-07-30, sede de las enmiendas RACI), #135/#128/#143 (contexto). Django adyacente: **PR #139 MERGED a `stg` el 2026-07-29** (`fix: harden issue 132 pre-window contracts`) y **PR #145 OPEN** (`feat(rollout): add guarded Django mode transition`, wrapper CAS shadow↔dual, `c373ab1`, **congelado, fuera de la instalación C1**).
- **Owner:** Juan.
- **Estado:** #132 abierto (sede de checkpoints y GO); #140 cerrado tras servir de sede a 3 enmiendas de gobernanza; #145 congelado.
- **Dependencias:** Alberto puede abrir/comentar issues aquí pero **no** puede pushear código; el fix Django lo ejecuta Juan.

---

## 3. Cronología completa (con distinción dev vs espera)

> Zona horaria: UTC. "Dev" = construcción del ejecutor + verificación independiente del Arquitecto. "Espera" = tiempo en que la pelota estaba en el otro lado (monitor de Juan, o gate humano). Los huecos idle NO se omiten.

| # | Fecha/hora (UTC) | Actor | Acción | Artefacto | ~Dev activo | ~Espera | Dependía de | Resultado |
|---|---|---|---|---|---|---|---|---|
| 1 | 07-28 03:12 | Juan | Abre #132 (integrar hardening Dual) | issue #132 | — | — | — | Contexto |
| 2 | 07-29 21:58 | Juan | Merge PR Django #139 a `stg` | `stg` Django | — | — | — | Pre-contratos endurecidos |
| 3 | 07-31 21:16 | Juan | Merge PR #142 (17 archivos) a `stg` → Heroku v212 (`4f0e741`) durante freeze | STG Django | — | — | — | Deploy vivo durante freeze; **auto-clasificado ex post** (`5147660691`) |
| 4 | 07-31 21:52 | Juan | **NO-GO C1 offline** (`5147782653`): 5 bloqueantes n8n + 2 P0 Dashboard | dictamen | — | — | entregas iniciales | Arranca el ciclo |
| 5 | 07-31 22:04 | Ejecutor Dashboard | Abre PR #2, SHA `1373d1a` (fix P0) | PR #2 | ~1 h | — | #4 | PASS Arquitecto |
| 6 | 07-31 22:37 | Ejecutor n8n | Abre PR #3, SHA `fe456b0` (5 bloqueantes + P2) | PR #3 | ~1 h | — | #4 | PASS Arquitecto (124/124) |
| 7 | 08-01 00:56 | Juan | Re-revisión (`5148715706`): Dashboard PASS; n8n NO-GO 1 P1 (2 bypasses SQL) | dictamen | — | ~2 h | #6 | Nueva iteración |
| 8 | 08-01 01:5x | Ejecutor n8n | `b2c89ba` (P1 SQL + 4 P2), 143/143 | PR #3 | ~1 h | — | #7 | PASS Arquitecto |
| 9 | 08-01 02:3x | Juan | Focal (`5148866994`): P1 aceptado, queda P2 redacción `run.log` | dictamen | — | ~0.5 h | #8 | Iteración |
| 10 | 08-01 03:xx | Ejecutor n8n | `4e2118c` (P2 redacción), 147/147 | PR #3 | ~0.5 h | — | #9 | PASS Arquitecto |
| 11 | 08-01 03:1x | Juan | **C1 ACEPTADA offline** (`5149044773`) de los 3 frentes | dictamen | — | — | #10 | Falso final (ver #12) |
| 12 | 08-01 03:2x | Juan | **NO-GO OPERATIVO** (`5149165789`): la contención VIVA no existe — el "instalador" era el harness offline; falta barrera A + instalador de 7 clones | dictamen | — | — | #11 | **Reset de alcance = ingeniería nueva** |
| 13 | 08-01 03:4x | Ejecutor n8n | `86a9c09`: barrera A (vivo 56→0) + instalador B, 190/190 | PR #3 | ~2 h | — | #12 | PASS Arquitecto |
| 14 | 08-01 03:34 | Ejecutor n8n | `7c64156`: construye camino PUT **5 min tras el handoff de límite** — prematuro | rama cuarentena | ~0.5 h | — | — | Autocorregido; a `c1-put-path-preparado` |
| 15 | 08-01 04:03 | Juan | **Decide A** (`5149704373`), FAIL: candidato único A+B, cerrar camino vivo, checkpoint 9 mínimos | dictamen | — | ~varias h (audita A/B) | #13 | A decidida |
| 16 | 08-01 04:2x–04:3x | Ejecutor n8n | `28167b6` (A+B unificado, 216/216) → `601a845` (pin n8n 2.28.7, 219/219) | PR #3 | ~2 h | — | #15 | PASS Arquitecto |
| 17 | 08-01 05:5x | Ejecutor n8n | `464dbd4`: CLI viva real inerte + preflight publicación, 231/231 | PR #3 | ~1.5 h | — | #16 | Checkpoint posteado (`5150052424`) |
| 18 | 08-01 05:53 | Juan | FAIL `5150070342`: rollback no recuperable, stop/target, checkpoint incompleto | dictamen | — | ~0.5 h | #17 | Iteración |
| 19–29 | 08-01 06:0x → 15:15 | Ejecutor + Juan | **~11 rondas de hardening** del checkpoint/CLI: `7c877a7`→`871221400`→`1c30a00`→`78442a4`→`4e8acea`→`8b2c8c2`→`d651b22`→`944cd96`. FAILs `5150210658`, `5151490235`, `5151680686`, `5151822875`, `5151883251`, `5151951037` | PR #3 + checkpoint | ~6 h agregadas | ~3 h agregadas | cada FAIL | Convergencia lenta |
| 30 | 08-01 15:15 | Juan | **PASS técnico offline** (`5152030384`) sobre `944cd96` | dictamen | — | — | #29 | Técnico casi cerrado |
| 31 | 08-01 15:2x | Ejecutor n8n | `5fcc0609`: hornea commit Vercel + orgId, 315/315 — push tras el PASS | PR #3 | ~0.5 h | — | — | 2º PASS de Juan (`5152051722`) |
| 32 | 08-01 15:36 → 23:19 | Juan ↔ Alberto | **Gate humano RACI/suplente** (`5152112808` → enmienda `5153952626`): operador único. **~7.7 h de espera humana** | issue #140 | — | **~7.7 h** | decisión de Alberto + escritura de Juan | Enmienda RACI (no es GO) |
| 33 | 08-01 23:24 → 08-02 00:01 | Juan ↔ Alberto | Ventana inmediata en vez de lunes; Alberto confirma "AHORA" | #140/#132 | — | ~0.6 h | disponibilidad Alberto | Precondición cerrada |
| 34 | 08-02 00:01 | Juan | **🟢 GO OPERATIVO C1** (`5154091214`) sobre `5fcc06099` | GO | — | — | #32/#33 | Sesión viva |
| 35 | 08-02 00:49 | Juan | Paso 2 preflight Hostinger: publicación=síncrona (`5154268653`) | evidencia | ~0.3 h | — | #34 | Verde |
| 36 | 08-02 ~01:2x | Alberto | Prechecks 3a–3e verdes; **3f bloqueado** (Dashboard 403 no producible) | evidencia | ~0.5 h | — | #34 | HOLD |
| 37 | 08-02 01:26 | Alberto | Reporta HOLD 3f a Juan (`5154417314`), pide decisión A/B | comentario | — | ~0.1 h | #36 | Espera dictamen |
| 38 | 08-02 01:32 | Juan | **Enmienda GO**: acepta opción A para 3f (acreditación config) (`5154440416`) | enmienda | — | — | #37 | HOLD levantado |
| 39 | 08-02 01:40 | Alberto | Paso 4.1 PAUSA journalizada VERDE (run-id `c1-...T014026-c975`) | mutación viva | ~0.05 h | — | #38 | 7 ingress pausados |
| 40 | 08-02 01:41 | Alberto | Paso 4.2 barreras → **STOP fail-closed en B** (`cabeza-viva-cambiada`) | mutación viva | ~0.05 h | — | #39 | 0 clones, 0 vivos tocados; restaurado |
| 41 | 08-02 01:49 | Alberto/Arq | Reporte STOP a #132 (`5154508007`) + handoff defecto (`c2d6dea`) | reporte | — | — | #40 | Excepción consumida |
| 42 | 08-02 02:00–02:02 | Ejecutor + Juan | Fix `02fd9ec` (vía a) ↔ Juan FAIL 6 puntos (`5154563080`) casi simultáneos | PR #3 | ~1 h | — | #41 | Convergen |
| 43 | 08-02 02:24 | Juan | **Enmienda #140** (`5154662330`): delega a su monitor la autorización de acciones vivas; **C1 re-run pre-autorizado** bajo 7 condiciones | enmienda | — | — | — | Elimina un gate humano por corrida |
| 44 | 08-02 03:00–03:30 | Ejecutor + Arq | `415ee46` (5 puntos ruta mínima) → drift `e7f3a78` (340/340) → checkpoint re-run `5154925188` | PR #3 | ~2 h | — | #42/#43 | HOLD monitor |
| 45 | 08-02 03:33 | Juan | FAIL consolidado `5154995079` (normalizar active, orden runbook, suite hermética) | dictamen | — | — | #44 | Iteración |
| 46 | 08-02 ~04:00 | Ejecutor + Arq | `161d6913`: 3 de código cerrados; **suite hermética 349/349** (corrige 340/340 no hermético); mis 2 partes en checkpoint `5155176112` | PR #3 | ~1 h | — | #45 | PASS Arquitecto |
| 47 | 08-02 04:06 → ahora | — | **HOLD**: espera PASS del monitor v3 sobre `161d6913` → "condiciones satisfechas" → 2ª corrida | — | — | **en curso** | monitor v3 | Abierto |

---

## 4. Handoffs

> Convención del ecosistema: los handoffs se dejan en el repo del ejecutor (`<repo>/handoffs/`), commiteados en `main`, con ruta absoluta. El Arquitecto redacta; el ejecutor detecta por "fichero sin informe de respuesta".

**Volumen (verificado en `Agente-n8n/handoffs/`):** ≈24 handoffs C1 Arquitecto→Agente n8n + ≈2 Arquitecto→Dashboard, entre 2026-07-31 y 2026-08-02. Cada uno con su informe de respuesta del ejecutor en `Agente-n8n/docs/2026-08-0*-informe-*.md`.

| Handoff clave | Origen→Destino | Motivo | Info entregada | Info faltante / aclaración posterior |
|---|---|---|---|---|
| `2026-07-31-pr-c1-contencion-gates-a-stg.md` (`9a41092`) | Arq→n8n | Corregir 5 bypasses + abrir PR #3 | SHAs, valores esperados 71/71 | Valores esperados eran **pre-fix**; el PR tuvo que explicar cada delta (sinks 24→22, gates 43→54) |
| `2026-08-01-barrera-A-decidida-candidato-unico-AB.md` (`904402b`) | Arq→n8n | Integrar A+B tras decisión A de Juan | 6 correcciones de hardening | — |
| `2026-08-02-c1-defecto-orden-pausa-B-anti-toctou.md` (`c2d6dea`) | Arq→n8n | Fix del STOP vivo | Causa raíz + 2 vías (a/b) | Vía (b) descartada luego: el defecto era latente también en A |
| `2026-08-02-c1-ruta-minima-segura-juan-6-puntos.md` (`2412d7e`) | Arq→n8n | Reconciliar `02fd9ec` con los 6 puntos de Juan | 4 puntos pendientes | — |
| `2026-08-02-c1-fail-consolidado-5154995079.md` (`588fe80`) | Arq→n8n | Normalizar active + orden + hermetismo | — | — |

**Handoffs problemáticos (incidentes de canal):**
- 3× el clon local del Arquitecto estaba en la **rama candidata** al commitear el handoff → contaminó el candidato bajo revisión (`e6ee2e9` el 31 jul; `6242007` el 1 ago; evitado la 3ª vez con **worktree temporal**, `9fa6e14`). El monitor de Juan detectó el 1º en ~4 min (`5147718871`).
- Handoff↔informe: el Arquitecto verificó **código** sin leer el **doc de entrega** del ejecutor → se le escaparon 2 contratos de API (los 7 IDs no fijables a priori; contradicción PUT de barrera A). Lección registrada: leer el doc de entrega, no solo el código.

---

## 5. Bugs y defectos (dónde, quién, fase, causa raíz, impacto en tiempo)

| # | Defecto | Quién detectó | Fase | Repo | Causa raíz | Impacto tiempo |
|---|---|---|---|---|---|---|
| 5.1 | **STOP vivo: `cabeza-viva-cambiada`** | Corrida viva (fail-closed) | Ejecución viva (Paso 4.2) | Agente-n8n | Defecto de **orden**: B verifica la cabeza viva contra un fingerprint congelado calculado con `active:true`; la pausa 4.1 puso `active:false` → n8n bumpea active/versionId → fingerprint no coincide | Abortó la única corrida viva; +varias rondas (`02fd9ec`→`415ee46`→`e7f3a78`→`161d6913`) |
| 5.2 | **Cliente falso publica sobre workflows pausados** | Regresión integrada (destapada al construir `415ee46`) | Dev/test | Agente-n8n | El ClienteFalso de tests no respetaba el contrato de n8n (`workflow.service.ts:553`: la puerta es `activeVersionId`, que `deactivate` deja null) | Enmascaraba el defecto 5.1; su fix es prerequisito de una regresión honesta |
| 5.3 | **Suite no hermética (340/340 vs 349/349)** | Juan (`5154995079`) + Arquitecto | Verificación | Agente-n8n | La suite dependía de `.vercel/repo.json` del clon de Alberto (máquina-dependiente); en el host de Juan fallaba/variaba | Falsos PASS del Arquitecto; obligó a mover el enlace Vercel a un preflight + guardián de hermetismo |
| 5.4 | **Checkpoint citó instalador inexistente** | Juan (`5149165789`) | Redacción checkpoint | Agente-Arquitecto | El Arquitecto conflacionó `import-stg-workflow.py` (importador del Bug #10) y el harness offline con "instalación viva" | Reset de alcance = ingeniería nueva (barrera A + instalador de 7 clones); reajustó el plazo |
| 5.5 | **Los 7 IDs no se pueden fijar a priori** | Doc de entrega del ejecutor | Diseño | Agente-n8n | La API n8n asigna `id` en el POST (`id: readOnly`); lo determinista es nombre+fingerprint | Invalidó el bloqueante 2 de Juan como literal; el Arquitecto lo detectó tarde (verificó código, no el doc) |
| 5.6 | **Contradicción de gobernanza: barrera A exige PUT sobre los 7 vivos** | Doc de entrega del ejecutor | Diseño/gobernanza | Agente-n8n / #132 | Instalar A = PUT sobre los 7 workflows vivos, justo lo que el handoff/Juan prohibían | Bloqueó la decisión A/B; +rondas de análisis de riesgo del PUT |
| 5.7 | **Placeholder Django en precheck** (`<comando-de-lectura-de-la-flag>`) | Juan (`5151680686`) | Verificación | Agente-n8n | El Arquitecto reportó "279/279 PASS" inspeccionando solo las primeras 40 líneas del guion (parte WhatsApp), no la Django | Ronda extra; **gap de verificación asumido** por el Arquitecto |
| 5.8 | **3f no producible: Dashboard login 500** | Alberto + Arquitecto | Ejecución viva (precheck) | Dashboard | `DATABASE_URL` scopeada a "Preview (stg)" → ausente en la rama del Preview congelado → `auth.js` SELECT falla → catch 500 → nunca se llega al 403 gate | Bloqueó 3f; requirió enmienda de GO de Juan (opción A, `5154440416`) |
| 5.9 | **Checker de target auto-validante** | Juan (`5151951037`) | Verificación | Agente-n8n / Dashboard | La guarda comparaba contra las mismas vars con `${VAR:-default}` → se auto-validaba (mismo bypass de target que C1 prohíbe) | Ronda extra (target Vercel inmutable) |
| 5.10 | **Rollback content-only** (ignora settings/active/publicación) | Juan (múltiples FAILs) | Verificación | Agente-n8n | El rollback comparaba solo `fingerprintContenido` → un cambio ajeno pasaba y recibía PUT | ~3 rondas de endurecimiento (activeVersionId null, estado pretendido completo) |
| 5.11 | **PUT prematuro** (`7c64156`) | Autodetección | Dev | Agente-n8n | Ejecutor construyó el camino PUT 5 min tras el handoff de límite | Cuarentena + force-push; **pero destapó 2 hallazgos materiales** (orden llamadores-primero; verificación por partes) |
| 5.12 | **Auto-deploys de plataforma no considerados** | Monitor de Juan (`5147884147`, `5147924496`) | Gobernanza | Dashboard/HYL-WAI | Git→deploy automático (Vercel Preview en cada push; Heroku en `stg`/`main`) no contemplado al declarar "sin deploy" | Clasificaciones ex post cruzadas; sin daño técnico |

---

## 6. Validaciones

Patrón por cada SHA candidato (≈23 SHAs): **triple validación** = tests del ejecutor + verificación independiente del Arquitecto (worktree/clon aislado) + reproducción del monitor de Juan.

| Tipo | Quién | Ejemplo/evidencia | Resultado |
|---|---|---|---|
| **Unit/suite** | Ejecutor n8n | 124→143→147→190→216→219→231→248→260→279→291→298→305→313→315 → (STOP) → 326→338→340→**349** | Verde en cada ronda; el conteo crece con cada FAIL |
| **Runner offline** | Ejecutor + Arquitecto | `node runner/run-c1.js` → `RESULTADO: OK — plano contenido`, cleanup `restantes=0` | Verde |
| **Verificación independiente** | Arquitecto | Worktree aislado, barrera A `56→0`, FAKE de dominancia inyecta la arista del dictamen, `git archive` limpio | PASS (salvo 5.3/5.7 donde falló por no-hermético/prefijo) |
| **Reproducción adversarial** | Monitor de Juan | `190/190 + runner OK, 56→0`; contrasta contra código público n8n (`n8n-io/n8n@10a7422`, tag `2.28.7@955be3ef`) | ~18 FAILs + 2 PASS + FAILs vivos |
| **Regresión integrada** | Ejecutor | `pausarInbound→B→A` en ClienteFalso + canarios (destapó 5.2) | Verde tras fix |
| **Smoke/manual vivo (prechecks)** | Alberto + Juan | 3a target/clave 200; 3b 0 en-vuelo; 3c 7/7 IDs; 3d Django false/false/true; 3e `migrate --check` exit 0; 3f **bloqueado**; 3g UI cerrada; preflight publicación=síncrona | 3a–3e,3g verde; 3f→opción A |
| **E2E vivo** | Alberto (operador) | Única corrida: pausa verde → B STOP fail-closed | STOP (recuperado) |

**#validaciones ≈ 60+** (≈23 SHAs × 3 actores) + 8 prechecks vivos + 1 E2E.

---

## 7. Despliegues

**NINGÚN despliegue de C1 llegó a STG.** La única corrida viva (2 ago 01:40–01:41Z) hizo la pausa (7 `deactivate`, recuperados) y **paró fail-closed en la barrera B antes de crear un solo clon o tocar un solo workflow vivo con A** (`b.resultados=[]`, `a.resultados=[]`; 0 clones creados, 0 PUTs). STG fue **restaurado** al estado pre-ventana (7 vivos `active=true`, contenido intacto, 0 clones C1-AISLADO), verificado independientemente por el Arquitecto.

**Despliegues adyacentes (NO son C1):**
- Django **PR #139** merged a `stg` (2026-07-29) → Heroku STG (pre-contratos de #132).
- Django **PR #142** merged a `stg` (2026-07-31) → Heroku STG v212 (`4f0e741`) — durante el freeze, auto-clasificado ex post por Juan; es la base Django del GO pero no es el instalador C1.
- Deploys automáticos de plataforma sin relación con el contenido C1: Vercel Preview en cada push a la rama Dashboard; Vercel Production en el commit docs-only a `main`; Heroku en merges a `stg` (defecto 5.12).

---

## 8. Esperas

| Espera | Duración aprox | Motivo | Quién tenía la siguiente acción |
|---|---|---|---|
| **Gate humano RACI / suplente** | **~7.7 h** (08-01 15:36 → 23:19) | Operador único no satisface el suplente HUMANO del RACI canónico #140 §10; requería decisión de Alberto + enmienda escrita de Juan | Alberto (elegir vía a/b) → Juan (escribir la enmienda) |
| **Rondas monitor de Juan (offline)** | ~0.5–3 h cada una, ~18 rondas | Cada FAIL exigía nuevo SHA; el monitor reproduce antes de dictaminar | Alternaba: ejecutor construye ↔ monitor audita |
| **Auditoría A/B de Juan** | "varias h" (no determinable exacto) | Decisión de alcance (incluir barrera A con PUT vivo) | Juan (accountable) |
| **HOLD final actual** | En curso (desde 04:06Z) | Espera PASS consolidado del monitor v3 sobre `161d6913` + "condiciones satisfechas" | Monitor v3 de Juan |
| **Confirmación datos humanos (Vercel deployment-id)** | Intermitente ~horas | El checker Dashboard necesitaba el deployment Preview real, confirmado por Alberto en panel | Alberto |
| **2FA Hostinger (preflight publicación)** | ~48 min (00:01 GO → 00:49 PASS) | Alberto no tiene el 2FA de Hostinger; solo Juan puede correr `docker inspect` | Juan |

**Observación:** las esperas AI↔AI (monitor ↔ ejecutor) fueron cortas (minutos a ~3 h). Las esperas **humanas** fueron las largas: el gate RACI de ~7.7 h es el mayor bloque idle único del caso.

---

## 9. Retrabajo

| Retrabajo | Por qué | ¿Evitable? |
|---|---|---|
| **~18 rondas FAIL/re-SHA** del checkpoint/CLI | Cada auditoría del monitor encontró un endurecimiento real (rollback recuperable, target inmutable, activeVersionId null, producers, bytes exactos…) | **Parcialmente.** Cada FAIL era legítimo; pero la meta "se alejaba al auditar más hondo" — falta de spec de aceptación cerrada por adelantado |
| **Reset de alcance** (harness offline → instalador vivo, `5149165789`) | El checkpoint conflacionó el banco de pruebas con instalación viva (5.4) | **Evitable** con una definición explícita de "contención viva" antes de declarar C1 aceptada |
| **Re-publicaciones del checkpoint** | Placeholders (`<ID>`, `<fingerprint>`, "a pactar"), datos humanos que llegaban tarde | **Parcialmente** — datos humanos (ventana, Vercel id, suplente) son dependencias externas |
| **SHA drift `415ee46`→`e7f3a78`→`161d6913`** | El candidato se movía mientras el monitor auditaba el anterior; el Arquitecto pusheó 5 min tras el freeze por no re-fetchear (auto-declarado, `88b1d27`) | **Evitable** con disciplina de fetch-before-push (adoptada como hábito) |
| **340/340 → 349/349 hermético** | Verificación no hermética (máquina-dependiente) daba falsos PASS (5.3) | **Evitable** con harness hermético desde el inicio (`git archive` limpio) |
| **PUT prematuro `7c64156`** → cuarentena + force-push | Ejecutor construyó trabajo A-contingente antes del GO de A (5.11) | **Evitable** (cruzó un límite explícito) — pero produjo 2 hallazgos útiles |
| **Corrida viva abortada + fix del defecto de orden** | El defecto 5.1 solo se manifestó en vivo (la pausa cambia el estado que B congeló) | **Difícilmente evitable offline** sin un test de integración que ejerciera pausa→B con estado real; la regresión que lo habría cazado (5.2) tenía a su vez un bug |

---

## 10. Root Cause Analysis (por categoría canónica)

**Falta de especificación.** Raíz dominante. No existía una **definición de "hecho" (Definition of Done) cerrada** para C1 al arrancar: "aceptada offline" (#11) no era lo mismo que "contención viva instalable" (#12). La ausencia de un contrato de aceptación por adelantado convirtió la revisión en descubrimiento incremental — ~18 rondas donde "la meta se aleja al auditar más hondo". El checkpoint arrancó con placeholders y con un instalador inexistente citado (5.4).

**Coordinación.** El modelo AI↔AI vía issues fue rápido y trazable, pero los **límites de alcance** se cruzaron dos veces (PUT prematuro 5.11; ejecutor leyendo la spec de 5 puntos como tarea). Las 3 contaminaciones de rama candidata (handoffs en la rama equivocada) son fallos de coordinación de canal, resueltos con la convención worktree.

**Dependencias humanas.** El cuello de botella temporal mayor. Gate RACI/suplente ~7.7 h; operador único (Alberto es el único humano operativo → no hay suplente HUMANO independiente → requiere enmienda escrita del A); 2FA Hostinger solo en manos de Juan; confirmación del deployment Vercel solo por Alberto en panel. **La IA nunca puede ser A ni emitir GO** (RACI #140 §10) — por diseño, cada corrida viva necesitaba un humano hasta la enmienda `5154662330`.

**Dependencias entre repositorios.** El cambio abarca 4 repos con owners distintos (Alberto en 3, Juan en HYL-WAI). El instalador n8n depende de identidad/versión de STG; la guarda Dashboard depende de un deployment Vercel inmutable; el checkpoint (Arquitecto) depende de datos de los otros 3. Ninguna herramienta cruza los límites: todo se reconcilia a mano vía handoffs + comentarios de issue.

**Integración.** El defecto 5.1 (STOP) es puro fallo de integración **temporal**: dos pasos correctos por separado (pausa; barrera B con anti-TOCTOU congelado) son incompatibles en secuencia (la pausa muta el estado que B congeló). Solo se manifestó en vivo porque el test que debía ejercerlo tenía su propio bug (5.2).

**Calidad.** Los checkers tenían bugs de auto-validación (5.9), content-only (5.10), falso verde (dry-run que imprime "OK"). El monitor de Juan actuó como red de calidad efectiva (los cazó todos), pero a costa de ~18 rondas.

**Entornos.** Acoplamiento de entorno = fuente recurrente: `DATABASE_URL` no scopeada al Preview (5.8) bloqueó 3f; STG (2.28.7) y PROD (2.6.3) a 22 minors → los artefactos **no son portables a PROD** (bloqueante futuro real); SQLite interna de n8n vs Postgres del bot (dos BD, el checkpoint no debía decir "restaurar la BD" sin apellido); suite no hermética por `.vercel` local (5.3).

**Esperas.** Ver §8: las esperas AI↔AI son cortas; las humanas son las largas. El gate RACI de ~7.7 h y el HOLD final son los mayores.

**Otros.** El monitor de Juan lee `Agente-n8n`, `Agente-Arquitecto` y las plataformas (Vercel/Heroku Deployments API) casi en tiempo real → **todo commit es comunicación pública de facto**. Positivo para trazabilidad, pero cambia el modelo mental: no hay "borrador privado".

---

## 11. Métricas (aproximadas)

| Métrica | Valor | Nota |
|---|---|---|
| **Tiempo total transcurrido** | ~30 h (sub-caso instalador A/B: 07-31 21:52Z → 08-02 04:06Z, sigue abierto) | Issue madre #132: ~5 días |
| **Tiempo dev activo (agregado)** | ~20 h | Construcción ejecutor + verificación Arquitecto, casi continuo la noche 31→1; **aproximado** |
| **Tiempo espera (agregado)** | ~11 h | Dominado por el gate RACI ~7.7 h + rondas del monitor + HOLD final |
| **#handoffs** | ~26 | ~24 Arq→n8n + ~2 Arq→Dashboard (verificado en `handoffs/`) |
| **#iteraciones Juan↔nuestro lado** | ~23 | ~18 FAIL/PASS offline + GO + STOP + 3 enmiendas de gobernanza |
| **#bugs/defectos** | ~12 | 5.1–5.12 (mezcla de defectos de código, verificación, entorno, gobernanza) |
| **#validaciones** | ~60+ | ~23 SHAs × 3 actores + 8 prechecks vivos + 1 E2E |
| **#repos** | 4 | Agente-n8n, Dashboard, Agente-Arquitecto, HYL-WAI |
| **#SHAs candidatos** | ~23 | Cadena `ad85149`…→`161d6913` |
| **#despliegues a STG (C1)** | **0** | Única corrida viva paró en B |

---

## 12. Timeline visual (ASCII)

```
07-28  #132 abierto (Juan)
07-29  ├─ Django PR#139 → stg (adyacente)
07-31  ├─ 21:16 Django PR#142 → stg v212 (freeze; ex-post)
       ├─ 21:52 NO-GO C1 offline ──────────────► ARRANCA EL CICLO
       └─ 22:04/22:37 PR#2 (Dashboard) / PR#3 (n8n)
                 │
08-01  [DEV/AUDIT AI↔AI — ~18 rondas offline]
 00:56 ├─FAIL─┐
 02:3x │  fe456b0→b2c89ba→4e2118c
 03:1x ├─"C1 aceptada" (FALSO FINAL)
 03:2x ├─NO-GO OPERATIVO ◄── reset de alcance (ingeniería nueva: barrera A + instalador)
 03:4x │  86a9c09 (7c64156 PUT prematuro→cuarentena)
 04:03 ├─Juan decide A (FAIL)
 04:2x │  28167b6→601a845→464dbd4
 05:5x─15:15  7c877a7→871221400→1c30a00→78442a4→4e8acea→8b2c8c2→d651b22→944cd96
 15:15 ├─🎯 PASS técnico offline (944cd96 / 5fcc06099)
       │
 15:36 ├════════ GATE HUMANO RACI/suplente ════════╗  ~7.7 h ESPERA
 23:19 ├─🎯 Juan enmienda RACI (operador único)     ║
 23:24 ├─ventana inmediata en vez de lunes          ║
       ▼══════════════════════════════════════════════╝
08-02
 00:01 ├─🟢 GO OPERATIVO (5fcc06099) ── SESIÓN VIVA
 00:49 ├─preflight Hostinger: síncrona ✓ (Juan)
 01:2x ├─prechecks 3a-3e ✓ ; 3f ✗ (Dashboard 500) ─► HOLD
 01:32 ├─Juan enmienda GO: opción A para 3f ✓
 01:40 ├─PAUSA viva ✓ (run c1-...c975)
 01:41 ├─BARRERA B → ✋ STOP fail-closed (cabeza-viva-cambiada)
       │        └─► 0 clones, 0 vivos tocados; STG RESTAURADO ✓
 02:24 ├─Juan enmienda #140: delega al monitor; C1 re-run PRE-AUTORIZADO
 03:00 │  02fd9ec→415ee46→(drift)e7f3a78→161d6913 (hermético 349/349)
 04:06 └─► HOLD: espera PASS monitor v3 → "condiciones satisfechas" → 2ª corrida
```

---

## 13. Observaciones (solo hechos)

- **Qué lo hizo lento (1):** ausencia de una Definition of Done cerrada. La "aceptación offline" (`5149044773`) no cubría contención viva → NO-GO operativo (`5149165789`) = ingeniería nueva a mitad del caso. Un contrato de aceptación por adelantado habría colapsado ~18 rondas.
- **Qué lo hizo lento (2):** el gate humano RACI/suplente (~7.7 h idle) — el mayor bloque muerto único, por un problema estructural (Alberto es el único humano operativo, y la IA no puede ser suplente).
- **Dónde más tiempo se perdió:** el ciclo de endurecimiento del checkpoint/CLI (06:0x→15:15, ~9 h de reloj) donde cada FAIL era real pero la meta se alejaba; y el retrabajo por verificación no-hermética / prefijo (5.3, 5.7) que produjo falsos PASS del Arquitecto.
- **Dónde más cambios de contexto:** el Arquitecto orquestó en paralelo n8n + Dashboard + Django + gobernanza en issues + cronología, saltando de repo en repo por evento. Las 3 contaminaciones de rama candidata son síntoma de ese context-switching.
- **Qué info faltó:** valores esperados de handoff desfasados (pre-fix); el doc de entrega no leído (contratos de API de 5.5/5.6); datos humanos que llegaban tarde (deployment Vercel, ventana, suplente); modo de publicación n8n (solo obtenible en ventana).
- **Pasos que aportaron valor:** la triple validación (ejecutor+Arquitecto+monitor) cazó ~12 defectos, varios que en PROD habrían sido incidentes (auto-validación de target, rollback content-only, cliente falso publicando sobre pausados). El fail-closed en B evitó tocar el bot vivo. La restauración limpia (RTO ≤20 min) funcionó.
- **Pasos que aportaron poco:** re-publicaciones de checkpoint por placeholders; SHA drift por no re-fetchear; el PUT prematuro (aunque dio 2 hallazgos). El P2 de portabilidad de test entre hosts se difirió sin cerrar.
- **Convergencia AI↔AI:** notable que los estándares de ambos lados **convergieron** (el `migrate --check` bloqueante de Juan sale de su propio incidente Heroku; su journal sanitizado, de nuestro P2 de redacción). El loop FAIL/PASS produjo aprendizaje bilateral.

---

## 14. Evidencias (referencias)

**Cronología primaria:** `/Users/AIP/claude-projects/Agente-Arquitecto/docs/iniciativas/2026-07-31-eventos-gobernanza-140-noche.md` (543 líneas, play-by-play).

**Comentarios de issue (verificados por API, `aguayo-co/HYL-WAI`):**
- `5147782653` (07-31 ~21:52) NO-GO C1 offline · `5148715706` (08-01 00:56) re-revisión · `5149044773` "C1 aceptada offline" · `5149165789` NO-GO OPERATIVO · `5149704373` decisión A + FAIL · `5150070342` (05:53) · `5150210658` (06:35) · `5151490235` (12:48) · `5151680686` FAIL+gap Arquitecto · `5151951037` target inmutable · `5152030384` (15:15) PASS técnico · `5152051722` 2º PASS · `5152112808` gate humano · `5153952626` (23:19) enmienda RACI · `5154091214` (08-02 00:01) **GO** · `5154268653` (00:49) preflight PASS · `5154417314` (01:26) HOLD 3f · `5154440416` (01:32) opción A · `5154508007` (01:49) reporte STOP · `5154563080` FAIL 6 puntos · `5154662330` (02:24) enmienda delegación · `5154995079` (03:33) FAIL consolidado · `5155176112` (04:06) checkpoint exacto.

**Issues:** #132 (OPEN, C1, autor oilycoyote, 07-28) · #140 (CLOSED 07-30, decisión rollout, sede enmiendas RACI) · #135/#128/#143 (contexto) · Django PR #139 (MERGED stg 07-29) · PR #145 (OPEN, congelado).

**PRs:** `Agente-n8n#3` (OPEN, base stg, head `feature/c1-contencion-gates-plano-aislado`, `161d6913`) · `Dashboard_seguroautoqualitas#2` (OPEN, `1373d1a`, congelado).

**SHAs clave (Agente-n8n):** `5fcc06099` (base del GO) → STOP → `02fd9ec` → `415ee46` → `e7f3a78` → `161d6913`. Cuarentena PUT: `c1-put-path-preparado@7c64156`.

**Run-ids vivos:** pausa `c1-20260802T014026-c975` (verde) · instalación `c1-20260802T014148-21a0` (STOP en B, `cabeza-viva-cambiada`).

**Handoffs:** `Agente-n8n/handoffs/2026-07-31-*`, `2026-08-01-*`, `2026-08-02-*` (≈26). Informes de respuesta: `Agente-n8n/docs/2026-08-0*-informe-*.md`.

**Docs Arquitecto:** `docs/iniciativas/c1-checkpoint-operativo-AB-v2.md`, `c1-checkpoint-operativo-borrador.md`, `c0-baseline-freeze-opcion-c.md`, `c2-matriz-nucleo-dual-runbook-borrador.md`, `2026-07-28-plan-ejecucion-132-135-lado-nuestro.md`.

**Bugs contexto:** `docs/bugs/bug-17-webhook-proactivo-stg.md` (guard n8n-proactive-message.js), `bug-10-vin-issue-policy.md` (importer citado erróneamente), `bug-12-inbound-caido.md` (webhookId).

---

## 15. Lecciones para AI-EOS (AI Engineering Operating System)

> Ángulo AI-EOS: dos "lados" IA (nuestro Arquitecto + el monitor de Juan) iteran vía GitHub issues bajo accountability humana, con un loop de auditoría FAIL/PASS, enmiendas de gobernanza, un gate "una-corrida-y-humano", y un modelo de pre-autorización delegada (`5154662330`).

1. **Dependencias estructurales.** El cambio cruzó 4 repos con 2 owners y ninguna herramienta cruza el límite: la reconciliación es 100% manual (handoffs + comentarios). Un AI-EOS necesita un **grafo de dependencias cross-repo de primera clase** y un objeto "cambio" que abarque los N repos, no N PRs sueltos reconciliados a mano.

2. **Ownership y el gate humano.** La regla "la IA nunca es A ni emite GO" es correcta como principio, pero **el operador único humano** (Alberto) se volvió el cuello de botella (gate RACI ~7.7 h; 2FA solo de Juan; confirmación de deployment solo en su panel). AI-EOS debe modelar **suplencia y accesos como recurso escaso** y permitir enmiendas de RACI acotadas y con caducidad (justo lo que Juan hizo en `5153952626`) sin ~8 h de negociación.

3. **Coordinación AI↔AI: rápida donde el contrato es objetivo.** Las rondas monitor↔ejecutor fueron minutos-horas y produjeron **convergencia de estándares bilateral**. La lección: cuando el criterio es reproducible (tests, hashes, `56→0`), la iteración IA↔IA escala. Donde se atascó fue en criterios **no pre-especificados** (Definition of Done de "contención viva"). AI-EOS: exigir un **contrato de aceptación cerrado y ejecutable ANTES** de abrir el loop.

4. **Integración temporal, no solo estructural.** El STOP (5.1) fue un fallo de composición temporal (pasos correctos, orden incompatible) invisible offline porque el test que lo cubría tenía su propio bug. AI-EOS necesita **entornos de ensayo fieles al estado vivo** (ordenación real, mutaciones de estado) y tratar los harness de test como código auditable con la misma severidad que el producto.

5. **Calidad: el auditor adversarial funciona pero es caro.** El monitor de Juan cazó ~12 defectos (varios habrían sido incidentes en PROD). ~18 rondas es el precio. AI-EOS debe **desplazar la auditoría hacia la izquierda**: canarios/adversarial-tests como parte del contrato de entrega del ejecutor, no descubiertos ronda a ronda por el revisor.

6. **Validación: hermeticidad no negociable.** Los falsos PASS del Arquitecto (5.3, 5.7) vinieron de verificación **máquina-dependiente** y de inspeccionar prefijos. AI-EOS: toda verificación desde artefacto limpio (`git archive`), suite completa, con un **guardián de hermetismo** permanente. "Pasa en mi entorno" no es evidencia.

7. **Trazabilidad: el commit es comunicación pública.** El monitor lee 3 repos + APIs de plataforma casi en tiempo real. Esto es un **superpoder de trazabilidad** (todo queda registrado, dedup cruzado, auto-clasificación ex post), pero elimina el "borrador privado". AI-EOS debería hacer esto **explícito y bidireccional** — un bus de eventos de delivery donde cada lado publica/observa, en vez de scraping de git/deployments.

8. **Observabilidad de la plataforma.** Los auto-deploys (Vercel Preview/Prod, Heroku stg) sorprendieron a ambos lados (5.12) y a los dos les tocó auto-clasificar ex post. AI-EOS debe **modelar la automatización de plataforma como un actor** (git→deploy) e incluirla en el checkpoint de "efectos", no descubrirla por la Deployments API a posteriori.

9. **Organización: el modelo de pre-autorización delegada es la innovación clave.** La enmienda `5154662330` (Juan delega a su monitor la autorización de acciones vivas bajo **7 condiciones objetivas**, sin nuevo GO humano por fase) es el patrón más importante para AI-EOS: **autorización humana condicional previa, verificable por máquina**, que corta el gate humano por-corrida sin quitar accountability. Es el prototipo de cómo un AI-EOS deja que las IA cierren fases vivas mientras el humano fija el sobre de riesgo una sola vez y la máquina acredita el cumplimiento. **El "gate una-corrida-y-STOP" + pre-autorización delegada + caducidad automática** es el núcleo replicable del AI Delivery Standard.

**Insight adicional AI-EOS:** el mayor coste NO fue construir (los ejecutores IA produjeron ~23 SHAs sólidos rápido) ni auditar (el monitor fue veloz), sino **la falta de un contrato de "hecho" y las dependencias humanas/de entorno**. Un AI-EOS que resuelva (a) Definition-of-Done ejecutable por adelantado, (b) suplencia/accesos como recurso gobernado, y (c) entornos hermético-fieles, colapsaría este caso de ~30 h a una fracción — sin perder la red de seguridad adversarial que evitó tocar el bot vivo.

---
*Fin del Caso #1. Próximo capítulo sugerido: auditar una fase que SÍ llegue a instalarse en vivo (C1 re-run o C2) para medir el modelo end-to-end incluyendo un despliegue efectivo.*
