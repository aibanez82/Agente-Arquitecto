# Respuesta — Evaluations como suite de regresión: validado, con tres enmiendas

**Arquitecto, 20 ago 2026.** El enfoque es correcto y lo respaldo. La investigación está hecha
contra la doc y el pricing, no de memoria, y la disciplina que propone —cada bug pasado es una
fila del dataset— es exactamente la que hoy ejercemos a mano y con resultados desiguales.

Tres enmiendas antes de bajarlo a handoff. La primera no es un detalle.

## Enmienda 1 — esto mueve la fuente del contrato, y hoy la fuente ya está rota

Añadir 6-8 nodos al bot **cambia el candidato**, y con él la premisa `source` de
`STG-OPERATIONAL-DUAL-MAIN@1.1.0`. Es exactamente lo que ocurrió con el `#174`: un cambio de
comportamiento pequeño obligó a re-firmar el contrato entero, y la primera firma quedó caduca antes
de poder fusionarse.

Y hoy el problema es peor: el `#187` documenta que **el candidato ya dejó de describir la
instancia** — 222 nodos con Metepec dentro frente a 249 vivos sin él. Construir la instrumentación
de evaluación sobre esa base significa firmar otra vez encima de una foto vieja.

**Condición: el `#187` se decide antes.** No «se tiene en cuenta»: se decide. Si la salida es
refrescar el candidato antes de cada firma, este trabajo empieza con un candidato al día; si es
desplegar el Dual, empieza después. Cualquiera de las dos vale; empezar sin elegir, no.

## Enmienda 2 — `Check if Evaluating` no gatea los workflows proactivos

La propuesta gatea correctamente los envíos **del propio bot**. Pero en STG hay workflows que
corren **por horario y leen la base**, no por el trigger del bot: `Retomar Conversacion_stg` y el
poller de descuentos. Una corrida de evaluación deja sesiones y filas reales en Postgres STG con
teléfonos de prueba, y **nada impide que el proactivo las recoja en su siguiente ciclo y mande un
WhatsApp de verdad**.

`Check if Evaluating` no lo cubre: esos workflows no participan en la evaluación y por tanto no
están en modo evaluación.

**Antes de la primera corrida hay que acreditar una de estas dos:** que los teléfonos de prueba
quedan fuera del alcance de los proactivos por construcción, o que los proactivos consultan también
la marca de evaluación. Medido, no supuesto — con una corrida en seco y la comprobación de que
ningún ciclo posterior seleccionó esas sesiones.

## Enmienda 3 — la regla que hace que el dataset no muera

Un dataset de regresión se degrada solo: nace con 20 casos, nadie añade el 21, y a los dos meses
acredita el bot de hace dos meses. La disciplina que la doc recomienda hay que convertirla en
regla nuestra, o no ocurrirá:

> **Ningún issue de comportamiento del bot se cierra sin su fila en el dataset.** El caso que lo
> reprodujo entra como fila antes del cierre, no después.

Con eso el dataset crece exactamente al ritmo al que aprendemos, y el trabajo de mantenerlo se
reparte en el momento en que ya se tiene el caso delante.

## Lo que valido sin enmienda

- **`Categorization` para los copys literales.** Es la métrica correcta: el cierre del `#177`, el
  marcador del `#182` y los mensajes plantilla son texto exacto aprobado por Alberto, y un match
  exacto es justo lo que hay que acreditar. Determinista y sin coste.
- **`Tools Used` + `intermediateSteps`.** Y aquí hay una sinergia que la propuesta no reclama:
  **es la vía para asertar qué tools llamó el agente sin tocar la memoria**, que es precisamente el
  agujero del `#183`. La tabla `n8n_chat_histories` solo persiste el último intercambio de tool por
  turno y no se puede ampliar sin cambiar lo que el modelo ve. Los `intermediateSteps` de la
  evaluación dan esa visibilidad por otro camino. Añádelo como argumento del issue.
- **Gastar el cupo metric-based en el bot principal.** Es donde vive todo el riesgo. De acuerdo.
- **Que no sustituye al E2E real por WhatsApp.** Bien dicho y hay que mantenerlo dicho: lo que toca
  canal, plantillas o media se sigue probando en vivo.

## Lo que pide decisión de Alberto

1. **Registrar la instancia STG** (Settings → Usage and plan). Sin eso no hay Evaluations.
2. **Asignar el cupo del workflow metric-based** al bot principal.

Ambas son suyas y las tiene planteadas. Con su confirmación y el `#187` decidido, bajo esto a issue
y handoff con la fase 1 acotada.

— Arquitecto
