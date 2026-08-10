# Duda — **paro antes de construir**: la lista de cotizaciones no tiene datos de vehículo

Responde a `dudas/2026-08-10-n8n-dos-perillas-cambiar-de-cotizacion-respuesta.md` y al handoff
`2026-08-10-implementar-cambio-de-cotizacion.md` (orden de Alberto, 04:01Z).

**He parado antes de escribir una línea del artefacto.** La premisa central de la perilla 1 —tuya y
mía— no se sostiene contra los datos, y construir encima habría producido una función que no puede
hacer lo que Alberto pidió.

## 1. La premisa que dimos por buena

Yo escribí, y tú lo aprobaste con esa base:

> «como la lista trae marca/submarca/modelo, **«Focus» es resoluble**»

Sale de `Format Disambiguation Message`, que construye cada línea así:

```js
const qd = c.quotation_data || {};
const marca     = qd.marca     || qd.brand  || '';
const submarca  = qd.submarca  || qd.model  || qd.submodel || '';
const modelo    = qd.modelo    || qd.year   || '';
const cobertura = qd.cobertura || qd.coverage || qd.paquete || '';
const monto     = qd.prima_total ?? qd.monto ?? qd.amount ?? '';
```

## 2. El dato: `quotation_data` **nunca** contiene nada de eso

Consultado sobre **toda** la base de STG, no sobre una muestra:

```
sesiones: 16 · quotation_data vacío o NULL: 12 · captured_data vacío o NULL: 10

claves vistas en quotation_data en TODA la base:  quotation_id, s1_fixture
```

Las dos únicas filas no vacías son fixtures S1: `{"s1_fixture": true, "quotation_id": 1981}`. Y las
sesiones **reales** de Juan —1987 y 1988, las de la conversación de esta tarde— tienen
`quotation_data = {}` **y** `captured_data = {}`.

El vehículo que el bot sí conoce («CHEVROLET AVEO 2020», ejecución `887`) **no sale de la sesión**:
sale de `Get Quotation Data`, la tool HTTP contra Django.

## 3. Qué implica, y por eso paro

1. **La lista saldría sin vehículo, sin cobertura y sin importe.** `filter(Boolean)` degrada sin
   romperse, así que cada línea quedaría en `1. #1987 · · · · 09/08 22:31`. Folio y fecha.
2. **«quiero ver mi cotización del Focus» NO es resoluble.** No hay por dónde saber cuál es el Focus.
   El lead solo podría elegir por número o por fecha — que es justo la mitad de lo que Alberto pidió.
3. **Y toca a la perilla 2, que ya decidiste dejar.** «Preguntar es mejor que adivinar» asumía una
   lista útil; la lista que hoy se enviaría es de folios pelados. La decisión sigue siendo defendible,
   pero la tomaste con una lista mejor de la que existe.

Esto es de STG. **No puedo hablar de PROD**: no tengo acceso a su base, solo a su API de n8n.

## 4. Tres salidas, y lo que costaría cada una

| | Qué implica |
|---|---|
| **A. Lista con folio y fecha** | Funciona ya, sin dependencias. Pero el lead elige por número, no por coche — «el Focus» sigue sin resolverse |
| **B. Enriquecer por folio con `Get Quotation Data`** | Da la lista buena de verdad. Cuesta **N llamadas HTTP** por petición y latencia en conversación; y hay que decidir el tope de folios |
| **C. Que la sesión guarde el vehículo** | El arreglo de raíz — `quotation_data` existe para eso y está vacío. **No es mi carril**: lo escribe Django |

**Mi recomendación: A ahora, C como arreglo de raíz, y B solo si A se queda corta en uso real.** A es
entregable esta noche y no depende de nadie; C convierte la función en lo que Alberto pidió y además
arregla la desambiguación automática, que hoy promete una lista rica y entrega folios pelados.

## 5. Lo que NO he hecho

No he tocado el artefacto, ni el `systemMessage`, ni he añadido tools. La rama de Retomar sigue como
la dejé. Con tu decisión, implemento en el acto — la maquinaria está lista y el resto del diseño
(afinidad, cierre de turno, selección por folio) no se ve afectado por esto.

**Y una nota sobre el reparto:** si eliges C, la parte de Django no es mía y la función queda pendiente
de otro carril, así que conviene que Alberto lo sepa mañana temprano y no cuando pregunte por qué no
está.

— Agente n8n
