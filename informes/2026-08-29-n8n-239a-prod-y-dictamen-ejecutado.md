# Informe — #239 A en PROD y las dos exigencias del dictamen, ejecutadas

**De:** Agente n8n · **Fecha:** 2026-08-29 ~04:1x UTC
**Responde a:** `handoffs/2026-08-29-dictamen-decisiones-y-arranque-239a-prod.md`

## §4 — #239 A promovido a PROD

`01e5c0fb` (231 nodos) → **`1ed79dac`** (231, active). Aceptación §5 completa: nodos igual, `postgres` estricto **46 → 46**, los cinco nodos en array con cuadre `$8/$7/$5/$7/$5` y huellas idénticas contra la forma probada de STG, `Persist Django Resolution` **intacto en texto** (no fue en este viaje, como exiges — en STG ya está en array desde `4c06511b` esperando atravesar conversación real). Respaldo: `backup/2026-08-28-prod-pre-239-import` (`f259bfd`). Espejos `stg` y `main` sincronizados. Reporte completo con tabla en `HYL-WAI#239`.

Pendiente declarado: el calco del incidente **en PROD** (objeción → `POR_VIN_40` desde el teléfono de Alberto) — no se fuerza; la evidencia verde vigente es la exec `21057` de STG que tú mismo diste por buena.

## §2 — rastro distinguible del check caído: puesto (STG `fedd2868`)

Y con una corrección honesta a mi informe anterior: tal como quedó anoche, un fallo de Postgres en `Discount Normal Guard` **no** seguía por el carril normal — tumbaba el turno con la ejecución en error (`alwaysOutputData` solo cubre el resultado vacío). Ahora: `onError: continueRegularOutput` en la guarda, y `Route Normal Guard` separa tres casos hacia 'normal': sin aplicación (`check_fallido: false`), **check caído (`check_fallido: true` + motivo, contable en las ejecuciones guardadas)**, y los bloqueos de siempre. «No hay aplicación» y «no pude comprobarlo» ya son separables.

## §1 — deuda anotada

Las cuatro entradas nuevas de Postgres, con su motivo y la marca de «primera candidata a mudarse a API», están en `HYL-WAI#238` como pediste (no como excepción suelta).

## Estado de STG al cierre

Bot `dNqtM20ij6ecZYAX` en **`fedd2868`**, 259 nodos, activo. Deploys de la noche: `6dfd7caa` (#232) → `4c06511b` (#243/#244) → `fedd2868` (rastro §2). Scripts en `chore/scripts-noche-232-243-244` (`HEAD` con el del rastro), sin mergear. La pasada de aceptación desde el teléfono de Alberto sigue pendiente (ráfaga → VIN → «ok gracias» → normal); la tabla sucia (62 filas) y la aplicación 236 en `pending_data` siguen preparadas para ella.

## Cola

`#245` y `#239 B`: sin empezar, siguientes en cuanto cierre la aceptación o lo ordenes antes. `#232` a PROD: detenido conforme a tu §5.

— Agente n8n
