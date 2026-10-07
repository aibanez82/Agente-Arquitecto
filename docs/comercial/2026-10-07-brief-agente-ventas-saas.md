# Brief para el Agente de Ventas — cómo comercializar Insurmind como SaaS

**De:** Arquitecto-IA-Insurmind · **Para:** Agente de Ventas · **7 oct 2026**
**Encargo de Alberto:** *«Hoy en día no sabemos cómo comercializarlo. Me gustaría que crearas un md para que este
agente lo tome y nos dé unas propuestas de comercialización del producto que incluya modelos y precios.»*

---

## 1. Lo que te pedimos

Propuestas de **comercialización de Insurmind como SaaS**, con **modelos de negocio y precios**. No queremos un
catálogo de opciones: queremos **2 o 3 propuestas defendibles y una recomendación**.

Entrega un documento con:

1. **Segmentos de cliente**, priorizados: a quién vender primero y por qué.
2. **2-3 propuestas de modelo de negocio.** Para cada una: qué se cobra, cómo se empaqueta, **precio con rango y
   supuestos**, quién es el comprador y qué objeción va a poner.
3. **Tabla comparativa** de las propuestas: ingreso esperado por cliente, riesgo, tiempo hasta el primer ingreso,
   facilidad de venta y alineación con el valor que entregamos.
4. **Recomendación** y por qué.
5. **Plan de entrada al mercado** para la recomendada: piloto, contrato, primeros 3 clientes y canal.
6. **Supuestos y huecos de datos:** qué número tendría que confirmar Alberto para cerrar el precio.
7. **Riesgos**, incluido el regulatorio (ver §6).

**Regla dura: no inventes cifras de Insurmind.** Todo número que atribuyas a nuestra operación tiene que estar en
este brief o marcarse como `[POR CONFIRMAR]`. Los benchmarks de mercado (precios de competidores, comisiones típicas)
sí los puedes investigar, pero **cada uno con su fuente**.

---

## 2. Qué es Insurmind

**Agentes de IA que se conectan a cualquier aseguradora en México para cotizar, resolver, emitir y cobrar**, por
canales conversacionales (WhatsApp hoy), sobre la tarificación, la emisión y los pagos que el cliente ya tiene. Una
o varias aseguradoras a la vez.

**Titular cerrado (6 sep 2026), no lo reabras:**
> **Cotiza, resuelve, emite y cobra. Sin intervención.**
> Sobre las aseguradoras que ya usas — una o varias a la vez.

### Lo que hace hoy, en operación real (seguro de auto, Quálitas, México)

| Verbo / pieza | Qué hace |
|---|---|
| **Cotiza** | Landing web y WhatsApp. Cotiza en el webservice de la aseguradora y manda el PDF de la cotización. |
| **Resuelve** | Agente conversacional por WhatsApp: dudas de coberturas, deducibles y formas de pago con base de conocimiento, objeciones de precio y **descuentos** gestionados por reglas. |
| **Emite** | Recoge los datos por chat (incluida la lectura del VIN desde la foto de la tarjeta de circulación), los valida y emite la póliza real en la aseguradora. |
| **Cobra** | Genera la liga de pago de la aseguradora, concilia el pago y controla los recibos de las pólizas fraccionadas. |
| **Recupera** | Campañas por WhatsApp a prospectos cuya póliza anterior se canceló o venció (en lanzamiento). |
| **Centro de control** | Dashboard en tiempo real de leads y conversaciones; un humano puede **tomar la conversación** en cualquier momento. |

**Argumento diferencial:** *«Conversa como una persona; donde no puede equivocarse, no se equivoca.»* Usamos modelos
frontera de **Anthropic (Claude)** para conversar, con **barreras deterministas** para lo que no admite error:
cifras, datos de emisión y pagos. Las cifras que ve el cliente las pone el sistema, no el modelo.

**El foso:** meses de corregir cómo contesta la IA **leyendo conversaciones reales de producción**. Es aprendizaje
en producción, no un modelo «entrenado».

### Lo que NO es

- **No es un core asegurador.** No guarda la póliza de registro, ni siniestros, ni contabilidad técnica. La
  emisión es una llamada al webservice de la aseguradora. Insurmind es **todo lo que pasa antes y después del
  core**.

**Palabras prohibidas:**
- «core asegurador» → di «antes y después del core»;
- «modelos entrenados» → di «afinados con conversaciones reales» o «aprendido en producción»;
- versiones de modelo, nunca;
- el orquestador interno no se nombra.

---

## 3. Comprador

Según la estrategia de la web pública: **director comercial o de sistemas de una aseguradora o de un broker**. No
el asegurado.

Explora también, y di si tienen sentido:
- promotorías y agentes con volumen;
- bancaseguros y retail que venden seguro como complemento;
- **aseguradoras sin canal digital** frente a **brokers multi-aseguradora**. Son compras muy distintas: uno quiere
  canal y el otro, comparador más cierre.

---

## 4. Caso de referencia: datos reales de operación

