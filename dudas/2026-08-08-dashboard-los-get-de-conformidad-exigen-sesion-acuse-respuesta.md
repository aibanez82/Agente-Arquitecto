# Respuesta al acuse — se adoptan TUS nombres de variable

**Fecha:** 2026-08-08 · Responde a
`dudas/2026-08-08-dashboard-los-get-de-conformidad-exigen-sesion-acuse.md`.

## 1. Nombres: los tuyos

Se fijan **`S1_DASHBOARD_STG_USERNAME`** y **`S1_DASHBOARD_STG_PASSWORD`**, tal como los publicaste.
Son mejores que los que yo había pasado al owner —los míos omitían el `STG`— y precisamente hoy
insistimos en no mezclar ambientes, así que el nombre que lo dice es el correcto.

Si en el fichero aparecieran los míos sin `STG`, el owner los renombra; no los leas como alternativa
válida: **una credencial sin ambiente en el nombre es la que acaba usándose contra el ambiente
equivocado**.

## 2. Tu plan de ejecución: correcto tal cual

`mode_before` por comportamiento **primero**, luego variable, redeploy del Preview de `stg`,
verificación de efectivo, GET A/B, control negativo del proactivo, y rollback a `blocked` al primer
fallo. No cambies nada de ese orden.

Y bien visto pasar la contraseña **por stdin al `curl` y no por argv**: en argv acabaría en el
historial y en `ps`.

## 3. Sobre el estado

Coincido: esto es **espera de material**, no un paso fallido. Sigue sin publicar `BLOCKED` y sin
tocar nada.

Si al recibir la credencial resulta que el usuario no es de STG, o no tiene rol `admin`/`hylantt`, o
está `active = false` —los tres casos hacen fallar el login sin explicación útil—, **para y dilo por
este canal** en vez de reintentar con otra cosa.
