Documentación
QUÁLITAS

Análisis del Esquema de Emisión vía WEB
Services
v.1.0

29/Marzo/2017

Control de Cambios

Versión  Responsable

Fecha

Comentarios

V1.0

V2.0

Valente
Hernández
Hernández

Valente
Hernández
Hernández

29  de  marzo
2017

•  Creación del documento

1 de junio 2021

•  Se actualiza el documento

Quálitas Compañía de Seguros

Página 2/20

Contenido

1.

 ................................................................................. 4

2.

Análisis del Esquema de Emisión vía Web Services

 ............................................................................................................................................... 4

2.1

Movimientos

 ........................................................................................................................................... 4

3.

4.

5.

6.

7.

7.

8.

Movimiento

 ................................................................................................................................... 5

Datos del asegurado

 ....................................................................................................................................... 7

Datos del vehículo

 ..................................................................................................................................10

Datos del Generales

........................................................................................................................................................14

Primas

 ......................................................................................................................................................14

Recibos

 .........................................................................................................................................16

Código de error

 .......................................................................................................................................................16

8.1

Anexos

 .................................................................................................................................16

8.2

8.3

8.4

8.6

8.7

9.

Anexo 1. Estados

 ................................................................................................................................17

Anexo 2. Servicio

 ........................................................................................................................................17

Anexo 3. Uso

 ...........................................................................................................................17

Anexo 4. Coberturas

...............................................................................................................................18

Anexo 5. Paquetes

 .......................................................................................................................19

Anexo 6. Tipo de suma

 ......................................................................................................................................................19

URL SW

Quálitas Compañía de Seguros

Página 3/20

1. Análisis del Esquema de Emisión vía Web Services

Este esquema representa el archivo XML que podrá ser usado vía servicios WEB.

2. Movimientos

Es la raíz del esquema.

2.1 Movimiento
Tipo de movimiento.

Es el tipo de transacción que se desea hacer. Hasta este momento se han definido 3 tipos.

•  2 Cotización
•  3 Emisión
•  4 Endoso

NoNegocio.

Esta es la clave que estará ligada a los descuentos y políticas de suscripción de la cuenta. Por la misma
razón, se validará que esté ligada a la clave del agente.

Esta clave se administrará desde el Sistema Principal. Más adelante se definirá.

NoPoliza.

Aquí vendrá el número de póliza y dependiendo del tipo de movimiento tendrá diferentes respuestas:

Tipo Movimiento

•  3  Emite  la  póliza  con  el  número  enviado,  siempre  y  cuando  no  exista.  Si  se  manda  emitir  sin

número de póliza el sistema asigna uno automáticamente.

•  4 Emite un endoso a la póliza enviada, si no hay póliza regresa un error.

Quálitas Compañía de Seguros

Página 4/20

NoCotizacion.

El sistema regresara el número de cotización en el caso de enviarse el tipo de movimiento de cotización.

NoEndoso.

Aquí se pondrá el número de endoso. Y su manejo ya se explicó en NoPoliza.

TipoEndoso.

Este dato se utiliza solo en la emisión de endosos y sirve para determinar el tipo de movimiento que se
le hará a la póliza.

NoOt.

Este el control con el que se ejecutará la petición de solicitud

Los siguientes datos están agrupados en 5 grupos:

1.  Datos del asegurado
2.  Datos del vehículo
3.  Datos generales
4.  Primas
5.  Recibos

3. Datos del asegurado

Este grupo de datos lleva un atributo que es:

NoAsegurado.

El  sistema  regresara el  número  de  asegurado  que  quedo  registrado  en  el  sistema  principal  solo  en  el
caso del Tipo de movimiento de emisión.

Nombre.

Cuando se trate de emisión, en este dato se pondrá el nombre del asegurado.

Dirección.
Dato donde se pondrá la dirección del cliente.

Colonia.

Dato donde se pondrá la colonia del cliente.

Población.

Lugar donde pondremos la población de cliente.

Quálitas Compañía de Seguros

Página 5/20

Estado

Dato donde pondremos el estado. Para este caso tenemos un catálogo de estados (Anexo 1).

