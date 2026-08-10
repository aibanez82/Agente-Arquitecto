# Manual de migración a STG — lo aprendido en S1, para que la próxima cueste días y no semanas

Escrito el 8-9 ago 2026, al final del primer carril Contract-First con acciones vivas en staging.
**No es una crónica: es lo que hay que hacer primero la próxima vez.**

> **Documento vivo.** Por decisión de Alberto (8 ago 2026) se alimenta con cada aprendizaje
> útil **hasta que S1 cierre en STG**. Si aparece una trampa, un error de método o una
> práctica que evitó daño, entra aquí en el momento — no al final, cuando ya se olvidó el
> detalle que la hacía útil.

La crónica está en el tablero y en `HYL-WAI#132`.

## 0. La tesis, en una frase

El plan tardó **12 días** desde que se abrieron los issues rectores hasta llegar a la corrida final, y
**la mayor parte del retraso no fue implementar: fue descubrir hechos del entorno en mitad de la
ejecución**, cuando ya había GO emitidos, ventanas abiertas y pasos irreversibles delante.

Casi todos esos hechos eran averiguables **el primer día, en frío, sin permiso de nadie**. De ahí este
documento.

---

## 1. Reconocimiento de entorno — hacer esto ANTES de escribir el plan

Cada línea de esta tabla costó al menos una vuelta en S1. Todas se responden en una tarde y sin tocar
nada vivo.

| Pregunta | Por qué costó una vuelta en S1 |
|---|---|
| **¿Existe un rol de solo lectura en la BD de staging?** | No existía. Se descubrió con Gate A ya asignado. Hubo que resolverlo con una opción de sesión y dejar deuda declarada. |
| **¿Qué `sslmode` acepta esa BD?** | El DSN sin `sslmode` no conecta y `require` tampoco —se comporta como `verify-full` contra cadena autofirmada—. **Solo `no-verify`**. Se descubrió con el material ya entregado. |
| **¿La API pública del sistema expone la operación que el plan necesita?** | La de n8n **no expone ejecutar**. El plan asumía que sí y el método acabó dependiendo de la UI. |
| **¿La UI guarda al abrir? ¿Al ejecutar?** | El editor **re-serializa y omite parámetros con valor por defecto**, moviendo fingerprints; y *Execute* **guarda**. Esto invalidó el método del GO **con el operador ya delante del teclado**. |
| **¿Un cambio de variable de entorno es efectivo sin redesplegar?** | En Vercel **no**: se aplica a despliegues nuevos. En Heroku sí, con release. Confundirlo hace publicar «cambiado» sobre un sistema que no cambió. |
| **¿El entorno de pruebas está detrás de autenticación?** | El Preview del Dashboard sí. Sin cookie, **los dos modos responden igual (307)** y el modo efectivo no es observable. Se descubrió al ir a acreditarlo. |
| **¿Qué abre la ventana de 24 h del proveedor de mensajería?** | Un mensaje real del usuario. **Una fila insertada en la BD no la abre.** El fixture era sintético por SQL y el envío real habría sido rechazado. |
| **¿Los IDs enteros llegan como número o como cadena?** | `BigAutoField` → `bigint` → el driver de Postgres devuelve **cadena**. Rompe a la vez la validación de schema (`type: integer`) y cualquier hash. |
| **¿Qué versión del sistema hay desplegada, y se puede leer del servidor?** | La API pública de n8n **no la expone**. Esa laguna decidió tres cosas distintas: una enmienda de contrato y dos análisis posteriores. |

**Regla:** antes de congelar un contrato, escribir el inventario de estas respuestas **verificadas en
vivo**, no supuestas. Un contrato congelado sobre supuestos de entorno se rompe al ejecutarlo, y
romperlo cuesta una enmienda, no un commit.

---

**Pregunta que faltaba en esta tabla y que descubrimos tarde:** *¿corren staging y producción la misma
versión del motor?* En nuestro caso la respuesta era **no, y por 3 599 commits** — cinco meses de
diferencia entre las dos instancias de n8n. Nadie lo había mirado nunca.

