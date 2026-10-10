# Informe n8n · #588 en PROD: 17 vectores de la KB regenerados

**Orden:** `Agente-n8n:handoffs/2026-10-10-orden-prod-588-kb-vectores.md` (`b804e792`), orden expresa de Alberto.
**Aplicado:** 10 oct, ~21:00 UTC, en una sola transacción.
- **Rama:** `fix/588-kb-vectores`.
- **Migración:** `migrations/588/002-prod-regenera-vectores.sql`, con su reversión `002-prod-revert.sql` y la prueba `002-prod-prueba.sql`.
- **Generador:** `scripts/588/gen-588-prod.py`.
- **Respaldo de las 17 filas enteras:** `backups/588/prod-17-filas-pre-20261010T205748Z.csv`.

## Guardas (las tuyas, medidas al empezar: coinciden)
| huella | al empezar | después |
|---|---|---|
| filas | 119 | **119** |
| todas (texto + vector) | `5366481415f1e3a832a2ce1e96de0cf5` | cambia, como debe (17 vectores nuevos) |
| texto de las 17 | `51788bb003e005a6240b7d74acddb8bb` | **`51788bb0…` idéntica** |
| vector de las otras 102 | `cc5a2dfeb2fc3f721cc90c02a56c9dce` | **`cc5a2dfe…` idéntica** |

La migración lleva además el md5 del texto por fila, y aborta si hay ≠119 filas o si la huella total no es la medida.

## Reversión probada antes del paso definitivo
`002-prod-prueba.sql`, en una transacción con ROLLBACK en PROD: migración → 119 filas, `51788bb0…` y `cc5a2dfe…` sin moverse → reversión →
huella total `5366481415f1e3a832a2ce1e96de0cf5`, la del principio → ROLLBACK.

## Auditoría suelta de las 119 filas
- **Antes:** 17 por debajo de 0,999, justo las del alcance.
- **Después:** **0 por debajo de 0,999**. Las 17 regeneradas, medidas sueltas: mínimo 0,999998 (el 31) y 1,0 las demás.
- **Sin tocar:** el 38 y el 61, como pedías. Ni `question` ni `content` cambian (huella del texto idéntica). No hay filas nuevas ni borradas.

## Recuperación en PROD (solo lectura; el SQL de búsqueda del bot sobre `kb_chunks_rag`): top 3
| fragmento | pregunta real (id de PROD) | antes | después |
|---|---|---|---|
| **31 (bancos MSI)** | «si se puede pagar con la tarjeta de credito de BBVA a meses sin intereses» (12553) | 33, 32, 21 (**sin el 31**) | 33, **31**, 32 (**entra**) |
| 6 (datos para emitir) | «Que necesito tener para activar el seguro» (5823) | 52, 15, **6** | 52, **6**, 15 |
| 36 (Limitada) | «…que incluye la cobertura amplia y que incluye la cobertura limitada ?» (6763) | 35, **36**, 37 | **36**, 37, 35 |
| 34 (promoción) | «tienes promociones?» (11128) | **34**, 32, 33 | **34**, 32, 33 |
| 5 (datos para cotizar) | «Si te mando los datos por aquí me podrías dar una cotización?» (4658) | **5**, 7, 80 | **5**, 6, 7 |

El `#333` no ha viajado: el texto del 40 sigue siendo el de PROD, y solo se regeneró su vector.

Agente: Agente-n8n
