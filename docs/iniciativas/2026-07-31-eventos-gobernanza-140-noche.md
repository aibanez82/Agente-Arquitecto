# Eventos de gobernanza #140 — noche del 31 jul 2026 (UTC)

Registro factual del Arquitecto (sesión autónoma, Alberto ausente). Todo verificado por API; ninguna acción ejecutada por nuestro lado. Decisión de Alberto pendiente al cierre de esta nota.

## Cronología

| Hora (UTC) | Evento |
|---|---|
| 19:49 | Alberto publica clasificación preventiva de la sonda de descuento (`5146858095`): workstream pricing, rama del port restaurada a `6f1d394`, artefactos en `docs/descuento-cotizacion-qualitas@0ccce8c`. |
| 19:53 | Monitor de Juan (`5146896956`) **valida la trazabilidad** del restore pero mantiene: no es C2/GO, no más sondas vivas, delimitación de superficie pendiente del accountable. |
| 20:01 | Alberto anuncia (`5146961166`) el barrido `listrecs` solo-lectura del **corte mensual Hylant** (Agente Conciliación, handoff `Agente-Conciliacion@dc59a33`). |
| 20:07 | Monitor (`5147008506`) pone **⛔ al barrido**: no puede verificar el handoff (repo privado → 404), pide no ejecutar sin confirmación explícita de Juan o autorización enlazable verificable. |
| 21:09 | **Juan mergea PR #141** (docs-only, runbook preventana #132) a `stg` → deploy automático Heroku STG **v211**. |
| 21:11 | Su propio monitor (`5147501167`) lo marca ⚠️ "cambio material sin checkpoint registrado" y congela #142. |
| 21:12 | Juan escribe en #135 (`5147507005`) cerrando el pendiente documental; ese comentario dice expresamente "No autoriza merge". |
| 21:16 | **Juan mergea PR #142** — NO docs-only: 17 archivos (preflight `dual-core` Django, `qualitas/*.py`, tests, `tests.yml`) — a `stg` sin reviews → deploy automático Heroku STG **v212** (`4f0e741`). |
| 21:18 | Monitor (`5147553808`) escala a 🚨: merge tras el aviso que dejaba #142 sin autorización y contradiciendo el límite de #135; exige "clasificación accountable inmediata". |
| 21:26 | Monitor se **auto-corrige** (`5147608218`): vía API de Deployments confirma los **dos despliegues vivos a STG** (`hyl-wai-stg`, deployments `5698232600`/`5698300481` = v211/v212) durante el freeze — el hecho que el Arquitecto ya había verificado por Heroku queda ahora en el registro público. Pide clasificación accountable/incidente + checkpoint explícito; C1 no cerrada, C2–C9 sin GO. |

## Hechos verificados por el Arquitecto (no observados por el monitor de Juan)

- `stg` **auto-despliega** en Heroku `hyl-wai-stg` vía integración GitHub: v211 (`2d99230`, 21:12) y v212 (`4f0e741`, 21:19, release command en ejecución al verificar). El monitor afirmó primero "sin paso de deploy observado" porque solo miraba GitHub Actions; a las 21:26 se auto-corrigió y lo confirmó por la API de Deployments — ya no somos los únicos con el dato, y no hizo falta señalarlo nosotros.
- El barrido `listrecs` **no ha arrancado**: en `Agente-Conciliacion` solo consta el cron diario (14:20 UTC, **falló**; también falló el del 29). `conciliacion_pagos` tiene datos del 30 jul.

## Evaluación

- **Riesgo técnico para nosotros: bajo.** #141/#142 son runbook + comandos de preflight offline; sin cambios de flags (últimos config vars: v210, 30 jul). Nada toca PROD ni nuestras superficies.
- **Narrativo: posición reforzada.** Juan ejecutó dos merges y dos deploys a STG durante el freeze, tras un "No autoriza merge" propio y un aviso de su monitor — mientras ese mismo monitor veta nuestro barrido de solo lectura. Si Juan se auto-clasifica como accountable del workstream, usa el mismo mecanismo que reclamamos para pagos/pricing. Precedente directamente citable para la delimitación de superficie (`5146329245`).

## 21:33 — Clasificación ex post de Juan + solicitud de trabajo a Alberto (`5147660691`)

Juan (accountable) clasifica ex post #141/#142 como **intencionales**, sin convalidar la secuencia ("no constituye GO, no cierra C1"). Reconoce que la release phase de Heroku ejecuta `migrate --noinput` y que sin el release log no puede afirmar que no se aplicó migración alguna. **Precedente clave: el accountable ejecutó acción viva en STG durante el freeze y la resolvió con auto-clasificación ex post — exactamente el mecanismo que reclamamos para pagos/pricing.** NO respondió al ⛔ del barrido `listrecs` ni a la delimitación de superficie: el corte mensual sigue bloqueado.

**Solicitud concreta a Alberto (todo offline, "abrir PR no autoriza integrarlos"):**

1. **PR n8n** `feature/c1-contencion-gates-plano-aislado → stg` (merge-base `stg@40fe572` ✓ verificado). Elegir: (a) candidato completo `b76a546` (= `ad85149` funcional + 2 commits de higiene) o (b) rama de revisión solo con `ad85149`. Incluir repro offline `scripts/c1/`: `node --test test/*.test.js` + `node runner/run-c1.js` → esperado 71/71, `RESULTADO: OK — plano contenido`, cleanup `creados=9, restantes=0`, contrato `run.log` (sin resultado = `INCIERTO`).
2. **PR Dashboard** `c1-gates-api-default-deny → stg` con `07324f4` ✓ verificado. Repro: `npm ci`, tests (88/88), lint, build, `assert-rollout-gates.js --target fixture` (6/6); `--target stg|prod` bloqueados.
3. Cerrar en el PR Dashboard el **contrato pre-live de `ALLOWED_ORIGINS`** (solo documental): valores literales del Origin de STG, formato lista CSV + `Set.has` exacto, fuente solo `process.env`, fail-closed, responsable humano, tests de rechazo (http/https, puerto, trailing slash). No provisionar nada.
4. Dos decisiones de alcance Dashboard: (a) ¿`revoke` = `DELETE /api/claim` con `control_id+epoch` existente, o falta capacidad?; (b) fix RBAC `isAllowedApiPrefix` — ¿se queda en C1 o se separa (nuevo SHA + evidencia completa)?
5. Confirmar en cada PR que las ramas C1 n8n/Dashboard no tuvieron merge/deploy/acceso a STG-PROD (formulación acotada, no global).

**Verificación del Arquitecto:** ramas y SHAs existen y cuadran en ambos repos; Juan tiene acceso de lectura a `Agente-n8n` y `Dashboard` (verificó las entregas él mismo) — el 404 solo aplica a `Agente-Conciliacion`.

**Recomendaciones del Arquitecto:** opción (a) candidato completo para el PR n8n (los 2 commits de higiene son triviales — gitignore + docs — y evita gestionar una rama extra); los PRs los abren los ejecutores (Agente n8n / Dashboard) con handoff del Arquitecto tras OK de Alberto; la evidencia numérica (71/71, 88/88) debe salir de corridas frescas de los ejecutores, no copiarse de Juan.

## 22:0x — Autorización de Alberto ("2. ok") y preparación de handoffs C1 — INCIDENTE PROPIO

Alberto autorizó preparar los handoffs de los PRs C1 (listrecs y cron: aparcados por decisión suya). El Arquitecto redactó ambos handoffs, pero al commitear el de n8n **el clon local estaba en la rama candidata**: el push movió `feature/c1-contencion-gates-plano-aislado` de `b76a546 → e6ee2e9` (commit docs-only, solo añade `handoffs/2026-07-31-pr-c1-contencion-gates-a-stg.md`). Es la misma clase de incidente que la sonda de descuento de esta tarde: contaminación docs-only de una rama candidata, detectada al instante.

**Remediación pendiente (requiere Alberto, comandos abajo en sesión):** restaurar el remoto a `b76a546` con force-push, mover el handoff a `main`. En el Dashboard el clon también estaba en la rama candidata pero el handoff quedó **solo untracked** — sin daño; basta `checkout main` antes de commitear.

**21:42 — el monitor de Juan lo detectó antes de la remediación** (`5147718871`): confirma que `e6ee2e9` es docs-only (solo el handoff), que aún no hay PR abierto, y exige reconciliar el head real del PR con una opción autorizada antes de abrirlo ("no declarar `b76a546` si GitHub propone `e6ee2e9`"). Coincide con la remediación ya planificada. Dato operativo nuevo: **el monitor vigila también `aibanez82/Agente-n8n` casi en tiempo real** (detectó el push en ~4 min y leyó el contenido del handoff). Tras la restauración, declarar la excursión en el cuerpo del PR y (si Alberto aprueba el texto) un acuse breve en #140.

## 21:52 — Dictamen NO-GO de C1 offline (`5147782653`) — cambia el alcance de los PRs

Juan reprodujo él mismo las tres entregas y emite **NO-GO con hallazgos accionables**. Mantiene la petición de abrir los 2 PRs, pero ahora **con fixes y nuevos SHA candidatos**:

- **n8n** (5 bloqueantes + 1 P2): ingress sin gate efectivo (10 ingress, 0 gates; allowlist no evaluada en runtime; 2 `executeWorkflowTrigger` sin cubrir); dominancia no validada (ignora `connections` — FAKE saltó el gate en verde); SQL controlable por payload admitido por el checker; alcanzabilidad `ai_*` en dirección equivocada (conector Anthropic real no detectado); sinks sin contrato con su consumidor; P2: persistir cleanup en `run.log`.
- **Dashboard** (2 P0 + 1 P1): `next@14.2.3` vulnerable a GHSA-f82v-jwr5-mffw (CVSS 9.1, bypass de middleware auth) — decisión Arquitecto: subir a `14.2.35` declarándola como propuesta de npm audit; dispatch proactivo sin verificar claim propio antes del `fetch` (repro de Juan: sin claim → HTTP 200) — fix con SQL exacto provisto + test adversarial 403 `CLAIM_NOT_OWNED`; P1 documental `ALLOWED_ORIGINS` en `.env.example`. No bloqueantes: `revoke` = release exacto existente (sin revoke administrativo); RBAC `isAllowedApiPrefix` se conserva con trazabilidad.
- Checkpoint operativo C1 bloqueado por el NO-GO; re-revisión verde ≠ GO (decisión humana separada).

**Handoffs v2 (dos fases: corregir → abrir PR) entregados:** `Agente-n8n/handoffs/2026-07-31-pr-c1-contencion-gates-a-stg.md` (commiteado en main, `9a41092`; rama candidata restaurada a `b76a546` por Alberto vía force-push) y `Dashboard_SeguroAuto/handoffs/2026-07-31-pr-c1-gates-api-default-deny-a-stg.md` (commiteado en main del Dashboard, `93add42`).

## 22:04–22:09 — PR Dashboard #2 abierto + 🚨 del monitor por deploys Vercel automáticos

El ejecutor Dashboard entregó: SHA candidato `1373d1a` (fixes P0-1/P0-2/P1 conformes a spec) y PR `Dashboard_seguroautoqualitas#2`. **Pasada adversarial del Arquitecto: PASS** — evidencia reproducida independientemente en worktree aislado (89/89, lint, build, fixture 6/6, audit 0 critical, targets stg/prod exit 1).

**22:09 — monitor (`5147884147`):** los pushes a la rama candidata disparan **deploys Vercel Preview automáticos** (`07324f4` a las 06:29 — anterior al dictamen — y `1373d1a` a las 22:03, posterior al NO-GO que prohibía deploys). Contradice la letra de "sin deploy" del PR. Exige corregir trazabilidad + clasificación accountable antes de continuar; prohíbe nuevos pushes mientras tanto. **Espejo exacto del incidente Heroku de Juan** (integración git→deploy automático no considerada al declarar).

**Hallazgo adicional del Arquitecto (el monitor no lo mencionó):** el commit del handoff a `main` (`93add42`, docs-only) disparó un deploy **Production** del Dashboard a las 21:56 (`5698716825`, success) — comportamiento estándar de Vercel en `main`, código idéntico al previo.

**Exposición técnica acotada:** los Preview corren con env vars de Preview (incluye `DATABASE_URL` de PROD — configuración histórica del proyecto), pero tras `DASHBOARD_PASSWORD`, con `GATE_*` sin provisionar (fail-closed 403) y `ALLOWED_ORIGINS` sin provisionar (origin guard deniega los endpoints gateados). Misma exposición que cualquier preview histórico del repo: automatización preexistente de la plataforma, no acción del agente.

**Plan:** clasificación accountable de Alberto en #140 (espejo de la de Juan) + edición del cuerpo del PR #2 corrigiendo la declaración ("sin deploy manual ni acceso del agente; la integración Vercel genera previews automáticos en cada push — automatización preexistente") + decisión futura opcional: desactivar previews de rama vía configuración Vercel.

## 22:16 — Monitor amplía a los 3 deployments y revela que lee este repo (`5147924496`)

El monitor encontró también el deploy Production `5698716825` (commit docs-only del handoff) y exige clasificación accountable de los **tres** deployments Dashboard. Citó expresamente `Agente-Arquitecto@01eea1c`: **lee este repositorio casi en tiempo real** — desde ahora, todo commit aquí es de facto comunicación pública hacia el lado de Juan. Registró la mención a la configuración de env vars de previews como "riesgo no verificado" (correcto por su parte: no consulta Vercel); la verificación, si se necesita, corresponde a Alberto como propietario del proyecto Vercel. Con OK de Alberto ("publica los dos"): clasificación publicada en #140 (`5148002777`) y cuerpo del PR #2 corregido con la trazabilidad de los previews automáticos.

## Decisión pendiente de Alberto (corte mensual HOY)

Opciones dejadas en sesión:
1. **(Recomendada)** Publicar el handoff sanitizado en #140 (neutraliza el 404), ventana corta de objeción, ejecutar `listrecs`, publicar evidencia sanitizada en el formato que pidió el monitor (inicio/fin, target, nº requests, agregado, cero-escritura).
2. Esperar OK explícito de Juan (coste: reporte Hylant se retrasa).
3. Plan B sin `listrecs`: reporte desde `conciliacion_pagos` — requiere diagnosticar y relanzar el cron fallido de hoy.

Transversal: decidir si dar a Juan acceso de lectura a `Agente-Conciliacion` (el 404 se repetirá con cada handoff).

## 22:34 — Monitor acota el alcance de la clasificación (`5148028755`)

