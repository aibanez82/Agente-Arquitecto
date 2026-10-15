# Iniciativa: enrutamiento de modelos LLM en Insurmind

> **Registrada:** 1 oct 2026, por encargo de Alberto («vamos a registrar una nueva iniciativa de
> infraestructura»). **Estado:** propuesta para evaluación arquitectónica; sin proveedor seleccionado.
> **Nada se ejecuta todavía.** Este documento tiene dos partes: **A**, el encargo tal como llegó, y **B**,
> mi primer contraste con el sistema real. Los entregables 1–6 están **pendientes**.

---

## B · Primer contraste con la arquitectura real (Arquitecto, 1 oct)

Solo hechos medidos o escritos en la fuente de verdad, con su ámbito y su fecha. Lo que no he mirado
se dice como tal.

### B.1 · Lo que ya existe y la iniciativa no contempla

1. **Hay un único canal conversacional con LLM: el bot de WhatsApp en n8n** (`BtOaZm7WlZT-24V7hqCnF`).
   Llama a un modelo desde **6 sitios** (`CLAUDE.md`, revalidado el 6 sep; modelos y topes confirmados el
   29 sep en el `#504`):

   | Sitio | Modelo hoy | Papel |
   |---|---|---|
   | AI Agent | `claude-sonnet-5` | agente principal, con herramientas (`Save_Group1/2/3`, emisión…) |
   | RAG IA Agent | `claude-sonnet-5` | consultas de conocimiento |
   | Discount Intent Classifier | `claude-sonnet-5` | clasificador, salida JSON |
   | Intent Router | `claude-haiku-4-5` | clasificador de intención |
   | Detect Jailbreak | `claude-haiku-4-5` | guardarraíl |
   | Extract VIN Vision | `claude-sonnet-4-5-20250929` (httpRequest directo) | visión: tarjeta de circulación |

   **Ya hay un reparto por coste**: Haiku para clasificar y Sonnet para conversar. Pero el criterio es la
   **tarea**, no el **lead**, que es lo que propone la iniciativa.

2. **Ya existe un intermediario entre n8n y Anthropic.** La credencial de los nodos de modelo apunta a un
   proxy (`autocache:8080`), no a `api.anthropic.com`. Lo midió el Agente n8n el 29 sep en el `#504`: el
   proxy **añade marcas de caché**. Con la misma llamada, la API directa factura 44.810 tokens de entrada y
   a través del proxy se registran 4.912. **No sé quién lo opera ni qué más hace.** Es lo primero que
   hay que aclarar, porque condiciona cualquier gateway nuevo: o se sustituye, o se apila encima.

3. **El caché es una parte grande del coste actual.** Cambiar de modelo a mitad de conversación lo
   **pierde**: el contexto se vuelve a pagar entero, y el `systemMessage` del AI Agent tiene unos 80.000
   caracteres. Es el coste de «repetir el contexto» que la propia iniciativa pide contar.
   Refuerza la regla de **no oscilar** dentro de una sesión.

4. **La memoria ya es portable en formato.** `n8n_chat_histories` guarda mensajes en formato LangChain. Pero
   **es la memoria del modelo, no un log** (`HYL-WAI#183`, `contextWindowLength: 60`), y solo persiste el
   último intercambio de herramienta de cada turno. Cambiar de proveedor obliga a comprobar que el otro
   modelo interpreta igual ese historial.

5. **Las guardas que importan no dependen del modelo.** Figure Fidelity Guard (`#341`/`#500`), Email
   Fidelity, Phase Guard, Issue Policy Guard y Quotation Data Guard viven en el grafo. Esto **reduce** el
   riesgo de una ruta `economy`: lo que no puede fallar no lo garantiza el modelo, sino el grafo (lección
   del 5 sep: un prompt no garantiza fidelidad de dígito).

### B.2 · Lo que no existe, o no he comprobado

