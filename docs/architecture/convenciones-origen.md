# Origen de las convenciones de CLAUDE.md (historias e incidentes)

> Este doc guarda el CONTEXTO de por qué existe cada convención — los incidentes y decisiones que
> las originaron — para que CLAUDE.md pueda quedarse solo con la regla. Extraído el 4 ago 2026 en
> la optimización de tamaño. Si una convención cambia, actualizar aquí su historia.

## Convención de handoffs (6 jul; endurecida 1 ago)

- **Por qué "siempre en `main` y verificar rama antes":** incidente doble 31 jul–1 ago — dos
  handoffs se commitearon en la rama candidata C1 del ejecutor (los clones son compartidos y
  estaban en rama candidata bajo auditoría del monitor de Juan), contaminándola.
- **Por qué "detección por fichero sin informe, NO por rango/HEAD de commits":** bug de loop del
  Agente-n8n — un `git pull` hecho para su propio push arrastraba handoffs por delante del
  marcador de HEAD y los marcaba "vistos" sin leerlos. Cerrado en `Agente-n8n@5470933b`. De ahí:
  dropear un handoff debe ser idempotente a pulls.
- **4 ago:** confirmado que el Agente-n8n tiene monitor propio sobre `handoffs/` de `origin/main`
  — basta el push, sin mensaje manual (primer uso real: handoff S2 `5cc2d07` → entrega `b104b1f`
  el mismo día).

## Verificar contra la fuente antes de publicar (reforzada 1 ago)

Raíz de los fallos por iteración. Fallos reales que la motivaron:
- un checkpoint publicado citó un instalador que no existía en la entrega del ejecutor;
- un orden de PUT publicado a Juan estaba invertido respecto al runbook real.
Lección adicional: verificar el código sin leer el **doc de entrega** del ejecutor deja fuera
contratos de API y contradicciones de gobernanza. Caso positivo (4 ago): el inventario S2 del
ejecutor se verificó contra los JSON antes de integrarlo — y eso destapó que el fix del #69
existía solo en STG mientras PROD seguía aceptando `completed`.

## Cambiar una convención = actualizar su herramienta en el acto (1 ago)

Fallo real: al mover las entregas de ejecutores a `main`, el monitor de vigilancia seguía mirando
solo ramas candidatas → las entregas a `main` eran invisibles. Un canal nuevo sin monitor es un
punto ciego.

## Backup de workflows n8n

El backup automático se descontinuó por decisión de Alberto el 29 jul (la `N8N_API_KEY` se rotó
ese día). La política vigente es export manual + commit en `docs/n8n-workflows/` de este repo
cada vez que se toque un workflow en producción. Detalle: `docs/architecture/backup-policy-n8n.md`.

## Alertar conflictos con el plan de Juan (31 jul)

Nació bajo la gobernanza `#140`/`#132` del plan C (freeze Dual, fases C con GO del monitor,
monitor `oilycoyote` vigilando nuestros repos por API). El 4 ago el plan C fue sustituido por
Contract-First S1–S5 (`#140 c.5174994247`); la convención sigue igual con la gobernanza vigente:
stand-down por etapa hasta contrato congelado + handoff.

## Respaldos/housekeeping en rama propia (4 ago)

Nació del incidente "port-132": el ejecutor n8n, con autorización de Alberto de "commit y push
de todo" (respaldo de exports STG que solo existían en local), commiteó sobre la rama en la que
estaba parado su clon — `feature/c2-matriz-nucleo-dual`, declarada inmóvil por la enmienda
Contract-First. Sin daño (commits aditivos, insumo `1161dcf` íntegro, candidatas r2 inmóviles),
pero obligó a clasificación preventiva en `#132 c.5185668015`. Regla instaurada por handoff en
ambos ejecutores (`Agente-n8n@5058907`, `Dashboard@0665df7`): destino de commit explícito,
rama propia para respaldos, y "autorización de contenido no es autorización de destino".

## Recortes de estado trasladados desde CLAUDE.md (4 ago, verbatim)

Estos párrafos de estado vivían en CLAUDE.md; su hogar es el doc de cada iniciativa y el tablero.
Se conservan aquí tal cual estaban por si el doc de iniciativa no los tuviera aún:

