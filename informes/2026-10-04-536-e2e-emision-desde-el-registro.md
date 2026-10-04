# `#536` — la emisión toma los datos del registro: acreditado. La póliza no salió por un RFC mal calculado que no es del `#536` (`HYL-WAI#545`)

> De: Agente QA & Testing · Para: Arquitecto-IA-Qualitas · 4 oct 2026
> Responde a: `Agente_QATest_Qualitas:handoffs/2026-10-04-536-e2e-emision-desde-el-registro.md` (`000df9d`)
> Autorización: Alberto, **en mi sesión** («si»), tras plantearle la emisión contra el QA de Quálitas.
> Versiones medidas por GET al empezar cada corrida: bot `dNqtM20ij6ecZYAX` **`00382130`** (414 nodos) · guard
> `PuogahK4qv9YOiF4` **`c0b8a798`** (17 nodos). Coinciden con el handoff.
> Runner: `Agente_QATest_Qualitas:runners/e2e_emision_registro_stg.js`. Corrida que cuenta: **`20261004-0633-536`**.

## El veredicto, en una tabla

| # | Aceptación | Resultado | Dónde |
|---|---|---|---|
| 1 | El cuerpo lleva Fresno / 150 / `''` y CP, teléfono, paquete y forma de pago idénticos a la cotización | **PASS** | guard **75875**, entrada de `Call Issue Policy Real` |
| 2 | Control positivo: el primer resumen dijo Roble 222 / Int. 4B y el cuerpo no lleva Roble | **PASS** | bot 75869 (resumen) frente al guard 75875 (cuerpo) |
| 3 | Ningún resumen enseña el teléfono | **PASS** | 2 resúmenes, se buscó `1000000536` y cualquier secuencia de 10 dígitos |
| 4 | Póliza creada en el QA de Quálitas | **FAIL — por el RFC, no por el `#536`** | guard 75875, respuesta de Django (abajo, literal) |
| 5 | Detectores «Continuamos con», «*Domicilio:*», «emitida exitosamente» | **2 de 3** | falta el tercero, consecuencia directa de la 4 |

**Lo que el `#536` venía a cambiar está acreditado de punta a punta:** el guard construyó el cuerpo **desde el registro**, recogió
la corrección hecha después del resumen, y Django lo recibió. Lo que falló después fue Quálitas rechazando un RFC que **calcula el
bot** con una regla del prompt que se contradice a sí misma, y que también está en PROD.

## El cuerpo que recibió Django (guard 75875)

Leído en la entrada de `Call Issue Policy Real`, es decir, en la salida de `Email Missing?` por su rama falsa, cuyos campos el nodo
mapea 1:1 al cuerpo:

| Campo | Llegó | En la cotización clonada 2906 | ¿Idéntico? |
|---|---|---|---|
| `calle` | `Fresno` | — | ✔ (la corrección) |
| `numero_exterior` | `150` | — | ✔ |
| `numero_interior` | `""` | — | ✔ |
| `codigo_postal` | `64650` | `64650` | ✔ |
| `telefono` | `1000000536` | `1000000536` | ✔ |
| `paquete` | `1` | `1` | ✔ |
| `forma_pago` | `C` | `C` | ✔ |
| `email` | el canónico del clon | `qa-suite-536-mutsxt3u@qa.invalid` | ✔ |
| `rfc` / `homoclave` | `PRUQ900101` / `""` | — | ver §RFC |

El CP y el teléfono son **únicos del clon** y no aparecen en ningún sitio del bot ni del guard (0 apariciones, medido con `grep`
sobre los JSON vivos). Que lleguen idénticos prueba de dónde salieron.

## La respuesta de Django, literal, y por qué no reintenté

```json
{"status":"error","code":"qualitas_business_error","msg":"El RFC no es válido.","details":{"qualitas_code":"239"}}
```

No he reintentado: el handoff lo prohíbe ante un fallo ajeno al `#536`, y lo era. El bot respondió al cliente pidiendo los apellidos y
la fecha, o el RFC completo — un manejo razonable del error.

## §RFC — lo medido, y lo que no

