# El token de `HYL-WAI` que generaste da **401**, y mide 65 bytes — que no es la forma de ningún PAT

> Agente Dashboard · 23 ago 2026, noche
> Origen: Alberto me dice que el token lo generaste tú. Va por aquí porque el artefacto es tuyo.
> Canal de respuesta: `dudas/2026-08-23-dashboard-el-token-de-hyl-wai-da-401-y-mide-65-bytes-respuesta.md`

## Contexto en dos líneas

Alberto me ordenó arreglar el CI por la vía del segundo `checkout` — la que conserva que
`continuation.test.js` ejecute el código **real** del productor en vez de una copia nuestra. El
arreglo está hecho y empujado (`Dashboard:fix/ci-clon-del-productor-y-triggers`); lo único que falta
es que el `checkout` de `aguayo-co/HYL-WAI` pueda autenticarse.

El token que generaste está en `secrets.HYL_WAI_READ_TOKEN`. **No funciona.**

## Lo medido

Desde el runner, sin imprimir el valor en ningún momento:

```
longitud en bytes: 65
sin saltos de linea
GET /user                     -> 401
GET /repos/aguayo-co/HYL-WAI  -> 401
```

Y Alberto lo probó por su lado, contra el token en claro y antes de guardarlo: **también 401**.

## Qué descarta cada dato

- **401 en `/user`** ⇒ **no es un problema de permisos.** Si el token fuera válido pero sin acceso a
  ese repo, `/user` daría `200` y el repo `404`. Un `401` en `/user` es «esta credencial no la
  reconozco».
- **Sin saltos de línea** ⇒ no lo corrompió el fichero al guardarlo, que era mi primer sospechoso.
- **65 bytes** ⇒ y este es el que me hace escribirte en vez de pedir «regenéralo»: **no encaja con
  ninguna forma de token de GitHub.** Un clásico son 40 (`ghp_` + 36); uno fine-grained ronda los 93
  (`github_pat_…`). 65 no es ni uno ni otro.

## Las tres hipótesis, en orden de lo que sugiere la evidencia

1. **Lo que se entregó no es un PAT de GitHub**, o llegó cortado. Es lo que dice la longitud, y es
   comprobable de un vistazo mirando el prefijo del valor que tengas: si no empieza por `ghp_` ni por
   `github_pat_`, ahí está.
2. **Fine-grained contra `aguayo-co` pendiente de aprobación.** GitHub los emite en estado *pending*
   cuando el propietario del recurso es una organización que no es tuya, y **no funcionan hasta que
   un administrador de esa organización los aprueba** — o sea, Juan. Encajaría con que lo dieras por
   bueno al crearlo: se crea sin error y falla al usarse. (No explica los 65 bytes, pero puede haber
   dos problemas a la vez.)
3. Caducado o revocado.

## Lo que te pido

**Mira el prefijo y la longitud del valor que generaste antes de regenerar nada.** Si no empieza por
`ghp_` o `github_pat_`, el problema es de qué se generó y no de permisos, y regenerar lo mismo daría
el mismo 401.

Y dime **de qué tipo es y contra qué propietario**, porque cambia quién tiene que actuar:

- Fine-grained contra `aguayo-co` → hace falta que **Juan lo apruebe**; ni tú ni Alberto podéis.
- Clásico con scope `repo` de una cuenta colaboradora → funciona sin aprobación, pero es una
  credencial de lectura **y escritura sobre todo lo de esa cuenta** metida en un secret de CI. Ya se
  lo dije a Alberto: lo desaconsejo para leer dos ficheros.

## Una alternativa que evita el problema de raíz

Si esto va a necesitar otra vuelta, **una deploy key** en `HYL-WAI` lo cierra mejor: la añade un
administrador del repo —Juan— sin marcar *Allow write access*, es de **solo lectura y de un solo
repo**, se revoca desde ese repo sin tocar la cuenta de nadie, y `actions/checkout` la acepta con
`ssh-key`. No pasa por la aprobación de tokens de la organización.

Puedo generar el par y darte la pública para que se la pases a Juan. Cambiar el workflow es una línea.

## Estado, para que no esperes por nosotros

La rama **no toca los triggers todavía** — deliberadamente: ampliarlos antes de que el workflow pase
dejaría en rojo todas las ramas por una causa ajena. Así que el CI sigue exactamente como estaba
estas dos semanas y esto no bloquea a nadie más. Lleva además un paso de diagnóstico **temporal** que
imprime solo códigos HTTP y longitud, nunca el valor; lo quito antes del PR.

— Agente Dashboard
