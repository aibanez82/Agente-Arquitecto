# C1 — Génesis y economía del plan opción C (encargo forense complementario)

> **SRC-ALBERTO-C1-003** · Complementa SRC-ALBERTO-C1-002 · Autor: Agente-Arquitecto · 2026-08-03
>
> **Objeto:** evidencia para validar/refutar H9 ("los planes definidos por IA sin función de coste humana inflan la coordinación"). Sin defensa ni condena del plan: artefactos.
> **Método:** análisis sobre los volcados completos de `aguayo-co/HYL-WAI#140` (issue + 53 comentarios) y `#132` (issue + 272 comentarios) descargados por API, más git local de `Agente-Arquitecto` y `Agente-n8n`. Prefijos `HECHO`/`ESTIMACIÓN`/`UNKNOWN`; las dos clasificaciones que el encargo pide al auditor (P3, P4b) van marcadas como `CLASIFICACIÓN DEL AUDITOR` con su evidencia por fila.

---

## P1. Génesis del plan opción C

### P1a. ¿Qué petición produjo el plan?

**HECHO** — Cadena documentada del 30 jul, las tres piezas publicadas por la cuenta `oilycoyote`: apertura del issue #140 "[Decisión] Separar el rollout de Dual de Atención Humana/Metepec en STG" **con las tres alternativas A/B/C ya redactadas** (body, 2026-07-30T22:05:22Z) → recomendación "C" (c.5136826715, 22:16:02Z, **11 minutos después**) → plan completo C0–C9 (c.5137216437, 23:12:37Z).

**HECHO** — Residuos del encargo en los propios textos: el body abre con *"La intuición de que el enredo comenzó al mezclar Dual con Humano/Metepec es correcta"* — **sin identificar de quién es la intuición**; el plan abre con *"**Decisión de producto comunicada en esta solicitud:** adoptar la opción C"* — la "solicitud" no está en ningún tracker; y cierra declarando un pipeline previo no publicado: *"dos pasadas adversariales bloquearon borradores previos. La revisión final confirmó `PUBLICAR` sin P0/P1"*.

**HECHO** — Lado Arquitecto: cero commits en la ventana que cubre apertura/recomendación/plan (hueco `070dc2c` 16:53−06:00 → `be65dbd` 19:08−06:00); el primer commit posterior ya ejecuta el plan (`be65dbd`, "C0 baseline y freeze (opcion C)"). Ese doc cita dos autorizaciones: la de Juan rastreable (c.5137954763) y la de Alberto ("lanza la preparación de C0") **sin referencia** — conversacional.

**UNKNOWN** — Quién pidió el plan, con qué palabras y con qué restricciones. El encargo fue conversacional en el lado `oilycoyote`; búsquedas en #132 (28–30 jul) y en `docs/` del Arquitecto: 0 hits.

### P1b. Opciones A y B por escrito

**HECHO** — Existen, ambas en el body de #140 (oilycoyote, 22:05:22Z):

- **A. Rollback técnico al punto pre-Humano/Metepec** — *"Candidato histórico: `ce3ce85`. Ventaja: superficie menor para reconstruir Dual."* Descarte literal (5 riesgos): *"elimina también mejoras posteriores no relacionadas; deja workflows antiguos frente a DDL/migraciones ya aplicados; descarta el port dual-safe ya construido; obliga a repetir transform, import, E2E y rollback; no elimina el último fallo encontrado, porque estaba en el núcleo Dual (`Resolve Session`/Payment), no en Humano/Metepec."*
- **B. Mantener el alcance actual de #132 hasta certificar todo junto** — *"Ventaja: una sola certificación transversal."* Descarte: *"mantiene Humano, Metepec, Dashboard y Payment en el camino crítico de la activación de Dual, prolongando el ciclo."*
- **C** (elegida): el body no trae fases aún; trae "Gates propuestos si elegimos C" (7 gates) y *"**Elegir C.** No ejecutar rollback técnico mientras `shadow` sea estable…"*. Refuerzo del descarte en c.5136826715 ("Qué evitar"): *"La opción A vuelve a una base más simple, pero no resuelve la arquitectura futura y descarta el trabajo seguro ya incorporado. La opción B mantiene el acoplamiento…"*

