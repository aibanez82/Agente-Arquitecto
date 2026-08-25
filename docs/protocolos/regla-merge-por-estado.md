# Quién dispara un merge — regla por estado de la rama

> **Fuente única del ecosistema.** Vive aquí, en `Agente-Arquitecto`, y **no se copia a los repos
> de los ejecutores**: ellos la referencian con un puntero de una línea. Decisión de Alberto,
> 24 ago 2026, al ver que la primera redacción quedó escrita solo en `Agente-n8n` y dejó al
> Dashboard sin saber si podía fusionar.
>
> Se copia = diverge. Nos pasó el mismo día con las dos copias de `detect-drift.py`, que hicieron
> que el Arquitecto midiera contra la equivocada y sacara una conclusión falsa. Una regla de
> gobernanza duplicada en cuatro sitios tiene cuatro versiones, y la que alguien lea será la falsa.

## La regla

**1. Por defecto, cada ejecutor fusiona el `stg` de su propio repositorio, por criterio.** Con dos
condiciones duras:

- **(a) Suite en verde** — o en rojo **solo** si el defecto que lo explica cumple las tres:
  es **anterior al cambio y ajeno a él**; se dice **contra qué se comprobó** esa anterioridad (SHA,
  run o medición); y lleva **fecha de resolución o dueño**. *Un rojo sin fecha deja de ser un
  pendiente y pasa a ser paisaje.*
- **(b) El merge relatado** en el informe o el chat del día.

La autonomía es del repo propio. **`main` y los repos ajenos son siempre de Alberto.**

**2. Excepción: la rama bajo revisión o acreditación declarada.** Cuando `stg` es un SHA a
dictamen, tiene una ventana de firma abierta, o está bajo congelación declarada por Alberto o el
Arquitecto → **ningún merge sin orden escrita de Alberto**, registrada donde la orden exista.

Es lo que enseña `HYL-WAI#179`: aquel merge necesitó orden **no** por ser el `stg` de un ejecutor,
sino porque `stg` era entonces un artefacto auditado y moverlo invalidaba lo firmado.

**3. El estado se declara, no se infiere — y la declaración vive en `handoffs/` o en el issue,
nunca en un chat.** La ventana empieza cuando su declaración escrita existe en uno de esos dos
sitios, con fecha de inicio, y termina cuando ahí mismo se escribe que terminó. **Mientras no esté
escrita ahí, no hay ventana.** Un anuncio hablado se convierte en nota de memoria, y la nota se
invierte: es el mecanismo exacto que produjo la «Regla 1» falsa del 24 ago.

**4. Esta regla vale porque está escrita aquí, con fecha y fuente** — no en la memoria de nadie.
Cambiarla es cambiar **este** fichero. Una nota de memoria que la contradiga pierde contra este
texto, siempre.

## Repos compartidos: la regla del 18 ago sigue entera

En **`aguayo-co/HYL-WAI`** y en cualquier repo con más de un desarrollador, **el merge lo dispara
Alberto**, para `stg` y para `main`. El handoff fija el **destino**, nunca el **momento**.

El motivo no es control, es **coste ajeno**: Juan trabaja en paralelo con ramas sacadas de `stg`, así
que cada merge le deja la base vieja y le obliga a rebasar. Quién paga ese coste y cuándo lo decide
Alberto. Y cuando el merge entre, **avisar a Juan es parte del trabajo**: el SHA nuevo de
`origin/stg` y que sus ramas necesitan rebase.

## Por qué existió la ambigüedad, para no repetirla

La redacción del 18 ago decía «el merge lo dispara Alberto» **para todo**, con un motivo —el rebase
de Juan— que **solo aplica a su repo**. Texto universal, motivo particular. Quien lo leyera de buena
fe podía quedarse con el motivo, y no tenía contra qué chocar: nunca se escribió si valía para los
repos de los ejecutores.

El 24 ago eso produjo cuatro merges hechos por criterio sobre una nota de memoria que decía lo
**contrario** de su fuente. No se revirtieron —eran técnicamente buenos y deshacerlos añadía riesgo
sin recuperar nada—; se arregló la fuente.

**La lección que sobrevive a esta regla concreta:** *una regla cuyo texto es más amplio que su
motivo está rota aunque nadie la incumpla todavía.* Escribir el ámbito junto a la regla, no solo el
porqué.

## Cómo la referencian los repos de los ejecutores

Una línea en su `docs/convenciones-de-rama.md` (o equivalente), **sin copiar el contenido**:

```markdown
> **Quién dispara un merge:** la regla es la de
> `aibanez82/Agente-Arquitecto:docs/protocolos/regla-merge-por-estado.md`.
> No se copia aquí: una copia diverge y la que se lea será la falsa.
```