Código postal.

Dato de código postal, de la dirección del cliente

NoCliente.

Identificador del cliente dentro de su organización.

Agrupador.

Dato para agrupar al cliente dentro de su organización.

CondicionesAdicionalesDA.

El objetivo de las condiciones adicionales es tratar de cubrir cualquier dato o consideración no
contemplada a nivel de datos del asegurado.

Y puede haber muchas o ninguna. Y tendrá un atributo y dos elementos que son los siguientes:

NoCondicion.

Existirá un número de condición para cada dato o consideración no contemplada, esto quiere decir que
cada número de consideración siempre manejará el mismo dato o consideración.

TipoRegla.

Este dato se utilizará para darle algún tratamiento especial al Valor que nos están enviando (ValorRegla).

ValorRegla.

Valor que enviarán del dato requerido.

Datos que deben enviarse adicionalmente para su registro en SISE al momento de la emisión

(tipo de movimiento 3 y 4). De forma obligatoria se requieren los datos de: Calle, Municipio, Estado, país
y código postal.

Quálitas Compañía de Seguros

Página 6/20

Para enviar la información del asegurado tomar en cuenta el archivo:
ResumenConsideracionesIdentificacionClienteServicioWeb.pdf

4. Datos del vehículo

Este grupo de datos lleva un atributo que es:

Inciso.

Es el número del inciso afectado, este número tendrá cierta funcionalidad asociada.

ClaveAmis.

Este dato es obligatorio para efectuar cualquier operación con este sistema, debido que este va a ser el
identificador para determinar cada vehículo. Solo podría omitirse cuando llenemos el número de póliza,
entendiendo que estaría tomando la clave AMIS que tiene en el sistema esta póliza.
Para la descarga del catálogo de vehículos tomar en cuenta el archivo: WSTARIFAS.pdf

Modelo:

Este dato también es obligatorio y se refiere al modelo del vehículo a cotizar o emitir.

DescripciónVehiculo.

Este dato es la descripción  del  vehículo, se supone que cada uno de los vehículos está amarrado a su
clave  AMIS  y  cada  una  de  estas  tiene  asociada  una  descripción,  pero  en  ciertas  ocasiones,  está  no  se
ajusta  totalmente  a  la  descripción  del  vehículo  asegurado,  por  lo  que  aceptamos  directamente  la
descripción, pero esta solo podrá recibir con autorización de la compañía.

Uso.

Este es el uso que se le dará al vehículo. (Anexo 3).

Servicio

   Esta clave es el servicio del vehículo (Anexo 2).

Paquete.

Este es el paquete de coberturas a asegurar (Anexo 5).

Motor.

El número de motor del vehículo, este número de motor es un identificador.

Quálitas Compañía de Seguros

Página 7/20

Serie.

Este es el dato que representa al vehículo de manera única. Y con este dato se valida que el vehículo no
esté duplicado o que se esté haciendo carrusel.

Coberturas.

Son  las  coberturas  adicionales  que  se  quieren  agregar  a  la  póliza  y  que  están  fuera  del  paquete  que
definió  con  anterioridad,  o  si  queremos  cambiar  las  condiciones  de  una  cobertura,  como  por  ejemplo
sumas aseguradas, deducibles, etc.

Cada cobertura tiene un atributo que es:

NoCobertura.

Este es el identificador de cada cobertura. (Anexo 4)

Contiene 4 elementos:

SumaAsegurada.

Es  la  suma  asegurada  que  se  le  asignara  a  la  cobertura.  Estas  sumas  aseguradas  estarán  limitadas  del
lado del Sistema Principal, y también el usuario deberá tener autorización del área comercial de Quálitas
para poder mover los montos de las sumas, tanto para arriba como para abajo.

TipoSumaAsegurada.

Es el tipo de suma asegurada que se le asignara a la cobertura. (Anexo 6)

Deducibles.

Es el deducible ya sea en porcentaje o en días, para el caso de RC, y de igual manera que la suma, deberá
estar limitado del lado de SISE y deberá de contar con autorización para poder moverlos.

