# Respuesta — los tres que faltan para el fence 9/9

**14 ago 2026 · Arquitecto → Agente n8n.** Las tres decididas. **1(a) y 2(a)**, como recomiendas, con
condiciones. La 3 cambia de categoría y ya está actualizada.

---

## Duda 1 — `Atencion Humana` cuenta como fenceado: **(a)**

Con tu argumento, y añado el mío: **ese camino ya se probó de punta a punta** el 13 de agosto con el
claim 67. La cadena Dashboard → webhook → n8n → Postgres funcionó, y el `control_id` y el `epoch` que
escribió n8n coincidían exactamente con los del claim. No es un conector desnudo ni sobre el papel:
está ejercitado con datos reales.

Fencearlo dos veces no lo hace más seguro, y migrar un ledger vivo dentro de un trabajo cuyo objeto es
otro es exactamente lo que esta semana ha salido caro. La unificación de los dos ledgers es **paso de
rollout**, como ya dice la cabecera de `003`.

**Condición, y no es negociable:** esto **se declara en #156**, no se esconde en la cifra. El dictamen
de Juan dice «bajo el fence común», y vamos a entregar un 9/9 en el que **uno de los nueve está
fenceado por el otro ledger**. Escríbelo en el inventario con esas palabras: *ocho por
`n8n_outbound_reserve`, uno por `dashboard_outbound_dispatch`, unificación diferida a rollout*. Una
cifra que necesita nota al pie y no la lleva es una cifra que engaña — y hoy ya hemos corregido dos.

## Duda 2 — nodo Postgres nuevo en Payment y Retomar: **(a), autorizado**

Descarto la **(b)** por lo mismo que te llevó a revertir el helper: un epoch que se lee en el momento
del envío **coincide siempre**, y llamar «fenceado» a eso es poner una etiqueta que miente. Y la **(c)**
deja el gate sin cumplir. Queda (a).

**Cuatro condiciones:**

1. **Solo lectura.** El nodo hace `SELECT` sobre `conversation_control_v1` y no escribe nada.
2. **No rompas el item.** Es el mismo problema que resolviste con `Stash`/`Restore` en el bot: un nodo
   Postgres sustituye el item y aguas abajo hay quien direcciona con `$json`. Aplica el mismo patrón —
   ya lo tienes construido y probado.
3. **Al candidato, no a la instancia**, como todo lo demás.
4. **Declarado en el diff semántico**: dos nodos nuevos en camino caliente de dos workflows vivos, con
   su porqué.

### Y una pregunta que te devuelvo antes de que lo cierres

**En Payment Confirmation, ¿qué debe pasar si el control humano está activo?** Es una confirmación de
pago disparada por Django, no una respuesta conversacional. Si el fence la bloquea porque un agente
tiene el claim, **el cliente se queda sin saber que su pago entró** — y eso puede ser peor que el
solapamiento que el fence viene a evitar.

No lo decidas tú solo, y tampoco lo decido yo sin el dato: **dime qué hace hoy la vista para ese
caso** (`handoff_state`, `automation_gate`) y qué haría tu implementación. Si resulta que el fence lo
bloquearía, lo subo a Alberto como decisión de producto antes de entregar el 9/9. Retomar no tiene este
problema: ahí el solapamiento es justo lo que hay que evitar.

## Duda 3 — tienes razón en el daño: **es el duplicado**

**Categoría corregida y ya actualizada** en `docs/iniciativas/2026-08-14-ventana-higiene-stg.md` §5,
antes de recibir tu duda — coincidimos en la lectura. Queda escrito que el peor caso **no es una fila
de más, es un mensaje repetido al cliente**, y con tu escenario literal: envío que llega a Meta,
ejecución que muere antes de liquidar, turno posterior con el mismo texto/sesión/epoch → mismo
`request_hash`, `dispatch_id` nuevo, **reenvía**.

**Sigue en higiene y no sube a bloqueante**, por lo que tú mismo dices: el daño es un duplicado, no un
envío indebido, y hacen falta tres coincidencias. **Pero con dos anotaciones:**

- **Para PROD sí es bloqueante.** Un mensaje repetido a un cliente real no es lo mismo que en un
  entorno de pruebas. Queda como requisito de la promoción, no de este trabajo.
- **Tu condición del `dispatch_id` la he registrado como invariante a proteger**, no como detalle: si
  alguien lo simplifica a algo estable entre turnos, una huérfana bloquea ese conector para siempre.
  Que esa razón viva en un comentario del código, no solo en un doc.

---

## Resumen

| duda | decisión |
|---|---|
| 1 | **(a)** cuenta como fenceado — **con la nota explícita en el inventario y en #156** |
| 2 | **(a)** autorizado, cuatro condiciones — y contéstame lo de Payment antes de cerrar |
| 3 | tu lectura es la correcta; categoría ya corregida; sigue en higiene, bloqueante para PROD |

Con esto puedes entregar el 9/9 completo. **Lo único que quiero antes de que lo des por cerrado es la
respuesta sobre Payment**, porque si ahí el fence bloquea una confirmación de pago legítima, eso no es
un detalle de implementación: es una decisión de producto.
