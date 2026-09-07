# Rediseño de la landing de Insurmind — brief para diseño y mockups

Eres un director de arte y diseñador de producto especializado en landings de **SaaS B2B**. Quiero que rediseñes la web pública de **Insurmind** y me entregues propuestas visuales concretas, no un documento de teoría.

---

## 0. El titular, ya decidido — no lo reescribas

> # Cotiza, resuelve, emite y cobra. Sin intervención.
>
> Sobre las aseguradoras que ya usas — una o varias a la vez.
> Tú ves cada conversación, mides la conversión y tomas el control cuando el negocio lo pida.

**Los cuatro verbos son la prueba de que el recorrido se completa**, que es lo que casi nadie en el sector puede decir. «Resuelve» es el que nos separa de un cotizador: un formulario da un precio; nosotros contestamos por qué el deducible es del 25 % en *esa* póliza.

**Nunca escribas «vende y cobra solo».** En español «solo» se lee como *solamente* antes que como *sin ayuda*, y diría lo contrario de lo que queremos. Usa «sin intervención», «sin que nadie lo empuje» o «de principio a fin».

**Y lo que NO somos, porque nos lo van a preguntar:** Insurmind **no es un core asegurador**. No guarda la póliza de registro, ni gestiona siniestros, ni lleva contabilidad técnica. **Es todo lo que pasa antes y después del core**: captar, cotizar, conversar, negociar y emitir; después, cobrar y retener. El core es el trozo del medio y **es de la aseguradora**. Decir lo contrario lo desmonta cualquier comprador en dos preguntas.

## 1. Qué es Insurmind

Insurmind es una **empresa de tecnología que vende un SaaS a aseguradoras y brokers**. Su producto convierte a un visitante anónimo en una póliza emitida y cobrada, sin intervención humana salvo cuando la aseguradora quiera tomarla.

El producto cubre el ciclo entero:

1. **Cotización desde una landing** — el visitante pide precio y el sistema crea el lead y la cotización.
2. **Conversación por WhatsApp** — un agente de IA resuelve dudas reales de coberturas, deducibles y exclusiones, con los datos de *esa* cotización, no con respuestas genéricas.
3. **Recotización y descuentos** — detecta objeción de precio, consulta qué descuento aplica y emite una cotización nueva mejorada.
4. **Emisión** — captura los datos (nombre, placas, número de serie, domicilio), valida y **emite la póliza** por el mismo canal.
5. **Cobranza proactiva** — recuerda recibos por vencer y entrega la liga de pago antes de que la póliza caiga.
6. **Dashboard de operación** — la aseguradora ve las conversaciones en curso, el estado de cada lead, el embudo, y puede **tomar el control humano** de cualquier conversación con un clic y devolverla al bot después.

## 2. A quién le habla la landing — y el matiz que lo decide todo

**El comprador es la aseguradora o el broker.** No el asegurado.

Pero **la mejor demostración del producto es enseñar la conversación que vive su cliente final.** Un director comercial de una aseguradora no compra «IA conversacional»: compra ver que un lead entra a las 18:21 y sale con póliza emitida a las 19:27, en WhatsApp, sin que nadie de su equipo toque nada.

Ese es el eje del rediseño: **enseñar el producto funcionando, no describirlo.**

## 3. Los cuatro verbos, con una captura cada uno — es el corazón de la página

El titular promete cuatro cosas. **Cada una tiene su sección y su captura de pantalla.** No son ilustraciones: son la prueba.

Las conversaciones de WhatsApp llevan **copy real de producción**. Úsalo literal, no lo reescribas.

---

### COTIZA — la landing

**Captura:** una landing de cotización **personalizada**. La misma plataforma genera una por aseguradora, por broker o por campaña, con su marca, y **posicionable en buscadores**.

**Lo que tiene que hacer sentir:** el embudo empieza donde el cliente busca, no donde a la aseguradora le viene bien. Y se puede tener una por marca sin montar un proyecto nuevo cada vez.

Es la única captura de las cuatro que hay que **diseñar**; las otras tres son conversaciones.

---

### RESUELVE — WhatsApp

**Dos capturas**, porque son dos capacidades distintas.

**(a) Una duda de cobertura**

> **Bot** · *(adjunta `Cotizacion_2381_HD_2020.pdf`)*
> Aquí tienes tu cotización. ¿Continuamos con la emisión de tu póliza?
>
> **Cliente** · ¿el deducible de daños materiales es 25%?
>
> **Bot** · *(contesta con la cifra de ESA cotización, nombrando la cobertura)*

**(b) Una objeción de precio, y el descuento**

> **Cliente** · tienes alguna promoción?
>
> **Bot** · ¡Voy a por ello! Déjame revisar tu cotización para buscarte el mejor precio posible. Ahora mismo te cuento.
>
> **Bot** · ¡Lo conseguí! 🎉 Hay un descuento aprobado para tu cotización y ya estoy armando la nueva con el precio mejorado. Te la mando por aquí en cuanto esté lista.
>
> **Bot** · *(adjunta `Cotizacion_2382_HD_2020_Descuento.pdf`)*
> Aquí tienes tu nueva cotización con descuento. ¿Continuamos con la contratación?

