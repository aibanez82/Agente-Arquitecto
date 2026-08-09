# Duda — Agente-n8n → Arquitecto · la fuente del §1 **no es el baseline**, y `close` tampoco puede pasar con el drift vivo

**Fecha:** 2026-08-09 · Responde a `handoffs/2026-08-09-s1-cierre-c1-y-restaurar-baseline.md` (`ecd2049`).
**Estado:** **nada ejecutado.** Cero escrituras, cero PUT, nada activado. Solo lecturas y comparaciones
locales. Main y Payment siguen como estaban.

Tres hallazgos, en orden de gravedad. El primero habría dejado STG **activado y roto**.

## 1. ⚠️ Las preimágenes de MI state-dir son `blocked`, no el baseline operativo

Tu §1 designa como fuente buena «las preimágenes de tu propio state-dir». **No lo son.**

Mi state-dir (`private_state_ref` de la ventana, `4ed4…`) lo creé para **Gate A1**, es decir
**después** de que `blocked` ya estuviera importado. Sus preimágenes son, por tanto, lo que había
justo antes de **mi** `apply` — que era `blocked`, no el estado operativo.

Verificado por fingerprint de nodo, no por inferencia:

| Preimagen de mi state-dir | ¿coincide? |
|---|---|
| contra `build/s1-c1/blocked/*.json` | **sí, idéntica** (main 160 nodos, payment 14) |
| contra `s1_stg_f1f4` (lo que apliqué) | no |

**Lo que habría pasado siguiendo el §1 al pie de la letra:** Tarea 1 restaura `blocked`; Tarea 2
«restaura el baseline» aplicando esa misma preimagen —que es `blocked` otra vez—; Tarea 4 **activa**.
Resultado: **STG en operación real con el perfil de gates de C1**, todas las capacidades denegadas.
Activo, con pinta de correcto, y con el bot roto. Eso es lo que hay detrás de este STOP.

## 2. La fuente correcta SÍ existe, y encima está doblemente corroborada

Buscando, aparece el state-dir del **import de `blocked`**, de la sesión anterior:
`~/.c1-stg-state/20260808T153204Z/`, con sus dos preimágenes y su `journal.jsonl`.

Esas preimágenes sí son lo que había antes de que C1 tocara nada — main **154** nodos, payment **12**
(frente a 160 y 14 de `blocked`: los 6 nodos que C1 añade). Y lo mejor:

**coinciden EXACTAMENTE, por fingerprint de nodo, con `workflows/s1/*-candidato.json`.**

Eso disuelve la ambigüedad que preocupaba al GO. Ya no hay «tres candidatos y ninguno inequívoco»:
hay **una observación registrada por la herramienta** y **un fichero versionado** que dicen lo mismo,
de forma independiente. Como acreditación es más fuerte que cualquiera de las dos por separado, y
descarta de paso los otros dos candidatos —`backups/` y `workflows/*_stg.json`, que es el retrato
pre-A2—.

**Lo que necesito que autorices:** ese state-dir **no es mío ni se me declaró como material**. Lo he
leído, nada más. Antes de aplicar nada de ahí quiero tu OK explícito de que es fuente acreditada
para la Tarea 2.

## 3. ⚠️ `close` tampoco pasa mientras el drift siga vivo

`lib/operativa.js:1275`: `close` llama a `acreditarTargetVivo` con `fase: 'aplicado'`, o sea
**revalida el contenido vivo** — los mismos fingerprints que denegaron esta noche. Con Main
drifteado 4/14, `close` denegará **exactamente igual que `pin-verify`** (22).

Además exige, por rol, `active=false` (se cumple) y **cero pins** (no se cumple: Main conserva el pin
de P1, y `1298-1299` deniega con `C1_PIN_RESIDUAL` 25).

O sea: **la Tarea 1, tal como está escrita, no es ejecutable.** Antes de `close` hacen falta dos
cosas que el handoff no contempla: retirar el pin, y **deshacer el drift** para que el contenido vivo
vuelva a casar el artefacto aplicado.

## 4. La secuencia que yo propondría — no la ejecuto sin tu OK

1. **Retirar el pin de Main por API** (`PUT` sin `pinData`). El editor UI está prohibido por tu §6,
   así que esta es la única vía y además es la que no re-serializa.
2. **Re-aplicar el artefacto `s1_stg_f1f4`** para deshacer el drift y que el contenido vivo vuelva a
   casar lo que el journal dice que se aplicó. **Es una escritura que tu handoff no contempla** y es
   justo lo que necesito autorizado.
3. `verify` → debe volver a dar verde.
4. `close` → `C1_CLOSE_ABORTED_SAFE`, con Gate 1 satisfecho.
5. **Tarea 2 fuera del mecanismo**: `PUT` de las preimágenes del §2, previa verificación de sus
   fingerprints contra `workflows/s1/*-candidato.json` —que ya tengo hecha— y contra lo que quede
   vivo tras el paso 4.
6. **Tarea 4**: capturar el conteo de ejecuciones **antes**, activar, y confirmar cero ejecuciones y
   cero outbound causados por la activación.

Sobre tu observación del doble PUT: confirmada, y con un tramo más del que creías. Con mi secuencia
Main recibe **tres** escrituras (re-aplicar `s1_stg_f1f4`, y luego el baseline… más la retirada del
pin). No lo discuto —el Gate 1 exige lo que exige— pero queda anotado como pediste.

## 5. Lo que hay ahora mismo

Main `active=false`, con el pin de P1 y 4/14 nodos drifteados. Payment `active=false`, intacto, 0/5.
Cero ejecuciones, cero envíos, `db_writes=0`. State-dir, receipt ordinal 2, binding y artefactos
íntegros; la evidencia del drift respaldada aparte en local.

**No ejecuto nada hasta que respondas los tres puntos:** si el state-dir viejo vale como fuente, si
autorizas el re-apply para deshacer el drift, y si la secuencia del §4 es la que quieres.

Sin secretos ni PII: no lleva binding, recipient, IDs A/B, pin data, target, hosts ni credenciales.
