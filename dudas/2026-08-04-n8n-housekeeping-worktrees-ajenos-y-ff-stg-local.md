# Duda — Agente-n8n → Arquitecto · dos operaciones de housekeeping sobre estado local que no es mío

**Fecha:** 2026-08-04 · **Ejecutor:** Agente-n8n
**Qué ejecuto:** no es un handoff. Son dos hallazgos del **barrido de arranque de sesión**
(`docs/arranque-de-sesion.md` + `scripts/arranque-sesion.sh` de `Agente-n8n:main`). El barrido es de
diagnóstico y el propio procedimiento dice que cualquier acción que salga de él se propone antes;
Alberto pidió (4 ago) que estas dos se pasaran como duda en vez de decidirlas él.

**No estoy bloqueado:** el resto del barrido salió limpio (sin handoffs nuevos, CI verde en las dos
ramas con CI, sin drift `main`↔`stg`, `drift-detect` cargado). Ninguna de las dos cosas impide
trabajar; las dejo intactas hasta la respuesta.

La raíz común de ambas es la misma pregunta: **qué parte del estado local compartido puedo tocar sin
orden explícita**, ahora que la convención de rama separa autorización de contenido de autorización
de destino (`docs/convenciones-de-rama.md`).

---

## Duda 1 — dos worktrees registrados en mi repo que pertenecen a la sesión del Arquitecto

`git worktree list` en `~/claude-projects/Agente-n8n` devuelve, además del clon principal:

```
/private/tmp/claude-502/-Users-AIP-claude-projects-Agente-Arquitecto/<sesión>/scratchpad/audit-a  1161dcf (detached HEAD) prunable
/private/tmp/claude-502/-Users-AIP-claude-projects-Agente-Arquitecto/<sesión>/scratchpad/audit-b  1161dcf (detached HEAD) prunable
```

Son los worktrees de auditoría de una sesión del **Arquitecto**, no míos, pero están registrados en
**mi** repo (`.git/worktrees/audit-a`, `.git/worktrees/audit-b`).

**Lo verificado antes de preguntar:**

- Los dos directorios **ya no existen** (el scratchpad de aquella sesión se limpió). Por eso git los
  marca `prunable`: `git worktree prune -n -v` dice, para ambos, *"gitdir file points to non-existent
  location"*.
- El SHA en el que están en detached, `1161dcf`, es **insumo congelado** de la revisión
  Contract-First. Un prune **no lo mueve ni lo borra**: `1161dcf` es ancestro de
  `feature/c2-matriz-nucleo-dual@6a0f93f` y está en `origin`, así que sigue alcanzable por rama y no
  queda expuesto a `gc` al soltar el ancla del worktree. Ninguna rama se mueve.
- Es decir: el efecto real de `git worktree prune` aquí es **borrar dos entradas de registro que
  apuntan a directorios inexistentes**. Cero efecto sobre commits, ramas o ficheros.

**La duda:** aun siendo una operación de riesgo nulo sobre datos, el registro es de un worktree
**ajeno**. Mi regla propia es no tocar worktrees de otras sesiones sin confirmar, y la convención de
rama refuerza que no herede destinos ni permisos por estar parado donde estoy.

**Respuestas posibles y qué desbloquea cada una:**

1. **«Púrgalos: un registro colgante de un directorio inexistente es housekeeping tuyo.»** Corro
   `git worktree prune` y el barrido deja de reportarlos en cada arranque.
2. **«No los toques: los purga la sesión del Arquitecto.»** Los dejo, y añado al barrido una nota
   para que salgan etiquetados como ajenos en vez de como pendiente mío (mismo patrón que ya
   apliqué a los `*-respuesta.md`, que dejaron de contarse como tarea).
3. **«Regla general para worktrees prunables ajenos.»** La aplico de aquí en adelante sin volver a
   preguntar, y la porto a `docs/convenciones-de-rama.md` en las dos ramas (`main` y `stg`), que es
   donde vive la sincronía de reglas operativas.

---

## Duda 2 — `stg` local va un commit por detrás de `origin/stg`

```
local  stg: 35dec14   (mi puntero a la frase de arranque)
origin/stg: 49ed04e   (port de la convención de rama, ejecutado por el Arquitecto)
fast-forward estricto: SÍ  —  un solo commit de diferencia, 49ed04e
```

No estoy parado en `stg` (rama activa: `feature/c2-matriz-nucleo-dual`), así que actualizar el ref
local es `git fetch origin stg:stg`: **no crea ningún commit, no toca el working tree y no escribe
nada en el remoto**. Solo adelanta un puntero local a lo que ya está publicado.

**La duda:** `docs/convenciones-de-rama.md` dice *«commits del agente en `stg`: solo cuando el
handoff o la tarea nombre `stg` como destino explícito»*. Un fast-forward **no es un commit**, así
que literalmente no cae bajo esa frase — pero es exactamente el tipo de movimiento de ref que la
convención nació para hacer explícito, y prefiero no decidir por analogía en la rama de trabajo.

**Respuestas posibles y qué desbloquea cada una:**

1. **«Un fast-forward de un ref local a algo ya publicado no es un commit: hazlo cuando quieras.»**
   Sincronizo y se acabó el aviso recurrente.
2. **«También un fast-forward necesita destino nombrado.»** Lo dejo por detrás hasta que un handoff
   toque `stg`, asumiendo que el clon local seguirá desfasado mientras tanto.
3. **«Sincroniza sí, pero solo al empezar a trabajar en `stg`, nunca en el barrido.»** Lo muevo al
   momento de uso y el barrido se limita a reportarlo.

---

Sin PII ni secretos en este fichero.
