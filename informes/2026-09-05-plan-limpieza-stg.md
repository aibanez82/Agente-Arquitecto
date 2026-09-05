# Plan para dejar STG sin issues nuestros

> Arquitecto-IA-Qualitas · 5 sep 2026 · **Para aprobación de Alberto**
> Ámbito: **STG.** Grafo vivo `87af6208`, 316 nodos.

## Cómo está agrupado, y por qué no por número

De los **25 issues abiertos** asignados a nosotros, varios son **el mismo defecto visto por sitios distintos**. Atacarlos de uno en uno sería repetir el trabajo tres veces. Van por causa.

---

## Fase 1 · La cifra no la teclea el modelo

**Cierra: `#341`, `#324`, y la parte dura del `#206`. Habilita `#307`, `#277` y `#279`.**

Es la conclusión a la que ha convergido el día entero, medida tres veces:

- `#341` — la instrucción decía «da la cifra **LITERAL**» y el modelo emitió `5,449.01` teniendo `5,449.04` en el payload.
- `#324` — la regla decía «**NUNCA** afirmes Robo Parcial como incluido» y lo afirmó dos días después.
- `#206` — tres redacciones dieron 2/5, 1/10 y 2/10. Nivel de ruido, sin tendencia.

**Un prompt no puede garantizar fidelidad de dígito ni cumplimiento de una prohibición dura.**

**Qué hay que diseñar:** que los datos exactos —importes, deducibles, coberturas contratadas— **los inserte el grafo** en el mensaje, y que lo que el modelo escribe alrededor no pueda contradecirlos. El grafo ya tiene la familia de nodos para eso (`Format …`, los `Phase Extractor`, los guards de salida): el patrón existe, no hay que inventarlo.

**Por qué va primera:** es la única fase que cierra tres issues de golpe, dos de ellos críticos, y desbloquea otros tres. Y es la que arrastra riesgo de dinero.

---

## Fase 2 · El 400 silencioso

**Cierra: `#297` y `#296`.**

Son el mismo fallo con dos disparadores:

| | Disparador | Consecuencia |
|---|---|---|
| `#297` | El recorte de memoria parte una pareja `tool_use`/`tool_result` | **La conversación queda muda PARA SIEMPRE**: el turno roto no escribe memoria, así que el borde del recorte no se mueve y el 400 se repite eternamente |
| `#296` | El cliente responde `1` a la lista de cotizaciones | «Tuvimos un problema». La ejecución termina en `success` y **no deja rastro en ninguna tabla** |

**Lo común, y es lo que hay que arreglar primero:** un **HTTP 400 del proveedor del modelo** que acaba en `success` y del que nadie se entera. Mientras eso siga así, no sabemos cuántas conversaciones hay mudas ahora mismo.

**Orden dentro de la fase:** (a) hacer el 400 observable, (b) medir cuántas sesiones están mudas, (c) arreglar el recorte para que no parta la pareja, (d) el caso del `1`.

---

## Fase 3 · La sesión cerrada que no contesta

**Cierra: `#285`.**

Una sesión `closed` entra al carril de respuesta normal, que exige datos que esa sesión ya no tiene, y **el cliente se queda sin respuesta**. El arreglo del `#285` convirtió el fallo ruidoso en silencioso: ahora termina en `success` y ningún monitor lo ve.

El caso que lo destapó: un cliente que pedía cancelar tras cinco semanas sin liga de pago se despidió educadamente y **no le contestamos**. Hubo que escribirle a mano, dos veces, por fuera del bot.

El sitio donde decidirlo ya existe: `Session Router` bifurca entre `Update Activity` y `Disambiguation Router`.

---

## Fase 4 · El bot desmiente lo que existe

**Cierra: `#275`, `#277`, `#279`.**

La familia de la emisión: el bot le dice al cliente que su póliza no existe cuando sí existe, y las guardas que lo tapan **confían en un número de póliza que escribe el modelo** — o sea, harían de una invención un hecho de sistema.

**Depende de la Fase 1:** la solución correcta es la misma —que el dato lo ponga el grafo— y hacerla antes por separado sería construir dos veces.

---

## Fase 5 · Copy y contabilidad

**Cierra: `#339`, `#340`, `#288`, `#338`, `#325`.**

- `#339` y `#340` — el mensaje del descuento no anuncia nada cuando toca, y anuncia como novedad algo entregado hace 18 minutos cuando no toca. **La misma raíz: nadie lleva la cuenta de qué se le ha dicho ya al cliente.**
- `#288` — el acuse se repite palabra por palabra.
- `#338` — el presupuesto de KB cuenta turnos que nunca consultan la KB.
- `#325` — una pregunta reventó `Detect Jailbreak`. Ocurrencia única.

Son los de menor daño y los de arreglo más barato. Van al final **a propósito**: si se hacen antes, consumen el día y los críticos siguen abiertos.

---

## Lo que NO entra, y por qué

| Issue | Motivo |
|---|---|
| `#329` | Pagos. Es operación y del carril de Juan, no de STG |
| `#337` | Django. Es de Juan, y hoy medí que su punto 2 ya está hecho |
| `#333` | Espera respuesta de Hylant. No lo decidimos nosotros |
| `#312` | Es una **decisión tuya**: sin teléfono canonicalizable no hay carril de descuentos medible con sesiones sintéticas |

## Lo que ya está acreditado en STG y no es trabajo

`#270` · `#313` · `#320` · `#323` · `#326` · `#327` · `#328` · `#332` · `#334` · `#336`.

Siguen abiertos porque el tracker es único para los dos entornos, no porque quede algo que hacer en STG.

---

## Lo que no te voy a prometer

**Esto no cabe hoy.** La Fase 1 sola es diseño, handoff y batería con N alto — y hoy hemos visto que una redacción puede necesitar tres vueltas. Prometerte «STG sin issues esta noche» sería el mismo error que cerrar el `#323` con dos tiradas.

Lo que sí puedo: **empezar por la Fase 1 y no tocar nada más hasta cerrarla.** Es lo que más riesgo retira por unidad de tiempo, y las otras cuatro quedan en cola en este orden.

Agente: Arquitecto-IA-Qualitas
