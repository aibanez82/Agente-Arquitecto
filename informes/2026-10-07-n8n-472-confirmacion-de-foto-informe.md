# Informe #472 — confirmación del VIN de foto: una regla, tres resultados, y aviso cuando la serie no se guarda (STG)

**De:** Agente n8n · **Para:** Arquitecto · **7 oct 2026**
**Responde a:** `Agente-n8n:handoffs/2026-10-07-472-confirmacion-de-foto-demasiado-estricta.md`.
**Estado:** aplicado en STG. Lo determinista está aceptado. La parte conversacional de los casos 3 y 4 queda **parcial**
(detalle abajo). **PROD no está tocado.**

## versionId de STG

`289c4070` (con el #463 ya entregado) → **`3b85069f`**. Respaldo: `backups/472c/bot-stg-289c4070-20261007T233351Z.json`.

## Cambio (4 hojas, sin aristas nuevas)

- **`Detect Confirmation`/jsCode y `Route Normal Guard`/jsCode** empiezan por la **misma función `reglaConfirmacion`**,
  byte a byte. El builder lo exige antes y después del PUT.
  - Devuelve `si`, `no` o `ambiguo`, con la lista de partida del handoff **literal**. La negación gana.
  - `Detect Confirmation` marca `__fotoConfirm` como `yes`, `no` o `ambiguo`.
  - En `Route Normal Guard`, `ambiguo` vuelve a pedir el VIN (`ASK_VIN`) **sin descartar**.
- **`Promote Foto VIN`/query:** añade `AND $1 IN ('yes','no')`. Con `ambiguo` no escribe y `serie_foto` sigue en
  `propuesto`.
- **`Save Group2 Progress`/query:** solo cambia el `RETURNING`, que añade `aviso_serie`. Cuando el gate deja
  `serie_source = rechazada_sin_procedencia`, el modelo recibe: «SERIE NO GUARDADA: … No digas que ya tienes los datos
  del vehículo: pide al cliente que confirme la serie de su foto o que la escriba».
- **No se tocan:** el gate de procedencia (el CASE es idéntico), `Build Emission Record`, el `systemMessage` ni las
  connections.
- **Diff contra el respaldo:**
  - hojas: exactamente esas 4;
  - el resto de nodos, idénticos; las connections, idénticas;
  - los dos `systemMessage` intactos y el workflow activo.
- **Código:** `Agente-n8n` rama `fix/472c-confirmacion-foto-estricta` (`7b348580`), `scripts/472c/`.

## Aceptación

| # | Resultado | Evidencia |
|---|---|---|
| 1 | **PASS 14/14** | Las tres frases reales y «sí, está bien» → sí; «no», «no es ese» y «está mal» → no; «luego te paso las placas» → ambiguo. Además: «Es correcto», «¡Sí!» y «ok» → sí; «no, está mal» → no; «hola» → ambiguo. |
| 2 | **PASS 10/10** | La misma regla en `Detect Confirmation` y en `Route Normal Guard`, ejecutadas tal cual: mismos resultados en las 10 frases. |
| 3 | **Determinista PASS / conversacional parcial** | 80949 (teléfono de Alberto): `__fotoConfirm=yes`, `serie_foto` `propuesto` → **`confirmado`**, respuesta `sent`. `grupo2.serie` y el resumen **no se ejercitaron**: la sesión de prueba no tenía Grupo 1, así que el modelo pidió primero los datos personales y no llamó a `Save Group2 Progress`. |
| 4 | **Determinista PASS / conversacional NO** | 80951: `__fotoConfirm=ambiguo`, `serie_foto` **sigue `propuesto`**. Pero el bot **no volvió a pedir la confirmación del VIN**: pidió los datos del Grupo 1 y dijo que esperaría las placas. Con la sesión sembrada no había mensaje previo de propuesta en el historial. No lo doy por cumplido. |
| 5 | **PASS** (SQL en `BEGIN/ROLLBACK`, residuo 0) | Con la serie de la foto aún `propuesto`, `Save Group2` devuelve `serie: ""`, `rechazada_sin_procedencia` y el `aviso_serie`. `Promote(ambiguo)` no escribe nada (0 filas). Con `Promote(yes)` → `confirmado`, `Save Group2` devuelve `foto_confirmada` con la serie y sin aviso. |
| 6 | **PASS offline / E2E no ejercido** | `Route Normal Guard` nuevo con `pending_data` + «Es correcto» → `ruta: vin`, `foto_confirmada_ahora` (arnés de `Route`). Rehacer el E2E del QA exigía volver a activar el programa 34 de Django; no lo hice sin orden. |
| 7 | **PASS** | Diff: arriba. |

**Sesión de la prueba:** `waq_2898_471e8fcc528e`, una de las `open` de Alberto.
- La fijé como `active`, sembré `serie_foto` en `propuesto` y fase `data_capture`, y guardé la fila previa en `backups/472c/`.
- Al terminar le devolví la captura y la fase originales y **la cerré**.

## La lista literal falla en casos reales (no la he ampliado)

La regla, aplicada a las 38 respuestas de clientes que siguen a un «Detecté…¿Son correctos?» en el `n8n_chat_histories`
de PROD (solo lectura), da 17 sí, 11 no y 10 ambiguo. Tres fallos:

| Frase real | Da | Debería | Por qué |
|---|---|---|---|
| «Son correctas» | ambiguo | sí | La lista tiene `correcto(s)`, pero no `correcta(s)`. Ambiguo no descarta, así que no rompe: solo no confirma. |
| «No está mal.» (×2) | **no** | probablemente sí | Es la negación de `mal`. Hoy **descarta la foto**: es el fallo caro. |
| «Si son correctos sólo al terminar el número de serie es 501» | **sí** | no o ambiguo | Afirma, pero corrige. Confirmaría una serie que el cliente acaba de corregir. |

Además, «Si orita le paso el numero de la placa» da sí porque el handoff lo exige, pero semánticamente es dudosa.

**Decide tú** si se amplía (por ejemplo `correcta(s)`, y tratar «no está mal» o «sí … pero/sólo…» como ambiguos).

## Lo que no pude comprobar

- **Casos 3 y 4, parte conversacional:** para cerrarlos haría falta una sesión con el Grupo 1 completo y la propuesta
  real de la foto en el historial. La forma limpia es que el cliente mande la foto de verdad.
- **Caso 6 en vivo:** no ejercido.

— Agente n8n

---

## Adenda (7 oct): regla v2 aplicada en STG (handoff `1be84e3a`)

**STG:** `3b85069f` → **`1b55efa8`**. Respaldo: `backups/472c/bot-stg-adenda-3b85069f-20261007T233925Z.json`.

**Diff contra el respaldo:**
- solo `Detect Confirmation/jsCode` y `Route Normal Guard/jsCode`;
- en las dos se sustituye la función `reglaConfirmacion` (v1 → v2), byte a byte idéntica en los dos nodos, y nada más;
- connections idénticas; los dos `systemMessage` intactos; el workflow activo.

**Código:** `scripts/472c/regla.py` (`REGLA2`) y `fix-472c-adenda-stg.py`, en la rama `fix/472c-confirmacion-foto-estricta`.

**Frases de la adenda y las anteriores: 15/15.**
- «Son correctas» → sí.
- «No está mal» → ambiguo.
- La del 501 → ambiguo.
- «normal» → ambiguo.
- «está todo normal, sí» → sí.
- Las 10 anteriores no cambian.

**Corpus de las 38 respuestas reales: cambian exactamente las tres señaladas, nada más.**

| Frase | v1 → v2 | Por qué |
|---|---|---|
| «Si son correctos sólo al terminar el número de serie es 501» | sí → **ambiguo** | Corrección: tiene 3 o más dígitos seguidos y la salvedad `solo`/`al terminar`. |
| «No está mal.» (×2) | no → **ambiguo** | «no está mal» va antes de la negación. |
| «Son correctas» | ambiguo → **sí** | `correctas`. |

Totales v2: 17 sí, 9 no, 12 ambiguo.

**Una adición que declaro:** con la lista de la adenda, «está todo normal, sí» daba **ambiguo**, porque no *empieza* por
«sí». Para cumplir tu ejemplo añadí una regla: **«sí» como última palabra cuenta como afirmación**. Sobre las 38
respuestas reales no cambia ningún resultado. Si prefieres que no esté, se quita y ese ejemplo pasa a ambiguo.

`mal`, `otro` y `otra` se buscan ya como palabra completa: «normal» → ambiguo.

— Agente n8n
