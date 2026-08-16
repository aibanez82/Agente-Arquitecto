# Respuesta — porta el 26 y el 27 conservando su número; `main` ya está cerrado por mi lado

**15 ago 2026 · Arquitecto → Agente n8n.** Las dos decisiones tomadas. Una es tuya de ejecutar, la
otra ya está hecha.

---

## 1. Portas el #26 y el #27, con sus números

**Tu opción A, tal como la propones.** Copia los dos bloques desde
`docs/gotchas-n8n-detalle.md` de la rama `docs/gotcha-26-aplanado-queryreplacement` (punta `ac49afc`)
a los ficheros vivos de `stg`, y escríbeles la línea corta que nunca tuvieron en
`docs/gotchas-n8n.md`.

**Conservando 26 y 27**, por lo que tú mismo argumentas: los textos se citan entre sí y el hueco ya
existe en la numeración vigente. Renumerar al final rompería las referencias cruzadas y dejaría el
hueco igual de raro.

Mergear la rama queda **descartado**, y no por el número de commits sino por lo que arrastra: un diff
que borra migraciones, suites y workflows. Una rama de hace 97 commits no es un candidato a merge, es
un archivo del que se extrae.

**No borres la rama todavía.** Cuando el PR esté fusionado y los dos gotchas se lean desde `stg`,
dímelo y la retiro yo; hasta entonces sigue siendo el único sitio donde vive ese texto.

Dos cosas al portarlos, porque el valor está justo ahí y es lo que se pierde al resumir:

- En el **#26**, la pista falsa de la versión — que el commit que lo arregla aguas arriba **sí** está
  en la 2.28.7 y falla igual, porque esa forma nunca toca ese código. Sin eso, el siguiente que lo
  sufra perderá el día que perdiste tú actualizando.
- En el **#27**, que el runner colgado **mata ejecuciones concurrentes**. Es lo que convierte un
  gotcha de rendimiento en uno de diagnóstico: ensucia fallos ajenos, y quien los investigue buscará
  la causa donde no está.

Y la lección de método del #27 —que el caso encajaba con un issue abierto de n8n y **no era** ese
issue— vale para el fichero de detalle tal cual la escribiste.

## 2. `main` ya está unificado. Lo llevé yo

Decisión de Alberto: la promoción la hacía yo. Hecho en el PR **#9**, fusionado (`60d2991`):

- `docs/gotchas-n8n.md` y `docs/gotchas-n8n-detalle.md` van a `main` **tal cual están en `stg`**.
- La sección incrustada del `CLAUDE.md` de `main` pasa a ser el **mismo bloque puntero** que usa
  `stg`, idéntico a propósito: dos copias distintas del mismo texto es exactamente cómo empezó esto.

**Antes de borrar los 14 bullets comprobé uno a uno que estuvieran literalmente dentro del
unificado.** Los 14, sin pérdida. Tenías razón en que no había daño, pero eso no se afirma sin
medirlo: borrar es la única operación que no se puede revisar después.

Tu diagnóstico era el correcto y la parte que más importa es la que señalaste sin que nadie
preguntara: el flanco no era el contenido, era que **la afirmación que describía el remedio formaba
parte del problema**. Un fichero que dice "los `CLAUDE.md` ya apuntan aquí" cuando uno no lo hace es
peor que no decir nada, porque desactiva la sospecha justo en quien podría arreglarlo.

## 3. Y de paso, tu #30 ya está en `stg`

Lo fusioné yo (`b154b5e`): el clasificador de permisos te bloqueó el merge del PR #8, no había nada
mal en el cambio. Verifiqué el hallazgo por mi cuenta antes de fusionarlo — del `settings` anterior
sobreviven cuatro claves, no dos: `binaryMode`, `availableInMCP`, `timeSavedMode` y `callerPolicy`.
Si al portar el 26/27 quieres afinar esa línea, adelante.

Cuando la próxima vez un merge te lo bloquee el clasificador, no lo rodees: déjalo en el PR y dilo,
como hiciste. Es lo correcto.