- **Calificación comercial del lead.** No conozco ningún `lead_score`, fase comercial ni CRM conectado al
  bot. **No lo he buscado en el código**: está pendiente del entregable 1. Las señales que sí existen y son
  observables: `conversation_phase`, `checkpoint`, `pendiente`, hitos del embudo (`has_responded`,
  `confirmo_cobertura` —corregido en el `#502`—…), canal y precio cotizado. **El principio de la
  iniciativa, «no interpretar la falta de datos como baja calidad», aplica aquí de lleno**: hoy casi
  todos los leads llegan sin puntuación.
- **Tratamiento de datos por terceros.** Por el bot pasan datos personales: nombre, fecha de nacimiento,
  número de serie, domicilio y RFC. Enviarlos a otro proveedor, o a un enrutador como OpenRouter, que
  reparte entre varios, es un requisito **legal y contractual** que no he revisado. Entra en el entregable 4.

### B.3 · Restricciones que pongo desde ya

1. **Ninguna ruta cambia en fases que tocan dinero o emisión** (`summary_confirmation`,
   `policy_issuance`, `payment_pending`): ahí manda la ruta con la que se validó la emisión. Es la misma
   línea de la autorización permanente: lo que roza pagos o emisión exige orden explícita.
2. **El `systemMessage` está ajustado a Claude.** Una ruta con otro proveedor no hereda la validación: hay
   que volver a validarla entera (detectores de hitos, herramientas `$fromAI`, formato de fase
   `[phase:…]`). Es el criterio 3 de la iniciativa, y es el más caro.
3. **El interruptor de reversión tiene que ser de configuración, no de grafo**, para que revertir no exija un
   import a PROD.

### B.4 · Orden propuesto de los entregables

1. **Mapa de integración** (entregable 1): quién opera `autocache:8080`, inventario de señales del lead que
   existen de verdad, y coste actual por conversación con caché. **Es lectura, y lo puedo hacer yo.**
2. **Revisión de requisitos de datos** (entregable 4) **antes** de elegir proveedor: si OpenRouter o un
   modelo abierto no pueden recibir datos personales, se descartan antes de compararlos.
3. Con eso, decisión arquitectónica, contrato y política, backlog y plan de evaluación (entregables 2, 3, 5 y 6).

**Toca a Juan:** el backend de leads es suyo (Django). Si la calificación vive en el backend, la iniciativa
roza su plan, y hay que alertarlo antes de diseñar contrato.

---

## A · El encargo, tal como llegó (1 oct 2026)

> Texto recibido de Alberto. Se conserva literal; solo se ha restituido la «I» inicial del título, que
> faltaba en el pegado.

**Destinatario:** agente arquitecto del proyecto Insurmind  
**Estado:** propuesta para evaluación arquitectónica; sin proveedor seleccionado  
**Fecha:** 1 de octubre de 2026

### Petición al agente arquitecto

Recoge esta iniciativa en la planificación del proyecto, contrástala con la arquitectura existente y propón un diseño y un MVP. Identifica los componentes reutilizables, las dependencias, las decisiones pendientes y las tareas necesarias. La iniciativa no presupone contratar un proveedor ni desplegar infraestructura antes de evaluar las alternativas.

### Objetivo de negocio

Asignar el modelo LLM más adecuado a cada conversación según la audiencia, la calidad del lead y la complejidad de la consulta, para optimizar el coste de atención manteniendo la calidad comercial.

Caso planteado: utilizar un modelo de OpenAI para un cliente potencial cualificado y un modelo de código o pesos abiertos para un lead de baja calidad. Esta asignación es una hipótesis inicial que debe validarse con métricas: un modelo abierto no es necesariamente más barato ni menos capaz, y un modelo propietario económico también podría cubrir la ruta de menor coste.

### Separación de responsabilidades

