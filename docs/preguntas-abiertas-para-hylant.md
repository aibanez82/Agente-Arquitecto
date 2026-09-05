# Preguntas abiertas para Hylant

> Preparado por el Arquitecto-IA · 4 sep 2026
> Son las dudas que **no se pueden resolver midiendo**: necesitan criterio asegurador o decisión de negocio.
> Cada una dice **qué desbloquea**, para que se puedan priorizar en la conversación.

---

## 1 · La Limitada, el incendio y la inundación — la más urgente

**Lo que dicen las Condiciones Generales** (cobertura 2, Robo Total):

> «ampara, **aun cuando no haya sido contratada la cobertura de Daños Materiales**, los daños ocasionados por los riesgos de los incisos **c, d, e, f y h** de la cobertura 1»

Y esos incisos son **incendio, rayo y explosión** (c), **fenómenos naturales incluida inundación** (d), motines (e), transporte (f) y desbielamiento por inundación (h).

**La pregunta:** un cliente con **Cobertura Limitada** —que incluye Robo Total— ¿está realmente amparado si su coche **se incendia** o **se inunda**?

**Y las tres que la acompañan:**
- ¿Con qué **suma asegurada** se indemniza? ¿La de Robo Total?
- ¿Qué **deducible** aplica? ¿El 10 % de Robo Total, el 5 % de Daños Materiales, o ninguno?
- Los **cristales** (inciso b) **no** están en esa lista. ¿Se confirma que un Limitada **no** tiene cristales?

**Qué desbloquea:** hoy nuestra base de conocimiento dice que la Limitada **no** cubre nada de eso, y el bot se lo repite a los clientes. Si la respuesta es que sí están cubiertos, **estamos diciéndole a gente con siniestro real que no tiene cobertura** — y puede que alguno no haya reclamado. Es el issue `#320`.

---

## 2 · Responsabilidad Civil circulando en Estados Unidos

Las Condiciones Generales (cláusula 9ª, territorialidad) dicen que **no**. Alberto le ha dicho a algún cliente que **sí, mediante endoso**.

**La pregunta:** ¿existe ese endoso? ¿Cómo se contrata, qué cuesta y se puede ofrecer desde este canal?

**Qué desbloquea:** hoy el bot no sabe qué responder y las dos fuentes se contradicen. Cualquier respuesta que demos es un compromiso comercial.

---

## 3 · La declaración PEP

La quitamos hoy de lo que el bot pide, por decisión de Alberto: el endpoint de emisión por WhatsApp no la exige y los campos son opcionales en el formulario web.

**La pregunta:** ¿es un requisito **regulatorio** (prevención de lavado) que deba recogerse igualmente en algún momento del proceso, aunque el sistema no lo bloquee?

**Qué desbloquea:** si la respuesta es que sí, hay que recogerla en otro punto y no simplemente eliminarla. Es la única de esta lista con posible implicación de cumplimiento.

---

## 4 · Qué es exactamente la «suma asegurada» que ve el cliente

El PDF de la cotización imprime **«VALOR CONVENIDO»** en Daños Materiales y Robo Total, **sin cifra**. El detalle técnico sí devuelve un número (por ejemplo, 310.500 para un vehículo concreto).

**Las preguntas:**
- ¿Ese número **es** lo que se indemnizaría, o el valor convenido se determina en el momento del siniestro?
- ¿Se le puede decir al cliente esa cifra, o hay riesgo de comprometer un importe que luego no sea el que se pague?

**Qué desbloquea:** el bot hoy **se calla** por prudencia (`#293`), y quien pregunta por el alcance de su póliza **convierte a la mitad** — 9-10 % frente a 19-21 %. Poder responder esa pregunta con seguridad es el mayor margen de mejora medido que tenemos.

---

## 5 · Los campos `valor_uno` y `valor_dos` del catálogo

Son dos números que llegan en cada cotización y **no sabemos qué representan**. Medido: `valor_dos` unas veces coincide con la suma asegurada y otras es su 90 %; `valor_uno` ronda el doble.

**La pregunta:** ¿qué son? ¿Valor factura, valor comercial, rango de aseguramiento?

**Qué desbloquea:** el bot llegó a decir «tu Ford Fusion tiene un valor asegurado de $422,000» cuando el dato real era 224.100. Hoy tiene prohibido nombrarlos. Si supiéramos qué son, dejarían de ser un número prohibido.

---

## 6 · `tipo_suma = 2`

Todas las coberturas de todas las cotizaciones llegan con `tipo_suma = 2`, y el catálogo de referencia solo define **0, 1 y 3**.

**La pregunta:** ¿qué significa el 2?

**Qué desbloquea:** poco por sí solo, pero es un campo que describimos como desconocido en un dato que enseñamos al cliente. Aprovechar la conversación para cerrarlo.

---

## 7 · El deducible como configuración

Medido en 7.932 bloques de 1.322 cotizaciones, **sin una sola excepción**: Daños Materiales 5 %, Robo Total 10 %, el resto 0.

**Las preguntas:**
- ¿Es una configuración del paquete que Hylant fija, o puede variar por vehículo, zona o cliente?
- Si es fija, ¿podemos decirla en la conversación sin consultar la cotización?

**Qué desbloquea:** hoy el bot manda al cliente al PDF a buscar el porcentaje. Si es constante y está confirmado, puede decirlo directamente.

---

## 8 · Qué cuenta como «pagado»

Hoy la verdad del pago vive en tres sitios que no coinciden: el redirect del navegador de Quálitas, el listado de recibos del portal, y el Excel que Laura envía al día siguiente.

**La pregunta:** ¿cuál es la fuente oficial? Y en concreto, **¿qué debe pasar con un recibo `VENCIDO` o `CANCELADO`** en cuanto al estado de la póliza y a la gestión de cobranza?

**Qué desbloquea:** es una decisión pendiente desde hace semanas, y de ella depende toda la cobranza automática y los recordatorios de pago.

---

## 9 · Los descuentos, si aplica preguntarlo aquí

El programa que se ofrece en producción es `POR_PRECIO_ALTO_PARA_IA_30` (**30 %**), y lo acordado era **40 %** en objeción.

**La pregunta:** ¿el 40 % está autorizado por Quálitas/Hylant, sobre qué base se calcula y tiene tope de uso?

**Qué desbloquea:** el `#301`. Puede que sea decisión interna y no haga falta preguntarlo fuera — en ese caso, ignorar este punto.

---

## 10 · Los meses sin intereses en NUESTRA liga de pago

Nuestra base de conocimiento dice que Quálitas ofrece **MSI a 3, 6 y 12 meses** con 25 bancos participantes, en el módulo **«Pago de Póliza» de Servicios en Línea**, cuando la póliza se paga de contado.

**La pregunta:** la **liga de pago que enviamos por WhatsApp** ¿es ese mismo módulo y le ofrece al cliente la opción de diferir a meses sin intereses?

**Qué desbloquea:** el `#326`. Hoy el bot le dice al cliente **«no manejamos meses sin intereses»** — que es falso — justo después de ofrecerle el fraccionado **con tasa de financiamiento**. Es la respuesta natural a la objeción de precio y la estamos tirando. Pero si la liga no lo ofreciera, prometerlo sería peor que callarlo: el cliente llegaría a pagar y no lo encontraría.

---

*Las diez salen de mediciones hechas contra las fuentes: Condiciones Generales, base de conocimiento, base de datos de producción y conversaciones reales. Ninguna es una suposición; todas son un hueco que ningún dato nuestro puede rellenar.*

Agente: Arquitecto-IA-Qualitas
