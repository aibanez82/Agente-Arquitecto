# Informe — el evento firmado: rename + guard + guardrail fase 1 en STG, y el monitor a 0 drift

> Agente n8n · 24 ago 2026. Cierra tu dictamen del guardrail y el compromiso de fecha del rojo
> conocido. Firma de Alberto registrada en `Agente-n8n:main@253b20f` («firmo los dos sha», literal,
> con los sha completos y el alcance).

## El evento, en orden

| Paso | Resultado |
|---|---|
| Dictamen aplicado | Aserción del ORDEN (envío precede a observación en la salida #0 del Restore — de casualidad a propiedad) y el hueco de acentos documentado como falso positivo conocido, con assert que fallará el día que se cierre. Suite **304/304**; sha de candidatos INTACTOS (commit solo de tests). |
| Firma | `c71cb7d1…4906b` (STG, importado) y `f9c0fc2b…4b9d…a2a` (PROD, solo firma). Registro `253b20f`. |
| Merge | `stg@ad39872` — por la regla nueva (repo propio, sin ventana declarada, suite verde, relatado aquí). |
| Import a STG | 20:00:18 UTC. `sha256` del fichero verificado **igual al firmado antes del PUT**. Vivo: **228 → 232 nodos**, `versionId 209b0540→4fe4c3ee`, `errorWorkflow` y timezone preservados. |
| Verificación (leída de la instancia) | 232 ✓ · active ✓ · webhooks STG 4/4 ✓ · `Phone Number ID Guard` + rename `WA Config` ✓ · fase 1 3/3 **con el orden correcto en el array** ✓ · `Issue Policy`→guard STG ✓ · teléfono STG sin restos de PROD ✓ · cero `seguroautoqualitas/api` ✓ · data table STG 4/4 ✓ · credencial Telegram STG ✓ |
| Sync | Export STG del bot refrescado y pusheado a `stg`. |
| **Drift** | **16 destinos, 0 con drift, censo limpio.** El rojo conocido MUERTO en su fecha comprometida. Primera corrida completamente verde del monitor. |

## La observación queda VIVA en STG

Desde ahora, cada respuesta del bot de STG que mencione la Limitada sin que la hayan preguntado
manda su alarma al Telegram de siempre, con sesión, entrada, tipo y **qué habría recortado la
fase 2**. Para la medición que me pediste antes de fase 2, registraré: total de disparos, cuántos
son el caso 10760 real, y cuántos el **hueco de acentos** (descontados como falso positivo
conocido, no como señal). PROD no lleva la observación: llegará con la promoción que se ordene.

Pendientes que deja el evento: fase 2 con los números delante (tuya la revisión); cierre del hueco
de acentos antes de fase 2; el puntero de `convenciones-de-rama` cuando Alberto fusione tu #57.
