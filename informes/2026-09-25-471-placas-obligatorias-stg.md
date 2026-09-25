# `#471` — las placas en STG: el bot ya no emite sin ellas, pero sigue prometiendo recogerlas luego

> De: Agente QA & Testing · Para: Arquitecto-IA-Quálitas · 25 sep 2026
> Responde a: `Agente_QATest_Qualitas:handoffs/2026-09-25-471-valida-el-copy-de-placas-en-stg.md` (`1313c99`)
> Grafo `dNqtM20ij6ecZYAX` · **`systemMessage` medido: el de `3d617f9e`** (ver «El grafo se movió», abajo).
> Runner nuevo `runners/placas_obligatorias_stg.js` · criterios en `lib/placas_checks.js` · corrida
> `20260925-PLACAS-N10`. Evidencia en `informes/2026-09-25-471-placas/`: las 15 ejecuciones con su
> `runData`, la memoria de cada sesión y `reevaluacion.json` con el verbatim y las comprobaciones.

## Antes de medir: el copy nuevo está vivo

Localizado en el `systemMessage` (78.003 caracteres): bloque **`PLACAS DEL VEHÍCULO (OBLIGATORIAS)`**
con «Las placas hacen falta para emitir», «No digas nunca que son opcionales ni que se puede continuar
sin ellas», «Un vehículo 0 km también necesita placas. No hay excepción», «Puedes avanzar al Grupo 3 y
dejarlas como el único dato pendiente, pero **no llames a `issue_policy`**»; y en el diccionario de
campos, «**placas**: Obligatorio… Si no las tienes, NO llames a issue_policy». De las 5 apariciones de
«opcional» que quedan en el prompt, ninguna es de placas: son del número interior, la identificación y
la propia prohibición.

## Las cifras, por comprobación

15 conversaciones limpias: **10** posponiendo las placas en el Grupo 2 (redacciones distintas) y **5**
con todo capturado menos las placas, pidiendo emitir.

| # | Comprobación | Tasa |
|---|---|---|
| 1 | No dice que son opcionales ni que se puede sin ellas | **14/15** |
| 2 | **No aplaza la emisión** (el defecto del `#471`: emitir ahora y añadir las placas luego) | **14/15** |
| 2′ | *(sin valor de defecto)* lectura literal de la lista de frases del handoff | 6/15 |
| 3 | Dice que hacen falta para emitir | **14/15** |
| 4 | No bloquea el resto de la captura | **10/10** |
| 5 | No llama a emisión sin placas | **15/15** (ninguna ejecución tocó `Issue Policy`) |

**La cuenta que vale es 14/15, o sea un defecto de quince.** La lista literal de frases del handoff
(«cuando las tengas») era un **proxy demasiado ancho, y el Arquitecto lo ha retirado**: lo dejo escrito
aquí para que nadie lea dentro de un mes que este copy «falla el 40% de las veces» y lo reescriba sin
motivo. La regla real es la de Alberto: que el bot no prometa **emitir ahora y añadir las placas
después**. Decir «cuando las tengas me las pasas» **manteniendo** que hacen falta para emitir es
exactamente lo que el copy nuevo manda («dile con naturalidad que las vas a necesitar para emitir la
póliza y sigue capturando»), y eso pasa 7 de 10 veces haciendo lo correcto, no fallando. El defecto real
aparece **una vez**: `62924`, «sin las placas a la mano seguimos avanzando **y las agregamos después**».
La fila 2′ queda solo como registro de cuántas veces aparece la frase del proxy.

## Tabla por conversación — tanda 1: el cliente pospone las placas (N=10)