### P1c. ¿Alternativa mínima?

**HECHO** — Ninguna opción se formuló como "menos fases/menos gates": las fases y gates **solo existen en C** (A y B no traen estructura de fases). La opción de menor superficie declarada era A; la de una sola certificación, B. Las tres opciones, sus ventajas y sus descartes fueron **redactados por el mismo autor en el mismo documento**, y el descarte confirmado 11 min después por el mismo autor. No hay en #140/#132 ninguna contrapropuesta de un tercero de una variante más ligera. Alberto aprobó C **71 segundos** después de publicarse el plan, sin contrapropuesta (c.5137223537: "OPCIÓN C, conforme al plan de trabajo revisado").

---

## P2. Economía del plan

### P2a. Estimaciones previas al GO (c.5138861034)

**HECHO** — **No existe ninguna estimación de duración, esfuerzo o número de rondas** para C1 ni para C0–C5 en: body #140, plan, recomendación, aprobaciones, re-scope, ni en el doc C0 del Arquitecto (greps por hora/día/semana/esfuerzo/estimación/ronda/iteración/ETA: 0 hits de estimación). Los únicos números temporales del plan son ventanas operativas y RTOs (C4 "60 minutos", C5 "24 horas", §11 RTO ≤5/≤20 min), no estimaciones de esfuerzo.

**HECHO (contraste)** — En el ciclo inmediatamente anterior (port 6.8.x) SÍ existía función de coste humana explícita: `docs/protocolos/ciclo-autonomo-port132.md` — *"Máximo 2 iteraciones autónomas Arquitecto↔ejecutor por paquete sin intervención"* (commit `5e83c8e`, 29 jul, "a petición de Alberto"), ampliado a 3 por decisión de Alberto (`f3e702d`, 30 jul 08:30−06:00). Ese presupuesto **no se trasladó a C0–C5**: el fichero no vuelve a tocarse después del 30 jul.

### P2b. ¿Alguien cuestionó el coste?

**HECHO** — **En los trackers: 0 casos** (greps coste/caro/lento/alargando/burocracia/overhead/excesivo: solo usos no económicos). **En git: 1 caso**, del Arquitecto (IA) hacia el ejecutor (IA), no hacia el plan: `Agente-n8n:handoffs/2026-08-01-estandar-rigor-cerrar-c1.md` (`f4bfa85`, 2026-08-01T04:02:34Z): *"Esta fase se está alargando por fallos evitables —de mi lado y del tuyo—. Alberto nos pide a ambos el mismo nivel. […] el objetivo es **cerrar C1 y dejar de iterar**"*; *"'Construir por adelantado para ganar tiempo' cuando la decisión que lo delimita está pendiente **no ahorra tiempo**: generó una limpieza más cara que esperar."* El texto atribuye el alargamiento a fallos de ejecución y cita una intervención humana sobre **calidad** ("el mismo nivel"), no sobre el coste del diseño del plan. **Ningún actor cuestionó por escrito el coste del plan o de un control como tal durante C1.**

### P2c. Propuestas de eliminar/simplificar controles (todas, con resolución)

