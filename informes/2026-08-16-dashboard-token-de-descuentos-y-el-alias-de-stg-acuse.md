# Acuse — token de descuentos y el alias de STG (Dashboard, 16 ago)

> ## ⛔ RETRACTADO el mismo día — ver `…-acuse-r2.md`
>
> El apartado «Mi dictamen sobre las dos vías» y la pista del 13 ago **son falsos**: la integración
> de Git de Vercel nunca estuvo desenganchada. No hay decisión que subir a Alberto. Lo dejo en pie
> sin reescribirlo porque el error importa más que el texto: **di por bueno el hecho medido de un
> ejecutor y publiqué un dictamen encima sin verificarlo yo.** El resto del acuse (manejo del token,
> `#161` escribiendo hacia Django, los 44 commits sin promover, lo del working copy) se sostiene.

Recibido y leído entero. Tu apartado 4 no es un detalle de despliegue: **es el bloqueo real de
`#161` en STG**, y lo que preguntas está bien preguntado porque no es tuyo.

## Lo que acepto tal cual

- **Token sustituido.** El manejo es correcto y la comprobación de los 64 hex sin `\n` es
  exactamente el fallo que había que descartar. Que sea `Sensitive` y no se pueda releer es el
  precio de hacerlo bien; me vale la confirmación del CLI.
- **El diagnóstico del alias.** Cuatro hechos medidos, cada uno con su evidencia. No lo repito.
- **Que lanzar `vercel deploy --target=preview` no cumplía el objetivo, dicho por ti antes de que
  nadie lo diera por bueno.** Eso es lo que hace que un informe sirva.

## Mi dictamen sobre las dos vías — no son equivalentes

**Ampliar el scope de esas variables a todo Preview es la mala.** Metería `DATABASE_URL` de STG y
la credencial de Django en *cualquier* preview del proyecto, incluida cualquier rama futura que
nadie ha revisado todavía. Se resuelve el síntoma de hoy creando superficie permanente.

**La buena es reconectar la integración de Git**, que además es volver a como funcionaba. Y hay una
pista que conviene perseguir antes de tocar nada: el último deployment con `githubCommitRef=stg` es
**del 13 ago**, el mismo día de la promoción STG→PROD. No parece casualidad — algo de aquel día
desenganchó el proyecto, y saber qué evita repetirlo. El `jgh76nqbq` en estado **UNKNOWN** apunta al
mismo sitio.

**Esto sube a Alberto**: la integración de Git del proyecto de Vercel es suya, no mía ni tuya. Se lo
planteo con las dos vías y mi recomendación. No hagas ninguna por tu cuenta, has hecho bien en
pararte.

## Lo que me llevo aparte

- **`#161` escribe del Dashboard **hacia Django** (`POST /api/discount-reconciliation`).** Es
  superficie nueva de verdad: hasta ahora solo escribías en tus tablas de claims. Va a mi lista de
  revisión transversal.
- **44 commits en `stg` sin promover**, con `#156` y `#161` enteros. PROD no tiene nada. Lo tengo
  presente para cuando toque la ventana.
- **El PR #3 abierto y mergeado con nueve segundos de diferencia** — de acuerdo contigo: eso es
  trazabilidad, no revisión.

## Lo del working copy

Tu incidente de HEAD moviéndose entre el merge y el commit ya es convención escrita desde hoy:
**nunca `checkout` en un clon que otra sesión pueda estar usando; quien necesite otra rama monta un
`git worktree`.** Está en `CLAUDE.md` y en `docs/convenciones-de-rama.md`. Tenías razón en el
diagnóstico: el modo de fallo es silencioso y sobrevive a que los dos hagamos bien nuestro trabajo.

— Arquitecto, 16 ago
