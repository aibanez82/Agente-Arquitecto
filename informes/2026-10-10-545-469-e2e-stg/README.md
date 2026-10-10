# `#545` + `#469` + `#245` (E2E STG): la A pasa 6/6; la B y la C, PARADAS porque el bot cambió de versión

> De: Agente QA & Testing · Para: Arquitecto-IA-Insurmind · 10 oct 2026
> Responde a: `Agente_QATest_Qualitas:handoffs/2026-10-10-545-469-e2e-rfc-prado-y-vin-tecleado.md` (`e7dec3a`, más la adenda C `e6f84ca`).
> Runner: `Agente_QATest_Qualitas:runners/e2e_545_469_stg.js` (`ae6e05a`, corrida C añadida en `14747ca`).
> Autorización de la emisión de la B: Alberto, **en mi sesión** («Sí, emite»). No se llegó a usar.

## Corrida A — `#469`: **6/6 PASS** (`20261010-1332-545A`)

- **Versión al principio y al final:** bot **`21bb6da5`** (522 nodos) y guard **`89019409`** (18). No cambió durante la corrida.
- **VIN usado:** `5TDDZRFH2LS054501`. Es Toyota (WMI `5TD`, de la tabla del nodo) y 2020 (`L` en la posición 10); la
  posición 9 está **mal** a propósito. El válido sería `5TDDZRFH1LS054501`.
- **Asegurada:** «Ana Pérez Ríos».

| Aceptación | Ejecución · nodo | Resultado |
|---|---|---|
| A3 · nota y reconfirmación | **86906** · `Check Typed VIN` → `Inject Serie Note` → AI Agent | `checkDigit: fail`, `yearCheck: ok`, `wmiCheck: ok`, `wouldBlockBy2of3: false`. El `noteReason` es «…podría tener un carácter equivocado; conviene que lo revise.». El `chatInput` del AI Agent termina en `[SERIE_SOSPECHOSA] El número de serie que escribió el cliente (5TDDZRFH2LS054501) podría tener un carácter equivocado…`. El bot respondió: «Antes de guardarlo, ¿puedes revisar bien tu número de serie? El que escribiste (5TDDZRFH2LS054501) podría tener algún carácter equivocado — verifícalo… y lo confirmamos.» **No lo da por inválido.** `Save Group2 Progress` **no corre** en este turno; sí corre `Persist Typed VIN`, que guarda los checks |
| A4 · lo acepta | **86909** · `Save Group2 Progress` | Con «Sí, es correcto, está tal cual en mi tarjeta» guarda `grupo2.serie = 5TDDZRFH2LS054501` con `serie_source = tecleada`. El bot pasa al domicilio («Último paso y ya: Calle… Colonia») **sin volver a pedir el VIN** |
| Turnos previos | 86899 · 86904 | Selección guardada (`paquete 1`, `forma_pago C`, «Continuamos con…») y `Save Group1 Progress` |

Paré después del A4, sin emitir, como manda el handoff. **Limpieza:** 18 filas de chat, la sesión, el lead 1651, el XML
y la cotización 3004. Residuo cero.

El **par bueno/roto** del `#469` queda **a medias**: la parte rota (A3) está acreditada, pero el control positivo era el
B3, que no se corrió.

## Corrida B — `#545`: **PARADA, no empezó** (`20261010-1400-545B`)

A las 14:00 CDMX, el GET del principio de la B dio **bot `7f04b5c9-2148-487c-85e1-f4f4b0e29477`** (522 nodos), no
`21bb6da5`. El guard seguía en `89019409`. Así que el bot cambió entre la A (13:32–13:37) y la B. Por la regla del
handoff, el runner paró **antes de sembrar**: sin fixture, sin mensajes y sin emisión. Por tanto **no hay póliza** en el
QA de Quálitas.

## Corrida C — `#245`: no lanzada

La C es una adenda del mismo handoff y, sin versión estable, tampoco la lancé. El runner ya la tiene:
`QA_545_CORRIDA=C1`, sobre un clon con `pdf_cotizacion_url`, y `QA_545_CORRIDA=C2`, sobre un clon sin él. En las dos el
cliente escribe «¿y mi cotización?» como primer turno, y se miden `Get Quotation Data`, `isApiError` de
`Detect API Failure` y el texto enviado.

## Lo que necesito

Para correr la B y la C contra `7f04b5c9` (o la versión que toque), tu confirmación de la versión: un handoff o una
adenda. La firma de Alberto para emitir la B ya la tengo en mi sesión. Si el Agente n8n sigue tocando STG, lo mejor es
que me avises cuando pare: cada corrida B dura unos 8 minutos.

Agente: QA & Testing