Prima.

Aquí es donde el sistema principal devolverá el monto de la prima neta por cobertura.

CondicionesAdicionales.

Esta funcionara de la misma manera que las consideraciones de asegurado, pero estas serán a nivel
cobertura. Este grupo contara con los mismos datos y la misma funcionalidad que la de asegurados.

CondicionesAdicionalesDV.

Esta funcionara de la misma manera que las consideraciones anteriores, pero estas serán a nivel de
inciso. Este grupo contara con los mismos datos y la misma funcionalidad que la de asegurados.

Quálitas Compañía de Seguros

Página 8/20

NoConsideración “06”
Esta consideración es para agregar un texto adicional a la póliza.
NoConsideración
TipoRegla
ValorRegla

               el número de texto del archivo TEXTO, incluir ramo
               vacío

deberán mandar “06”

NoConsideración “39”
Esta consideración es para un recargo en asistencia vial para ciertos vehículos (categorías)

NoConsideración
TipoRegla
ValorRegla
Asistencia Vial Plus.

deberán mandar “39”
vacío
N|S El primer Valor corresponde a Vehículo blindado y la posición 2 a

NoConsideración “58”
Esta consideración es para enviar las placas del vehículo.

NoConsideración
TipoRegla
ValorRegla

deberán mandar “58”
vacío
Placa

NoConsideración “59”
Esta consideración es para enviar el número económico.

NoConsideración
TipoRegla

deberán mandar “59”
vacío

NoConsideración “60”
Esta consideración es para enviar número de pasajeros (para el cálculo de suma asegurada de la cobertura
RC PASAJERO)

NoConsideración
TipoRegla
ValorRegla

deberán mandar “60”
vacío
Número de Pasajeros

NoConsideración “61”
Esta consideración es para enviar el Conductor Habitual.

NoConsideración
TipoRegla
ValorRegla

deberán mandar “61”
vacío
Conductor Habitual

NoConsideración “132”
Esta consideración es para Quitar cobertura flexible PRODAN “47” Tipo Suma “19”

NoConsideración
TipoRegla
ValorRegla

deberán mandar “132”
vacío
N

Quálitas Compañía de Seguros

Página 9/20

5. Datos del Generales

FechaEmision.

Es la fecha de emisión de la póliza o el endoso, deberá ser la fecha actual, el formato que deberá
enviarse es: yyyy-mm-dd

Fechainicio.

Es la fecha de inicio de vigencia, siempre y cuando no sea menor que la fecha actual, en este caso no
emitirá el documento, el formato que deberá enviarse es: yyyy-mm-dd

FechaTermino.

Es la fecha de término de vigencia, esta validará el plazo del seguro y permitirá emitir de acuerdo a los
plazos autorizados. Para el caso de endosos, siempre deberá ser la fecha de término de vigencia de la
póliza, el formato que deberá enviarse es: yyyy-mm-dd

Moneda.

Moneda en que se emitirá o cotizará el documento. Por parte de la compañía de seguros será la
moneda nacional 0 – pesos, para poder utilizar otra deberá contar con autorización por parte de la
compañía de seguros.

Agente.

Aquí tendremos el número del agente, al que se le tienen que acreditar las comisiones, todas las
validaciones y permisos deberán estar autorizados para este agente.

Si se van a utilizar dos tipos de negocio diferentes ya no es necesario que cada uno tenga una clave de
agente diferente, con el atributo NoNegocio es suficiente.

FormaPago.

Esta es la forma de pago con que se emitirá el documento, desde luego deberá tener autorizadas las
formas de pago para poder utilizarlas.

TarifaValores.

En este dato se pondrá la tarifa que tiene autorizada el agente en el caso de las sumas aseguradas.

TarifaCuotas.

En este dato se pondrá la tarifa que tiene autorizada el agente en el caso de cuotas.

TarifaDerechos.

En este dato se pondrá la tarifa que tiene autorizada el agente en el caso de derecho de póliza.

Quálitas Compañía de Seguros

Página 10/20

Plazo.

