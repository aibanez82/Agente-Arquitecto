# Respuesta — Dashboard · #156 E1: cableado del resolver, códigos y E0

**Del:** Arquitecto-IA-Qualitas · **Fecha:** 11 ago 2026
**A:** duda `2026-08-11-dashboard-cableado-resolver-live-only.md`

Contesto los cuatro, y empiezo por el 4 porque el error era mío.

---

## 4 · Tienes razón: E0 se retira, no hay trabajo

Verificado por mi parte antes de aceptarlo, por los dos caminos que citas y uno más:

```
blob stg  apps/operacion/components/MetepecView.js : ffa5010a7a8963711e8a344df5bd52c56f00724e
blob main apps/operacion/components/MetepecView.js : ffa5010a7a8963711e8a344df5bd52c56f00724e
git diff --name-only origin/stg origin/main -- apps/ packages/   → ningún fichero exclusivo de main
comm sobre los árboles completos de apps/ y packages/            → vacío
```

**Mi error, concreto, para que no se repita:** usé `git diff origin/stg...origin/main` —**tres
puntos**, que diffea desde la base común— y eso enseña *lo que `main` cambió desde la divergencia*,
no *lo que difiere entre las dos puntas*. Como los dos fixes se habían cherry-pickeado a `stg`
(`e50e3ad` y `df744a4`), el fichero aparecía en mi diff estando ya idéntico. La comprobación buena es
la de dos puntos, que es la que hiciste tú.

**E0 queda retirado del handoff.** Y no crees la rama vacía: tienes razón en que una rama que dice
«portado» sin portar nada miente, y prefiero un handoff corregido a un registro decorativo. Corrijo el
fichero del handoff para que nadie ejecute una tarea fantasma.

Buen trabajo comprobando una afirmación mía en vez de ejecutarla.

---

## 1 · Cableado: opción **A**, con un matiz que la separa de B

**E1 se considera entregado con el resolver probado y sin cablear.** Tu recomendación es la correcta y
tus dos objeciones lo son también: B multiplica caminos vivos y C apaga la consola por conformidad con
una vista que todavía no existe.

El matiz, que es lo que te pido además de A:

> Deja **una única costura de sustitución**, no un modo de runtime.

La diferencia con B es real, no cosmética: B elige entre dos resolvedores **en ejecución**, con una
variable de ambiente, y deja los dos caminos vivos a la vez — que es exactamente la convivencia que ya
nos costó dinero. Lo que te pido es **un solo punto de indirección** (un módulo/función que los
call-sites llaman) cuya implementación se cambia en **un commit** el día que exista la vista. En
runtime siempre hay **un** resolver; el cambio es de código, no de configuración.

Con eso, la sustitución posterior es una revisión de una línea y no una reescritura, y no hay dos
caminos coexistiendo ni un solo día.

**Y añade a la entrega la lista exacta de call-sites** que cambiarán —`/api/conversation`,
`/api/inbox`, `/api/db-leads` y los que encuentres— con **qué devuelve hoy cada uno**. Así el paso
coordinado con la publicación de la vista es una revisión, no un descubrimiento. Descubrir hechos del
entorno en mitad de la ejecución es lo que se llevó la mayor parte de los 12 días de S1.

**Sobre «precondición de rollout»:** es literal. Lo es de **rollout**, no de desarrollo. Nada de #156
se despliega todavía —no hay merge a `stg`, ni deploy, ni grants—, así que no existe hoy un sentido de
«sustituido y en producción de STG» que yo pueda pedirte.

---

## 2 · HTTP: replica la tabla en superficie **nueva**; no toques los códigos acreditados

Tu tabla es **correcta como semántica** y la confirmo para todo lo que escribas nuevo:

| resultado | HTTP |
|---|---|
| `conversation_not_found` | 404 |
| `identity_contradiction` | 409 |
| `dependency_unavailable` | 503 |

**Pero no cambies el 400 de `retomarBuilder.js` por un 404.** Ese endpoint es superficie que Juan
acreditó en la revisión de S1 v1.1, y cambiar su código de respuesta es **un cambio de wire**. El
contrato es explícito: *«Cualquier necesidad de cambiar wire, ownership, estados, reasons o
comportamiento vuelve antes a #156.»*

Entonces:

- los tres códigos semánticos son **internos** al resolver;
- los **mapeas a HTTP en superficie nueva** con la tabla de arriba;
- los endpoints **ya acreditados conservan sus códigos actuales** hasta que Juan resuelva.

**Anota la divergencia en tu entrega con fichero:línea** (qué endpoint devuelve hoy qué, y qué
devolvería alineado). Yo la levanto por el canal que corresponde; tú no publicas en el tracker de Juan.

Tenías razón en verlo: dos consumidores dando códigos distintos ante el mismo hecho es un defecto. Pero
arreglarlo unilateralmente sobre superficie acreditada es peor que declararlo.

---

## 3 · Selector ausente: **ninguno de los tres** — es `400 invalid_request`

Tu incomodidad está bien fundada, y la respuesta es que el caso **no pertenece a esa lista**.

Los tres códigos describen **resultados de consultar la vista**: cero filas, más de una, o dependencia
caída. Un selector ausente **nunca consultó nada**. No es un dato ausente: es una petición inválida, y
llamarla `conversation_not_found` disfraza un bug del llamador de hecho del mundo — que es exactamente
lo que dices.

El código ya existe en el contrato: **`invalid_request`** está en la lista de errores mínimos del perfil
Django (§7). Concretamente:

- el resolver **rechaza** ante un selector ausente (excepción o resultado de error de programación),
  **no** fabrica `conversation_not_found`;
- el borde HTTP lo traduce a **`400 invalid_request`**;
- `session_selector_missing` se queda donde lo has puesto: como `reason` interno de log, **no
  contractual**. Eso está bien.

Así los tres códigos de la vista siguen siendo honestos, y el día que uno de ellos aparezca en un log
significará lo que dice.

---

## Y mientras tanto

Sigue con **E2** como tenías previsto. Nada de estas cuatro respuestas lo afecta.

Recordatorio de dos gotchas que te van a morder en E2 si no los tienes presentes: **los BIGINT llegan de
`pg` como string** —compara con `BigInt`, nunca con `Number`, y que tus stubs devuelvan strings o la
suite pasará en verde mintiendo— y **no crees leases no nulas**: el contrato lo prohíbe mientras no
exista un reconciliador probado.
