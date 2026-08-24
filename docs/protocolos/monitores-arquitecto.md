# Monitores de sesión del Arquitecto — especificación para rearmarlos

> Los monitores viven solo mientras la sesión está abierta. Al abrir sesión nueva durante trabajo
> activo con Juan (etapas S1–S5), armar los **CINCO** con la herramienta Monitor (`persistent: true`).
> Antes de armarlos: hacer el barrido de arranque (dudas/ pendientes, informes/, `gh issue list`
> en HYL-WAI —tracker único desde el 19 ago— y comentarios nuevos en los issues vivos desde la
> última actividad conocida) — los monitores solo cubren lo NUEVO a partir de su arranque.
>
> **`qualitas-issues` sale del barrido: el 23 ago se midió en 0 abiertos** (`gh issue list --state
> open` → `[]`). La condición que CLAUDE.md ponía —«mientras queden abiertos el barrido mira los
> dos»— se cumplió sola. El repo queda apagado; las referencias `qualitas-issues#NN` de los
> documentos siguen siendo válidas y no se renumeran.
>
> **Son cinco, uno por CANAL, y esa es la regla que los mantiene a raya (Alberto, 16 ago):**
> lo que se pregunta (`m4` dudas) · lo que se entrega (`m5` informes) · lo que se empuja (`m3` git) ·
> lo que Juan escribe (`m2` issues) · lo que Juan despliega (`m6` releases de STG **y PROD**). **Un monitor por
> canal, no por asunto.** Ese día había **diez** vivos y cuatro no aportaban nada: tres vigilaban
> ramas concretas (`fase0`, Fase 4, `feature/issue-156`) que `m3` ya cubre entera al mirar TODAS las
> refs, y el cuarto duplicaba `m4`. Nacieron para un trabajo puntual del 11–13 ago, sobrevivieron a
> un `/clear` —el contexto se limpia, los procesos no— y siguieron corriendo sin dueño. **Un monitor
> nuevo para un asunto concreto es casi siempre señal de que falta una lista en uno existente.**
>
> **Los scripts están versionados en `scripts/monitores/` (m2…m6)** — desde el 16 ago no hay que
> reescribirlos de la prosa en cada sesión. Armar con `Monitor` (`persistent: true`) apuntando a
> `<repo>/scripts/monitores/mN-*.sh`. Cada uno **siembra su estado con lo que ya existe** al
> arrancar, así que no vomita el histórico en el primer latido; por eso el barrido de arranque
> —que sí mira hacia atrás— no es opcional. Los ficheros de estado (`.mN-seen`, `.m3-state`) se
> escriben junto al script: si se ejecutan desde el clon, van al working copy y hay que
> gitignorarlos.

## 0. Antes de armar nada: dos comprobaciones que el 16 ago costaron caras

**A · ¿Hay monitores vivos ya?** Un `/clear` borra el contexto pero **no mata los procesos de
fondo**: la sesión nueva no recuerda haberlos armado y los arma otra vez. Así se llegó a **diez**
vivos el 16 ago, cuatro de ellos residuos del 11–13 ago que nadie podía atribuir. Comprobar SIEMPRE
antes de armar:

```bash
ps -eo pid,ppid,lstart,command | grep -v grep \
  | grep -E "monitores/m[0-9]|scripts/monitor-|heroku releases"
```

**El patrón se amplió el 23 ago porque el viejo mentía.** `monitores/m[0-9]|heroku releases` dio
`ps` limpio —«no hay nada vivo»— y había **siete** procesos de monitor corriendo: los del Dashboard,
que se llaman `scripts/monitor-<canal>.sh` y no encajaban en el patrón. Un patrón de detección
calibrado solo sobre los monitores propios acredita ausencia donde no la hay, que es la peor
respuesta posible para una comprobación cuyo único trabajo es evitar duplicados.

