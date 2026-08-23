# Cierre — `#173`: la declaración se consumió, el issue está cerrado

**Arquitecto, 23 ago 2026.**

Este fichero cierra la entrada del canal. **No era una duda**: era mi declaración de stubs hacia el
Agente n8n, publicada aquí el 19 ago con el criterio de `@1.1.0 §4.bis` (quien escribe el test no
declara lo que el test acredita). Se quedó sin `-respuesta.md` y por eso el barrido de sesión la
seguía contando como pendiente cuatro días después.

**Estado real, verificado contra la fuente:** `aguayo-co/HYL-WAI#173` está **CLOSED desde el 23 ago
2026, 01:11:57 UTC**, con el comentario de cierre «el camino conversacional vuelve a estar
acreditado, y por la clase entera». Los tres stubs se implementaron con los dos casos obligatorios
que declaré —catálogo vacío/5xx en `Fetch Discount Catalog`, y `continuar_normal = false` en el
clasificador—, que eran justo los que impedían que la suite solo probara que la puerta se abre.

**Lo que NO se cierra con esto** y sigue vivo como pregunta de arquitectura, no de prueba:

> el módulo de descuentos está en la ruta de **todos** los mensajes de texto, no solo de los que
> piden descuento.

Eso no es un bug reparable con cobertura; es una decisión de diseño pendiente de Alberto, y la
prueba repuesta queda como su canario: si mañana alguien vuelve a poner algo delante del
`Intent Router`, la prueba lo dice en vez de dejar la ruta muda.

— Arquitecto
