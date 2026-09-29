# Pólizas con VIN que no se sostiene — revisión manual de Alberto

**Decisión de Alberto, 25 sep 2026: las trece van por fuera.** No se abre issue operativo; el
`#469` se queda solo con lo técnico. Esta lista existe para que la revisión sobreviva a la sesión y
se pueda trabajar desde cualquier máquina — un censo que vive en un comentario de GitHub entre otros
quince no es una lista de trabajo.

**Fuente:** censo del Arquitecto sobre `qualitas_polizaemitida` cruzada con su cotización, BD de
PROD, VIN de 17 caracteres, medido el 25 sep 2026.
**Issue:** `aguayo-co/HYL-WAI#469` (`sistema:n8n`, `criticidad:critico`, `area:emision`).

---

> ⚠️ **Corrección del 26 sep 2026, antes de nada:** de las tres, **dos no eran «marcadores de
> captura»** como escribí aquí el 25 sep. Salieron de la lectura de la foto y su prefijo es legítimo.
> Y **ninguna de las tres se cobró nunca**. Detalle y medición más abajo. Si leíste la versión
> anterior, lo que sacaste de ella sobre estas dos no vale.

## La que ya lleva Alberto

| Póliza | Pago | VIN en la póliza | Vehículo cotizado | VIN real (de la foto) |
|---|---|---|---|---|
| **7620103198** | **PAGADO** | `3N1AB7AP7EL609642` | RENAULT STEPWAY 2012 | **`93YB62JB1CJ081818`** |

El VIN real se leyó de la propia tarjeta de circulación que viaja en la ejecución `58067`. Encaja en
todo: dígito verificador correcto, WMI `93Y` = Renault, posición 10 `C` = 2012. La titular está
avisada por otro canal.

## ⚠️ Corregido dos veces: eran trece, luego siete, **y son tres**

Esta lista ha encogido dos veces el mismo día y las dos por el mismo motivo: **filtré por el campo
equivocado.**

**Primera corrección (13 → 7).** Seis eran emisiones de prueba nuestras. Se colaron porque filtré
por el **VIN**, y el número de serie de una prueba puede parecer perfectamente normal.

**Segunda corrección (7 → 3).** Otras cuatro también eran pruebas. Se colaron porque filtré por el
**titular**, y miré si «parecía una persona real»: nombre corriente, correo de Gmail o Hotmail. Lo
son. **Son las cuentas personales de quienes prueban el sistema.** Dos están en la lista interna por
correo y dos por teléfono.

**La lección, que es la misma dos veces:** no se descarta una prueba por si el dato *parece* real, se
descarta contra **el registro de quién es interno**. El Dashboard tiene esa puerta única
(`esLeadInterno`, 17 correos y 14 teléfonos) y es la que manda. Yo estaba juzgando apariencias.

Y hay una confirmación independiente de que las cuatro eran pruebas: sus VIN codifican los años
**2005, 2027, 2004 y 2008** contra cotizaciones de **2025, 2018, 2016 y 2024**. No son desviaciones
de un carácter mal leído — son números que no tienen nada que ver con el coche.

## Las tres

Emitidas, sin cobrar, **clientes reales**. Y no son el mismo problema, así que van separadas.

### Una con un VIN que no cuadra

| Póliza | VIN emitido | Vehículo cotizado | Señal |
|---|---|---|---|
| 7620099526 | `3N1AB7AP8EY708126` | NISSAN APRIO 2008 | dígito verificador **y** año |

Dos señales independientes. Es el perfil de un VIN mal leído o mal tecleado.

### Y dos que ~~no parecen VIN~~ — ❌ **esto era falso. Corregido el 26 sep**

| Póliza | VIN emitido | Vehículo cotizado | Señal |
|---|---|---|---|
| 7620099709 | `MEX5A2669L1974968` | VW VENTO 2020 | dígito verificador |
| 7620098914 | `MB2C22AC6LM856961` | HYUNDAI CRETA 2020 | dígito verificador |

> **Lo que escribí el 25 sep y no se sostiene:** «`MEX` y `MB2` no son prefijo de ningún fabricante»
> y «parecen marcadores de captura colados donde va el número de serie». **Las dos afirmaciones son
> mías y las dos son falsas.** Lo dejo tachado arriba en vez de borrarlo, porque quien leyó la
> versión anterior salió con la idea de que había que buscar un bug de captura — y no hay tal.

**`MEX` es el WMI de Volkswagen de la India, y es el correcto.** Medido contra los propios datos de
PROD: `MEX` aparece **dos veces**, en dos tarjetas de circulación independientes, y las dos son
**VOLKSWAGEN** — un POLO 2015 y el VENTO 2020 de esta lista. Ni el Polo ni el Vento que se venden en
México se fabrican aquí: vienen de la planta india. Dos coches distintos, dos clientes distintos, el
mismo prefijo y la misma marca no es casualidad.

