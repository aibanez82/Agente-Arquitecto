# Iniciativa — La póliza actual del lead: leerla, compararla con nuestra cotización y argumentar

**Pedida por:** Alberto, 10 oct 2026. **Dueño del diseño:** Arquitecto-IA-Insurmind. **Tracker:** `aguayo-co/HYL-WAI#594`.

## Lo que pide Alberto (literal)

> «Es posible que algunos leads nos manden una foto o un pdf con la póliza que tienen hoy contratada. Tenemos que ser capaces de extraer y entender esa información. También de comparar su póliza con nuestra cotización y también ser capaces de argumentar por qué nuestra póliza es más conveniente. Si no lo es, tenemos que argumentar que Quálitas es la aseguradora número 1 en autos en México y que en caso de siniestro nuestro servicio de atención es el número uno en México.»

## Lo que ya existe (medido el 10 oct en PROD, bot `c31d2687`)

| Pieza | Estado |
|---|---|
| **Foto** de una póliza | **Ya se reconoce** (`#581`): `Parse VIN Extraction` clasifica `[IMAGEN_CLIENTE] tipo=poliza_anterior` y extrae parte de la carátula. Caso real: la prueba de Alberto (`waq_4395`, fila 14957), una póliza de ANA Seguros de un X-Trail 2023: «Vi la póliza que compartiste…». **No compara:** solo describe |
| **PDF** de una póliza | **No se soporta.** `Session Context Builder` trata `document` (igual que audio, vídeo o sticker) como `[MEDIA_NO_SOPORTADA]`. Desde el 1 sep hay 8 medios no soportados en PROD; no consta cuántos eran PDF |
| Fotos de pólizas en PROD | 1 desde el 1 sep (la de la prueba). **La demanda real está sin medir:** habrá que mirarla antes de construir mucho |
| Piezas vecinas | `#553` (oferta de la competencia: pedir precio y cobertura); c1 / `fecha_inicio` (cuando vence la actual, la nueva empieza ese día); `#543` / `#566` (renovación y póliza nuestra) |

## Qué hay que construir (por fases)

**Fase 1: leer**
- Aceptar el **PDF** (hoy no soportado), además de la foto. Que la póliza se convierta en **datos estructurados**: aseguradora, vehículo, vigencia (desde/hasta), coberturas (DM, RT, RC con su suma, GM, asistencias…), deducibles, sumas aseguradas, prima total y forma de pago.
- Cada dato con su **confianza**, y **sin inventar lo que no se lea**.

**Fase 2: comparar** (lo pone el grafo, no el modelo)
- Cobertura a cobertura contra **nuestra cotización vigente**: los XML y la tarifa de Quálitas que ya consulta `Get_Quotation_Data`.
- La comparación es **determinista**: qué cubre cada una, con qué suma y deducible, y el precio. **Las cifras son exactas y las calcula el sistema** (`#341`/`#324`).
- Si una cobertura no es comparable (otra definición, otra suma), se dice así, sin forzar una conclusión.

**Fase 3: argumentar**
- **Si la nuestra conviene** (más barata a igual cobertura, o más cobertura por un precio parecido): el argumento con las cifras de la comparación.
- **Si no conviene:** el argumento de Alberto, Quálitas como **número 1 en autos en México** y **número 1 en atención de siniestros**.
- **Enganche con la vigencia:** si la actual vence pronto, «te preparo la nueva para que empiece justo el día que vence» (c1).

## Arquitectura: un nodo especialista en pólizas (Alberto, 10 oct: «es conveniente tener un nodo especialista en reconocer pólizas»)

**De acuerdo, y como sub-workflow propio, no como un caso más del lector de tarjetas.**
- Hoy `Extract VIN Vision` + `Parse VIN Extraction` hacen dos trabajos: reconocer **qué** es la imagen y leer la tarjeta. Meter ahí la lectura de una póliza (decenas de campos, varias páginas, PDF) lo sobrecargaría, y cualquier cambio rozaría la lectura del VIN, que ya funciona.
- **Propuesta:** el lector actual solo **clasifica** (tarjeta / póliza / otra) y lee la tarjeta. Si es una **póliza** (foto o PDF), la pasa a un **«Lector de Pólizas»** especialista: un sub-workflow con su propio prompt, su **esquema de salida fijo** (JSON con cada campo y su confianza), su modelo y el soporte de PDF. Devuelve datos, no texto para el cliente.
- **El comparador** (fase 2) es **otro nodo, de código**, sin modelo: recibe los datos del lector y la cotización vigente, y devuelve la tabla de diferencias con las cifras exactas.
- **El bot** solo recibe un resumen ya comparado en el `[CTX:]` (o un carril con texto firmado) y argumenta.
- **Ventajas:**
  - se prueba aislado, con un banco de pólizas reales anonimizadas;
  - se puede cambiar de modelo sin tocar el bot;
  - es el primer paso real de **partir el bot en sub-workflows**, así que una sesión del Agente n8n puede construirlo en paralelo sin pisar a la otra (protocolo de dos constructores).

## Condiciones antes de construir

1. **Los dos «número 1» necesitan una fuente citable y un literal firmado.** No se puede afirmar al cliente algo que no podamos sostener.
   - **Número 1 en autos:** por cuota de mercado, con la fuente (AMIS o CNSF) y el periodo.
   - **Número 1 en atención de siniestros:** ¿según qué ranking (CONDUSEF u otro) y de qué año?

   Alberto (o Hylant) aporta la fuente; el texto exacto va a la bandeja de firmas.
2. **No desacreditar a la otra aseguradora:** comparar datos, sin opiniones sobre la otra marca. Que lo valide Hylant.
3. **Datos personales:** una póliza trae nombre, dirección y número de póliza. Hay que decidir qué se guarda, dónde y cuánto tiempo (hoy las imágenes se tratan con `n8n_inbound_media`). Sin guardar el documento si no hace falta.
4. **Medir la demanda primero:** cuántos leads mandan su póliza y en qué formato. Hoy hay 1 foto desde el 1 sep. Si es raro, la fase 1 basta durante un tiempo.

## Siguiente paso

Que Alberto aporte las dos fuentes. Después:
- **Agente n8n · A:** una duda de diseño de las fases 1 y 2 (PDF, esquema de datos y comparador).
- **Mejoras:** los textos de la fase 3, con casos.
