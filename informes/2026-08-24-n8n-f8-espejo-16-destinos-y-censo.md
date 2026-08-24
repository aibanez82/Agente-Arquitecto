# Informe F8 — el espejo cubre 16 destinos y gana el censo que no se olvida

> Agente n8n · 24 ago 2026 · Handoff `2026-08-24-f7-f8-limpieza-y-espejo.md` (GO `8a460f5`), parte F8.
> `stg` con el cambio mergeado (`fix/f8-espejo-completo-y-censo`); la copia legada de `main` también
> ganó sus dos filas (`3af4e9e`).

## Lo hecho

1. **Las dos filas pedidas**: `oTZ86TYMitK2bSur` (Error Handler) y `SEKpp6E4gggaHj11` (Issue
   Policy Guard), rama `main`, baselines los exports sincronizados en F4.
2. **El censo que sugeriste — implementado**: `_censo_instancias()` lista los workflows **ACTIVOS**
   de cada instancia (paginado) y **falla con nombre** por cada uno sin fila en `TARGETS`. Cuenta
   para el exit code del `--fail-on-drift` y avisa por Telegram. Razón en el código: la regla del
   «mismo movimiento» falló tres veces (S1, Atencion Humana, estos dos un día tarde) — una regla
   que depende de que alguien se acuerde no vigila nada; el censo cuenta.
3. **El censo destapó dos activos de STG sin vigilar** que también entraron, con espejo verificado
   por hash contra el vivo antes: `PuogahK4qv9YOiF4` (Issue Policy Guard STG) y `DeCguAaVtCuW2CUj`
   (poller de descuentos). **Total: 16 destinos**, no 14 — tus 12 + los 2 pedidos + los 2 que el
   censo encontró.

## El dispatch — y por qué NO salió verde, que es la parte honesta

Run `32759965218`: **16 destinos revisados, censo limpio, 1 drift → rojo.** El drift es el
**esperado y documentado por ti en F3**: `s1/main-candidato.json` lleva el rename (`WA Config`) y
el `Phone Number ID Guard` que **aún no se importaron a STG** — «repo por delante», pendiente del
import con firma. Dirección medida: 1 nodo solo en el vivo (`WA Config STG`), 2 solo en el baseline
(`Phone Number ID Guard`, `WA Config`). Un verde hoy habría sido falso; el monitor está rojo
nombrando exactamente la pieza pendiente, que es su trabajo. Cuando ese import se haga, 16/16.

## Nota de mapa

La copia de `scripts/detect-drift.py` en `main` es **legada** (motor viejo, sin
`--fail-on-drift`/perfiles/censo, y con los baselines S1 de la era «operativo»). El CI corre la de
`stg`. Propongo igualarlas (reemplazar la de `main` por la de `stg`) en un movimiento aparte —
decisión tuya, no la ejecuto sin orden.
