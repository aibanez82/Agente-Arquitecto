# Informe — vigilancia del VIN y de su procedencia (#469 y #472)

**De:** Agente Dashboard · **Para:** Arquitecto / Alberto · **25 sep 2026**
**Encargo:** `Dashboard_seguroautoqualitas:handoffs/2026-09-25-469-472-vigilar-lo-que-acaba-de-entrar-en-prod.md` (`6abc8a7`)
**Entregado en:** `Dashboard_seguroautoqualitas` `stg` = `b8a6838`, suite 611/611. **Sin promocionar a `main`.**
> [!WARNING]
> **Corregido el 25 sep 2026, después de publicar.** Dos de las seis pólizas que señalé eran
> **falsos positivos míos**: `1C4` no es exclusivo de Dodge, cubre todo el grupo Chrysler, y acusé a
> dos Jeep reales. **El censo queda en 4, y las cuatro fallan el dígito verificador.** Ver
> «Corrección» al final. Las tablas de abajo conservan la versión errónea, tachada donde toca.

**Ámbito:** todo lo de abajo medido contra **PROD** hoy, con el instrumento que se entrega. Solo lectura.

---

## Lo que se entrega, y por qué es repetible

Un endpoint, `GET /api/alertas/vin-polizas`, que responde a las dos preguntas del encargo y a
ninguna más. Lee **PROD siempre**, también desplegado en `stg`, con `queryProd`
(`CONCILIACION_DATABASE_URL`), igual que Conciliación. Cero escrituras.

- `apps/operacion/lib/s1/vinSenales.js` — las señales de un VIN. La aritmética vive aquí y **no en
  SQL**, para que haya una sola verdad probada contra VIN de referencia.
- `apps/operacion/lib/s1/vinVigilancia.js` — el censo y la distribución de procedencias.
- 33 pruebas nuevas.

**Rol:** `admin` o `hylantt`. **`agente` NO puede pedirla** —lista pólizas— y hay un test que lo fija.

### El control, que va primero y viaja en la respuesta

Pediste que el comprobador se enfrentara a un VIN bueno y a uno malo conocidos. Se ejecuta en cada
llamada y su veredicto sale en el JSON:

| | VIN | veredicto |
|---|---|---|
| bueno | `3N1AB7AD5HL617551` (NISSAN 2017, leído de la tarjeta) | no merece revisión ✅ |
| malo | `3N1AB7AP7EL609642` (póliza 7620103198) | merece revisión, por dígito ✅ |

**`control_del_comprobador.sano = true`** y **`censo_fiable = true`** en la medición de abajo. Si
alguna vez sale `false`, el recuento que lo acompaña no significa nada y la respuesta lo dice sin
que haya que deducirlo.

---

## 1 · El censo (`#469`)

Medido hoy contra PROD:

| | |
|---|---|
| pólizas con VIN de 17 caracteres | **67** |
| descartadas por ser de prueba | **24** |
| reales | **43** |
| limpias | **37** |
| **merecen revisión** | **6** |
| de ellas, fallan el dígito verificador | **4** |
| de ellas, **pagadas** | **1** |

### Las seis

| póliza | VIN | vehículo | señales |
|---|---|---|---|
| **7620103198** | `3N1AB7AP7EL609642` | RENAULT 2012 · **PAGADA** | dígito, año, marca |
| 7620099709 | `MEX5A2669L1974968` | VOLKSWAGEN 2020 | dígito |
| 7620099526 | `3N1AB7AP8EY708126` | NISSAN 2008 | dígito, año |
| 7620098914 | `MB2C22AC6LM856961` | HYUNDAI 2020 | dígito |
| ~~7620098789~~ | ~~`1C4AJCCB5CD666154`~~ | ~~JEEP 2012~~ | ~~marca~~ · **FALSO POSITIVO** |
| ~~7620097487~~ | ~~`1C4RJFAG6CC179859`~~ | ~~JEEP 2012~~ | ~~marca~~ · **FALSO POSITIVO** |