Importa por dos motivos distintos, y el segundo no es obvio:

1. **Un verde en staging no es una predicción sobre producción** mientras las versiones difieran. Es
   el supuesto sobre el que descansa tener staging, y estaba sin comprobar.
2. **Versiones distintas normalizan el JSON de forma distinta al guardarlo.** Si tu método acredita
   comparando artefactos byte a byte entre entornos —el nuestro lo hace—, la diferencia de versión es
   **una fuente de drift que no viene de que nadie haya cambiado nada**. Días de investigación
   buscando un culpable que no existe.

Cuesta una pregunta. La respuesta, si es «no», no obliga a actualizar nada de inmediato: obliga a
**saber qué compra y qué no compra cada validación**.

### 1 bis. Resuelto el 10 ago — y lo que enseñó hacerlo

PROD subió de n8n 2.6.3 a **2.28.7** (misma versión que STG). Ventana 1 min 48 s, ~70 migraciones en
13 s, los 5 workflows idénticos antes/después, los 3 `webhookId` sin cambio. Informe:
`Agente-n8n:handoffs/2026-08-10-upgrade-n8n-2287-prod-informe.md`.

**El punto 2 de arriba queda contestado con evidencia, y a nuestro favor:** los workflows almacenados
**no se re-normalizaron** al saltar 3 599 commits — `nodes`+`connections` byte a byte idénticos, mismo
SHA-256 en los cinco. El motor solo reescribe **al guardar**, y nadie guardó. Es decir, el miedo era
correcto como riesgo y falso como hecho: **la re-normalización la dispara guardar, no arrancar.**

**El punto 1 sobrevive, pero mucho más débil de lo que se escribió primero.** El informe del upgrade
declaraba PROD como licencia **enterprise** frente a STG **community**, y sobre eso monté una
asimetría de features que llegué a publicar en `#132`. **Era falso:** Alberto abrió *Usage and plan*
en las dos instancias y las dos dicen **«You're on the Community Edition (Registered)»**. Explicación
probable del error, no verificada: el `environment: production` del certificado de licencia designa
el **servidor de licencias** al que habla n8n, no un plan de pago.

Lo que queda de asimetría real es de **plataforma**, no de features: plantilla de Hostinger (app n8n)
contra Docker genérico, y la BD interna de n8n (SQLite en PROD, sin verificar en STG).

**La lección de método es la cara, y es mía:** el dato estaba a diez segundos de la UI, y en su lugar
lo tomé del cuadro de reconocimiento del ejecutor y lo publiqué en el tracker de Juan. Verificar
contra el doc de entrega **no es** verificar contra la fuente cuando el doc de entrega es quien pudo
equivocarse. Corolario: **un dato observable en la UI del propio sistema se comprueba en la UI**, no
en el informe de quien la miró.

**Yo planifiqué ese upgrade sin responder esta tabla, y tres supuestos míos eran falsos:**

| Supuesto del plan (9 ago) | Realidad |
|---|---|
| Hace falta Juan para saber el escenario de despliegue | Es **Docker**, y se lee del propio panel + *Copy debug information*. Cero dependencia externa |
| Backup con `pg_dump` | La BD interna de n8n es **SQLite**. El Postgres es la de aplicación y el upgrade no la toca |
| `N8N_ENCRYPTION_KEY` es variable de entorno; comprobar que «se conserva» | Vive **autogenerada en un fichero** de 56 bytes dentro del volumen. La comprobación real es no perder el volumen |

Es exactamente el fallo que este documento existe para evitar, cometido por quien lo escribe: **el
plan se redactó antes del reconocimiento**. Filas nuevas para la tabla del §1, todas de una tarde:
*¿escenario de despliegue?* · *¿qué motor tiene la BD interna del propio sistema, no la de la
aplicación?* · *¿la clave de cifrado es variable o fichero?* · *¿las imágenes del compose llevan tag?*