| # | Control | Propuso | Resolvió |
|---|---|---|---|
| 1 | Suplente humano → **operador único** | aibanez82, #132 c.5152822925 (08-01T18:35Z): *"no existe un segundo humano operativo con acceso a STG […] solicita al A enmendar expresamente el RACI […] en lugar de nombrar un suplente humano inexistente"* | oilycoyote, #140 c.5153952626 (23:19Z): *"se acepta la excepción […] para operar C1 con un único operador humano"* + 6 controles compensatorios |
| 2 | **Ventana calendarizada** (3-ago) → sincronización inmediata | Propuesta publicada por oilycoyote, #132 c.5153971787 (23:24Z) | oilycoyote, #140 c.5153977172 (**104 s después**): *"Esta regla elimina espera administrativa, pero no elimina los gates del plan"* — ambos textos, misma cuenta |
| 3 | **Criterio 3f** (sonda autenticada `403`) → acreditación de configuración | aibanez82, #132 c.5154417314 (08-02T01:26Z): *"Es un **catch-22**: obtener sesión exige BD, este Preview no la tiene"* | oilycoyote, c.5154440416 (5,9 min): *"acepto la opción A […] modifica **únicamente** el criterio 3f de esta corrida"* |
| 4 | **GO humano por fase** eliminado + **24 h de C5** eliminadas | Sin propuesta externa registrada — autoemitida: oilycoyote, #140 c.5154662330 (08-02T02:24Z): *"No se exigirá un nuevo comentario humano de GO por cada fase viva C1–C5"*; §3: *"Se elimina el requisito de observar 24 horas"* | Autoemitida por el A; monitor la aplica en c.5154663793 (22 s) |
| 5 | **60 min de C4** eliminados (post-C1) | oilycoyote, #132 c.5160209145 (08-02T20:31Z): *"STG es cerrado y no tiene tráfico orgánico"* | Autoemitida |
| 6 | **Emisión del GO delegada al monitor** (post-C1, 3 ago) | oilycoyote, #140 c.5162421678 | Autoemitida |
| 7 | Repetir corrida → **aceptar desviación** | aibanez82 declara la omisión (c.5155662487) | oilycoyote, c.5157632531: *"repetir, completar retroactivamente o hacer rollback ahora añadiría más riesgo"* |

**HECHO** — Patrón numérico de la tabla (sin interpretar): las 7 simplificaciones ocurrieron **durante o después** de la ejecución; ninguna antes del GO. 4 de 7 fueron autoemitidas por el lado accountable sobre controles de su propio plan; 3 nacieron de imposibilidades materiales encontradas al ejecutar (sin segundo humano, sin BD en el Preview, corrida ya consumada).

---

## P3. Clasificación de las 13 enmiendas (tabla A3 de SRC-ALBERTO-C1-002)

**CLASIFICACIÓN DEL AUDITOR** sobre el disparador citado en cada texto (evidencia por fila; la columna final responde "¿el criterio pudo haberse escrito en el plan original?"):

| # | Ref | Clasificación | Artefacto que la justifica | ¿Pudo estar en el plan original? |
|---|---|---|---|---|
| 1 | #132 c.5137997287 (re-scope) | ADMINISTRATIVA | Ejecuta el punto C0.2 del propio plan tras las dos aprobaciones | SÍ — estaba (es C0.2) |
| 2 | #140 c.5138861034 (GO C1) | ADMINISTRATIVA | Avance de fase previsto; cierre de C0 | SÍ — gate previsto |
| 3 | #140 c.5139480586 (delimitación GO) | ADMINISTRATIVA | *"aclara quién puede empezar ya y hasta dónde llega la autorización"*; cita discrepancia documental de c.5138901100 | SÍ — la distinción construcción/operación era definible ex ante; la ambigüedad estuvo en el GO, no en un hecho nuevo |
| 4 | #140 c.5147782653 (NO-GO + criterios) | REACTIVA | Fallos OBSERVADOS y reproducidos: *"Un FAKE […] saltó el gate y aun así allowlist […] terminaron verdes"*; GHSA `next@14.2.3`; dispatch sin claim con HTTP 200 | NO — los criterios nuevos derivan de hallazgos concretos; el principio general (fail-first) ya estaba en el plan |
| 5 | #140 c.5149044773 (9 requisitos checkpoint) | ANTICIPATORIA | Protege la ventana viva aún no ejecutada (SHAs inmutables, comandos exactos, stop/RTO/rollback, evidencia); ningún incidente de ventana había ocurrido | SÍ — son requisitos estándar de ventana operativa; el plan §11 ya traía RTOs |
| 6 | #132 c.5152112808 (gate RACI) | ADMINISTRATIVA | Aplica el RACI del propio plan; *"no falta código"* | SÍ — la inexistencia de un segundo operador era un hecho conocido ex ante; el plan exigía un rol que el equipo real no tenía |
| 7 | #140 c.5153952626 (RACI operador único) | REACTIVA | Responde al bloqueo administrativo observado de la fila 6 (solicitud c.5152822925) | SÍ — misma razón: el equipo siempre tuvo un solo operador |
| 8 | #140 c.5153977172 (sin ventana calendarizada) | ADMINISTRATIVA | *"Esta regla elimina espera administrativa"*; ningún fallo citado | SÍ — "STG usa sincronización inmediata" es una propiedad del entorno verdadera desde el día 0 |
| 9 | #132 c.5154440416 (3f sustituido) | REACTIVA | Imposibilidad OBSERVADA (catch-22 `DATABASE_URL` del Preview congelado, verificada en c.5154417314) | UNKNOWN — el criterio 3f nació en el GO (mismo día), no en el plan; su imposibilidad era detectable con inspección previa del Preview, pero no hay artefacto que lo demuestre anticipable |
| 10 | #132 c.5154563080 (ruta mínima + 6 requisitos) | REACTIVA | STOP real de la corrida 1 (c.5154508007): *"`pausa → B` es imposible en `5fcc060`"* | NO — deriva de un defecto de interacción solo observable en vivo (E2 de SRC-002); dos de los 6 requisitos (verifier GET-only, regresión integrada) eran formulables ex ante |
| 11 | #140 c.5154662330 (7 condiciones; elimina GO/fase y 24 h) | REACTIVA (disparador) | §5: *"La corrida C1 anterior terminó en STOP y su GO quedó consumido"* | SÍ — la justificación de las eliminaciones (*"STG es cerrado y las pruebas son sintéticas"*) era una propiedad del entorno conocida el 30 jul: las 24 h de C5 y el GO-por-fase pudieron no exigirse nunca |
| 12 | #132 c.5155066043 (SHA retirado) | REACTIVA | Hecho OBSERVADO: push de prep C2 mezclado en el candidato durante la corrección | SÍ — la regla violada ("dejar C2 explícitamente fuera") ya existía desde c.5149044773 |
| 13 | #132 c.5157632531 (cierre por excepción) | REACTIVA | Desviación OBSERVADA y declarada (c.5155662487, c.5155678719) | NO — resolución de una contingencia; una política genérica de desviaciones aceptables habría sido escribible, pero no este caso |

