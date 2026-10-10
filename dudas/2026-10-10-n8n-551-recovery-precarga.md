# Duda n8n · #551 Recovery: precargar el contexto de Django y pedir solo lo que falta (diseño antes de construir)

**Handoff:** `Agente-n8n:handoffs/2026-10-10-551-recovery-precargar-y-pedir-solo-lo-que-falta.md`. Bot STG `9412c9b0`.
**Fuente del contrato:** `HYL-WAI:qualitas/recovery_n8n.py::_source_context` (último commit `c01d3b02`, 9 oct). **No he construido nada.**

## Lo medido
1. **El descarte:** se confirma. `Validate Recovery Envelope` solo deja pasar `previous_policy`, y `Activate Recovery Session` solo guarda eso
   más `recovery_solo_contexto`.
2. **«Capturado» se decide por la clave, no por el contenido.** `derivarCheckpoint` (en Merge Session Data, que alimenta `checkpoint=` y
   `pendiente=` del [CTX:]) copia a Django: `'grupo1' in captured_data`. Si **precargo un grupo a medias**, el bot y los seguimientos de
   checkpoint de Django lo dan por capturado, y el modelo se salta lo que falta. Es justo el «no basta con que exista la clave» de Juan.
3. **Los Save GroupN sobrescriben el grupo entero** con lo que pasa el modelo (`jsonb_build_object` con todos los campos). Si precargo y
   el modelo guarda solo lo nuevo, se borra lo precargado.
4. **Género:** Django lo da como «0»/«1» (`forms.py`: `0`=Masculino, `1`=Femenino). La frontera de emisión ya acepta M/F como alias
   (`external_emission_contract._GENDER_ALIASES`). El bot guarda M/F (STG: 18 M, 7 F, 1 N/A). Mapeo seguro: `0`→M, `1`→F, cualquier
   otro valor → se pide.
5. **Lo que exige la emisión** (`emission-record.core.js`, el mismo criterio del resumen y del cuerpo): nombre, apellido paterno,
   fecha de nacimiento, género, RFC, `requiere_factura`, serie, calle, número exterior y colonia, más el CP, el teléfono, el paquete y la
   forma de pago de `qualitas_cotizacion`. El materno, el interior y las placas pueden ir vacíos.
6. **La cotización de recuperación del caso real** (2985) ya trae paquete `1` y forma de pago `C`: la selección no falta.
7. **Fuera de mi mapeo:** el tipo y número de identificación los fija hoy la emisión (`'1'`, `'1234567891'`); los de Django no se usan.

## 1. El mapeo (propuesta)
| contexto v2 | va a | validación; si falla o es nulo → se pide |
|---|---|---|
| `personal.first_name` / `paternal_surname` / `maternal_surname` | `grupo1.nombre` / `apellido_paterno` / `apellido_materno` | texto no vacío ni marcador. El materno nulo se pregunta y se acepta «no tengo» |
| `personal.birth_date` (ISO) | `grupo1.fecha_nacimiento` (DD/MM/AAAA, la forma del bot) | fecha real; edad entre 18 y 99 |
| `personal.gender` | `grupo1.genero` | solo `0`→M, `1`→F |
| `personal.rfc` | `grupo2.rfc` | 10 o 13 caracteres; los 10 primeros = `rfcBase` del grafo con el grupo 1. Si no cuadra, no se precarga |
| *(no viene)* | `grupo2.requiere_factura` | **siempre se pregunta** (ver §6) |
| `vehicle.plates` | `grupo2.placas` | el validador del `#478` |
| `vehicle.vin` | `grupo2.serie` | **lo decides tú (§3)** |
| `address.street` / `exterior_number` / `interior_number` / `neighborhood` | `grupo3.calle` / `numero_exterior` / `numero_interior` / `colonia` | no vacíos (el interior puede faltar) |
| `address.city` (o `municipality`) / `state` | `grupo3.ciudad` / `estado` | informativos |
| `address.postal_code` | `grupo3.codigo_postal` | **igual al CP de la cotización de recuperación**; si difiere, no se precarga el domicilio |
| `contact.email` / `contact.phone` | no se precarga | el correo canónico sale de `qc.email` (`#466`/`#492`) |

**Dónde vive:** `captured_data.recovery_precarga = {grupo1, grupo2, grupo3}`, solo con los campos válidos. Se escribe en
`Activate Recovery Session`, en la misma sentencia y con las mismas guardas de identidad. Un grupo **completo y válido** se escribe
además en `grupoN`, así que la clave solo existe cuando de verdad está todo. Un grupo parcial **no crea la clave**.

**Los Save GroupN fusionan:** si el modelo deja un campo vacío o con marcador y la precarga lo tiene, se queda el de la precarga. Si el
cliente lo corrige, gana el cliente. Así se integran las respuestas parciales y las correcciones sin perder nada.