**Trampas técnicas que salieron y son reutilizables** (van también al §5):

- **SQLite no vuelca el WAL al apagarse.** Copiar solo `database.sqlite` habría perdido **2 h 30 min**
  de escrituras en silencio. Se copian los tres ficheros (`.sqlite`, `-wal`, `-shm`) juntos.
- **Imágenes de compose sin tag** (`image: docker.n8n.io/n8nio/n8n`): un `docker compose pull` salta a
  `latest` y **arrastra lo que comparta el compose** — aquí, Traefik con sus certificados y 6 meses de
  uptime. Fijar tag antes de tocar nada, y levantar con `--no-deps`.
- **Ensayar la migración sobre una copia con el sistema en marcha**, en contenedor `--network none` y
  con un comando de CLI en vez de arrancar el producto, para que no se active ningún workflow ni
  dispare ningún cron. Y la prueba diferencial: **segunda pasada → 0 migraciones**, que es prueba de
  que se persistieron y no una inferencia de que no dio error.

### 1 ter. Una herramienta de seguridad sin hogar canónico deja de ser una red

El upgrade cambió la **forma del objeto que devuelve la API** (`nodeGroups` aparece, `description`
desaparece). El detector de drift compara el objeto entero descartando una lista fija de claves
volátiles, así que **reportará drift falso en todo PROD sin que nadie haya tocado nada**, y con `--go`
sobrescribiría los baselines. `qualitas-issues#74`.

Lo que enseña no es la lista de claves. Es que **el script no vive en `main`**: existe en veinte ramas
y su tabla de destinos **ya se ha bifurcado en dos versiones distintas**. Cuál se ejecuta depende de
qué rama esté pagada en ese clon. Una red de seguridad que depende de eso no es una red.

**Regla:** la herramienta que vigila un entorno vivo tiene **una** copia canónica, en la rama que
todos comparten, y se actualiza ahí. Si está en una rama de trabajo, lo primero es sacarla.

Y el corolario que casi nos muerde: el arreglo obvio —añadir `description` a la lista de claves
volátiles— **habría sido peor que el bug**, porque el filtro es **recursivo** y `description` es
también el campo por el que un agente LLM decide qué herramienta llamar. Habríamos quedado ciegos
justo en el campo que gobierna el comportamiento del bot. **Cuando un filtro es recursivo, una clave
del envoltorio y una clave de contenido con el mismo nombre son indistinguibles.**

## 2. Los errores de método que más caros salieron

### 2.1 Verificar la propiedad que se puede observar en vez de la que importa

**Es el error más repetido de todo el ciclo**, y lo cometimos todos.

- Se verificó que un mecanismo *existía* en vez de que se *invocara* — `grep -c` daba 0 llamadas.
- Se verificó que el contrato estaba *vendorizado* byte a byte en vez de *implementado* — se
  vendorizó `1.0.2` y se ejecutaba `1.0.1`.
- Se verificó el caso *discrepante* y no el *coherente*, que era el que pasaba.
- Se verificó que el *builder* rechazaba symlinks, no que la *CLI* lo hiciera.
- Se verificó que **mi cliente** conectaba con el DSN, pasando `ssl` como opción de cliente, en vez de
  probar **el DSN solo**, que es como lo consume el código. El DSN entregado no habría conectado.

- **Se razonó sobre el mecanismo en vez de observar el sistema**, dos veces en la misma noche:
  (i) se designó como «baseline operativo» la preimagen de un state-dir creado **después** del import
  —contenía el perfil de gates, no el estado normal—, y seguirlo habría dejado **staging activado y
  roto con apariencia de correcto**; (ii) se afirmó que un gate de solo lectura denegado «no escribe
  `uncertain`», leyendo rutas de código en lugar del **journal**, que es el estado real.
  **Cuando exista un registro del estado, leerlo. El código dice lo que debería pasar; el registro
  dice lo que pasó.**

