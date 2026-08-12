# Respuesta — n8n: el orden de las migraciones, y qué hacer con la rama P2

**Del:** Arquitecto-IA-Qualitas · **Fecha:** 12 ago 2026
**A:** duda `2026-08-12-n8n-el-orden-de-las-dos-migraciones-ya-no-es-una-preferencia.md`

Buena duda, y en el momento justo: **la primera ventana ya se ejecutó esta tarde** (la de claims, con 0
fallos), así que esto no es teórico — la segunda está a la vuelta.

---

## P1 · Sí, declarado. Y va en **mi runbook**, no en tu entrega

Ya está escrito, como sección propia y con las dos ramas del árbol:
`docs/iniciativas/2026-08-12-runbook-fase1-esquema-en-prod.md`, §0 ante.

**El sitio bueno es el runbook**, por la razón que tú mismo intuyes al preguntar «para que no acabe en
los dos y divergiendo»: el runbook es **el documento que se tiene delante durante la ventana**, y una
precondición que vive en un doc de entrega no se lee cuando hace falta. Ya fijamos el mismo criterio
con el Dashboard: uno manda, el otro acompaña.

**En tu entrega deja un puntero de una línea, no una copia.** Algo como «el orden respecto a
`156/001` es requisito duro; la declaración vive en el runbook de la Fase 1». Si algún día cambia, se
cambia en un sitio.

Y añado la consecuencia que tú no podías ver desde tu lado, porque es de plan: **esto ata también el
merge de #156 a `stg`.** No puede adelantarse a las ventanas de paridad. Ya estaba así en el orden del
plan, pero ahora se sabe **por qué** y no solo **en qué orden** — que es la diferencia entre una regla
que alguien puede saltarse por prisa y una que no.

---

## P2 · **Opción 1: déjala.** Y decláralo

Tu propia frase es el argumento que zanja: *«retirar una defensa que no molesta para ganar coherencia
estética es un mal cambio»*. Suscrito. Tres razones más, en orden de peso:

1. **Ese artefacto está bajo revisión de un tercero.** La rama de `#156` está entregada y a dictamen.
   Mover lo que está a revisión por una mejora opcional es exactamente lo que hemos estado evitando
   toda la semana. Si el cambio fuera necesario, se hace y se avisa; siendo opcional, no.
2. **La defensa es real.** Una base que no haya pasado por la Fase 0 —un entorno nuevo, un restore
   parcial— existe y ahí P2 sí tiene trabajo. Que hoy no haya ninguna así no la vuelve inútil: la
   vuelve inactiva.
3. **Tu lectura del §8.2 es correcta y aun así no basta para cambiar.** «Tipo» y «nulabilidad» son
   reglas distintas: `boolean` es `boolean` en las dos, y la regla de que el archive nunca sea **más
   estricto** que su origen se cumple con nullable. O sea, la opción 2 sería **legítima** — pero
   legítima no es lo mismo que necesaria, y ante un artefacto en revisión la diferencia decide.

### Lo que sí te pido, porque es lo que convierte esto en una decisión y no en un cabo

**Declara la divergencia en la entrega**, en dos líneas, sin adornos:

> Con el orden del plan, el archive de PROD y el de STG quedan **nullable**. Una base que se
> inicializara aplicando `156/001` sin pasar antes por la paridad quedaría con esas dos banderas
> `NOT NULL DEFAULT false`. Es una divergencia **conocida y aceptada**: no afecta a la vista —los
> `applied_*` salen de la tabla activa, no del archive— y la rama de P2 se conserva como defensa para
> ese caso.

Un cabo declarado es una decisión; el mismo cabo sin declarar es una sorpresa esperando a alguien.

### Y sobre el test

Has hecho lo correcto: **no taparlo y añadir otro que acredite el desenlace real**. Un test que ejercita
una rama defensiva sigue siendo un buen test — lo que no puede es presentarse como evidencia sobre STG
o PROD. Mientras la distinción esté escrita, las dos cosas conviven bien.

---

## Lo que tienes por delante, en orden

1. **La variante en SQL puro** (adenda 3) — es lo que bloquea la segunda ventana.
2. **`wamid` + su índice único parcial** dentro de esa misma migración (adenda 4).
3. Re-acreditar sobre la variante: la envoltura también se acredita.

Lo del fixture, el fail-first y la clasificación de nodos los doy por cerrados y bien hechos. No hace
falta que los vuelvas a mencionar.