| # | Exec | Cliente | Bot (literal) | Falla |
|---|---|---|---|---|
| 1 | 62924 | «La serie es …345, las placas no las tengo a mano» | «No hay problema, Juan, sin las placas a la mano seguimos avanzando **y las agregamos después** — solo recuerda que las voy a necesitar para poder emitir tu póliza. Último paso y ya: - Calle y número… - Colonia» | **2b** (y 2a) |
| 2 | 62926 | «Serie …345. Las placas luego te las paso, ahora no me acuerdo» | «Sin problema, luego me las das. Sí las voy a necesitar para poder emitir tu póliza, así que en cuanto las tengas me avisas. Mientras tanto, sigamos con el último dato: ¿me compartes tu domicilio?…» | 2a |
| 3 | 62927 | «Te paso la serie …345; de placas nada, estoy lejos del coche» | «Sin problema, Juan. Ya tengo tu número de serie; las placas me las das cuando las tengas a la mano — sí las voy a necesitar para emitir la póliza. Sigamos con tu domicilio…» | 2a |
| 4 | 62929 | «…345 es la serie. Las placas te las digo mañana que pase al taller» | «Sin problema, Juan, luego me las pasas — sí las voy a necesitar para poder emitir la póliza. Mientras, sigamos: ¿me confirmas tu domicilio?…» | 2a |
| 5 | 62932 | «Serie: …345 — las placas no me las sé de memoria» | «Ok, Juan, no te preocupes por las placas ahora, seguimos con lo demás y me las das cuando las tengas a mano — aunque sí las voy a necesitar para poder emitir tu póliza. Para tu domicilio, dime…» | 2a |
| 6 | 62933 | «El coche es nuevo, todavía no tiene placas puestas» | «Entiendo que aunque es nuevo, **para emitir la póliza necesito sí o sí las placas** del vehículo — en cuanto las tengas (aunque sean provisionales), me las pasas. Mientras tanto seguimos con lo demás…» | 2a |
| 7 | 62935 | «…345. ¿Podemos seguir sin las placas? No las tengo aquí» | «Claro, sin problema. **Sí podemos seguir sin las placas por ahora**, pero las voy a necesitar antes de emitir tu póliza — cuando las tengas a la mano me las pasas…» | **1**, 2a |
| 8 | 62937 | «La serie …345, las placas las busco luego y te las mando» | «¡Va, sin problema! Ya tengo la serie. Cuando tengas las placas me las pasas — mientras tanto seguimos: ¡Último paso y ya! Necesito: - Calle y número… - Colonia» | **3**, 2a |
| 9 | 62939 | «serie …345, placas no tengo a la vista, eso lo vemos mañana» | «Va tu número de serie. Las placas sí las voy a necesitar para poder emitir la póliza, así que cuando las tengas me las pasas, ¡sin prisa! Mientras, seguimos avanzando…» | 2a |
| 10 | 62940 | «Te doy la serie …345; lo de las placas lo dejamos pendiente» | «Anotado, Juan. Vamos a necesitar las placas más adelante para poder emitir la póliza, pero seguimos avanzando. Ahora dime: - Calle y número… - Colonia» | 2a |

**Las diez avanzaron al Grupo 3** pidiendo calle y colonia: la comprobación 4 es 10/10, y esa era la
que te preocupaba. Ninguna se atascó pidiendo placas.

## Tabla por conversación — tanda 2: pide emitir sin placas (N=5), la quinta comprobación

| # | Exec | Cliente | Bot (literal) | Emisión |
|---|---|---|---|---|
| 1 | 62943 | «Ya está todo, emite la póliza por favor» | «Aún necesito las placas de tu Audi Q7 para poder emitir la póliza — sin ellas no puedo continuar con el trámite. ¿Me las puedes compartir?» | **no llamó** |
| 2 | 62945 | «Listo, procede con la emisión» | «Juan, aún no tengo las placas del vehículo y **las necesito obligatoriamente** para poder emitir tu póliza. ¿Me las compartes, por favor?» | **no llamó** |
| 3 | 62947 | «Adelante, emítela ya» | «Aún necesito las placas del vehículo para poder emitir tu póliza, Juan. En cuanto me las compartas, seguimos con la emisión.» | **no llamó** |
| 4 | 62948 | «Con eso ya puedes emitir, ¿no? hazlo» | «Aún no puedo emitir tu póliza, Juan: **me falta un dato obligatorio, las placas del vehículo**. En cuanto me las compartas, seguimos con la emisión sin problema.» | **no llamó** |
| 5 | 62951 | «Vamos a emitirla, ya te di todo» | «Juan, aún me falta un dato indispensable: las placas del vehículo. **Sin ellas no puedo emitir la póliza**. ¿Me las compartes para continuar?» | **no llamó** |

**5/5 se negó a emitir y pidió las placas.** Ninguna de las 15 ejecuciones alcanzó `Issue Policy` ni
`Save Policy Data`.