**`MB2` encaja igual, y lo dejo sin cerrar.** `M**` es el bloque de la India en la ISO 3779, y el
Creta que se vende en México también es de fabricación india. Pero esto lo he medido con **una sola
póliza**, y no tengo aquí el registro autoritativo de WMI asignados. **Es coherente, no está
acreditado** — y lo escribo así a propósito, porque la afirmación anterior sonaba igual de segura y
era mentira.

### De dónde salieron de verdad: de la foto

Las tres cadenas están en `n8n_chat_histories` y las tres entran por el mismo sitio, con este texto
literal:

```
[FOTO_VIN] El cliente adjuntó una foto de su tarjeta de circulación.
número de serie detectado: MEX5A2669L1974968.
```

O sea: **las escribió el paso de visión leyendo la tarjeta del cliente.** No las inventó el agente
conversacional y no las puso ningún marcador. El origen es la lectura de la imagen.

### El regalo que trae el VENTO: la misma tarjeta, leída dos veces

Esta es la pieza más útil de toda la lista. En la sesión `525549026018` la visión produjo **dos**
lecturas de la misma tarjeta:

| Lectura | Dígito verificador | Código de año | Qué pasó con ella |
|---|---|---|---|
| `MEX5A2609LT074968` | ✅ **cuadra** | ✅ `L` = 2020 | Quálitas la rechazó: «ya está registrada con otra póliza activa» |
| `MEX5A2669L1974968` | ❌ falla (esperaba `6`, escribió `9`) | ✅ `L` = 2020 | **es la que llevó la póliza** |

Tres caracteres de diferencia entre dos lecturas del mismo cartón. Y la que **sí** pasa la
aritmética es justamente la que Quálitas reconoce como ya existente — es decir, con toda
probabilidad **el VIN real de la clienta**, y la póliza se emitió con la corrupta.

Esto no es un fallo del modelo conversacional: es **deriva del paso de visión**, y se mide sola
porque tenemos las dos lecturas. Es el mejor caso de calibración que hay en el censo.

### Y lo que cambia la urgencia: **ninguna de las tres se cobró nunca**

| Póliza | `estatus_pago` | Recibos en la última observación válida | Pagados |
|---|---|---|---|
| 7620098914 | PENDIENTE | 2, **cancelados** | 0 |
| 7620099526 | PENDIENTE | 5, **4 cancelados** | 0 |
| 7620099709 | PENDIENTE | 2, **cancelados** | 0 |

Última observación válida de las tres: **4 sep 2026, 21:5x CDMX** (`snapshot_status =
valid_complete`). Cero pesos cobrados en las tres, y Quálitas ya había cancelado los recibos.

**El ámbito de esa medición, que importa:** esas tres están en el grupo de **40 de las 73** pólizas
cuyo último snapshot es el 4 sep CDMX; las otras 31 siguen observándose hasta el 25 sep. Así que ese
corte **no dice nada sobre estas tres en particular** y no acredita su estado de hoy — pero un
recibo cancelado no se descancela.

**Consecuencia para la revisión manual: no hay nadie a quien llamar.** No son clientes con una
póliza mala encima: son tres pólizas que murieron sin cobrar. Lo que queda no es atención al
cliente, es **dato de calibración** — y de los tres, el del VENTO es el que vale.

---

## Tres cosas que hay que saber antes de trabajar la lista

**1. Es un suelo, no un techo, y el suelo se midió sobre datos sucios.** La comparación de marca usa una tabla de WMI conocidos: si el WMI
de un VIN no está en esa tabla, **no se señala nada**. Puede haber más de trece. El número que sí es
cerrado es el del dígito verificador, que es aritmética y no depende de ninguna tabla.

**Y una advertencia que nació de equivocarme:** los datos de PROD **no distinguen lo real de lo de
prueba** (`HYL-WAI#346`). Cualquier censo sobre pólizas arrastra nuestras emisiones QA. **Cruzar
siempre con el asegurado y descartar por titular**, nunca por el aspecto del dato técnico.

**2. Una señal no es una condena.** El dígito verificador es obligatorio en EE. UU. y Canadá; en
vehículos de mercado mexicano se cumple casi siempre pero **no por norma**. Un VIN legítimo que no
cuadre existe. Lo que la señal acredita es que **merece mirarse**, no que esté mal. Los catorce
salen de 59 pólizas reales: los otros 45 pasan limpios.

**3. Dónde entra el VIN.** En todos estos casos `qualitas_cotizacion.serie_vehiculo` está **vacía**:
el VIN llega a la póliza sin pasar por la cotización. Por eso el primer censo, que miraba la
cotización, salió limpio y no acreditaba nada. Si alguien rehace este recuento, la tabla es
`qualitas_polizaemitida`.

---

## Qué NO cubre esta lista

Las pólizas ya emitidas. El agujero que las produjo se cierra en el `#469` (comprobaciones
aritméticas antes de dar un VIN por bueno) y en el `#472` (no persistir lo que el cliente no
confirmó, ya construido y en STG sin promover). **Mientras el `#472` no esté en PROD, el camino que
produjo la 7620103198 sigue abierto.**

La vigilancia recurrente —volver a correr este censo cada cierto tiempo para cazar el nº 15— se
queda en el `#469`, no aquí: es trabajo técnico, no revisión manual.
