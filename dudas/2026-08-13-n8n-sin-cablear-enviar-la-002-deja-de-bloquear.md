# Nota — sin cablear `enviar`, **la `002` deja de ser precondición de la promoción 2**

**13 ago 2026 · Agente n8n · no es duda, es una corrección al §3 de tu estado.** Y va a favor: quita una
ventana del camino crítico.

`docs/fase4-preparacion (ultimo commit)` · detalle en `docs/fase4/2-atencion-humana.md`.

## Lo que medí al aplicar tu cambio de alcance

Alcanzabilidad desde cada uno de los tres triggers, en el grafo del workflow:

| Trigger | Nodos alcanzables | ¿Ledger? | ¿WhatsApp? | ¿Historial? |
|---|---|---|---|---|
| `atencion-humana-iniciar` | **1** — `Marcar Human Takeover ON` | **no** | no | no |
| `atencion-humana-liberar` | **1** — `Marcar Human Takeover OFF` | **no** | no | no |
| `atencion-humana-enviar` | **14** | **sí, los tres** | sí | sí |

Los dos que **sí** se cablean alcanzan **un solo nodo cada uno**, y ese nodo toca únicamente
`whatsapp_sessions` — columnas que ya están en PROD desde la ventana del 12 ago.

**`dashboard_outbound_dispatch` no se toca por ninguno de los dos caminos vivos.** Así que la promoción 2,
con el alcance que decidió Alberto, **no necesita ningún DDL nuevo**: todo lo que ejecuta ya está en
producción.

Tu §3 la sigue listando como precondición ✅ de la ventana. No está mal —está escrita y acreditada— pero
**ya no es un bloqueo**: pasa a ser precondición del día en que alguien cablee `enviar`. La diferencia
importa para el calendario, porque saca una ventana de esquema del camino crítico.

## Y la otra cara, que no me callo

El workflow llevará **tres nodos cuyo SQL referencia una tabla que en PROD no existe**. Mientras nadie
llame a `enviar` no se ejecutan y no pasa nada. El día que alguien lo llame —por error, por un cambio
futuro del Dashboard, o probando en la interfaz— **falla en el parseo**, que es el fallo que la `002`
existe para evitar.

**Recomiendo aplicarla igual**: es aditiva, está acreditada 14/14, cuesta una ventana corta, y **un
endpoint que existe y falla es peor que uno que existe y funciona**. Pero como no bloquea, puede ir
después de la promoción 2 sin retrasarla — y esa es la decisión de Alberto, no mía.

## Lo que he retirado de mi propio E2E

El criterio del dispatch, que **yo mismo había hecho obligatorio** después de medir que ese camino nunca
ha corrido en ningún sitio. Sigue siendo verdad, pero con `enviar` sin cablear el argumento se vuelve al
revés: **si nadie va a llamarlo, estrenarlo en producción es añadir riesgo sin cerrar nada.** El día que
se cablee, el criterio vuelve — y con la `002` aplicada antes.

Queda en el E2E lo que cierra el `#57` de verdad: tomar → `iniciar` → `human_takeover=true` → el guard
corta y **el bot deja de contestar**; `liberar` → vuelve a contestar; y el caso del cliente que vuelve con
cotización nueva sobre el mismo teléfono.

## Acuso el resto

- **`#159` a Juan**: anotado, con el plan B de mi lado —detectar que el `quotation_id` cambió respecto al
  claim— **sin empezarlo**, como dices.
- **El `DROP INDEX` del duplicado de `whatsapp_sessions.quotation_id`**: lo tengo apuntado como lo último
  del viaje. No lo toco hasta que las dos ventanas estén cerradas.
- **El límite de lectura de la base**: entendido — es para **este** viaje y nunca para `#156`, cuyo régimen
  offline es condición del contrato. No he leído la base para nada de `#156` y no lo haré.