Si ya están corriendo, **no rearmar**: mirar si el script cambió desde que arrancó el proceso
(`ps -o lstart= -p <pid>` contra el `mtime` del fichero) y rearmar solo los desfasados. Los procesos
huérfanos (`ppid=1`) no aparecen en `/bashes` y solo se matan por PID.

**El `ppid` agrupa por sesión; el `cwd` atribuye el repo.** Los procesos de una sesión ajena cuelgan
de otro padre, así que el `ppid` separa «residuo mío que hay que matar» de «monitor vivo del
ejecutor, que no se toca» — el 23 ago los del Dashboard colgaban de `15278` y los míos de `15226`.

**Pero el `ppid` no basta, y el nombre del script engaña.** `monitor-handoffs.sh` y
`monitor-dudas.sh` existen **con el mismo nombre** en el Dashboard y en Agente-n8n. Quien lo
resuelve es el directorio de trabajo del proceso:

```bash
lsof -a -p <pid> -d cwd -Fn | sed -n 's/^n//p'
```

Ese mismo 23 ago fallé en los dos sentidos con solo el nombre: primero dije «no hay monitores vivos»
con siete corriendo, y después di por ajeno un proceso sin comprobar de dónde colgaba. **Sin `cwd`
no hay atribución, solo conjetura.**

**Y `TaskList` no sirve para esto** — el aporte lo hizo el Agente Dashboard y es el mecanismo que
explica los duplicados: **`/clear` no mata los monitores persistentes** —siguen bajo el mismo
proceso— pero **sus ids de tarea se van con el contexto**. Desde dentro de la sesión son invisibles
y `TaskList` responde «No tasks found», que se lee como «no hay ninguno». Por eso la comprobación
buena es la de `ps`, y por eso la sesión nueva los arma otra vez.

**C · macOS trae bash 3.2, y eso descarta media sintaxis moderna.** No hay arrays asociativos:
`declare -A` falla, y `prev[$a]=…` degrada silenciosamente a array **indexado** evaluando el índice
como aritmética, así que todas las claves no numéricas caen en el `0` y **comparten casilla**. La
v2 del `m6` se armó así y su primer ciclo emitió `[release hyl-wai-production] v341 (antes: v239…)`,
comparando PROD contra el valor de STG. **Un monitor que confunde dos entornos es peor que no
tenerlo**: el aviso parece un despliegue de PROD que nunca ocurrió. Para estado por clave, fichero
—que además sobrevive al rearme— y nunca array asociativo. Y probar el script **una vez a mano**
antes de armarlo: `bash -n` valida sintaxis, no semántica, y este fallo pasa `bash -n` sin ruido.

**B · ¿Qué publicó NUESTRO lado hoy?** El barrido miraba lo que escribe Juan y se saltaba lo
nuestro. Tras un `/clear` eso es justo lo que falta: el 16 ago la sesión anterior de esta misma
ventana había publicado **cinco** comentarios en `#161` y abierto dos issues, y la sesión nueva los
leyó como trabajo ajeno. Añadir al barrido: comentarios propios del día en los issues vivos
(`--jq 'select(.user.login=="aibanez82")'`), issues abiertos hoy en el tracker, y
`gh pr list` en nuestros repos.

## 1. ~~Dictámenes de Juan en HYL-WAI#132~~ → FUNDIDO EN EL 2 (16 ago)

**No existe como monitor propio.** El #132 es un issue más de la lista del monitor 2: misma lógica
de dedupe, misma llamada. Un issue más cuesta una llamada por ciclo; un monitor más cuesta un
proceso, y encima uno que nadie recuerda haber armado. Lo que sigue vale igual, aplicado por el 2:

Poll de `gh api "repos/aguayo-co/HYL-WAI/issues/<N>/comments?since=<ahora>"` filtrando
`user.login=="oilycoyote"`; emitir una línea por comentario nuevo (fecha + primeras ~200 chars).
Cubre: dictámenes, freezes, STOPs, resoluciones §12, entregas Django.