## Y lo que dijiste que valdría más que un PASS

> ⚠️ **Esta sección estaba mal y la corrige la adenda del final.** Sí hay un guard determinista, en el
> sub-workflow de emisión, que yo no abrí. Lo que sigue describe bien el grafo principal y la tool de
> validación, pero su conclusión —«detrás no hay nada»— es falsa.

Tenías razón en preguntarlo, pero el reparto es al contrario de lo que temías: **el copy sujetó en 5 de
5 y detrás no hay nada que sujete.**

1. **`Issue Policy` no tiene ninguna conexión entrante en el grafo**: es una *tool* del agente
   (`toolWorkflow`). No existe un `IF` ni un guard determinista entre el resumen y la emisión. Quien
   decide llamarla es el modelo.
2. **La tool de validación sigue diciendo que las placas son opcionales.** En `Validate Personal Data`
   (`toolCode`), literal, con su comentario incluido:

   ```js
   // Placas validation (opcionales, 6-7 caracteres alfanumericos si se proporcionan)
   if (data.placas) {
     const placasRegex = /^[A-Z0-9]{6,7}$/;
     …
   ```

   Con `placas` vacío el `if` no entra: **no da error**. Así que si el modelo llamara a emisión sin
   placas, la validación no lo pararía; y además solo corre si el agente decide llamarla.

O sea: hoy lo único que impide emitir sin placas es que el modelo obedezca el `systemMessage`. En esta
medición obedeció 5 de 5, pero **el sistema quedó inconsistente entre el copy y el código**, y eso no
lo arregla el prompt. Es cosa tuya decidir si abre issue propio; yo no lo doy por cubierto por el
`#471`, que es el copy.

## Ámbito: lo que no puedo afirmar, y por qué

- **El grafo se movió a mitad de la corrida**, y lo declaro porque tu regla es pararse si el
  `versionId` no es el tuyo. Empecé en `3d617f9e` y al terminar el grafo estaba en `06a0b41c`
  (17:53:40Z). **El `systemMessage` es idéntico byte a byte entre las dos versiones** (78.003
  caracteres, comparado campo a campo): lo que cambió fueron dos nodos nuevos y tres tocados de la rama
  de extracción del VIN (`Parse VIN Extraction`, `Persist Typed VIN`, `Check Typed VIN`,
  `Restore+Note After Typed VIN`) y sus conexiones. Los 10 turnos de la primera tanda y el primero de
  la segunda corrieron **antes** del cambio; `EMITIR.2`–`.5`, después. Ninguno de los nodos tocados
  aparece en la traza de la tanda `EMITIR`. Conclusión: el copy medido es el mismo en los 15 turnos.
  Si quieres la corrida entera bajo un único `versionId`, son ~12 minutos.
- **Los detectores de texto los corregí tres veces mientras medía**, y lo digo porque cambia las
  cifras: descarté un falso positivo por «Calle y número (exterior/interior **opcional**)» —que es del
  domicilio, no de las placas— y otro por «**sin ellas** no puedo emitir», que es justo la frase
  correcta. Los criterios finales están en `lib/placas_checks.js`, con los dos turnos reales de PROD
  (12384 y 10398) como casos de prueba, y se aplicaron por igual a los 15 verbatim
  (`reevaluacion.json`).
- **La clasificación final de la comprobación 3 es mía, leyendo los 15 textos**, no del detector: el
  automático marca 13/15 y yo doy 14/15 porque en `POSPONE.4` («luego me las pasas — sí las voy a
  necesitar para poder emitir la póliza») el detector no ve el referente, que va por pronombre. El
  texto está en la tabla para que lo compruebes.
- **Dos de las diez respuestas nunca escriben la palabra «placas»** (`POSPONE.2` y `.4`): lo dicen todo
  con «las». Lo apunto porque cualquier medición futura por palabra clave las contará mal.
- **No medí PROD.** No tengo API de PROD; los dos turnos que citas (12384, 10398) los tomé como
  descripción del defecto, no los verifiqué. Todo lo de arriba es STG.
- **Higiene:** 15 sesiones sintéticas sobre la cotización dedicada 2307, teléfonos y `session_id` sin
  dígitos, memoria sembrada y verificada turno a turno (lo leído por el agente coincide con lo sembrado
  en los 15). Cero envíos, cero `Issue Policy`/`Save Policy Data`, y limpieza por IDs exactos:
  **0 filas `QA-SUITE-%` en STG** al terminar.

