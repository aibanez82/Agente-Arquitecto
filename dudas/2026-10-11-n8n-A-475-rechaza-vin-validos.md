# Duda de diseño · Agente n8n · A · #475: ¿el bot rechaza VIN válidos? ¿Grafo o prompt?

**Orden:** `Agente-n8n:handoffs/2026-10-10-A-noche-486-461-475.md`, punto 3 (orden de Alberto: «si, lánzalo todo»).
**Modo:** solo lectura. Sin import, sin prompt, sin PROD salvo lecturas (SELECT por `service=agente_n8n_prod` y GET de la API) y sin llamar al modelo.
**Fuente del grafo:** bot de PROD `BtOaZm7WlZT-24V7hqCnF` en **`c31d2687`** (445 nodos). Comparo con STG `5adf0e57`.

## 1. Medición en PROD desde el 1 sep

### Vía 1 — `n8n_chat_histories`
**Ámbito:**
- filas con `created_at` ≥ 2026-09-01 y `inherited = false`;
- primera fila 2026-09-01 00:16 UTC, última 2026-10-09 23:33 UTC;
- **273 sesiones, 976 turnos de cliente**;
- un turno es la fila `human` más todas las filas `ai`/`tool` hasta la siguiente `human`; las filas `Calling …` no cuentan como texto.

**«VIN válido según el grafo»:**
- **tecleado:** el texto del cliente casa con la regex exacta de `Detect Typed VIN` (`(?<![A-Z0-9])[A-HJ-NPR-Z0-9]{17}(?![A-Z0-9])`) y `Check Typed VIN` no inyectó `[SERIE_SOSPECHOSA]`. Ese marcador queda en la fila `human` porque `Inject Serie Note` lo añade al `chatInput`;
- **foto:** fila con `[FOTO_VIN] … número de serie detectado`. `Parse VIN Extraction` solo escribe esa frase si `vinValid`.

**Denominador:**
- **39** turnos con VIN tecleado de 17. 5 llevan `[SERIE_SOSPECHOSA]`, así que **34 son válidos según el grafo**;
- **13** turnos con `[FOTO_VIN]` y serie detectada.

**Patrón de «rechazo de formato»** (sobre el texto de las filas `ai` del turno):
`(número de serie|serie|VIN|NIV)` a menos de 160 caracteres de `no me cuadra | no (parece|luce) (corresponder|correct|válid) | carácter (equivocado|mal) | formato | no es válid | inválid | incorrect | le falta | le sobra | tiene N (caracteres|dígitos) | no alcancé a ver | revis`, o esas frases (más `no (lo )?(veo|vi|encuentro)` y `correcto de tu`) antes de la palabra «serie».

Los primeros patrones, más estrechos (longitud / carácter no permitido / «no es válido» / noveno), daban 47 aciertos, **todos de P1 «17 caracteres»**, y los 47 eran **solicitudes** («Número de serie (NIV/VIN): 17 caracteres, sin las letras I, O ni Q»), no rechazos. Por eso usé el patrón ancho y revisé a mano cada acierto.

**Resultado: 8 turnos con el patrón.** Los clasifico uno a uno abriendo las filas `tool` del turno:

| clase | turnos | detalle |
|---|---|---|
| **rechazo inventado sobre un VIN bueno** | **0** | ninguno de los 34 tecleados válidos ni de las 13 fotos válidas recibe un rechazo |
| pregunta fiel a `[SERIE_SOSPECHOSA]` (el grafo lo dio por sospechoso) | 3 (+1 que el patrón no ve) | `waq_3719…` (h 13028 «no parece corresponder», h 13030 «podría tener algún carácter equivocado», fuera del patrón), `waq_3721…` (h 13093), `waq_4326…` (h 14081, WMI de Honda en una Toyota). **Las cuatro son sesiones de QA** (Juan, `waq_3719/3721`; teléfono de Alberto, `waq_4326`) |
| rechazo correcto de un VIN malo **sin marcador** | 1 | `waq_4339…` (h 14303, 6 oct, cliente real): **16 caracteres**. Ver §2 |
| rechazo tras un error real de una tool | 2 | h 12072: `issue_policy` → `qualitas_business_error` 41 («ya está registrado con una póliza»; no es formato). h 13064: `issue_policy` → `vehicle_serie_review_required`, `reason: check_digit_mismatch` (el Issue Policy Guard) |
| falso positivo del patrón (no había VIN) | 2 | h 14134 («Numero de placas») y h 14146 («Este»): el bot dice «no alcancé a ver», y es verdad |

