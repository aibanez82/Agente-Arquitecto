# R3 `C1-N8N-CAPABILITIES@1.0.1` — plan de verificación del Arquitecto

> Escrito **antes** de recibir la entrega, a propósito: un criterio redactado después de ver el
> informe se acomoda a lo que el informe cuenta. Fecha: 7 ago 2026.
>
> Regla que gobierna todo lo de abajo: **nada se da por bueno porque lo diga el informe.** Cada
> línea marcada ⟳ la reproduzco yo sobre el árbol entregado, en worktree limpio.

## 0. Por qué este documento existe

En r2 firmé el `CANDIDATE_READY_R2` afirmando haber verificado el carril real, y liderazgo encontró
después que `--environment prod` **no aborta** si el binding también dice `prod`
(`build-candidate.js:197` compara igualdad, no `stg`). Yo había probado el **cruce** —binding `prod`
contra flag `stg`, que sí deniega— y lo di por cubierto.

El fallo no fue de ejecución: **fue de diseño del control**. Probé la propiedad que esperaba en vez
de la que el contrato prohíbe. Es la misma familia del punto ciego de r3/r4 del Dashboard (stubs con
IDs numéricos cuando `pg` devuelve strings). De ahí la sección 3.

## 1. Gobernanza — primero, y es eliminatorio

| ⟳ | Comprobación | Cómo |
|---|---|---|
| ⟳ | `ac90bc4` sigue siendo **ancestro** del head entregado | `git merge-base --is-ancestor` — si falla, hubo reescritura: **STOP**, no verifico nada más |
| ⟳ | Base `stg@7608f933` conservada | ídem contra el head |
| ⟳ | **`stg` NO se ha movido** | `git rev-parse origin/stg` == `7608f93` |
| ⟳ | PR #4 **OPEN, sin merge**, base `stg` | `gh pr view 4` |
| ⟳ | **Perímetro S1 vacío**: el diff no toca `scripts/s1/` ni `workflows/` | `git diff --stat` contra `fb98f24`/base |
| ⟳ | Árbol inmóvil durante mi verificación | `git status --porcelain` = 0 en worktree detached |

## 2. Identidad del contrato

| ⟳ | Comprobación |
|---|---|
| ⟳ | Los 3 ficheros vendorizados coinciden **byte a byte** con `HYL-WAI@cc712b30` |
| ⟳ | Los 4 fingerprints reproducidos (md `107100f1…`, fixture `9cc116a7…`, schema `75905393…`, combinado `e44cd56c…`) |
| ⟳ | Las líneas `version=1.0.1` de los seis comandos §11.1, **exactas** |
| ⟳ | Cero rastro de `1.0.0` como contrato activo (el `const` del schema debe exigir `@1.0.1`) |

## 3. Controles negativos — la sección que en r2 me faltó

Para cada prohibición, probar **las dos formas de violarla**: la discrepante *y* la coherente. Un
control que solo prueba la discrepante deja pasar la clase entera de fallos "coincidentes pero
prohibidos".

| ⟳ | Prohibición | Negativo discrepante | **Negativo coherente** (el que fallé) |
|---|---|---|---|
| ⟳ | Solo STG | binding `prod` + flag `stg` | **binding `prod` + flag `prod`** → debe denegar igual |
| ⟳ | Roles separados | commitment de otro caso | **binding válido de Payment ejecutado contra Main** (y viceversa) |
| ⟳ | Tuplas completas | campo ausente | **tupla con todos los campos válidos salvo uno, todos coherentes entre sí** |
| ⟳ | Receipt vinculado | receipt ausente/`FAIL` | **receipt válido pero de otro run/binding/target** |
| ⟳ | Ordinales de Gate A | sin receipt | **receipt ordinal 1 usado para `pin-verify`** → debe rechazarlo |

Además, para cada gate que el informe declare "deniega": comprobar que **deniega por la razón
correcta**, no por una razón lateral. Un `deny` con el `error_code` equivocado es un test que pasa
por casualidad — ya nos pasó con C1-N4/N5.

## 4. Lo que el contrato pide y hay que ver funcionando

