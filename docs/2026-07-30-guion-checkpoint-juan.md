# Guion de Alberto — checkpoint con Juan, jueves 30 jul 10:00 CDMX

> Meet: https://meet.google.com/ywh-djvu-vxr (45 min). Agenda = los 8 puntos de Juan (su
> comentario del 29 jul en #132). Nuestro estado: TODO verde (`848057e`, 249 tests, ambos
> flavors, certificado). Lo que se juega: el GO/NO-GO de la ventana del viernes 13:00.

## Chuleta de datos (por si te preguntan)

- Rama: `aibanez82/Agente-n8n:feature/issue-132-port-dual-safe`, SHA **`848057e`**
- Tests: **249** (245+4 skip `actual` / 248+1 skip `objetivo`), 0 fallos, 3× sin flakiness
- Artefactos de ventana: 5 workflows transformados + sub-workflow `Issue Policy Guard (STG)`
  + script de schema (con paridad archive) + runbook `deploy/deploy-port-132-stg.py` (dry-run
  ensayado) + rama Dashboard `fix/operator-webhooks-post-headerauth` (`08981ef`)
- Header de auth: **`X-Operator-Auth`** · Env vars Vercel: `N8N_OPERATOR_WEBHOOK_BASE_URL`,
  `N8N_OPERATOR_WEBHOOK_SECRET` · Un solo secreto para los 4 webhooks de operador

## Punto por punto (qué escuchar, qué decir, qué decidir)

**1. Estado STG tras PR #138 (presenta Juan — su preflight read-only).**
Escuchar: ¿modo `shadow` confirmado? ¿flags apagados? ¿migraciones 0053-0061? ¿existe aún
`idx_whatsapp_sessions_phone_number`? ¿forma real de las tablas archive?
→ Si el índice único YA no está: nuestra realidad es el flavor `objetivo` (todo probado).
→ Si las archive difieren de lo asumido: nuestro script tiene guardas; ajuste pequeño, no bloquea.

**2. Canónico `hashtext()` (el gate crítico).**
Nuestra string y vectores están publicados (todos → `525512345678`). Pedir: que Juan confirme
que su helper unificado reproduce EXACTAMENTE esos vectores (idealmente enseña su test cruzado
corriendo). Sin match exacto → NO-GO automático del viernes.

**3. Writers con/sin lock + Chat Memory.**
Ya resuelto de nuestro lado: trigger BEFORE INSERT (cubre LangChain) + `Update Activity`
lockeado. **Decisión real de este punto: los 4 writers legacy sin lock** (`Save Group1/2/3
Progress`, `Save Policy Data`, `Update Out of Scope in DB`, `Increment KB Counter`).
→ Tu posición: si Juan los quiere lockeados, lo hacemos hoy jueves por la tarde (fase pequeña,
mismo patrón, cabe antes del viernes). Si no, quedan como excepción documentada. No lo ofrezcas
proactivamente — que lo pida él.

**4. Paridad active/archive.** Corregida en nuestro script. Solo confirmar contra su preflight.

**5. Payment v1 / lead_id.** Nuestro supuesto: `lead_id` NULL = compatible, solo contradicción
real bloquea. Que apruebe o endurezca. Su deploy de Payment v1 a STG: a su ritmo (parser dual).

**6. Humano/Metepec.** Exclusión fail-closed implementada (`blocked_metepec_active` /
`blocked_human_active`), Dashboard ya la mapea. Transferencia explícita = diseño aparte, NO
entra en esta ventana. Solo pedir su OK a la semántica.

**7. #69 + ventana 24h.**
Cuéntale el hallazgo si no lo ha leído: **Phase Guard nunca funcionó** (leía propiedad
inexistente) — corregido + 3 barreras, Payment único writer de `completed`. Pedir su OK al
cambio observable (sesiones completed ahora reciben respuesta de cierre).
Ventana 24h: ya acordado diferirla a #135/B4 con followups en dry-run — solo formalizar.

**8. GO/NO-GO y logística de ventana.**
- Criterio GO viernes 13:00: su preflight verde + canónico match + supuestos 1-6 aprobados.
  Si falta algo → plan B lunes 3-ago AM, sin forzar.