**Errores de serie en filas `tool` en todo el ámbito:**
- 3 × `qualitas_business_error` 41;
- 1 × `vehicle_serie_review_required` / `check_digit_mismatch`;
- **0 errores de `validate_personal_data` sobre `serie`**, y 0 `invalid_vin_format`.

### Vía 2 — ejecuciones con `runData`
**Ámbito:** las que conserva la API. Son **295 ejecuciones del bot, del 2026-10-05 15:05 al 2026-10-09 23:32 UTC**, todas con `runData`. **Antes del 5 oct no hay nada**: es retención, no ausencia de tráfico.
- `Detect Typed VIN` corrió 193 veces; en **6** había un VIN tecleado.
- `Check Typed VIN` corrió **6** veces y puso nota en 1 (exec 78401, WMI `fail` = la sesión QA de Alberto de arriba). En las otras 5 los tres checks dieron `ok`/`inconclusive`, y el bot siguió adelante en las 5.
- `Parse VIN Extraction` corrió **9** veces:
  - 3 con `vinValid`, sin rechazo después;
  - 2 sin VIN legible;
  - **4 descartados por la aritmética**. Los cuatro descartes eran correctos:
    - exec 83073 fue una lectura errónea de la foto: el VIN tecleado después difiere en un carácter central y pasa el dígito de control en `Check Typed VIN` (exec 82647);
    - los otros tres dan `fail` en los tres checks: un VIN de otra marca para el vehículo cotizado.
- Salidas con el patrón: **4**, y son exactamente turnos de la vía 1: 79616 = h 14303, 79328 = h 14146, 79321 = h 14134, 78401 = h 14081.

**Conclusión de la medición:** en PROD, del 1 sep al 9 oct, **el bot no ha rechazado ni una vez un VIN que el grafo diera por bueno** (0 de 34 tecleados y 0 de 13 fotos). Antes del 26 sep sí había una pieza que podía hacerlo: el bloque «si no cumple… NO la aceptes». El #475 que viajó ese día (`f8ed4444`) la quitó. El 11/20 sigue siendo la línea base adversaria de STG, no un síntoma de PROD.

## 2. Lo que queda sobre formato en el prompt y en las tools (PROD `c31d2687`)

Recuentos sobre el `systemMessage` del `AI Agent` (90.279 caracteres). El del `RAG IA Agent` da 0 en todos.

| literal (patrón) | AI | dónde / qué es |
|---|---|---|
| `17 caracteres` | 6 | las solicitudes, p. ej. off. 42001 y 51287: «Número de serie (NIV/VIN): 17 caracteres, sin las letras I, O ni Q», y la copia de errores (abajo). **Información para el cliente**, conservada a propósito en el #475 |
| `sin (las letras )?I, O ni Q` | 6 | los mismos sitios |
| `9º\|noveno` | 1 | dentro de la prohibición: «NO juzgues qué letras lleva ni si el noveno es un dígito» (off. 50473) |
| `NO cuentes sus caracteres` | 1 | off. 50473 (bloque `**Cuando el cliente escriba un número de serie:**`) |
| `SERIE_SOSPECHOSA` | 2 | off. 49548, y la regla de arriba |
| `invalid_vin_format` | 2 | la regla de arriba, y la copia de errores de `issue_policy` (off. 71149: «debe tener exactamente 17 caracteres, sin espacios ni guiones y sin las letras I, O ni Q…») |
| `SERIE_FORMATO` | 0 | — |
| `rechazada_sin_procedencia` | **0** | el valor lo escribe el grafo (`Save Group2 Progress`), y el prompt no lo nombra |

**Fuera del `systemMessage`, y por tanto fuera de lo que limpió el #475:**
- la **descripción del argumento `serie` en el `inputSchema` de `Validate Personal Data`** (toolCode), que el modelo lee al llamar a la tool, todavía dice: `"Vehicle serial/VIN number: exactly 17 characters, no spaces or dashes, no letters I, O, Q (9th char is a digit or X)"`;
- su mensaje de error dice «(el 9º carácter es un dígito o X)». Ese texto lo emite el grafo cuando su regex `^[A-HJ-NPR-Z0-9]{8}[0-9X][A-HJ-NPR-Z0-9]{8}$` falla, así que es verdad.

Igual en STG `5adf0e57`. Es el mismo «priming del 9º» que el #475 quitó del prompt, y que en la tanda de STG producía «el noveno no es un dígito».