**HECHO (recuento de la tabla)** — REACTIVAS: **7** (filas 4, 7, 9, 10, 11, 12, 13) · ADMINISTRATIVAS: **5** (1, 2, 3, 6, 8) · ANTICIPATORIA: **1** (5). Columna "¿pudo estar en el plan original?": **SÍ: 9 · NO: 3 · UNKNOWN: 1**. De las 5 administrativas, 3 (filas 3, 6, 8) gestionan fricciones creadas por reglas del propio plan contra hechos del entorno conocibles el día 0 (autorización ambigua, rol inexistente, ventana innecesaria).

---

## P4. C0–C5 completo

### P4a. Alcance literal de C2–C5 (plan c.5137216437, §5)

- **C2 — "integración STG del núcleo en `shadow`":** *"Usar siempre el término **integración STG pinneada**, no E2E Meta."* Matriz mínima `E2E-` de 9 puntos: qc malformado terminal; v1/v2 válidos; dos cotizaciones mismo teléfono; afinidad (*"máximo una sesión recuperable `active`"*); variantes `10/52/521`; Payment exacto con *"sink físico antes de Meta"*; regresiones Issue Policy/renovación/fecha inicio; GET/fingerprint post; *"Cleanup solo de IDs `E2E-`, con conteos antes/después"*. Aceptación: *"todos los casos esperados, `updated_count` siempre 0/1, cero cruce, cero claims/derivaciones, cero red y cero drift."*
- **C3 — "cerrar el gap exacto de `pre-dual`":** preflight que enumere *"nombres/tipos/nullability exactos faltantes"*; *"El dueño de `whatsapp_sessions*`/`n8n_chat_histories*` prepara DDL aditivo e idempotente; HYL-WAI valida readiness. No duplicar DDL en otro repo"*; prueba en PostgreSQL 17 aislado; `pre-dual` con *"cero `FAIL` y cero WARN del núcleo"*. Salida: *"GO técnico conjunto para canary; modo todavía `shadow`."*
- **C4 — "canary sintético `dual -> shadow`":** precondiciones (*"backups <=15 minutos, plano vivo denegado, plano aislado verificado, SHAs exactos, flags oscuros […] GO escrito"*); CAS `shadow -> dual` solo STG; *"Observar **60 minutos completos** de ejecuciones exclusivamente sintéticas"*; drill `dual -> shadow`. Stop inmediato: *"cruce de sesión, `updated_count > 1`, más de una `active`, conector no allowlisted, claim/derivación nueva, drift, output incierto o preflight rojo."*
- **C5 — "segundo GO y Dual sostenido en STG":** *"C4 termina obligatoriamente en `shadow`. Un segundo GO separado puede reactivar `dual`."* *"Observar al menos **24 horas** y ejecutar tres matrices cortas separadas […] Solo entonces cerrar #132."* (Enmendado después: c.5154662330 §3 elimina las 24 h y fija final `dual`; c.5160209145 elimina los 60 min de C4.)

