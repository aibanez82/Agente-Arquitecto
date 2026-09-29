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
| 29 sep | **`#495` · ¿se libera sola una conversación tomada por un humano?** En pausa por decisión de Alberto: Montserrat a veces entrega conversaciones a Metepec, y entonces la IA no debe retomarlas. Construido y acreditado en STG, reloj apagado | Agente Dashboard y Agente n8n | **Alberto**: decisión de negocio. Para tomarla hace falta poder apuntar «esta la atiende Metepec»: hoy una entrega y un olvido se ven igual | tomas que nunca terminan; y ahora sabemos que algunas pueden ser entregas a propósito |
| 29 sep | **El «precio original» tachado del PDF (`#498`)**: un precio de referencia que nunca se le ofreció al cliente | medido por mí | **Alberto**: mirada comercial o legal. No es técnico | — |
| 29 sep | **La rama de Juan del `#273`** (`Agente-n8n:feature/issue-273-direct-discount-quote`) — sin fusionar. Su builder choca *add/add* con el nuestro, que reconstruyó sobre el grafo vivo. Su migración SQL se versiona aparte en `stg`, byte a byte | Agente n8n | **Alberto** (y Juan): fusionarla, retirarla o dejar convivir los dos builders | ninguno inmediato: lo que corre ya está versionado. Pero mientras siga abierta, hay dos builders para el mismo carril |
| 29 sep | **`CLAUDE.md` del Dashboard, línea de gates desfasada** — dice «la suite y el verificador» (ya son **tres**: suite + verificador + `build`) y cita **310/310** cuando la suite tiene **666** | Agente Dashboard, que **no lo tocó a propósito** | **Alberto**: por el canal en vivo jamás se pide editar `CLAUDE.md`, permisos ni configuración | un gate real que su propio manual no nombra; el siguiente que lo lea creerá que puede saltárselo |
| 29 sep | **`#492` E2E** — el runner de emisión completa en STG, escrito y con control negativo montado | Agente QA (`29ed804`) | **Alberto**: su clasificador frenó la acción y solo un humano la levanta. **No la levanta un handoff mío** | el P0 del `#492` se cerró sin verificación E2E: el arreglo está en PROD acreditado por lectura del grafo, no por una emisión real |
| 26 sep | **PRs #113–#117** de este repo, todos `docs/`, todos `MERGEABLE` | yo | **Alberto**: `main` es suyo. El `#117` es el que hace operativo este mismo fichero y su vigilante | el `m7` no se puede armar desde el clon: en `main` no existen ni el script ni este documento |
| 26 sep | **`#486`** — la lista final priorizada del análisis de coherencia | Agente n8n (inventario completo) | **Alberto**: decidir actuar | ninguno; no hay defecto vivo |

## Cerrado, para no repetir la discusión

| Decidido | Qué era | Cuánto esperó |
|---|---|---|
| 30 sep | **`#499` a PROD** — firmado por Alberto en la sesión del Agente n8n; bot `4e5a6b92`, verificado por mí contra mi foto de `7a0cb905` | cerrado |
| 30 sep | **`#500` B y `#504` a PROD** — firmados por Alberto en la sesión del Agente n8n; bot `7a0cb905`, verificado por mí contra mi foto de `0eeee085` | cerrado |
| 30 sep | **Promoción del Dashboard, variante B** — fusionada por Alberto; `main` = `f552f47` (padres `db9fdf7` + `1425508`), verificado por mí contra GitHub; el `#495` no entró | cerrado |
| 29 sep | **`#493` · los clientes que esperaban respuesta** — Alberto se lo pasó a Montserrat y a Rafa. Uno, el lead 2255, ya está liberado | **el mismo día** |
| 29 sep | **`#477` → PROD** — firmado por Alberto. En PROD `7d142334`; equivalencia 59/59 (5 VIN de control + 54 series reales); canon idéntico byte a byte en los dos nodos. Cerrado | **mismo día** |
| 29 sep | **`#478` → PROD** — firmado por Alberto. En PROD `681676e0`; efecto neto medido contra mi foto de `f104c3a8`: exactamente 3 nodos, `connections` idénticas. Cerrado | **mismo día** |
| 29 sep | **`#479` residuo** — decidido: **no se hace, y no espera a nadie**. Efecto medido 0 en 14 casos; su único coste es ventana de contexto, y un viaje propio para eso no se justifica. **Vuelve a la mesa si aparece un caso real de un agente releyéndose sus marcadores, o si algún paquete toca `Detect API Failure` por otra causa** | **3 días** |
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
