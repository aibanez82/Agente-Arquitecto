# Barrido de honestidad del tracker — 8 ago 2026

Verificación **en vivo y de solo lectura** de los 17 issues abiertos con criticidad `crítico` o
`alto` en `aibanez82/qualitas-issues`. Cero escrituras: consultas `SELECT` sobre PROD con el rol
`readonly_leads`, lectura de código en `HYL-WAI@origin/main` (`43bfaf2`, 27 jul), lectura de los
exports de n8n y dos `heroku config:get` de un **nombre de bucket** (ninguna credencial leída).

## Resultado por issue

| # | Veredicto | Evidencia |
|---|---|---|
| **#7** | **REAL, se reproduce hoy** | de las pólizas con `phase=completed` + `numero_poliza`: **5 `PAGADO` / 5 `PENDIENTE`**. Global: 51 `PENDIENTE` vs 6 `PAGADO` |
| **#26** | **REAL, zanjado** | `AWS_STORAGE_BUCKET_NAME = hyl-wai-www` **en producción y en staging**. El mismo bucket |
| **#25** | **REAL, sin cambios** | `QUALITAS_PASSWORD_TARIFA` con default `"LINEA"` en `services.py:98` y `:163`; más `QUALITAS_URL` y `QUALITAS_URL_OPL` |
| **#9** | **REAL, matizado** | las tres ramas 400 de `api_emitir_externo` (`views.py:848+`) devuelven mensajes **distintos** —no genéricos— pero **ninguna registra la causa**; el único `component=` está en el tramo de payment link |
| **#29** | **REAL** | los 6 deployments Preview siguen `Ready` y sirviendo 307; los alias ya no resuelven a ellos (inventario del Agente Dashboard, 7 ago) |
| **#4** | **REAL, magnitud corregida a la BAJA** | 141 cotizaciones sin sesión en 30 días, pero **125 son `LANDING`** (full-web, sin sesión por diseño) y solo **16 son `WHATSAPP`**. La cifra accionable es **16**, no «4+» ni 141 |
| **#20** | **REAL, tasa corregida** | **86 de 1 311 = 6,6 %** en 60 días. El issue dice ~11 % |
| **#56** | **REAL pero mal enunciado** | anunció fase y **no** persistió: **25**; anunció y **sí** persistió: **146**. Falla ~15 %, no siempre |
| **#45** | **Consistente con real, no concluyente** | los dos nodos `Postgres Chat Memory` del bot PROD no declaran `sessionKey`: ambos usan la derivación por defecto. Compatible con que compartan sesión; no distinguible sin ejecutar |

## No verificables con el acceso actual

| # | Motivo |
|---|---|
| **#40** | `qualitas_leadcheckpointfollowupattempt` **sin grant de SELECT** para `readonly_leads` |
| **#18** | `opciones_cotizacion` **no es columna** de `qualitas_cotizacion`; probablemente vive en `qualitas_cotizacionrespuestaxml`, que tampoco tiene grant |
| **#13, #39, #49, #57, #64, #69** | requieren ejecutar el bot, o son materia de S3 (#57), o afectan a STG mientras está en pleno ciclo de import (#69) |

**Hallazgo colateral, y no menor:** el rol `readonly_leads` **no tiene SELECT sobre 21 tablas
`qualitas_*`**, entre ellas todas las de follow-up y las de experimentos. Cualquier verificación
futura sobre esas áreas necesita otro rol o un grant explícito. Conviene decidirlo antes de que
alguien concluya «no hay datos» cuando lo que hay es «no hay permiso» — el mismo error que casi
cometo con `information_schema` al comprobar el espejo de PROD.

## Qué se hizo con el resultado

Comentados con la evidencia los issues **#4, #7, #20, #25, #26 y #56**. Los tres últimos incluyen
corrección del enunciado: **#4** (magnitud), **#20** (tasa) y **#56** (el bug es parcial, no total).
Ninguno se ha cerrado: la evidencia dice que los nueve verificados siguen vivos.