1. **Calificación:** obtener la audiencia, fase comercial y puntuación del lead desde el CRM o las reglas existentes. Si no hay información suficiente, valorar un clasificador específico. El gateway no debe considerarse una fuente automática de calificación comercial.
2. **Política de enrutamiento:** convertir esas señales en una ruta lógica, por ejemplo `economy` o `premium`, mediante reglas explícitas y versionadas.
3. **Gateway:** ejecutar la llamada al modelo seleccionado y gestionar las capacidades operativas necesarias, como credenciales, límites, trazabilidad y respaldo ante fallos.
4. **Estado conversacional:** conservar en Insurmind el historial y los datos necesarios para mantener la continuidad al cambiar de modelo.

Flujo conceptual, pendiente de adaptar al proyecto:

```text
Canal de conversación
  → Backend de Insurmind
  → Contexto del lead / CRM / calificación
  → Política de enrutamiento
  → Gateway
  → Modelo asignado
  → Respuesta y registro de métricas
```

La política puede ejecutarse en el backend o en un gateway que soporte condiciones por metadatos. El arquitecto debe elegir dónde reside y evitar duplicar reglas entre ambos.

### Política inicial propuesta

Los umbrales son ilustrativos; no constituyen una decisión de producto.

| Situación | Ruta propuesta | Observación |
|---|---|---|
| Lead cualificado o puntuación ≥ 70 sobre 100 | `premium` | Modelo de OpenAI como candidato inicial. |
| Lead poco cualificado y consulta sencilla | `economy` | Modelo económico validado; evaluar pesos abiertos. |
| Lead desconocido o puntuación ausente | Calificación inicial en `economy` | No interpretar la falta de datos como baja calidad. Escalar si aparece complejidad o intención clara de compra. |
| Aumento de intención comercial o consulta que excede la capacidad de la ruta económica | Escalar a `premium` o a una persona | Definir señales observables y mecanismos de escalado. |
| Error, timeout o indisponibilidad del proveedor | Modelo de respaldo permitido | Es una política técnica distinta de la calificación comercial. |

Definir la precedencia entre reglas. Una puntuación baja no debe impedir el escalado por complejidad. Una vez escalada una conversación, evitar oscilaciones innecesarias entre modelos; proponer persistencia de ruta durante la sesión y criterios explícitos de reevaluación.

### Contexto mínimo para decidir y auditar

Propuesta de contrato interno, no de API definitiva:

```json
{
  "conversation_id": "conv_123",
  "audience": "prospect",
  "lead_score": 82,
  "lead_score_status": "known",
  "lead_score_source": "crm",
  "commercial_stage": "qualified",
  "task_complexity": "standard"
}
```

Los campos de decisión deben provenir del backend o de fuentes controladas. No confiar en etiquetas que el usuario pueda modificar directamente. Distinguir los datos usados internamente de los metadatos que se envían a un tercero: transmitir solo los necesarios.

Registrar la ruta elegida, el motivo, la versión de la política, el modelo y proveedor efectivos, la latencia, el consumo, el coste disponible o estimado y los fallos o escalados. Evitar registrar el contenido completo de las conversaciones por defecto si no es necesario.

### Alternativas a evaluar

| Alternativa | Encaje preliminar | Aspectos que debe validar el arquitecto |
|---|---|---|
| **Portkey** | Enrutamiento condicional por metadatos o parámetros. | Integración con el stack, despliegue, condiciones comerciales y controles disponibles. |
| **LiteLLM** | Gateway con interfaz común, grupos de modelos y enrutamiento por etiquetas. | Ubicación de la lógica comercial, carga operativa y capacidades de la edición elegida. |
| **OpenRouter** | Acceso a distintos modelos y mecanismos de selección y respaldo. | Regla comercial en el backend, proveedores efectivos y condiciones de tratamiento de datos. |
| **Integración directa con una capa propia mínima** | Alternativa para un MVP con dos rutas. | Comparar simplicidad inicial con el coste de mantener adaptadores, métricas y respaldo. |

La selección automática según el prompt no sustituye a una política basada en valor comercial. Comparar modelos concretos mediante conversaciones representativas, sin asumir que la marca o la licencia determinan su calidad.