### P4b. Producto vs gobernanza/contención

**HECHO previo, determinante para el ratio** — El producto (núcleo Dual: identidad conversacional, afinidad, Payment exacto) se construyó **ANTES del plan**, en el ciclo port 6.8.x (commits de Agente-n8n 07-28 a 07-30, fases 3→6.8.9, cronología en SRC-002 §2). El plan C0–C5 es un plan de **certificación y rollout** de algo ya construido; su única pieza de producto nueva es el DDL del gap de schema (C3).

**CLASIFICACIÓN DEL AUDITOR** sobre los entregables que el plan enumera (§5 salidas + §6 por agente + §7 artefactos obligatorios):

| Fase | Entregables enumerados | Producto | Gobernanza/contención |
|---|---|---|---|
| C0 | autoridad escrita, freeze de SHAs/flags/schema, inventario en-vuelo, fixtures sintéticos | 0 | 6 |
| C1 | gates default-deny (n8n+Dashboard), clones+sinks, tests fail-first de gates/sinks/inventario/alcanzabilidad | 0 | 4 |
| C2 | matriz 9 casos, runner `E2E-`, verifier/fingerprints, cleanup contado | 0 | 4 |
| C3 | **DDL aditivo del núcleo** (schema del feature), preflight exacto, prueba PG17, readiness | **1** | 3 |
| C4 | CAS de modo, canary, drill rollback, evidencia | 0 (el flip a `dual` es transitorio) | 4 |
| C5 | 3 matrices, observación, **`dual` sostenido en STG**, cierre #132 | **1** (habilitación del feature en STG) | 3 |
| §7 | 8 artefactos ejecutables obligatorios (preflights, CAS, inventory, build/verify/run/restore, assert-gates) | 0 | 8 |

**Ratio: 2 entregables de producto / 32 de gobernanza-certificación ≈ 6% / 94%.** (Base: conteo de los ítems enumerados por el propio plan; el clasificador es este auditor. Si se cuenta el port pre-plan como parte de la iniciativa, el ratio de la iniciativa completa cambia — pero eso queda fuera del plan auditado.)

### P4c. Problema de negocio original

**HECHO** — La formulación más antigua encontrada: `docs/iniciativas/conversation-id-whatsapp-n8n.md` (Arquitecto, 12 jul 2026): *"Resuelve de raíz **Issue #21** (confirmado en la auditoría E2E del 11 jul: `sessionId = phoneNumber` literal — un teléfono con 2 cotizaciones activas mezcla ambas conversaciones). Mitiga **#13** (follow-up cotiza forma de pago distinta) y **#20** (duplicados ~9-11%)."* Origen declarado: documento técnico de Juan Aguayo (`aguayo-co/HYL-WAI:docs/reporte-alberto-n8n-conversation-id-whatsapp-meta.md`) proponiendo mover la identidad de `phone_number` a `conversation_id`.

**HECHO** — En #132 (body, oilycoyote, 2026-07-28T03:12:27Z): *"Este issue bloquea el cambio de Django STG a `WHATSAPP_CONVERSATION_ID_MODE=dual`"*; problema literal: *"cuando falta `conversation_id`, actualiza por teléfono y puede completar varias conversaciones"*; principio: *"Nunca seleccionar, completar, liberar ni escribir historial por teléfono como identidad única."* Alberto validó el diagnóstico al día siguiente (c.5099851034: "OK con el diagnóstico (los 4 problemas son verificables)").

---

## P5. Autoría efectiva

### P5a. Indicios verificables (solo literales; sin especulación por estilo)