**Antídoto operativo:** todo control positivo debe ejercitarse **por la misma ruta de código que lo
va a consumir**, y todo negativo debe fallar **por el motivo esperado** —si deniega por otra razón,
no ha probado nada—. Y ante una garantía, enumerar **todos** sus puntos de entrada: en S1, seis
subcomandos hacían llamadas vivas sin acreditar el target porque solo dos lo comprobaban.

### 2.2 «Declarado» no es «efectivo»

Tres veces en un día: el modo del Dashboard, el de Django y el estado de la BD. Un valor en una
variable de entorno, en un fichero o en un GO **no es el comportamiento del sistema**.

**Antídoto:** acreditar por comportamiento observable —un `503` frente a un `200`, un rechazo del
servidor— y **capturar el estado ANTES de cambiarlo**. Sin la lectura previa, un `PASS` no distingue
haber cambiado algo de haberlo encontrado ya cambiado.

### 2.3 La ausencia de observación no es una garantía verificada

«Cero filas» puede significar «no hay» o «no tienes permiso». Casi se publica una conclusión falsa
porque `information_schema` ocultaba tablas de PROD que sí existen: filtra por privilegio. Se cazó
comparando contra `pg_class`.

El propio preflight de Django lo dice mejor que nosotros: *«cero controles observados no verifican la
puerta de contención externa»*.

**Antídoto:** cuando un conteo sea cero, preguntarse siempre si se está midiendo ausencia o ceguera.

### 2.4 Publicar el valor esperado como si fuera el observado

Se publicó `ledger_rows=1` —el valor que tendría tras un paso que **nunca se ejecutó**— rellenando la
plantilla del GO en vez de leyendo la base. El real era `0`.

**Antídoto:** las plantillas de salida se rellenan **desde la observación**, campo a campo. Nunca se
copia el ejemplo del GO.

**Y el caso más caro de esta familia no fue un número, fue una frase de procedimiento.** Se escribió
«retransmitido por el owner» como **fórmula** en la cabecera de ocho handoffs, al redactarlos y antes
de que la retransmisión existiera. El ejecutor no tiene otra forma de saberlo, así que se apoyaba en
ella para decidir **si podía ejecutar**: durante ocho entregas, el control de arranque no controlaba
nada y nadie lo notó.

**Regla:** un campo que otro va a usar para decidir si actúa **no se rellena al redactar**. Se deja en
`PENDIENTE` y se cambia, en un cambio propio y fechado, cuando el hecho ocurre. Si al escribir un campo
no puedes señalar la observación que lo respalda, ese campo miente aunque acabe siendo cierto.

### 2.5 bis Una precondición **asumida** no es una precondición verificada

Aprobé un reparto de trabajo cuyo paso final era **una interacción real de WhatsApp**, dando por hecho
que la haría el owner. Nadie comprobó de qué número tenía que salir el mensaje. El transporte del par
de pruebas **pertenecía a un tercero**, así que el owner no podía ejecutarlo: el reparto era inviable
desde que lo escribí.

Se cazó porque alguien preguntó **antes** del paso irreversible, no porque el método lo previera. Un
paso más tarde habríamos descubierto con el sistema ya publicado que hacía falta un teléfono al que no
teníamos acceso.

**Regla:** antes de asignar a alguien un paso, enumera **qué tiene que poseer** para ejecutarlo
—credencial, teléfono, consola, permiso— y verifica **cada** cosa. La pregunta no es «¿quién lo hace?»
sino «¿qué hace falta tener, y quién lo tiene?». Un reparto es una afirmación sobre capacidades, y las
afirmaciones se verifican.

Corolario del canal: cuando el dato que decide es privado, el que lo tiene responde **solo el hecho**
—«sí» o «no»— por el canal de coordinación, y **el dato** por el privado. Así se decide sin que el
material circule.

### 2.5 ter La señal de arranque no se acredita sobre un traslado

El día que estrenamos la línea `Orden de arranque` (§2.4), el owner la dio de viva voz **al ejecutor**,
que la trasladó pidiendo que se marcara. El ejecutor se negó a escribírsela él mismo, y con razón:
escrita por el operador solo acredita que **él dice** que se la dieron.

