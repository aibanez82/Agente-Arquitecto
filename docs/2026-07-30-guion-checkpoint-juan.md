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

---

## ACTUALIZACIÓN 29-jul ~21:30 — Fase 6.8 entregada; el proceso adversarial NUEVO la retuvo antes de Juan (Fase 6.8.1 en curso)

El Agente n8n cerró la 6.8 (`520a805`, 306 JS × ambos flavors + 60 Py, reproducidos en verde
por el Arquitecto). **Pero estrenamos el proceso anti-ping-pong**
(`docs/protocolos/estandar-adversarial-desarrollo.md`): 3 revisores adversariales del
Arquitecto atacaron el paquete ANTES de notificar a Juan. Resultado: **4 críticos y ~8 medios
que Juan habría cazado en su tercera auditoría — esta vez los encontramos nosotros**:

1. **Writer nº 9 sin gate:** hay 10 writers de `whatsapp_sessions`, no 8 — `Update Phase in DB`
   quedó fuera del universo y puede regresar la fase de una sesión pagada a `payment_pending`
   (re-enganche a cliente que ya pagó). `Update Activity` comparte el hueco.
2. **Auto-rollback determinista del runbook:** el fingerprint del sub-workflow compara el id
   placeholder del build contra el id que genera el servidor → NINGUNA ventana real podría
   completarse; el verify nunca se calibró contra la forma real de la API (los backups de
   Fase 0 estaban en el repo para hacerlo).
3. **root↔activeVersion contradictorio** (los backups prueban que la API sí expone el campo,
   pero un comentario vigente de 6.7 dice que viene rezagado post-PUT → rollback en falso).
4. **Readiness del trigger fail-open cross-schema** (el fake de Juan sobrevive un schema más
   allá).

**Handoff Fase 6.8.1 entregado** (`Agente-n8n:handoffs/2026-07-29-fase6-8-1-pasada-adversarial-arquitecto.md`,
commit `0cff96b`). Juan NO ha sido notificado de la 6.8 — solo se le notifica cuando 6.8.1
cierre y re-verifique.