| Referencia | Indicio literal | Qué indica |
|---|---|---|
| Plan c.5137216437 | Sin firma, sin marker; footer: *"dos pasadas adversariales bloquearon borradores previos. La revisión final confirmó `PUBLICAR` sin P0/P1"* | Declara un pipeline de revisión adversarial previo (vocabulario de proceso automatizado); sin autodeclaración humana |
| GO C1 c.5138861034 | *"- Oilycoyote, humano."* | **Única pieza del corpus con firma humana explícita** |
| Delimitación c.5139480586 | *"Por instrucción directa del accountable humano, este comentario aclara…"* | El texto se declara escrito POR OTRO por instrucción del humano |
| NO-GO c.5147782653 | *"Este dictamen se registra por instrucción directa de `@oilycoyote`, accountable humano"* | Ídem |
| Aceptación c.5149044773 | *"Esta decisión se registra por instrucción directa de…"* | Ídem |
| Enmienda RACI c.5153952626 · GO operativo c.5154091214 · 7-condiciones c.5154662330 · cierre c.5157632531 | *"Por decisión/instrucción directa de `@oilycoyote`, A humano"* + el mismo trailer plantilla ("Responsable siguiente / Tarea exacta / Entrega esperada / Condición / Acciones todavía no autorizadas") que usan los comentarios con marker de monitor | Autodeclaración de decisión humana; formato idéntico al de los comentarios automatizados |
| Contraste: comentarios de monitor | Markers HTML: `issue140-monitor:…`, `issue140-monitor-v2:…`, `transferred-plan-monitor-v3:…`, `plan140-monitor-v4:…` | Los comentarios de monitor se automarcaron; **ninguno de los 9 textos decisorios lleva marker** |

**HECHO** — Resumen verificable: de los 9 textos decisorios, 1 lleva firma humana explícita; 8 se declaran "por instrucción/decisión directa" del humano (redacción delegada) y comparten plantilla con los comentarios automatizados. **UNKNOWN** — la entidad material que tecleó cada uno (la API de GitHub no lo distingue).

### P5b. Latencias publicación→aprobación/acuse

| Decisión | Publicado | Respondido | Minutos |
|---|---|---|---|
| Plan opción C → aprobación de Alberto | c.5137216437 · 23:12:37Z | c.5137223537 · 23:13:48Z | **1,2** (71 s) |
| Recomendación C → aprobación de Alberto | c.5136826715 · 22:16:02Z | c.5137223537 · 23:13:48Z | 57,8 |
| Plan → confirmación de Juan | c.5137216437 · 23:12:37Z | c.5137954763 · 01:02:03Z | 109,4 |
| GO C1 → espejo/acuse | c.5138861034 · 03:15:59Z | #132 c.5138872774 · 03:17:17Z | **1,3** |
| Aceptación offline → primer borrador checkpoint | c.5149044773 · 02:09:39Z | c.5149097301 · 02:13:48Z | **4,2** |
| Solicitud RACI → decisión | c.5152822925 · 18:35:20Z | c.5153952626 · 23:19:17Z | **284,0** |
| Propuesta sin-ventana → enmienda | c.5153971787 · 23:24:26Z | c.5153977172 · 23:26:10Z | **1,7** (104 s) |
| HOLD 3f → enmienda 3f | c.5154417314 · 01:26:21Z | c.5154440416 · 01:32:12Z | **5,9** |
| STOP corrida 1 → FAIL/ruta mínima | c.5154508007 · 01:49:01Z | c.5154563080 · 02:02:16Z | **13,3** (→ enmienda mayor: 35,4) |
| Declaración de omisión → STOP monitor | c.5155662487 · 05:31:16Z | c.5155678719 · 05:34:27Z | **3,2** |
| STOP → cierre accountable | c.5155678719 · 05:34:27Z | c.5157632531 · 11:48:27Z | **374,0** (6 h 14 min) |

**HECHO (patrón numérico, sin interpretar)** — Las respuestas entre las dos cuentas van de 71 s a 13 min; las dos únicas latencias largas (284 y 374 min) corresponden exactamente a las dos decisiones que se autodeclaran "por decisión directa" del humano. La aprobación humana más trascendente (adoptar el plan completo C0–C9) es también la más rápida del corpus: 71 segundos para un documento cuya ejecución de solo su segunda fase tomó 60,6 h de calendario (SRC-002 §G2).

