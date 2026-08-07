# Monitores de sesión del Arquitecto — especificación para rearmarlos

> Los monitores viven solo mientras la sesión está abierta. Al abrir sesión nueva durante trabajo
> activo con Juan (etapas S1–S5), armar los CUATRO con la herramienta Monitor (`persistent: true`).
> Antes de armarlos: hacer el barrido de arranque (dudas/ pendientes, informes/, `gh issue list`
> en qualitas-issues, y comentarios nuevos en #132/#140 desde la última actividad conocida) —
> los monitores solo cubren lo NUEVO a partir de su arranque.

## 1. Dictámenes/comentarios de Juan en HYL-WAI#132

Poll cada 60-90s de `gh api "repos/aguayo-co/HYL-WAI/issues/132/comments?since=<ahora>"` filtrando
`user.login=="oilycoyote"`; emitir una línea por comentario nuevo (fecha + primeras ~200 chars).
Cubre: dictámenes, freezes, STOPs, resoluciones §12, entregas Django.

**Ojo con el comentario de «Estado canónico del monitor»** (marcador
`seguroauto-monitor:canonical`): el daemon lo **edita en sitio**, así que `since` —que filtra por
`updated_at`— lo devuelve una y otra vez. Dedupe por **hash del contenido**, no por `id+updated_at`;
y **quitando antes los timestamps ISO**, porque su campo «Próxima revisión» se reescribe cada ~30
min sin que cambie nada material y dispara el monitor en vacío (visto el 7 ago).

## 2. Comentarios nuevos en HYL-WAI#140 (gobernanza)

Igual que el 1 pero sobre `issues/140/comments`. Baja frecuencia real; poll 120s.

## 3. Ejecutores: pushes en ramas candidatas + commits en main + PRs

Poll cada 60s de los remotos de `~/claude-projects/Agente-n8n` y `~/claude-projects/Dashboard_SeguroAuto`:
`git fetch --prune` + comparar SHAs de TODAS las refs de `origin` contra los últimos vistos (no una
lista fija de ramas: así aparecen también las nuevas); emitir "REPO rama: SHA mensaje" por cambio.
Cubre: entregas, informes n8n, handoffs propios (eco), ramas nuevas.

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

## 4. Dudas de ejecutores

Poll cada 60s de `git ls-tree origin/main -- dudas/` del repo Agente-Arquitecto: fichero sin su
`-respuesta.md` = duda pendiente → emitir una línea. (Responder SIEMPRE por fichero.)

## Notas

- Emitir solo líneas accionables (los monitores ruidosos se auto-detienen).
- `seen` en memoria del script para no repetir.
- El informe del Dashboard llega por `informes/` de este repo; su señal de terminado es el push
  de su rama candidata (monitor 3) — no requiere monitor propio.
- Tabla de canales: `informes/README.md`. Si cambia un canal, actualizar monitor y esta spec en
  el acto (convención "canal nuevo sin monitor = punto ciego").
