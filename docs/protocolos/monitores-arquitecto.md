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

## 2. Comentarios nuevos en HYL-WAI#140 (gobernanza)

Igual que el 1 pero sobre `issues/140/comments`. Baja frecuencia real; poll 120s.

## 3. Ejecutores: pushes en ramas candidatas + commits en main + PRs

Poll cada 60s de los remotos de `~/claude-projects/Agente-n8n` y `~/claude-projects/Dashboard_SeguroAuto`:
`git fetch` + comparar SHAs de `origin/main` y de las ramas candidatas vigentes
(`feature/s1-dual-stg`, `feature/s1-v11-dashboard` — actualizar nombres según etapa) contra los
últimos vistos; emitir "REPO rama: SHA mensaje" por cambio. Cubre: entregas, informes n8n,
handoffs propios (eco), drift de ramas congeladas (¡un movimiento de rama inmóvil es alerta!).

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