Dos merecen una mirada aparte por su forma, no por su aritmética: **`MEX5A2669L1974968`** y
**`MB2C22AC6LM856961`**. Tienen 17 caracteres y pasan el formato, pero empiezan por `MEX` y `MB2`,
que no son WMI de ningún fabricante conocido. Parecen **marcadores de captura**, no VIN. No lo
afirmo: lo señalo porque un VIN inventado con forma correcta es peor que uno ausente.

### Tu censo dio 14 y el mío 6. No nos contradecimos: medimos cosas distintas

La población coincide **exacta** —67 pólizas con VIN de 17—, así que toda la diferencia está en dos
criterios, y los dos son defendibles:

1. **A quién llamamos lead de prueba.** Yo uso `esLeadInterno`, la puerta única del Dashboard (17
   correos + 14 teléfonos), y descarta **24**; tú descartaste 8.
2. **Cuántas señales miramos.** Tú usaste dígito verificador y WMI; yo añado el **año** (posición 10
   contra el año de la cotización).

Para que esto se pueda cerrar sin adivinar, la respuesta publica los dos números que faltaban:
**`descartadas_con_señales = 22`** y **`señaladas_sin_excluir_nada = 28`**.

Con eso: 22 de las 24 que descarto habrían señalado. Es un 92 %, coherente con que sean pruebas con
VIN fabricados — pero también es la cifra que hay que mirar si alguien sospecha que mi exclusión se
está llevando pólizas reales por delante. **No he verificado una por una esas 24.**

### Las tres reglas, respetadas en el código y no solo en el informe

- **Una señal no es una condena.** El campo se llama `merece_revision`. En ningún sitio se dice
  «inválido».
- **Es un suelo, no un techo.** Un WMI fuera de la tabla devuelve `null`, nunca `false`. El catálogo
  es corto a propósito: añadir un WMI dudoso convierte un inconcluso en un falso positivo.
- **El dígito verificador es cerrado**, y por eso se cuenta **aparte** (`fallan_digito`): es la única
  señal que no se degrada cuando el catálogo envejece.

---

## 2 · La procedencia del VIN (`#472`)

| | |
|---|---|
| `tecleada` / `foto_confirmada` / `descuento` / `rechazada_sin_procedencia` | **0 / 0 / 0 / 0** |
| sesiones con `serie_source` escrito, cualquier valor | **0** |
| sesiones con `grupo2` | **70** |
| sesiones con `grupo2.serie` | **70** |
| **`cero_interpretable`** | **false** |

**Ese cero no mide nada todavía, y el instrumento lo dice solo.** Hay 70 sesiones que ya guardaron
un VIN y **ninguna** lleva sello: la columna nació hoy y aún no ha pasado tráfico por el gate. Un
cero de una población vacía no distingue «no hubo nada que rechazar» de «esa columna no se escribe
nunca», que es exactamente tu aviso.

**Remedición comprometida: 2 de octubre de 2026.** Lo que habrá que mirar ese día, en este orden:

1. **¿`sesiones_con_sello` ha crecido?** Si sigue en 0 con tráfico real, el problema no es el gate:
   es que el sello no se escribe, y ahí hay que mirar antes de interpretar nada.
2. Solo entonces, el reparto de los cuatro valores y el de rechazos.

### Las dos causas ya vienen separadas

Tu aviso de esta tarde llegó antes de que estuviera montado, así que está dentro desde el principio:
`rechazada_sin_procedencia` se reparte en **`modelo_sin_procedencia`** (el que se vigila) y
**`cliente_contradice_su_coche`**, según `captured_data->'serie_tecleada_blocked'`. Hoy ese campo no
existe, así que el 100 % cae en la primera y los números no cambian; el día que aterrice, **la serie
vigilada sigue siendo comparable** en vez de dar un salto. Y los motivos concretos
(`anio_contradice_cotizacion` y los demás) se cuentan **uno a uno**, sin fundirlos.

---

## Lo que esto no cubre

- **El censo es un suelo.** Con un catálogo de WMI corto, «28 sin excluir nada» es *al menos*, nunca
  *solo*.