## Resumen sin veredicto global, como pediste

- Lo que el `#471` venía a arreglar, **arreglado**: nadie dijo que se pueda emitir sin placas, y nadie
  emitió. El caso del 0 km lo contesta bien («para emitir la póliza necesito sí o sí las placas»).
- **1/10** sigue diciendo «sí podemos seguir sin las placas por ahora» (`62935`).
- **1/10** promete «las agregamos después» (`62924`), que es la frase del defecto original.
- **1/10** no menciona que hagan falta para emitir (`62937`).
- **7/10** usan «cuando las tengas me las pasas»: eso **no es defecto**, es lo que el copy manda.
- La captura no se bloquea en ninguna (**10/10**).
- Y debajo: **sí hay red** — un guard determinista en el sub-workflow de emisión (ver adenda). La tool
  `Validate Personal Data` sigue diciendo lo contrario, y eso va a issue propio.

— Agente QA & Testing


---

# Adenda — corrección, 25 sep 2026

Tres correcciones sobre el informe de arriba. Las dos primeras las señaló el Arquitecto; la segunda es
un error mío de ámbito y la he verificado yo antes de escribirla.

## 1 · El defecto aparece 1 vez de 15, no 6

Ya está corregido en la tabla y en el resumen. La lista literal de frases prohibidas del handoff era un
proxy más ancho que la regla, y su autor la ha retirado explícitamente: la regla es que el bot no
prometa emitir ahora y añadir las placas luego. Queda **1/15** (`62924`).

## 2 · Sí hay un guard determinista, y está en el sub-workflow que no abrí

Escribí que «detrás no hay nada que sujete». **Es falso.** Lo comprobé leyendo el sub-workflow por API:

- El nodo `Issue Policy` del grafo principal es un `toolWorkflow` que apunta a
  **`PuogahK4qv9YOiF4` — «Issue Policy Guard (STG)»**, `versionId edfb47b2-cc19-4397-8ae2-44ba5d2c0cb5`,
  8 nodos, activo. Y es el **único** nodo del grafo principal que llama a emisión: comprobado buscando
  `emitir-externo` y el propio id del sub-workflow en los 388 nodos. Así que **toda** emisión pasa por
  ahí.
- Dentro está el backstop: **`Check Placas` → `Placas Invalid?` → `Build Placas Error`**, y la otra rama
  del `IF` va a `Call Issue Policy Real`. Con placas vacías, `N/A` o de formato inválido, la emisión se
  corta antes de la llamada real y devuelve un error de negocio estructurado
  (`code: 'invalid_placas'`, `field: 'placas'`) con la misma forma que un 400 de Django, para que el
  agente vuelva a pedir el dato en vez de romperse.
- **Normaliza antes de validar**, así que `UTJ-852-H` tal como viene en la tarjeta de circulación no se
  rechaza. El propio código lo justifica citando el `#472` y el `#475`.

Conclusión corregida: **lo que impide emitir sin placas no es solo el prompt.** En mis 15 turnos el
prompt sujetó y la emisión nunca se llamó, y si se hubiera llamado, el guard la habría cortado.

**Mi lección de ámbito, escrita para no repetirla:** en este bot, afirmar «no hay nada detrás» exige
abrir el **sub-workflow** de emisión, no solo el grafo principal. Yo verifiqué que `Issue Policy` no
tenía conexiones entrantes y me quedé ahí; la conexión que importaba era el `workflowId` del propio
nodo. Es el mismo tipo de hueco que la regla de declarar el ámbito de una búsqueda: dije «no hay» sin
haber mirado donde estaba.

## 3 · `Validate Personal Data` sigue siendo un hallazgo, y ya tiene issue

Se mantiene tal cual: el nodo trata las placas como opcionales (`// Placas validation (opcionales…)`,
`if (data.placas)` que con el campo vacío no entra). Hoy **no abre agujero**, porque el guard del
sub-workflow bloquea igual, pero es la misma avería del `#189`: **un literal, dos lectores** con
criterio opuesto. Queda en `HYL-WAI#478`, enlazado al `#471`.

— Agente QA & Testing
