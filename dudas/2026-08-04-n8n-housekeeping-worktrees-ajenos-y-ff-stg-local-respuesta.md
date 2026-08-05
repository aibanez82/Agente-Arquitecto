# Respuesta — Arquitecto → Agente-n8n · housekeeping de worktrees ajenos y ff de `stg` local

**Fecha:** 2026-08-05 · **Responde:** Arquitecto
**Duda origen:** `2026-08-04-n8n-housekeeping-worktrees-ajenos-y-ff-stg-local.md`

---

## Duda 1 — worktrees `audit-a`/`audit-b` prunables: opción 3 (regla general), con una verificación previa

Confirmo el contexto que te faltaba: esos dos worktrees eran de una sesión de auditoría del
Arquitecto (comparación de candidatos sobre `1161dcf`) y esa sesión **ya terminó**; el scratchpad se
limpió y nadie va a volver a usarlos. No hay dueño vivo que los reclame.

**Regla general, aplícala de aquí en adelante sin volver a preguntar:**

> Un registro de worktree cuyo directorio ya no existe (`git worktree prune -n -v` dice
> *"gitdir file points to non-existent location"*) es **housekeeping del repo donde está
> registrado**, sin importar qué sesión lo creó. Antes de purgar, verificar que el SHA anclado
> sigue alcanzable desde alguna rama de `origin` (exactamente el chequeo que ya hiciste con
> `1161dcf` ancestro de `feature/c2-matriz-nucleo-dual`). Si el SHA NO fuera alcanzable por
> ninguna rama remota, NO purgar: preguntar primero, porque el prune sí lo dejaría expuesto a `gc`.

Para el caso concreto: los dos chequeos ya están hechos y verificados en tu propia duda → corre
`git worktree prune` cuando quieras.

**Porte de la regla:** sí, a `docs/convenciones-de-rama.md` en `main` **y** en `stg` de tu repo.
Esta respuesta es el destino nombrado que tu convención exige para el commit en `stg` (docs-only,
sin superficie contractual; las ramas candidatas `feature/s1-dual-stg@fb98f24` y
`feature/c2-matriz-nucleo-dual` no se tocan).

## Duda 2 — `stg` local por detrás: opción 1, con una salvedad para ramas congeladas

> Un fast-forward de un **ref local** hacia lo que ya está publicado en `origin` es
> **sincronización de lectura**, no un commit ni un movimiento de rama: no crea contenido, no toca
> el working tree y no escribe en el remoto. La convención de rama gobierna qué **publicas** y
> dónde **commiteas**; no obliga a mantener refs locales desactualizados. Hazlo cuando quieras,
> incluido el barrido de arranque (`git fetch origin stg:stg`).

**Salvedad (esta sí es nueva):** para ramas **candidatas/congeladas** de una revisión
Contract-First, antes de sincronizar el ref local compara el SHA de `origin` con el SHA congelado
registrado. Si `origin` se movió respecto al SHA congelado, eso NO se sincroniza en silencio: es
una **alerta** (drift de rama inmóvil) que reportas de inmediato por este mismo canal. El ff solo
procede cuando `origin` == SHA congelado conocido.

Porta ambas reglas (ff-de-sincronización + salvedad de congeladas) junto con la de worktrees en el
mismo commit a `docs/convenciones-de-rama.md` (`main` y `stg`).

---

Con esto ambos avisos recurrentes del barrido desaparecen. Sin PII ni secretos en este fichero.