**Lo que tienen que hacer sentir:** la primera, que no es un FAQ — contesta con los datos de *esa* póliza. La segunda, que **negocia y rescata la venta** en lugar de limitarse a responder.

---

### EMITE — WhatsApp

**Captura:** el cierre real, con el resumen de póliza.

> **Bot** · Perfecto, Juan. Ahora necesito:
> · Placas del vehículo
> · Número de serie (NIV/VIN): 17 caracteres
>
> **Cliente** · *(manda las placas)*
>
> **Bot** · ¡Perfecto, estamos a nada! 🙌 Último paso y ya:
> · Calle y número
> · Colonia
>
> **Cliente** · *(manda el domicilio)*
>
> **Bot** · ¡Listo, Juan! 🎉 Tu póliza fue emitida exitosamente.
> *(resumen con número de póliza y monto)*

**Lo que tiene que hacer sentir:** aquí es donde se cae la competencia. Esto **emite de verdad**; no deja un lead caliente para que llame un humano.

---

### COBRA — WhatsApp

**Captura:** un mensaje que el cliente **no pidió**, días antes del vencimiento, con la liga de pago.

> **Bot** · Hola Juan, tu recibo de la póliza vence el 21 de septiembre. Aquí tienes tu liga de pago para que tu cobertura siga vigente, sin interrupciones.
> *(liga de pago)*

**Lo que tiene que hacer sentir:** el producto **defiende la cartera**, no solo la vende. Es el único módulo que actúa cuando ya no hay venta que hacer, y por eso es el que más fideliza a la aseguradora.

> **Nota interna, no para la web:** el sistema ya detecta el recibo por vencer y genera la liga a diario en producción. **El envío proactivo del aviso está en despliegue**, así que este texto es la especificación de lo que dirá, no un recorte de un envío pasado. Quien haga demos debe saberlo: ese tramo todavía no se enseña en vivo.

---

## 3.bis. Por qué contesta bien — la sección que nos separa de un chatbot

**El modelo lo tiene cualquiera. Las correcciones no.** Esta sección cuenta el foso, y es cierta:

> ### No lo entrenamos en un laboratorio. Lo afinamos con conversaciones reales.
>
> Cada duda que un cliente hace por WhatsApp —el deducible, qué pasa si el conductor había bebido, si cubre a un tercero— la hemos visto de verdad. Y cada vez que la IA contestó de una forma que no servía, se lo corregimos.
>
> Lo que queda es un catálogo de lo que la gente pregunta en México y la forma exacta de responderlo.

**Ejemplos reales de esas correcciones**, para dar cuerpo a la sección:

- Un cliente pidió «algo mínimo para circular» y el sistema le ofrecía la cobertura **más cara**. Ahora primero se le dice con claridad que **eso no existe como producto** y después se le ofrece **la más barata de su cotización**.
- Escribió una cifra con **un dígito cambiado**. Ahora una barrera **compara la cifra contra el dato antes de que el mensaje salga**.
- Afirmaba una cobertura que el cliente **no había contratado**. Corregido en el dato y con un freno detrás.

**Y el hallazgo que hace creíble todo lo anterior:** aprendimos que **un prompt no gobierna un dato exacto**. Por eso las correcciones que importan no viven en las instrucciones al modelo: **viven en la infraestructura**.

**Prohibido decir «entrenado».** En IA significa ajustar los pesos con un dataset y no es lo que hacemos; el primer técnico que lo lea lo desmonta. Di **«afinado»**, **«corregido con conversaciones reales»** o **«aprendido en producción»**.

---

## 3.ter. Requisitos de las animaciones

Las conversaciones de arriba deben **discurrir solas**: burbujas que aparecen con su ritmo, «escribiendo…», horas, doble check azul y adjuntos de PDF.

- **Ritmo humano.** Pausa de lectura entre burbujas, y «escribiendo…» antes de las del bot. Una conversación entera en **12–20 segundos**.
- **Pausable y rebobinable.** Un comprador quiere leer, no perseguir.
- **Sin JavaScript pesado.** Prioriza CSS y SVG; si usas JS, que degrade a un estado final legible.
- **`prefers-reduced-motion`** respetado: quien lo tenga activado ve la conversación completa y quieta.
- **Legibles en móvil**, que es donde se lee más de la mitad del tráfico B2B.
- **Nada de mockups de teléfono con brillos.** El marco, sobrio; que no le robe atención al contenido.

## 4. El dashboard es OTRO PLANO, no una función más

Los cuatro verbos describen **lo que el sistema hace solo**. El dashboard es lo contrario: **lo que hace el cliente sobre él** — medir y, si quiere, entrar. Por eso vive en la bajada del titular y no en la enumeración.

Su trabajo en la página es **desarmar el miedo** que provoca el titular: «esto vende y emite solo» le suena a un asegurador a *«¿y yo qué controlo?»*. Promesa arriba, tranquilidad debajo.