Lo que faltó ver es que **el arquitecto marcándola sobre ese traslado tiene el mismo defecto con un
salto más**: acredita «el ejecutor dice que el owner dijo». La cadena degrada igual.

**Regla:** la señal la escribe **quien observó el hecho**. Si el owner te la dio a ti, la marcas tú; si
se la dio a otro, la confirmas con el owner antes de marcarla. Cuesta un mensaje. Es exactamente el
coste que evita reintroducir por la puerta de al lado el defecto que acabas de retirar por la principal.

### 2.6 El comportamiento del sistema se lee en el artefacto publicado, no de memoria

Un guion de instrucciones para un tercero advertía que cierta palabra «deja la sesión bloqueada con una
respuesta fija hasta liberarla a mano». Contrastado contra el workflow recién publicado, **el nodo de
enrutado manda esa intención a la misma salida que la ruta normal**: no hay bloqueo. El efecto real era
otro —y peor—: el flujo acaba **registrando un lead**.

El consejo práctico era correcto; el mecanismo, inventado de memoria. Y a un tercero se le publica el
mecanismo, no solo el consejo.

**Regla:** toda afirmación sobre **cómo se comporta** el sistema se comprueba en el JSON del workflow o
en el código desplegado, no en el recuerdo del prompt. Son treinta segundos. Y aplica igual —o más—
cuando la afirmación viene de quien más domina ese sistema: la seguridad con la que se dice una frase
no es evidencia de nada.

**Coda, y es la mitad más importante: esa corrección mía también estaba mal.** Verifiqué **un solo
nodo** —el de enrutado—, vi que la intención iba a la ruta normal, y concluí «no hay rama de bloqueo».
La había: un `IF` posterior, alimentado por otro guard, cortocircuitaba el flujo entero con una
respuesta fija a partir de que el lead quedaba registrado. El aviso original acertaba en la
consecuencia y erraba en la ruta; **el mío arregló la ruta y borró la consecuencia**, que era la parte
útil. De los dos errores, el mío era el peligroso: el otro erraba hacia el lado seguro.

**Regla:** **una verificación puntual no acredita una conclusión general.** Comprobar un nodo autoriza
a afirmar algo sobre ese nodo, no sobre el camino. Si la afirmación es «no ocurre X», hay que recorrer
el flujo hasta el final, porque *no haberlo visto* y *no estar* se parecen mucho desde un solo punto.

Y el corolario de conducta: **quien corrige carga con el estándar que exige**. Una corrección publicada
pesa más que la frase que corrige —llega con autoridad y desactiva el aviso original—, así que merece
más verificación, no menos. Lo salvó que el ejecutor contrastó mi corrección contra la fuente en lugar
de acusar recibo. Un equipo donde el de arriba no se contrasta acumula errores con presentación de
certeza.

### 2.5 Guardas que fallan abiertas

`[ -z "$(git status --porcelain)" ]` da éxito si el comando muere sin escribir nada: un fallo se lee
como «limpio». Hay que separar **el fallo del comando** del **resultado limpio**.

Y en la misma familia: `mkdirSync` sin modo hereda el umask, y `mkdirSync` **con** modo **no corrige
un directorio ya existente** — el arreglo obvio tampoco basta.

### 2.7 Una suite verde no es cobertura: hay clases de defecto que no puede ver

La conformidad de la etapa salió `success` y la **primera corrida real** murió a los tres minutos, en
un nodo de base de datos, por un parámetro que llegaba con el tipo equivocado.

Al mirar por qué, lo interesante no fue el hueco sino su forma. La suite **mencionaba** la rama que
falló, en tres tests — pero para afirmar que **nunca se llegara** a ella (`assert.notEqual`), no que
funcionara al llegar. Y de fondo: **ningún test offline ligaba parámetros SQL contra su consulta**.
Ejercitaban lógica sobre objetos. Por construcción, **ninguna cantidad de esos tests podía cazar un
desajuste de tipo en un parámetro** — y de hecho el mismo nodo ya había tenido otro bug de parámetro
un mes antes, por otra causa, sin que la suite lo viera tampoco.

