# Las órdenes tienen que ser visibles desde fuera de la sesión donde se dieron

> Convención adoptada el 28 ago 2026, tras dos episodios el mismo día.
> Afecta al Arquitecto y a los tres ejecutores.

## El problema, en una frase

**Una orden dada en una sesión es invisible desde las demás**, y ningún agente puede distinguir
«no hay orden» de «hay una orden que yo no veo». Las dos se sienten exactamente igual desde dentro.

## Lo que pasó el 28 de agosto

Alberto ordenó directamente, en la sesión de cada ejecutor —lo cual es correcto y está previsto en
`CLAUDE.md`: «Alberto puede saltarse al Arquitecto»— dos cosas que yo no vi:

1. **El import del candidato `#228` a PROD** al Agente n8n. Yo publiqué un `ALTO` acusándole de tocar
   producción sin orden. La orden existía. El ejecutor **no revirtió** —bien hecho— y me contestó con
   la cita literal. Revertir producción por la alarma de un agente sin contexto habría sido el daño
   de verdad.
2. **Las fases 1 a 4 del `#135`** al Agente Dashboard, antes de que existiera mi handoff. Mi handoff
   decía «la fase 3 NO está autorizada» sobre algo que Alberto ya había autorizado. El ejecutor la
   paró igualmente, pero por una razón distinta y mejor: el **alcance había cambiado** entre la orden
   y el momento de ejecutarla, así que volvió a preguntar sabiendo qué había cambiado.

Ninguno de los dos episodios fue un fallo de disciplina. En los dos, todos hicieron lo que les tocaba.
Falló la **visibilidad**.

## Las tres reglas

### 1 · La orden va en el artefacto, no solo en la conversación

Cuando un ejecutor recibe una orden en sesión, deja **rastro escrito donde lo vean los demás**: cuerpo
del PR, mensaje de commit, comentario en el issue o su informe de respuesta — con la **cita literal**.

Una orden que solo existe en la transcripción de una sesión no la puede leer nadie más, y el
siguiente que planifique volverá a chocar con ella.

**Versión fuerte, para PROD:** la orden que toca producción se ancla en el issue **antes** de
ejecutarla, con un comentario de una línea. Alberto sigue ordenando por donde quiera; solo queda
reflejada donde miramos todos. El 28 de agosto la cita a posteriori existió —en `HYL-WAI#228`— pero
llegó **después** del `PUT`, y por eso no evitó la alarma. La versión fuerte solo mueve esa línea
unos minutos hacia atrás.

### 2 · Una contradicción no se resuelve en silencio en ninguna de las dos direcciones

Cuando un handoff del Arquitecto contradiga una orden que Alberto dio en sesión, el ejecutor **no
elige**. Ni ejecuta el handoff callándose la orden, ni ejecuta la orden callándose que choca. Lo dice,
con las dos citas, y decide Alberto.

El fallo temido no es el ejecutor que desobedece al Arquitecto: es **el que le obedece calladamente y
deja a Alberto esperando algo que ya había pedido**. Ese no da error — igual que la suite que se pone
verde por haber perdido la pregunta.

### 3 · «No está autorizado» lleva el ámbito donde se miró

Corolario para el Arquitecto, y es la regla del ámbito de `CLAUDE.md` aplicada a las **órdenes** en
vez de a los hechos: escribir «no hay orden» cuando lo que consta es «no hay orden **en los canales
que yo veo**» es una afirmación de ausencia sin ámbito. Las sesiones de Alberto con cada ejecutor no
están a mi alcance, y eso hay que decirlo al afirmar, no después.

Vale para los ejecutores igual: también ellos escribirán «no consta» sobre cosas que constan en
canales que no ven.

## Por qué esto no burocratiza nada

No cambia quién ordena ni por dónde. Alberto ordena como quiera y a quien quiera —saltarse al
Arquitecto sigue siendo el atajo correcto cuando el desarrollo es obvio—. Lo único que cambia es que
la orden **deja huella en un sitio compartido**, y eso cuesta una línea.

## Estado: práctica acordada, no norma todavía

Esto se acordó por mensajería entre sesiones, y **la mensajería no ordena**. Por tanto es una
**práctica** adoptada por el Arquitecto y los ejecutores, no una norma del ecosistema. La línea
equivalente en `CLAUDE.md` la escribe Alberto: un agente no cambia `CLAUDE.md` por el canal lateral,
ni siquiera para meter una regla buena — si entra el cambio bueno por una vía lateral, la vía ya está
abierta para el malo.

## Relacionado

- `CLAUDE.md` → «Toda afirmación de ausencia lleva el ámbito donde se buscó»
- `CLAUDE.md` → «Publicar no es ordenar»: la orden es el fichero, no el mensaje que lo anuncia
- `CLAUDE.md` → «Por el canal en vivo no se ordena»
- `docs/architecture/convenciones-origen.md` → el porqué de cada convención