**[CTX:]:** dos líneas nuevas, `precargado=` (qué campos hay, sin valores) y `faltan=` (la lista de la emisión, calculada en el grafo).
El modelo pregunta solo `faltan`.

## 2. El nombre
- Si `personal.*` viene, se usa tal cual.
- Si **solo** viene `contact.full_name` (el caso de la campaña: «Persona Ficticia Recovery Colombia», sin `Asegurado`), **no se parte**:
  el bot se lo enseña al cliente y le pide «nombre(s), apellido paterno y apellido materno».
- Choque con el contrato, para el `#551` (lo documento allí si estás de acuerdo): sin `Asegurado`, Django solo tiene el nombre completo
  en `nombre_comprador`. O Django aporta los componentes, o la pregunta es inevitable.

## 3. La serie y las placas de Django (toca la emisión: decides tú)
Hoy `Save Group2 Progress` solo acepta una serie con procedencia: `tecleada`, `foto_confirmada` o `descuento` (`discount_serie`, que
**ya es una serie que viene de Django y se acepta sin confirmar**). Opciones:
- **(a) Como la foto:** la serie de Django entra como `serie_recovery` con estado «propuesto». El bot la enseña («¿Tu número de serie sigue
  siendo …?») y la confirmación la promueve, con la misma lógica que `Promote Foto VIN`, a `serie_source = 'recovery_confirmada'`.
  Es el camino más seguro (un coche cambiado o una serie mal capturada en la póliza anterior) y cuesta una pregunta.
- **(b) Como el descuento:** `serie_source = 'recovery'`, aceptada sin preguntar. Ese precedente existe, y es la única forma de cumplir el
  escenario 1 de Juan (resumen directo).

Recomiendo **(a)**, pero el resumen ya muestra la serie y la emisión exige confirmarlo: en la práctica, (b) también la enseña antes de
emitir. Las placas pasan por el validador del `#478` en los dos casos.

## 4. El flujo
- Tras «me interesa», si `faltan` está vacío, **ir directo al resumen**. Propongo hacerlo determinista: un carril gemelo del `#418`,
  que lea el registro con `Read Summary Record` y `Rebuild Summary From Record` (lo mismo que hoy rehace el resumen del modelo), mande el
  resumen literal y pase la fase a `summary_confirmation`.
- La alternativa es dejarlo al modelo con `faltan=` en el [CTX:]. Funciona, pero no es «inmediatamente» garantizado.
- La emisión sigue exigiendo la confirmación explícita del resumen; «me interesa» no la sustituye.
- Si faltan campos, el modelo pide **solo esos**. Cuando el último se guarda, en el turno siguiente `faltan` queda vacío y se aplica la
  misma regla.

## 5. El aislamiento
- La precarga solo sale del sobre ya validado (participante, campaña, `quote_id` del par `waq_<quote>_…` iguales a los de la respuesta).
- Se escribe en la misma sentencia que activa la sesión, bajo el lock del teléfono y con las comprobaciones de identidad (`cid_ajeno`,
  `identidad_distinta`).
- En un reintento (`replayed`), la precarga se rellena solo si no existía. Nunca pisa grupos ya capturados ni datos de otro lead: la
  sesión es la del `quote_id` resultante.

## 6. Contrato insuficiente (para Juan, en el `#551`)
- `requiere_factura` y la homoclave no vienen, aunque `Asegurado` tiene `requiere_factura` y `homoclave`. Sin ellos, el escenario 1
  («todo completo → resumen directo») siempre hace **una** pregunta: la de la factura.
- El nombre estructurado, cuando no hay `Asegurado` (§2).

## Preguntas
1. ¿Vale el diseño de dónde vive la precarga (`recovery_precarga` aparte, grupo escrito solo si está completo, y fusión en los Save)?
2. **La serie:** ¿(a) o (b)?
3. **El resumen:** ¿carril determinista o modelo con `faltan=`?
4. ¿Documento en el `#551` lo de la factura, la homoclave y el nombre? ¿O asumimos la pregunta de la factura y Juan no cambia nada?

## Aceptación (si me das paso)
- Los tres escenarios de Juan, con sesiones sintéticas sembradas con el sobre en el arnés sin envíos:
  - todo completo → resumen directo, salvo la factura según §6;
  - solo faltan género y nacimiento → solo eso, y luego el resumen;
  - un sobre como el de la campaña → conserva el nombre y pide los componentes y lo que falte.
- Más: respuesta parcial, corrección posterior y reintento sin mezclar leads.
- Prueba controlada en STG con el teléfono de Alberto. La versión y los resultados, en el `#551`.

Agente: Agente-n8n