- **Seguimiento leads estancados:** "✅ ENVIANDO EN REAL en PROD desde el 20 jul (171 envíos al
  30 jul; verificado en `n8n_chat_histories`, `metadata.source='django_checkpoint_followup'`). El
  filtro de horario 9am-8pm sigue SIN construir; decisión de Alberto (30 jul): se acepta el envío
  sin filtro (residuo fuera de horario ~1-3/día en los bordes) — el filtro pasa de bloqueante a
  mejora deseable. En STG están apagados/dry-run por la contención del port #132."
- **Conversation ID (Issue #21):** "Ya desplegado en PROD en modo shadow (Django
  `WHATSAPP_CONVERSATION_ID_MODE=shadow`, nodos `Resolve Session`/`Session Router` en n8n PROD).
  Pendiente: mergear a `main` la rama del Dashboard (`fix/conversation-id-whatsapp-n8n`) y decidir
  con Juan el paso a `dual`."
- **Recordatorios por fecha mencionada:** "handoff a Juan 16 jul; cliente da fecha para no
  contratar todavía → Haiku extrae, Python calcula, se envía vía el webhook proactivo existente.
  Bloqueante: plantilla de Meta para re-enganche fuera de ventana 24h."
- **Tabla BD, fila retirada:** "`NumeroPruebaWhatsapp` — no existe en producción y ya no importa:
  `normalize_whatsapp_phone` cae siempre a `52`. Bug #2 cerrado
  (`docs/bugs/bug-02-prefijo-57.md`)."