**Para la llamada (actualiza el árbol de decisión anterior):**
- Si 6.8.1 cierra esta noche y re-verifica en verde → notificar a Juan a primera hora con 6.8 +
  6.8.1 juntas y el relato del proceso nuevo ("tu método ya corre de nuestro lado ANTES de
  entregarte") — es el mejor argumento posible para mantener vivo el GO del viernes.
- Si no cierra → llevar a la llamada la 6.8 con los hallazgos propios declarados y proponer
  lunes 3-ago; la transparencia de "nos auto-cazamos el writer nº 9" vale más que llegar
  "en verde" y que lo cace él.
- Narrativa clave para Juan: adoptamos su metodología como estándar permanente (checklist de 10
  heurísticas destilada de sus 2 auditorías) + pasada adversarial obligatoria pre-notificación.
  Proponerle el paso 3: suite negativa COMPARTIDA como criterio de aceptación común.

---

## ACTUALIZACIÓN 29-jul ~23:30 — 6.8.1 CERRADA, CERTIFICADA Y NOTIFICADA A JUAN (ciclo autónomo, 1ª vuelta)

El ciclo autónomo completó su primera vuelta sin intervención: el Agente n8n entregó la 6.8.1
(`b74d9b4`), el Arquitecto la reprodujo (JS 331 × ambos flavors, Python 118, 0 fallos) y el
re-chequeo adversarial independiente la dio por **cerrada a la clase** (el auditor regeneró los
workflows built y reprodujo la enumeración de writers por su cuenta). Los 4 críticos + 8 P1 +
P2 declarados: cerrados. **Juan notificado** (issuecomment-5125749001) con el rango
`1424163..b74d9b4`, la narrativa del proceso nuevo y la propuesta de suite negativa compartida.

**Hallazgo transversal propio, verificado en ambos repos (nota declarada a Juan):** con el gate
nuevo, `last_activity` se congela durante takeover humano/Metepec. El followup de estancados
(`whatsapp_checkpoint_followups.py`, lado Juan) NO filtra `human_takeover` → una conversación
atendida por humano parecería estancada (riesgo de re-enganche automático; hoy dry-run). Le
pedimos la exclusión (1 WHERE) antes de activar envío real. Dashboard: impacto solo
cosmético/métrico (contador abandonados 48h, orden inbox) — pendiente menor nuestro para el
Agente Dashboard, sin urgencia.

**Estado para la llamada:** todo entregado y en verde de nuestro lado. El GO del viernes
depende de: (a) re-auditoría de Juan del rango completo, (b) su preflight read-only en STG,
(c) el WHERE de followups si decide activar envío real cerca de la ventana. La disyuntiva
viernes-vs-lunes se decide en la llamada — llegamos con la mejor posición posible: dos fases en
una noche, 4 críticos auto-cazados y el método de Juan institucionalizado.

---

## ACTUALIZACIÓN 30-jul ~03:45 UTC — TERCERA auditoría de Juan: CONVERGENCIA CALIBRADA (esto cambia el tono de la llamada a positivo)

Juan re-auditó `b74d9b4` (issuecomment de las 03:42 UTC) y el resultado es el mejor posible sin
ser GO inmediato:

- **Reprodujo y confirmó toda nuestra certificación** (JS 327/330, Python 118, 16 writers con
  lock en su escaneo independiente). "Las mejoras de 6.8/6.8.1 son reales."
- **ACEPTÓ la suite negativa compartida** (nuestra propuesta anti-ping-pong).
- **CALIBRÓ el cierre — fin del ciclo abierto de perfeccionamiento:** 7 bloqueantes concretos
  con criterios de aceptación explícitos + lista de riesgos DIFERIDOS que "no abrirán otra
  ronda bloqueante". Con los 7 verdes → **GO técnico para preparar la ventana STG en shadow**.
  Su re-verificación será limitada a esos 7 contratos.
- Los 7 (resumen): (1) rebase sobre `stg` vigente + fix `binaryMode` 400; (2) `qc:` inválido
  terminal por ALCANZABILIDAD de grafo (su parser-fuzzing resolvió `qc:garbage`); (3) carrera
  de Payment que consume el pago sin completar sesión (el hallazgo más serio); (4) respuesta
  IA stale se envía aunque `writer_rows=0`; (5) Metepec inserta lead y manda correo ANTES del
  gate; (6) TOCTOU de takeover/liberación humana; (7) activeVersion/rollback/guard de destino
  del DDL.
- Su lado mientras tanto: Django en shadow, followups APAGADOS/dry-run (recoge nuestra nota de
  `last_activity`), preflight a repetir, #135 congelado offline.

**Hecho ya (ciclo autónomo, iteración 2 de 2):** handoff 6.8.2 pusheado (`c65c98a`, el loop
del ejecutor lo recoge solo) con alcance ESTRICTO a los 7 y la advertencia de no tocar
diferidos; acuse a Juan publicado (issuecomment-5126165367) aceptando el marco y proponiendo
concretar la suite compartida post-ventana como `test/negative-suite/` versionado.

**Para la llamada de las 10:00 — el guion cambia:**
- Ya NO es "defender el paquete": es confirmar la secuencia operativa que el propio Juan
  enumeró (contención/preflight → DDL autorizado → import shadow → E2E vivo → dual con GO
  conjunto) y ponerle fechas.
- Si la 6.8.2 está entregada y certificada antes de la llamada → pedir su verificación de los
  7 en la propia llamada o inmediatamente después, y la ventana del viernes 13:00 es
  plausible; si no, viernes se convierte en "ventana de preparación" y el import real va al
  lunes — decisión de Alberto con Juan.
- OJO límite del ciclo autónomo: la 6.8.2 es la iteración 2 de 2. Si la re-verificación de
  Juan sobre los 7 saliera con hallazgos nuevos, el Arquitecto NO itera solo — lo trae a
  Alberto (y a esa altura sería señal de discutir enfoque en la llamada, no de parchear).

---

## ACTUALIZACIÓN 30-jul madrugada — 6.8.2 ENTREGADA, CERTIFICADA Y NOTIFICADA (ciclo completo; pelota en Juan)

El ciclo autónomo cerró su segunda y última vuelta: el ejecutor entregó la 6.8.2 (`19e98c5`),
el Arquitecto la reprodujo (**JS 394 × ambos flavors, Python 149, 0 fallos** — concurrencia
con Postgres real incluida) y la pasada adversarial acotada a los 7 dio **los 7 contratos
CERRADOS**, diff completo (41 archivos) dentro de alcance, diferidos intactos. **Juan
notificado** (issuecomment-5131822493) con las notas declarables:
1. Punto 6b: ventana residual sub-sentencia (revocación en tabla de claims mientras la reserva
   espera el lock — EPQ no aplica cross-tabla). Su reproducción exacta SÍ está cerrada; se le
   propone decidir si va a diferidos o a E2E.
2. Punto 5: validación inicial (no continua) para motivos no-renovación — decisión declarada.
3. `binaryMode` fuera del PUT/rollback — reponer a mano post-ventana si algún flujo necesita
   media.
4. Guard de destino validado con conexión read-only a STG (0 escrituras, declarado).

Piezas nuevas reutilizables: helper de alcanzabilidad de grafo (`test/helpers-graph.js`) y
guard de destino (`port132_target_guard.py`, 2 capas + `--confirm-target-db`, pre-DDL).

**Posición final para la llamada de las 10:00:** TODO nuestro lado está entregado y
certificado. Falta solo la verificación de Juan de los 7 (su compromiso: verde = GO técnico
shadow, sin más rondas). La llamada idealmente ARRANCA con su verde (o lo ejecuta en vivo) y
pasa directo a fechas de la secuencia operativa: contención/preflight → DDL autorizado (con
`--confirm-target-db`) → import shadow → E2E vivo → dual con GO conjunto. Presupuesto
autónomo agotado: cualquier hallazgo nuevo de Juan vuelve a Alberto, no al ciclo.

---

## ACTUALIZACIÓN 30-jul ~10:20 — cuarta revisión de Juan (2/4/5/6/7 FAIL) → 6.8.3 entregada y notificada (iteración 3/3, presupuesto AGOTADO)

Secuencia de la mañana, toda por el ciclo autónomo:
1. Juan verificó `19e98c5`: contratos 1 y 3 PASS; 2/4/5/6/7 FAIL por 4 hallazgos (el crítico:
   los 5 IF nuevos serializados PLANOS cuando n8n v2.3 exige `fixedCollection` anidada — los
   tests de alcanzabilidad elegían rama a mano, falso verde de integración). Rechazó como
   diferidos la decisión del punto 5 y la ventana residual del 6b.
2. Handoff 6.8.3 (`af388a7`) con sus correcciones exactas; estándar ampliado con heurística
   11 (validar artefactos contra el schema real del consumidor) y corolario EPQ cross-tabla.
3. El ejecutor entregó `843ac43`; reproducción Arquitecto: **JS 431 × ambos flavors, Python
   160, 0 fallos**; adversarial con verificación independiente de H1 (transform in-memory +
   emulador de condiciones propio): **los 4 hallazgos CERRADOS**, diff dentro de alcance,
   heredados byte-intactos.
4. **Juan notificado** (issuecomment-5133067666) con 2 riders menores declarados (invariante
   H1 de los 3 workflows no-Main corre sobre base, no built; guard InitPlan asimétrico en
   `session_fence` — ambos fail-closed, no violan contrato).

**PRESUPUESTO AUTÓNOMO AGOTADO (3/3).** Lo que Juan responda va a Alberto, no al ciclo. Si su
quinta revisión trae hallazgos nuevos, recomendación firme del Arquitecto: sesión síncrona de
pairing (Alberto + Juan + agentes en vivo) en lugar de otra ronda asíncrona — el patrón de
convergencia es real (cada ronda encuentra menos y más fino: 10 → 10 → 7 → 4 → ¿0?) pero el
método asíncrono tiene coste de ~medio día por ronda. La ventana del viernes ya no es
defendible; lunes 3-ago es la propuesta honesta.

---

# 🟢 RESULTADO FINAL 30-jul ~11:10 CDMX — GO TÉCNICO DE JUAN (matriz 7/7 PASS)

Tras SEIS pasadas de auditoría (10→10→7→4→3→0 hallazgos), Juan dio el **GO técnico para
preparar la ventana STG en shadow** sobre **`f33abf8`** (SHA congelado de ventana; cualquier
commit posterior a la rama = re-apertura que exige su re-verificación). Su verificación final:
458 JS × ambos flavors + 166 Python + invariante de 6 artefactos/31 IF + carreras con
conexiones reales — 0 hallazgos nuevos. Quinta y sexta ronda cerradas por el ciclo con
autorización expresa de Alberto (6.8.5: sub-workflow IF, reserva Metepec INSERT→Gmail con TTL,
active en rollback final).

**El GO NO autoriza cambios vivos.** Secuencia pactada (cada paso con autorización explícita):
1. Ambos lados quietos: Django shadow, followups off, dry-run, cero cambios a la rama.
2. Juan publica preflight read-only sin FAIL. ← ESPERANDO ESTO
3. Checkpoint/autorización de Alberto con Juan → fechar y ejecutar DDL
   (`--confirm-target-db`) + import n8n en STG. ← DECISIÓN DE FECHAS DE ALBERTO
4. E2E en shadow (Agente QA disponible) + evidencia de rollback real.
5. `dual` solo con GO conjunto posterior + observación + rollback disponible.

Acuse publicado: issuecomment-5133942154. Post-ventana pendiente: concretar la suite negativa
compartida (`test/negative-suite/`) como criterio de aceptación común. #135 sigue
offline/draft. Juan no cierra #132 hasta completar la secuencia (correcto: deploy ≠ cierre).

---

# ✅ VENTANA STG EJECUTADA — 30-jul ~12:15 CDMX (paso 3 de la secuencia COMPLETO)

Juan autorizó por canal directo ("subamos ya"); Alberto instruyó al Agente n8n con el handoff
de ventana (`ef85e35`). Resultado: **DDL + import n8n con exit 0, sin rollback, PROD
intocado**. Evidencia: `Agente-n8n:docs/2026-07-30-ventana-stg-evidencia.md` (`ce430c3`),
sync a `stg` = `acef1a9`, publicado en #132 (issuecomment-5134625523).

- Target guard validó `dei0jssp8kr5kv` pre-commit. Sub creado: `PuogahK4qv9YOiF4`.
- Única desviación: `--header-auth-cred-id` faltaba en el handoff → el guard del script
  abortó limpio y Alberto confirmó el ID en sesión (`TyxFAIYtKfgHt9cv`). Bien manejado.
- **Verificación independiente del Arquitecto contra el STG vivo:** Main → sub correcto,
  24 IF / 0 planos, 6 tablas, trigger 'O', columnas de fencing desplegadas. Todo verde.

**Quedan de la secuencia:** (2) preflight de Juan publicado sin FAIL + su línea de
autorización en el issue; (4) E2E en shadow (Agente QA — coordinar escenarios: Metepec,
takeover, payment, qc:) + evidencia de rollback real; (5) `dual` con GO conjunto.
También pendiente nuestro: merge Dashboard + env vars Vercel (fase aparte, manos de Alberto)
y la suite negativa compartida post-ventana.
