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

**Remediación pendiente (requiere Alberto, comandos abajo en sesión):** restaurar el remoto a `b76a546` con force-push, mover el handoff a `main`. En el Dashboard el clon también estaba en la rama candidata pero el handoff quedó **solo untracked** — sin daño; basta `checkout main` antes de commitear. Recomendación: declarar la excursión `e6ee2e9` (docs-only, revertida) en el cuerpo del PR n8n, en vez de un comentario aparte en #140.

## Decisión pendiente de Alberto (corte mensual HOY)

Opciones dejadas en sesión:
1. **(Recomendada)** Publicar el handoff sanitizado en #140 (neutraliza el 404), ventana corta de objeción, ejecutar `listrecs`, publicar evidencia sanitizada en el formato que pidió el monitor (inicio/fin, target, nº requests, agregado, cero-escritura).
2. Esperar OK explícito de Juan (coste: reporte Hylant se retrasa).
3. Plan B sin `listrecs`: reporte desde `conciliacion_pagos` — requiere diagnosticar y relanzar el cron fallido de hoy.

Transversal: decidir si dar a Juan acceso de lectura a `Agente-Conciliacion` (el 404 se repetirá con cada handoff).