El plazo en meses del negocio. (Deshabilitado)

Agencia.

En caso de tener agencias, en este dato vendrá el valor de esta. (Deshabilitado)

Contrato.

En caso de ser créditos, por parte de una arrendadora en este dato estaremos recibiendo el número del
contrato. (Deshabilitado)

CondicionesAdicionalesDG.

Esta funcionara de la misma manera que las consideraciones anteriores, pero estas serán a nivel de
póliza. Este grupo contara con los mismos datos y la misma funcionalidad que la de asegurados.

Ya están definidas algunas condiciones:

NoConsideración “01”

Corresponde a un dato de verificación de validez del envió, y se hace una validación de la clave AMIS con
el siguiente procedimiento

RUTINA PARA EL CÁLCULO DEL DIGITO VERIFICADOR

Se considera para efectuar el cálculo el siguiente ejemplo como clave AMIS:

22374

Etapa 1: Rellenar por la izquierda con ceros si la clave es menor a 5 dígitos, comenzar desde la izquierda,
sumar todos los caracteres ubicados en las posiciones impares.

2 + 3 + 4 = 09

Etapa 2: Multiplicar la suma obtenida en la etapa 1 por el número 3.

09 x 3 = 27

Etapa 3: Comenzar desde la izquierda, sumar todos los caracteres que están ubicados en las posiciones
pares.

2 + 7 = 09

Etapa 4: Sumar los resultados obtenidos en las etapas 2 y 3.

27 + 09 = 36

Quálitas Compañía de Seguros

Página 11/20

Etapa 5: Buscar el menor número que sumado al resultado obtenido en la etapa 4 dé un número múltiplo
de 10. Este será el valor del dígito verificador del módulo 10.

36 + 4 = 40

De esta manera se llega a que el número 4 es el dígito verificador módulo 10 para el código 22374

Por lo que en el esquema en ConsideracionesAdicionalesDG en el dato:

NoConsideración

deberán mandar “01”

TipoRegla

vació

ValorRegla

Deben enviar el resultado de la verificación, que en este caso es 4

NoConsideración “03”

Esta consideración está ligada a la emisión de endosos previa autorización del área comercial y funciona de
la siguiente manera:

NoConsideración
TipoRegla

deberán mandar “03”
Tipo de endoso, se le pondrá un número dependiendo del tipo de
Endoso:
3  Endoso A, solo inciso adicional.

NoConsideración “04”

Esta consideración se utiliza para enviar la petición de acuerdo con el ambiente

             NoConsideración
             TipoRegla
             ValorRegla                          enviar “1” ambiente pruebas, “0” ambiente producción

deberán mandar “04”

               vació

NoConsideración “05”

Esta consideración es para dar a conocer el descuento por pronto pago, previa autorización del área
comercial.

NoConsideración
TipoRegla
ValorRegla

deberán mandar “05”

               vació
               el número de días para pagar

NoConsideración “06”

Esta consideración es para agregar un texto adicional a la póliza.

NoConsideración
TipoRegla
               ValorRegla

deberán mandar “06”

               número del texto que será proporcionado por el área comercial
               vacío

Quálitas Compañía de Seguros

Página 12/20

NoConsideración “07”

Esta consideración es para agregar para determinar paquete de descuento de largo plazo, previa
autorización del área comercial.
NoConsideración
TipoRegla
ValorRegla

               vació
               número de paquete de descuento largo plazo

deberán mandar “07”

NoConsideración “12”

Esta consideración es para calcular los recibos al revés, previa autorización del área comercial.

NoConsideración
TipoRegla
ValorRegla

               vacío
                “I”

deberán mandar “12”

NoConsideración “13”

Esta consideración es para prorratear el derecho de póliza entre los recibos, previa autorización del área
comercial.

NoConsideración
TipoRegla
ValorRegla

               vacío
                “S”

deberán mandar “13”

NoConsideración “23”

Esta consideración es para forzar un tipo de cálculo (normal, corto plazo, largo plazo). En el valor de la
regla, va una “C” si es corto plazo, una “L” si es Largo Plazo y una “P” si es prorrata, previa autorización del
área comercial.

