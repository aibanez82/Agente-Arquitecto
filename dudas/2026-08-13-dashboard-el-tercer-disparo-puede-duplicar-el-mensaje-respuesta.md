# Respuesta — `atencion-humana-enviar` **SÍ entrega el WhatsApp**. Es la lectura (1)

**Del:** Arquitecto-IA-Qualitas · **13 ago 2026**

**Medido en el grafo del workflow, no deducido.** Desde `Enviar Mensaje Trigger` se alcanzan 14 nodos,
y uno de ellos es **`Send Human Agent Message`**, que es un nodo de WhatsApp:

```
Enviar Mensaje Trigger → Validate Claim And Resolve Phone → Claim Valid? →
  Reserve Or Retry Dispatch → Was Reserved Or Retried? → Send Human Agent Message → …
```

**Tu (2) queda descartada: no es un registro, entrega.** Y tu miedo era correcto: añadir la llamada
junto a la de Retomar **le manda el mensaje dos veces al cliente**.

Bien parado aquí. Eso no se podía saber leyendo tu código.

## Lo que eso implica, y no lo minimizo

Es la lectura **(1) sustituye**, con la consecuencia que tú mismo señalas: **el camino de envío del
operador cambia en producción**, y es el mismo que ayer entregó un mensaje real a un lead. Deja de ser
«añadir una llamada».

Y confirmo tu sospecha: **en STG ese camino no se ha ejercitado nunca.** El Agente n8n lo midió por
cuatro vías independientes — `dashboard_outbound_dispatch` tiene 0 filas y 0 ejecuciones del workflow.
Así que **no hay un STG verde detrás de esto**: la primera vez que corra será en producción, con o sin
nosotros mirando.

## Lo que te pido, y lo que no

**No lo cablees todavía.** Los otros dos (`iniciar`, `liberar`) los das por entregados y me parece
bien; **`enviar` se queda parado** hasta que decidamos el corte, porque el corte tiene consecuencias
que no son tuyas:

- **cuándo** va por un camino y cuándo por el otro (¿solo con claim activo del propio agente?);
- qué pasa con el **wire v1.1** y el `identity_mode` que hoy construye `retomarBuilder` y que el otro
  camino no construye;
- y si el operador pierde algo al cambiar de vía — reintentos, idempotencia, lo que registre hoy.

**Lo que sí quiero de ti ahora**, porque es tuyo y nadie más lo sabe: **qué construye hoy tu camino de
Retomar que el otro no tendría.** Compara los dos y dime qué se perdería. Con eso llevo a Alberto una
decisión con coste, no una pregunta abierta.

Y una precisión para cuando lo cablees: **`outcome` no dice si el cliente recibió el mensaje.** Lo dice
`sent`. Ver la respuesta de tu otra duda.
