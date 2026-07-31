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

## Hechos verificados por el Arquitecto (no observados por el monitor de Juan)

- `stg` **auto-despliega** en Heroku `hyl-wai-stg` vía integración GitHub: v211 (`2d99230`, 21:12) y v212 (`4f0e741`, 21:19, release command en ejecución al verificar). El monitor afirmó "sin paso de deploy observado" porque solo mira GitHub Actions — **el deploy ocurre por fuera de Actions**. Ambos merges SÍ tocaron el entorno STG vivo durante el freeze.
- El barrido `listrecs` **no ha arrancado**: en `Agente-Conciliacion` solo consta el cron diario (14:20 UTC, **falló**; también falló el del 29). `conciliacion_pagos` tiene datos del 30 jul.

## Evaluación

- **Riesgo técnico para nosotros: bajo.** #141/#142 son runbook + comandos de preflight offline; sin cambios de flags (últimos config vars: v210, 30 jul). Nada toca PROD ni nuestras superficies.
- **Narrativo: posición reforzada.** Juan ejecutó dos merges y dos deploys a STG durante el freeze, tras un "No autoriza merge" propio y un aviso de su monitor — mientras ese mismo monitor veta nuestro barrido de solo lectura. Si Juan se auto-clasifica como accountable del workstream, usa el mismo mecanismo que reclamamos para pagos/pricing. Precedente directamente citable para la delimitación de superficie (`5146329245`).

## Decisión pendiente de Alberto (corte mensual HOY)

Opciones dejadas en sesión:
1. **(Recomendada)** Publicar el handoff sanitizado en #140 (neutraliza el 404), ventana corta de objeción, ejecutar `listrecs`, publicar evidencia sanitizada en el formato que pidió el monitor (inicio/fin, target, nº requests, agregado, cero-escritura).
2. Esperar OK explícito de Juan (coste: reporte Hylant se retrasa).
3. Plan B sin `listrecs`: reporte desde `conciliacion_pagos` — requiere diagnosticar y relanzar el cron fallido de hoy.

Transversal: decidir si dar a Juan acceso de lectura a `Agente-Conciliacion` (el 404 se repetirá con cada handoff).
