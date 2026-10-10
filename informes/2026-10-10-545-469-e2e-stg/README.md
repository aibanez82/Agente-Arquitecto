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

---

## Adenda — 10 oct, 14:01–14:10 CDMX: B y C contra **bot `7f04b5c9` + guard `89019409`** (tu adenda 2, `f1882a6`)

Antes de lanzar comprobé tu medición del cambio comparando los JSON de las dos versiones del bot:
- no hay nodos añadidos ni quitados, y las conexiones son idénticas;
- solo cambian `Anthropic Chat Model`, `Anthropic Chat Model2`, `Discount Classifier Model` y `Outbound Leak Guard`;
- `Check Typed VIN`, `Detect Typed VIN`, `Inject Serie Note`, `Save Group2 Progress`, `Detect API Failure` y
  `Get Quotation Data` son idénticos.

Así que tu conclusión se sostiene: el B3 empareja con el A3. La versión fue la misma al principio y al final en las tres
corridas.

### Corrida B — `#545`: **póliza `7620104155` emitida en el QA de Quálitas** (`20261010-1401-545B`)

| Aceptación | Ejecución · nodo | Resultado |
|---|---|---|
| **#469 B3 · control positivo** | **87034** · `Check Typed VIN` | VIN `5TDDZRFH1LS054501`. Los tres checks dan `ok` (`checkDigit`, `yearCheck`, `wmiCheck`), `noteReason` es `null` y el `chatInput` **no** lleva `[SERIE_SOSPECHOSA]`. El bot siguió al domicilio. **Con esto el par bueno/roto queda completo: nota en la A3 y ninguna en la B3** |
| **#545 · base** | guard **87042** · `Calcular Base RFC` | `_rfc_545 = {calculada: "PALJ880315", modelo: "PALJ880315", aplicada: true, desacuerdo: false}` |
| **#545 · cuerpo** | guard **87042** · entrada de `Call Issue Policy Real` | `rfc = "PALJ880315"`, `homoclave = ""` |
| **#545 · póliza** | guard **87042** · respuesta de Django y `qualitas_polizaemitida` | **`7620104155`** en las dos. Quálitas aceptó a la primera, sin reintento |
| Turnos previos | 87030 · 87032 · 87035/87036 · 87038 | Selección guardada, grupos 1, 2 y 3 (Fresno 150, colonia ofrecida en un segundo turno) y resumen desde el registro (guard 87039/87040, en `modo` `resumen`) |

**Frase de detector perdida (lo pedías citado):** la respuesta de la emisión ya **no dice «emitida exitosamente»**. Dice,
literal, «¡Listo, Juan! 🎉 Tu póliza fue emitida.». Las otras dos sí aparecen: «Continuamos con» (87030) y «\*Domicilio:\*»
(87038). Mi runner marcó la póliza como PASS porque el número existe, pero **cualquier detector que busque «emitida
exitosamente» no verá esta emisión**. Es el primer turno de emisión que mido con Sonnet 5.5.

**El monto, otra vez:** la póliza sale por **$11,775.69** y lo cotizado era **$10,858.25**. Es exactamente lo mismo que
en mi `#536` del 5 oct (`1c9f7db`), y sobre el mismo origen clonado, la 2683. Ahora el bot lo explica al cliente, literal:
«Ojo: este monto es distinto de los $10,858.25 MXN que te mostré en el resumen. El sistema emitió la póliza con
$11,775.69 MXN y no tengo el motivo de la diferencia. Revisa el monto antes de pagar.». Que la cifra se repita al
centavo apunta a que Quálitas recalcula el precio de la cotización vieja de la 2683, no a algo aleatorio. Sigue sin
estar medido con una cotización recién hecha.

**Limpieza:** WARN. Queda el mismo residuo que en el `#536`: `qualitas_leadfunnelevent` 803–806, que es append-only y
retiene el lead 1652, su asegurado y la cotización 3005. La póliza `7620104155` sigue viva en el QA de Quálitas y no se
puede borrar desde aquí.

### Corrida C — `#245` (`20261010-1408-545C1`, `20261010-1409-545C2`)

| Caso | Ejecución | `Get Quotation Data` | `isApiError` | Texto enviado |
|---|---|---|---|---|
| **C1, con PDF** (cot. 3006, con `pdf_cotizacion_url`) | **87047** | sin error | `false` | «Ya tengo tu cotización para tu \*TOYOTA HIGHLANDER 2020\*: Cobertura Amplia, pago anual de \*$10,858.25 MXN\*. ¿Te la dejo lista para contratar?» → **PASS**: da la cotización, sin avería y sin URL |
| **C2, sin PDF** (cot. 3007, `pdf_cotizacion_url = ''`) | **87050** | sin error | `false` | **El mismo texto, carácter a carácter** → **FAIL según el criterio escrito**: da los datos y no fabrica ninguna URL, pero **no dice que el PDF no esté disponible por este medio** |

**Sobre el FAIL del C2, para que decidas tú.** Lo que el `#245` venía a evitar no ocurre en ninguno de los dos casos:
`isApiError` sale `false` en ambos y no hay ni «no pude recuperar» ni «intenta más tarde». El bot trata «¿y mi
cotización?» a secas como una petición de **la cotización**, no del PDF, y responde lo mismo tenga PDF o no. Eso es justo
la desambiguación que describía el propio `#245` («“¿y mi cotización?” sin nombrar el documento NO es pedir el PDF»,
cabecera de mi `runners/documento_cotizacion_stg.js`). Así que el criterio de la adenda para el C2 («dice que el PDF no
está disponible») choca con ese diseño. O el criterio sobra, o el diseño del `#245` cambió. No lo doy por bueno: lo dejo
como **FAIL contra el texto de la aceptación**, con esta nota.

### Lo que no pude comprobar

- **Las líneas que quita `Outbound Leak Guard`: NO COMPROBABLE.** El nodo **no corrió en ningún turno** de B, C1 ni C2
  (no aparece en el `runData`). Cuelga detrás del fence de salida, y en mis sesiones sin dígitos el fence corta antes.
  Es una ceguera del arnés, no una incógnita: medirlo exige un envío real (teléfono real, como en el E2E del VIN de foto).
- **El resultado del modelo con N=1.** Cada aceptación se midió una vez. La frase «emitida exitosamente» puede faltar
  siempre o solo a veces con Sonnet 5.5: con una sola corrida no lo distingo.

Agente: QA & Testing

### Nota — C2 con el criterio corregido (`47d45fc`)

Corregiste el criterio del C2 en el handoff: exigir «PDF no disponible» era un proxy. Ahora el criterio es que **no
fabrique una URL y no anuncie ninguna avería**. Contra ese criterio, la medición de 87050 (sin repetir la corrida)
da **0 URLs**, ninguna frase de avería e `isApiError: false`. **El C2 PASA.** Dejo arriba el FAIL contra el texto
original para que quede el rastro de la corrección.

**Total del handoff:**
- A: 6/6.
- B: 9 PASS + WARN de limpieza (residuo declarado).
- C1 y C2: PASS.
- Pendientes para ti: la frase «emitida exitosamente» que falta con Sonnet 5.5, el monto 11,775.69 frente a 10,858.25,
  y `Outbound Leak Guard`, NO COMPROBABLE.

Agente: QA & Testing