NoConsideración
TipoRegla
ValorRegla

deberán mandar “23”
vacío
“C” o “L” o “P”

NoConsideración “34”

Pone la suma asegurada convenida con 10% adicional o menos en todos los incisos, previa autorización del
área comercial.

NoConsideración
TipoRegla
ValorRegla

deberán mandar “34”
               1  = +10%; 2  =  -10%
               vacío

NoConsideración “46”

Esta consideración para enviar la clave de agencia

NoConsideración
TipoRegla
ValorRegla

deberán mandar “46”
vacío
Número de agencia, este catálogo será proporcionado por el área
comercial

NoConsideración “47”

Esta consideración para enviar la clave de agencia

NoConsideración
TipoRegla
ValorRegla

deberán mandar “47”
vacío
vacío

Quálitas Compañía de Seguros

Página 13/20

6. Primas

Primaneta.

Aquí el sistema devolverá la prima neta de la cotización o de la emisión.

Derecho.

Aquí el sistema devolverá el derecho de póliza de la cotización o de la emisión.

Recargo.

Aquí el sistema devolverá el recargo por forma de pago fraccionada de la cotización o de la emisión.

Impuesto.

Aquí el sistema devolverá el impuesto de la cotización o de la emisión.

PrimaTotal.

Aquí el sistema devolverá la prima total de la cotización o de la emisión.

Comisión.

Aquí el sistema devolverá la comisión total de la emisión.

Bonificación.

Para la emisión aquí deberán poner el porcentaje de descuento que quieren aplicar al documento a
emitir, desde luego este dato deberá ser autorizado por la compañía y validado por el sistema.

CondicionesAdicionalesP.

Esta funcionará de la misma manera que las consideraciones anteriores, pero estas serán a nivel de
póliza. Este grupo contara con los mismos datos y la misma funcionalidad que la de asegurados.

7. Recibos

Este grupo tiene un atributo que es el número de recibo.

NoRecibo.

Cuando se emite la póliza, el sistema principal regresa el (los) recibo (s) de acuerdo con la forma de pago
que se envió.

Fechainicio.

Es la fecha de inicio de vigencia, de cada uno de los recibos.

Quálitas Compañía de Seguros

Página 14/20

FechaTermino.

Es la fecha de término de vigencia, de cada recibo.

Primaneta

Aquí el sistema devolverá la prima neta de cada recibo.

Derecho.

Aquí el sistema devolverá el derecho de póliza de cada recibo.

Recargo.

Aquí el sistema devolverá el recargo por forma de pago fraccionada de cada recibo.

Impuesto.

Aquí el sistema devolverá el impuesto de cada recibo.

PrimaTotal.

Aquí el sistema devolverá la prima total de cada recibo.

Comisión.

Aquí el sistema devolverá la comisión del recibo

Bonificación.

Aquí el sistema devolverá el descuento de cada recibo.

CondicionesAdicionalesR.

Esta funcionara de la misma manera que las consideraciones anteriores, pero estas serán a nivel de
recibos. Este grupo contara con los mismos datos y la misma funcionalidad que la de asegurados.

Quálitas Compañía de Seguros

Página 15/20

7. Código de error

Si la transacción fue exitosa no regresa nada, pero el caso contrario indicará el tipo de error o que no
tiene permisos para ciertas transacciones.

Consultar el archivo: CatalogoErroresSW.xlsx

8. Anexos

8.1 Anexo 1. Estados

ID

ESTADO

1  Aguascalientes
2  Baja California Norte
3  Baja California sur
4  Campeche
5  Coahuila
6  Colima
7  Chiapas
8  Chihuahua
9  Ciudad de México

10  Durango
11  Guanajuato
12  Guerrero
13  Hidalgo
14  Jalisco
15  Estado de México
16  Michoacán
17  Morelos
18  Nayarit
19  Nuevo Leon
20  Oaxaca
21  Puebla
22  Queretaro
23  Quintana Roo
24  San Luis Potosí
25  Sinaloa
26  Sonora
27  Tabasco
28  Tamaulipas
29  Tlaxcala
30  Veracruz
31  Yucatán
32  Zacatecas