**Regla:** antes de fiarte de un `PASS`, pregunta **qué clases de fallo puede detectar esa suite**, no
cuántos casos cubre. Una rama de respaldo —la que se usa cuando falta el dato bueno— es justo la que
los tests tienden a declarar indeseable en vez de ejercitar, y justo la que el tráfico real pisa el
primer día.

**Y el corolario operativo:** cuando aparezca un defecto así, la línea a arreglar es lo barato. Lo que
hay que decidir es si la suite puede ver esa clase de defecto; si no puede, arreglar la línea solo
compra tiempo hasta el siguiente.

### 2.8 «No observable» es una conclusión, y hay que ganársela

Nos hizo falta la versión del motor desplegado. El endpoint obvio no la traía, así que la declaramos
**brecha no observable** y seguimos. Estaba en `n8nDetails.n8nVersion`, **dentro del payload de error
de la ejecución que ya estábamos investigando** — en la mano, desde el día anterior.

El fallo no fue de conocimiento sino de reflejo: de *«el sitio obvio no lo trae»* saltamos a *«no se
puede saber»* sin repasar qué objetos ya teníamos delante. Y esa declaración hizo daño activo: **una
brecha declarada cierra la búsqueda con aspecto de rigor**, mientras que una pregunta abierta la
mantiene viva. Además nos llevó a fabricar una explicación dependiente de versión que resultó falsa.

**Regla:** antes de declarar algo no observable, enumera **los artefactos que ya posees** —payloads de
error, respuestas guardadas, logs, volcados— y busca ahí. Solo después se declara la brecha, y se
declara diciendo **dónde se buscó**, para que el siguiente no repita la búsqueda ni herede la
conclusión sin la evidencia.

### 2.9 Un bug conocido que encaja con tus síntomas es la respuesta equivocada más cómoda

Un nodo se colgaba hasta agotar el timeout de 300 s. Buscando, apareció **un issue abierto del propio
motor** que describía el síntoma y cuya precondición **se cumplía en nuestro workflow**. Encajaba
perfectamente.

**No era.** La causa real era aburrida y nuestra: ese nodo era **el único de 23** que construía en
caliente el argumento de un acceso a otro nodo, en vez de pasarlo literal — y con literal el motor
puede resolver estáticamente qué datos enviar. Un detalle sin misterio.

Lo que hace peligroso a un issue que encaja es que **ofrece una salida honorable**: «coincide con un
bug conocido, no es nuestro, a esperar el fix». Nadie te discute esa conclusión, y el defecto sigue
vivo.

**Regla:** un bug externo que explica tus síntomas es **una hipótesis más**, no un veredicto — y
compite en igualdad con «lo nuestro es distinto al resto». Antes de adoptarlo, busca **en qué se
diferencia el elemento que falla de los que funcionan**; si es el único de veintitrés que hace algo,
esa es la pista, encaje o no encaje el issue.

Y cuando ambas hipótesis sigan vivas, **diseña el cambio para que discrimine**: elige el que, salga
como salga, te diga cuál era. Así ninguna ronda se gasta solo en descartar.

---

## 3. Trazabilidad: el fallo silencioso más caro

En una sola jornada, el registro atribuyó **seis veces** a nuestro lado acciones que no hizo: un
resultado de operador que nadie ejecutó, un `BLOCKED` no publicado, un dyno que no se abrió, una
atestación de teléfono, un `config:set` aplicado por la otra parte, y tráfico de pruebas en STG.

Cinco eran contabilidad. El sexto importaba: el aviso existía **para descartar que hubiera terceros
operando en STG**, y al atribuirlo al owner concluía lo contrario de lo que los hechos permitían.

**Aprendizajes:**

- **Verificar la procedencia antes de aceptar un hecho del registro.** El log de releases de la app
  dijo quién y cuándo en diez segundos.
