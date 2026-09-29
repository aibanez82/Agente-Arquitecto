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
| 26 sep | **`#478`** — que el validador previo exija las placas igual que la emisión. Una línea. | medido por mí | yo: engancharlo a un paquete que toque ese nodo | el cliente se come el error al final en vez de al capturar |
| 26 sep | **`#475`** — que `Check Typed VIN` se niegue a construir el patch si `typedVin === '__NONE__'`, para que la guarda viaje con el nodo | Agente n8n | yo: mismo, engancharlo a un viaje del carril | ninguno hoy; la guarda de arriba filtra |
| 26 sep | **`#479` residuo** — escribir en memoria el `cleanOutput` en vez del crudo, para que el agente no se relea sus marcadores | Agente n8n | yo: engancharlo a un paquete que toque `Detect API Failure` | ninguno medido (0 efecto en 14 casos); ocupa ventana de contexto |
| 25 sep | **`#481`** — el carril de recuperación envía **sin pasar por el fence de salida**. Ninguno de sus 15 nodos está en PROD | Agente QA | yo: ordenar el arreglo **antes** de que viaje | ninguno hoy, porque no está en producción. Si viaja sin fence, enviaría con la conversación tomada por un humano |
| 26 sep | **`#488`** — añadir a la tabla de WMI los cuatro prefijos con ≥2 observaciones (`LZW`, `93C`, `MEX`, `ZFA`) | medido por mí | **depende del `#477` en PROD**; después, orden mía con `v2` del canon | el check de marca no trabaja en casi la mitad del parque |
| 29 sep | **`#460`** — el E2E conversacional en STG, y luego el viaje | Agente n8n (arreglo listo desde el 23 sep) | yo: secuenciar cuando el QA libere STG | **se pierde la fila del bot en el 100 % de los turnos del guard** |
| 26 sep | **`#486`** — la lista final priorizada del análisis de coherencia | Agente n8n (inventario completo) | **Alberto**: decidir actuar | ninguno; no hay defecto vivo |

## Cerrado, para no repetir la discusión

| Decidido | Qué era | Cuánto esperó |
|---|---|---|
| 29 sep | **`#460`** — «insertar solo la fila `ai`», confirmado | **4 días** |
| 29 sep | **`#477`** — canonicalizar + contrato, descartado el sub-workflow | mismo día |
| 29 sep | **`#463`** — no se hace la sonda ni la mitigación: PROD limpio en 75 sesiones | 7 días sin mirarse |

Agente: Arquitecto-IA-Qualitas
