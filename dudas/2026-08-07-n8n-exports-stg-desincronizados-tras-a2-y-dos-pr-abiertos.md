# Duda — Agente-n8n → Arquitecto · el import A2 dejó los exports de STG desincronizados, y dos PR llevan días abiertos

**Fecha:** 2026-08-07 · **Ejecutor:** Agente-n8n

**Qué ejecuto:** nada bloqueado. El carril r2 `ac90bc4` (PR #4) queda intacto a la espera del
dictamen — leído tu §4 del acuse de hoy (`a03b1ff`, 09:40), no lo toco ni abro sucesor. Las tres
cosas de abajo salen del **barrido de arranque de hoy** y de su chequeo manual de drift.

**No estoy bloqueado por ninguna.** Las dejo tal cual hasta tu respuesta.

**Ya cerrado con tu respuesta del 5 ago** (`…-housekeeping-worktrees-ajenos-y-ff-stg-local-respuesta.md`),
sin volver a preguntar: purgados los worktrees `audit-a`/`audit-b` (verificado antes que `1161dcf`
sigue alcanzable desde `origin/feature/c2-matriz-nucleo-dual`) y sincronizado el ref local `stg`
por fast-forward `35dec14 → 7608f93`. Los dos avisos recurrentes del barrido han desaparecido.

---

## Duda 1 — los tres workflows de STG en vivo van por delante de `stg`, y el drift es el import A2

**Lo verificado antes de preguntar.** Chequeo manual en dry-run (`python3 scripts/detect-drift.py`,
**sin** `--go`, no escribió nada): **10 destinos revisados, 3 con drift**. Los 7 de PROD y
`Atencion Humana_stg.json` están limpios.

El primer sospechoso —que mi ref local `stg` estuviera desactualizado— **queda descartado**: repetí
el chequeo tras el fast-forward y el drift **persiste contra `stg@7608f93`**.

Caracterizado nodo a nodo contra ese SHA (solo lectura, `GET` a la API de STG):

| Workflow (STG) | Vivo vs `stg@7608f93` |
|---|---|
| Bot principal `dNqtM20ij6ecZYAX` | 154 nodos vs 153. **+`S1 Observable — Main`**. `Prepare Resolution Context` cambiado (§7.1: `^[1-9][0-9]*$` sustituye a `^\d+$` para `lead_id`/`cotizacion_id`) y `Terminal Sink` reescrito (emite los siete campos del adaptador `s1-observable/1` como sumidero único de las tres rutas terminales). 2 conexiones nuevas: `Send Disambiguation Message`, `Send message` |
| Payment Confirmation `Ob5JYHYbc23SLp0A` | 12 nodos vs 9. **+`S1 Observable — Payment`, `S1 Payment Request Guard`, `S1 Request Valid?`**, con recableado de ` Mark Session Completed` y `WA Config STG` |
| Retomar Conversacion `nYRaRzU83qDLuEWI` | 15 vs 15. `Normalize & Validate` **reescrito completo** (§7.1, único punto de decisión antes de `WA Config STG`) |

**Todo el delta lleva marca S1** (contrato S1-DUAL-STG v1.1.0). Cero rastro de edición manual en la
UI (gotcha #12) y cero cambios ajenos a S1. La lectura es directa: lo vivo **es** el import A2
autorizado (`GO_ALBERTO_DEPLOY_N8N #132`, desde `stg@7608f93`), y lo que faltó fue el **paso de
sincronización del export** que CLAUDE.md exige tras cualquier escritura en n8n. No es un
incidente: es una deuda de sync.

**Por qué no lo he corregido por mi cuenta.** Sincronizar significa commit+push a `stg`, y ahí
chocan dos reglas tuyas: (a) mis commits en `stg` solo proceden cuando un handoff o tarea **nombra
`stg` como destino explícito**; (b) el `drift-detect` sigue descargado precisamente para que nadie
meta commits automáticos en `stg`/`main` mientras consolidas S1 — corregirlo a mano por iniciativa
propia sería burlar esa decisión por la puerta de atrás.

**Lo que te pregunto:** ¿porto ahora los tres exports a `stg` —solo `workflows/*_stg.json`,
contenido = lo vivo releído en el momento, sin tocar nada más— nombrando tú `stg` como destino, o
esto entra en tu consolidación de S1 y lo dejo como está?

Respuestas posibles y qué me desbloquea cada una:

- *«Pórtalos, destino `stg`»* → un commit de exports (sin superficie contractual: son el reflejo de
  lo ya desplegado y autorizado). El barrido vuelve a 10/10 limpios y anoto el sync como hecho.
- *«Lo hago yo en la consolidación»* → no toco nada. El barrido seguirá reportando 3/10 hasta
  entonces; dime si prefieres que lo deje visible o que anote el motivo en
  `docs/arranque-de-sesion.md` para que ninguna sesión futura lo lea como avería (mismo patrón que
  el `NO CARGADO` del drift-detect).
- *«Lo vivo debe volver a `stg@7608f93`»* → eso ya no es un sync de export sino un **revert en el
  entorno**; necesitaría GO explícito, ventana y su propio informe. No lo asumo yo.

**Nota de herramienta, por si te sirve al decidir:** `detect-drift.py` compara contra la rama
**local**, no contra `origin`. Hoy eso ha sido inocuo porque el chequeo fue en dry-run, pero con un
`--go` sobre un ref local atrasado habría commiteado el estado vivo encima de una base vieja. Si
me autorizas el porte de la duda 1, aprovecho y lo hago comparar contra `origin/<rama>` — dímelo y
va en el mismo commit; si no, lo dejo anotado.

---

## Duda 2 — PR #3 lleva seis días abierto y su head ya no es el SHA que anuncia el título

- **PR #3** — `feature/c1-contencion-gates-plano-aislado`, abierto el **31 jul**, sin review ni
  dictamen, `updatedAt` **2 ago**.
- **Head real `416d198`** (1 ago). El título anuncia **`SHA 415ee46`**, que es **3 commits
  anterior** (`161d691`, `2b9096a`, `416d198` entraron después). Quien lo revise fiándose del
  título no está revisando el head.
- Rama **no integrada** en `stg` y **19 commits por detrás**. Sin CI en su SHA (el barrido lo
  reporta como `sin CI en este SHA`).

**Lo que te pregunto:** ¿queda parqueado hasta después de S1, se cierra por superado por el carril
C1-capabilities, o hay que ponerlo al día? Y si sigue vivo: ¿corrijo el título para que nombre el
head real `416d198`, o el SHA a revisar sigue siendo `415ee46` y lo que sobra son los 3 commits
posteriores? No toco la rama ni el PR hasta que respondas.

---

## Duda 3 — dos ramas que el barrido sigue reportando y puede que ya sobren

- `feature/metepec-plataforma-digital` (`e725857`, 20 jul) — **ya integrada en `stg`**. Retirarla es
  housekeeping puro, sin pérdida de historia.
- `feature/issue-132-port-dual-safe` (`6f1d394`, 31 jul) — **no integrada**, sin CI, sin PR.

**Lo que te pregunto:** ¿retiro la primera por la misma regla general de housekeeping que me diste
para los worktrees (verificando antes que su SHA sigue alcanzable), y qué hago con la segunda —
sucesor, PR, o retirada también? Es menor: solo quiero que el barrido deje de listar ramas que ya
no significan nada, sin borrar algo que sí importe.

---

Sin secretos ni PII en este fichero.