| ⟳ | Comprobación |
|---|---|
| ⟳ | **Validador estándar de verdad**: contrastar el binding sintético contra un validador independiente (Python `Draft202012Validator`), no solo contra el suyo |
| ⟳ | Un binding conforme **compila**; los inválidos importantes deniegan **sin generar artefactos** (comprobar el directorio de salida vacío, no solo el exit code) |
| ⟳ | **P1–P5 se ejecutan de verdad**: la traza sale de la ejecución. Prueba decisiva: **alterar `visited_nodes` del fixture y comprobar que el test FALLA** — si pasa, sigue siendo teatro |
| ⟳ | `outbound_real=0` observado, no afirmado |
| ⟳ | **Gate A** con fuentes falsas: solo SELECT en `READ ONLY`; identidad DB no coincidente deniega; DataTable GET-only; receipt atómico `0600`, sin symlink, fuera del worktree y **sin** DSN/API key/host/recipient |
| ⟳ | `clienteReal` sin socket ni DNS: **verificar que no abre red**, no fiarme del diseño |
| ⟳ | Rutas privadas: repetir yo los symlinks (fichero preexistente, directorio padre, ancestro) y los modos `0777` |
| ⟳ | Recuperación: matar el proceso de verdad y comprobar que `reconcile`/`rollback`/`close` se comportan; que un `attempted` abierto no queda huérfano |

## 5. R2-08 — lo verifico yo, no me fío del barrido ajeno

Fui yo quien encontró que estaba subdescrito (dos ocurrencias, una de PROD). Así que:

| ⟳ | Comprobación |
|---|---|
| ⟳ | `casos-operativos.test.js:31` y `:101` ya no llevan hosts reales |
| ⟳ | Grep propio del **diff completo** por `hstgr.cloud`, `herokuapp`, `vercel.app`, `srv[0-9]+` e instance IDs — en source, tests, errores, journal y manifests públicos |
| ⟳ | El barrido de redacción es **un test que falla solo**, no un paso de checklist; comprobarlo **introduciendo yo un host** y viendo que se pone rojo |
| ⟳ | **Historia NO reescrita**: `ac90bc4` sigue alcanzable y los commits viejos intactos |

## 6. La dependencia npm que autoricé

| ⟳ | Comprobación |
|---|---|
| ⟳ | `package.json` + **lockfile commiteado**, y **dentro de `scripts/s1-c1/`**, no en la raíz |
| ⟳ | La suite S1 (`scripts/s1/`) sigue corriendo **sin npm**: su `258/258` no depende de `node_modules` |
| ⟳ | El CI solo añade `npm ci` en el job de C1; el resto del workflow intacto |
| ⟳ | El informe **lo declara explícitamente** (dependencia, versión, motivo, y que la propiedad "sin dependencias npm" ya no cubre el job de C1) |
| ⟳ | Revisar el diff que introduce el lockfile por si arrastra algo inesperado |

## 7. Trazabilidad R2-01…R2-08

Los nombres de fichero **ya no son normativos** (enmienda `c.5220188803`). Lo exigible:

- cada R2 está cubierto por una prueba con **buen oráculo** — oráculo independiente del sujeto, no
  el propio fixture;
- el informe trae el **resumen breve** que relaciona cada R2 con la prueba que lo cubre;
- ⟳ yo compruebo que esa relación es cierta: abrir la prueba citada y ver que ejerce lo que dice.

## 8. Qué hago con el resultado

- **Todo verde y reproducido** → publico `ALBERTO_C1_CAPABILITIES_CANDIDATE_READY_R3` en #132 con
  SHA/tree, hashes, diff, matriz y comandos, **diciendo qué reproduje yo y qué tomé del informe**.
- **Algo falla** → no publico entrega. Handoff de corrección al ejecutor con el fallo anclado a
  fichero:línea y su regresión, como en r1/r2.
- **Ambigüedad contractual real** → `BLOCKED` con ejemplo mínimo, nunca por una regresión ordinaria.

En el comentario de entrega, la frontera entre "reproducido por mí" y "declarado por el ejecutor"
va explícita. En r2 esa frontera estaba difusa y por eso mi hueco de `--environment` viajó a #132
como si fuera verificación.

---

## ADENDA tras el dictamen R3 (`c.5221329253`) — cuatro lecciones pagadas

Este plan **no bastó**. Firmé `READY_R3` sobre `c013954` y liderazgo encontró cuatro bloqueantes,
dos de ellos comprobables con una línea de shell. Lo que faltaba, y queda incorporado como
obligatorio para R4 y siguientes:

