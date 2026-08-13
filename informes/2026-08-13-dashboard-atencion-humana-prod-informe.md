# Atención Humana en producción — ejecutado el paso 2

**De:** Agente Dashboard · **Para:** Arquitecto · **13 ago 2026**
**Handoff:** `Dashboard:handoffs/2026-08-13-atencion-humana-a-produccion.md`
**Orden respetada:** ejecuto yo, acreditas tú. Aquí van medidas, no veredictos.

---

## Lo entregado

| | |
|---|---|
| Commit en `main` | **`e6e2256`** |
| Merge | `57ef54a` (`feature/atencion-humana-cliente` → `main`, `--no-ff`) |
| Subida de `next` | `e6e2256`, 14.2.3 → 14.2.35, **mismo despliegue** |
| Despliegue | `https://dashboard-seguroautoqualitas-hzbs8dae7-albers-projects-52295059.vercel.app` |
| Alias productivo | `https://dashboard-seguroautoqualitas.vercel.app` |
| Estado | `● Ready`, 41 s |

La rama era **idéntica a `origin/stg`** (`c58a62f`), así que el merge promovió exactamente los 4 commits
previstos y nada más — lo comprobé por SHA, no por confianza. Los 4 ficheros del handoff, más
`package.json` y `package-lock.json` por la subida de `next`.

## Tu checklist, punto por punto

**Variables antes del despliegue.** ✅ Las dos existen en Production **y** Preview. No he leído ningún
valor: `vercel env ls` da nombres y entornos, nunca contenido.

| Variable | Production | Preview |
|---|---|---|
| `N8N_OPERATOR_WEBHOOK_BASE_URL` | 19 h | 15 d |
| `N8N_OPERATOR_WEBHOOK_SECRET` | 19 h | 15 d |

El orden que exigías se cumple: las de Production se reescribieron hace 19 h, o sea **antes** de este
build. El despliegue viene después de las variables.

**Build y tests verdes con `next@14.2.35`.** ✅ `✓ Compiled successfully`, sin warnings, middleware
compilado (32.2 kB). Suite S1 **107/107** offline. Verificado contra la versión **instalada**
(`require('next/package.json').version` → `14.2.35`), no solo contra el `package.json`.

Los repetí **sobre la punta real de `main`**. El primer pase corrió sobre el árbol de la rama y no quise
acreditar sobre un árbol que no es el que se despliega.

**Desplegado en Production.** ✅ Con una salvedad de método que prefiero declarar: el meta de git viene
vacío en `vercel inspect` (`githubCommitSha: undefined`), así que **no pude acreditar el SHA por esa
vía**. Lo hice por contenido: el chunk de `/login` que sirve producción y el de mi build local de
`e6e2256` tienen el mismo hash, `login-d888d41affbceb32.js`. Y `api/claim` figura como lambda compilada
en el despliegue, que es lo que prueba que el `import` nuevo de `n8nOperatorWebhook.js` resolvió en build.

**«Tomar conversación» sigue funcionando.** ⚠️ **Acreditado en estático, NO en runtime.** Lo explico
abajo porque es lo único que te debo y no te doy.

**`enviar` sin cablear** y flujo existente sin refactorizar. ✅ El diff de `claim.js` es aditivo en
comportamiento: sigue devolviendo 201, `ok: true` y `claim`; solo se añaden `bot_avisado` y `aviso`. La
rama del 409 de fencing no se toca.

## Lo que no te puedo acreditar, y por qué

**«Tomar conversación» en runtime no lo he probado.** Sin cookie de sesión el middleware corta con 307 a
`/login`, así que una petición anónima **nunca llega al handler**: no prueba nada del código nuevo. La
única prueba real exige un POST autenticado que **cree un claim de verdad sobre un lead real**, y eso es
una mutación de producción que tu paso 4 asigna a Alberto. No la he hecho por mi cuenta.

Lo que sí tengo, y acota el riesgo:

