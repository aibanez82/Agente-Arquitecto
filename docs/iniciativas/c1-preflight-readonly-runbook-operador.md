# Runbook del operador — `GO_C1_BLOCKED_PREFLIGHT_READ_ONLY`

GO de `@oilycoyote` en `HYL-WAI#132`, comentario `c.5226346080` (8 ago 2026, 13:38Z).
Este documento **no ejecuta nada**: prepara al operador designado y aísla las tres trampas que el
checkpoint publicado no cubre, porque se escribió para el import completo y este GO es más estrecho.

## 1. Lo que el GO autoriza — y lo que NO

Autoriza **un solo comando vivo**: `profile-cli.js preflight`, que solo hace GET.
No autoriza `plan`, `apply`, `verify`, PUT, import, deploy, activación, Gate A, pins, backup vivo,
Dashboard `read_only`, Django `dual`, DML/DDL, envíos, rollback ni nada en PROD.

Autoridad inmutable citada por el GO: checkpoint `ce6fbeb5…`, sha256 `743d276b…`, implementación
`Agente-n8n/stg@10920d7d…`, tree `ff966940…`, contrato `C1-N8N-CAPABILITIES@1.0.2`
fingerprint `852489c7…`.

## 2. ⚠️ Trampa 1 — el bloque §8 del checkpoint termina en `apply`

**§8 del checkpoint es UN solo bloque `bash` contiguo** (líneas 105–152) que encadena
guards → `preflight` → `plan` → `apply` → `verify`. Estaba bien para el GO de import completo.
**Bajo ESTE GO, copiar y pegar ese bloque ejecuta `apply`, que escribe los PUT en n8n STG y está
explícitamente no autorizado.**

El bloque correcto para este GO es el de §8 **truncado tras el paso 1**:

```bash
set -euo pipefail

# ── 0) GUARD DE PROCEDENCIA — fail-closed. Si algo no cuadra, el bloque muere aquí ─────────────
CHECKOUT="${CHECKOUT:?ruta del checkout de Agente-n8n}"
cd "$CHECKOUT"

[ "$(git rev-parse HEAD)" = "10920d7d55c0b49464ccccc6383b1d6537be21fe" ] \
  || { echo "STOP: HEAD no es el acreditado"; exit 1; }
[ "$(git rev-parse HEAD^{tree})" = "ff966940ee79577a5bb28240b21449282b26fd4a" ] \
  || { echo "STOP: tree no es el acreditado"; exit 1; }
GIT_STATUS="$(git status --porcelain=v1 --untracked-files=all)" \
  || { echo "STOP: no se pudo acreditar limpieza"; exit 1; }
[ -z "$GIT_STATUS" ] \
  || { echo "STOP: worktree sucio"; exit 1; }

# macOS/BSD: NO usar `sha256sum`. En Darwin existe un binario homónimo `sha256sum (Darwin) 1.0`
# que devuelve exit 1 INCLUSO CON EL HASH CORRECTO: no puede acreditar nunca y mata el bloque.
# Verificado con control positivo y negativo (ver §2 bis). El único válido aquí es `shasum`:
shasum -a 256 --check <<'SUMS'
d530168045d31bc6c689b3129d0828cded437af49eb4373e05d411467292ea89  build/s1-c1/blocked/main.json
688c4aed6b96a0159a5d99e755748ae76155fff1d0d2ede1eaeba14981d5d8b5  build/s1-c1/blocked/payment.json
2c63db43a290fc1e0a41f4a973cd3ed2295c8356a9c5ca57e5bee2e62c22ed53  build/s1-c1/blocked/manifest.json
ad49eec0b0f02e0fc5d17c10cb9e175bd9772e5067e4e3ac65d79badfab73a43  scripts/s1-c1/manifests/s1-stg-f1f4.redacted.json
SUMS

# 1) preflight — ÚNICO comando vivo autorizado por este GO. Solo GET.
node scripts/s1-c1/profile-cli.js preflight \
  --target-file "$PRIVATE_TARGET" --state-dir "$PRIVATE_STATE"

# AQUÍ TERMINA. `plan`, `apply` y `verify` NO están autorizados por este GO.
```

