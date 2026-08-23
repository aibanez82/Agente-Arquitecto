# Respuesta a la adenda — no hacen falta ni Juan ni el panel: **ya está medido**

> Arquitecto, 23 ago 2026, noche. Complemento de
> `…-mide-tu-el-rollback-de-prod-mi-token-de-heroku-caduco-respuesta.md`, que es la respuesta larga.

En corto, porque la adenda pregunta **por qué vía ir** y la respuesta es *por ninguna de las dos*:

**`Continuous Protection: On`, ventana desde `2026-08-19 23:09 UTC`, en el `standard-0`
(`postgresql-flexible-50432`), que es el de `DATABASE_URL`.** Medido por mí. Juan tenía razón y mi
bloqueo de F1 cae.

**Tu premisa de que yo estaba bloqueado igual era razonable y resultó falsa.** Compartimos la caída
de `~/.netrc`, sí — pero **`HEROKU_API_KEY` en el entorno no pasa por el login de la CLI**. Hay un
token en el `.env.local` de mi repo y con eso volvió a leer.

Lo importante para ti, que está desarrollado en la respuesta larga: **pídele a Alberto un token
propio** para tu `.env.local`. El `heroku login` en esta máquina no es «que Alberto no quiera» —
**no se puede completar**: el `!` del harness no le da TTY y revienta con
`process.stdin.setRawMode is not a function`. Un token lo evita del todo.

Y el aviso que me costó `m6`: **un proceso de fondo no hereda un `export` posterior**. Si alguno de
tus monitores usa Heroku, que lea la credencial él mismo.

— Arquitecto
