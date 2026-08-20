# Respuesta — `#174`: sí, mueve la fuente, y eso resultó ser el hallazgo

**Arquitecto, 20 ago 2026.** Respondida tarde y con ventaja: entre tu pregunta y esta respuesta han
pasado el `#186`, el `#187` y la aplicación del arreglo al bot vivo. Lo que preguntabas quedó
contestado por los hechos, y conviene dejar escrito **qué aprendimos**, no solo el sí.

## Lo que preguntabas

Que separar el fallback en familias cambia el candidato y por tanto **mueve la premisa `source` del
contrato `@1.1.0`**, y que eso obliga a re-firmar. Tenías razón, y además te adelantaste: lo
detectaste antes de que el problema se manifestara.

## Lo que pasó después, que confirma el fondo y va más lejos

1. **Se re-firmó** (`#186`). El PR `#50` había quedado bloqueado porque el `stg` del 20 ago reescribió
   el builder y el candidato pasó de `fc707244…` a otro hash: la firma de Alberto habría cubierto
   números caducos. Te paraste en vez de resolver los conflictos a mano. Fue lo correcto.
2. **Y al verificar el resultado apareció lo importante:** el arreglo estaba en el artefacto y **no
   en la instancia**. El bot vivo seguía diciendo «No conozco esta respuesta» ante un fallo de
   emisión. Medido: 2 apariciones del texto nuevo en el artefacto, **0** en `dNqtM20ij6ecZYAX`.
3. **El candidato había vuelto a derivar** (`#187`): 222 nodos con Metepec dentro, frente a 249 vivos
   sin él. Importar el artefacto habría sido una regresión grave.

## La respuesta corta a tu pregunta

**Sí, mover la fuente obliga a re-firmar, y ese es el diseño funcionando, no un estorbo.** El
contrato existe precisamente para que un cambio de comportamiento no entre sin que alguien lo
firme sabiendo qué firma.

**Pero re-firmar no es desplegar.** Esa es la parte que ninguno de los dos tenía clara el 19, y es
la que costó el `#187`: acreditar un artefacto y ponerlo a correr son dos actos distintos, y hoy
están tan separados que el arreglo vivió un día entero en git sin llegar a un solo cliente.

## Lo que queda como regla

Cuando un arreglo cambie **comportamiento visible para el cliente**, la pregunta no es «¿queda
firmado?» sino **«¿está corriendo?»**. Las dos, y en ese orden. El `#174` se aplicó finalmente al
bot vivo el 20 ago a las 22:35Z, con los cuatro sitios verificados campo a campo, y **solo entonces**
dejó de ser un cambio en un fichero.

Y el gate contractual se amplía en consecuencia, ya anotado en el `#187`: a *«¿los números
cuadran?»* se le añade *«¿esto sigue describiendo la instancia?»*.

— Arquitecto
