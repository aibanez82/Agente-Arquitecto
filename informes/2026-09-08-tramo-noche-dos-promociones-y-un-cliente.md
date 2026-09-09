# Tramo del 7 al 8 de septiembre — dos promociones, un cliente localizado y tres correcciones mías

> Arquitecto-IA-Qualitas. Horas en CDMX. **Punto de retomada tras `/clear`.**

## Lo que espera a Alberto

| # | Qué | Por qué |
|---|---|---|
| 1 | **Merge del Dashboard `stg` → `main`** | Lleva la retirada de GA4 **y el arreglo del falso positivo**: hoy 23 conversaciones vivas pueden decirle a un operador que envió un mensaje que no salió |
| 2 | **Token de API de Vercel (solo lectura)** en el `.env.local` | Sin él no puedo acreditar el entorno tras una promoción del Dashboard: el `VERCEL_OIDC_TOKEN` da `403` en la API REST. Dependo de que me lo cuenten |
| 3 | **Canal del mensaje a Juan** | Enumerado ya escrito. Mi recomendación: comentario en el `#335` |
| 4 | **`DATABASE_URL` de Preview en Vercel** | Acotado a `stg`; el preview de cualquier otra rama revienta con 500 antes de llegar a la base |

## Lo que entró en PROD, verificado por mí contra el grafo vivo

| Paquete | versionId final | Qué |
|---|---|---|
| `#342` | `c31401a1` | Los **once** `Persist Human Row`. 319 → 330 nodos |
| Copy mexicano | `de20a75c` | Una línea en `Build Offer Notice Copy`, la fuente única |

**El detalle que decidía el primero:** los once traían en STG la credencial `Postgres STG`. Sin cambiarla, once nodos de producción habrían escrito en la base de staging **en silencio**, porque el `INSERT` funciona igual.

**Lo que medí y el ejecutor no podía ver, en el segundo:** el `request_hash` del carril Direct firma ese copy. Fui al ledger antes de ordenar: 215 filas, todas `sent` y liquidadas, cero `uncertain`. **Ventana vacía.** Con una sola reserva viva, el handoff habría dicho «espera».

### Y una tercera, ya de día: el Dashboard a PROD

**Orden expresa de Alberto.** `main` en `337007e`, deployment del mismo commit, y el **`buildId` del alias de producción medido por mí**: `VIbXUmy0ZnXb7yWZKO14r`. El embudo de fuga sustituye a las tres bandas del Resumen.

Viajaron **diez** commits, no solo el embudo. Verificado contra la base antes de darlo por bueno — las cuatro cifras que lo sostienen, medidas por mí y no aceptadas de palabra:

| | |
|---|---|
| Leads | **1352** |
| Pólizas con número real | **61** |
| Pagadas | **25** |
| Reparto `sesiones_wa` | `{0: 244, 1: 1108}` |

**El riesgo que declaré no era el código:** `main` tenía 54 ficheros en `handoffs/` y `stg` solo 3, porque por convención van directos a `main`. Un merge los conserva —lo simulé en un worktree desechable—; un `reset` o un `force` habría borrado el canal de órdenes entero. Comprobado después: fue merge, el `main` anterior sigue siendo ancestro.

**Y un error mío en esa orden, cazado antes de que se ejecutara:** puse como criterio «53 handoffs tras el merge» habiendo contado `main` **antes de añadir el propio fichero del handoff**. Eran 54. El ejecutor habría medido 54, visto descuadre y parado por un fallo mío. Anclé el criterio a un número que yo mismo movía al publicarlo.

## El hallazgo que resultó ser otra cosa — RETRACTADO

Escribí aquí que había **un cliente real con 20.673,46 MXN y ventana hasta el 14 de septiembre**, y preparé un artefacto para que alguien le llamara a cobrar. **Era falso, y lo descubrí al ir a buscar su teléfono.**

Armando Lobo pidió la liga de pago **dos veces el 1 de septiembre**, el sistema le falló las dos, y escribió «Cancelar el trámite por favor». A las 12:32 le respondimos: **«Tomamos nota de la cancelación y nos encargamos del trámite; no tiene que hacer nada más.»**

**No es cobranza pendiente: es una venta perdida por un defecto nuestro, ya cerrada con el cliente.** Llamarle a cobrar habría sido desdecirnos de una promesa escrita. El artefacto del escritorio está anulado y abre con «NO LLAMAR A COBRAR».

Lo que sí queda: **prometimos gestionar una cancelación y no consta que se hiciera** — la póliza sigue emitida y `PENDIENTE`. Y el cron **le siguió generando ligas hasta el 7 de septiembre**, seis días después de la baja.

El `#329` está corregido y retitulado con esta evidencia.

## Lo que entró en PROD de madrugada, y lo que destapó

**`Retomar Conversacion` 12 → 27 nodos** (`6c894d50`) y **`Discount Application Poller` 68 → 71** (`547b47d9`). Los dos verificados por mí contra el grafo vivo: cero literal «STG», antifuga limpia, credenciales nodo a nodo, y los **siete** nodos de solo-entorno del poller **intactos byte a byte**.

