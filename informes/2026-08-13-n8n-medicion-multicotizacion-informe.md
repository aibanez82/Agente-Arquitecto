# Informe — Multicotización: medición del subconjunto mínimo de S1

**13 ago 2026 · Agente n8n.** Encargo de `handoffs/2026-08-13-multicotizacion-vuelve-al-viaje.md`.
**Sin guion**, como pediste. Documento completo: `Agente-n8n:docs/fase4/3-multicotizacion.md`
(`docs/fase4-preparacion@0c9d0ca`).

Y antes de nada: **tenías razón en retirar la decisión.** Yo también la había dado por buena — mi
documento decía «fuera del viaje» y lo firmé. Retirar alcance por una dificultad técnica es de los dos.

## El resultado, en una línea

**No es «todo S1». Son dos piezas y una tercera que es la cara. Y el reparto no cae donde parecía: lo
barato es el nodo nuevo, lo caro es un `SELECT` que ya está en producción.**

| | Pieza | Coste |
|---|---|---|
| **A** | `Prepare Resolution Context` | **casi cero** |
| **B** | el bloque de prompt del cambio (~7 menciones × 2 agentes) | medio, y toca el `systemMessage` |
| **C** | el `SELECT` de `Resolve Session` | **caro, y cambia comportamiento en PROD** |

Las tools necesitan **A + B**. Solo `Limpiar Turno De Cambio` necesita **C**.

## Tus cinco preguntas

**(2) Dónde se inserta A — resuelto, y hay un único sitio.** `Prepare Resolution Context` entra desde
`Session Context Builder`, que **ya existe en PROD y ya es ancestro de los dos agentes** (a 34 y 37 nodos).
Y devuelve `{ ...ctx, qcTerminal, qcTerminalReason, phoneNumberVariants }`: **extiende, no reforma**. Así
que se inserta en serie, dos aristas:

```
PROD hoy   :  Session Context Builder ─────────────────────→ Resolve Session
PROD con A :  Session Context Builder → Prepare Resolution Context → Resolve Session
```

`Resolve Session` sigue recibiendo todo lo que usa. **Ancestro real garantizado por construcción**, no por
suerte. Único arrastre, e inerte: calcula `qcTerminal`, que en PROD nadie lee porque `QC Terminal?` no
viaja.

**(1) Una pieza que no estaba en la lista de nadie: el prompt.** Medido en los cuatro sitios: **PROD tiene
0 menciones** al flujo de cambio y **STG tiene 7 en cada agente**. La `toolDescription` dice *cuándo*
llamar, pero el protocolo de 6 pasos vive en el `systemMessage`. Sin B, el modelo tiene una herramienta que
nadie le enseñó a secuenciar — y el histórico de este carril dice qué pasa (921/922/925). El coste de B no
es escribirlo: es **extraerlo sin arrastrar el bloque de METEPEC**, que instruye llamar una tool que en
PROD no existe. Y por regla del repo, esa edición la validas tú.

**(3) Qué arrastra el `SELECT` nuevo — todo existe, salvo una cláusula.** `$3` lo da la pieza A; los
`JOIN` a `qualitas_cotizacion` y `qualitas_lead` existen; `chat_watermark` es un `max(id)`; las columnas
nuevas son aditivas y `Session Resolution` hace `matches[0]` + spread. **El problema es el filtro**, que
pasa de fail-open a fail-closed en dos sentidos:

```sql
PROD:  COALESCE(status,'open') IN ('open','active')  AND fase NOT IN (3 valores)   -- blocklist
STG :  COALESCE(status,'')     IN ('open','active')  AND fase IN (6 valores)       -- allowlist
```

Una sesión con `status` **NULL** hoy se resuelve viva y con el nuevo **no**; y cualquier fase desconocida
hoy pasa y con el nuevo **no**. En STG eso arregla la conversación zombi. **En PROD cambia qué sesiones
existen para el bot.**

**La medición que me falta y no puedo hacer** (no tengo la base de PROD). La consulta está en §4 del
documento; el número que decide es `dejarian_de_resolver` sobre las 1 084 filas. Si es 0, C es gratis en
comportamiento. Si no es 0, son clientes que hoy retoman su hilo y después no, **con síntoma silencioso**:
se les trataría como sesión nueva.

**(1.bis) ¿Puede ir una tool sin las otras? Técnicamente sí, funcionalmente no.** `Limpiar Turno De Cambio`
**degrada seguro** sin `chat_watermark`: el bind manda `''`, `NULLIF` lo vuelve `NULL`, la única línea que
lo usa es `AND t.marca IS NOT NULL`, y el `DELETE` remata con `BETWEEN 1 AND 24`. **Borra cero filas: no
borra lo que no debe, no borra nada.** Y `$('Session Resolution')` existe en PROD y sí expone `sessionRow`.

**Pero inerte es justo lo que no puede estar.** Ese nodo existe porque la memoria escribe el turno con el
`session_id` del inicio, así que «Listo, seguimos con la #X» queda en la conversación abandonada. Con ese
estado exacto, **927-929 cambiaron de cotización tres veces sin que nadie lo pidiera**. Promover A+B sin C
es **encender la causa y dejar apagado el remedio**.

**(4) Riesgo del subconjunto con el modo en `shadow`:** ninguno por esa vía. Las tools resuelven por
`phoneNumberVariants`, que es búsqueda **por teléfono** y no depende del modo de `conversation_id`. **Nada
de esta medición necesita `shadow`→`dual`**, y si algún día hiciera falta sería una petición propia a
Alberto, no un efecto colateral.

**(5) Sí hay un orden más barato, y lo recomiendo: A sola primero, en su propia ventana.** Riesgo
prácticamente nulo —un nodo autocontenido en serie que no cambia ningún comportamiento observable— y
verificación trivial: se inserta y el bot conversa igual. Aparte de acortar la ventana grande, **prueba el
procedimiento de inserción en serie sobre el bot principal, que no lo hemos hecho nunca en producción**: la
promoción 1 fue un parámetro y no tocó el grafo. Después A+B+C, con la cifra del §4 en la mano.

Lo que **no** propongo: A+B sin C (recrea el daño) ni esperar a S1 entero (es lo que ya retiraste).

## Un aviso de secuencia

Si Atención Humana entra antes, el bot pasa a **115 nodos** y **hay que rehacer el retrato del antes**.
Los guiones fallan en cerrado contra el `versionId`, así que no es silencioso — pero es un paso, y prefiero
que esté escrito antes de que alguien se lo encuentre con la ventana abierta.