- Orden de ventana: el suyo de 13 pasos (más completo que el nuestro) — aceptado; nuestro
  runbook cubre los pasos n8n (backup→drift→transform→import→verify→sync Git).
- #130 (`N8N_TOKEN`): nuestra posición = rotar en esta ventana si todo va verde.
- #129 (rol read-only `conciliacion_pagos`): prerrequisito del E2E conjunto, NO de la ventana.
- Recordar: deploy ≠ cierre de #132 (falta integración pinneada, sign-off, `dual`, rollback
  probado) — ya acordado, sin discusión.

## Antes de la llamada (5 min, tuyos)

1. ☐ `GH_TOKEN` al environment cloud (claude.ai/code → environments → Default) — desbloquea el
   monitor horario de Juan. Independiente del checkpoint pero pendiente tuyo.
2. ☐ Mira si Juan respondió algo en #132 durante la noche (o pídemelo al arrancar sesión:
   "revisa comentarios de Juan").
3. ☐ Confirma tu disponibilidad real del viernes 13:00-15:00 — la ventana requiere TUS manos
   (credencial n8n, env vars Vercel, correr el runbook, merge del Dashboard).

## Después de la llamada

Pásame el resultado (aunque sea en 3 líneas: GO/no-GO, decisión de los 4 writers, supuestos
aprobados/ajustados) y yo: actualizo docs, lanzo la fase pequeña si Juan pidió los locks
legacy, y dejo la ventana del viernes lista paso a paso.

---

## ACTUALIZACIÓN 29-jul noche — el checkpoint llega mucho más maduro