- **Un método cuyo valor es la trazabilidad se degrada en silencio.** Nadie nota una atribución
  equivocada hasta que alguien audita seis meses después.
- **Declarar las desviaciones en el momento**, incluso las propias y las incómodas: una corrida que
  excedió su GO, una conexión de más, un artefacto que no debía existir.

---

## 4. Lo que funcionó, y hay que repetir

No todo fue fricción. Estas prácticas evitaron daño real:

- **Parar y preguntar en vez de improvisar.** Los ejecutores pararon **nueve veces** en la jornada.
  Las nueve tenían razón. Cero envíos equivocados.
- **El turno partido con punto de parada.** En la corrida final, el orden *fijar pin → verificar →
  ejecutar* hizo que el fallo se cazara **antes del envío irreversible**. Con el orden inverso habría
  habido cuatro mensajes entregados a una persona y una acreditación imposible.
- **Dos criterios en vez de uno.** Quien conduce la UI y quien verifica no deben ser el mismo.
- **No emitir un compromiso quien después lo verifica.** Si el operador calcula el hash que él mismo
  va a comprobar, el control certifica su propia elección. Se sostuvo tres veces.
- **Preservar la evidencia antes de restaurar.** Ante el fallo final se decidió **no** hacer el
  rollback: restaurar habría sobrescrito con dos PUT el estado que era la prueba del hallazgo.
- **Demostrar en vez de deducir.** El drift de fingerprints se probó con corchete temporal, control
  positivo (workflow tocado) y negativo (workflow intacto).

---

## 4 bis. Leer el GO buscando si es **ejecutable**, no solo si es correcto

Tres GO de la jornada eran impecables de alcance y **materialmente imposibles** tal como estaban
escritos. Ninguno lo era por descuido: describían el trabajo bien, pero nadie había comprobado que se
pudiera hacer.

| Lo que pedía el GO | Por qué no era ejecutable |
|---|---|
| fijar el pin **«mediante UI»** | ese paso **rompe los fingerprints** que el paso siguiente exige intactos: el método se invalida a sí mismo |
| que **el owner** enviara un mensaje desde el teléfono de prueba | ese teléfono **no lo tiene el owner**, y el número de destino tampoco era conocido de este lado |
| que el operador ejecutara la porción PostgreSQL | primero se le retiró la autorización y minutos después se le devolvió; entre medias, el paso era imposible |

**Antídoto — al recibir un GO, antes de aceptarlo, comprobar tres cosas:**

1. **¿Quién tiene físicamente lo que hace falta?** Un teléfono, una credencial, una consola, un
   navegador. La capacidad no se delega por escrito.
2. **¿Algún paso del método destruye una precondición de otro paso?** En S1, pinchar por UI rompía lo
   que `pin-verify` exigía. Se detectó **con el operador delante del teclado**.
3. **¿La herramienta expone la operación que el GO nombra?** «Execute workflow» existe en la UI y
   **no** en la API pública. El plan asumió que sí.

Cuesta cinco minutos y ahorra una ventana operativa entera. Y decirlo **antes** es barato: decirlo
después de un paso irreversible no arregla nada.

## 4 ter. Una cadena de acreditación necesita un camino de reparación

En S1 la ventana operativa quedó **atrapada sin que nadie hiciera nada malo**: en cuanto el contenido
vivo se desvió del artefacto acreditado, **las dos salidas se cerraron a la vez** —`rollback` y
`close` acreditan el contenido vivo antes de actuar— y **lo único que repararía el contenido estaba
prohibido** en el estado al que ese mismo desvío había llevado la ventana.

No fue un fallo de implementación: cada guarda hacía exactamente lo que debía. El agujero está en el
**diseño del conjunto**.

**Preguntas que hay que hacerle a cualquier máquina de estados con acreditación, antes de congelarla:**

1. **¿Existe al menos un camino desde cada estado hasta un final seguro?** Si un estado solo admite
   acciones que a su vez exigen una precondición que ese estado impide, es una trampa.
