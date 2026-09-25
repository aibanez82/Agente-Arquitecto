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

## Las trece pendientes de pago

Emitidas, sin cobrar. Ordenadas por número de señales.

| # | Póliza | VIN emitido | Vehículo cotizado | Señal |
|---|---|---|---|---|
| 1 | 7620102772 | `3N1AB7AP7HY219404` | HYUNDAI ELANTRA 2024 | dígito (7≠0) **y** WMI Nissan |
| 2 | 7620099714 | `3FA6P0H77HR103594` | TOYOTA C-HR 2022 | dígito (7≠8) **y** WMI Ford |
| 3 | 7620099716 | `3G1BE5SM3JS114952` | FORD EDGE 2020 | dígito (3≠6) **y** WMI Chevrolet |
| 4 | 7620098914 | `MB2C22AC6LM856961` | HYUNDAI CRETA 2020 | dígito (6≠9) |
| 5 | 7620099526 | `3N1AB7AP8EY708126` | NISSAN APRIO 2008 | dígito (8≠6) |
| 6 | 7620099709 | `MEX5A2669L1974968` | VW VENTO 2020 | dígito (9≠6) |
| 7 | 7620102540 | `3HGCM5H5XHA000123` | CHEVROLET AVEO 2015 | dígito (X≠0) |
| 8 | 7620102934 | `1FAFP42X64F165471` | VW JETTA 2016 | WMI Ford |
| 9 | 7620102937 | `WBANV13548CZ54505` | AUDI Q5 2024 | WMI BMW |
| 10 | 7620101467 | `1HGCG32601A007720` | AUDI Q3 2020 | WMI Honda |
| 11 | 7620102689 | `1FTCR14A3VTA51719` | NISSAN MARCH 2018 | WMI Ford |
| 12 | 7620098611 | `1FMPU15595LA45520` | KIA K3 2025 | WMI Ford |
| 13 | (sin número) | `3N1BC1AS6BL477627` | TOYOTA RAV4 2024 | WMI Nissan |

**El nº 8 tiene una particularidad:** su dígito verificador **sí cuadra**, pero el WMI es Ford sobre
una VW Jetta. Es el VIN de la conversación `waq_3613`/`waq_3608` del 21 sep, y su foto **está visible
en el Dashboard**, así que es el único de los trece que se puede contrastar contra la imagen sin
pedir nada a nadie. Por ahí empieza la revisión más barata.

---

## Tres cosas que hay que saber antes de trabajar la lista

**1. Es un suelo, no un techo.** La comparación de marca usa una tabla de WMI conocidos: si el WMI
de un VIN no está en esa tabla, **no se señala nada**. Puede haber más de trece. El número que sí es
cerrado es el del dígito verificador, que es aritmética y no depende de ninguna tabla: **ocho** de
los catorce lo fallan.

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
