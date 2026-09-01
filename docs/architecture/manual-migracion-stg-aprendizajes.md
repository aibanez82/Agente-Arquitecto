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

### Resuelto el 10 ago por la noche — y la lección es de una palabra: **parcial**

Arreglado, y con la solución estructural en vez de la cómoda: **de lista negra recursiva a lista blanca
de nivel superior** (`name`, `active`, `nodes`, `connections`, `settings`). Como `nodes` entra entero, un
`description` **dentro** de un nodo da drift y el del workflow no se mira. **La distinción que hacía
falta era de profundidad, y una lista negra recursiva no puede hacerla** — por eso afinar la lista nunca
iba a bastar. 17 canarios en las dos direcciones, `main` como copia canónica, y verificado en vivo:
`10 destinos, 0 drift`.

**Mi aviso era correcto y estaba mal formulado, y el matiz es el aprendizaje.** Escribí que el arreglo
obvio nos dejaría «ciegos en el campo que gobierna el comportamiento del bot». Medido contra el bot real:
**11 nodos llevan la descripción de herramienta dentro de `parameters` y solo uno usa literalmente la
clave `description`; los otros diez usan `toolDescription`.** Así que no habría apagado el detector
—apagarlo se nota— sino dejado **un punto ciego del 9 %**: diez herramientas vigiladas y una a oscuras.

> **Un fallo parcial es peor que uno total, porque el total hace ruido y el parcial no.** Al evaluar un
> arreglo, la pregunta no es «¿rompe algo?» sino «¿qué fracción deja de vigilar, y se notaría?». Y la
> forma de contestarla no es leer el filtro: es **contar los casos reales en el artefacto** — aquí,
> cuántos nodos usan cada nombre de clave.

Dos cosas más que dejó, ambas de método:

- **La cifra que publiqué del alcance también estaba mal, y por debajo.** Dije «veinte ramas con dos
  versiones» de la tabla de destinos; eran **26 y cuatro**, con 19 apuntando al retrato pre-A2. Un
  «vive en varias ramas» sin contarlas es una estimación disfrazada de dato.
- **Un fail-first se puede verificar sin fiarse de quien lo reporta:** reconstruir la implementación
  anterior y correr los tests de hoy contra ella. Lo hice, y de paso salió una discrepancia numérica
  (5 y 4 fallos frente a los 3 declarados) que se explica por qué se tome como «versión anterior».
  Cuesta diez minutos y convierte «dice que falla antes» en «he visto fallar antes».

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

### 2.7 bis Una batería offline prueba la lógica, no que el dato llegue (29 ago 2026)

El `#254` cambiaba cuándo sube el contador que banea a un cliente. El gate decide leyendo el texto
del cliente (`chatInput`): si el tema es del dominio —precio, póliza, cobertura, identidad— no cuenta.
La batería offline le inyectaba al nodo un objeto **con `chatInput` dentro** y daba 19/19.

**Lo que esa batería no puede ver, por construcción, es si `chatInput` llega ahí en el grafo real.**
Y el modo de fallo es peor que un error: con `chatInput` ausente, el texto queda vacío, **nada encaja
nunca en la exención**, todo sigue contando y el arreglo es un **no-op perfecto** — suite en verde,
informe correcto, cliente baneado exactamente igual que antes. Nadie lo notaría hasta que se quejara
un cliente, y entonces el issue estaría cerrado hace semanas.

Se comprobó en el grafo, y llegaba: `Parse Router Output` devuelve `{...sessionCtx, routedIntent}` y
entre él y el gate solo hay nodos `IF`, que pasan el ítem intacto. **Pero eso es una propiedad del
cableado, no del código**, y por tanto no la acredita ninguna prueba unitaria del nodo.

**Regla:** cuando un nodo decide leyendo un campo del ítem que recibe, la verificación tiene dos
mitades y **la batería solo cubre una**:

1. **la lógica** — dado el campo, ¿decide bien? → batería offline;
2. **la llegada** — ¿ese campo está realmente en el ítem que entra a ese nodo, en el grafo vivo? →
   se traza el camino hacia arriba hasta el nodo que lo construye, mirando qué devuelve cada eslabón
   intermedio (§ «Colgar de X»: `postgres` y `code` devuelven lo suyo, los `IF` pasan el ítem).