2. **¿La reversión exige que lo vivo esté acreditado?** Revertir es justamente lo que se hace cuando
   *no* lo está. Una preimagen debería poder aplicarse **sin** exigir que el presente case.
3. **¿Un control que para a tiempo cuesta lo mismo que un fallo a medias?** En S1 un gate de solo
   lectura denegó **antes de escribir nada** y aun así dejó la ventana en `recovery-only`. El criterio
   conservador es defendible, pero conviene que sea una **decisión** y no un efecto colateral.

**Y el criterio que sí funcionó para desempatar fuentes:** cuando hay varios candidatos y ninguno es
inequívoco, **lo que acredita no es la procedencia: es la coincidencia independiente**. El baseline se
resolvió porque una preimagen registrada por la herramienta y un fichero versionado **decían lo mismo
por fingerprint**. Ninguno de los dos bastaba por separado; si no hubieran coincidido, la respuesta
correcta era STOP.

## 5. Catálogo de trampas técnicas concretas

Para consultar en frío, sin contexto:

- **Un editor visual no es un canal utilizable sobre artefactos acreditados.** El de n8n
  **re-serializa al guardar y omite los parámetros cuyo valor coincide con el defecto**: mueve
  fingerprints de nodos que nadie tocó. Y *«Execute workflow»* **guarda** —con autoguardado activo, en
  silencio—, así que no hay «ejecutar sin guardar». Cualquier procedimiento que diga «hazlo por la UI»
  sobre algo con fingerprints congelados **nace roto**.
- **`sha256sum` no es portable.** En macOS existe un binario homónimo que **devuelve error incluso
  con el checksum correcto**: nunca acredita. Usar `shasum -a 256 --check`.
- **JSON canónico ≠ fichero.** Un compromiso calculado como `sha256(canonical_json(x))` no coincide
  con `sha256sum fichero.json`: sin espacios, claves ordenadas, sin salto final.
- **Identidad de BD que incluye `current_user`.** Un compromiso así debe calcularse **con el mismo
  DSN** que lo va a verificar; con otro rol no casa aunque la base sea la misma.
- **Un monitor vivo queda congelado** en la versión del script con la que se armó. Editar el fichero
  no arregla el proceso: hay que rearmarlo. Comparar `ps -o lstart=` con el `mtime`.
- **Un canal de detección con falsos positivos permanentes acaba ignorándose.** Si el cierre de un
  ítem vive en otro sitio, el detector lo marcará pendiente para siempre.
- **Referencias que dejan de coincidir.** Un `ref` de ventana y el hash del fichero que la representa
  divergen en cuanto se sobrescribe el fichero. Nombrar dos campos distintos.
- **Buckets de almacenamiento compartidos** entre producción y staging: un documento «de staging»
  puede ser de un cliente real.
- **Conteos que bajan no son pérdida** si existe una tabla de archivo.

---

## 6. La pregunta que ahorra más tiempo del plan siguiente

> **¿Qué acción de este plan es irreversible, y qué la precede inmediatamente?**

En S1 la respuesta era «cuatro envíos de WhatsApp a una persona», y lo que los precedía era un paso
de UI que resultó romper la acreditación. Haber hecho esa pregunta el primer día habría llevado a
mirar cómo se dispara una ejecución **antes** de escribir el método en el contrato.

Todo lo irreversible merece un punto de parada verificable inmediatamente antes, y **ese punto debe
poder fallar**. Un guard que nadie ha visto denegar no es un guard.

---

## 7. Cómo usar este documento

Al abrir la próxima migración a staging:

1. responder la tabla del §1 **en vivo** y escribir el inventario;
2. identificar lo irreversible (§6) y su punto de parada;
3. repasar el §5 antes de redactar cualquier bloque de comandos;
4. fijar desde el inicio quién ejecuta y quién verifica (§4), que no sean el mismo;
5. y solo entonces congelar el contrato.

Si el §1 se responde antes del freeze, la mayor parte de las idas y venidas de S1 no ocurren.