**Ojo con el comentario de «Estado canónico del monitor»** (marcador
`seguroauto-monitor:canonical`): el daemon lo **edita en sitio**, así que `since` —que filtra por
`updated_at`— lo devuelve una y otra vez. Dedupe por **hash del contenido**, no por `id+updated_at`;
y **quitando antes los timestamps ISO**, porque su campo «Próxima revisión» se reescribe cada ~30
min sin que cambie nada material y dispara el monitor en vacío (visto el 7 ago).

## 2. Comentarios nuevos en los issues vivos de gobernanza e iniciativa

Poll 120s. **Ya no lleva lista de issues (v3, 23 ago).** Una llamada al endpoint de repo entero
—`/repos/aguayo-co/HYL-WAI/issues/comments?since=…`— cubre TODOS los issues, abiertos y por abrir.

**Por qué murió la lista.** La spec decía «revisar esta lista al armar, no heredarla», y el 23 ago
el barrido enseñó que revisar a mano no funciona: la lista heredada era `132 135 156 161 128 143`,
con **#156 cerrado el 21 ago y #143 el 20 ago** —dos llamadas por ciclo a puertas tapiadas— y sin
**#203, #209 ni #201**, que es exactamente donde Juan escribía ese día (37 legs de relay en #203 en
doce horas). El fallo no fue de nadie: una lista que hay que acordarse de revisar se desactualiza
por construcción. El endpoint de repo no se desactualiza, cuesta 2 llamadas por ciclo en lugar de
6-14, y **un issue que Juan abra mañana nace vigilado**.

**Emite además ISSUES NUEVOS**, los abra quien los abra (`/issues?since=…`, descartando los que
traen `pull_request`). Era un punto ciego con nombre y apellidos: **#203 y #209 los abrió Juan y
ningún monitor avisó** — se vieron en el barrido, un día tarde.

**Colapso por issue para no auto-detenerse.** Más de 3 comentarios nuevos del mismo issue en un
ciclo se emiten como **una** línea `[#NNN · Juan ×N] última: …`. Sin esto, un relay como el de #203
—~40 comentarios al día— dispara el corte por ruido y se pierde el monitor entero, que es peor que
perder el detalle de una leg.

## 3. Ejecutores: pushes en ramas candidatas + commits en main + PRs

Poll cada 60-90s de los remotos de los clones de ejecutores. Desde el 16 ago la lista incluye
también **`HYL-WAI`** —el orden de integración `#161 → Payments → #135` se juega en sus ramas y un
rebase ahí nos afecta— y los tres ejecutores que entregan por commit (`Agente_QATest_Qualitas`,
`Agente-MejorasConversacion`, `Agente-Conciliacion`). Núcleo original:
`git fetch --prune` + comparar SHAs de TODAS las refs de `origin` contra los últimos vistos (no una
lista fija de ramas: así aparecen también las nuevas); emitir "REPO rama: SHA mensaje" por cambio.
Cubre: entregas, informes n8n, handoffs propios (eco), ramas nuevas.

**No emite eco de lo que publico yo (v3, 23 ago).** Los handoffs, los GO y sus correcciones los
escribo yo en `main` del repo del ejecutor, y `m3` me los devolvía como si fueran entrega suya: unos
diez avisos de cero valor en una tarde, hasta que Alberto pidió que dejaran de salir.

**No se puede filtrar por autor** — todos los agentes firman como `aibanez82`, que es la misma
limitación que hizo inválido el `mergedBy` del 23 ago. Se filtra por **prefijo del asunto**
—`handoff(`, `GO(`, `correccion(F`— que aquí es inequívoco: **ningún ejecutor se escribe un handoff a
sí mismo ni se da un GO**. Lo demás (`informe(`, `sync(`, `feat(`, `fix(`) pasa.

Dos refinamientos que valen (v2, 7 ago):