- **No he mirado las 24 descartadas una por una.** Si alguna fuera real, sería una póliza señalada
  que no estoy contando.
- **La procedencia se mide sobre la sesión viva y la archivada.** Decisión mía: una sesión archivada
  por recotización se lleva su `captured_data`, y un rechazo que quedara solo ahí desaparecería del
  recuento sin que nadie lo notara.
- **Ni un correo ni un teléfono viajan** en la respuesta. La póliza y el vehículo bastan.

## Pendiente de Alberto

El endpoint está en `stg` y **no se ha promocionado a `main`**. Desde `stg` ya lee PROD, así que la
vigilancia es utilizable hoy; promocionarlo solo la pone al alcance de quien entre por el dominio de
producción.

— Agente Dashboard

---

## Corrección — 25 sep 2026, después de publicar

**Dos de las seis eran falsos positivos míos.** Lo cazó el Arquitecto.

Mi tabla tenía **`'1C4': 'DODGE'`**, y `1C4` no es exclusivo de Dodge: cubre todo el grupo Chrysler.
Las dos pólizas que señalé por marca son Jeep reales —`1C4RJFAG…` patrón de Grand Cherokee,
`1C4AJCCB…` de Patriot/Compass—, así que **acusé a dos clientes de un error que no cometieron**.

El argumento que lo cierra no es saber de coches: para que mi catálogo tuviera razón harían falta
**dos clientes distintos** que hubieran puesto por su cuenta un VIN de Dodge en una cotización de
Jeep. Dos errores idénticos y coincidentes son mucho menos probables que una entrada de catálogo
demasiado estrecha.

Y es exactamente lo que advertía el comentario de mi propio fichero: *«añadir un WMI dudoso convierte
un `inconclusive` en un falso positivo, que es peor que no señalar»*. **La regla estaba bien; la
entrada no.**

**No se arregla ampliando.** Reasignar `1C4` a Jeep acusaría a los Dodge. Un prefijo compartido por
varias marcas del mismo grupo **deja de opinar**: devuelve `inconclusive`, igual que uno desconocido.
Hay un test que impide reasignarlo, porque «arreglarlo» así es justo lo que alguien intentaría.

Del mismo defecto salieron otros: `LSG` lo tenía como MG y es SAIC-GM (Chevrolet, Buick); `KL1` es
GM Corea; `JS2`, `JSA` y `MA3` son Suzuki rebadged como Chevrolet en varios mercados. Todos pasan a
compartidos.

### El censo corregido (`stg` = `c1b46c1`, medido contra PROD)

| | antes | **ahora** |
|---|---|---|
| reales | 43 | 43 |
| limpias | 37 | **39** |
| **merecen revisión** | 6 | **4** |
| de ellas, fallan el dígito | 4 | **4** |
| pagadas | 1 | **1** |
| señaladas sin excluir nada | 28 | **26** |

| póliza | VIN | vehículo | señales |
|---|---|---|---|
| **7620103198** | `3N1AB7AP7EL609642` | RENAULT 2012 · **PAGADA** | dígito, año, marca |
| 7620099709 | `MEX5A2669L1974968` | VOLKSWAGEN 2020 | dígito |
| 7620099526 | `3N1AB7AP8EY708126` | NISSAN 2008 | dígito, año |
| 7620098914 | `MB2C22AC6LM856961` | HYUNDAI 2020 | dígito |

**Las cuatro fallan el dígito verificador**, que es la única señal que no depende de ningún catálogo.
El censo es más corto y más firme que el de antes.

**Lo que me llevo, más allá de las dos pólizas:** una señal basada en un catálogo hereda los errores
del catálogo, y los hereda **en la dirección que acusa**. El dígito verificador no tiene ese defecto.
Por eso se contaba aparte desde el principio, y por eso ahora es el que sostiene el resultado entero.

— Agente Dashboard

---

## Cierre de la reconciliación — 25 sep 2026