**El detalle que decidía los dos viajes:** en STG los nodos `WA Config STG` / `WA Config Worker STG` son **los de PROD renombrados**, no nodos nuevos. Copiar el grafo habría dejado nodos llamados «STG» en producción con otros apuntándoles por nombre.

**Y lo que destapó, que no vi al promover:** el fence del `#156` llegó con Retomar. Cuando la reserva deniega, la hoja responde **sin `success` ni `status`**, y el Dashboard —que solo mira el código HTTP— **da el mensaje por enviado y lo audita como enviado**. El cliente no recibe nada.

**23 conversaciones vivas** están hoy en esa condición (44 legacy bloqueadas, de las que 23 siguen abiertas; las 11 v2 se caen antes por validación y están todas cerradas). **No se revierte**: antes de la valla esos leads recibían el mensaje igualmente — lo que se rompió es el informe del envío, no el envío. El arreglo va del lado del Dashboard y ya está escrito.

Issues: **`#353`** (falta `n8n_payment_events` en PROD, bloquea `Payment Confirmation`) y **`#354`** (el falso positivo).

**Lo mío:** verifiqué el grafo a fondo y **no verifiqué a quién lo consume**. Lo encontró el Dashboard.

## Issues: cinco nuevos con dueño, dos reencuadrados

- **`#345`** — nadie comprueba las rutas citadas en comentarios: **22 muertas sobre 16 rutas**.
- **`#346`** — `whatsapp_sessions` no guarda quién creó la fila. Con tres emisores, toda limpieza es una inferencia.
- **`#347`** — 17 leads con sesión y póliza sin historial (del Dashboard). **Medido por mí: en mi población son 9 y los 9 son `canal_atencion = LANDING`** — cerraron por web, nunca hubo conversación. No lo cierro: su población es otra y no la he medido yo.
- **`#348`** — `Extract VIN Vision` sigue en `claude-sonnet-4-5-20250929` en **los dos entornos**. Sobrevivió a todas las revisiones porque **no es un nodo de modelo**: es un `httpRequest` con el identificador escrito a mano.
- **`#349`** — la cadena de GA4 del Dashboard se quedó **sin consumidor** al retirar la banda CAPTACIÓN. Y `pages/api/analytics.js` **no es código muerto: es un endpoint HTTP vivo** con las credenciales de Google detrás y sin nadie que vigile sus fallos. Desatasca por el lado bueno un pendiente viejo: la clave de la cuenta de servicio no hay que **rotarla**, hay que **borrarla**. Línea roja escrita en el issue: **no tocar GA4 en la landing**, que es la atribución de Google Ads.
- **`#329`** — remedido: de cinco fallos, tres se cobraron por otra vía y uno era de prueba.
- **`#339`** — **entregado en PROD**: la frase de Alberto está puesta. No se cierra por falta de tráfico, no de trabajo.

## Lo que hice en la base y en STG

Retiradas mis cinco sesiones de arné de STG (13 filas de historial, 6 de dispatch, 5+1 de intentos), tras barrer **las 19 tablas con `session_id` por catálogo** — `whatsapp_sessions` no tiene ni una FK entrante. STG vuelve a **158 filas / 158 leads**.

## Mis tres correcciones

1. **Clasifiqué por indicio, no por acto.** Di por buena la clasificación de cinco sesiones por el prefijo del `session_id` **sin abrir la tabla**. Solo una lo llevaba; las delataba el teléfono. Las cinco eran mías, así que no se perdió nada — **si una hubiera sido real, ese criterio la habría borrado**.
2. **Juzgué injustificada la desactivación de la liga** antes de ver que llevaba la fecha mala. Con eso delante, pudo ser lo correcto. Retractado en el `#329`.
3. **Propuse evaluar el modelo del VIN con fotos de clientes reales.** Ni se puede —no guardamos nada de lo que entra, y n8n retiene 46 ejecuciones de cuatro días— ni **debía**: es usar sus datos para un fin que no es el que nos los dieron.

## El patrón de la noche, en tres herramientas distintas

**La herramienta que busca el fallo comparte el punto ciego del fallo.** El `--check` de Juan probó que el fichero existía y la ejecución murió porque el nodo dentro ya no; el primer filtro del Dashboard dio verde con tres rutas muertas dentro; y mi guarda de privilegios devolvió cero porque `git grep -E` no soporta `\b`. Tres veces el mismo día. La defensa es el **control positivo**: un caso que sabemos roto y que el barrido debe encontrar siempre.

## Estado de los demás

**PROD lleva sin conversaciones de clientes desde el 4 de septiembre.** Todo lo promovido este fin de semana espera tráfico para demostrarse.

**Juan volvió** y avanza solo el relay del `#281` — por el leg 30 al cierre. Su «PostgreSQL manifest drift» es interno de su manifiesto de tests: **ninguna colisión** con el DDL que aplicamos en su base.

Agente: Arquitecto-IA-Qualitas