Es la misma familia del §2.7 y de la trampa del `#41`: **la mitad que nadie prueba es la que decide
en producción.** Y conviene repartirla: la mitad 1 la acredita quien ejecuta, la mitad 2 quien
verifica — son dos preguntas distintas y se contestan con instrumentos distintos.

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

### 2.10 Un filtro cambia de significado según dónde se ponga (30 ago 2026)

El `#195` pedía una cosa razonable: **no ofrecer descuentos sobre una cotización que ya tiene póliza**.
Se implementó como un predicado SQL —`n8n_cotizacion_sin_poliza(quotation_id)`— y se colocó en el
`WHERE` del nodo que **resuelve la sesión**, es decir, el que decide **con quién estamos hablando**.

Ahí el predicado dejó de decir «no ofrezcas descuento» y pasó a decir **«emitir termina la
conversación»**: en cuanto se emitía la póliza, la sesión del cliente **dejaba de ser candidata para
su propio dueño**. El cliente pedía la liga de pago un minuto después de emitir y recibía una lista de
cotizaciones ajenas, sin salida posible.

**Nada de esto daba error.** La ejecución terminaba en `success`, el resolvedor encontraba filas
—las viejas— y el cliente simplemente se iba.

**Y el agravante que solo se ve al arreglarlo:** al ir a mover el predicado a «su sitio», resultó que
**su sitio estaba vacío**. Django no comprueba la póliza en el carril de descuentos —verificado en
`_availability` y `_chain_context`—, así que ese filtro mal colocado era **el único guard que
existía**. Quitarlo sin más habría arreglado el cobro y reabierto el agujero.

**Reglas:**

- **Una regla de negocio se escribe donde se llama como ella.** Un guard de descuentos vive en el
  carril de descuentos. En la resolución de identidad, el mismo predicado significa otra cosa —más
  grande— y nadie lo lee ahí cuando busca por qué se ofrecen o no descuentos.
- **Antes de mover un guard, comprobar que su destino no está vacío.** El comentario del código decía
  «el predicado es la fuente única del `#195`»: era verdad literal y había que creerlo.
- **Y al relajar un filtro, exigir el valor autoritativo en positivo.** Aquí la tentación era usar la
  copia local (`sessionRow.policy_data`); si llega vacía, la guarda pasa — fail-open. Se expuso el
  predicado como columna calculada en la misma consulta y se exigió `=== true`.

### 2.11 Prohibir un texto nombrándolo es enseñárselo (30 ago 2026)

El agente decía a los clientes «tu cotización ya está al mejor precio disponible», una promesa
comercial que no podemos respaldar. Se corrigió el prompt con una prohibición explícita:

> «NUNCA afirmes que su cotización «ya está al mejor precio disponible» — es una promesa comercial que
> no podemos respaldar.»

**Y el bot la siguió diciendo.** En sesión limpia, verificado en la base: la frase aparecía **una sola
vez en todo el historial de esa conversación, y era esa misma respuesta**. No hubo memoria
contaminada —esa fue la primera hipótesis y era falsa—.

**La prohibición falla por su forma:** deja la frase escrita, literal, en el sitio exacto del prompt
donde el modelo busca qué contestar a esa pregunta. Es el mismo mecanismo por el que decirle a alguien
«no pienses en un elefante» no funciona.

**Reglas:**

- **Prescribir, no prohibir.** Dar la frase que debe decirse en vez de nombrar la que no. Si hace
  falta prohibir, describir la clase («no afirmes superioridad de precio») sin citar el texto.
- **Una pregunta con una sola respuesta correcta no se le pregunta al modelo.** Se contesta con copy
  determinista antes de llegar a él — es lo que ya funciona para «¿eres un robot?».
- **Y al medir si una regla de prompt funcionó, comprobar primero si el historial de esa conversación
  ya contenía el texto**: la memoria del modelo pesa más que la regla, y confundir las dos causas
  lleva a arreglar lo que no era.

### 2.12 Una aceptación escrita por quien redactó la regla no la puede refutar (30-31 ago 2026)

En dos días, **la misma regla de prompt produjo dos afirmaciones falsas en producción**, y las dos
**pasaron una tabla de aceptación que yo mismo había escrito**.

| Redacción | Lo que hizo decir al bot | Quién lo destapó |
|---|---|---|
| 1ª (`#249`) | «Amplia o Limitada traen **exactamente las mismas coberturas**» | Alberto, preguntando **«¿cubre lo mismo?»** |
| 2ª (`#265`) | «El descuento es sobre la Amplia, **no sobre Limitada**» | **un cliente real**, preguntando «en cobertura limitada ¿también tienes descuento?» |

