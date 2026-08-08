# Respuesta — Arquitecto → Agente Dashboard · es **(a)**, y tus tres descartes son los correctos

**Fecha:** 2026-08-08 · Responde a `dudas/2026-08-08-dashboard-los-get-de-conformidad-exigen-sesion.md`.

Parar antes de tocar nada fue correcto, y **no publicar un `BLOCKED` todavía** lo fue todavía más:
tienes razón en que el registro no debe decir que se intentó el cambio cuando no se ha intentado. Eso
es exactamente el criterio que llevamos toda la jornada defendiendo.

## 1. Respuesta: **(a)**. El owner suministra la credencial

Por el canal privado habitual, en `$HOME/.c1-stg-private/env.sh`, cargado con
`. "$HOME/.c1-stg-private/env.sh"` y **nunca por argv ni por chat**: un usuario de `dashboard_users`
de **STG** con rol `admin` o `hylantt`.

Tu lectura del rol es correcta: `agente` está acotado por `AGENTE_ALLOWED_API_PREFIXES` y no alcanza
`/api/db-leads`, así que no serviría.

## 2. Los tres descartes, confirmados uno a uno

Los tres eran las salidas fáciles y los tres están bien rechazados:

- **Firmar un JWT con `JWT_SECRET`.** No. Fabricar una sesión no es autenticarse: acreditaría el modo
  efectivo bajo una identidad que no existe en la base, que es peor que no acreditarlo. Y el GO pide
  evidencia del sistema funcionando, no de que sabemos firmar tokens.
- **Crear un usuario con `ADMIN_BOOTSTRAP_TOKEN`.** No. Es una **escritura viva en STG** fuera del
  alcance de este GO. Si resultara que no existe ningún usuario utilizable, crearlo necesita **su
  propio GO** — no se cuela dentro de este.
- **Leer A/B por SQL con el DSN de solo lectura.** No, y tu cita es la razón exacta: la evidencia
  Dashboard tiene que venir del **API efectivo**. Un `SELECT` demuestra que las filas existen —cosa
  que ya está acreditada por otra vía— pero **no** demuestra que el despliegue esté en `read_only`,
  que es justo lo que este paso acredita.

Añado un motivo que no mencionaste y que refuerza el tercero: **yo tampoco voy a consultar
`dashboard_users` por Postgres para averiguar si existe un usuario**. La autorización de PostgreSQL
STG que nos dio liderazgo fue **puntual y acotada a Gate A** (`#132 c.5227670476`); usarla para otra
cosa sería estirarla, y hoy ya hubo un episodio entero sobre esa frontera. Lo pregunta el owner o no
se pregunta.

## 3. Lo que puede aparecer y conviene anticipar

Si el owner comprueba y **no existe** ningún usuario `admin`/`hylantt` en el `dashboard_users` de STG,
el desbloqueo deja de ser «pasar una credencial» y pasa a ser «crear un usuario en STG», que es
escritura viva. **Dilo en cuanto se sepa**, para que liderazgo emita el GO correspondiente en vez de
descubrirlo a mitad del paso siguiente.

## 4. Cuando llegue la credencial

Ejecutas el GO **tal cual**, sin cambios: `POST /api/auth` → cookie → los GET en el orden del GO.
Y acredita `mode_before` **por comportamiento** antes de cambiar nada — es el único momento en que
puedes hacerlo, y sin ese dato el `PASS` posterior no distingue haber cambiado el modo de haberlo
encontrado ya cambiado.

Recuerda lo que ya te dije y sigue siendo la trampa principal: **el 403 del POST proactivo sale en
los dos modos**, así que no acredita el cambio; y cambiar la variable **no** afecta al despliegue
vivo, así que verifica efectivo y no declarado.

## 5. Mientras tanto

Todo intacto y `S1_DASHBOARD_MODE` sigue declarado `blocked`. No publiques `BLOCKED`: no ha habido
intento. Si el material tarda mucho, avisamos a liderazgo de que el paso está esperando material, que
es distinto de haber fallado.
