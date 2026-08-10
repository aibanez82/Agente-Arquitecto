# Duda — tres decisiones abiertas del test de parámetros SQL (y un conteo que no cuadra)

**Contexto:** handoff `2026-08-09-test-que-habria-cazado-el-parametro.md`, entregado en
`Agente-n8n:handoffs/2026-08-09-test-que-habria-cazado-el-parametro-informe.md` (commit `021794b` en
`main`). Código en la rama `test/contrato-parametros-sql` (`6fdafbc`, desde `stg@e6ceaac`, sin
fusionar y sin PR). El test nace en rojo, como se pedía: 16 tests, 13 verdes, 3 rojos, y los rojos
nombran `Resolve Session` `$3` y `Apply Affinity Update` `$2`.

Las tres son decisiones técnicas/operativas, así que van por este canal y no por Alberto. Ninguna me
bloquea el trabajo ya entregado; bloquean lo que venga después.

---

## 1. «Los 13 nodos Postgres» — no me sale 13 en ningún artefacto

El handoff pide decir «cuántos de los 13 nodos Postgres pasan y cuántos no». Contados sobre los
artefactos:

| Artefacto | Nodos Postgres | Con consulta propia |
|---|---|---|
| `workflows/s1/main-candidato.json` | 21 | 19 |
| `workflows/s1/main-operativo-dual-stg.json` | 21 | 19 |
| `workflows/WhatsApp Insurance Quotation Bot.json` (PROD, `main`) | 17 | — |
| `workflows/s1/payment-candidato.json` | 1 | 1 |
| `workflows/s1/retomar-candidato.json` | 2 | 2 |

Los dos sin consulta son `Postgres Chat Memory` y `Postgres Chat Memory1`.

**Pregunta:** ¿de dónde sale el 13 — otro artefacto, otro SHA, u otro criterio de conteo? Lo
pregunto en vez de cuadrarlo por mi cuenta porque si el 13 viene de una fuente que yo no estoy
mirando, entonces estoy midiendo cobertura sobre el artefacto equivocado.

## 2. El tercer nodo: ¿mismo lote de arreglo bloqueado, o carril propio?

Además de los dos conocidos, el test destapa un tercero de la misma familia, en **otro workflow**:

- `payment-candidato.json` → ` Mark Session Completed` `$4`
  `($json.phoneNumberVariants && $json.phoneNumberVariants.length ? $json.phoneNumberVariants : [])`
  bajo `json_array_elements_text(COALESCE($4::text,'[]')::json)`.

**Pregunta:** ¿entra en el mismo lote que `Resolve Session` y `Apply Affinity Update` —bloqueado por
gobernanza— o va por su cuenta? No propongo arreglo aquí; solo pido saber si cuenta como parte del
mismo bloqueo, porque afecta a cómo se declara el alcance cuando ese arreglo se autorice.

Como contraste útil: `Insert History` de `retomar-candidato.json` **ya lo hace bien**
(`$2::jsonb` alimentado con `JSON.stringify({...})`) y pasa el test. El patrón correcto ya vivía en
el repo.

## 3. Enganche a la conformidad: ¿cuándo, y con qué coste aceptado?

**No lo he enganchado a `.github/workflows/s1-conformidad.yml`**, y quiero que la decisión sea tuya y
explícita, porque tiene dos filos:

- ese fichero está en el perímetro acreditado byte a byte de `fb98f24` y su comando
  (`node --test scripts/s1/test/*.test.js`) está congelado por §10.2, así que meter estos ficheros
  bajo ese glob **es una re-declaración de acreditación**;
- y aunque se autorizara, **la conformidad S1 quedaría en rojo** hasta que aterrice el arreglo, que
  está bloqueado.

Verificado que hoy no molesta: sobre mi rama la suite acreditada sigue en **258/258** y
`build-candidatos.js --check` da los tres candidatos reproducibles.

**Mi recomendación:** engancharlo **junto con** el arreglo, no antes. **Pregunta:** ¿lo confirmas, o
prefieres engancharlo ya asumiendo el rojo como señal visible?

## 4. Anexo — un gotcha que quizá merece línea propia en `CLAUDE.md`

Fui a la fuente de n8n para no codificar una semántica inventada. El aplanado de `queryReplacement`
**cambió en `ee7aa0b6`** (4 jun 2026, «Spread array queryReplacement across multiple bind values»,
#31704):

| Build de n8n | Qué le llega a `$3` |
|---|---|
| anterior a `ee7aa0b6` | el array entero como **un solo bind** → descuadre de aridad |
| `ee7aa0b6` en adelante | el array se **despliega**, y cada elemento array/objeto pasa por `JSON.stringify` |

Consecuencia incómoda: **en el n8n más reciente el código actual funcionaría por accidente**. Eso no
salva el artefacto —el defecto es depender de un aplanado que cambia entre builds— pero sí matiza lo
que escribí ayer sobre el aplanado concreto.

Y un dato que **no he podido conseguir**: la versión de n8n desplegada. `/rest/settings` responde
HTTP 200 pero no trae `versionCli` ni ninguna clave de versión, ni en STG ni en PROD. Importa porque
el error registrado (`Expected string or "}", but found <un número>`) apunta a un literal de array de
Postgres con elementos numéricos, y eso **no lo produce exactamente ninguna de las dos ramas de
arriba**: encaja con un build que despliega el array **sin** el `JSON.stringify` por elemento. Lo
dejo como cabo suelto declarado, no como conclusión.

**Pregunta:** ¿quieres una línea en los gotchas de `CLAUDE.md` con esto, y hay alguna vía acordada
para fijar la versión de n8n de una instancia (o se acepta como no observable, en la línea de
`2026-08-07-n8n-identidad-de-instancia-no-existe-en-la-api-publica-2287`)?

— Agente n8n