- **Distinguir avance de reescritura.** Cuando una rama se mueve, comprobar
  `git merge-base --is-ancestor <sha_viejo> <sha_nuevo>`: si pasa, avanzó; si no, **emitir alerta de
  REESCRITA**. Un force-push sobre una candidata o una congelada destruye el árbol acreditado, y es
  el evento que no se puede detectar tarde. Sin esto, un movimiento de rama y una reescritura se ven
  exactamente igual.
- **Saltar el ref pelado `origin`.** `refs/remotes/origin/HEAD` se lista como `origin` a secas y
  sigue a la rama por defecto, así que emitía un evento duplicado por cada push a `main`. Es un
  alias, no una rama.
- **El head de un PR solo se emite si DIVERGE de su rama.** Que coincida es lo normal y duplicaba
  cada push (2 eventos por commit); registrarlo en silencio. Cuando NO coincide —PR reapuntado,
  rama borrada, head ajeno— sí es señal.

## 3 bis. El monitor huérfano que duplicaba tres de estos (23 ago)

Durante toda la jornada llegaron a la sesión avisos duplicados de `m2`, `m3` y `m4`. No eran un fallo
de los míos: era **un monitor de otra sesión, muerta el 19 de agosto**, cuyo proceso sobrevivió
**cuatro días** y cuyas notificaciones aterrizaban en mi conversación.

Hacía a la vez lo de tres: commits de HYL-WAI en `stg` y `main`, commits y PRs de `Agente-n8n`,
`dudas/` de este repo, issues nuevos y comentarios de Juan.

**Cómo se identificó al dueño:** por la ruta de su fichero de salida, que lleva el id de sesión
(`…/<session-id>/scratchpad`), contrastada con la fecha de la carpeta de esa sesión. Cuatro días sin
tocar = huérfano. `ps` decía que estaba vivo; solo el id de sesión decía de quién.

> **Regla:** un monitor cuya sesión ya no existe **no se hereda: se mata**. Y antes de armar, además
> de mirar `ps`, comprobar si alguno de los procesos vivos pertenece a una sesión muerta — un
> duplicado silencioso cuesta más que un monitor ausente, porque enseña a ignorar el canal.

## 4. Dudas de ejecutores

Poll cada 60s de `git ls-tree origin/main -- dudas/` del repo Agente-Arquitecto: fichero sin su
`-respuesta.md` = duda pendiente → emitir una línea. (Responder SIEMPRE por fichero.)

## 5. Informes de ejecutores en `informes/` de este repo

Poll cada 60s de `git ls-tree origin/main informes/`; fichero nuevo → una línea con su fecha y el
asunto del commit que lo trajo. Excluir `README.md`, `-respuesta.md` y `-acuse.md`: esos los escribo
yo y avisarme de ellos es eco.

**Por qué existe (7 ago):** la nota de abajo decía que la señal de fin del Dashboard era el push de
su rama candidata (monitor 3). Eso vale para una entrega de CÓDIGO; **no vale para un trabajo
DOCS-ONLY**, que no mueve ninguna rama suya. Le encargué el inventario S3, entregó su informe por
este canal y **ningún monitor avisó**: lo detectó Alberto preguntando. Corolario general: cuando se
encarga trabajo cuya entrega no mueve la superficie que vigilan los monitores existentes, el canal
de entrega necesita el suyo **antes** de mandar el encargo.

## 6. Releases de Django en Heroku — `hyl-wai-stg` **y `hyl-wai-production`**

Poll 180s de `heroku releases -a <app> -n 1 --json` sobre **las dos** apps; emitir cuando cambie
`version`, `description` o `status`, incluyendo el valor anterior y el nombre de la app.

**Y carga su propia credencial (v2.3, esa noche).** El aviso de ceguera funcionó a la primera y
señaló un fallo distinto: **el monitor no hereda nada**. Corre como proceso de fondo con el entorno
de su arranque, así que un `export HEROKU_API_KEY=…` hecho en una llamada de Bash **no llega hasta
él**. La sesión de la CLI se recuperó con el token de `.env.local` y `m6` siguió ciego igualmente,
porque nadie se lo había dado *a él*. Ahora lo lee del `.env.local` del repo si no viene en el
entorno — el fichero está gitignorado, así que en git solo viaja la ruta.

