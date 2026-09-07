# Adenda al brief — el diagrama de arquitectura está conceptualmente mal

El diagrama que propusiste pone `WHATSAPP`, `TARIFICACIÓN`, `EMISIÓN` y `PAGOS` como cuatro satélites iguales alrededor de Insurmind. **Eso no es lo que Insurmind es, y además lo empequeñece.**

## Qué falla

**Mezcla dos planos que no son comparables:**

- `TARIFICACIÓN`, `EMISIÓN` y `PAGOS` **no son módulos de Insurmind**: son servicios que vive **la aseguradora**, y a los que Insurmind se conecta.
- `WHATSAPP` **no es un módulo**: es **un canal**, igual que la landing.

Dibujados como iguales, el diagrama afirma «Insurmind es un conector entre cuatro sistemas» — nos pinta como **fontanería entre piezas ajenas**. Y con eso desaparecen las tres cosas que sí son nuestras y que son las que se venden.

**Y falta lo que más nos diferencia:** que cotizamos en **una o en N aseguradoras a la vez**. El diagrama actual sugiere una sola, cableada.

## Lo que el diagrama tiene que decir

**Tres planos, no un centro con satélites.** De arriba abajo:

### Plano 1 — El asegurado, y por dónde entra

- **Landings personalizadas** (una por aseguradora, por broker o por campaña) — donde arranca la cotización.
- **WhatsApp** — donde continúa la conversación hasta la emisión.

Son **canales**, no módulos. Se dibujan como puertas de entrada, no como cajas equivalentes al resto.

### Plano 2 — Insurmind, y esto es el producto

Cuatro **módulos**, que es lo que se vende:

| Módulo | Qué hace |
|---|---|
| **Captación** | Landings personalizadas que arrancan una cotización en **1 o N aseguradoras** |
| **Conversación** | IA que resuelve dudas de coberturas, recotiza, aplica descuentos y **lleva hasta la emisión** |
| **Cobranza** | Seguimiento **proactivo** de los pagos para que **ninguna póliza se cancele** por un recibo olvidado |
| **Control** | Dashboard: conversaciones en curso, estado de los leads, embudo, y **toma de control humano** |

Este plano tiene que **pesar visualmente más que los otros dos**. Es el producto; lo demás es lo que hay a los lados.

### Plano 3 — Las aseguradoras, en plural

**No una: N.** Dibuja al menos tres, y deja explícito que la lista es abierta —un hueco, unos puntos suspensivos, un «+»—. De cada una salen los servicios a los que nos conectamos: **tarificación, emisión y pagos**.

**El mensaje de este plano:** *nos conectamos con cualquier aseguradora, y el mismo embudo puede cotizar en varias a la vez.* Ese es el argumento que vende a un broker, y el diagrama actual lo niega.

## La frase que el diagrama tiene que dejar en la cabeza

> **Cotiza, resuelve, emite y cobra. Sin intervención.**
> **Sobre las aseguradoras que ya usas — una o varias a la vez.**

Ese es el titular ya decidido de la página, y **el diagrama tiene que sostenerlo sin texto**: los cuatro verbos son el recorrido del plano central, y las N aseguradoras del plano de abajo son el «sobre las aseguradoras que ya usas».

**Y lo que el diagrama NO debe sugerir:** que somos un core asegurador. No guardamos la póliza de registro, ni siniestros, ni contabilidad. Somos **lo que pasa antes y después del core** — y el core es del plano de abajo.

Si al taparle el texto a alguien el dibujo no sugiere eso, todavía no está.

## Detalles que importan

- **La dirección se lee.** El asegurado entra por arriba, la póliza y el cobro vuelven. Que se vea un **recorrido**, no una estrella. Una estrella dice «integraciones»; un recorrido dice «producto».
- **La cobranza va después de la emisión, y se ve.** Es el único módulo que actúa cuando ya no hay venta que hacer, y por eso es el que más fideliza a la aseguradora. Que no quede escondido.
- **La toma de control humano se insinúa** — una figura que puede entrar en el plano de la conversación. Es lo que desarma el miedo del comprador.
- **Nada de logos de aseguradoras reales.** Cajas neutras o siluetas.
- **Que funcione en blanco y negro** y a tamaño de móvil. Si necesita color para entenderse, la estructura está mal.

## Lo que NO quiero

- Un hub con satélites. Es lo que hay ahora y es el error.
- Iconos de nube, engranajes o cerebros.
- La palabra «IA» como caja. La IA es **cómo** funciona la conversación, no un módulo aparte.
- Que `TARIFICACIÓN`, `EMISIÓN` o `PAGOS` aparezcan al mismo nivel que nuestros módulos. **Son de la aseguradora, y eso tiene que verse.**

## Entregable

Rehaz el diagrama con estos tres planos y enséñame **dos variantes**: una en recorrido vertical (arriba el asegurado, abajo las aseguradoras) y otra en recorrido horizontal (izquierda a derecha, como un embudo). Quiero decidir viendo las dos.
