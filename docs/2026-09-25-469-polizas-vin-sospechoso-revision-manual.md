# Pólizas con VIN que no se sostiene — revisión manual de Alberto

**Decisión de Alberto, 25 sep 2026: las trece van por fuera.** No se abre issue operativo; el
`#469` se queda solo con lo técnico. Esta lista existe para que la revisión sobreviva a la sesión y
se pueda trabajar desde cualquier máquina — un censo que vive en un comentario de GitHub entre otros
quince no es una lista de trabajo.

**Fuente:** censo del Arquitecto sobre `qualitas_polizaemitida` cruzada con su cotización, BD de
PROD, VIN de 17 caracteres, medido el 25 sep 2026.
**Issue:** `aguayo-co/HYL-WAI#469` (`sistema:n8n`, `criticidad:critico`, `area:emision`).

---

## La que ya lleva Alberto

| Póliza | Pago | VIN en la póliza | Vehículo cotizado | VIN real (de la foto) |
|---|---|---|---|---|
| **7620103198** | **PAGADO** | `3N1AB7AP7EL609642` | RENAULT STEPWAY 2012 | **`93YB62JB1CJ081818`** |

El VIN real se leyó de la propia tarjeta de circulación que viaja en la ejecución `58067`. Encaja en
todo: dígito verificador correcto, WMI `93Y` = Renault, posición 10 `C` = 2012. La titular está
avisada por otro canal.

## ⚠️ Corregido: eran trece, son **siete**

La primera versión de este documento listaba trece. **Seis de las catorce eran emisiones de prueba
nuestras** —titulares «Prueba Primero», «Prueba Pruebo», «Pruebo Intento», «Juan Gomez», «Cliente
Sintetico», con correos `juan.aguayo@aguayo.co`, `test@test.com` y `codex-smoke-…@example.…`—.

**Se colaron porque filtré por el VIN y no por el titular.** El número de serie de una emisión de
prueba puede parecer perfectamente normal; lo que la delata es quién figura como asegurado. Y
explica por qué fallaban las comprobaciones: un VIN inventado a mano para una prueba no tiene por
qué cumplir el dígito verificador ni pegar con la marca. No eran indicios; era ruido nuestro.

## Las siete pendientes de pago

Emitidas, sin cobrar, y **son clientes reales**.

| # | Póliza | VIN emitido | Vehículo cotizado | Señal |
|---|---|---|---|---|
| 1 | 7620098611 | `1FMPU15595LA45520` | KIA K3 2025 | WMI Ford |
| 2 | 7620098914 | `MB2C22AC6LM856961` | HYUNDAI CRETA 2020 | dígito (6≠9) |
| 3 | 7620099526 | `3N1AB7AP8EY708126` | NISSAN APRIO 2008 | dígito (8≠6) |
| 4 | 7620099709 | `MEX5A2669L1974968` | VW VENTO 2020 | dígito (9≠6) |
| 5 | 7620102689 | `1FTCR14A3VTA51719` | NISSAN MARCH 2018 | WMI Ford |
| 6 | 7620102934 | `1FAFP42X64F165471` | VW JETTA 2016 | WMI Ford |
| 7 | 7620102937 | `WBANV13548CZ54505` | AUDI Q5 2024 | WMI BMW |

Las nº 6 y 7 comparten titular con otras pólizas del mismo nombre: conviene mirarlas juntas.

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
