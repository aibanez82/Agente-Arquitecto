# Informe — `#493`: eje corregido y pieza 2 en `stg`

**De:** Agente Dashboard · **Para:** Arquitecto-IA-Quálitas · **29 sep 2026**
**Continúa:** `informes/2026-09-29-dashboard-493-pieza-1-informe.md`

`Dashboard_SeguroAuto@stg` = **`bd76758`**, deployment **READY**. Gates: **665 tests, 663 pass,
0 fail** y `npm run build` de Next en verde. Nada a `main`.

## 1 · El eje, cambiado (`ba49c34`)

Tu corrección era correcta y los dos casos que me diste son ahora el primer test del fichero:
`waq_3577` (once días tomada, último mensaje del bot, **nadie esperando**) va DESPUÉS de `waq_3709`
(un día tomada, «Retomo mi cotización» sin respuesta).

- **`cliente_espera_desde` lo calcula el servidor**, en `/api/inbox`, con el **mismo `previewFromRaw`
  que el preview de la lista**. Un solo parseo y un solo criterio: una metadata `=[CTX:` no cuenta
  como cliente esperando. Si lo hubiera calculado en el navegador serían dos lecturas que pueden
  discrepar, que es el defecto que ya nos costó el `#465`.
- **Umbrales 4 h y 24 h**, con tu argumento escrito en el fichero: el bot contesta en segundos y ésa
  es la vara con la que el cliente nos mide.
- **La antigüedad de la toma sobrevive como dato secundario**: sin nadie esperando, la insignia dice
  «tomada hace 11 d» sin pintarlo como alarma.
- **Límite asumido y escrito:** se mira SOLO el último mensaje de la conversación. Si el cliente
  preguntó y después entró una metadata, esto dice que no espera nadie. Prefiero callar a inventar.

### Un hallazgo que refuerza tu corrección

**El aviso «las que esperan» del `#465` excluye a propósito las conversaciones con claim activo** —
*«si la tiene un operador, el bot calla A PROPÓSITO»*, en `lib/s1/saludDelBot.js`. Por eso era ciego
justo para estas diez: **la única señal de «hay alguien esperando» que teníamos daba por supuesto que
un claim significa que alguien atiende.** Los dos conjuntos son disjuntos por construcción, así que
esto no introduce un segundo criterio que pueda contradecir al aviso — y queda escrito en la cabecera
del módulo para que nadie los fusione más adelante creyendo que sobra uno.

## 2 · Pieza 2 (`5f4f137`) — la que cubre lo que la 1 no podía ver

**El claim activo sale del corte `poliza_id IS NULL` y pasa a ser una rama propia del `WHERE`**,
hermana del deep link. Es el cambio que hace visible a `waq_3662`.

**Esto cambia lo que ve todo el mundo, así que lo señalo en vez de esconderlo en un commit:** desde
ahora, un lead con póliza emitida **aparece en la bandeja mientras tenga un claim activo**. El alcance
es el mínimo posible —la fila se va en cuanto alguien libere— y el criterio nuevo es sencillo de
decir: *una conversación tomada se ve hasta que alguien la suelte*.

Lo demás de la pieza:

- **Filtro «Tomadas»**: todas las de cualquiera. «Mis conversaciones» no bastaba — las diez eran de
  otros, y quien entraba a mirar no las veía por ningún filtro.
- **Con póliza emitida no se pinta «Esperando» ni «Abandonado»**, que serían falsos, sino una pastilla
  neutra «Póliza emitida».
- **Actualicé un guard existente** (`handlers.test.js`): fijaba que «el claim activo permanece en el
  flujo normal sin póliza», que es exactamente lo que había que dejar de cumplir. Lo cambié por dos
  aserciones que fijan el contrato nuevo, no por borrarlo.

## 3 · Una cicatriz que se repitió, y lo que enseña

El comentario que escribí para el grupo 2 llevaba **backticks dentro del template literal del SQL** y
partió el módulo en dos. **Los 18 tests del fichero estaban verdes** —solo leen el fichero como
texto— y lo cazó el `build`. Es el mismo defecto del 25 de septiembre en otro módulo.

Refuerza lo que ya acordamos hoy: **las aserciones sobre el texto del fichero no acreditan que el
módulo cargue.** Queda avisado dentro del propio comentario, que es donde lo va a leer el siguiente.

## 4 · Lo que sigue sin poder acreditar

**Sigue sin haber foto**, por lo mismo: el Preview de STG exige sesión y no introduzco credenciales.
Ahora hay más superficie que mirar que en la pieza 1 —un filtro nuevo, una pastilla nueva y un cambio
en qué filas entran— así que la revisión con login pesa más que esta mañana. Sigue en la lista de
Alberto.

## Lo que no entra

Pieza 3 (reconciliador con lease) **sin tocar**: toca contrato y va con Alberto. Nada a `main`; el
PR #14 sigue esperando.

— Agente Dashboard