Desde que se escribió este guion pasó todo esto (todo publicado en #132):

- **Fase 6.5 y 6.6 cerradas y certificadas** (`f5072f5`, 273 tests, ambos flavors): los 5 gates
  de la revisión de Juan en verde. **Los 8 writers legacy ya tienen lock** — el punto 3 del
  guion original queda obsoleto (ya no hay decisión de "4 writers sin lock").
- **Juan entregó su paquete Django** (PR draft #139) y **el contraste del Arquitecto dio
  canónico en MATCH EXACTO** — el gate 1 se cierra con su corrida en el PG real de STG.
- **De las 6 preguntas de aprobación, 3 se cerraron con su propio código** ((a)/(c)/(d)).
  **Decisiones reales que quedan: (b) RETURN NULL vs RAISE en el trigger, (e)
  `payload_v1_lead_no_verificable` terminal vs degradar, (f) re-validación por
  identidad/generación sin gates de fase.** Recomendación del Arquitecto: defender las tres
  como están (razonadas en issuecomment-5123328661).
- **4 sincronizaciones menores** ya avisadas a Juan (issuecomment-5123375090): su runbook
  referencia scripts superseded (usar `create-port132-window-schema-stg.py`), la expectativa
  errónea de `blocked_human_active` en Dashboard, la asimetría de sus writers single-statement
  sin lock (confirmar deliberada), y flags de followups seteados EXPLÍCITOS en Heroku STG
  (su preflight trata ausente como false-PASS).
- **Criterio de GO actualizado:** nuestros gates ✅ + canónico match ✅ → el GO del viernes
  depende solo de su preflight real en STG + las 3 decisiones (b)/(e)/(f) + firmas.
- **Punto extra para la llamada (decisión Alberto 29-jul: todo Meta lo ejecuta Juan):** pedirle
  que someta la **plantilla de re-enganche fuera de ventana 24h** (pendiente desde el 16-jul,
  bloquea Recordatorios por fecha mencionada y rescates tipo Bug #12). El Arquitecto tiene el
  borrador listo (nombre `reenganche_cotizacion_pendiente`, categoría Utilidad, cuerpo con
  {{nombre}}/{{vehículo}}, botones de respuesta rápida) — se le pasa para copy/paste.

---

## ACTUALIZACIÓN 29-jul 22:30 — dictamen de auditoría de Juan: NO-GO offline (SUPERSEDE lo anterior donde contradiga)

Juan publicó su auditoría de `f5072f5` (issuecomment-5123871526). Lo esencial:

- **Confirma nuestros números** (reprodujo las suites en PG17 aislado: 269+272 pass, 139/139
  unitarias, dry-run completo) y da por presentes los 5 avances funcionales. **Pero el dictamen
  es NO-GO offline** para ejecutar el runbook contra STG: 3 P0 en el script de deploy + 5 P1
  de fencing/identidad + readiness/rollback. Ninguno toca la lógica certificada — todos están
  en la tubería de deploy o en cobertura que las suites no tenían.
- **Las 3 decisiones abiertas quedaron resueltas — ya NO son agenda de la llamada:**
  (b) `RETURN NULL` ✅ aprobado; (e) `lead_no_verificable` terminal ✅ aprobado;
  (f) ❌ RECHAZADO omitir gates de fase/estado en los 8 writers — lo reprodujo (writer stale
  mutó una sesión `completed`; `Update Out of Scope` baneó a una identidad nueva). Los gates
  son ahora trabajo obligatorio, no decisión.
- **Handoff Fase 6.7 ya entregado al Agente n8n** con los 10 puntos:
  `~/claude-projects/Agente-n8n/handoffs/2026-07-29-fase6-7-bloqueantes-auditoria-juan.md`
  (rama `feature/issue-132-port-dual-safe`, commit `095829a`). Orden: P0 runbook → gates
  writers → resto. Ideal: llegar a la llamada con T1+T2 en verde.
- **PR #139 ya está en STG:** mergeado a `stg` como `34d7d6b` y desplegado en `hyl-wai-stg`
  (sin flags nuevos ni migraciones), ANTES del checkpoint. Juan lo declaró y no tocará STG sin
  autorización. **Abrir la llamada con el punto 1 (preflight read-only)** — confirmar `shadow`,
  flags y schema efectivos — ya no es "presenta Juan si quiere", es el primer paso conjunto.
- **Juan sincronizó su runbook** al script consolidado y al outcome real del Dashboard
  (`HYL-WAI@6499284`).
- **Criterio de GO re-actualizado:** ya no basta preflight + decisiones. Ahora: Fase 6.7
  cerrada y certificada + re-revisión de Juan + su preflight verde. **La ventana del viernes
  13:00 está en riesgo real** — llevar a la llamada la disyuntiva viernes-vs-lunes 3-ago sin
  forzar; si T1+T2 no están en verde y contrastados antes de la llamada, recomendación del
  Arquitecto: proponer lunes directamente.

---

## ACTUALIZACIÓN 29-jul ~19:00 — Fase 6.7 CERRADA Y CERTIFICADA (supersede el riesgo del bloque anterior)

**El escenario ideal se cumplió con margen: no solo T1+T2 — los 10 puntos (T1-T7) están en
verde, certificados por el Arquitecto y avisados a Juan** (issuecomment-5124468615, con petición
de re-auditoría antes de las 10:00 si le da la vida; si no, primer punto de la llamada).

- **Entrega:** commit `1424163` en `feature/issue-132-port-dual-safe` (pusheado). Reporte del
  ejecutor: `Agente-n8n:docs/2026-07-30-fase6-7-reporte-port-issue-132.md`. 0 nodos nuevos en
  ningún workflow (Main sigue 118→125) — todo es mutación de contenido.
- **Verificación independiente del Arquitecto (checkout limpio, worktree propio):** JS 290
  tests × ambos flavors (286+4 skip / 289+1 skip, 0 fallos — números idénticos a los del
  reporte); Python 46 tests 0 fallos (T1:11, T7:11, T4:2+6, T7b:16). Las DOS reproducciones de
  Juan son tests de regresión citables que fallaban contra el código pre-fix.
- **Decisiones tomadas por el Arquitecto (comunicadas a Juan para sign-off):**
  1. Matriz de gates: terminal sí/no (no por-fase) + `Mark Session Closed` con gate propio;
     `human_takeover` fuera del gate. Si Juan quiere granularidad por fase, es fase pequeña
     post-checkpoint con las fases exactas que él defina.
  2. T6 acotado a `qc:v1` — el patrón también existe en la rama v2 del nodo CONGELADO; anotado,
     no tocado (disciplina de freeze, `qualitas-issues#66`).
  3. Preflight Django 0053 como gate duro del runbook (desactivable por parámetro si Juan
     prefiere informativo).
- **Criterio de GO del viernes:** vuelve a estar sobre la mesa — depende solo de (a)
  re-auditoría de Juan sobre `1424163` y (b) su preflight read-only real en STG. La disyuntiva
  viernes-vs-lunes sigue siendo el cierre de la llamada, pero ya sin recomendación de proponer
  lunes de entrada.
- **Flag operativo menor:** el clon local de `Agente-n8n` tiene la rama `stg` con 1 commit sin
  pushear (`31306db`, refuerzo CASO A) — pedir al Agente n8n que lo pushee o lo explique
  (regla multi-máquina: nada vive solo en local). [RESUELTO ~18:10 — ya sincronizado]

---

## ACTUALIZACIÓN 29-jul ~18:30 — SEGUNDA re-auditoría de Juan: NO-GO otra vez → Fase 6.8 en curso (SUPERSEDE el bloque anterior)

Juan re-auditó `1424163` en menos de media hora (comentario 30-jul 00:01 UTC). Reprodujo
nuestros números (los confirma todos) y da por cerrados 6 fixes de 6.7, pero su revisión
negativa encontró **10 huecos nuevos** y el dictamen sigue **NO-GO offline**. Él mismo propone
"Fase 6.8 corta". Lo esencial:

- **Writers (los 4 duros):** el gate debe ser ALLOWLIST de estados recuperables (reprodujo
  mutación con `status='completed'` y `phase='archived'`, que nuestro gate blocklist no cubre);
  `Mark Session Closed` debe usar el gate estándar (reprodujo a Mark pisando a Payment); falta
  `conversation_id` en la identidad de los writers; y **rechazó mi decisión de 6.7**: los
  handoffs `human_takeover`/`metepec` SÍ entran al gate de los writers del agente.
- **`qc:v2`:** también rechazó mi acotación a v1 — v2 es contrato nuevo, `l:` numérico
  obligatorio. Acepté ambos criterios suyos (tiene razón en los dos).
- **Runbook/readiness:** fingerprint ciego a IDs de nodos, sync Git no atómico, doble fuente de
  URL/credencial STG, rollback que trata timeout como "borrado", readiness por nombre y no por
  definición (nos cazó con fakes: trigger passthrough homónimo, índice con definición errónea).
- **Su "Estado de cierre" de #132:** lista explícita de lo que falta aunque el offline quede
  perfecto (preflight verde, DDL aplicado, import real, E2E shadow, dual observado, rollback
  real). Coincide con lo ya acordado (deploy ≠ cierre) — no es alcance de 6.8.

**Hecho ya:** handoff Fase 6.8 entregado al Agente n8n
(`Agente-n8n:handoffs/2026-07-29-fase6-8-segunda-auditoria-juan.md`, commit `53e30a2` en la
rama) con los 10 puntos como T1-T10 y las dos decisiones revocadas documentadas. Acuse a Juan
publicado (issuecomment-5124869364) aceptando sus criterios y comprometiendo allowlist + matriz
como tablas para su sign-off.

**Para la llamada:**
- Si al arrancar la llamada la 6.8 está cerrada, certificada por el Arquitecto Y re-auditada
  por Juan en verde → GO viernes sigue vivo (dependiendo solo del preflight).
- Si la 6.8 está cerrada y certificada pero SIN re-auditoría de Juan → proponer que la
  re-audite el jueves por la tarde y decidir GO/NO-GO el viernes 9:00 por el issue (ventana
  13:00 se mantiene tentativa).
- Si la 6.8 no está cerrada → proponer lunes 3-ago directamente, sin forzar.
- Señal positiva para la relación: Juan respondió en <30 min a las ~18:00 de su noche y propuso
  él mismo la fase corta — está tan invertido como nosotros en que la ventana salga.
