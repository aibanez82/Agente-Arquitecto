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