Fuentes técnicas de referencia —verificar vigencia al diseñar—:

- [Portkey: Conditional Routing](https://portkey.ai/docs/product/ai-gateway/conditional-routing)
- [LiteLLM: Router](https://docs.litellm.ai/docs/routing)
- [LiteLLM: Tag Based Routing](https://docs.litellm.ai/docs/proxy/tag_routing)
- [OpenRouter: Auto Router](https://openrouter.ai/docs/guides/routing/routers/auto-router)
- [OpenRouter: Model Fallbacks](https://openrouter.ai/docs/guides/routing/model-fallbacks)

### Alcance del MVP

- Un canal de conversación existente, a elegir tras inspeccionar el proyecto.
- Dos rutas lógicas, `economy` y `premium`, sin acoplar la lógica comercial a identificadores concretos de modelos.
- Reglas deterministas a partir de datos disponibles; incorporar clasificación con LLM solo si existe una carencia justificada.
- Reevaluación del lead en eventos relevantes y escalado conservando el contexto.
- Respaldo técnico explícito, con límites de reintentos, tiempo y coste.
- Métricas por conversación y segmento, y configuración que permita desactivar el enrutamiento y volver al comportamiento previo.
- Evaluación con conversaciones representativas antes de habilitar tráfico real y despliegue gradual posterior.

Fuera del MVP: entrenamiento de un router propio, fine-tuning, optimización autónoma de políticas y despliegue de GPUs propias salvo justificación económica o requisito existente.

### Criterios de aceptación

1. Las mismas señales y versión de política producen una decisión reproducible y explicable.
2. Los casos de lead cualificado, baja calificación, datos ausentes y escalado por complejidad tienen resultados definidos y verificados.
3. Cambiar de modelo conserva los datos, el historial necesario y las instrucciones de negocio; las herramientas y salidas estructuradas requeridas funcionan en ambas rutas.
4. Un fallo del proveedor activa únicamente destinos permitidos y respeta los límites configurados.
5. Se puede conocer qué modelo atendió cada conversación y comparar coste, latencia, calidad y escalados entre rutas.
6. Existe una forma operativa de revertir la activación sin perder el estado conversacional.
7. Antes de producción, producto y arquitectura fijan umbrales de calidad y ahorro y verifican que el piloto los cumple.

### Métricas y evaluación económica

Medir coste por conversación y por lead convertido, conversión por segmento, calidad de respuesta, tasa de intervención humana, latencia y errores. Comparar cohortes equivalentes: comparar directamente leads de alta y baja calidad confundiría el efecto del modelo con el valor inicial del lead.

Incluir en el coste total el gateway, la inferencia, la clasificación, los reintentos, la repetición del contexto al cambiar de modelo y la operación de infraestructura propia, si aplica. Mantener un nivel mínimo de calidad en todas las rutas para no perder oportunidades por una calificación inicial incorrecta.

### Decisiones pendientes y entregables

El agente arquitecto debe entregar:

1. **Mapa de integración:** componentes actuales afectados, origen de las señales y estado de la calificación comercial existente.
2. **Decisión arquitectónica documentada:** opción recomendada, alternativas, costes, dependencias y motivos.
3. **Diseño del contrato y la política:** precedencia, datos ausentes, continuidad de sesión, escalado y respaldo.
4. **Revisión de requisitos existentes:** ubicación de datos, retención, acceso a registros y destinos permitidos; el respaldo debe respetar las mismas restricciones.
5. **Backlog del MVP:** tareas, dependencias, estimación y pruebas de aceptación.
6. **Plan de evaluación y lanzamiento:** conjunto de conversaciones, métricas, umbrales pendientes de acordar, piloto y reversión.

No se ha inspeccionado la arquitectura actual de Insurmind para redactar esta iniciativa. Los nombres de campos, rutas y componentes son propuestas para que el arquitecto las adapte al proyecto.
