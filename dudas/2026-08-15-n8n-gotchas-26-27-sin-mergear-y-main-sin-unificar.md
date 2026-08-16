# Los gotchas #26 y #27 existen pero no están en ninguna rama viva, y `main` nunca recibió la unificación

**15 ago 2026 · Agente n8n · dos decisiones que no me toca tomar solo.**

## Contexto: de dónde sale esto

Ejecutando el handoff `2026-08-15-issue161-worker-descuentos-aviso-terminal-stg.md` (HYL-WAI#161)
apareció un gotcha nuevo —**el `PUT` fusiona `settings` en vez de reemplazarlo**, así que
`binaryMode` y `availableInMCP` sobreviven en el vivo pese a mandar un `settings` limpio, y la
allowlist del gotcha #4 resulta ser permanente y no una precaución de una vez—. Al ir a escribirlo
me encontré con que la lista de `docs/gotchas-n8n.md` **salta del 25 al 28**, así que numeré el mío
como **#30** para no pisar nada, y me puse a mirar dónde estaban el 26 y el 27.

El #161 en sí está **ejecutado y verificado**, con las cinco comprobaciones en verde e informe en
`informes/` de `main`. Nada de lo de abajo lo bloquea. Y el #30 ya está escrito y pusheado, en el
PR #8 de `Agente-n8n` contra `stg` — **sin mergear**, porque el merge me lo bloqueó el clasificador
de permisos de la sesión.

## Hallazgo 1 — el 26 y el 27 están escritos, y colgando de una rama muerta

No es un hueco de numeración: son dos gotchas reales, terminados, que nunca se incorporaron.

Viven en `docs/gotcha-26-aplanado-queryreplacement` (punta `ac49afc`, pushada a origin), una rama
que está **97 commits por detrás de `stg`**. Los dos se escribieron **sólo en
`docs/gotchas-n8n-detalle.md`** y nunca llegaron a tener su línea en la lista corta; además, como la
rama sale de antes de la unificación del 14 ago, allí `docs/gotchas-n8n.md` ni siquiera existe.

Y no son menores — los dos salen de incidentes reales de STG del 9 ago:

- **#26** — `options.queryReplacement` escrito como **una sola expresión que evalúa a un array**
  (`={{ [a, b, c] }}`) **no pasa por la lógica de reparto** del nodo: se usa tal cual como lista de
  binds, y un elemento que sea array llega a Postgres como ARRAY y revienta en cuanto alimenta un
  contexto `::json`. Es la causa raíz de la ejecución 876. Trae la regla accionable
  (`JSON.stringify` explícito cuando el bind alimenta `::json`/`::jsonb`), los tres sitios afectados
  (`Resolve Session` `$3`, `Apply Affinity Update` `$2`, `Mark Session Completed` `$4`) y —esto es
  lo que más valor tiene— el aviso de la **pista falsa de la versión**: el commit que "arregla" esto
  aguas arriba sí está en la 2.28.7 y falla igual, porque esa forma nunca toca ese código.
- **#27** — en un nodo `Code` bajo task runner, `$(variable)` **cuelga la tarea hasta el timeout de
  300 s** y `$('literal')` no; el `try/catch` no protege porque no lanza nada. Medido en la misma
  ejecución: 22 nodos con acceso literal a 11-60 ms y uno con `$(nombre)` a 300 006 ms, que bajó a
  12 ms al pasarlo a literales. Y el runner colgado **mata ejecuciones concurrentes**, así que
  ensucia fallos que no tienen nada mal. Incluye lo que NO es el arreglo (subir el timeout, o
  `continueRegularOutput`) y una lección de método: el caso encajaba perfectamente con un issue
  abierto de n8n y **no era** ese issue.

Mientras sigan ahí, el coste es concreto: son dos trampas caras que ya nos mordieron una vez y que
hoy no ve nadie que trabaje desde `stg` o `main`.

## Hallazgo 2 — `main` nunca recibió la unificación del 14 ago

Este me preocupa más que el anterior. `main` **no tiene** `docs/gotchas-n8n.md` ni
`docs/gotchas-n8n-detalle.md`: sigue con la sección `## Gotchas n8n` incrustada en su `CLAUDE.md`,
con los 14 bullets de siempre.

O sea que la cabecera del fichero unificado afirma «los `CLAUDE.md` llevan ahora un puntero a este
fichero en vez de una copia» y **en `main` eso todavía no es cierto**. Es exactamente la divergencia
que la unificación venía a cerrar, y la que ya nos costó perder de vista el procedimiento de
rotación del `phone_number_id`.

Contenido perdido no hay —esos 14 bullets son literalmente la cola del fichero unificado—, así que
hoy es un flanco abierto, no un daño. Pero se convierte en daño en cuanto alguien edite la copia de
`main`, y quien lo haga no tendrá ningún motivo para sospechar que hay otra.

## Las dos preguntas

**1. ¿Cómo rescato el 26 y el 27?**

| opción | qué implica | qué desbloquea |
|---|---|---|
| **Portar los dos bloques a `stg` en un PR limpio** (mi propuesta) | copio los bloques de `gotchas-n8n-detalle.md` y les escribo su línea en la lista corta; la rama vieja se abandona | los dos gotchas visibles desde `stg` sin arrastrar nada más |
| **Mergear la rama tal cual** | 97 commits de retraso; el diff toca ~140 ficheros, borra migraciones, suites y workflows enteros | nada que compense — lo descarto salvo que veas algo que se me escape |
| **Dejarlos donde están** | el hueco 26/27 queda documentado como deliberado | nada, pero al menos deja de parecer un despiste |

Si eliges la primera, ¿los numero **26 y 27** conservando su sitio, o los renumero al final? Yo
conservaría los números: los textos se citan entre sí y el hueco ya está en la numeración vigente.

**2. ¿Cierro el flanco de `main`?** Sustituir su sección de gotchas por el puntero al fichero
unificado toca el `CLAUDE.md` de `main`, y eso es promoción, no un `docs/` de los que van directos.
Necesito que me digas si lo hago yo y por qué vía, o si lo llevas tú.

## Qué hago mientras tanto

- El **#161 está cerrado por mi lado** y no espera a esto.
- El **#30 se queda en el PR #8** hasta que alguien lo mergee — no puedo hacerlo desde la sesión.
- **No toco la rama `docs/gotcha-26-aplanado-queryreplacement`** ni la borro hasta que decidas: es
  el único sitio donde vive ese texto.
- **No toco el `CLAUDE.md` de `main`.**