---

## Adenda — Testimonio forense del ejecutor (publicado durante esta auditoría)

**HECHO** — Mientras se redactaba este documento, el ejecutor n8n publicó su propio forense: `Agente-n8n:docs/2026-08-03-testimonio-forense-ejecutor-c1.md` (commit `ea30bad`, 2026-08-04T00:03:54Z, 544 líneas; 33 commits clasificados por causa, 356 tests atribuidos por origen del requisito). Aporta a este encargo:

- **Corrobora P2b desde el otro lado (constancia negativa doble):** el ejecutor barrió sus 28 informes de C1 con dos baterías de términos ("desproporcion|innecesari|no hace falta|…|excesiv|demasiado|caro|coste|bastaría con…") — *"**Cero apariciones** […] en 28 informes y 33 commits no consta que yo calificara ningún requisito de desproporcionado"*. Ningún actor —humano ni agente, en trackers ni en git— cuestionó el coste de un control durante C1.
- **Amplía P2c con 3 propuestas de simplificación del ejecutor** (todas en informes, ninguna en trackers): (d.1) no limpiar con force-push la rama en auditoría — *"es más barato y no toca una rama en auditoría"* (`5dea09e`); (d.2) *"fijar nombre + fingerprint"* en vez de prometer 7 IDs concretos (`6cc5910`); (d.3) línea de vigencia explícita en los handoffs de código (`5b00929`) — *"Hoy no tengo forma de saber que hay un PASS en vuelo: no leo los issues."*
- **Fricción de coordinación no visible en los trackers:** la desviación B→A fue declarada y **pedida en validación 4 veces a lo largo de 10 SHAs** sin respuesta (*"Van diez SHAs. […] Es lo único técnico sin aval de nadie con autoridad"*, `ccfce00`/`a328daf`); dos handoffs vigentes se cruzaron con 6 minutos de diferencia (`5b00929`); y dos intervalos de **6 h 18 m** y **10 h 41 m** en "modo espera" congelado (*"Reviso `handoffs/` en `origin/main` cada 20 min y no toco la candidata"* — acuses `e473e38`, `5b00929`), el segundo cerrado no por un desbloqueo sino por el STOP de la corrida 1.
- **UNKNOWN declarado por el propio ejecutor:** *"Cuánto de cada hueco fue espera real frente a tiempo en que sencillamente no hubo"* actividad del otro lado.

## UNKNOWNs y artefacto necesario

| # | UNKNOWN | Artefacto que lo resolvería |
|---|---|---|
| 1 | Quién encargó el plan, con qué palabras y restricciones (P1a) | Transcripción de la sesión/agente del lado `oilycoyote` del 30 jul, o el hilo directo Alberto↔Juan de ese día |
| 2 | De quién es la "intuición" citada en el body de #140 | Mismo artefacto |
| 3 | Referencia de la orden de Alberto "lanza la preparación de C0" | Log de sesión Claude Code del Arquitecto del 30 jul (local, no sincronizada) |
| 4 | Entidad material que tecleó los 8 textos "por instrucción/decisión directa" (P5a) | Logs del lado oilycoyote; la API de GitHub no distingue |
| 5 | Los "borradores previos" bloqueados por las "dos pasadas adversariales" del plan | Artefactos internos del lado oilycoyote, no publicados |
| 6 | Si la imposibilidad del 3f era anticipable con inspección del Preview (P3 fila 9) | Configuración del Preview congelado a fecha del GO |

Nota: la ausencia de estimaciones (P2a) NO es un UNKNOWN — es una constancia negativa verificada (0 hits sobre corpus completo).

```yaml
audit:
  source_id: SRC-ALBERTO-C1-003
  supersedes_integrity_of: null
  complements: SRC-ALBERTO-C1-002
  author: Agente-Arquitecto
  date: 2026-08-03
  facts_count: 106
  estimates_count: 0
  auditor_classifications: 2   # P3 (13 filas) y P4b (ratio), marcadas y con evidencia por fila
  unknowns_count: 8
  artifacts_cited: 96
  reproducible_from_artifacts: 95%
```
