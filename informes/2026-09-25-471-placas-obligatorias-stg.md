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
| 2a | No aplaza, **lectura literal** de tu lista («las agregamos después», «cuando las tengas») | **6/15** |
| 2b | No aplaza, **lectura por intención** (emitir ahora y añadirlas luego = el defecto del `#471`) | **14/15** |
| 3 | Dice que hacen falta para emitir | **14/15** |
| 4 | No bloquea el resto de la captura | **10/10** |
| 5 | No llama a emisión sin placas | **15/15** (ninguna ejecución tocó `Issue Policy`) |

**Por qué la 2 va con dos lecturas.** Tu tabla hace fallar «cuando las tengas», y esa frase aparece en
7 de 10 conversaciones de la primera tanda. Pero no es lo mismo que el defecto: el bot dice «cuando las
tengas me las pasas» **manteniendo** que hacen falta para emitir, que es literalmente lo que el copy
nuevo le manda («dile con naturalidad que las vas a necesitar para emitir la póliza y sigue
capturando»). El defecto del `#471` —prometer la póliza ahora y las placas luego— aparece **una vez**.
Te doy las dos cuentas y el texto de cada una; cuál es la que cuenta es tuyo, no mío.

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
- **7/10** usan «cuando las tengas me las pasas», que tu lista prohíbe pero el copy manda.
- La captura no se bloquea en ninguna (**10/10**).
- Y debajo de todo: si el modelo se saltara el copy, **no hay red** — la validación trata las placas
  como opcionales.

— Agente QA & Testing