**Los dos censos coinciden ahora exactamente.** El Arquitecto comprobó contra `esLeadInterno` las
cuatro pólizas que su lista tenía y la mía no, y **las cuatro son internas**: dos casan por correo y
dos por teléfono —el mismo teléfono en dos de ellas—. Su lista queda en **3 pendientes**, que con la
pagada son **las 4** de este informe. Ya no hay dos cifras que reconciliar.

Con eso se cierra la única incógnita que dejé abierta arriba: **las 24 que descarto como prueba no
estaban escondiendo clientes reales**, al menos en las cuatro que se pudieron contrastar. La
alternativa que planteé —que mi filtro estuviera ocultando leads de verdad en el embudo entero— queda
descartada para esos casos, y era la que importaba.

Y la señal del **año** resultó ser la que lo delataba sin necesidad de consultar ninguna lista: 2005,
2027, 2004 y 2008 contra cotizaciones de 2025, 2018, 2016 y 2024. No son desviaciones de un carácter
mal leído; son VIN que no tienen nada que ver con el coche, que es la firma de una emisión de prueba
con un número inventado a mano. Esa señal no estaba en el encargo: la añadí y es la que resolvió el
empate.

**Lo que no cambia:** el censo sigue siendo un **suelo**. Que las cuatro contrastadas fueran internas
no acredita que las otras veinte lo sean.

---

## Qué protege PROD hoy, y el hueco que este contador NO ve — 26 sep 2026

Medido por el Arquitecto contra el grafo vivo (`149be760`) a petición mía, porque un commit decía
«el `#469` no queda funcional en PROD» y eso contradecía lo reportado. La frase era **demasiado
ancha**: hay tres caminos y solo uno está protegido.

| Camino | En PROD hoy |
|---|---|
| **Foto** | **protegido** — `Parse VIN Extraction` calcula `vinValid` (formato + dígito + año + WMI) y `IF Foto VIN Valid?` no persiste si falla. Y en cascada: sin `serie_foto` no hay nada que promover a `confirmado`, y `Save Group2 Progress` solo se fía de la foto cuando está `confirmado`. **Dos barreras independientes.** |
| **Tecleado** | **sin proteger** — `Check Typed VIN` no existe en PROD. No hay ninguna aritmética. |
| **Aviso al cliente** | inerte — el generador del marcador no está. |

**El caso de la póliza 7620103198 no puede repetirse por el camino de la foto.**

### Y esto es lo que hay que saber antes de leer mi contador el 2 de octubre

**Un VIN tecleado que falle el dígito verificador se persiste hoy como `tecleada`, y el gate lo
acepta como procedencia buena.** No aparecerá en `rechazada_sin_procedencia` — no porque no exista,
sino **porque nadie lo está comprobando**.

O sea que `rechazada_sin_procedencia` mide *«el modelo pasó un VIN de ningún sitio»* y *«la foto no
se sostiene»*, pero **no** *«el cliente tecleó un número que no cuadra»*. Ese hueco lo cierra el
`#475`. Un cero ahí no significa «no hay VIN malos»: significa «no hay VIN malos **por los caminos
que se miran**».

Es la misma trampa que `cero_interpretable`, un escalón más arriba: el contador no puede declarar lo
que nadie le pidió medir, así que queda declarado aquí.

---

## El punto ciego del camino tecleado, medido — 26 sep 2026

La nota de arriba decía que un VIN tecleado que falle **no aparecería en ningún recuento**. Con el
viaje de hoy (`98edabbe`, 346 nodos) eso deja de ser verdad, y la vigilancia lo recoge:
`Check Typed VIN` escribe `captured_data->'serie_tecleada_checks'`, así que **hay dato aunque no
haya bloqueo**.

`GET /api/alertas/vin-polizas` publica ahora `vin_tecleado` (`stg` = `328c0b2`, suite 619/619):

| campo | hoy en PROD |
|---|---|
| `comprobados` | **0** |
| `falla_digito` / `falla_anio` / `falla_wmi` | 0 / 0 / 0 |
| `bloquearia_2de3` | 0 |
| `solo_wmi_sin_nada_mas` | 0 |
| `cero_interpretable` | **false** |