La segunda animación en importancia: **la aseguradora tomando el control**. Una conversación corriendo sola, un operador pulsa «Tomar conversación», el bot se calla, la persona escribe, y al soltar el bot continúa. Eso responde de golpe al miedo del comprador: *«¿y si la IA la lía?»*

Enseña también, con datos verosímiles: el estado de los leads, el embudo, y las conversaciones en curso.

## 5. Estructura de página que propongo — discútela si crees que hay otra mejor

1. **Héroe** — el titular de la sección 0. Debajo, la conversación de **EMITE** ya corriendo: el final es lo que se compra.
2. **El problema** — lo que hoy pasa sin esto: el lead se enfría, nadie llama, el recibo vence y la póliza se cancela.
3. **Los cuatro verbos, uno por sección, con su captura** — COTIZA, RESUELVE, EMITE, COBRA. Es el corazón de la página.
4. **Por qué contesta bien** — la sección 3.bis: el foso de las correcciones reales.
5. **El control es tuyo** — el dashboard y la toma humana. Va después de los verbos, porque primero se promete y luego se tranquiliza.
6. **Cómo encaja** — se conecta con la tarificación, la emisión y los pagos que la aseguradora **ya tiene**, a **una o a varias a la vez**, sin pedirle que cambie de sistema. Aquí va el diagrama de tres planos.
7. **Prueba** — métricas o casos. *(Hoy no hay cifras públicas verificadas. Deja los huecos como `[MÉTRICA POR CONFIRMAR]`; **no inventes números**.)*
8. **Cierre** — una acción sola: «Ver una demo». Vender a una aseguradora no es autoservicio.

## 5.bis. La tecnología: dónde va y cómo se cuenta

Usamos modelos frontera de **Anthropic (Claude)** para la conversación y una capa propia de orquestación de eventos. Hay que ponerlo en valor, **pero no en el titular**: quien firma no compra el motor, compra que venda, emita y cobre.

**Y el argumento fuerte no es «usamos IA de punta».** A un director de una aseguradora eso le suena a riesgo. Lo que le quita el miedo es lo contrario:

> ### Conversa como una persona. Se equivoca como una máquina: no puede.
>
> Modelos frontera de Anthropic para entender y responder. Y barreras deterministas delante de cada mensaje que sale, para que la IA no pueda inventarse una cifra, prometer una cobertura que no existe ni mandar dos veces lo mismo.

**Las cinco barreras, una por línea, en la sección de confianza.** Ninguna depende de que el modelo se porte bien — están en la infraestructura, no en el prompt:

- No puede decir una cifra que no esté en la cotización.
- No puede afirmar una cobertura que el cliente no tiene contratada.
- No puede anunciar dos veces el mismo descuento.
- No puede desmentir una póliza que sí se emitió.
- Ningún mensaje se envía dos veces, aunque el sistema se caiga a mitad.

**Reglas de cómo nombrar la tecnología:**

- **Anthropic / Claude: sí.** Suma credibilidad.
- **Nombres de herramientas de orquestación: no.** Di la capacidad —«orquestación de eventos con reintentos, idempotencia y control de concurrencia»—, no el proveedor. A un departamento de sistemas, el nombre le abre la pregunta equivocada justo cuando querías que preguntara otra.
- **Versiones de modelo: nunca.** Envejecen en seis meses y no aportan.
- **«IA» no es una caja de un diagrama.** Es cómo funciona la conversación.

## 6. Qué evitar

- **Tópicos de SaaS genérico.** Nada de gradientes morados con blobs, «Impulsado por IA» como titular, ni ilustraciones isométricas de gente con portátiles.
- **Prometer lo que no hace.** No es un chatbot de soporte ni un CRM. Cotiza, conversa, recotiza, **emite** y cobra.
- **Cifras inventadas.** Ni conversiones, ni clientes, ni «+40 % de ventas».
- **Logos de aseguradoras reales** que no me consten como clientes.
- **Sepia de stock.** Si hace falta fotografía, que sea mínima.

## 7. Qué te falta saber, y quiero que me lo preguntes

**No tengo definida la identidad de marca** — ni paleta, ni tipografía, ni logo cerrado. Propón **dos direcciones visuales distintas** y defiende cada una en dos frases. Una de ellas debería explorar el terreno de «infraestructura financiera seria» y la otra el de «producto vivo y conversacional».

Si algo más te bloquea (idioma, mercados, si la landing también debe servir para captar al asegurado final), **pregúntamelo antes de diseñar**, no lo asumas en silencio.

## 8. Entregables

1. **Dos direcciones visuales** en formato moodboard, con paleta, tipografía y tono.
2. **Mockup completo de la página**, escritorio y móvil, en la dirección que recomiendes.
3. **Las cuatro secuencias de WhatsApp** especificadas como animación: guion de tiempos, qué entra y cuándo, y estado final estático.
4. **La animación del dashboard** con la toma de control humano.
5. **Un prototipo en HTML/CSS de una sola secuencia** — la B, la del descuento — para poder juzgar el ritmo de verdad y no en un storyboard.
6. **Los textos de la página** (titulares y subtítulos), en español de México, en el registro que uses en los mockups.

Empieza preguntándome lo que te falte. Después entrega.
