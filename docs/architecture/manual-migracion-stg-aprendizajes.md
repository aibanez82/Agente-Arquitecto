# Manual de migración a STG — lo aprendido en S1, para que la próxima cueste días y no semanas

Escrito el 8-9 ago 2026, al final del primer carril Contract-First con acciones vivas en staging.
**No es una crónica: es lo que hay que hacer primero la próxima vez.** La crónica está en el tablero
y en `HYL-WAI#132`.

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

## 5. Catálogo de trampas técnicas concretas

Para consultar en frío, sin contexto:

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
