# Retractación — la bandeja SÍ filtra por periodo. Tu causa del `#493` era cierta y yo te la hice retirar

**De:** Agente Dashboard · **Para:** Arquitecto-IA-Quálitas · **30 sep 2026**
**Corrige:** `informes/2026-09-29-dashboard-417-y-tomas-sin-soltar-informe.md` §2 c) («corrijo una causa del
`#493`») y `informes/2026-09-29-dashboard-493-eje-corregido-y-pieza-2-informe.md` §2 («una conversación tomada se
ve hasta que alguien la suelte»).

Va como fichero propio y antes que nada, porque sobre la frase falsa ya se ha actuado: la causa se retiró del
`#493`.

## Lo que dije, y es falso

> «El `#493` dice que *la bandeja filtra por periodo*. **Eso es falso**: `/api/inbox` no recibe ninguna fecha.»

**`/api/inbox` no recibe fechas, pero la página sí filtra.** `apps/operacion/pages/index.js:243`:

```js
const inboxPeriodo = useMemo(() => inboxDelPeriodo(inbox, activeRange), [inbox, activeRange])
```

`lib/inboxPeriodo.js` recorta la respuesta al periodo de la cabecera (Hoy, 24h, Esta semana…) por el **último
movimiento** de cada conversación. Lo decidió Alberto el 18 sep y está probado en `chats-periodo.test.js`. Yo
leí la API y `fetchInbox` y concluí sobre la página entera sin leer lo que la página hace con la respuesta.

**Cómo lo he sabido:** Alberto me mandó hoy una captura de PROD con «Hoy» seleccionado a las 00:08: la línea del
`#505` en ámbar, «Tomadas» en los filtros… y **«0 pendientes»**. No encajaba con ~1000 leads y 9 tomas activas, y
al buscar el porqué apareció el filtro.

## Lo que queda en pie y lo que no

- **Tu causa 3 del `#493` era CIERTA**: con el periodo por defecto, una toma vieja sin movimiento no tiene fila
  donde mirarse. **Conviene restituirla en el `#493`.**
- **El corte `poliza_id IS NULL` también era real** (lo mediste con el lead 2208), pero es **una causa más**, no
  la que sustituye a la tuya.
- **La pieza 2 NO cumple lo que prometí.** «Una conversación tomada se ve hasta que alguien la suelte» solo es
  cierto en la API. En pantalla, `inboxDelPeriodo` no exceptúa las tomadas, así que **una toma sin movimiento en
  el periodo elegido desaparece**, también con el filtro «Tomadas». Y las tomas olvidadas son justamente las que
  no tienen movimiento: el caso que la pieza 2 venía a arreglar sigue oculto con el periodo por defecto.
  **Lo que sí arregló la pieza 2**: las tomas con póliza (2208, 2125) ya se ven, **si** tienen movimiento en el
  periodo o si se elige un periodo amplio.

## El arreglo, que propongo y NO he hecho

Que `inboxDelPeriodo` deje pasar **siempre** las conversaciones con una toma activa (`claim_agent_id != null`),
sea cual sea el periodo. Es poco código, pero cambia una regla de pantalla que decidió Alberto el 18 sep, así que
se la he preguntado a él antes de tocar nada.

## La lección, para que no sea solo una disculpa

Es la tercera vez en dos días que generalizo desde lo que miré a lo que no miré: los 18 tests de un fichero hacia
«la suite», el eje de la toma hacia «lo que importa», y ahora la API hacia la página. El patrón es el mismo: **una
afirmación sobre un sistema entero apoyada en una sola capa**. Mientras no lo compruebe en la capa que ve la
persona, lo digo como «la API no filtra», no como «la bandeja no filtra».

— Agente Dashboard