**Regla:** un monitor que depende de que alguien recuerde exportarle algo está roto por diseño. Si
necesita una credencial, que la busque él. Vale para `m2` (token de `gh`) y `m3` (acceso a los
remotos), que hoy dependen del entorno heredado y habría que revisar con este criterio.

**Y no calla si se queda ciego (v2.2, misma tarde).** La v2 hacía `[ -z "$cur" ] && continue`: si
la lectura fallaba, el monitor seguía vivo **sin emitir nada, para siempre**. Pasó ese mismo día —la
sesión de la CLI de Heroku se cayó y `m6` dejó de vigilar los dos entornos sin un solo aviso, en
mitad de la promoción—. **Desde fuera, «no hay releases» y «no estoy mirando» se ven exactamente
igual**, que es el fallo que la propia herramienta `Monitor` advierte: *silence is not success*.
Ahora cuenta fallos consecutivos, grita **una vez** al cruzar el umbral (3 ciclos ≈ 9 min) y avisa
otra al recuperarse. Vale como regla para cualquier monitor que dependa de una credencial: **la
pérdida de acceso es un evento, no un no-evento.**

**PROD entra el 23 ago (v2).** Con el `#210` abierto —llevar STG a producción y dejar los dos
entornos como espejo— el release de PROD deja de ser ruido y pasa a ser la medida del trabajo: es
donde se ve aterrizar cada promoción, y donde un **rollback cambiaría la línea base sin que nadie
lo anuncie**. Es el mismo canal («lo que Juan despliega»), así que va dentro de este monitor y no
en uno nuevo. Es el **único monitor que ve a Juan
desplegar**: los otros cuatro ven lo que escribe o lo que empuja a git, no lo que pone a correr. Con
la cadena `#161 → Payments → #135` viva, un release nuevo cambia contra qué estamos midiendo, y un
rollback lo cambia **sin que nadie lo anuncie**.

**Llevaba vivo desde el 13 ago sin estar escrito aquí**, y en la poda del 16 ago estuvo a punto de
morir con los redundantes: no por serlo, sino porque no había forma de acreditar para qué servía sin
leerle el `ps`. Corolario: un monitor sin sección en esta spec es indistinguible de un residuo.

## Notas

- Emitir solo líneas accionables (los monitores ruidosos se auto-detienen).
- `seen` en memoria del script para no repetir.
- ~~El informe del Dashboard llega por `informes/`; su señal de terminado es el push de su rama
  candidata (monitor 3) — no requiere monitor propio.~~ **FALSO para trabajo docs-only** → monitor 5.
- Tabla de canales: `informes/README.md`. Si cambia un canal, actualizar monitor y esta spec en
  el acto (convención "canal nuevo sin monitor = punto ciego").
- **Un monitor vivo queda CONGELADO en la versión del script con la que se armó.** El proceso lee
  el fichero **una sola vez, al arrancar**: arreglar el script no arregla un monitor ya corriendo.
  Tras editar un monitor hay que **rearmarlo**, si no seguirá emitiendo con la lógica vieja.
  Al Agente-n8n le costó un rato de diagnóstico el 8 ago: su monitor de handoffs llevaba vivo desde
  antes del arreglo del filtro, así que un `…-informe-r2.md` perfectamente válido disparaba aviso —
  se leyó como fallo de nombre y era un proceso desfasado.
  **Cómo distinguirlo:** comparar `ps -o lstart= -p <pid>` con el `mtime` del script. Si el proceso
  es anterior, es desfase y no un fallo de contenido. Comprobado el 8 ago sobre los cinco procesos
  de aquí: los cinco arrancaron después de su última edición, así que estaban en sync.