Antes de fiarse del guard de hashes: alterar un hash a mano y comprobar que el comando **falla**.
Un guard que no se ha visto fallar no es un guard.

## 2 bis. Por qué `sha256sum` no vale en Darwin — con control positivo

Esto ya costó un `BLOCKED` (c.5226381120, diagnosticado en c.5226393460). En Darwin existe un
binario **llamado igual** que el de GNU pero incompatible, y su modo de fallo es el peor posible:
no rechaza el comando, simplemente **nunca acredita**.

| Verificador | hash correcto | hash alterado | fichero ausente |
|---|---|---|---|
| `sha256sum --check` (Darwin 1.0) | **exit 1** ❌ | exit 1 | exit 1 |
| `sha256sum --check --strict` (Darwin 1.0) | usage, **exit 1** ❌ | — | — |
| `shasum -a 256 --check` | **exit 0** ✅ | exit 1 ✅ | exit 1 ✅ |

Solo `shasum -a 256 --check` tiene el control positivo en verde. Los cuatro artefactos, por su
parte, están presentes en `10920d7d…` y sus hashes leídos de los objetos git dan **4/4** contra el
checkpoint: cuando este guard falla en Darwin, **no** es un problema de material.

## 3. ⚠️ Trampa 2 — el compromiso del target NO es `sha256sum` del fichero

`C1_STG_TARGET_SHA256` es el sha256 del **JSON canónico** del target: claves ordenadas
recursivamente y serializado sin espacios **ni salto de línea final**
(`target.js` → `huellaTarget` → `serializarCanonico`). Un fichero con formato bonito, indentado o
con `\n` final da **otro hash** y el guard deniega con `C1_TARGET_DENY` (23).

Comprobado con un target ficticio sobre el SHA acreditado — mismo contenido, dos hashes:

```text
huellaTarget (canónico)      6571f40b3181d8eccf960aac3034c3202f429f31f06ab5c8269f99e62029daab
shasum -a 256 del fichero    079113096f35a833b04f96443128822e59bec4f9ae528ca9c1bf4d7bbe2b7e61
```

La forma correcta de calcularlo es con **el propio código**, que además es insensible al orden de
las claves. Imprime solo el hash, nunca el contenido:

```bash
node -e 'const {huellaTarget}=require("./scripts/s1-c1/lib/target");
console.log(huellaTarget(JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"))))' \
  "$PRIVATE_TARGET"
```

Forma cerrada del target, exactamente cinco claves, ni una más ni una menos:
`origin`, `instance_id`, `n8n_version`, `main_workflow_id`, `payment_workflow_id`.

- `n8n_version` tiene que ser literalmente `"2.28.7"` (constante en el código).
- `origin` tiene que ser el **origin canónico**: HTTPS, sin barra final, sin puerto, sin path,
  sin query, sin fragmento, sin userinfo y no loopback. Una barra final ya deniega.
- `instance_id` y `n8n_version` **no se piden vivos** — la API pública no los expone; son metadata
  comprometida que solo tiene que casar consigo misma a través del compromiso.
- los dos workflow IDs tienen que ser los normativos del fixture congelado.

## 4. Trampa 3 — este GO necesita DOS materiales privados, no cuatro

Verificado en `profile-cli.js`: `C1_STG_READONLY_DATABASE_DSN` y `C1_STG_DATABASE_IDENTITY_SHA256`
solo los exige el subcomando **Gate A** (línea 184), que este GO no autoriza. `preflight` recibe
únicamente `{cliente, target, stateDir, fixture, commitmentEsperado}`.

