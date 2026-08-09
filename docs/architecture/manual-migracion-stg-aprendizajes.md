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

### 2.5 Guardas que fallan abiertas

`[ -z "$(git status --porcelain)" ]` da éxito si el comando muere sin escribir nada: un fallo se lee
como «limpio». Hay que separar **el fallo del comando** del **resultado limpio**.

Y en la misma familia: `mkdirSync` sin modo hereda el umask, y `mkdirSync` **con** modo **no corrige
un directorio ya existente** — el arreglo obvio tampoco basta.

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
