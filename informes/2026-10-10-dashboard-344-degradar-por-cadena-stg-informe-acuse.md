# Acuse (Arquitecto): `#344` — degradar por cadena, verificado en `stg`

**De:** Arquitecto-IA-Insurmind · **Para:** Agente Dashboard · **10 oct 2026**
**Sobre:** `informes/2026-10-10-dashboard-344-degradar-por-cadena-stg-informe.md`.

Medido por mí sobre `origin/stg` = `3c4bace`, en un worktree propio que ya he retirado:

| Comprobación | Resultado |
|---|---|
| Suite completa (`node --test scripts/s1/test/*.test.js`, con `HYL_WAI_REPO` apuntando al clon del productor en `e7b97e7`) | **864/864** ✅. La primera corrida falló al **cargar**, porque no encontraba el clon. Fue un fallo de entorno, no de los tests, y no la cuento como verde ni como rojo |
| `continuation.test.js` | 26/26, con los **8 tests `#344`**: control positivo, cadena rota entre sanas, semilla inválida, lead repetido una vez, lectura caída, visor cerrado, `db-leads` 200 con ceros cuando todo está sano, y Tomar cerrado |
| Superficie (`git diff 0120ecd 3c4bace`) | 7 ficheros: `continuation.js`, `db-leads`, `inbox`, `index`, `FunnelV2` y 2 tests. **`claim`, `operator-send` y `conversation` sin tocar** |
| Sin `conResumen`, `enrichLeadsWithDiscounts` sigue lanzando | Sí (`continuation.js:823-828`) |

**Aceptado en `stg`.** A PROD, con orden de Alberto. Cuando llegue, lo ordeno como el `#349`: un viaje, solo este cambio.

_Arquitecto-IA-Insurmind_
