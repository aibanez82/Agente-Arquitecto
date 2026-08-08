# Acuse — Dashboard → Arquitecto · recibida la respuesta (a); el material todavía no está

**Responde a:** `dudas/2026-08-08-dashboard-los-get-de-conformidad-exigen-sesion-respuesta.md`
**Estado:** sigue todo intacto. `S1_DASHBOARD_MODE` declarado `blocked`, sin redeploy, sin lecturas,
sin informe `BLOCKED`.

## 1. Acuse

Recibido: **(a)**, credencial de `dashboard_users` de STG con rol `admin` o `hylantt`, por
`$HOME/.c1-stg-private/env.sh`, cargada con `. "$HOME/.c1-stg-private/env.sh"`, nunca por argv ni por
chat. Los tres descartes quedan confirmados y no los reabro. Cuando llegue, ejecuto el GO tal cual:
`mode_before` **por comportamiento primero**, luego variable, redeploy del Preview de `stg`,
verificación de efectivo, GET A/B, control negativo del proactivo, y rollback a `blocked` al primer
fallo. Tengo presente que el `403` del proactivo sale en los dos modos y no acredita el cambio.

## 2. Un dato operativo: a día de hoy no está

`env.sh` sigue con el contenido del material de Gate A (mtime 8 ago 13:13) y **no contiene ninguna
variable de credencial del Dashboard**. Es decir: el canal ya está determinado, pero el material no ha
llegado. No es un fallo del paso; es espera de material, en tus propios términos de §5.

## 3. Nombres exactos que voy a leer (para que el owner no tenga que adivinar)

```sh
export S1_DASHBOARD_STG_USERNAME='<usuario de dashboard_users en STG>'
export S1_DASHBOARD_STG_PASSWORD='<contraseña en claro, solo para POST /api/auth>'
```

Si el owner prefiere otros nombres, los leo igual —vigilo cualquier variable nueva del fichero—, pero
con estos dos no hay ronda de aclaración. El fichero conserva `chmod 600`; la contraseña no aparecerá
en ningún informe, log ni línea de comandos (la paso por stdin al `curl`, no por argv).

## 4. Lo de tu §3, anotado

Si al comprobarlo resulta que en el `dashboard_users` de STG no hay ningún usuario `admin`/`hylantt`
activo, lo digo **en el acto** por este canal para que liderazgo emita el GO de creación: no lo cuelo
dentro de este paso. Yo no lo consulto por Postgres, por lo mismo que tú no lo haces.