**El caso que la medición sí deja ver: h 14303 (`waq_4339…`, exec 79616)**
- El cliente tecleó **16 caracteres**. `Detect Typed VIN` da `__NONE__`, así que `Check Typed VIN` no corre y **no hay marcador**.
- El modelo llamó a `save_group2_progress` con esa serie. El grafo la **anuló**: la puerta del #472 respondió `serie: ""`, `serie_source: "rechazada_sin_procedencia"` (h 14305), porque no casaba con `serie_tecleada` ni con la foto confirmada.
- El modelo contestó «no me cuadra con el formato esperado — revisa que sean 17 caracteres exactos…», que es correcto. El cliente reenvió 17 válidos y se guardó como `tecleada`.

Lo que se ve ahí:
- **El grafo ya decidió**: la puerta del #472 impide guardar una serie que `Detect Typed VIN` no reconoció, lo que en la práctica es un control de formato. Pero al modelo **no le dice por qué**.
- La regla de off. 50473 le manda lo contrario: «Sigue adelante con el número tal como lo escribió… La comprobación del formato del número de serie no es tuya». Esta vez el modelo juzgó el formato por su cuenta y acertó.
- Es el hueco del #475b, ya medido: la falta de marcador cubre dos estados, «comprobado y bien» y «nunca comprobado».

## 3. Diseño: la recomendación es el grafo

**El dato es exacto.** Longitud e I/O/Q se cuentan; el dígito de control, el año y el WMI ya los calcula el canon v2. Así que decide el grafo, y el modelo solo transmite el motivo.

**Propuesta (no construida):** el marcador **`[SERIE_FORMATO]`**, emitido por el grafo **solo** cuando el mensaje del cliente trae algo con forma de serie que no es un VIN.
- **Qué cuenta:** un token de 14–20 caracteres, quitando espacios y guiones, con letras y dígitos, o uno de 17 que lleve I/O/Q. Y además `Detect Typed VIN` dio `__NONE__`.
- **El motivo, exacto:** «tiene 16 caracteres», «lleva la letra O», «lleva espacios o guiones».
- **Sitio natural:** junto a `Detect Typed VIN`, inyectado por `Inject Serie Note` igual que `[SERIE_SOSPECHOSA]`, después de `Detect Jailbreak` (#479).
- **En el prompt:** basta un caso (c) en el bloque de off. 50473: «si te llega `[SERIE_FORMATO]`, pídele que lo revise con ese motivo». Esa línea es **prompt**, así que necesita la firma de Alberto.

**Criterio #179 — el defecto concreto que habría atrapado:** h 14303 / exec 79616.
- Era una serie de 16 sin marcador; el prompt mandaba seguir adelante, el grafo la anuló sin explicarlo y el modelo juzgó el formato él solo.
- Con el marcador, el motivo («tiene 16 caracteres») lo habría dado el grafo.
- **Lo digo claro:** en ese caso el cliente no sufrió daño (el modelo acertó y la puerta del #472 protegía el dato). Lo que el control quita es la contradicción entre el prompt y el grafo, y el silencio que el #475b dejó abierto. Si la contracción (`HYL-WAI#146`, C9) cuenta esto como instrumentación nueva, lo decides tú.

**Lo que NO recomiendo:**
- **Un guardarraíl de salida** que quite un rechazo de formato cuando el grafo dio el VIN por bueno. No puedo citar ningún defecto en PROD: 0 de 34 + 13. Solo existe el 11/20 adversario de STG, anterior al prompt del #475. Por el #179, no entra.
- **Más texto en el prompt** para que el modelo juzgue mejor. Va contra la regla.

**Higiene opcional, que no es del grafo:** quitar `(9th char is a digit or X)` de la descripción del argumento `serie` en el `inputSchema` de `Validate Personal Data`.
- Es una descripción de tool, no el `systemMessage`, pero el modelo la lee.
- Defecto citable: solo el origen del «noveno» en la línea base de STG. En PROD, 0.
- Tú decides si viaja sola, con el marcador o no viaja.

## Preguntas
1. ¿Construyo `[SERIE_FORMATO]` en STG (grafo + caso (c) en el prompt, con la firma que corresponda), o el #475 se cierra con la medición (0 en PROD) y el hueco se queda anotado?
2. ¿Se quita el `(9th char is a digit or X)` del schema de `Validate Personal Data`, y en qué viaje?
3. ¿La acreditación del #475 sigue siendo la tanda adversaria N ≥ 20 en STG (11/20 antes), con el control de que un VIN *con* marcador siga provocando la pregunta?

**Evidencia (en local, fuera de git, porque contiene VIN y placas reales):**
- volcado de las filas;
- clasificación por turno;
- extracto de las 295 ejecuciones.

En esta duda, los VIN y las placas van enmascarados y los `session_id` truncados.

— Agente n8n · A
