# Guardas

## `guarda-privilegios-dashboard.sh`

Caza el **default-deny por GRANT ausente** antes de que llegue a PROD: cruza el catálogo de
privilegios REAL de PROD con los objetos que el código del Dashboard consulta de verdad.

```
DATABASE_URL=<PROD> ./guarda-privilegios-dashboard.sh origin/stg
```

Sale `1` si algún objeto consultado no es legible por el rol; `2` si la propia guarda no puede
acreditar nada.

### Por qué existe, y por qué NO es un rol en STG

La idea primera era crear `dashboard_rw` en STG para que el fallo se cazara allí. **No es posible
con el plan actual, medido el 6 sep 2026:**

- `dashboard_rw` en PROD no es un rol hecho a mano: es una **credencial de Heroku**. PROD
  (`standard-0`) tiene tres — `default`, `dashboard_rw`, `readonly_leads`.
- STG es `essential-0` y tiene **una sola**. La API responde
  `403 · "Cannot create new credentials for essential-tier addons"`.
- Y por SQL tampoco: ni el usuario de STG ni el de PROD tienen `CREATEROLE`.

Así que la topología de privilegios de PROD **no se puede reproducir en STG** sin subir el plan.
Esta guarda sustituye a ese entorno, y sale mejor parada: compara contra el catálogo de PROD, que
es el que manda, en vez de contra una copia que envejece.

### El punto ciego que tuvo, y por qué la guarda cambió (6 sep 2026)

La primera versión enumeraba **el catálogo** y preguntaba «¿lo usa el código?». Con ese orden, **un objeto que el código consulta y que NO EXISTE nunca aparece**: no está en `pg_class`, luego no se comprueba. Devolvía `denegados: 4` y parecía completa.

Así se nos escapó `dashboard_control_commands`: definida en `migrations/2026-08-11-claims-epoch-anti-aba.sql`, **creada en STG y nunca en PROD**, y consultada por `pages/api/claim.js` de la rama que corre en producción con `INSERT`, `SELECT` y dos `UPDATE`.

Ahora la guarda hace **las dos direcciones**: del código al catálogo (¿existe?) y del catálogo al código (¿tengo permiso?). Un ausente devuelve `1` igual que un denegado.

### Tres trampas que esta guarda tiene incorporadas

1. **`git grep -E` NO soporta `\b`.** No da error: no casa nada. Por eso la guarda usa `-P` y por
   eso lleva un **control positivo** (`conversation_control_v1`) que aborta con código 2 si la
   búsqueda deja de encontrar lo que se sabe que está.
2. **`to_regclass` no filtra por privilegios** — y por eso es exactamente la función buena para la comprobación de ausencia: un `NULL` es ausencia real, no falta de permiso. Al revés que `information_schema`, donde «no existe» y «no lo veo» son indistinguibles.
3. **La dirección de la pregunta importa.** Verificado conectando como `dashboard_rw` contra
   PROD: `to_regclass('public.qualitas_leadfunnelevent') IS NOT NULL` → `true`, y el `SELECT`
   siguiente → `permission denied`. Cualquier detección de disponibilidad basada en `to_regclass`
   da un **falso positivo** y el camino de degradación no se activa. Usar `has_table_privilege`.

Ambas son la misma convención de `CLAUDE.md`: *una lectura que puede fallar en silencio no
acredita ausencia*.