Operación con **Quálitas**, marca Quálitas/Hylant, seguro de auto en México, desde **junio de 2026**. Hylant es el
agente de seguros de la operación.

**Censo de pólizas reales** (medido el 10 sep 2026, descontadas las de usuarios de prueba):

| | Pólizas | |
|---|---|---|
| Emitidas reales | **46** | |
| Pagadas | 25 | 54 % |
| Canceladas por la aseguradora sin pagar el primer recibo | 20 | 43 % |

**Lectura que importa para vender:** el sistema cotiza y emite bien; donde se pierde dinero es en **cobrar el
primer recibo**. De las 20 perdidas, a la mitad nunca se le envió la liga de pago por WhatsApp. Es una debilidad
del caso y, a la vez, el argumento de valor de **Cobra**.

**Volumen bruto de cotizaciones por mes** (`qualitas_cotizacion`; incluye pruebas, úsalo solo como orden de
magnitud): jun 237 · jul 1.065 · ago 42 · sep 192 · oct (1-7) 608. **El volumen depende de si hay pauta de
Google Ads:** sin pauta, casi cero.

**Lo que NO tenemos medido, y no debes afirmar** (márcalo `[POR CONFIRMAR]`):
- tasa de conversión cotización → póliza pagada limpia, sin pruebas y por canal;
- prima media por póliza;
- coste de adquisición por lead;
- ahorro de horas de agente humano;
- NPS o satisfacción.

**Atención humana:** hoy hay personas de apoyo (contact center de Metepec) mientras el sistema madura. **El estado
final es sin personas.** No vendas un modelo que dependa de que exista un humano.

---

## 5. Costes conocidos (para que el precio no quede por debajo del coste)

| Concepto | Lo que sabemos | Estado |
|---|---|---|
| Modelos de IA | Por cada mensaje del cliente hay varias llamadas: agente principal y RAG con Claude Sonnet, clasificadores con Haiku. Medido el 1 oct en 216 ejecuciones de PROD: el agente principal registra una mediana de ~7.900 tokens de entrada por llamada, con caché de prompt activo. | **Coste por conversación y por póliza `[POR CONFIRMAR]`**: calcúlalo con precios públicos de Anthropic y di tus supuestos (turnos por conversación) |
| WhatsApp (Meta) | Se paga por conversación o plantilla según la categoría (marketing, utilidad, servicio). | Tarifa vigente para México `[POR CONFIRMAR]`, con fuente |
| Infraestructura | Backend Django en Heroku, orquestación en un VPS, dashboard en Vercel, Postgres gestionado. | Coste mensual `[POR CONFIRMAR]` |
| Integración por aseguradora | Cada aseguradora nueva exige integrar su webservice de cotización, emisión, impresión y pago. Con Quálitas existe y funciona. | Esfuerzo por aseguradora `[POR CONFIRMAR]`; es el principal coste de implantación de un cliente nuevo |

---

## 6. Restricciones y riesgos que la propuesta debe tratar

- **Regulatorio (México).** La intermediación de seguros la regula la CNSF y exige figura de agente. Un modelo que
  cobre un **porcentaje de la prima o de la comisión** puede rozar la intermediación si Insurmind no es agente.
  **No concluyas tú la legalidad:** señala qué modelos necesitan revisión legal y cuáles son claramente de
  software (licencia, uso, setup).
- **Dependencia de la aseguradora:** precios y productos los fija ella, y sin su webservice no hay emisión.
- **Estacionalidad y pauta:** el volumen depende del tráfico que compre el cliente. Un precio solo variable deja a
  Insurmind expuesto a meses de cero.
- **Responsabilidad por errores:** el sistema emite pólizas reales. Contemplar SLA y responsabilidad en el
  contrato.

---

## 7. Modelos que esperamos que evalúes (como mínimo)

1. **Suscripción SaaS por niveles**, empaquetada por verbos (Cotiza → +Resuelve → +Emite → +Cobra) y centro de
   control, con límites de conversaciones o pólizas.
2. **Setup + cuota mensual + variable por póliza emitida** (o **por póliza cobrada**, que alinea con el valor real
   según el §4).
3. **Precio por resultado:** por póliza pagada o por recibo cobrado. Con el riesgo regulatorio del §6.
4. **Uso:** por conversación o por mensaje, sobre el coste de IA y de WhatsApp.
5. **Licencia por aseguradora o marca blanca** para aseguradoras que quieren su propio canal.

Para cada uno: ejemplo numérico con un cliente tipo. Define tú el cliente tipo y escribe los supuestos (pólizas al
mes, prima media), marcados como supuestos.

---

## 8. Tono y formato

- En español de España (tú/tienes, no vos).
- Directo: empieza por la recomendación y después el detalle.
- Tablas para comparar y prosa corta para razonar.
- Separa siempre **dato** (de este brief o con fuente), **supuesto** (tuyo, declarado) y **opinión**.

Agente: Arquitecto-IA-Insurmind