Las dos aceptaciones preguntaban «**¿el descuento trae la misma cobertura?**» —la formulación de quien
escribió la regla— y con esa frase el bot respondía bien. **Ninguna de las dos falsedades era
alcanzable desde el guion.**

**La causa no fue el modelo:** las dos veces obedeció una frase mía que mezclaba en una sola oración
**qué cubre un paquete** y **a qué precio**. El modelo elegía una lectura u otra según cómo se le
preguntara.

**Reglas:**

- **Quien redacta la regla no puede escribir solo él su aceptación.** Comparte el punto ciego: prueba
  la lectura que tenía en la cabeza, que es justamente la que no falla.
- **Las frases de prueba se toman de conversaciones reales**, con las palabras y la ortografía de la
  gente. Las dos que destaparon esto —«cubre lo mismo?» y «en limitada también tienes descuento?»— no
  se le habrían ocurrido a nadie en un despacho.
- **En un cambio de prompt, el verde estructural no es la validación.** Un diff medido y un `sha256`
  acreditan que **el texto quedó como se quería**, no que **el modelo diga la verdad**. Lo segundo
  solo lo acredita una conversación.
- **Un hecho por frase.** Si una regla afirma dos cosas —un precio y una cobertura, un estado y una
  causa—, sepáralas en oraciones distintas. La vecindad basta para que se mezclen.
- **Y antes de dictar un hecho de negocio, medirlo.** La segunda falsedad nació de deducir que el
  descuento «era de un paquete». Bastaba mirar el XML de cuatro cadenas para ver que **baja también la
  Limitada**; cuando por fin lo medí, la regla se escribió sola.

### 2.13 Para un empalme, la evidencia son las aristas, no los parámetros (31 ago 2026)

Toda la semana hemos verificado cada import del grafo n8n igual: **diff de `parameters` nodo a nodo**
contra el respaldo. Funciona para cambios de contenido —una regla del prompt, una SQL, un copy— y es
lo que ha cazado varios descuadres.

**Y es ciego a un recableado.** Al meter la guarda de «una sola oferta viva», el cambio consistió en
llevar `IF Create Discount Offer?[0]` a un nodo nuevo en vez de a `Create Discount Offer`. **Ese nodo
no cambió ni un parámetro**: cambió una **conexión**, y las conexiones viven en `workflow.connections`,
no en `node.parameters`.

Resultado: la comprobación del ejecutor esperaba ver ese nodo en la lista de «parámetros cambiados»,
no lo vio, y **paró creyendo que el import había fallado**. El import estaba perfecto; **la aserción
estaba mal puesta**.

**Reglas:**

- **Un paquete que reconecta se verifica en dos planos:** `parameters` para el contenido —donde el
  conjunto esperado puede ser legítimamente **vacío**— y `connections` para el empalme.
- **Al dictar un encargo que empalma, pedir la evidencia del cableado explícitamente**, nodo origen y
  nodo destino con su índice de rama. Si solo se pide «diff contra el respaldo», se está pidiendo la
  mitad.
- **Y el punto ciego es compartido:** las dos sesiones —ejecutor y arquitecto— verificábamos igual, así
  que ninguna de las dos habría detectado un empalme mal hecho por el mismo camino. Cuando dos
  verificadores usan el mismo instrumento, **no son dos verificaciones**.

*(Corolario del `#260` y del «colgar de X» del §2.10: los tres son fallos del mismo plano — lo que un
nodo hace se lee en sus parámetros; **dónde está enchufado, no**.)*

### 2.14 En una prueba, el destino del mensaje no lo elige quien lo escribe (31 ago 2026)

Ordené inyectar dos mensajes «en la sesión `waq_2314`». **No era posible**, y ni el ejecutor ni yo lo
habríamos sabido sin mirar el código de resolución: con varias sesiones abiertas en un teléfono,
`Session Resolution` toma la **única `active`** como respuesta autoritativa —
`if (active.length === 1) { sessionRow = active[0] }` — y esa era otra. Los mensajes habrían aterrizado
justo en la conversación que **la misma orden prohibía tocar**.

**Escribir el mensaje no es elegir dónde cae.** Entre el texto y la sesión hay una resolución con
reglas propias, y esas reglas mandan. Una orden de prueba que nombra una sesión de destino está
asumiendo, sin decirlo, que existe una vía hasta ella.

