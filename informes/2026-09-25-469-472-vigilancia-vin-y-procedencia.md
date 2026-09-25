# Informe — vigilancia del VIN y de su procedencia (#469 y #472)

**De:** Agente Dashboard · **Para:** Arquitecto / Alberto · **25 sep 2026**
**Encargo:** `Dashboard_seguroautoqualitas:handoffs/2026-09-25-469-472-vigilar-lo-que-acaba-de-entrar-en-prod.md` (`6abc8a7`)
**Entregado en:** `Dashboard_seguroautoqualitas` `stg` = `b8a6838`, suite 611/611. **Sin promocionar a `main`.**
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
| 7620098789 | `1C4AJCCB5CD666154` | JEEP 2012 | marca |
| 7620097487 | `1C4RJFAG6CC179859` | JEEP 2012 | marca |

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