- **Pendiente fecha_inicio #114 (texto largo):** "✅ Django en PROD 27 jul (PR #125, v331). E2E
  n8n STG validado 28 jul (pólizas reales, +0 y +30 exacto). Falta: fix prompt límite 30d
  (`qualitas-issues#66`, definía SHA de freeze de #132) y promoción n8n a PROD. Desbloquea
  M47/M48."
- **Monitor JUAN (detalle):** "rutina cloud `trig_013gQWu8gqfDh5c8QQWzTAbM`, 6-23h CDMX → issue
  `JUAN:` en qualitas-issues. Creado 29 jul pero CIEGO: el entorno cloud no tiene credencial
  GitHub (la corrida de prueba no creó el issue de control 'JUAN-monitor activo')."
- **Issue #119 (contexto):** "rider aceptado en la autorización de B3, 29 jul." — y 4 ago:
  hallazgo nuestro publicado en #119 `c.5183416152` (endpoint acepta POST sin credencial).

## Cambio de rol del Arquitecto (Alberto, 10 ago 2026) — de emisor de handoffs a definidor de requerimientos

**Qué cambia:** Alberto pasa a instruir **directamente** a los ejecutores (n8n, Dashboard). El
Arquitecto deja de publicar handoffs en sus repos y de responder `dudas/*.md`. Su entregable es el
**paquete de instrucciones para Alberto** — requerimiento, alcance, qué tocar, criterios de
aceptación y pruebas — y él decide qué pasa, cómo y cuándo.

**Qué NO cambia:**

- El Arquitecto sigue **leyendo** los repos de los ejecutores (informes, commits, artefactos). Es de
  donde sale el conocimiento E2E y la verificación contra la fuente; leer no es comunicar.
- El conocimiento E2E incluye explícitamente **la parte de Juan** (`aguayo-co/HYL-WAI`), no solo
  nuestros sistemas.
- La comunicación con **Juan y sus issues** sigue siendo del Arquitecto salvo orden en contra.
- El principio de la «orden de arranque» (contenido ≠ orden; ordena Alberto; la orden se registra
  aparte del contenido) sigue vigente aunque su mecanismo concreto en el fichero de handoff no se use.

**Por qué importa dejarlo escrito:** durante los 12 días de S1 el Arquitecto era el emisor de
handoffs y el que resolvía dudas en vivo, y buena parte de las convenciones de este documento
(orden de arranque, respaldos en rama propia, detección por fichero sin respuesta) nacieron de ese
modo de trabajo. Al cambiar el emisor, esas convenciones no se borran: quedan **suspendidas** y con
su formato documentado, porque el histórico de S1 se lee con ellas y porque Alberto puede reutilizar
el mismo formato al instruir.

**Ampliación del rol:** definición de requerimientos con más profundidad. Alberto detalla el
requerimiento de negocio y el Arquitecto devuelve las instrucciones para el ejecutor que toque.
Primer caso: recordatorios de pago (`docs/iniciativas/recordatorios-de-pago.md`, `HYL-WAI#144`).

## Tracker único en HYL-WAI — `qualitas-issues` congelado (Alberto, 19 ago 2026)

**La regla nueva:** todo issue nuevo nace en `aguayo-co/HYL-WAI`, sea de Django, n8n, Dashboard o
transversal. Desaparece el ruteo «el fix decide el repo», que obligaba a clasificar antes de poder
escribir. Autorización de Alberto en esta fecha, con el cambio ya hablado con Juan.

**Por qué no se migró nada.** GitHub solo transfiere issues entre repos del **mismo owner**, y
`aibanez82` y `aguayo-co` no lo son. Mover los 41 abiertos habría significado recrearlos a mano,
perdiendo número, autoría y comentarios, y dejando muertas todas las referencias `qualitas-issues#NN`
de `CLAUDE.md` y de los docs. Se eligió **corte limpio**: el repo viejo se congela, sus abiertos
viven su curso y se cierran donde están, y se apaga solo. Coste cero y ni un puntero roto — a cambio
de convivir con dos trackers una temporada, que es por lo que el barrido de sesión mira los dos.

**Lo que hubo que mover para que el cambio funcionara:** las 18 labels de la taxonomía
(`sistema:*`, `criticidad:*`, `reportado-por:*`, `triage`, `src:*`, `idea`) no existían en HYL-WAI
—solo tenía las nueve por defecto de GitHub— y sin ellas el inbox de captura rápida se queda sin
filtro. Se replicaron el mismo día. Es la convención «cambiar una convención = actualizar su
herramienta en el acto»: un canal nuevo sin su tooling es un punto ciego.

**El cabo que no está de nuestro lado:** la captura `QUALITAS:` la crea el flujo de Alberto en la
app de Claude, y ese flujo decide en qué repo escribe. Mientras siga apuntando al repo congelado,
las capturas nuevas caerán ahí por mucho que el protocolo diga otra cosa. Se cambia en la app, no
aquí.

**Consecuencia de gobernanza a vigilar:** el backlog de HYL-WAI pasa de 33 abiertos a recibir
también lo nuestro, y de los 41 que quedaban en el repo viejo **19 eran de n8n y solo 7 de Django**.
El repo es de Juan; que el volumen y la naturaleza de lo que ve cambien es precisamente lo que había
que hablar con él antes, y se habló.

## El trabajo para un repo nuestro vive en una rama nuestra (13 ago 2026)

**Incidente:** el módulo de descuentos de n8n de `HYL-WAI#156` se quedó **solo** en
`oilycoyote/Agente-n8n@feature/issue-156-conversation-control-n8n` (`d3a6387`) — 30 commits, 57
ficheros, +16.494 líneas — porque la cuenta de integración de Juan tiene solo `READ` en
`aibanez82/Agente-n8n` y publicó en su fork. Nuestro upstream se quedó en `383f6c2`, con Conversation
Control y **sin el módulo**. Nadie lo movió durante dos días.

**Diagnóstico de Alberto (13 ago):** el error es nuestro, no de Juan. La falta de escritura era un
hecho conocido; la respuesta correcta era abrirle una rama en nuestro repo o traer la suya el mismo
día, no dejar que el entregable viviera fuera.

**Tres costes concretos, todos materializados:**
1. **Invisibilidad.** El trabajo no aparece en `git branch -r` de nuestro repo. Se descubre leyendo un
   comentario del tracker, no mirando el repo.
2. **Sin respaldo.** Queda fuera de nuestros backups y depende de que un fork ajeno siga existiendo.
3. **La autoría deja de acreditar.** 25 de esos 30 commits llevan `aibanez82 <a.ibanez@gmail.com>`
   como autor *y* committer, porque el agente de Juan trabajó con la config git del clon. Solo 5
   llevan `Pi Coding Agent`. Es el mismo mecanismo que el 12 ago provocó una acusación equivocada en
   el Dashboard (`044d252`): **en repos compartidos con agentes, la firma git no dice quién escribió
   el código.** Revisar por contenido, siempre.

**Regla derivada:** ningún entregable para un repo nuestro pernocta en un fork ajeno.

## Gitflow en todos los repos, no solo en el de Juan (14 ago 2026)

**Observación de Alberto:** *«Juan desarrolla basándose en gitflow, siento que nosotros no.»* Y los
datos del día le dan la razón:

- el **Agente n8n commiteó directo en `stg`** todo el 14 ago — el fence, los scripts de import y
  borrado, los archivados de duplicados;
- el **Arquitecto publicó directo en `main`** de los repos de los ejecutores (handoffs, baselines);
- solo aparecieron ramas `feature/…` **cuando Juan lo exigió explícitamente** en su decisión de
  `#156`, y entonces salió natural en los dos lados a la vez.

Teníamos la convención escrita **solo para `aguayo-co/HYL-WAI`** (memoria `feedback-gitflow-hyl-wai`,
de una indicación de Juan) y nunca se extendió a los nuestros. No fue una decisión: fue un hueco.

**Lo que costó, el mismo día en que se detectó:** tres veces se commiteó en la rama equivocada por
trabajar sobre la rama viva de un clon compartido —un handoff cayó en `stg`, otro en una rama
`feature` del ejecutor, y un `push origin main` desde otra rama dijo «OK» sin publicar nada—. Con
ramas propias por tarea, el destino no depende de dónde estuviera parado el clon.

**La excepción declarada** —`handoffs/`, `dudas/`, `informes/` directos a `main`— no es pereza: los
monitores de los ejecutores vigilan `handoffs/` de `origin/main`. Meter la comunicación en el flujo de
release rompería el canal sin mejorar nada. Es coordinación, no artefacto de release.

## Worktree en vez de `checkout` en clones compartidos (16 ago 2026)

El 16 de agosto el Arquitecto y el Agente n8n trabajaron todo el día sobre el mismo clon de
`Agente-n8n`. A media tarde el Arquitecto tenía `CLAUDE.md` modificado sin commitear en `stg` y el
Agente n8n necesitaba `main` para cerrar un informe: un `git checkout main` habría fallado o le
habría arrastrado el cambio ajeno a otra rama.

El Agente n8n lo resolvió montando un worktree temporal, commiteando desde ahí y retirándolo — sin
tocar el árbol activo — y propuso generalizarlo. Su argumento es el que decidió la convención:
**avisar por el canal en vivo solo funciona si los dos están mirando el socket en el instante
correcto; el worktree funciona aunque no lo estén.** Una mitigación que depende de la atención
simultánea de dos partes no es una mitigación, y este modo de fallo es de los que sobreviven a que
ambas hagan bien su trabajo.

No era una idea nueva: `lib_workflow_sync.py` ya usaba worktrees para no ensuciar el checkout
activo. Lo que faltaba era generalizar una práctica que el repo ya contenía.

La alternativa de raíz —un clon por sesión— quedó descartada por coste en disco frente a un
mecanismo que sale gratis. Alberto fijó la convención el mismo día.

## Segunda mano y retractación en su canal (16 ago 2026)

Las dos salen del mismo incidente, y las dos son correcciones a cómo trabajo yo, no a un ejecutor.

El Dashboard entregó un informe con una tabla de hechos medidos, cada uno con su evidencia: el alias
de STG apuntaba a un deployment de hace 14 h, el merge de `#161` no había generado deployment de
rama, el último con `githubCommitRef=stg` era del 13 ago. Concluía que la integración de Git del
proyecto de Vercel estaba desenganchada, y preguntaba —bien— si reconectarla o ampliar el scope de
las variables de Preview, porque la decisión no era suya.

Acusé recibo dando el diagnóstico por bueno, dictaminé cuál de las dos vías era la mala, añadí una
pista propia («el corte coincide con el día de la promoción, no parece casualidad») y **escalé a
Alberto una decisión que no existía**. No verifiqué ni uno de los hechos.

Era falso. El CLI de Vercel miente en tres sitios a la vez: `vercel ls --meta githubCommitRef=X` no
filtra, `vercel inspect` no muestra rama ni commit, y los alias de rama se truncan a hash, así que
el del `feature/issue-161` se lee igual que el de `stg`. La API lo desmentía en dos llamadas:
deployments `githubCommitRef=stg` continuos hasta ese mismo día. El propio Dashboard lo descubrió a
las 12:50 al ir a reconectar la integración y encontrarse un «already connected».

**De ahí la primera regla.** La convención de verificar contra la fuente ya existía y ya decía «ni de
segunda mano», pero yo la venía aplicando a lo que afirmo y no a lo que repito. Un hecho medido por
un ejecutor **con su evidencia delante** se siente como fuente y no lo es: la tabla de evidencia es
exactamente lo que hace que baje la guardia. Si dictamino o escalo encima, lo mido yo.

**De ahí la segunda, que la formuló el Dashboard.** Él supo a las 12:50 que su informe era falso y lo
corrigió en conversación y en su memoria, pero el fichero siguió en pie en `informes/` hasta las
20:50. Mi acuse es de las 14:35: llegó **después** de que él ya lo supiera, construido sobre el
documento que seguía siendo la única versión publicada. Un agente no lee la conversación de otro:
lee el fichero. Mientras el original siga sin marca, es la verdad operativa por mucho que su autor
ya no la sostenga — y quien actúe sobre él actuará mal, sin culpa de nadie.

Alberto las aprobó las dos el mismo día. El apunte operativo que las acompaña: para hechos de
plataforma Vercel, la API REST, nunca el CLI.

## Hablar en git, y no confundir rama con entorno (17 ago 2026)

Alberto la pidió él mismo, con dos motivos suyos: familiarizarse con git y —el que pesa— **no
equivocarse al ordenar**. Es él quien autoriza las acciones vivas, así que necesita poder nombrar
con precisión lo que autoriza. Un «hazlo» sobre una frase ambigua es el modo de fallo a evitar.

El día que la pidió habían pasado dos cosas que la justifican solas:

- El Dashboard dio por desplegado lo que solo estaba **mergeado**, y de ahí salió un informe con un
  diagnóstico falso, un acuse mío construido encima y una decisión escalada que no existía. Juan nos
  lo escribió el mismo día con otras palabras: *«el merge en `stg` no equivale a confirmación de
  deploy»*.
- Al revisar ramas viejas aparecieron dos ya fusionadas (0 commits fuera de `main`) y una con **3
  commits de trabajo real** sin integrar desde hacía tres días. En un listado se parecen; borrar la
  segunda habría destruido un diagnóstico entero. Lo que las distingue es un contador, no el nombre
  ni la fecha.

De ahí las dos mitades de la convención: **situar el objeto** (clon, rama local, `origin/<rama>`,
PR, y de qué repo) y **separar rama de entorno**. Con el corolario operativo de que el estado del
entorno se pregunta a su fuente y el `fetch` va antes de mirar, porque `origin/<rama>` es una foto
del último fetch y no el presente.

## Decir dónde se buscó antes de decir qué se encontró (18 ago 2026)

Tres resbalones el mismo día, entre el Arquitecto y el Agente n8n, y los tres de la misma familia:

| quién | el fallo | la conclusión que produjo |
|---|---|---|
| Arquitecto | contador de ramas con **una sola base** (`origin/main..rama`) en un repo con dos troncos | «41 commits sin integrar» — eran **0**, la rama estaba entera en `stg` |
| Agente n8n | `grep s1-dual-stg` sobre el CI, que dio positivo **por el nombre de un fichero** | «el CI referencia la rama» — la menciona un documento, no la fija |
| Arquitecto | búsqueda en `scripts/s1/lib/` de unos ficheros que viven en `scripts/stg-operational-dual/lib/` | «no existen en ninguna rama» — estaban en **ocho** |

Ninguno de los tres da error. Los tres devuelven un resultado **limpio y confiado**, que es lo que
los hace peligrosos: una conclusión equivocada con aspecto de comprobación.

Lo que los caza no es más rigor genérico, es una frase: **decir dónde se buscó antes de decir qué se
encontró**. El Agente n8n lo formuló así al corregir el tercero: «si el mensaje hubiera dicho *busqué
`scripts/s1/lib/` en todas las refs*, la ruta mala se ve en un segundo». El ámbito convierte una
afirmación irrefutable en una verificable por cualquiera — incluido el que la escribió.

Corolario que ya estaba en la convención de segunda mano y aquí se refuerza: **la búsqueda estrecha
da falsos negativos y la cita amplia falsos positivos**, y desde dentro las dos se sienten igual de
concluyentes. Por eso el remedio no es «buscar mejor», es **publicar el ámbito**.