Y el filo largo: **eso vuelve sospechosa toda acreditación pasada por el mismo camino**. Al revisar la
que ya daba por buena, el destino **sí** era el correcto — pero por coincidencia entre lo que pedí y lo
que el sistema elige, no porque yo lo hubiera controlado. Con dos `active`, el mismo mensaje se va a
otro sitio y el informe sale idéntico.

**Regla:** en un entorno con sesiones múltiples, la prueba **declara la sesión que resolvió**, leída de
la ejecución — no la que pretendía. Y si el escenario no es alcanzable por la vía normal, **clonar su
FORMA** (mismos datos, misma fase, teléfono sintético) es válido cuando la guarda bajo prueba decide
con datos de la sesión del turno: no se simula el escenario, se pone la misma entrada en la misma
puerta.

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
- **Texto libre por `queryReplacement` del nodo Postgres de n8n = corrupción silenciosa de
  parámetros.** Desde `typeVersion` 2.5, cada expresión que no resuelva a array pasa por
  `isJSON(v) ? [v] : stringToArray(v)`: **el texto no-JSON se parte por comas**. Una copia con dos
  comas se convierte en tres parámetros y corre todo lo que venga detrás. No da error — la validación
  del destino rechaza datos que ya llegaron corridos, y el diagnóstico apunta al sitio equivocado.
  **Forma segura: `={{ [v1, …, vN] }}`**, con cada elemento entre paréntesis (sin ellos, un `||` o un
  `??` dentro de un elemento se come la coma separadora y reproduce el fallo con otra sintaxis). O
  `JSON.stringify`, que pasa por `isJSON` y viaja entero. **Al convertir, verificar el cuadre
  `$N` ↔ número de elementos**: un array con un elemento de más o de menos no arregla nada, rompe
  distinto. Encontrado el 28 ago 2026 (`HYL-WAI#239`) por el Agente n8n, instrumentando la BD para
  capturar lo que n8n bindaba de verdad — el `runData` de n8n **no guarda los parámetros resueltos**
  del nodo Postgres, así que desde la ejecución el fallo es invisible.
- **El disparador de ese fallo es contenido, no código.** La copia vivía en Wagtail: la escribe una
  persona de negocio, sin revisión de código y sin despliegue. El programa que funcionaba desde julio
  tenía **cero comas** y el nuevo **dos**. Un sistema donde una coma en un CMS tumba un carril de
  producción no tiene un bug: tiene una **frontera de confianza mal puesta**. Y en los nodos que
  guardan datos del cliente (`Save Group1/2/3 Progress`, `Save Policy Data`) el que escribe la coma no
  es ni siquiera una persona: **es el modelo**, cualquier día, en un domicilio.

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

## «Colgar de X» no es «ponerlo después de X» (29 ago 2026)

Dicté que un nodo nuevo se pusiera «**justo después** de `Settle Discount Availability`, punto común
a todo resultado». El ejecutor lo puso **en serie**, que es lo que la frase pedía. Y con eso rompió
el carril de descuentos entero: el nodo era `postgres`, devolvía el resultado de su `UPDATE`
—`{"marca":"false"}`— en vez del ítem que venía, y el `IF Create Discount Offer?` siguiente evaluaba
`$json.crear_oferta === true` sobre un objeto que ya no tenía ese campo. **`undefined === true` es
`false`, así que ninguna oferta de descuento se creó** hasta que se detectó.

**No dio error.** Ni excepción, ni ejecución roja, ni aviso: el `IF` simplemente decidía «no» siempre,
y el turno caía al carril normal donde el agente improvisaba argumentario de venta. Lo encontró
Alberto probando, no la estructura.

**La regla, para las dos manos:**

- **Instrumentación y efectos laterales van COLGANDO** —rama paralela, sin salida—, nunca
  intercalados. Es lo que se hizo bien el mismo día con el detector de Limitada, colgado de
  `Restore Main Reply Payload`.
- **Solo rompen en serie los nodos que devuelven algo distinto**: `postgres` devuelve su consulta,
  `code` lo que retorne. **Los `IF` pasan el ítem intacto**, así que intercalarlos es inocuo — por eso
  `IF No Discount Available?`, en la línea principal, no rompía nada.
- Y al dictar: **decir «colgando de X» cuando se quiere una rama lateral.** «Después de X» significa
  en serie, y en un nodo que transforma, en serie significa cortar el dato.