- `api/claim` compila y se despliega como lambda → el grafo de imports resuelve.
- Revisé el modo de fallo que más me preocupaba: que `tomar()` lanzara y el `catch` convirtiera un claim
  ya creado en un error para el operador. **No puede pasar**: el módulo nunca lanza, devuelve siempre un
  objeto con `clase`, y acota con `AbortSignal.timeout(15000)`.
- `bot_avisado` no lo consume ningún componente, así que la UI no cambia de aspecto.

## Dos cosas que no estaban en el encargo

**1. `next@14.2.35` NO deja `npm audit` limpio.** Conviene saberlo antes de darlo por cerrado: los avisos
que quedan sobre `next` se corrigen en **`>=15.5.21` / 16.x**, fuera de la línea 14.2. **14.2.35 es el
techo de esa línea.** Subir de major es otro trabajo y no cabía en una ventana de producción, así que no
lo he tocado — pero «subido a 14.2.35» no equivale a «sin vulnerabilidades». Lo dejé escrito en el
mensaje del commit para que no se pierda.

**2. El secreto de Preview tiene 15 días; el de Production, 19 horas.** Alberto reescribió los de
Production, no los de Preview. Si la credencial `Atencion Humana Header Auth PROD` se creó después, el
secreto de STG **no coincide** con ella. No lo he comprobado —no debo leer valores— pero encaja
exactamente con la trampa que tú mismo nombraste: **un 401 que parece un problema de red**.

Consecuencia práctica para tu planificación: si alguien intenta verificar en STG antes de producción y
sale un fallo de autenticación, **el sospechoso por defecto debería ser el secreto de Preview, no el
código**. Que la verificación en STG fuera dudosa ya lo dijiste tú; esto añade un motivo concreto y
comprobable.

## Un incidente de proceso, sin culpa de nadie

A mitad de la ejecución, **tu agente y yo escribimos sobre el mismo working copy** de
`Dashboard_SeguroAuto`. Publicaste la actualización del handoff («el paso 1 ya está hecho») haciendo
`checkout` a `docs/handoff-atencion-humana-prod`, commiteando ahí y dejando el repo en
`feature/atencion-humana-cliente`. Entre mi merge y mi commit siguiente, `HEAD` cambió de rama.

**Resultado:** mi commit de `next` cayó en `feature/atencion-humana-cliente` en vez de en `main`.

**Daño: ninguno.** Nada se empujó en ese estado y nada se perdió. Lo detecté al leer la salida de
`git commit` —que dice la rama entre corchetes— y lo reconstruí: `git branch -f` para devolver la rama a
`c58a62f` (idéntica a origin) y `cherry-pick` del commit a `main`. Verifiqué las tres referencias antes
de empujar.

Lo reporto **porque el modo de fallo es silencioso y sobrevive a que los dos hagamos bien nuestro
trabajo**: ninguno de los dos hizo nada incorrecto, simplemente el repo tiene dos escritores y
`git checkout` es global. En una ventana de producción, un commit en la rama equivocada que nadie mire
se convierte en «lo desplegué» sin haberlo desplegado.

Dos remedios posibles, y la decisión es tuya: que tus handoffs se publiquen desde un `git worktree`
aparte, o que sea yo quien trabaje en worktree cuando haya ventana viva. Cualquiera de los dos rompe el
acoplamiento; el primero lo rompe también para el Agente n8n si comparte clon.

## Estado en que dejo las cosas

- `main` = `e6e2256`, empujado y desplegado.
- `feature/atencion-humana-cliente` = `c58a62f`, **idéntica a origin**, sin commits huérfanos.
- `stg` = `c58a62f`, intacta.
- Working tree limpio, repo en `main`.
- Sin tocar: `enviar`, `claim.js` en lo preexistente, `FunnelV2.js`, y la rama de #156 (que ahora mueve
  Juan).

Pendiente de ti el paso 3 (activar el workflow) y de Alberto el 4. Cuando el workflow esté activo y
quieras que yo aporte algo a la prueba end-to-end, dímelo por handoff.
