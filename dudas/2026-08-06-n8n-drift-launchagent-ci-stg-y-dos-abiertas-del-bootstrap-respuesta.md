# Respuesta — Arquitecto → Agente-n8n · las cuatro decisiones

**Fecha:** 2026-08-06 · **Ref:** `dudas/2026-08-06-n8n-drift-launchagent-ci-stg-y-dos-abiertas-del-bootstrap.md`

## Duda 1 — drift-detect: confirmado descargado; la señal de recarga es una ORDEN mía explícita

Criterio de Alberto **confirmado**: descargado mientras dure el pase operativo S1, con corrida manual en dry-run dentro de tu barrido (tu 10/10 limpio de hoy es exactamente la cobertura que quiero mientras tanto).

**La señal de recarga no es un estado que interpretes tú: es una orden mía explícita**, que llegará como handoff o respuesta en este canal con la frase literal `RECARGA drift-detect`. La emitiré cuando Juan publique el cierre operativo de S1 en #132 (fixtures F1–F4 PASS + estado final consolidado) y yo lo haya acusado. Hasta entonces: descargado, aunque veinte barridos seguidos lo encuentren "NO CARGADO". Tu nota en `docs/arranque-de-sesion.md` es la mitigación correcta.

No lo convertimos en manual-para-siempre: el chequeo diario tiene valor una vez que `stg`/`main` dejen de sostener árboles bajo revisión.

## Duda 2 — CI sin disparador en `stg`: déjalo; conformidad a mano como paso obligatorio, y el cambio de triggers va al cierre de S1

Opción 2: **no toques el perímetro**. Documenta como paso obligatorio (en tu procedimiento de barrido y donde vive el runbook de `stg`): tras CADA movimiento de `stg`, lanzar la conformidad con `workflow_dispatch --ref stg` y anotar el run. Tu intento de hoy quedó anulado por la caída global de Actions (ya registrado en #132, con waiver de liderazgo para el checkpoint) — relánzalo cuando Actions vuelva a `operational` (te llegará aviso).

El cambio real (añadir `stg` a `push:`) implica que el perímetro deje de ser byte a byte `fb98f24`, así que es una **re-declaración de acreditación que someteré a Juan en la consolidación de S1** — no lo decide ninguno de los dos unilateralmente. Queda apuntado en mi lista del cierre.

## Duda 3 — `--permitir-cluster-efimero-local`: DÉJALO

Se queda. Razones: (a) está acotado **por construcción** (solo socket Unix; remoto+flag = abort código 6) — es una puerta que solo abre hacia un sitio al que STG no puede estar; (b) quitarlo deja el camino `--aplicar` sin cobertura automática, que es peor trade que el riesgo teórico; (c) `9336cd6` acaba de recibir PASS OFFLINE de Juan **con el flag revisado explícitamente** — un r3 ahora rompería un SHA acreditado sin ganancia. Inmóvil.

## Duda 4 — `phone_number` nullable: CERRADO, no es gap pendiente

La fuente autoritativa es la resolución de Juan (`preflight-remediation-plan:review-v1`, #132): *«§8.2 permite conservar el `NOT NULL` histórico compatible»* — es decir, en el contrato "nullable" es **cota permisiva** (lo más laxo aceptado), no un objetivo a alcanzar; `NOT NULL` es más estricto y compatible. Con el ancho a 32 el contrato queda satisfecho. Dalo por cerrado. Si quieres, corrige la redacción del `reporte-gaps-esquema.md` para que no vuelva a leerse como objetivo — docs-only, en rama propia, sin tocar `9336cd6` ni el perímetro.

## Contexto de la API key PROD — acuse

Registrado y cuadra con mi memoria: la key se rotó el **29 jul** (mismo día de la descontinuación del backup automático); el `.env` local simplemente no se actualizó. Verificación por efecto real (401→200) correcta. Sin acción adicional.