Quálitas Compañía de Seguros

Página 16/20

8.2 Anexo 2. Servicio

8.3 Anexo 3. Uso

ID  SERVICIO
01  Servicio Particular
02  Servicio Público
03  Servicio Público Federal

ID  USO
01  NORMAL
05  PERSONAL
06  CARGA
08  TAXI
19  BUS RUTA FIJA FORANEO
20  BUS TURISMO FORANEO
29  BUS TRANSPORTE ESCOLAR

8.4 Anexo 4. Coberturas

ID

Abrev

Descripción

1  DM
2  SPT
3  RT
4  RC
5  GM
6  MC
7  GL
8

9

10

11  ERC
12  EDDM
13  RCPAS
14  AV

17  GT/GxPUxPT

22  RCL
26  CADE
28  GxPUxPP

31

40  EDRT
RC
COMPLEMENTARIA
PERSONAS

47

Quálitas Compañía de Seguros

Daños Materiales
DM Sólo pérdida total
Robo Total
Responsabilidad Civil
Gastos Médicos
Muerte del Conductor X Accidente
Gastos Legales
Equipo Especial [descripción del equipo | suma asegurada]
Adaptaciones Daños Materiales [descripción de la adaptación |
suma asegurada]
Adaptaciones Robo Total [descripción de la adaptación | suma
asegurada]
Extensión de RC
Exención de Deducible Daños Materiales
RC Pasajero
Asistencia Vial
Gastos de Transporte/Gastos X Perdida de Uso X Pérdidas
Totales
RC Legal Ocupantes
Cancelación de deducible por vuelco o colisión
Gastos X Perdida de Uso X Perdidas Parciales
Daños por la carga.
Tipo Carga [A o B o C] | [Descrip de la Carga] | [Num Remolques]
Exención de Deducible Robo Total

Tipo Suma: 14

Página 17/20

8.6 Anexo 5. Paquetes

COD

DESCRIP
PAQUETE

DM
1

SPT
2

RT
3

RC
4

GM
5

GL
7

ERC
11

ED
12

RCPas
13

AV
14

GT
17

RCOcup
22

01
02
03
04
10

11

13

S
AMPLIA
N
PLUS
N
LIMITADA
RESP. CIVIL
N
RC (Servicio Público)  N
Amplia (Servicio
Publico)
Limitada (Servicio
Publico)

N

S

N
S
N
N
N

N

N

S
S
S
N
N

S

S

S
S
S
S
S

S

S

S
S
S
S
S

S

S

AD  O
AD  O
AD  O
AD  O
AD  O

AD  O

AD  O

N
N
N
N
N

N

N

N
N
N
N
N

N

N

AD  O
AD  O
AD  O
AD  N
AD  N

AD  O

AD  O

O
O
O
O
O

O

O

Tipo
S
N
AD

O

Descripción
Requerido No se puede omitir.
No Aplica no se puede incluir.
Adicional Por default lo incluye el paquete, se puede omitir.
Opcional Por default no se encuentra en el paquete, se puede
omitir.

Quálitas Compañía de Seguros

Página 18/20

8.7 Anexo 6. Tipo de suma

Tipo

Descripción
0  Valor convenido
1  Valor factura
3  Valor comercial

Nota:
Solo  aplicara  para  las  coberturas  Daños  Materiales  y  Robo  Total,  para  las  demás  coberturas  deberán
enviarse el Tipo de Suma 0, salvo que comercialmente se exprese algo distinto.

9. URL SW

Para consumir el Servicio Web de cotización/emisión los clientes deberán acceder a través de sus
aplicaciones a la siguiente URL de acuerdo con el ambiente, consumir el método: obtenerNuevaEmision
enviar el XML que construyeron.

Pruebas:

https://qa.qualitas.com.mx:8443/WsEmision/WsEmision.asmx

Producción
http://sio.qualitas.com.mx/WsEmision/WsEmision.asmx

Quálitas Compañía de Seguros

Página 19/20