- El bot calculó **`PRUQ900101`** para «Ana Prueba Quality, 01/01/1990» y lo guardó con `Save Group2 Progress` (bot 75865 y 75869).
- Por la regla del SAT corresponde **`PUQA900101`** (1.ª letra y 1.ª vocal interna del paterno, inicial del materno, inicial del nombre).
- El prompt dice, literal: `Formato: [2 letras apellido paterno][vocal interna apellido paterno][1ra letra apellido materno][1ra letra nombre][AAMMDD]`.
  Son 11 caracteres, contra los «10» que anuncia, y contradice su propio ejemplo `PÉREZ GÓMEZ JUAN → PEGJ921203`.
- Aplicada al pie de la letra a PRUEBA: `PR` + `U` + `Q` → **`PRUQ900101`, carácter a carácter lo enviado**.
- Con Pérez o López (2.ª letra vocal) las dos lecturas coinciden: por eso no se había visto. Con dos consonantes al inicio divergen.
- **La misma línea está en el espejo de PROD** (`Agente-n8n:origin/main` `22d3abf5`, `workflows/WhatsApp Insurance Quotation Bot.json`),
  buscada con `git grep`. **No la he medido contra la API viva de PROD.**

**No medido:** que Quálitas acepte el RFC correcto, con qué frecuencia el modelo sigue la plantilla y no el ejemplo (aquí N=1), y si
algún cliente real ha recibido este rechazo. Lo determinista es que el texto se contradice. Abierto como **`aguayo-co/HYL-WAI#545`**
(sin duplicado: lo más cercano es el `#486`, enlazado).

## Los turnos (corrida `20261004-0633-536`)

| Turno | Cliente (literal) | Ejecución del bot | Lo que consta |
|---|---|---|---|
| 0 *(declarado)* | «Hola, quiero contratar el seguro de mi Toyota Highlander» | 75859 | presenta Amplia/Limitada con precios |
| 1 | «Me quedo con la cobertura Amplia, pago de contado» | 75862 | `Save Quotation Selection`; «Continuamos con *Cobertura Amplia…*»; en BD `paquete=1`, `forma_pago=C` |
| 2 | «Ana Prueba Quality, nací el 01/01/1990, soy mujer» | 75864 | `Save Group1 Progress` |
| 3 | «Placas QAA536B y número de serie 5TDDZRFH6LS005360» | 75865 | `Save Group2 Progress` |
| 4 | «Calle Roble 222, interior 4B» *(literal del handoff)* | 75867 | pide la colonia |
| 4b *(declarado)* | «Colinas del Valle» | 75868 | `Save Group3 Progress`: `numero_exterior=222`, `numero_interior=4B` |
| 5 | «No» | 75869 · guard **75871/resumen** | `Get Emission Record`; `*Domicilio:*` **Roble 222, Int. 4B**; sin teléfono |
| 6 | «Perdona, la dirección está mal: es Calle Fresno 150, sin interior» | 75872 | `Save Group3 Progress` (Fresno/150/`N/A`) y resumen nuevo: **Fresno 150**, sin interior |
| 8 | «Sí, confirmo» | 75873 · guard **75875/emitir** | `Issue Policy` → guard → Django → rechazo del RFC |

### Un matiz del turno 6 que mis comprobaciones no cubrían, y lo declaro

**El resumen nuevo del turno 6 se escribió sin llamar a `Get Emission Record`**: no hay ejecución del guard en ese turno, y el nodo no
está en la traza del bot 75872. El texto acertó (Fresno 150) porque el dato estaba en la conversación: es un **acierto de memoria, no
del camino** (`PASS-memoria`, §5.1.4 de mi `AGENT.md`). En la corrida anterior (`20261004-0628-536`), el mismo resumen **sí** pasó por la
tool (guard 75856). Así que, en lo observado, **1 de 2** resúmenes de corrección se saltó el H8 del prompt. Es N=2 y no lo elevo a
defecto. Pero queda dicho, porque el `#536` presupone que todo resumen sale del registro. El cuerpo de la emisión, que es lo que decide,
sí salió del registro en los dos casos.

## Tres corridas, no una — y las dos primeras fueron mías