Cero porque nadie ha tecleado un VIN desde que el nodo entró hace minutos, y **el instrumento lo
declara** en vez de enseñar un verde.

**Tres cosas que quedan fijadas en el código y no solo aquí:**

1. **Esto no son rechazos.** El modo es solo-avisa: un VIN tecleado que no cuadra **se guarda
   igual**. `bloquearia_2de3` es calibración —lo que se habría bloqueado—, no una decisión tomada.
2. **`serie_tecleada` se escribe siempre**, cuadre o no. Su presencia ya **no** implica un VIN
   válido; quien lea ese campo dentro de seis meses necesita saberlo.
3. **Un `wmiCheck: fail` a solas es raro** y se cuenta aparte. De los 54 VIN de PROD medidos por el
   Arquitecto, los 9 que fallan WMI fallan **además** el dígito o el año. Uno solo merece mirarse en
   vez de darse por normal.

Y el marcador `serie_tecleada_blocked` **sigue sin escribirse**, por diseño: el desempate entre las
dos causas de `rechazada_sin_procedencia` queda inerte y su cero es el esperado. No es una avería.

---

## Los tres ceros del 2 de octubre, y el control positivo — 26 sep 2026

`stg` = `fba60f9`, suite 625/625. Medido contra PROD ahora:

| # | qué mide | valor | su denominador | ¿dice algo? |
|---|---|---|---|---|
| 1 | rechazos del carril **foto** | 0 | 0 sesiones con sello | **no** |
| 2 | VIN **tecleado** que no cuadra | 0 | 0 comprobados | **no** |
| 3 | **intentos** de serie sin comprobar | 0 | 0 sesiones con intento | **no** |

**Los tres se leen por separado y no se suman nunca.** Sumar ceros de caminos distintos produce un
cero que parece el doble de sólido y es el doble de ciego. Cada uno declara su propio estado:
*comprobado y bien*, *comprobado y roto*, o **no comprobable todavía** — que es donde están los tres
hoy, cada uno por su motivo.

### El nº 3 es el control positivo del nº 2, y hacía falta

`Detect Typed VIN` solo ve cadenas que **ya tienen 17 caracteres válidos**. Si el cliente escribe 15,
o 18, o mete una `O`, el detector no dispara y **no se escribe nada**. Así que el denominador del
nº 2 cuenta **«los que se comprobaron», no «los que intentaron escribir una serie»** — y la
diferencia entre esas dos poblaciones es justo el caso que más se parece a un error de tecleo.

**Si el nº 3 crece y el nº 2 no, el detector se está dejando fuera los errores de tecleo.** Esa es
la lectura que hay que hacer el 2 de octubre, y no «hay cero fallos».

**Es una heurística sobre texto libre y viaja declarada como tal** (`heuristica: true`). Validada
**antes** de conectarla, contra Postgres y no de palabra:

- sobre texto real de STG, **cero falsos positivos en 98 sesiones** con mensajes humanos: no casa
  con bloques `CTX`, ni teléfonos, ni nombres de vehículo;
- y contra ocho casos construidos, **8 de 8**: caza 16 caracteres, 18, un VIN con la `O` prohibida y
  uno dentro de una frase; **no** caza un VIN de 17 bien formado —a ese lo ve el detector—, ni un
  teléfono, ni texto normal, ni metadata.

Un cero que sale de un detector que no detecta nada se ve igual que un cero bueno. Por eso el
control del control va antes que la cifra.

Puede contar de más (un número de póliza largo, un RFC) y de menos (quien parta la serie en dos
mensajes). Acotado desde el **26 sep**, el día que el nodo entró: contar intentos anteriores
compararía dos mundos distintos.

### Ámbito de la medición de los 54, citado como toca

Cuando arriba se dice que *«de los 9 con `wmiCheck: fail`, los 9 fallan además el dígito o el año»*,
el ámbito es: **54 números de serie de 17 caracteres, medidos el 26 sep sobre
`captured_data->grupo2->serie` en PROD**, mezclando carril de foto y tecleado porque a esa fecha no
había forma de separarlos. **No es el universo de los tecleados**: es lo que había.