1. **Verificar la INVOCACIÓN, no la existencia.** Comprobé que `receipt.exigirVigente()` denegaba
   bien con `ordinalMinimo: 2`, y no comprobé que alguien lo llamara. No lo llamaba:
   `grep -c exigirVigente lib/operativa.js` = **0**. Es el mismo patrón que yo bauticé en R2-04
   («parámetros opcionales que degradan a no-comprobar») aplicado un nivel más arriba.
   → Por cada guard nuevo: barrido de llamadas **y** ejecución del comando real sin el artefacto
   exigido, esperando deny observado.
2. **Contrastar `require()` contra el manifiesto de paquetes.** `fuentes-vivas.js:66` requiere `pg`
   y `package.json` solo declara `ajv`/`ajv-formats`. Verifiqué el *scoping* de la dependencia que
   sí estaba y no que estuvieran todas. El carril vivo no lo ejercen los tests, así que la suite
   verde no lo revela.
   → Barrido de `require(` no relativos contra `dependencies`.
3. **Ejecutar lo que el plan dice, no una parte.** «Symlinks en fichero, padre y ancestro» estaba
   escrito en la §4 de este documento. Ejecuté el del fichero (probado ya en r2) y di por buenos los
   otros dos desde el informe. El defecto estaba en el ancestro.
   → Un ítem del plan no ejecutado se marca como **no verificado**, nunca se hereda de una ronda
   anterior ni del informe.
4. **`SIGKILL` real o nada.** Los tests simulaban el journal en el mismo proceso; yo no forcé la
   muerte de un subproceso con journal en disco.
   → La recuperación solo se acredita matando un proceso de verdad.

**Lo que sí funcionó y se conserva:** separar en el comentario de entrega lo reproducido por mí de
lo tomado del informe. Gracias a esa frontera se puede decir con precisión que R3-03 estaba
declarado como no verificado y que el fallo de revisión fueron R3-01, R3-02 y R3-04 — no una
imprecisión difusa sobre todo el conjunto.

---

## ADENDA 2 tras el dictamen R4 (`c.5221844666`) — la tercera variante del mismo error

R4-03 volvió a señalar lo mismo con otra cara. Construí los reproducers de los ancestros symlink
contra `build-candidate.js`, comprobé que `daa4ccb` los deniega —y los deniega—, y **no ejercí la
CLI exacta**. `profile-cli.js` resuelve sus rutas con `exigirPrivado()` → `fs.realpathSync`: solo
comprueba que el destino quede fuera del worktree, o sea que **resuelve** el enlace en vez de
rechazarlo. `exigirAncestrosSinSymlink` aparece 0 veces en ese fichero.

La secuencia completa del error, para que se vea que es uno solo con tres disfraces:

| Ronda | Qué verifiqué | Qué faltaba |
|---|---|---|
| R2 | el cruce `binding prod` + `flag stg` | el caso **coherente** `prod`+`prod` |
| R3 | que `receipt.exigirVigente` **existe** y deniega bien | que alguien lo **llame** |
| R4 | que **el builder** rechaza ancestros symlink | que **la CLI** también |

Siempre lo mismo: **verifico la instancia que tengo a mano y la generalizo.** Regla que pasa a ser
comprobación fija, no propósito:

> **Toda garantía se ejercita en TODOS sus puntos de entrada** —builder, CLI, helpers— y se
> enumeran explícitamente antes de firmar. Si un punto de entrada no se ejerció, va declarado como
> no verificado en el comentario de entrega, igual que se declara lo tomado del informe.

Corolario operativo: antes de firmar, listar los ejecutables/módulos que aceptan la entrada
correspondiente (`grep` de los flags o del parámetro) y marcar uno por uno cuál se probó.

---

## ADENDA 3 tras el dictamen R5 (`c.5222678799`) — variante nueva: identidad del contrato ≠ conformidad

R5-01 no era una guarda floja: **el mecanismo de `1.0.2` no estaba cableado**. El contrato movió la
identidad del target de «headers vivos» a «metadata comprometida contra `C1_STG_TARGET_SHA256`», y
el código conservó el camino de `1.0.1`. Verificado: esa variable **no aparece en `profile-cli.js`**
(sí en el contrato vendorizado, el fixture y `gate-a.js`), y `acreditarIdentidadViva()` seguía
exigiendo `instance_id`/`n8n_version` vivos que `clienteReal` devuelve `null` por diseño → el carril
vivo denegaba siempre.

Yo verifiqué que los tres artefactos coincidían byte a byte con el freeze y que las tres copias del
fingerprint concordaban. Todo cierto. **Y no comprobé que el comportamiento hubiera cambiado.**
Vendorizar es barato precisamente porque no obliga a nada.