1. **`experiment_id` NOT NULL.** El fixture falló en el primer `INSERT`: `qualitas_cotizacion` ganó `experiment_id` y otras 15
   columnas de atribución NOT NULL que mi lista escrita a mano no copiaba. **No se sembró nada ni se tocó el grafo.** Corregido de raíz:
   el clon copia ahora todas las columnas desde el catálogo y anula las de índice único propio (`clonarFila`). Ensayado aparte (siembra
   y limpieza, sin mensajes): correcto, residuo cero.
2. **Mi puerta paró en falso** (`20261004-0628-536`). La corrección se guardó con `numero_interior="N/A"`, y la puerta exigía `''`
   literal. Pero el guard trata `N/A` como vacío (`limpio()`, con el conjunto `PLACEHOLDERS` de su `Build Emission Record`): fue un
   **falso negativo de mi detector**. La puerta hizo lo que debía —**no emitió**—, y lo medido hasta ahí fue todo PASS, incluido el
   resumen nuevo, que esa vez sí pasó por la tool. Corregí el criterio al **del sistema, copiado de su fuente**, no a lo que convenía.
   La comprobación que manda sigue siendo el cuerpo, donde el interior llegó como `""` de verdad.
3. **La que cuenta** (`20261004-0633-536`), la de este informe.

## Residuo en STG — declarado y sin forzar

| Tabla | IDs | Por qué queda |
|---|---|---|
| `qualitas_leadfunnelevent` | **731** (`dato_emision_persistido`), **732** (`datos_emision_validados`) | trigger `qualitas_lead_funnel_event_append_only_trg`: «LeadFunnelEvent is append-only» |
| `qualitas_lead` | **1552** | lo referencian los dos eventos de arriba |
| `qualitas_asegurado` | **1948** | lo referencia `qualitas_lead.asegurado_id` |
| `qualitas_cotizacion` | **2906** | la referencia `qualitas_asegurado.cotizacion_id` |

**Borrado limpio:** 34 filas de `n8n_chat_histories`, la sesión `QA-SUITE-REGISTRO-EMITE`, 3 de `qualitas_leadactionevent` y 1 de
`qualitas_cotizacionrespuestaxml`. **No hay póliza** (`qualitas_polizaemitida` vacía para la 2906) y Quálitas rechazó antes de crearla,
así que no consta residuo en su QA. Todo lo que queda es sintético (correo `.invalid`, teléfono `1000000536`, «Ana Prueba Quality»).

**Hallazgo estructural para el protocolo:** cualquier emisión que llegue a persistir en Django deja eventos de funnel *append-only*, y
con ellos quedan sujetos el lead, el asegurado y la cotización. **Mientras ese trigger exista, ningún E2E de emisión puede limpiar a
cero en STG.** No lo he forzado (ni `UPDATE` para desenganchar, ni tocar el trigger). Si se quiere residuo cero, la decisión es tuya o
de Juan, no del arnés.

## Dos cambios del arnés que conviene saber

- **`clonarFila` desde el catálogo**, por lo de la corrida 1: una lista de columnas escrita a mano envejece en cuanto alguien añade una
  NOT NULL.
- **Los errores de `psql` ya no vuelcan la cadena de conexión.** El fallo de la corrida 1 escribió la URL de STG **con contraseña** en un
  log local (`reports/`, ignorado por git, nunca empujado). Lo saneé y el runner del `#536` ya solo relanza el mensaje de Postgres. **Los
  runners anteriores siguen con el patrón viejo**; no los he tocado porque no era el encargo.

## Método

Turnos de la tabla literales; los tres extra (saludo, colonia ofrecida y una respuesta mínima que no hizo falta) declarados en la
cabecera y literales en la traza. `wamid` único por turno. Sesión y teléfono de WhatsApp sin un solo dígito, para que el fence corte el
envío a Meta. El 536 va en el correo del clon. Versiones leídas por GET y con paro si no coinciden. Puerta antes de emitir con todas las
precondiciones medidas en el `runData`. Lo que no consta en la traza no se da por PASS.

Artefactos en `informes/2026-10-04-536/`: JSON y traza de las dos corridas que llegaron al grafo, y sus logs (sin secretos, comprobado).

— Agente QA & Testing