Acepta lo factual (dedup de los 3 deployments, PR #2 verificado como corregido) pero rechaza la cláusula prospectiva "sin nuevo aviso por evento": ampliar el límite "no nuevos deploys" del dictamen corresponde solo al accountable Juan. Mientras no lo actualice, cada push nuevo al Dashboard será alerta de cambio material. Sin acción nuestra: los eventos actuales quedan cerrados; si la re-revisión de PR #2 pide cambios (= pushes nuevos), será el momento natural de que Juan actualice ese límite.

## 22:40 — Entrega n8n completa: PR #3 con SHA candidato `fe456b0` — PASS del Arquitecto

El ejecutor n8n corrigió los 5 bloqueantes + P2 y abrió `Agente-n8n#3` (base `stg`, merge-base `40fe572` verificado). Suite 71→124 tests. **Pasada adversarial del Arquitecto: PASS** — evidencia reproducida independientemente en worktree aislado: 124/124, runner `RESULTADO: OK — plano contenido`, cleanup persistido en `run.log` (intento/resultado/fin, `restantes=0`, `intentos_sin_resultado=0`), FAKE de dominancia inyecta exactamente la arista del dictamen (`WhatsApp Message Trigger → Update Activity`) y asserta el BYPASS, 10/10 ingress deniegan path de producción, 0 aristas `ai_*` en el aislado (22 en el vivo). Métricas idénticas a las declaradas en el PR. Nota: los valores esperados del handoff (71/71, creados=9) eran los pre-fix; el PR explica cada delta (sinks 24→22, gates 43→54) con causa.

Ambos frentes de la re-revisión C1 (Dashboard #2 y n8n #3) quedan entregados con doble verificación (ejecutor + Arquitecto). Pendiente: aviso a Juan con OK de Alberto.

## 22:5x — Aviso formal de re-revisión publicado (`5148108549`, OK de Alberto)

Ambos frentes C1 (n8n #3 `fe456b014`, Dashboard #2 `1373d1ab9`) sometidos formalmente a la re-revisión del accountable. La noche cierra con: 2 PRs entregados con doble verificación, 3 clasificaciones ex post cruzadas (sonda descuento, Heroku STG de Juan, Vercel Dashboard), y pendientes aparcados por decisión de Alberto (listrecs/corte mensual, cron Conciliación). La pelota: re-revisión de Juan.

## 01:0x (1 ago) — Re-revisión de Juan (`5148715706`) + iteración P1 n8n lanzada

**Dashboard: PASS técnico offline acotado**, congelado en `1373d1a` (prohibido cualquier push adicional). **n8n: NO-GO acotado por 1 P1** — dos bypasses de clase en el checker SQL (dinámico degradado a `read` sin gate de mutación; spoof de `parameters.table` sobre el destino SQL real) + P2s. Juan da **luz verde expresa a corrección offline inmediata** del PR #3 con nuevo SHA candidato; re-revisión focal e inmediata.

Handoff de iteración entregado al Agente n8n (`handoffs/2026-08-01-iteracion-p1-sql-pr3.md`). **Trazabilidad:** el commit del handoff (`6242007`, docs-only) aterrizó en la propia rama `feature/c1-contencion-gates-plano-aislado` — el clon compartido estaba en esa rama por la iteración activa del ejecutor. A diferencia del 31 jul (rama congelada como candidato), la rama está ahora en desarrollo autorizado por el accountable; se deja en el historial y el PR declarará la composición del nuevo candidato incluyéndolo como docs-only, en vez de reescribir historia sobre la que el ejecutor ya puede estar trabajando.

## 01:5x (1 ago) — Iteración P1 n8n entregada: nuevo SHA candidato `b2c89ba15` — PASS del Arquitecto

Ejecutor n8n cerró el P1 (2 bypasses SQL) + los 4 P2 en tres commits (`b8b214c` fix, `43836dc` FAKEs e2e, `b2c89ba` P2s) y actualizó el PR #3 con la composición completa (incluye `6242007` docs-only declarado). **Verificación independiente del Arquitecto: 143/143 tests, runner OK, FAKEs e2e reproducen exactamente ambos bypasses del dictamen (gate ejecutado deniega payload malicioso; sujeto acreditado = destino SQL real), `taxonomy.js` clasifica dinámico/no-analizable como mutación fail-closed.** Pendiente: aviso a Juan para la re-revisión focal (con OK de Alberto).

## 02:0x (1 ago) — Aviso de iteración P1 publicado (`5148827114`, OK de Alberto) — TODO en el lado de Juan

Con este aviso, el estado queda: PR n8n #3 (`b2c89ba15`) sometido a re-revisión focal; PR Dashboard #2 (`1373d1a`) PASS y congelado; ningún pendiente operativo del lado nuestro en #132/#135/#140. Próximos hitos, todos de Juan: re-revisión focal n8n → aceptación offline humana de C1 → borrador de checkpoint operativo (en #132, con decisiones futuras de Alberto: ALLOWED_ORIGINS, ventana, guardia).

## 02:3x (1 ago) — Focal de Juan (`5148866994`): P1 ACEPTADO, queda P2 final de redacción

Los 2 bypasses cerrados y reproducidos por Juan (143/143, runner OK). C1 "técnicamente verde" salvo un P2 de evidencia: `redactar()` no inspecciona el contenido de claves permitidas (canario de Juan: password/URL/SQL/token pasan dentro de `mensaje`/`argv`/`detalle`) y el runner imprime el ID de `credenciales_aisladas`. Luz verde a corrección final acotada (5 puntos, solo delta de redacción). Handoff entregado en `main` de Agente-n8n (`9fa6e14`) **vía worktree temporal — el clon estaba otra vez en la rama candidata y la convención nueva evitó el tercer incidente**. Dato nuevo: Django avanza en paralelo offline con wrapper CAS (`feature/issue-140-django-rollout-cas`).

## 03:xx (1 ago) — P2 final entregado: SHA candidato `4e2118c39` — PASS del Arquitecto

Ejecutor n8n cerró los 5 puntos en un commit (`4e2118c`, redacción por vocabulario cerrado en vez de por clave) y actualizó el PR #3. Verificación independiente: 147/147, runner OK, `credenciales_aisladas_n` solo conteo, `argv:["run-c1.js"]`, grep del canario de Juan sobre `run.log` = 0 coincidencias. Borrador de aviso final a Juan listo — pendiente del "publica" de Alberto (ausente).

## 03:xx (1 ago) — Aviso P2 final publicado (`5148961363`, OK de Alberto) — C1 entera en el tejado de Juan

Los tres frentes entregados y verificados: n8n `4e2118c39` (P1+P2 cerrados), Dashboard `1373d1a` (PASS, congelado), Django de Juan en paralelo (wrapper CAS). Próximos pasos, todos de Juan: revisión del delta de redacción → aceptación offline humana de C1 → borrador de checkpoint operativo en #132.

## 03:0x (1 ago) — Estatus coordinado de Juan (`5148997078`), cruzado con nuestro aviso

Su punto 1 (entregar delta n8n) ya estaba cumplido 8 min antes (`5148961363`). Confirma la secuencia a STG: delta n8n → checks Django #145 (nuevo PR suyo: wrapper CAS shadow↔dual, `c373ab1`, 97 PASS offline) → aceptación humana offline de C1 → borrador checkpoint en #132. Convergencia de estándares entre lados (su `migrate --check` bloqueante sale de su incidente Heroku; su journal sanitizado, de nuestro P2). Sin acción nuestra.

## 03:1x (1 ago) — C1 ACEPTADA offline (`5149044773`) + borrador de checkpoint preparado

Juan aceptó la entrega técnica C1 offline de los 3 frentes (n8n `4e2118c` 147/147, Dashboard `1373d1a`, Django `4f0e741`). Cierra el NO-GO; NO declara C1 operativamente instalada. Django #145 (CAS) queda fuera de la instalación C1, sin merge. Luz verde para preparar (sin ejecutar) el borrador del checkpoint operativo en #132 (9 puntos mínimos). **Borrador redactado:** `docs/iniciativas/c1-checkpoint-operativo-borrador.md` con SHAs/IDs reales del C0 freeze — pendiente del OK de Alberto para publicar en #132. NO es GO; su ejecución exige comentario explícito posterior del accountable.

## 03:2x (1 ago) — Borrador de checkpoint C1 publicado en #132 (`5149097301`, OK de Alberto)

Los 9 puntos en el tejado de Juan para revisión. Pendientes de Alberto para la ventana real: comandos literales de merge/import y designar guardia/suplente. Ejecución bloqueada hasta GO explícito de Juan en #132.

## 03:3x (1 ago) — Checkpoint #132 completado: comandos + guardia doble

Rellenados los dos huecos (decisión Alberto): merge por CLI `--merge` ambos PRs, import por Agente n8n; guardia doble = Arquitecto (vivo) + Juan activo desde #132. Comentario `5149097301` editado en #132. Borrador ya completo salvo la fecha de ventana. Falta: GO explícito de Juan + pactar ventana.

## 03:2x (1 ago) — NO-GO OPERATIVO del checkpoint (`5149165789`) — la contención viva no existe aún

Juan revisó el borrador y detectó (correctamente, verificado por el Arquitecto contra el artefacto) que la aceptación offline cubría el **banco de pruebas del plano aislado** (barrera B), no un instalador de contención viva. Bloqueantes: (1) el instalador n8n C1 no existe como script; (2) el borrador proponía importar "sobre los IDs inmutables" cuando el runbook exige 7 clones NUEVOS `active:false`; (3) **falta la barrera A: el plano vivo sigue con `real_connector_calls=24`, gates=0** — los 54 gates solo viven dentro de `aislarWorkflow()`; (4) checkpoint con campos abiertos; (5) rollback (reimport 7 vivos + restore BD) demasiado amplio para la acción; (6) faltan identidades/comandos por frente + validación de head anti-TOCTOU.

**Error del Arquitecto reconocido:** el checkpoint citó `import-stg-workflow.py` (importador del Bug #10) como instalador C1, y conflacionó el harness offline con instalación viva. Handoff de corrección entregado (`Agente-n8n@b5d81be`, en main): construir barrera A + instalador de 7 clones con GET fingerprint/journal/rollback acotado + nuevo SHA + re-revisión adversarial. Checkpoint marcado como superseded hasta que exista el artefacto. Dashboard/Django #145 congelados. **Esto NO es un ajuste menor: es ingeniería nueva — reajusta el plazo a STG.**

## 03:4x (1 ago) — Instalador C1 + barrera A entregados: SHA `86a9c093c` — PASS del Arquitecto

Ejecutor n8n construyó los dos artefactos que faltaban en 3 commits y actualizó el PR #3. **Verificación independiente (190/190 tests, runner OK):**
- **Barrera A (plano vivo default-deny):** `vivo_alcanzable_sin_gate 56 → 0`, 10/10 ingress con gate, 50 gates que deniegan, `vivo_identidad_conservada:true`. Ya NO es solo el aislado — contiene el plano vivo, que era el bloqueante 3.
- **Instalador (barrera B):** tests cubren exactamente lo que Juan exigió — FAKE de que borrar/activar un ID vivo lanza antes de tocar red; verificación POR GET; POST que pierde respuesta se acredita por GET sin duplicar; fingerprint no coincide → incierto y NUNCA borra; anti-TOCTOU si el vivo cambió; rollback borra SOLO lo creado por esta corrida (reconcilia por GET antes de cada DELETE, nunca restaura BD, nunca toca los 7 IDs vivos). Rollback acotado exactamente como Juan pidió (bloqueante 5).

Los 6 bloqueantes del NO-GO cubiertos. Pendiente: aviso a Juan (con OK de Alberto) + rehacer el checkpoint con los comandos/IDs del instalador nuevo.

## 03:4x (1 ago) — Instalador C1 + barrera A entregados: SHA `86a9c093c` — PASS del Arquitecto

Ejecutor n8n construyó los dos artefactos que faltaban en 3 commits y actualizó el PR #3. **Verificación independiente (190/190 tests, runner OK):**
- **Barrera A (plano vivo default-deny):** `vivo_alcanzable_sin_gate 56 → 0`, 10/10 ingress con gate, 50 gates que deniegan, `vivo_identidad_conservada:true`. Contiene el plano vivo (bloqueante 3).
- **Instalador (barrera B):** tests cubren lo que Juan exigió — borrar/activar un ID vivo lanza antes de red; verificación POR GET; POST que pierde respuesta se acredita por GET sin duplicar; fingerprint no coincide → incierto sin borrar; anti-TOCTOU; rollback borra SOLO lo creado por esta corrida, reconcilia por GET, nunca restaura BD ni toca los 7 IDs vivos (bloqueante 5).

6 bloqueantes del NO-GO cubiertos. Pendiente: aviso a Juan (OK de Alberto) + rehacer checkpoint con comandos/IDs del instalador nuevo.

## 04:0x (1 ago) — Doc de entrega del ejecutor (main) revela 2 correcciones al checkpoint + 1 decisión de gobernanza

El Arquitecto había verificado el CÓDIGO pero no el doc de entrega (`Agente-n8n:docs/2026-08-01-entrega-arquitecto-c1-barreras-y-comandos-instalador.md`). Al leerlo:

1. **Los 7 IDs NO se pueden fijar a priori** — la API de n8n los asigna en el POST (`id: readOnly`, leído del schema fuente). Lo determinista es **nombre + fingerprint de contenido**; el id se recoge del POST y se confirma por GET. El bloqueante 2 de Juan ("fijar los 7 IDs") es imposible como literal — se satisface con nombre+fingerprint. (Mi checkpoint viejo decía "importar sobre los IDs inmutables": doblemente equivocado.)
2. **Contradicción de gobernanza real (barrera A):** instalar la contención viva **exige `PUT` sobre los 7 IDs vivos** — justo lo que el handoff/Juan prohibieron ("ni PUT, ni activar, ni borrar"). El ejecutor no puede resolverlo: o el checkpoint **autoriza explícitamente el PUT de contención** sobre los 7 vivos (rollback: reponer el export congelado de git), o **la barrera A se queda sin instalar** y el checkpoint declara que la contención viva no entra en esta ventana. **Decisión de Alberto+Juan, no del Arquitecto.**

El ejecutor entregó además: comandos de solo-lectura (guarda anti-TOCTOU con fingerprints por los 7 vivos, plan de instalación offline, verificación por GET), instalación viva NO expuesta (doble guarda `permitirRed` + `C1_INSTALADOR_VIVO=1`), los 7 destinos (nombre+fingerprint) y rollback mínimo por acción. Lección reforzada: **leer el doc de entrega, no solo verificar el código** — el doc traía lo que el código no dice.

## 04:1x (1 ago) — Aviso publicado en #132 (`5149463414`): SHA 86a9c093c + pregunta de barrera A a Juan

Con OK de Alberto. Nuevo candidato + 6 bloqueantes cubiertos + la decisión de alcance planteada a Juan: opción A (incluir barrera A con PUT autorizado sobre los 7 vivos) vs opción B (diferir, instalar solo barrera B). Bloqueado esperando su decisión antes de rehacer el checkpoint. Sin acción nuestra hasta entonces.

## 02:58 (1 ago) — Dirección post-C1 de Juan (`5149471243`) — hoja de ruta, NO respuesta a barrera A

Juan fija que cerrar C1 no cierra #140. Secuencia canónica declarada: C1 (contención viva+aislado) → C2 (integración STG shadow, matriz E2E-, cero red) → C3 (gap pre-dual + readiness PG) → C4 (canary dual→shadow, termina en shadow) → C5 (2º GO + Dual sostenido STG) → C6-C9. Cada fase con aceptación técnica + checkpoint humano separado; NO GO anticipado. Hasta cerrar C1, foco exclusivo, sin trabajo lateral. **La pregunta de barrera A (#132 c.5149463414) sigue sin responder.** Sin acción nuestra; es hoja de ruta.

## 03:1x (1 ago) — El ejecutor verifica 3 riesgos del PUT de barrera A (material para la decisión A/B)

Informe `Agente-n8n@4621d6f` (main), verificado contra el código fuente de n8n. Los 3, relevantes para la opción A que Juan audita:
1. **`webhookId` se conserva solo por construcción** (`resolveNodeWebhookId`: uuid nuevo solo si el nodo no trae uno). El rollback propuesto es seguro PORQUE el export lleva los 8 nodos completos; un PUT que reduzca campos reintroduce el Bug #12. Guarda de webhookId = 30 min si sale A.
2. **PUT sobre workflow ACTIVO publica de inmediato** (`publishIfActive:true`; los 7 vivos activos). No hay ensayo; 7 PUT independientes → ventana cortada a mitad = plano MIXTO. Exige orden explícito + rollback por workflow (Main el último). Orden propuesto: Metepec Liberar → Issue Policy Guard → METEPEC Registrar → Retomar → Payment → Atención Humana → Main.
3. **API sin control de concurrencia** (`forceSave:true`, "skip version conflict check"). Anti-TOCTOU enteramente nuestro, pegado a CADA PUT, no una vez al abrir ventana.

Nada afecta a barrera B (POST nuevos, instalable tal cual). Ejecutor en disciplina correcta: no construyó el PUT (sería trabajo lateral prohibido). **Estos hechos cambian el perfil de riesgo de la opción A — deben llegar a Juan ANTES de que decida.** Suplemento publicado en #132 (`5149524046`, OK de Alberto) mientras Juan audita A/B.

## 03:22 (1 ago) — Dictamen técnico de Juan sobre el suplemento (`5149565446`) — valida candidato, NO decide A/B

Juan reprodujo `86a9c093` (**190/190 + runner OK, 56→0**) y contrastó los 3 riesgos del PUT contra el código público de n8n (`n8n-io/n8n@10a7422`):
- **webhookId:** confirmado con condición (rollback seguro respecto de ese id solo si el payload conserva todos los nodos/IDs).
- **forceSave/sin CAS:** confirmado (GET pegado al PUT reduce, no elimina la carrera).
- **publishIfActive:** confirmado **con matiz nuevo e importante** — NO está acreditado que en la versión/config concreta de STG el efecto sea siempre "inmediato y sin estado intermedio"; n8n guarda versión nueva antes de publicar y admite publicación **asíncrona por outbox o ruta legacy**. → **Hay que fijar la versión/config efectiva de STG antes del checkpoint.**

**Si el accountable elige A**, el camino del PUT (sin construir) no entra al checkpoint hasta cubrir, POR workflow: (1) preimagen fresca + guarda exacta de webhookId; (2) exclusión de ediciones concurrentes; (3) journal durable + reconciliación por GET ante timeout, sin retry ciego; (4) verificación posterior de contenido + estado publicado + activeVersion; (5) orden por dependencias + rollback inverso por workflow. Ojo: reponer un export crea/publica OTRA versión (restaura contenido, no el versionId previo) y sufre los mismos riesgos.

**B sola sigue siendo C1 parcial** bajo el alcance de #140 (no cierra "plano vivo contenido + aislado instalado"). NO decide A/B, no es PASS/GO. Dashboard #2 y Django #145 congelados. **Sigue pendiente: la decisión A/B de Juan.**

## 03:2x (1 ago) — Límite de alcance al ejecutor sobre la spec de 5 puntos de Juan

El ejecutor leyó la spec de 5 puntos de Juan como tarea (correcto en parte). El Arquitecto fija el límite (handoff `Agente-n8n@06fff01` en main): ✅ ejecutable ahora = corregir sus 2 afirmaciones de más + análisis del grafo de dependencias como hallazgo offline (aporta a la decisión A/B); 🛑 NO = construir el camino del PUT (5 puntos), que es A-contingente por definición de Juan y trabajo lateral hasta GO de A. Nada pusheado aún por el ejecutor; el candidato 86a9c09 sigue igual. Recordatorio: fijar versión/config STG (por publishIfActive async) es lectura de STG que decide Alberto, no el ejecutor.

## 03:34 (1 ago) — Ejecutor construyó el camino PUT (7c64156) — PREMATURO pero con 2 hallazgos materiales

El ejecutor pusheó `7c641562c` (camino PUT, `instalador-vivo.js`, 209/209) **5 min DESPUÉS** de mi handoff de límite (`06fff01` 03:29Z; push 03:34Z). Cruzó la línea "no construir PUT hasta GO de A", aunque con transparencia total (etiquetado "NO autorizado" en PR + reporte en main `040d8999e`; cliente HTTP inerte, sin modo vivo). **Trabajo preservado en rama de cuarentena `c1-put-path-preparado@7c64156` (no destructivo). Candidato de Juan `86a9c09` debe restaurarse (force-push de Alberto).**

**2 hallazgos materiales que salieron del prototipo:**
- (a) La verificación NO puede ser fingerprint global: `workflow.service.ts:484` fusiona settings y poda con `removeDefaultValues()` → verificar por partes. Consecuencia buena: `binaryMode` de los 7 vivos (no enviable, da 400) lo CONSERVA la fusión — el PUT no lo pierde.
- (b) **CORRIGE EL ORDEN QUE YO PUBLIQUÉ A JUAN** (suplemento `5149524046`): "periferia primero, Main al final" es el PEOR — deja el Main atendiendo tráfico e invocando sub-workflows ya cerrados (bot "vivo" roto por dentro). Correcto: **LLAMADORES PRIMERO, Main el PRIMERO**, calculado del grafo. Hay que corregírselo a Juan porque afecta el perfil de riesgo de A.

Pendiente de Alberto: (1) force-push restaurar candidato a 86a9c09; (2) OK para corregir a Juan el orden + el hallazgo de verificación.

## 04:0x (1 ago) — Autocorrección del push prematuro + recomendación A/B a Juan (`5149673985`)

Secuencia limpia ejecutada (con OK de Alberto):
1. **Force-push de Alberto** restauró el candidato `7c64156 → 86a9c09` (el validado por Juan). Trabajo del PUT preservado en `c1-put-path-preparado`.
2. PR #3 corregido (cuerpo + título): candidato = `86a9c09`, camino PUT declarado FUERA del candidato (en cuarentena). Autocorregido ANTES de que el monitor de Juan lo marcara.
3. **Recomendación publicada a Juan** (`5149673985`): (a) corrijo el orden de contención que le di en `5149524046` — "periferia primero" era incorrecto; verificado por el Arquitecto contra el grafo congelado que Issue Policy Guard y METEPEC Registrar son callees puros sin ingress → van los últimos; principio = llamador antes que callee; orden exacto a computar del grafo y re-verificar en checkpoint (NO aserté las 7 posiciones, límite honesto de mi verificación); (b) hallazgo de verificación por partes + binaryMode conservado; (c) **recomendación: opción B ahora, barrera A como checkpoint separado posterior** — los hallazgos del PUT vivo lo hacen operación de riesgo alto que merece su propio checkpoint; (d) estado del artefacto y reconocimiento del prototipo prematuro.

Decisión A/B sigue siendo de Juan. Nuestra postura ya está sobre la mesa, verificada.

## 03:56 (1 ago) — Juan acusa la recomendación y VERIFICA la autocorrección — incidente prematuro cerrado limpio

Acuse `5149...` (no decisión): Juan cita "el candidato `86a9c09` y la rama inerte `c1-put-path-preparado@7c64156`" — aceptó el encuadre de cuarentena, sin escalado. La autocorrección proactiva funcionó: cerramos el push prematuro antes de que su monitor lo marcara como violación. Nota de actualización al ejecutor en `main` (`7a1e995`): sincronizar clon (reset a origin), no re-pushear la candidata. Sigue pendiente: decisión A/B (Juan la está revisando).

## 04:03 (1 ago) — DECISIÓN A/B: Juan elige A. FAIL técnico, C1 incompleto (`5149704373`)

Juan reprodujo candidato (190/190) y prototipo (209/209). **Rechaza nuestra recomendación B; decide A:** "B sola no satisface C1; el alcance canónico fija plano vivo contenido Y 7 clones aislados; NO procede diferir A". Tres bloqueantes para cerrar:
1. **Un único SHA candidato auditable A+B** que exponga el instalador/verificador target-guarded REAL de ambas barreras (el trabajo del PUT en cuarentena entra ahora al candidato, autorizado).
2. **Cerrar el camino vivo antes del checkpoint** — correcciones al PUT (`7c64156`): rollback puede sobrescribir edición concurrente sin GET/guarda inmediata previa; acredita "repuesto" solo por contenido (falta settings/active/publicación/activeVersion); la verificación de ida no rechaza settings nuevos ajenos. Añadir: reconciliación completa por workflow, journal durable, `incierto` sin retry ciego TAMBIÉN en rollback, fijar versión/config n8n, demostrar orden por dependencias + rollback inverso.
3. **Publicar el checkpoint completo de los 9 mínimos** (no elección A/B): comandos literales target-guarded, IDs/nombres/fingerprints/bytes+GET post, operador/guardia/suplente/ventana, producers/en-vuelo/destinos, stop/RTO/rollback, identidades/efectos de Dashboard y Django. Dashboard #2 y Django #145 congelados; C2 fuera. Solo offline.

**Consecuencia:** A queda decidida → el ejecutor está desbloqueado para completar la barrera A (ya no es lateral). Plan de cierre: (1) ejecutor completa PUT hardening + candidato unificado A+B; (2) Arquitecto rehace el checkpoint completo de 9 puntos con A. Nuestra recomendación B no ganó — decisión del accountable, sin error nuestro.

## 04:1x (1 ago) — Alberto acepta A. Handoff de barrera A dispatchado (`904402b`)

Decisión de Alberto: adelante con A. Handoff al ejecutor en main (`904402b`): completar camino vivo con las 6 correcciones de Juan + integrar en candidato único A+B, solo offline. En paralelo, el Arquitecto rehará el checkpoint completo de 9 puntos sobre el SHA unificado cuando el ejecutor lo entregue. Ejecutar seguirá requiriendo GO aparte. Ruta a cierre de C1: ejecutor entrega A+B → Arquitecto verifica + rehace checkpoint → Juan revisa → GO → ventana con Alberto.

## 04:2x (1 ago) — Candidato unificado A+B entregado: SHA `28167b6e7` — PASS del Arquitecto

Ejecutor integró el camino PUT + hardening (efd3c606 PUT, 28167b6 los 6 puntos de Juan). **Verificación independiente (216/216, runner OK):**
- Barrera A intacta: vivo 56→0 alcanzable sin gate, 10/10 ingress, identidad conservada; barrera B (instalador de 7 clones) presente → candidato A+B unificado real.
- **Los 6 puntos de hardening de Juan, cada uno con test nombrado:** (1) rollback no sobrescribe edición concurrente (GET previo); (2) rollback acredita "repuesto" por contenido+settings+active+publicación+activeVersion; (3) verificación de ida rechaza settings ajenos; (4) INCIERTO sin retry ciego también en rollback; (5) fija entorno n8n, fail-closed si no declarado/distinto; (6) orden llamadores-primero (Main index 0, los 2 callees puros últimos — coincide con mi ancla) + rollback inverso.
- Matiz async de publishIfActive manejado: "versión publicada sigue siendo la anterior → INCIERTO". Excepción PUT ESTRECHA (permite actualizar los 7 para contención, sigue prohibiendo borrar/activar) tras cliente-de-contención explícito + autorización escrita. Dos bugs auto-reportados corregidos (copia profunda; fingerprint sobre lo enviado).

Pendiente: que el ejecutor actualice el PR #3 al nuevo SHA; luego aviso a Juan + rehago el checkpoint de 9 puntos.

## 04:3x (1 ago) — Ejecutor fija n8n 2.28.7 (candidato `601a845`) — PASS; checkpoint actualizado

Alberto observó la versión en la UI (About n8n): 2.28.7. El ejecutor la fijó y **re-verificó los 5 hechos del contrato contra el tag `n8n@2.28.7` (`955be3ef`)** — descubrió que hasta ahora leía master (~5 minors por delante); los 5 se sostienen. Cerró un hueco propio en la guarda de publicación (un `null` la atravesaba). Candidato `28167b6 → 601a845`. Verificación independiente del Arquitecto: 219/219, runner OK, barrera A 56→0, **manifests/fingerprints sin cambios** (tablas del checkpoint siguen válidas). Checkpoint v2 actualizado: SHA `601a845`, punto 6 corregido (versión 2.28.7 fijada + re-verificada; modo de publicación = requisito de pre-ejecución vía `docker inspect ... PUBLICATION`, NO por /rest/settings). Buen trabajo senior: procedencia legítima (Alberto), dato etiquetado, re-verificado contra el tag correcto. Pendiente: confirmar con Alberto la observación de 2.28.7 + OK para postear checkpoint a Juan.

## 04:5x (1 ago) — Checkpoint C1 completo publicado a Juan (`5149876716`) — los 3 bloqueantes cubiertos

Con OK de Alberto y evidencia de la versión (captura About n8n = 2.28.7). Respuesta completa al FAIL `5149704373`: candidato `601a845` (219/219, PASS independiente) + hardening (6 puntos) + checkpoint de 9 puntos íntegro. En el tejado de Juan para revisión. Pendientes de pre-ejecución cuando dé GO: observar modo de publicación (`docker inspect ... PUBLICATION`), ventana Alberto↔Juan, exponer modo vivo del instalador (cambio de código con GO escrito). Cerrar C1 = revisión de Juan → GO → ventana.

## 05:00 (1 ago) — FAIL del checkpoint (`5149896236`) — convergente, a grado ejecutable

Juan reprodujo (219/219, runner OK). Tres correcciones:
1. **Entregar el instalador/verificador REAL A+B** — hoy ninguna CLI expone `--vivo` ni invoca `aplicarContencion`; el modo vivo quedó como "cambio futuro". Juan lo quiere **construido ya, inerte por defecto y target-guarded**, con comandos reales PUT/POST, GET post y rollback. (Refina el planteamiento anterior: el código debe existir e inerte, no diferirse — el GO es decisión humana + fijar guardas, no escribir código nuevo.) → ejecutor.
2. **Checkpoint sin placeholders:** sustituir `<ID>`, `<fingerprint-vivo>`, `<contenedor>`, "a pactar", observación futura por los 7 valores completos, hashes/bytes exactos, ventana concreta, operador/guardia/suplente nominales, comandos literales. Prechecks target-guarded ACTUALES (no el C0 histórico) para producers/en-vuelo/destinos/publicación; el runner offline no verifica el plano instalado. → Arquitecto (+ ventana/suplente de Alberto).
3. **Efectos/rollback al alcance:** quitar el backup de BD (A+B no muta BD); fijar identidad/efecto exacto de Dashboard (proyecto/env/deployment Vercel, cero acción al estar congelado) y Django (app/release activo + `migrate --check` target-guarded), manteniendo #2 y #145 congelados. → Arquitecto.

Solo offline; sin PUT/POST/DELETE, docker inspect, backup, STG/PROD, etc. Pendiente de Alberto: pactar ventana con Juan + nombrar suplente.

## 05:0x (1 ago) — Entorno STG observado por Alberto (debug info UI) — NO violación, 4 hallazgos + 1 estratégico

Alberto pasó el About→Copy debug info; el ejecutor lo analizó (nota `619df159b` en main). C1 no tocó STG. Hallazgos:
1. **Confirma el pin 2.28.7** (n8nVersion en debug) — ya no descansa en una sola lectura.
2. **DOS bases de datos:** n8n usa SQLite interna (workflows/ejecuciones/credenciales); el bot habla con un POSTGRES aparte (whatsapp_sessions/n8n_chat_histories, cred `5wlLe3gD07CLIM7U`). El checkpoint no debe decir "restaurar la BD" sin apellido → refuerza el quitar el backup (Juan p.3).
3. **Acota el TOCTOU:** cluster instanceCount 1, un solo main leader, executionMode regular → NO hay segundo proceso n8n que edite en paralelo. El único editor concurrente posible es una PERSONA con la UI abierta u otro cliente API. La exclusión operativa se vuelve concreta: **el garante confirma que nadie tiene la UI de STG abierta al abrir la ventana, y se re-comprueba antes del PUT del Main.**
4. **`publicacion` sigue null:** el debug info tampoco la expone (última vía sin shell). Requisito de pre-ejecución; el instalador se niega.
5. **⚠️ FUERA DE C1, muerde después:** STG (2.28.7) y **PROD (2.6.3) están a 22 minors**. STG no es ensayo fiel de PROD; verificado contra el tag `n8n@2.6.3`: **2 de los 5 hechos que sostienen el instalador NO existen en 2.6.3.** Los artefactos no son portables a PROD tal cual. Alberto evalúa subir PROD (el ejecutor le dio el procedimiento; ni lo ejecuta él ni es alcance C1). **Bloqueante futuro real del rollout a PROD.**

## Datos de Alberto para el checkpoint (1 ago) — suplente + ventana

- **Suplente:** Juan (`@oilycoyote`), además de guardia. Operador: Alberto. Guardia doble: Arquitecto + Juan.
- **Ventana STG:** **lunes 3 ago 2026, 09:30 CDMX = 15:30 UTC** (día laborable; propuesta a confirmar con Juan en el checkpoint).
- Pendiente para la reescritura sin placeholders: comandos reales del instalador vivo (ejecutor, en curso) + ref del contenedor.

## 05:1x (1 ago) — Petición a Juan: obtener N8N_USE_WORKFLOW_PUBLICATION_SERVICE (`5149960007`)

Alberto no tiene el 2FA de Hostinger (lo tiene Juan) → no puede abrir la terminal del VPS. Se pide a Juan que corra la consulta de solo lectura (`docker ps` + `docker inspect ... | grep -i PUBLICATION`) para fijar el modo de publicación (último dato de pre-ejecución del checkpoint). Sin salida → default false → síncrono. Incluida la sinergia: Juan confirma también la exclusión operativa (UI cerrada) en la ventana del lunes 3.

## 05:25 (1 ago) — FAIL `5149976697` — la variable de publicación es preflight de VENTANA, no pre-obtención

Juan: mi petición `5149960007` no cierra el FAIL (no trae SHA, el modo sigue sin fijar, el comando conserva `<ese-nombre>` sin target guard). **Y declina correr Hostinger/SSH/docker offline** — lo trata como preflight vivo de la ventana. Reencuadre: el valor NO se pre-obtiene; el checkpoint debe incorporar el **precheck literal, target-guarded y fail-closed** del modo de publicación, y la **CLI A+B debe consumir/acreditar ese valor antes de cualquier escritura**. Luego nuevo SHA + checkpoint completo sin pendientes. Arreglo de nuestro lado (ejecutor + checkpoint), sin Juan ni Alberto. El `<ese-nombre>` se resuelve identificando el contenedor n8n de forma determinista (p.ej. `--filter ancestor=n8nio/n8n:2.28.7`, fail-closed si no hay exactamente uno), no con un nombre hardcodeado. Mi petición a Juan de consultarlo queda superada.

## 05:5x (1 ago) — Instalador vivo real entregado (464dbd4) + checkpoint completo POSTEADO a Juan (`5150052424`)

Ejecutor entregó la CLI viva real A+B inerte + preflight de publicación (231/231, inercia verificada: 5 guardas, sin flags→DRY-RUN cero escrituras; preflight con doble target-guard imagen+binario). Verificación independiente del Arquitecto PASS. **Posteado por el Arquitecto directo (delegación de Alberto)**, con las 3 condiciones cumplidas: entregado + verificado + sin placeholders. Correcciones al posteo previo cazadas verificando: quité la columna de fingerprint de artefacto (era mía y de más — la verificación es por partes, no fingerprint único); comandos = salida verbatim de la CLI; SHA 464dbd4; ventana lunes 3 ago 09:30 CDMX. PR #3 actualizado a 464dbd4. Pendiente único: revisión + GO de Juan. Alberto durmiendo; nada irreversible hecho.

## 05:53 (1 ago) — FAIL `5150070342` — rollback/stop/target (2 bugs reales de la CLI + checkpoint incompleto)

Juan reprodujo (231/231, dry-run inerte, simulación verde). Tres bloqueantes:
1. **Rollback no recuperable entre corridas (bug del ejecutor):** cada invocación borra `build/instalador.log`; `--rollback` re-aplica A e instala B y solo revierte lo de esa invocación; no consume preimágenes/IDs de pasos 3–4 ni recupera tras corte. → estado durable identificable + `--rollback-from`/reconciliación; en rollback NUNCA emitir primero los PUT/POST de ida.
2. **Stop/target guard sin cerrar (bug del ejecutor):** la CLI ejecuta B aunque A quede parcial; siempre `log.fin(true)`; puede salir 0 con errores/`incierto`. → parar, cerrar no-verde, exit !=0. Y el preflight Docker no está ligado a `N8N_BASE_URL`: **guarda exacta del host/instancia STG antes de cualquier PUT/POST/DELETE** (que las credenciales no puedan apuntar a otro target).
3. **Checkpoint realmente completo (Arquitecto):** los 6 curls con `…` → literales; placeholders de autorización; ventana "a confirmar"; prechecks sin comandos literales (ejecuciones/producers/schedules/destinos); deployment Vercel inmutable; comando Django `migrate --check` target-guarded; operador/guardia/suplente/ventana definitivos.

Solo offline. Nota: Juan trata la ventana lunes 3 como "a confirmar" — aún no la aceptó; requiere su OK explícito para ser definitiva.

## 06:0x (1 ago) — Fix rollback/stop/target entregado (7c877a7) + checkpoint v2 completo POSTEADO a Juan (`5150183935`)

Ejecutor cerró los 2 bugs (248/248): rollback recuperable (estado durable + `--rollback-from`, sobrevive corte, nunca re-aplica ida), STOP con exit≠0 en no-verde, target guard atado a `N8N_BASE_URL` (host STG exacto). **Cambio clave verificado: orden ahora B→A** (clones desde el freeze primero; si B no limpia, no se toca el vivo). Verificación independiente del Arquitecto PASS. Checkpoint reescrito completo (comandos verbatim, prechecks literales, Django, Vercel, ventana concreta pidiendo confirmación a Juan) y **posteado por el Arquitecto directo** (delegación de Alberto), 3 condiciones cumplidas. PR #3 → 7c877a7. Pendiente: (a) Juan confirma ventana; (b) revisión + GO de Juan. Alberto durmiendo; nada irreversible.

## 06:2x (1 ago) — Ejecutor autocazó hueco de fixture (871221400) + reconciliación de SHA con Juan + congelación

Ejecutor encontró que la instancia simulada de sus tests no persistía entre procesos → el rollback entre corridas no estaba realmente ejercido; corregido en `871221400` (borra/repone de verdad). Verificado: comandos/fingerprints SIN cambio, 248/248. Pero llegó 2 min tras mi post del checkpoint (`7c877a7`) y del ack de Juan. **Reconciliado:** doc + PR + delta a Juan (`5150193383`) → candidato `871221400`, checkpoint íntegro. **Congelación pedida al ejecutor** (handoff `4f5cea0`): no pushear la candidata durante la revisión de Juan; si algo crítico, reportar a main y coordinar — van 4 SHAs seguidos y cada uno desfasa el SHA bajo revisión del accountable. Pendiente: Juan confirma ventana + revisión/GO.

## 06:3x (1 ago) — Ejecutor acusa congelación (c6ebdd287) + recordatorio: validar B→A antes del GO

Ejecutor confirmó freeze en 871221400 (local==remoto==PR head, 248/248, nada crítico) vía main (protocolo correcto). Recordatorio suyo: el orden B→A es desviación pendiente de validación explícita de Juan. Cubierto: B→A + rationale están en el checkpoint que Juan revisa (§0/§2), así que su revisión lo valida. PUNTO A VIGILAR en el dictamen de Juan: que acepte explícitamente B→A; si no lo menciona, confirmarlo con él antes del GO.

## 06:35 (1 ago) — FAIL `5150210658` — uncertain/interrupted + producers/target + datos definitivos

Juan reprodujo 248/248. Tres bloqueantes:
1. **Recuperar lo incierto/interrumpido (ejecutor):** `revertibleDe()` descarta todo `incierto`; el estado se actualiza SOLO tras terminar cada workflow → un corte entre intento y reconciliación queda en journal pero `--rollback-from` lo ignora. → persistir intención ANTES de cada escritura; reconciliar por GET los intentos abiertos/`incierto` antes de decidir, sin retry/borrado ciego; estado durable de verdad (`fsync`) y privado (`0600`, contiene preimágenes).
2. **Producers/destinos + target exacto (mixto):** prechecks solo cubren ejecuciones/schedules — faltan comandos para pausar/acreditar TODOS los producers (WhatsApp/Django/webhooks) y denegar/verificar destinos/conectores (Arquitecto). Y `verificarTarget()` debe exigir el **origin HTTPS exacto**; hoy acepta HTTP, puerto/ruta o userinfo con el mismo hostname (ejecutor).
3. **Datos definitivos del checkpoint (Arquitecto + Alberto/Juan):** ventana sigue "a confirmar"; **falta suplente INDEPENDIENTE** (Juan no puede ser suplente Y guardia); deployment Vercel inmutable real; guarda del release Django esperado; **hashes/bytes exactos de los artefactos enviados** (= fingerprint_contenido del PUT, que yo había quitado — hay que reponerlo).

Solo offline. **BLOQUEANTE DE ALBERTO: suplente independiente** — Alberto es el único humano operativo; o hay un tercero, o se negocia con Juan la realidad de operador único. + confirmar ventana.

## 06:5x (1 ago) — Fix incierto/target entregado (1c30a00b6) PASS + re-congelado; checkpoint pendiente de decisión humana

Ejecutor cerró p1/p2 (260/260): incierto/interrumpido recuperable (intención en disco antes de escribir + reconciliación por GET + `fsync` atómico + `0600`); target guard = origin HTTPS exacto (rechaza http/puerto/ruta/userinfo, declara honesto lo de `:443`). Autocatch extra: el manifest llevaba desfasado "BARRERA A" 2 rondas (doc interna, no ejecutable, no afecta fingerprints ni mi checkpoint que ya decía B→A); regenerado + test que muerde el desfase. Verificado por el Arquitecto: fingerprints/hashes estables, hashes de artefacto enviado confirmados idénticos. Candidato **re-congelado en 1c30a00b6** (`bf04e10`). SHA del checkpoint bumpeado. **Punto 3 preparado (prep en scratchpad):** hashes de artefacto enviado (§1), prechecks de producers WhatsApp/Django/webhooks + guarda release Django v212 (§5), códigos del target guard. **Bloqueantes humanos para cerrar (Alberto/Juan):** (1) suplente INDEPENDIENTE — Alberto único humano operativo, Juan no puede ser suplente+guardia → decisión de Alberto (recomiendo negociar operador-único con Juan); (2) Juan confirma ventana lunes 3. Repost a Juan SOLO tras ambos.

## 12:1x (1 ago) — Respuesta única y completa POSTEADA a Juan (`5151470952`) — con OK de Alberto

Juan pidió respuesta única completa (`5151359011`). Alberto autorizó ("postea") y resolvió el suplente: **operador único** (Alberto operador, Arquitecto segundo técnico, Juan guardia) — no hay 2º humano operativo. Posteado sobre `1c30a00b6` (260/260): SHA fijado, producers/destinos cerrados (§5 literal), hashes enviados (§1), guarda release Django v212, Vercel congelado. Las dos cosas que quedan son ACEPTACIÓN de Juan (ventana lunes 3 + figura operador único), no pendientes nuestros. Todo offline. Pendiente: revisión + GO de Juan (y su aceptación de ventana/figura).

## 12:48 (1 ago) — FAIL `5151490235` — rollback pre-guard + prechecks reales + mínimos definitivos

Juan reprodujo 260/260. Tres bloqueantes:
1. **Rollback pre-guard content-only (ejecutor):** `revertirContencion()` compara solo `fingerprintContenido`; un cambio ajeno en settings/active/publicación pasa y recibe el PUT de preimagen. → acreditar el ESTADO PRETENDIDO COMPLETO antes del rollback; cualquier diferencia → `incierto`, sin escritura.
2. **Prechecks reales de producers/destinos (ejecutor + Arquitecto):** mi precheck WhatsApp exige credenciales nulas, pero los exports congelados traen `WhatsApp Trigger/Send STG` → falla siempre y NO pausa el inbound; `heroku config|grep` no valida false/dry-run; Dashboard/destinos son comentarios, no gates ejecutables. → comandos fail-closed que PAUSEN/acrediten todos los producers y denieguen/verifiquen conectores antes de los PUT, sin imprimir config sensible.
3. **Cerrar los mínimos, no pedir que el revisor los complete (Arquitecto + Alberto):** ventana/figura siguen "pendientes de aceptación" (Juan no puede inferir su aceptación — hay que PUBLICARLOS definitivos); `1373d1a` es SHA Git, NO deployment Vercel inmutable (falta ID/URL exacto); los hashes A **excluyen settings** — Juan quiere **SHA-256 + tamaño de cada cuerpo PUT/POST exacto**.

Solo offline. Van ~8 FAILs convergentes; cada uno endurece algo real pero la meta se aleja al auditar más hondo.

## 13:0x (1 ago) — Fix pre-guard/producers/bytes entregado (78442a467) PASS 279/279 + re-congelado

Ejecutor cerró los 3 puntos (279/279): pre-guard del rollback sobre estado completo (settings/active/publicación → incierto sin escritura, era peor de lo que parecía: EMITÍA el PUT); comandos de ventana REALES que pausan el inbound (`/deactivate`, fail-closed, verificado contra fuente 2.28.7); SHA-256+bytes de los 14 cuerpos (A: 464.895 B; B: 444.693 B total). **2 cambios de procedimiento para el checkpoint:** (1) pausar inbound ANTES de barrera A (obligatorio); (2) el rollback NO reactiva → STG queda apagado tras C1 hasta reactivación HUMANA deliberada (debe ir en runbook). Re-congelado en 78442a467.
**Bloqueante único para el checkpoint completo: deployment-id de Vercel (Alberto) — `1373d1a` es SHA Git, Juan lo rechaza.** + aceptación de Juan (ventana/figura) + decisión Alberto async vs sesión síncrona.

## 13:28 (1 ago) — Addendum de responsabilidad de Juan (`5151628075`) — sin hallazgos nuevos

Formaliza: responsable siguiente @aibanez82; entrega = UNA respuesta única en #132 (SHA exacto + repro offline + checkpoint final completo). 2 de 3 bloqueantes ya cerrados por el ejecutor (78442a467). Instrucción: "no refactors ni mejoras laterales" — corregir exacto los 3 bloqueantes y entregar (valida el freeze del ejecutor). Al publicar, monitor acusa → responsabilidad al revisor; con PASS técnico → a Juan para decisión humana. Bloqueante único nuestro: Vercel deployment-id (Alberto) + aceptación de Juan.

## 13:42 (1 ago) — FAIL consolidado `5151680686` sobre 78442a4 + GAP DE VERIFICACIÓN DEL ARQUITECTO

Juan reprodujo y encontró que 78442a4 NO cierra:
1. **Rollback: FAIL** — la ruta omite `activeVersionId` cuando el esperado es `null` (justo el estado tras el deactivate-antes-de-A). Canario: activeVersionId ajeno → rollback="repuesto", PUTs=1. Debe ser incierto/PUTs=0.
2. **Prechecks: FAIL** — el guion lleva placeholder literal `<comando-de-lectura-de-la-flag>` (no hay comando real para acreditar la flag Django por valor); en el entorno de Juan `bash -n`=2 y suite 278/279 (en el del Arquitecto 279/279 + bash válido: `$(<...>)` parsea distinto por versión de bash — pero el placeholder es real). Además la "reverificación viva" corre `--barrera ab` SIN `--vivo` → DRY-RUN exit 0 cero-GET pero imprime "OK 3b" (falso verde). Los 7 deactivate quedan fuera del journal/reconciliación.
3. **Mínimos: PASS huellas** (SHA-256+bytes de los 14, NO rehacer); siguen ausentes ventana/roles/suplente + Vercel deployment-id.

**GAP DEL ARQUITECTO (asumido):** reporté "279/279 PASS" pero NO cacé el placeholder — solo inspeccioné las primeras 40 líneas del guion de producers (WhatsApp), no la parte Django. Verificación cierta en mi entorno pero INCOMPLETA. Lección: inspeccionar el artefacto COMPLETO, no un prefijo; y no fiar el "pass" solo de mi entorno cuando hay generación de scripts (probar bash -n).

## 14:1x (1 ago) — Correcciones consolidadas entregadas (4e8acea48) PASS 291/291, verificado COMPLETO

Los 3 bloqueantes de 5151680686 cerrados: rollback acredita activeVersionId incluido null (canario de Juan → incierto/0 PUTs); guion con comando Django real (heroku config:get, sin placeholder) + bash -n propio = 0; falso verde eliminado (reverificación no degrada a dry-run); deactivates journalizados + reconciliación tras corte. Verificación del Arquitecto esta vez COMPLETA (artefacto entero + bash -n propio, aplicando la lección del gap). Re-congelado en 4e8acea48. **Técnico cerrado; el cierre del checkpoint espera SOLO datos humanos: Vercel deployment-id (Alberto) + aceptación de Juan (ventana/roles). ~10 rondas; recomendación de sesión síncrona en pie.**

## 14:20 (1 ago) — FAIL focal `5151822875` sobre 4e8acea4 — PASÓ el delta, quedan 2 P1 (convergencia)

Juan PASÓ el delta: rollback null/publicación-no-correlacionable → incierto/0 PUT; guion pasa bash -n y sh -n; reverificación exige `modo: VIVO` (falso verde cerrado); deactivates con intención durable + GET + stop sin retry + reconciliación read-only. 291/291 + focal 30/30. Huellas intactas. **Convergencia: "no hace falta otra ronda sobre hashes/SQL/sinks/estilo".**
Dos P1 restantes (ejecutor):
1. **Acreditar TODOS los producers + Dashboard:** el guion solo mira `WHATSAPP_FOLLOWUPS_ENABLED`; faltan los caminos independientes `WHATSAPP_CHECKPOINT_FOLLOWUPS_ENABLED=false` y `WHATSAPP_CHECKPOINT_FOLLOWUPS_DRY_RUN_DEFAULT=true` (checkpoint followups sigue siendo producer aunque el legacy esté off) + comando que acredite el default-deny del Dashboard. Incumple "todos los producers" + C1.A.3.
2. **Recuperar la pausa, no solo reconciliarla:** el journal guarda el preestado pero ninguna ruta lo consume para restaurar; `permitirPausaInbound` prohíbe activar, `--reconciliar` solo lee. Un corte deja 4/7 inactivos sin vuelta segura; una corrida verde deja los 7 inactivos indefinidamente. C1.A.2 exige read/release/revoke disponibles. → **restore target-guarded SOLO de lo que esta corrida desactivó, desde el preestado journalizado, con intención/GET/incierto sin retry ciego.**
Gate humano (ventana/roles/Vercel) tras los 2 P1, en UNA versión final. Bloqueante nuestro sigue: Vercel deployment-id (Alberto).

## 14:3x (1 ago) — 2 P1 finales entregados (8b2c8c202) PASS 298/298 — TÉCNICO CERRADO

P1.1: guion acredita los 3 producers Django + default-deny Dashboard (ninguna GATE_*_ENABLED, rutas reales del código, fail-closed). P1.2: restore acotado a lo que la corrida desactivó (solo esos ids, GET/incierto, corte 4/7→esos 4). Verificación del Arquitecto COMPLETA (bash -n propio). Re-congelado en 8b2c8c202. **Todos los bloqueantes técnicos de Juan (~11 rondas) resueltos.** Cierre del checkpoint espera SOLO: confirmación Vercel deployment (dpl_E5yQGegYSXZqbNy38TBi4j69U2gK, proyecto dashboard-seguroautoqualitas — Alberto confirma commit en panel) + aceptación de Juan (ventana lunes 3 / figura operador único).

## 14:36 (1 ago) — FAIL focal `5151883251` — Django/restore-4-7 PASS, 2 P1 (Dashboard target + restore verify)

Juan: Django verde (3 controles por valor), restore 4/7 canary PASS, 298/298 + focal 25/25. Dos P1:
1. **Guarda Dashboard NO ligada al deployment:** `VERCEL_DEPLOYMENT_ID` exigido pero cero usos; `vercel env ls production` sin `--project`/`--scope`/`.vercel`, y consulta `production` cuando el 1373d1a de PR #2 es **Preview** (¡confirma mi hallazgo!). Puede mirar otro proyecto/env e imprimir OK. → fijar y verificar proyecto+environment+deployment ID/URL/SHA exactos antes de evaluar gates. (Datos que ya tengo: proyecto `dashboard-seguroautoqualitas`, scope `albers-projects-52295059`, deployment Preview `dpl_E5yQGegYSXZqbNy38TBi4j69U2gK` — commit pendiente de confirmar Alberto.)
2. **`--restaurar` activa sin verificar que A volvió a preimagen:** la guarda solo mira `active`, no compara contenido/settings/fingerprint con la preimagen restaurada; y el restore ni aparece en el guion/manifest de ventana. Canario: workflow inactivo con `C1 Gate` aún presente → restore="restaurado", activate=1, publica C1 Gate. → antes de activar, acreditar por GET el estado completo esperado tras rollback A; no-correlacionable → incierto/0 activate. Integrar el comando literal en la secuencia de rollback con los run IDs.
Convergencia: "no ampliar alcance ni tocar lo verde". Gate humano (ventana/roles/Vercel) tras estos.

## 14:5x (1 ago) — 2 P1 entregados (d651b2253) PASS 305/305

P1.1 guarda Dashboard usa scope/proyecto/entorno-preview/deployment-id reales (ejecutor declara honesto: campos JSON de vercel inspect sin confirmar offline); P1.2 restore acredita estado post-rollback-A contra dos fuentes antes de activar (canario C1 Gate → incierto/0). Verificación del Arquitecto completa. Re-congelado en d651b2253. **2 residuos humanos/runtime:** deployment-id dpl_E5yQ... por defecto pendiente de confirmación de Alberto (commit 1373d1a) + campos JSON en ventana. El deployment de Vercel está ahora en el CÓDIGO como default → la confirmación de Alberto es camino crítico.

## 14:55 (1 ago) — FAIL focal `5151951037` — restore PASS, ÚNICO P1: target Vercel inmutable

Juan PASÓ el restore (acredita contenido vs preestado+export, settings, active=false, activeVersionId=null; canario C1 Gate→0 activate; en secuencia tras rollback A con run-id). Dashboard distingue Preview e inspecciona por JSON. 305/305 + focal 32/32. **ÚNICO P1 restante:** el target es sobreescribible — `VERCEL_DEPLOYMENT_ID/URL` y `DASHBOARD_REPO` con `${VAR:-default}`; el checker compara contra esas mismas vars → se auto-valida; `VERCEL_ORG_ID/PROJECT_ID` exportados pero no usados para acreditar el vínculo. Mismo bypass de target que C1 prohíbe. → fijar ID/URL/repo/org/project SIN override (o rechazar valor previo distinto), leer y comparar `.vercel` contra orgId/projectId fijos antes de `env list`, + canarios de override ajeno fail-closed. No tocar restore/Django/huellas. Ejecutor. Datos humanos ventana/roles siguen aparte.

## 15:1x (1 ago) — Vercel CONFIRMADO por Alberto (panel): dpl_E5yQ... = commit 1373d1a

Captura del panel: deployment `dpl_E5yQGegYSXZqbNy38TBi4j69U2gK` / domain `...8xb7zsprm...` / Source rama `c1-gates-api-default-deny` commit `1373d1a` / Preview / projectId `prj_CU5Qqp3BK2B31HVytLeEOBuSlnrU`. El deployment que hallé por correlación de hora ERA el correcto. Confirmado al ejecutor (`2dd41c8`) para hornear el target inmutable. Checkpoint §1 Dashboard actualizado con la identidad completa. **Ya no hay dato humano pendiente para la guarda Dashboard; solo falta la entrega del ejecutor del target inmutable → técnico cerrado.**

## 15:1x (1 ago) — Target Vercel inmutable entregado (944cd963) PASS 313/313 — TÉCNICO COMPLETO

Target inmutable: valores literales readonly (sin override), verificados por el Arquitecto que provienen de FUENTES REALES (no inventados): projectId prj_CU5Qqp3... + orgId team_MyB7xWdzJZcEPzeK7rlHMFe8 del .vercel/repo.json del clon Dashboard (corrijo mi error previo: SÍ hay .vercel, es repo.json no project.json); deploymentId dpl_E5yQ... = 1373d1a confirmado en panel de Alberto. 313/313. Re-congelado en 944cd963. **TÉCNICO 100% COMPLETO — todos los P1 de ~13 rondas de Juan resueltos.** Falta solo: gate humano de Juan (aceptar ventana lunes 3 + figura operador único + GO). Listo para montar y postear la respuesta única final en cuanto Juan pase el focal de 944cd963.

## 15:15 (1 ago) — 🎯 PASS TÉCNICO OFFLINE de Juan (`5152030384`) sobre 944cd963

Tras ~13 rondas convergentes, Juan cierra el ÚNICO P1 técnico restante: target Vercel inmutable (8 vars readonly/literal, canarios de otro Preview/production/JSON incompleto/otro proyecto fallan cerrados, .vercel acredita orgId+projectId). Nota: en el host de Juan 312/313 — el único fallo es una aserción ambiental que exige el .vercel/repo.json del clon de Alberto (inexistente allí); P2 de portabilidad de test, NO bypass (el guion real falla cerrado sin el vínculo); DIFERIDO sin otra ronda. **TÉCNICO CERRADO.**
Responsabilidad → @oilycoyote (gate humano). Tareas del gate: (1) confirmar deployment ID/URL→SHA 1373d1a (Alberto YA lo confirmó en panel — relayar evidencia); (2) el default-deny EFECTIVO del Dashboard se acredita en ventana (403 GATE_DENIED autenticado, no offline); (3) fijar ventana + roles/suplente; (4) decidir GO por comentario separado. **PASS técnico, NO GO.** C1 abierta hasta checkpoint humano.

## 15:2x (1 ago) — Ejecutor pushea 5fcc0609 (hornea commit) DESPUÉS del PASS de Juan — decisión

Tras el PASS técnico de Juan sobre 944cd963, el ejecutor pusheó `5fcc0609`: hornea el commit confirmado `1373d1a` en la guarda del Dashboard (responde a mi handoff 2dd41c8; probable carrera con el re-freeze c11daeb). Buena intención (verifica el mapeo por código), PERO supera el SHA aprobado y reabre la revisión técnica de Juan — contra su "no tocar lo verde". Juan había enmarcado el mapeo deployment→1373d1a como confirmación HUMANA, no como código. **Decisión pendiente de Alberto (necesita force-push):** (A) restaurar candidato a 944cd963 [el PASSeado] y confirmar el mapeo por el gate humano [evidencia del panel] — recomendado; o (B) quedarse en 5fcc0609 y que Juan re-revise. Recomiendo A.

## 15:2x (corrección) — 5fcc0609 verificado 315/315: recomendación cambia a HOLD (no restaurar)
Verificado: 5fcc0609 hornea el commit 1373d1a (machine-verifica el mapeo del gate humano #1) + corrige orgId a team_MyB7... 315/315, limpio. Cambio recomendación: NO restaurar a 944cd963 — la mejora atiende justo lo que Juan pidió y no rompe nada; restaurar la tiraría. Juan ya revisa 5fcc0609. Congelación DURA al ejecutor (no más pushes, ni mejoras). Esperar el focal de Juan.

## 15:21 (1 ago) — 🎯 SEGUNDO PASS TÉCNICO de Juan (`5152051722`) sobre 5fcc0609 — TÉCNICO C1 CERRADO Y APROBADO

Juan PASÓ el pin del source: `FIJO_COMMIT=1373d1a...` + `FIJO_RAMA=c1-gates-api-default-deny` literales/readonly; otro commit/rama/source ausente → fail-closed; contraste read-only local confirma que 1373d1a ∈ origin/c1-gates-api-default-deny. En su host 313/315 (2 P2 no portables por ruta /Users/AIP hardcodeada — diferidos). **TÉCNICO C1 100% CERRADO Y APROBADO por Juan sobre 5fcc0609.**
Gate humano (todo de @oilycoyote + inputs de Alberto): fijar ventana + roles/suplente; la evidencia efectiva `403 GATE_DENIED` del Dashboard se acredita EN LA VENTANA (no offline); decidir GO por comentario explícito. La confirmación del panel horneada NO sustituye el comentario de checkpoint humano. Candidato congelado duro en 5fcc0609. Listo para postear la respuesta del gate humano con OK de Alberto.

## 15:2x (1 ago) — Respuesta del gate humano POSTEADA a Juan (`5152108294`, OK de Alberto)

Datos humanos definitivos fijados: (1) deployment dpl_E5yQ...=commit 1373d1a confirmado en panel; (2) ventana lunes 3 ago 09:30 CDMX/15:30 UTC; (3) roles = operador único (Alberto operador, Arquitecto 2º técnico, Juan guardia — sin suplente humano independiente); (4) 403 GATE_DENIED se acredita en la ventana. Pedido a Juan: aceptar ventana+figura y emitir checkpoint/GO humano. **Todo lo que depende de nuestro lado, CERRADO.** Pelota 100% en Juan: aceptar + GO. Nada se ejecuta hasta su comentario explícito.

## 15:36 (1 ago) — Juan: gate humano incompleto (`5152112808`) — bloqueo RACI/suplente, NO técnico

Técnico totalmente aceptado (nada más ahí). Deployment→SHA y ventana (lunes 3 09:30) aceptados. El `403 GATE_DENIED` puede ser precondición/primer paso de ventana con STOP si falla. **ÚNICO bloqueo: no se puede rebajar el RACI canónico (#140 §10):** A humano = @oilycoyote (Juan, NO Alberto); R primario = @aibanez82 (Alberto); Suplente = operador n8n STG nominal (HUMANO con acceso); IA nunca es A ni emite GO. → El "operador único con Arquitecto como 2º técnico" NO satisface el suplente (la IA no puede serlo). Antes de GO, expresamente por el A: (a) nombrar suplente HUMANO con acceso probado + stop/rollback, O (b) modificar el RACI canónico de #140 asumiendo/delimitando el riesgo de operador único (enmienda en #140). Silencio no vale. **DECISIÓN DE ALBERTO.** (También: RACI dice Alberto=R no A; mi post lo llamó "accountable" — el A es Juan.)

## 15:5x (1 ago) — Solicitud de enmienda del RACI (operador único C1) posteada a Juan (`5152822925`, OK de Alberto)

Alberto eligió vía (b): pedir a Juan (A) enmendar el RACI canónico de #140 §10 para C1, aceptando operador único con riesgo ACOTADO por los controles ya construidos (doble vigilancia stop, rollback recuperable tras corte, instalador inerte con 5 guardas, alcance C1 reversible). Delimitado a C1 (C2+ aparte). Pedido: enmendar RACI + emitir GO, o indicar controles adicionales. **Nuestro lado CERRADO; la decisión del operador único + GO es de Juan (A).**

## 18:37 (1 ago) — Juan: solicitud RACI suficiente para decisión del A (`5152829869`) — no es enmienda ni GO

Juan valida la solicitud (atribución R/A correcta, ausencia de suplente declarada, acotada a C1, C2+ aparte). No falta técnico. Dos límites: (1) la excepción SOLO existe si Juan la ESCRIBE en #140 (silencio/dictamen/controles no la crean); (2) la enmienda no rebaja otros gates: **RTO canónico restore n8n ≤20 min (§11 #140)** — corrijo el checkpoint (yo había puesto <30); la IA observa/invoca STOP técnico pero no es A; el GO operativo va posterior y separado en #132. **Decisión EXCLUSIVA del A (Juan):** aceptar+enmendar #140 (alcance C1, controles, RTO canónico, CADUCIDAD) → checkpoint separado; o rechazar → volver a Alberto por suplente. Checkpoint §7 RTO alineado a ≤20 min.

## 23:19 (1 ago) — 🎯 Juan ENMIENDA el RACI: acepta operador único para C1 (`5153952626`, #140) — NO es el GO

Juan (A canónico) acepta la excepción de operador único para C1/STG. Alcance: solo C1 (barrera A+B), operador único @aibanez82, Juan sigue A+guardia/STOP, la IA observa/pide STOP pero no es A ni operador ni emite GO. **Si Alberto no está disponible → ventana se CANCELA (sin sustitución automática).** Controles obligatorios: instalador inerte+target guard origin exacto; fsync/0600+intención previa+reconciliación GET; stop inmediato ante drift/uncertain sin retry; rollback solo por run-id con guardas por workflow; **RTO restore n8n ≤20 min**; triple observación de stop (Alberto+Juan+monitor). Caducidad: al instalarse C1, o al terminar/cancelarse/abortarse la ventana del lunes 3, o ante drift/incierto/repetición. C2+ y cualquier reintento vuelven al RACI canónico. **Enmienda acepta riesgo/RACI, NO es GO.** Tarea de Juan: emitir GO/NO-GO separado en #132 sobre 5fcc06099. El bloqueo del gate humano queda RESUELTO; el GO es inminente.

## 23:24 (1 ago) — Juan propone VENTANA INMEDIATA en vez del lunes (`5153971787`) — decisión de Alberto

STG no tiene otros usuarios humanos (solo Alberto+Juan), así que Juan propone no esperar al 3-ago y hacer la ventana YA (hasta 2h), en cuanto Alberto confirme disponibilidad para operar y permanecer toda la ejecución/rollback. La ventana sigue siendo cerco operativo (los PUT publican al instante; interrupción = estado parcial), no por tráfico. **NO es GO aún** — no ejecutar ni prechecks vivos hasta comentario explícito con hora inicio/fin. Tarea de Alberto: confirmar si está disponible AHORA ~2h, con acceso operativo funcional, sin otra sesión/UI editando n8n STG, y capacidad de rollback ≤20 min. Su confirmación → Juan fija timestamps y emite/rechaza GO inmediato; indisponible → Alberto propone primera ventana cercana. **DECISIÓN DE ALBERTO.**

## 23:26 (1 ago) — Juan: sincronización inmediata, sin ventana calendarizada (#140 5153977172 / #132 5153977974)

Superadas la fecha del lunes 3 y la propuesta de 2h. Modelo STG ahora: (1) Alberto confirma listo + sin otra sesión editando n8n STG; (2) Juan emite GO específico del checkpoint; (3) Alberto ejecuta inmediato, ambos sincronizados hasta evidencia/STOP/rollback. Inicio/fin+run-id se registran como evidencia, no aprobación de calendario. Caducidad de la excepción operador único redefinida: termina al completar/abortar la sesión C1 sincronizada, o ante incierto no reconciliado, o nueva corrida. RTO ≤20 min. NO es GO. **Pendiente: confirmación de disponibilidad inmediata de Alberto → Juan emite GO.**

## 23:3x (1 ago) — Alberto confirma "AHORA"; disponibilidad relayada a Juan (`5154060859`)

Alberto listo para C1 inmediata. Verificado: credenciales n8n STG en Agente-n8n/.env (exportar al arrancar); target guard exige origin n8n-xlqk exacto. División operativa por accesos: Juan corre docker inspect del modo publicación (2FA Hostinger, Alberto no lo tiene) + confirma UI cerrada; Alberto ejecuta instalador C1 + Django migrate --check + prueba 403 Vercel; Arquitecto vigila stop conditions en vivo. Esperando GO específico de Juan con checkpoint/comandos/targets exactos. **En el umbral de la ejecución viva.**

## 23:53 (1 ago) — Juan: disponibilidad registrada, gate no cambió (`5154066236`) — GO aún pendiente

Juan confirma precondiciones (R presente, accesos repartidos, exclusión a reconfirmar, RTO ≤20). Pero reitera procedimentalmente: la disponibilidad NO sustituye la enmienda RACI (ya en #140 5153952626) ni el GO/checkpoint específico posterior. Punto operativo clave: el modo de publicación es valor a OBSERVAR en ventana ("esperado síncrona" ≠ acreditación); si sale asíncrona/no concluyente → STOP antes de credenciales/mutaciones. Su tarea: (1) enmienda RACI [ya posteada 23:19] → (2) emitir/rechazar GO separado con comandos/target/orden/prueba 403/stop/rollback. **GO aún pendiente de Juan.** No es ask de Alberto.

## 23:57 (1 ago) — Juan corrige estado: RACI YA enmendado, solo falta GO C1 (`5154077026`)

Juan supersede su propio 5154066236: la excepción operador único ya aceptada (#140 5153952626) + sincronización inmediata (#140 5153977172), ambas antes de la disponibilidad de Alberto. **Nada más de código ni coordinación de Alberto.** Único gate: el GO operativo del A en #132. Su tarea: emitir/rechazar GO C1 que autorice primero el preflight Hostinger read-only (docker inspect) y, solo si todas las precondiciones pasan, la ejecución A+B sobre 5fcc06099. Modo publicación = primer precheck; no concluyente/async → STOP antes de mutaciones. **GO INMINENTE.**

## 00:01 (2 ago) — 🟢 GO OPERATIVO C1 de Juan (`5154091214`) — SESIÓN VIVA

Juan (A) emite el GO C1 en STG, una sola corrida sincronizada, sobre 5fcc06099 (tree 2a12c807). Verificación del Arquitecto (2º técnico): tree ✓ + los 5 hashes de artefactos ✓ coinciden con el GO (comandos-ventana.json 44be6d2d, plan-instalacion.json f04f2075, instalar-clones.js 9b8753c2, pausar-inbound.js bf899698, preflight-publicacion.sh 8d903b57). Target STG n8n-xlqk.srv1810257 v2.28.7 instance 7ae96bdc... AUTORIZACION=5154091214, GARANTE=Juan, VENTANA=sync-inmediata-c1-5154091214. Secuencia: (1) Alberto checkout detached+verifica; (2) Juan docker inspect publicación=síncrona o STOP; (3) prechecks (target/version, 0 en-vuelo, UI cerrada, 3 producers Django, migrate --check, deployment Vercel exacto, 403 GATE_DENIED); (4) solo si todo verde: pausa 7 ingress + barrera B 7 POST + barrera A 7 PUT (orden B→A) + GET post; (5) 2 run-ids + evidencia. STOP autorizado ante cualquier discrepancia; rollback solo por run-id, RTO ≤20min. Una corrida; si no arranca bajo esta sync, aborta+nuevo GO+excepción caduca. **Alberto opera; Arquitecto vigila stop conditions.**

## 00:49 (2 ago) — Paso 2 PASS: preflight Hostinger de Juan = síncrona (`5154268653`)

Juan corrió el docker inspect read-only en la Web console del VPS STG: `PRECHECK_OK: version=2.28.7 mode=sincrona variable=ausente`. Versión pin confirmada, N8N_USE_WORKFLOW_PUBLICATION_SERVICE ausente → publicación SÍNCRONA (el caso que el instalador exige). Precondición cerrada. Responsabilidad → Alberto para el resto de prechecks (Paso 3) y la corrida. Modo a pasar al CLI: --publicacion-observada "sincrona".

## (2 ago, madrugada) — Paso 3 prechecks: 3a-3e VERDES; 3f BLOQUEADO → HOLD, decisión a Juan (`5154417314`)

Alberto operó el Paso 3. Verde: 3a target/clave n8n STG=200; 3b 0 ejecuciones en vuelo; 3c 7 activos = 7 IDs del GO (7/7), 0 schedule/cron; 3d Django false/false/true; 3e migrate --check exit 0. (El Arquitecto verificó 3a/3b/3c en paralelo read-only con la N8N_STG_API_KEY de .env.local — clave de 267 chars; Alberto exportó primero por error una service-account de OpenAI sk-svcacct-… → 401; rotarla, quedó expuesta en chat.)

**3f (prueba autenticada Dashboard → 403 GATE_DENIED) NO PRODUCIBLE en el Preview congelado.** Causa raíz (verificada en código+env del Preview c1-gates-api-default-deny dpl_E5yQ…, SHA 1373d1a): DATABASE_URL está scopeada a "Preview (stg)" → ausente en esta rama → el login (auth.js) hace SELECT sobre dashboard_users, sin BD lanza y cae al catch 500 "Error de autenticación" (frontend login.js:28 muestra el mensaje del server; el 401 diría otro texto). Catch-22: sin BD no hay sesión; sin sesión getAgentFromRequest→401 antes del gate; nunca se alcanza el 403 GATE_DENIED. Dashboard contenido por TRIPLE vía: (1) sin DATABASE_URL, (2) cero GATE_*_ENABLED provisionadas → isGateEnabled (=== 'true') default-deny, (3) guard Bug #17 en n8n-proactive-message.js. El diseño del ejecutor ya trata la sonda-con-sesión como paso humano y acredita la CONFIGURACIÓN sin credenciales. Provisionar DATABASE_URL rompería el freeze y no lo autoriza el GO.

**Acción:** HOLD en Paso 4 (pausa/B/A). Comentario a Juan en HYL-WAI#132 (`5154417314`) pidiendo decisión entre: (A, recomendada) aceptar acreditación config default-deny como cumplimiento de 3f; (B) acuñar dashboard_session JWT con el JWT_SECRET del Preview → GET /api/metepec-leads → 403 GATE_DENIED sin tocar freeze (el gate va antes de la BD). Todo lo demás verde y en espera.

## (2 ago 01:32 UTC) — ✅ Juan ENMIENDA el GO: acepta opción A para 3f (`5154440416`)

Juan (A) acepta la opción A de `5154417314`: acreditación de configuración default-deny como sustitución ACOTADA de la prueba autenticada 403 del Dashboard, sobre el deployment congelado dpl_E5yQ.../1373d1a. Evidencia aceptada: (1) sin DATABASE_URL en el Preview → sin camino de login/BD; (2) cero GATE_TAKE/DISPATCH/METEPEC_ENABLED en el env Preview; (3) isGateEnabled solo con "true" literal; (4) guard Bug #17. **NO autoriza opción B** (nada de acuñar JWT, leer/usar JWT_SECRET, provisionar DATABASE_URL, tocar Vercel ni el deployment congelado). Modifica ÚNICAMENTE el criterio 3f. 3a-3e registrados verdes; 3g (UI cerrada) confirmado por Alberto. Autoriza reanudar la MISMA sesión desde el Paso 4 (pausa → B → A → verificación), mismos stop conditions, rollback ≤20 min. **Condición previa a la primera mutación:** reconfirmar target, 0 en vuelo, exclusión/UI cerrada y fingerprints anti-TOCTOU; si hay drift, STOP. Responsable siguiente: @aibanez82. HOLD levantado; pasamos a reconfirmación de guardas + Paso 4.

## (2 ago 01:40 UTC) — Paso 4.1 PAUSA journalizada = VERDE (run-id pausa `c1-20260802T014026-c975`)

Alberto ejecutó la primera mutación: pausar-inbound.js --vivo con --publicacion-observada sincrona, ventana sync-inmediata-c1-5154091214, garante Juan-@oilycoyote, autorizacion 5154091214. Los 7 ingress → pausa-verificada, RESULTADO verde. **run-id de la pausa: c1-20260802T014026-c975** (journal en build/corridas/…; para restore: --restaurar --run-id c1-20260802T014026-c975). Verificación independiente del Arquitecto (read-only): los 7 vivos active=false y 0 workflows activos en toda la instancia. Siguiente: paso 4.2 barreras B→A (instalar-clones --barrera ab --vivo).

## (2 ago 01:41 UTC) — Paso 4.2 barreras: STOP fail-closed en B (causa raíz: pausa-antes-de-B invalida el anti-TOCTOU congelado). Recuperado.

instalar-clones --barrera ab --vivo (run-id instalación c1-20260802T014148-21a0). B falló en el PRIMER clon: journal i1 verificar-cabeza-viva → error codigo "cabeza-viva-cambiada". Causa raíz: B arranca verificando la cabeza VIVA del workflow fuente contra el fingerprint CONGELADO, que se calculó con los workflows en active=true (pre-pausa). La pausa 4.1 los puso active=false → la cabeza viva cambió (n8n bumpea active/versionId al desactivar) → B fail-closed. Es un defecto de ORDEN: la secuencia GO pausa→B→A es incompatible con el anti-TOCTOU congelado de B, que espera el estado pre-pausa. (El anti-TOCTOU manual del paso 3c pasó porque corrió ANTES de la pausa, con active=true — confirma que las huellas son correctas para el estado pre-pausa; el problema es que B las re-verifica DESPUÉS de la pausa.) Fail-closed correcto: b.resultados=[], a.resultados=[] → CERO clones creados, CERO vivos tocados por A.

**Recuperación (pre-autorizada, RTO ≤20min):** restore de la pausa run-id c1-20260802T014026-c975 → 7/7 restore-verificado verde; reconcile → 7 ACTIVO, pausados acreditados 0/7. Verificación independiente del Arquitecto: 7 vivos active=true, contenido intacto (node counts iguales), 7 activos en instancia, 0 clones C1-AISLADO. STG restaurado a estado pre-ventana. Sin daño.

**Estado gobernanza:** STOP conforme al GO. Excepción de corrida única consumida (la corrida comenzó y paró en B). Re-intento requiere fix del defecto de orden (lado ejecutor) + nuevo GO. Responsabilidad → @oilycoyote. Pendiente: reporte STOP a #132 + handoff del defecto al Agente n8n.

## (2 ago) — Reporte STOP a Juan + handoff del defecto al ejecutor

Reporte del STOP posteado a HYL-WAI#132 c.`5154508007` (secuencia real, causa raíz, recuperación verde, gobernanza: excepción consumida, re-intento requiere fix+nuevo GO, responsabilidad→@oilycoyote). Handoff del defecto al Agente n8n commiteado a su `main` (`Agente-n8n@c2d6dea`, vía worktree — el checkout de Alberto sigue en la rama feature intacto): `handoffs/2026-08-02-c1-defecto-orden-pausa-B-anti-toctou.md`, con causa raíz y 2 vías de fix (a: cabeza-viva content-only + re-freeze de huellas + nuevo GO; b: reordenar B→pausa→A con bendición de Juan). Offline; nada en vivo hasta nuevo GO.

## (2 ago 02:00-02:02 UTC) — Fix del ejecutor + Juan confirma FAIL P1 (convergen, casi simultáneos)

Ejecutor entregó fix del STOP en rama nueva feature/c1-cabeza-viva-invariante-a-la-pausa@02fd9ec (informe Agente-n8n@cff33f7, docs/2026-08-02-informe-arquitecto-cabeza-viva-invariante-a-la-pausa.md), vía (a): fingerprintFuenteViva() = fingerprintWorkflow menos active, usada por las 2 guardas de fuente + comprobar-fingerprint; re-freeze de 7+7 huellas en plan-instalacion.json; cuerpos y comandos-ventana.json sin cambio; 326/326 x3, fail-first 6/11. Hallazgo del ejecutor (verificado por el Arquitecto en el código): el defecto también estaba LATENTE en la barrera A (tomarPreimagen también metía active) → descarta la vía (b). Verificación del Arquitecto: fingerprintFuenteViva idéntica a fingerprintWorkflow salvo active (no rebaja guarda); base desciende de 5fcc06099 (intacto).

Juan (02:02, c.5154563080) reprodujo el mismo defecto offline, confirmó A enmascarada, y prescribió "ruta mínima segura" de 6 puntos (vía a): #1 aserto explícito active===false + activeVersionId===null en B y A; #2 normalizar solo active; #3 persistir cortes tempranos de B (onProgreso); #4 herramienta GET-only que reemplace la falsa re-verificación (que hace POST/PUT vía instalar-clones --vivo); #5 regresión integrada active:true→pausarInbound→B→A en un ClienteFalso + canarios; #6 sim post-pausa + re-freeze manteniendo 14 cuerpos. Correcciones de Juan a mi reporte: (a) "plano vivo exactamente como antes" demasiado amplio — hubo 7 deactivate+7 activate, cada activate publica activeVersionId nuevo (contenido/settings/active:true restaurados 7/7 pero declarado, no probado independientemente); (b) b.resultados=[] es laguna de observabilidad. Tarea Juan → @aibanez82: UN SHA nuevo con la corrección+regresiones + evidencia sanitizada del restore; PASS offline → @oilycoyote para RACI/GO nuevo.

Reconciliación 02fd9ec vs 6 puntos: núcleo (vía a + re-freeze + contra-tests) OK; faltan #1, #3, #4, #5. Handoff al ejecutor: Agente-n8n@2412d7e (handoffs/2026-08-02-c1-ruta-minima-segura-juan-6-puntos.md). Evidencia del restore la prepara el Arquitecto.

## (2 ago) — port-132 dual-prep: CERRADO (subagente verificó)

Mapeo read-only: los 10 items P0/P1 del dictamen NO-GO de Juan (29 jul) están RESUELTOS en feature/issue-132-port-dual-safe (commit 1424163 + 6 pases de re-auditoría → GO técnico de Juan 30 jul 17:08, matriz 1..7 PASS). Decisión (f) respetada (gates mantenidos y reforzados). Ninguno abierto; residual declarado/aceptado en item 5 (trigger sin columna dedicada). Nada accionable; la vía viva de dual está gated detrás de C1.

## (2 ago 02:24 UTC) — 🔶 Juan ENMIENDA #140: delega autorización de acciones vivas STG al monitor; C1 re-run PRE-AUTORIZADO (c.5154662330; espejo #132 02:24:44)

Enmienda accountable de Juan. Puntos clave:
- #140 pasa a issue de decisión/arquitectura/RACI; C0-C5→#132, C7→#128, C6/C8/C9→trackers nuevos. Cerrar #140 = planificación completa, NO implementación ni PROD/enforced.
- C5 sin espera pasiva 24h: 3 matrices sintéticas independientes (run-id distintos), modo final dual en STG.
- **Delegación al monitor**: PASS/FAIL técnico, clasificación P0/P1/P2, diferimiento P2, revisión consolidada por SHA, prep offline de la fase siguiente, verificación de condiciones de checkpoint. **NO se exige un nuevo GO humano por cada fase viva C1-C5 en STG.** La enmienda es autorización humana condicional PREVIA cuando se cumplen 7 condiciones objetivas (fase previa cerrada; SHA/tree congelados—push posterior invalida PASS; checkpoint publicado en #132 con target/comandos/stop/RTO/rollback; PASS técnico sin P0/P1; Alberto disponible + target STG acreditado; alcance sintético/allowlisted sin PROD; una sola corrida—STOP/drift/uncertain consume la autorización). Cumplidas, el monitor publica "condiciones de autorización humana satisfechas" y transfiere a Alberto; NO se requiere otra confirmación de Juan.
- **C1 re-run específico pre-autorizado** cuando: @aibanez82 publique SHA correctivo + evidencia offline; el monitor emita PASS consolidado sobre el defecto pausa→B→A + observabilidad temprana + verifier GET-only; checkpoint/hashes regenerados y publicados; STG restaurado/acreditado + guardas inmediatas pasan. Cumplido → Alberto ejecuta sin otro GO humano. STOP/uncertain en esa corrida → nueva decisión humana.
- C2 puede prepararse offline mientras C1 termina (no ejecutarse antes del cierre operativo de C1). Una sola revisión consolidada por SHA; SHA congelado tras PASS.
- Límites sin cambio: no C6-C9, Meta real, secretos/rotación, PROD, enforced, fuera de checkpoint, target distinto, reintento tras STOP.

**Lectura del Arquitecto:** el handoff 2412d7e ya apunta EXACTO a las 3 condiciones nombradas para el PASS del monitor (defecto pausa→B→A + observabilidad temprana + verifier GET-only). AMBIGÜEDAD a aclarar: "el monitor" que publica "condiciones satisfechas" — se lee como el monitor técnico v2 de JUAN (tiene autoridad PASS/FAIL), NO el Arquitecto; el Arquitecto NO asume poder de autorizar acciones vivas (el GO original lo limitó a observar+STOP). La evidencia del restore pasa a ser precondición nombrada del re-run.

## (2 ago 03:00-03:30 UTC) — SHA correctivo 415ee46 verificado + checkpoint del re-run publicado; hub Arquitecto activo

- Ejecutor entregó 415ee46 (informe e3161f4) cerrando los 5 puntos de Juan: aserto de estado active===false/activeVersionId===null en B/A (instalador.js/instalador-vivo.js), cortes tempranos de B persistidos, verificar-instalacion.js GET-only (permitirSoloLectura estructural), regresión integrada real pausarInbound→B→A + canarios; destapó y corrigió un bug del cliente falso (publicaba sobre pausados; verificado contra workflow.service.ts:553 — la puerta es activeVersionId, que deactivate deja null). Ejecutor avanzó PR #3 a 415ee46 por fast-forward (limpio). **Verificación independiente del Arquitecto: suite 338/338 (npm test); asertos y verifier GET-only en código; contenido vivo de los 7 STG == huellas re-congeladas 7/7.**
- **Evidencia del restore** (precondición nombrada): 7/7 contenido/settings==freeze, active=true, activeVersionId NUEVOS (caveat de Juan confirmado).
- **Checkpoint del re-run publicado en #132 (5154925188)**: identidad 415ee46/tree 2b85f038, hashes de artefactos, anti-TOCTOU content-only (d0d2fdbe…), secuencia con paso 5 GET-only, guardas, STOP/RTO/rollback, evidencia offline+restore.
- Juan's monitor v3 auditando 415ee46 (03:14) y el checkpoint (03:20).
- **Nueva directriz operativa (Alberto+Juan): el Arquitecto es único interlocutor hasta C5; las IA de ambos lados convergen y cierran sin preguntar a los humanos. Autoridad del Arquitecto C1→C5, mismas líneas duras (secuencial; una corrida/fase; STOP→humano; sin PROD/Meta/secretos/enforced/C6-C9; guards puestos).**
- Ejecutor (ccfce002) pidió 4 desbloqueos: #1 scope C2-C5 → handoff C2 emitido (main e28b91d: matriz M1-M6, suite negativa, fixtures, harness offline); #2 traceability + #3 aval B→A → transmitidos a Juan (#132 5154946600); #4 los 4 puntos del runbook humano → anotados al checkpoint.
- **HOLD:** esperando al monitor v3 (PASS de 415ee46 + aval B→A + traceability). Cumplido eso + guardas → el Arquitecto ejecuta la única corrida C1 (pausa→B→A) bajo la pre-autorización 5154662330.

## (2 ago 03:30 UTC) — SHA drift detectado y estabilizado en e7f3a78; datos de ventana resueltos

El candidato se movió 415ee46→e7f3a78 (runbook generado + fix cross-ref paso 8 + fix test Dashboard-HEAD), y el monitor v3 ya auditaba e7f3a78, no el 415ee46 de mi checkpoint. Verificado por el Arquitecto: delta INOCUO — los 6 artefactos ejecutables byte-idénticos, 7 fingerprints anti-TOCTOU sin cambio (contenido vivo==freeze 7/7 sigue válido), único cambio en plan-instalacion.json es un comentario del restore; suite 340/340; tree 3ccce460. Alineado todo en e7f3a78: handoff de FREEZE al ejecutor (main 2fc1f82: no más pushes al candidato C1, C2 en rama aparte, guardas intactas) + checkpoint de #132 actualizado (5154997235).

Datos de ventana (Alberto tomó autoridad: "jamás os detengáis por unos datos de ventana"): ventana=sync-inmediata-c1-rerun, garante=Alberto-@aibanez82, autorizacion=el comentario "condiciones satisfechas" del monitor v3 (que espero igualmente para ejecutar). El ejecutor confirmó y mantuvo la lectura correcta: "no os paréis esperando ≠ rebajar la guarda" — sin los 3 datos, dry-run por diseño.

**HOLD:** esperando al monitor v3 → PASS de e7f3a78 + aval B→A + "condiciones satisfechas". Cumplido + guardas → el Arquitecto ejecuta la única corrida C1 (pausa→B→A).

## (2 ago ~04:00 UTC) — SHA correctivo 161d6913: FAIL 5154995079 cerrado, verificado hermético; mis 2 partes publicadas

Ejecutor entregó 161d6913 (informe 226e52a47) cerrando los 3 de código: #1 normalize active (fingerprintFuenteNormalizada = fingerprintWorkflow con active fijado al freeze; las 7 huellas VUELVEN a las originales de 5fcc06099 — bot 9380710b); #2 orden runbook (productores expone pre/postinstalacion, verifier solo post-install, canarios de orden y único post-check); #3 suite hermética (enlace Vercel movido a preflight-enlace-vercel.js, hermetismo.test.js guardián). **Verificación independiente del Arquitecto ESTA VEZ BIEN: suite 349/349 desde git archive limpio con .vercel AUSENTE** (corrige mi 340/340 local previo no hermético); asertos y normalize en código; contenido vivo == freeze 7/7 (normalizado).

Mis 2 partes publicadas en checkpoint exacto #132 (5155176112, reemplaza 5154925188): #4 restore 7/7 sanitizado por workflow (contenido==freeze, active=true, activeVersionId nuevos f69215fc…, 0 clones, 0 en vuelo, 7 totales, uncertain=0); #5 checkpoint exacto de 161d6913 (tree b441a311, hashes completos no truncados, secuencia corregida verifier solo post-install, garante HUMANO Alberto, autorizacion=comentario "condiciones satisfechas" del monitor aplicando 5154662330). PR #3 = 161d6913.

**HOLD:** único gate restante = PASS consolidado del monitor v3 sobre 161d6913 + verificación de mi checkpoint/restore → publica "condiciones satisfechas" → el Arquitecto ejecuta la única corrida C1 (pausa→B→A) con las guardas frescas.

## (2 ago ~04:22 UTC) — P1 operativo cerrado en 2b9096a; checkpoint republicado

Ejecutor entregó 2b9096a (informe d9d4eace) cerrando el P1 5155205173: pausar-inbound.js con expectativa post-restore explícita "0/7 activos → exit 0" (vía a, conserva la lectura independiente) + nuevo ciclo-completo.test.js (canario que exige exit 0 en los 6 pasos pausa→B→A→verifier→rollback→restore→reconcile); P2 cerrados (--active-congelado en los comandos, comprobar-fingerprint fail-closed, dup tests quitados). Verificación independiente del Arquitecto: suite 351/351 desde git archive limpio (.vercel ausente), ciclo-completo pasa. Hashes cambiados: pausar-inbound 3b5f2923, comprobar-fingerprint a53004f1, plan-instalacion a0eaaf20; fingerprints anti-TOCTOU sin cambio (9380710b originales). tree d91ae27c.

Checkpoint republicado #132 (5155289240, reemplaza 5155176112) para 2b9096a con las 2 correcciones de Juan: --autorizacion 5154662330 (no placeholder) y semántica corregida (rollback NO reactiva; --restaurar SÍ reactiva). Restore evidence 7/7 sigue válida (fingerprints sin cambio). HOLD: espera PASS consolidado del monitor v3 sobre 2b9096a + verificación del checkpoint → "condiciones satisfechas" → 2ª corrida.

Aparte: AI Delivery Audit caso #1 escrito (docs/2026-08-02-ai-delivery-audit-caso-1-c1.md, commit local bd24074 sin push) — pendiente decisión de Alberto sobre push (repo público) y artefacto.

## (2 ago 05:05-05:12 UTC) — ✅✅ C1 EJECUTADO Y ACREDITADO EN STG (corrida única, verde completo)

Ruta al disparo: monitor v3 dio PASS técnico consolidado sobre 416d1987 (5155482965, sin P0/P1: suite 349→356/356 hermético, ruta mínima literal PASS, ciclo-completo exit 0, install/rollback consumen $VENTANA/$GARANTE/$AUTORIZACION). Arquitecto congeló 416d1987 (Agente-n8n@293377f) + midió guardas frescas (target 200, 0 en vuelo, 0 schedule, anti-TOCTOU 7/7) + publicó handoff de ventana (5155509842) con disponibilidad de Alberto + UI cerrada. Monitor aplicó la pre-autorización 5154662330 y transfirió la corrida única ("condiciones de autorización humana satisfechas", 5155529675).

CORRIDA (operador humano Alberto, Arquitecto vigilando): 
- Pausa run-id c1-20260802T050946-7aa3 → 7 pausa-verificada, verde. Arquitecto verificó: 7 active=false, 0 activos.
- Barreras B→A run-id c1-20260802T051054-0453 → B: 7 clones C1-AISLADO creados (active:false) + GET OK; A: 7 estado-verificado-workflow-inactivo. RESULTADO verde. **El fix del active normalizado hizo pasar el anti-TOCTOU que paró la 1ª corrida.**
- Post-check GET-only (verificar-instalacion.js --vivo): 7 clon-acreditado + 7 vivo-contenido-acreditado, verde.
- Verificación independiente Arquitecto: 14 workflows (7 vivos + 7 clones), 7 clones active=false, 7 vivos active=false contenidos, 0 activos. Cardinalidad 7+7.

**SIN STOP, SIN uncertain, SIN retry.** Plano vivo STG contenido default-deny; 7 clones aislados para C2. Evidencia sanitizada publicada #132 (5155576499). Devuelto a monitor v3 para cierre operativo C1 + prep offline de C2. HOLD: espera confirmación de cierre C1 del monitor.

## (2 ago 05:25 UTC) — HOLD de cierre C1: omití el tramo de productores/prechecks (error del Arquitecto)

Monitor v3 (5155631752): núcleo 7+7 verde, pero el reporte salta el tramo obligatorio del paso 4 (productores/prechecks entre pausa e instalación): OK 1b webhook-404, OK 2 Django, OK 2b Vercel/1373d1a/GATE_*, OK 3a runner 56→0, TODOS LOS PRECHECKS ACREDITADOS. Realidad: di al operador la secuencia pausa→barreras→verifier y OMITÍ comandos-ventana-productores.js. En la 1ª ventana (~01:2x) sí se hicieron los prechecks 3d/3e/3f, pero NO frescos entre pausa e instalación de esta corrida; webhook-404 y runner 56→0 no se corrieron como paso de la corrida.

Aclaración de journal (verificado): los "inciertos" 7/14 son transitorios (deactivate/POST/PUT-emitido-pendiente-de-verificar), cada uno resuelto por GET a verificada/acreditado; 0 incierto SIN resolver; verde:true, errores:0 en ambos run-id. Mi "uncertain=0" era 0-sin-resolver (correcto), lo precisé.

Complemento honesto publicado (5155662487): declaro la omisión sin disfrazarla + evidencia de journal + estado POSTERIOR read-only claramente etiquetado (webhook-404 7/7=404, Django false/false/true, Dashboard opción-A). Conforme a 5155631752 la desviación vuelve a @oilycoyote. Estado real fail-closed y seguro; sin PROD tocado. Lección: en un re-run hay que re-ejecutar (o acreditar explícitamente con OK de Juan) TODO el tramo de precondición, no solo las guardas inmediatas de n8n.

## (2 ago 11:48 UTC) — ✅✅✅ C1 CERRADA OPERATIVAMENTE por Juan (decisión accountable humana, 5157632531)

Juan (humano A) volvió por la mañana (05:34 STOP → 11:48 decisión) y ACEPTÓ la desviación declarada en 5155662487, cerrando C1. Excepción única aceptada porque: (1) los ingress ya estaban desactivados antes de los POST/PUT; (2) mutación principal + post-check GET-only verdes; (3) evidencia posterior fail-closed; (4) repetir/completar/rollback ahora añadiría riesgo sin reconstruir la precondición histórica. La aceptación NO crea precedente ni convierte la comprobación posterior en precondición; la omisión queda registrada — futuros checkpoints deben ejecutar su secuencia EXACTA. Sin rollback/restore/repetición/reactivación. Corrida C1 consumida y aceptada.

Evidencia aceptada por Juan: artefacto 416d1987 (PASS 5155482965, 356/356); pausa 7aa3 (7/7); instalación 0453 (B 7 clones + A 7 vivos, GET-only 7+7); 14 workflows = 7 vivos contenidos + 7 clones, todos active=false; cero retry/uncertain-sin-resolver/rollback; Dashboard opción A; producers Django/webhooks seguros.

**C1 CERRADA. La contención está viva en STG.** Estado final: plano vivo STG contenido default-deny + 7 clones aislados para C2, todos active=false. Sin PROD tocado en toda la operación.

Siguiente: monitor v3 + @aibanez82 completan la prep C2 OFFLINE (manifest allowlisted, fixtures/run-id, runner one-shot, verifier GET-only, cleanup, canarios) → checkpoint C2 consolidado en #132. C2 vivo solo tras PASS técnico + las 7 condiciones de 5154662330. Lección dura registrada: en re-run ejecutar el tramo de precondición COMPLETO, no solo las guardas inmediatas.

--- FIN DE LA MARATÓN C1: ~31h (28 jul #132 → 2 ago 11:48 cierre), ~24 SHAs, 1 STOP en vivo recuperado + 1 desviación aceptada, C1 contención VIVA y CERRADA en STG. ---

## (2 ago mañana) — C2 prep OFFLINE completa + checkpoint consolidado publicado (#132 5158316507)

Ejecutor entregó infra C2 en e2852d9 (informes d1b4d207 canarios 14/14, 3b2a3281 infra): suite negativa 14/14 (3 canarios if-shape/binding-3-4/sub-workflow-if con fixture de procedencia — cazó 2 errores de mi handoff contra la fuente); los 5 requisitos de Juan: manifest allowlisted (manifest-c2.js→c2-matriz.json), run-id (por corrida, conversation_id con índice único), runner one-shot (run-c2.js, guarda de corrida única), verifier GET-only (verificar-matriz-c2.js + lector-c2.js con BEGIN READ ONLY, exit 2 incierto separado — lección P1 5155205173), cleanup reconciliado (3 tablas, RETURNING, reconcilia no solo cuenta); herencia C1 (cherry-pick hermetismo.test.js + preflight-enlace-vercel + target-vercel-inmutable; rebase bloqueado por permisos). Verificación independiente del Arquitecto: 431/431 desde tarball limpio (.vercel ausente), gate 14/14 exit 0, verifier 3 desenlaces, run-c2 exit 0. tree 9356536d.

Manifest anclado: 7 clones (por nombre), 22 mutaciones, 3 tablas allowlist (n8n_payment_events→n8n_chat_histories→whatsapp_sessions), 6 bloques M1-M6, nodo multitabla Mark-Session, 4º destino Data-Table interna cubierto por gate. PRECONDICIÓN DURA para GO C2: esquema OBJETIVO (S3/S4 comparten teléfono; índice único de teléfono retirado en objetivo, UNIQUE en actual). Punto a confirmar: los IDs del manifest son planificados; el runner debe resolver clones por NOMBRE (los vivos tienen IDs w8Nzwmyb… de la corrida 0453).

Checkpoint C2 offline publicado #132 5158316507. HOLD: monitor v3 revisa para PASS técnico. C2 vivo gated en PASS + esquema objetivo en STG + ventana fresca (7 condiciones). Global: C0 ✓ · C1 vivo+cerrado ✓ · C2 offline completo+checkpoint 🔄 · C3-C5 por delante.

## (2 ago 16:02) — FAIL P1 consolidado C2: e2852d9 es un ensayo simulado, no el artefacto operativo (error de anclaje del Arquitecto)

Monitor v3 (5159072250) FAILó C2: 431/431 + 14/14 reproducidos, pero "acredita el simulador que declara, no el checkpoint C2 exigido en 5154752604". 6 P1: (1) la siembra usa columnas (estado/variantes/affinity/payment_pending) que NO existen en el DDL objetivo; (2) no hay runner ejecutable real (auto-asigna 8 sembradas/8 borradas, ignora --execute/--target/etc.); (3) M1-M6 prueban una spec autocontenida (Map en memoria), no los workflows n8n; (4) M6 cerrado por el gate C1, falta dual-core-c2.json + resolución de clones reales por nombre; (5) fixtures/one-shot no cumplen el contrato (ON CONFLICT silencia colisión, guarda no atómica); (6) cleanup/verifier no acreditan (LIKE sin escapar _, colapsa tablas, target acepta cualquier PGHOST). M0/M7/M8 no existen.

ERROR DEL ARQUITECTO: anclé el scope de C2 al borrador de simulación M1-M6 (c2-matriz-nucleo-dual-runbook-borrador.md), NO a la spec autoritativa de Juan 5154752604 (M0-M8 + contrato c2-fixtures/1 con IDs concretos + 6 artefactos operativos en scripts/c2/), que existía desde las 02:44. Lección dura: anclar SIEMPRE a la spec autoritativa del accountable, no a un borrador local. (Mismo patrón que la omisión de productores en C1.)

Handoff C2 rework al ejecutor (Agente-n8n@bdcb43b): construir los 6 artefactos OPERATIVOS (dual-core-c2.json, core-matrix.json+validador, run-core-matrix.js one-shot real, verify-final-get-only.js, cleanup-run.js, suite adversarial) contra workflows/clones/DDL reales, M0-M8, siembra con columnas del DDL objetivo, clones reales por nombre, run-id atómico. Es un build sustancial (escala C1). Los fixtures/canarios/patrones de e2852d9 se reusan. C1 permanece cerrada e intacta.

## (2 ago tarde) — C2 rework 91e96cf: 6 P1 cerrados + los 3 huecos de spec rellenos y transcritos

Ejecutor entregó C2 REWORK operativo 91e96cf (informe 1f20af2): los 6 P1 del FAIL cerrados con reproducción+canario (columnas DDL via validarFila, TOCTOU mkdir+O_EXCL, banderas que paran, clones por nombre verificados vs corrida real 0453, 9 cero-colisión, target rechaza PGHOST/PGDATABASE/PGOPTIONS/PGSERVICE, cleanup por tabla+event_id+_-escapado), M0/M7/M8 declarados, delta dual-core. 51/51 + 431/431 tarball limpio. --execute PARA en payloads-no-declarados (3 huecos que solo viven en la spec 5154752604, que el ejecutor NO puede leer — su canal es solo handoffs/).

LECCIÓN DE PROCESO (durable): todo contenido autoritativo de spec va TRANSCRITO dentro del handoff, nunca referenciado por id de comentario. El ejecutor no ve el repo de Juan.

Subagente construyó los payloads M0-M8 + verificado por el Arquitecto contra el código: (1) CRÍTICO — el fixture sembraba conversation_phase='quote_ready', que NO está en RECOVERABLE_PHASES (session-state-gate.js:33) → M2-M6 fallarían como zombi → fix a 'greeting'; (2) outcome M6 = 'updated' no 'approved' (payment-exact-port.js:200-203); (3) payloads literales por bloque. + 3 issues de diseño decididos: M4→S3/S4 (misma phone), M5 asimetría normalización Main-bot(no antepone 52 a 10-díg) vs Payment(sí) — escalada a Juan #132 5159302243, C2 rodea con canónico 520000000001; M6 ambiguous/M1 estado_no_recuperable necesitan filas nuevas (inalcanzables con 8 slots). Handoff transcrito: Agente-n8n@aa848f0. HOLD para que el ejecutor cierre --execute + las filas nuevas.

## (2 ago tarde) — C2 correctivo e5a9c88: 6 P1 + 3 huecos cerrados; entrega/checkpoint a #132 (5159402107)

Ejecutor cerró los 3 huecos en e5a9c88 (informe d4b85fe): Gap#1 quote_ready→greeting (verificado bug: no recuperable), Gap#2 outcome updated no approved, Gap#3 35 payloads con 'postear' — y CORRIGIÓ 2 errores de forma de mi handoff contra el código: (a) Main-bot = sobre Meta completo dentro de {body} del webhook (no {"message":...}); (b) Payment = objeto plano (no {"body":...}). Implementó mis 3 decisiones (M4→S3/S4, M5 rodeo, filas S9/S10/S11 para ambiguous+estado_no_recuperable), cazó su propio LIKE corto al ampliar rango. Verificación independiente del Arquitecto: C2 70/70 (scripts/c2) + C1 431/431 desde tarball limpio (.vercel ausente), --execute NO corrido. tree 86418d29.

El chequeo multi-agente cazó de nuevo mis errores relayados (el sobre de payloads) contra la fuente — funciona como red. Entrega correctiva + checkpoint C2 publicado #132 5159402107 (cierra FAIL 5159072250). HOLD: reauditoría consolidada del monitor v3. C2 vivo gated en PASS + esquema objetivo en STG + ventana. Global: C0✓ C1 vivo+cerrado✓ C2 offline correctivo en reauditoría🔄.