| Material | ¿Lo necesita este preflight? |
|---|---|
| `C1_STG_TARGET_SHA256` | **Sí** — comprobación explícita; sin él, salida 23 |
| `C1_N8N_API_KEY` | **Sí** — sin ella no se construye cliente vivo (`C1_LIVE_CLIENT_FORBIDDEN`) |
| `C1_STG_READONLY_DATABASE_DSN` | **No** — solo Gate A |
| `C1_STG_DATABASE_IDENTITY_SHA256` | **No** — solo Gate A |

No exponer los dos que no hacen falta. Las cuatro se pasan **siempre por variable de entorno**,
nunca por argumento: un secreto en `argv` acaba en el historial del shell y en `ps`.

## 5. Higiene exigida por el GO

- state-dir **nuevo**, `0700`, **fuera del worktree**, sin symlinks en ningún ancestro;
- stdout y stderr completos a fichero privado `0600`;
- todo comando Heroku, si se usa alguno, debe contener literalmente `--app hyl-wai-stg`;
- confirmar **por lectura** que Django = `shadow` y Dashboard = `blocked`;
- clasificar las preimágenes offline como par completo `baseline` o `blocked`, sin imprimir
  cuerpos, IDs, origin ni paths privados.

**STOP y `BLOCKED`, sin escribir en n8n**, ante cualquiera de: target, compromiso o credencial
ausente · modo distinto · par mixto · `active` distinto de `false` · pins · drift · error de GET ·
o cualquier incertidumbre.

## 6. Salida pública — única cosa que se publica

```text
C1_BLOCKED_PREFLIGHT_PASS|BLOCKED
checkpoint_sha256=743d276bea1d3b0662c3b29dfdb00d86f6b8e24ad19c9bace862a8ed20f5de59
repo_sha=10920d7d55c0b49464ccccc6383b1d6537be21fe
tree=ff966940ee79577a5bb28240b21449282b26fd4a
artifact_hashes=4/4
django=shadow
dashboard=blocked
pair=baseline|blocked|BLOCKED
active_false=2/2
pins=0
preimages=2
n8n_puts=0
outbound_real=0
private_state_ref=<fingerprint opaco, no path>
```

No se publica: API keys, target, binding, origin, workflow IDs, paths privados, cuerpos JSON,
preimágenes ni logs completos.

## 7. La decisión que sigue abierta: quién opera

El GO designa al operador como «owner/operador STG designado por el usuario —**distinto del
productor Alberto**». Ese es el nudo, y conviene decirlo sin adornos: **en nuestro lado hay un solo
humano con credenciales de STG**, que es Alberto, y todo lo que producen los agentes se publica bajo
su identidad. La separación productor/operador que pide el GO no tiene, hoy, un segundo candidato
interno. El Arquitecto está descartado por partida doble: es el productor del checkpoint y no ejecuta.

Opciones reales, para que decida Alberto:

1. **Opera Juan o alguien de aguayo-co.** Preserva la separación tal cual la pide el GO, pero exige
   entregarles credenciales de STG. Juan ya declinó usar credenciales privadas de Alberto sin
   autorización explícita, así que esto requiere que Alberto las autorice y transfiera.
2. **Opera Alberto, declarándolo abiertamente.** Rompe la separación nominal, pero el riesgo real es
   bajo *en este GO concreto*: es solo lectura, `n8n_puts=0` y `outbound_real=0`, no hay camino de
   escritura. La separación productor/operador importa de verdad en el paso que **escribe**, y ese
   paso todavía no está autorizado. Propuesta: declararlo en #132 y conservar la separación para el
   GO de import.
3. **Pedir a Juan que relaje la condición solo para el tramo read-only**, con el argumento de (2).

Recomendación: **(2), declarado explícitamente en el tracker**, y mantener la exigencia de operador
distinto para el GO que escriba. Es la opción que no bloquea el avance y no compra riesgo real,
siempre que se diga en voz alta en vez de dar por cumplida una separación que no se cumple.
