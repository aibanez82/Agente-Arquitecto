# Lo que espera una decisión mía

> **Fichero vivo.** Cada línea es trabajo **terminado por un ejecutor** que no avanza porque falta que yo
> decida, ordene o secuencie. Se añade en el momento en que lo aplazo, no al final.
>
> Lo vigila `scripts/monitores/m7-decisiones-pendientes.sh`.

## Por qué existe

El `#460` estuvo **cuatro días parado esperando una decisión mía** que podía haber dado el 25 de
septiembre. El arreglo estaba construido y probado en STG desde el 23; el ejecutor me dijo que quedaba
pendiente de mi palabra; y en ese tiempo producción perdió cinco turnos más de historial.

No fue un olvido de nadie en particular: **«esperando una decisión del Arquitecto» no tenía casa.** No hay
campo en el tracker, ni etiqueta, ni lista. Así que un encargo en ese estado **es indistinguible de uno
terminado** — para el ejecutor, porque hizo su parte; y para mí, porque no me llega nada que me lo
recuerde.

Es exactamente el mismo modo de fallo que las diez conversaciones tomadas del `#493`: no caduca, no lo
suelta nadie más que el dueño, y no se ve. Y le pedí al Agente Dashboard que lo hiciera visible antes que
automatizarlo **mientras me lo saltaba en mi propia mesa**.

## Cómo se usa

**Al aplazar algo, se añade aquí en el mismo momento.** Una línea, con:

- **qué** espera, en una frase que se entienda sin abrir el issue;
- **quién** lo entregó y **cuándo** quedó esperando;
- **qué lo desbloquea** — una decisión mía, una firma de Alberto, o un hueco de secuencia;
- y **qué cuesta la espera**, aunque sea «nada».

**Se quita cuando se decide**, no cuando se hace. Decidir y ordenar son dos cosas, pero la que falta aquí
es la primera.

## Abierto

| Desde | Qué espera | Quién lo dejó listo | Lo desbloquea | Coste de esperar |
|---|---|---|---|---|
| 29 sep | **`#493` · cuatro clientes esperando respuesta**: `waq_3603` «Quiero cancelar» (7 d), `waq_3626` «mándame el PDF» (7 d), `waq_3662` (4 d) y `waq_3709` «Retomo mi cotización» (1 d, cliente del P0) | medido por mí | **Alberto**: esto no espera a un arreglo, espera a **una persona**. No es decisión de arquitectura | cuatro clientes sin contestar, uno de ellos con la compra confirmada |
| 29 sep | **`#492` E2E** — el runner de emisión completa en STG, escrito y con control negativo montado | Agente QA (`29ed804`) | **Alberto**: su clasificador frenó la acción y solo un humano la levanta. **No la levanta un handoff mío** | el P0 del `#492` se cerró sin verificación E2E: el arreglo está en PROD acreditado por lectura del grafo, no por una emisión real |
| 26 sep | **PRs #113–#117** de este repo, todos `docs/`, todos `MERGEABLE` | yo | **Alberto**: `main` es suyo. El `#117` es el que hace operativo este mismo fichero y su vigilante | el `m7` no se puede armar desde el clon: en `main` no existen ni el script ni este documento |
| 26 sep | **`#479` residuo** — escribir en memoria el `cleanOutput` en vez del crudo, para que el agente no se relea sus marcadores | Agente n8n | yo: engancharlo a un paquete que toque `Detect API Failure`. **No hay ninguno previsto**, y por eso lleva aquí tres días sin moverse | ninguno medido (0 efecto en 14 casos); ocupa ventana de contexto |
| 26 sep | **`#486`** — la lista final priorizada del análisis de coherencia | Agente n8n (inventario completo) | **Alberto**: decidir actuar | ninguno; no hay defecto vivo |
| 29 sep | **`#477` → PROD** — el canon VIN v1, ya idéntico byte a byte en las dos copias de STG | Agente n8n | **Alberto**: firma. Toca el carril de emisión, así que no entra en la autorización permanente | bloquea el `#488` y el `#475`, que viajan detrás |
| 29 sep | **`#478` → PROD** — la validación previa de placas. **STG ya verde** (`249b33ac`, un solo nodo cambiado, `connections` idénticas, 4/4 con fail-first), medido por mí | Agente n8n | **Alberto**: firma. Toca emisión | el cliente sigue comiéndose el error al emitir, y el de guiones al capturar |

## Cerrado, para no repetir la discusión

| Decidido | Qué era | Cuánto esperó |
|---|---|---|
| 29 sep | **`#481`** — decidido: *el carril de recuperación no viaja a PROD sin reserva de salida*. Y al medirlo, el fence **no se podía copiar**: `n8n_outbound_reserve` rechaza nulos en los cinco campos de identidad y Recovery nace frío. Handoff `f8c9dfa1` | **4 días** |
| 29 sep | **`#478`** — decidido: manda el criterio de `Check Placas`, y el validador previo se alinea con él **en las dos direcciones** (exigir presencia, y normalizar guiones). Handoff `8f57f3bc` | **3 días** |
| 29 sep | **`#488`** — decidido: la lista entra con el viaje del `#477`, y **son CINCO, no cuatro**: `LZW`, `5YF`, `93C`, `MB2`, `MEX`. `ZFA` sale — era un solo coche contado dos veces | **3 días** |
| 29 sep | **`#475`** — decidido: viaja enganchado al `#477`, que es el único paquete que toca `Check Typed VIN`. No necesita viaje propio | **3 días** |
| 29 sep | **`#460`** — «insertar solo la fila `ai`», confirmado | **4 días** |
| 29 sep | **`#477`** — canonicalizar + contrato, descartado el sub-workflow | mismo día |
| 29 sep | **`#463`** — no se hace la sonda ni la mitigación: PROD limpio en 75 sesiones | 7 días sin mirarse |

## Lo que NO está aquí, y por qué — el `#460`

El `#460` figuró en esta lista el 29 sep por la mañana. **Lo he quitado el mismo día**: no espera una
decisión mía, espera la **medición del Agente n8n** que le pedí en el handoff `c51d5733` de las 03:14 CDMX.

La distinción no es cosmética y es la razón de ser de este fichero: si aquí entra todo lo que no avanza, en
una semana es un segundo tablero de tareas y deja de leerse. **Aquí solo entra lo que está parado porque
falta que yo hable.** Lo que está en manos de un ejecutor lo vigila el `m3`; lo que espera a Alberto lleva
su nombre en la columna «lo desbloquea».

Agente: Arquitecto-IA-Qualitas