La serie completa, que es un solo error con cuatro caras:

| Ronda | Verifiqué | Faltaba |
|---|---|---|
| R2 | el cruce `prod`+`stg` | el caso coherente `prod`+`prod` |
| R3 | que el mecanismo existe | que alguien lo llame |
| R4 | que el builder lo rechaza | que la CLI también |
| **R5** | **que el contrato nuevo está vendorizado** | **que el contrato nuevo está implementado** |

Regla que se añade a las anteriores:

> **Ante un contrato nuevo, listar QUÉ CAMBIÓ respecto del anterior y verificar el comportamiento de
> cada cambio.** La identidad del artefacto (hashes, `const`, vendorizado byte a byte) no acredita
> conformidad. Y las variables o parámetros que el contrato nombra se buscan **en los puntos donde
> el contrato dice que se usan**, no solo en el repositorio.

Corolario que también salió de esta ronda: una comparación puede degradar a no-comprobar igual que
un `if` — `null === null` satisface una igualdad de commitments. Al auditar guardas, mirar también
las **comparaciones cuyo caso ausente es simétrico**.

---

## ADENDA 4 tras el dictamen R6 (`c.5223134798`) — quinta cara: el guard tiene más llamadores que los que probé

`acreditarTargetVivo()` se invoca **solo** desde `preflight` y `apply`; los otros seis subcomandos
—`verify`, `reconcile`, `rollback`, `pin-verify`, `execution-verify`, `close`— hacen requests vivos
sin acreditar. Yo verifiqué que el guard funcionaba (control positivo + siete negativos) y que
`preflight` lo usaba. La matriz de puntos de entrada que sí ejecuté cubría los guards de **ruta**
(cuatro entradas × builder/CLI) — el guard de **target** no tenía su matriz por subcomando.

| Ronda | Verifiqué | Faltaba |
|---|---|---|
| R2 | el cruce | el caso coherente |
| R3 | que el mecanismo existe | que alguien lo llame |
| R4 | que el builder lo rechaza | que la CLI también |
| R5 | que el contrato está vendorizado | que está implementado |
| **R6** | que el guard funciona y un llamador lo usa | **todos los demás llamadores** |

Regla que sustituye a la de R4 (que se quedaba corta):

> **Por cada garantía, enumerar la lista COMPLETA de sus llamadores y ejercitar cada uno.** No basta
> con «los puntos de entrada» entendidos como binarios o interfaces: son *todas las funciones que
> deberían invocarla*. Se obtiene con un `grep` del símbolo y contrastando contra la lista de
> funciones públicas del módulo — si una función pública hace un request y no aparece entre los
> llamadores, eso es el hallazgo.

Y un caso concreto que ni el ejecutor ni yo habíamos probado, para no perderlo: **mutar un nodo del
baseline que NO esté entre los fingerprints acreditados**. Los 19 son un subconjunto; el resto del
workflow quedaba sin cubrir.

---

## ADENDA 5 — dos fallos de HANDOFF (no de verificación), con la misma causa

En R7 y R8 mandé handoffs defectuosos y hubo que corregirlos en caliente:

- **R7**: dije «los ocho subcomandos». Eran **diez**, y dos tenían regla propia.
- **R8**: di como corrección de R7-01 «que acepte baseline **o** `blocked`». El plan revisado decía
  **solo `(blocked,blocked)`, con baseline DENY** — mi versión dejaba el guard *más laxo* de lo que
  el contrato admite. Y **me salté R7-08 entero**.

**Causa común: escribí el handoff desde una lectura PARCIAL del dictamen.** R7-08 estaba en la línea
121 de 152; el paso del plan que contradecía mi arreglo, en la 133. En ambos casos leí las primeras
secciones, me pareció que ya tenía el cuadro y me puse a redactar.

> **Regla: leer el dictamen ENTERO antes de escribir el handoff — incluida la sección de plan.**
> El «Plan de Sugerencia» no es un resumen de los bloqueantes: puede **corregir o endurecer** la
> lectura obvia de un bloqueante, y cuando lo hace, manda el plan. Contar los `### R7-NN` y
> contrastarlos con el número que cita el estado canónico antes de dar el handoff por completo.

Es un fallo distinto del de verificación —allí generalizaba desde una instancia; aquí redacto desde
un fragmento— pero comparte la forma: **actuar con una muestra creyendo que es el todo.**
