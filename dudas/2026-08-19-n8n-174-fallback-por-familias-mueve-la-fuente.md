# `#174`: separar el fallback mueve la fuente del contrato `@1.1.0`

**19 ago 2026.** Verificado sobre `origin/stg` de `Agente-n8n` (`d918592`) antes de escribir.
Ejecuto `aguayo-co/HYL-WAI#174`, abierto por mí y asignado a Alberto en el tablero.

## Contexto en una línea

«No conozco esta respuesta» se le suelta al cliente también cuando lo que ha fallado es la
emisión o una llamada técnica. En emisión es lo peor: calla sobre el cobro y el cliente se
queda sin saber si le cobraron una póliza que no existe. El arreglo separa el fallback en
familias por **destino del fallo**.

Rama `fix/issue-174-fallback-por-familias`, commit `c6108e9`, ya en `origin/`.
PR [`Agente-n8n#39`](https://github.com/aibanez82/Agente-n8n/pull/39).

## Lo que ya corregí sin preguntar

La primera versión editaba a mano `workflows/s1/main-candidato.json`. Ese fichero **lo genera
`scripts/s1/build-candidatos.js`**: `--check` lo rechazaba y la siguiente construcción habría
borrado el arreglo en silencio. Lo aislé para no confundirlo con estar detrás de `stg` —con
`origin/stg` al día y sólo aquel diff encima, `--check` seguía en rojo— y lo reescribí como
transformación declarada en el builder, con `parche()`. El texto no cambió: los cuatro campos
son byte a byte los de antes y el candidato tiene el mismo sha256.

## La medida del delta, que es lo que tu respuesta del 18 ago pide antes de nada

Candidato antes (`origin/stg`) contra candidato ahora, comparado nodo a nodo:

| | |
|---|---|
| conjunto de nodos | **idéntico**, 256 a 256 |
| `connections` | **idénticas** |
| nodos que cambian | **4**, un campo de texto cada uno |
| sha256 de la fuente | `7961624111dd268f…` → `39cc7c4c024d230c…` |

| familia | nodos | campo |
|---|---|---|
| emisión | `Issue Policy`, `Apply Guardrail Result` | `description`, `jsCode` |
| consulta | `Get Quotation Data`, `Send Generic Error Message` | `toolDescription`, `textBody` |
| desconocimiento real | `RAG IA Agent` | **sin tocar, a propósito** |

`RAG IA Agent` es el único sitio donde la frase genérica es literalmente cierta. Tocarla ahí
sería el mismo error en espejo, y por eso el nodo no aparece en ninguna lista de declaración.

Los cuatro se declaran en `preservacion.test.js` (§6.3.2/§6.3.8). El `#170` ya está reconciliado
en el candidato, o sea que la precondición de tu §3 —reconciliar antes de reponer— está cumplida.

## Duda 1 — esto no es reponer un hash, ¿verdad?

Tu respuesta del 18 ago parte el caso en dos: si el delta **sólo adopta lo que ya estaba vivo y
aprobado**, se repone bajo el contrato vigente con un acta que explique la comparación; si hay
**algo funcional que la revisión no vio**, es contrato nuevo con su plan y su revisión.

Aplicando tu propia regla, **yo leo el segundo caso**: esto no adopta nada que ya estuviera vivo,
introduce texto nuevo de cara al cliente que ninguna revisión ha visto. Pequeño en líneas, pero
funcional. No quiero que la firma valga menos por haberlo colado como reposición.

Lo digo porque a Alberto le anticipé «hay que re-firmar el acta `@1.1.0`», y con tu doctrina
delante creo que me quedé corto. Si me equivoco y esto cabe como reposición, mejor: dilo y lo
hago así.

- **Si es contrato nuevo** → me desbloquea saber si el plan y la revisión los redactas tú o los
  preparo yo para que los firmes.
- **Si cabe como reposición** → me desbloquea saber si el acta la escribo yo con la comparación
  de arriba.

## Duda 2 — toqué la semántica de una aserción de seguridad y quiero tu ojo

Declarar esos cuatro nodos destapó un falso positivo en §5.7: la aserción marcaba
`525634352430` —la línea pública de atención— que **ya estaba en esos nodos antes de tocarlos**.

Lo que persigue §5.7 es que S1 *introduzca* un secreto o un dato personal, así que la reescribí
para comparar contra el nodo vigente y marcar sólo lo que no estuviera ya allí. No es un
debilitamiento y no lo dejé en argumento: inyectando un token y un teléfono **nuevos** en un nodo
declarado, las dos ramas vuelven a rojo. Descarté la lista blanca del número justamente por ser
más débil — taparía un `525634352430` recién embebido en un nodo nuevo.

Aun así es una aserción de seguridad y la he cambiado yo solo. **¿La das por buena, o prefieres
otra forma?** Alternativa que veo: dejar §5.7 como estaba y no declarar los nodos, pero eso pone
§6.3.8 en rojo y el modo de calmarlo sería esconder el cambio, que es peor.

## Duda 3 — los tres pins de aguas abajo

El hash vive en cinco sitios. Dos son documentos tuyos y no los toco:
`docs/authorization-stg-operational-dual-main-v1.1.0.md` y `docs/plan-…-v1.1.0.md`. Los otros
tres son `scripts/s1/test/reproducibilidad-candidatos.test.js` (`SHA_MAIN_AUTORIZADO`),
`scripts/stg-operational-dual/build.js` (premisa `source`) y su `manifest.json`.

**¿Los actualizo yo en cuanto exista la firma, en el mismo PR?** Es lo que asumo, pero no lo doy
por hecho: son la parte ejecutable de tu expediente.

## Estado mientras tanto, y qué NO está bloqueado

La suite queda **293 en verde y 1 en rojo a propósito**: `#176 generar() reproduce el Main
autorizado`. Los dos CI del PR fallan por ese único test. Es el contrato funcionando —el
candidato no puede moverse sin firma— así que el PR se queda ahí parado, que es el sitio correcto.

No me bloqueo entero: el resto de PRs abiertos (`#30`, `#37`, `#38`, `#40`) no dependen de esto y
están limpios contra `origin/stg`, a la espera de que Alberto ordene el merge. Recordatorio de
siempre: mergear a `stg` **no** despliega STG; el import y el E2E real van después.
