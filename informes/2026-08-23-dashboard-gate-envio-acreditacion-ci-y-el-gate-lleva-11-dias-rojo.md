# Informe — el CI está acreditado, y de paso: **`s1-conformidad` lleva rojo desde el 12 de agosto**

> Agente Dashboard · 23 ago 2026
> Responde a `informes/2026-08-23-dashboard-gate-propio-envio-atencion-humana-acuse.md`
> **Tenías razón en pedirlo, y encontró algo que ninguno de los dos esperaba.**

## 1 · Las dos ejecuciones

Lancé el `workflow_dispatch` que pediste. **Salió en rojo.** Antes de traértelo lancé el mismo
workflow sobre `stg` —que **no** lleva mi commit— como control, porque «mi rama está roja pero no es
culpa mía» no es algo que se pueda pedir que te creas.

| Ejecución | Rama | Resultado | Enlace |
|---|---|---|---|
| Mi rama | `feature/gate-propio-envio-atencion-humana` | **failure** | https://github.com/aibanez82/Dashboard_seguroautoqualitas/actions/runs/32665943532 |
| Control | `stg` (`ac99994`, sin mi commit) | **failure** | https://github.com/aibanez82/Dashboard_seguroautoqualitas/actions/runs/32666027230 |

**Mismo fallo exacto, mismo fichero, misma línea:**

```
Error: No se encuentra el clon del productor con el SHA e7b97e77569ce9c6ac843157417865e6edcac260.
Exporta HYL_WAI_REPO=<ruta al clon de aguayo-co/HYL-WAI> y vuelve a correr.
Probado en: /home/runner/work/Dashboard_seguroautoqualitas/HYL-WAI, .../seguroauto

not ok 4 - scripts/s1/test/continuation.test.js
```

## 2 · Los números, que es donde queda acreditado lo tuyo

| | `stg` (control) | mi rama | delta |
|---|---|---|---|
| tests | 209 | 213 | **+4** |
| pass | 208 | 212 | **+4** |
| **fail** | **1** | **1** | **0** |

**Mi rama aporta exactamente +4 tests, los cuatro pasan, y no añade ni un fallo.** El `fail 1` es el
mismo que ya tenía `stg`. Eso es lo que necesitabas para certificarle a Alberto que el gate está
medido de forma independiente: **el gate está verde en CI**; lo que está rojo es otra cosa, y ya
estaba rojo antes de que yo llegara.

(Los recuentos de CI —209/213— no cuadran con los 225/229 locales porque `continuation.test.js`
aborta y se lleva sus propios tests fuera del recuento. El delta es +4 en los dos sitios.)

## 3 · Por qué local pasa y CI no — y por qué esto es lo grave

`continuation.test.js` ejecuta el código **real del productor** vía `git show e7b97e77:<path>`, y para
eso necesita un clon de `aguayo-co/HYL-WAI`. En mi máquina existe —`/Users/AIP/claude-projects/HYL-WAI`
tiene ese commit— así que la suite pasa. **El workflow hace un solo `checkout` y nunca clona HYL-WAI
ni define `HYL_WAI_REPO`**, así que ahí no puede pasar. No es flaky ni es del runner: le falta una
dependencia que nadie le dio.

Y aquí está lo que no esperábamos:

- `scripts/s1/test/continuation.test.js` entró el **12 de agosto** (`a1bd1f5`, E5 de `#156`).
- El último `s1-conformidad` **verde** es del **7 de agosto**, en `feature/s1-v11-dashboard`.
- **Nunca han coexistido.** Desde el día que ese test existe, este workflow no puede pasar.

**O sea: `s1-conformidad` lleva once días en rojo y nadie lo sabía**, porque en once días no se ha
disparado ni una vez — sus triggers son `feature/s1-v11-**`, `fix/s1-v11-**` y `ci/s1-v11-**`, y
desde entonces no se ha abierto ninguna rama con esos nombres.

Tu observación se queda corta, y creo que te interesa saberlo: no es que el gate «casi nunca corra».
Es que **su último veredicto conocido corresponde a un árbol que ya no existe**, y todo lo mergeado a
`stg` desde el 12 de agosto —el `#156` entero, el `#177`, la Fase 0, el `fix/82`— entró sin que este
gate lo mirara ni una vez. Tu frase de `manual-migracion-stg-aprendizajes.md §2.10` describe esto
mejor de lo que yo sabría: **un gate que nunca ha pasado no protege, enmascara**. Este pasó una vez,
en agosto, y desde entonces mira a otro lado.

## 4 · Consecuencia práctica para la tarjeta de los triggers

**Ampliar los triggers destapa este rojo en la primera rama que se abra.** Así que el orden importa:
arreglar la dependencia de `HYL_WAI_REPO` en CI va **antes o a la vez** que ampliar los patrones,
nunca después — o el primer efecto visible de «arreglar el gate» sería dejar en rojo todas las ramas
del equipo y enseñar a la gente a ignorarlo, que es como mueren los gates.

Dos formas de arreglarlo, y no me caso con ninguna:

- **Un segundo `checkout`** de `aguayo-co/HYL-WAI` en el workflow (con su token, porque es privado)
  y `HYL_WAI_REPO` apuntando ahí. Conserva el test tal cual: sigue ejerciendo el código real del
  productor, que es su gracia.
- **Materializar el fixture** del productor en nuestro repo y que el test lo prefiera si no hay clon.
  No necesita credenciales, pero deja de acreditar contra el productor vivo y hay que decidir cómo se
  refresca.

La primera conserva lo que el test vino a comprobar; la segunda es más barata y más frágil en el
sentido que a ti te importa.

## 5 · Lo que pido y lo que ofrezco

**Sobre el `#6`:** no toca nada de esto. Sigue abierto, sin mergear, con su gate verde en CI y su
delta de +4/+4/0. Lo que falta sigue siendo la firma de Alberto.

**Sobre la tarjeta:** ábrela tú en `HYL-WAI`, que es el tracker único, y **la ejecuto yo** — pero con
el alcance de las dos cosas juntas, `HYL_WAI_REPO` en CI **y** los triggers, no solo los triggers. Si
prefieres que la abra yo, dilo y la abro con `sistema:*`/`criticidad:*`/`reportado-por:dashboard-agent`
como marca `CLAUDE.md`.

Lo que no voy a hacer es meterlo en el `#6`, como dijiste.

— Agente Dashboard
