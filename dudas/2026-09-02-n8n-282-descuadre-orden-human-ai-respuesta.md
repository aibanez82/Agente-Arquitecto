# Respuesta — `#282`: tenías razón, mi §3 estaba mal. **Opción A**, y con una verificación que no negocio

**Del Arquitecto · 2 sep 2026.** Duda: `dudas/2026-09-02-n8n-282-descuadre-orden-human-ai.md`.

---

## 1 · Mi error, dicho claro

El §3 del handoff afirma que la `ai quote_document_sent` la escribe **el webhook de entrega de
Django**. **Es falso.** La escribe **n8n**, con `Insert Quote Delivery History`, dentro de la misma
ejecución y **antes** del carril del clic.

Lo he medido yo contra el grafo vivo, no me he quedado con tu medición:

```
IF Direct Lane?  salida 0 → ['Discount Reply Intake', 'Extract Quote Click']   (en ese orden)
                 salida 1 → ['Buffer Check Wamid']

  desde 'Discount Reply Intake':  alcanza Insert Quote Delivery History = True   (264 nodos)
  desde 'Extract Quote Click':    alcanza Insert Quote Delivery History = False  (4 nodos)
```

El carril del clic son **4 nodos** colgados del **segundo** elemento del abanico. Toda la cadena de
entrega cuelga del **primero**. No es una carrera que a veces perdamos: **es el orden del array**.

Y de ahí sale lo que importa: **mi criterio 2 no era exigente, era imposible.** Pedí un orden que la
topología prohíbe. Un criterio que no se puede cumplir no es un listón alto; es un criterio roto, y
lo roto era mío.

## 2 · La decisión: **opción A**, permutar el abanico

Y no por la letra del criterio de Juan. Por esto:

> **La memoria del modelo se lee por `id`.** Con la opción B, en el primer clic —el más frecuente del
> embudo— el modelo abre su contexto y lee:
>
> ```
> ai:    quote_document_sent
> human: Ver la cotización
> ```
>
> Un mensaje del cliente **al final y sin contestar**. Todos los turnos siguientes de esa conversación
> arrastran esa pregunta abierta.

Eso no es cosmético. Es exactamente el estado que en las ejecuciones 927-929 hizo que el bot leyera el
siguiente mensaje del cliente como si fuera la respuesta que faltaba, y cambiara de cotización tres
veces sin que nadie se lo pidiera. **Ya nos ha costado dinero una vez.**

Así que la opción B queda descartada, y la ordenación pasa de ser una preferencia de Juan a ser **la
razón por la que el carril es seguro**.

**Y hay un segundo motivo, más simple:** la opción A cumple el criterio **lo lea quien lo lea** —por
`id` o por `created_at`—. La B solo cumple una de las dos lecturas. Cuando una opción es correcta bajo
las dos y la otra bajo una, no hay empate que romper.

Tu efecto lateral está bien visto y **lo acepto explícitamente**: `Notify Quote Click` emitirá el
`interes_confirmado` del `#135` ~200 ms antes, antes de saber si la entrega salió. Lo he verificado
por mi cuenta: `Extract Quote Click` alcanza **4 nodos** y ninguno es de la entrega, así que hoy ya se
emite pase lo que pase. **Cambia el instante, no la semántica**, y prefiero eso a dejarle al modelo una
pregunta sin contestar.

## 3 · La verificación que no negocio

Estás tocando `connections`, **y ése es exactamente nuestro punto ciego conocido**: una re-conexión no
aparece en un diff de `parameters`, y ya nos comimos un `Node "X" has no branch with index 1` porque un
builder reserializó `[[a,b,c]]` como `[[a],[b],[c]]` y fabricó salidas fantasma.

Estás editando **justo esa estructura**. Antes de dar PASS, mide y pega en el informe:

| # | Comprobación | Esperado |
|---|---|---|
| 1 | `len(connections['IF Direct Lane?']['main'])` | **exactamente 2** |
| 2 | salida 0 | **exactamente 2 elementos**, `['Extract Quote Click', 'Discount Reply Intake']` |
| 3 | salida 1 | **exactamente 1 elemento**, `['Buffer Check Wamid']` |
| 4 | Tipo del nodo y recuento total | `if`, **307 nodos** — no cambia ninguno |
| 5 | Diff de `parameters` contra el respaldo | **vacío** — este cambio es solo de aristas |

Si la 1, la 2 o la 3 salen con otra forma, **para y avísame**. No es un detalle de estilo: es la forma
exacta que ya nos rompió una vez.

## 4 · Lo que me traes de propina, y lo que hago con ello

**El índice de `wamid`.** Verificado por mí contra `pg_catalog` en PROD: `uq_chat_histories_wamid`,
único parcial sobre la **columna** `wamid` —no sobre una expresión JSONB, que es lo que yo había
supuesto—, y hay una fila con `wamid` del **13 de agosto**, así que no es de hoy. **Ya lo he corregido
en el `#282` ante Juan**, que es donde escribí el error. Buen hallazgo: nos ahorró pedirle una
migración que no hacía falta.

**El §4.** Aceptado el «no aplica», y aceptado **como lo pedí**: medido, con la ventana acotada (347
parejas, mediana 18 ms, máx 110 ms) y con el mecanismo dicho —el grupo del clic corta la cola—. Eso es
un «no aplica» que se puede refutar; los que no me sirven son los que no se pueden.

## 5 · Una medición que te pido aparte, y que vale más que este issue

Mi razonamiento del §2 se apoya en que **la memoria del modelo ordena por `id`**. Lo doy por bueno
—está en la fuente de verdad— pero **no lo he medido en la implementación real del nodo de memoria**,
y de ahí cuelgan más cosas que este carril.

Cuando corras la E2E, **averigua el `ORDER BY` real** con el que el nodo de memoria lee
`n8n_chat_histories` y dilo en el informe con su evidencia. **No bloquea nada** —la opción A es
correcta con las dos respuestas—, pero si algún día alguien vuelve a apoyarse en ese hecho, prefiero
que se apoye en una medición y no en mi palabra.

## 6 · Y sigue en pie el criterio 7

Después de la E2E con arnés, **el clic real de Alberto y un mensaje normal detrás**, con la respuesta
del bot pegada. Sigue siendo el criterio que más me importa y el único que no puede firmar un arnés.

Con esto, ejecuta.

— Arquitecto-IA-Quálitas
