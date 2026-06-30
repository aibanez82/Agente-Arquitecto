Web Service
Tarifas

Identificación del documento

  Tipo

Contenido
Nombre del Archivo
Versión

Documentación Servicio Web
Web Service Tarifas
WSTarifas.doc
1.0.0.1

Elaboro

Nombre
Servicios en Linea

Función

Área
Servicios en Linea

Sistemas Servicios en Línea

03 de octubre de 2013

2  de 8

Contenido

Introducción .................................................................................................. 4
Propósito ............................................................................................................................................. 4
Alcance ................................................................................................................................................ 4
WSDL ..............................................................................................................................................5
Métodos............................................................................................................................................6
listaMarcas .......................................................................................................................................6
listaTarifas........................................................................................................................................9
Catálogo de Errores del Web Service Tarifas ............................................... 13

Sistemas Servicios en Línea

03 de octubre de 2013

3  de 8

Introducción

El  siguiente  documento  tiene  la  finalidad  de  orientar  al  cliente  sobre  el  Web  Service  Tarifas,  además
contiene  la  información  necesaria  para  consumir  el  Web  Service  desde  el  sistema  del  cliente  hacia  el
sistema de QUALITAS

Propósito

El objetivo de este documento es dar a conocer la documentación necesaria para el consumo del Web
Service Tarifas, los requisitos necesarios, así como los estándares para el envío de información entre el
Sistema del cliente y el Sistema de QUALITAS.

Alcance

El alcance de este documento abarca el consumo del Web Service a través de peticiones por parte de
cliente.

Sistemas Servicios en Línea

03 de octubre de 2013

4  de 8

Como Consumir el Web Service Tarifas

Para consumir el Web Service Tarifas los clientes deberán acceder a través de sus aplicaciones a la
siguiente:

URL: http://qbcenter.qualitas.com.mx/wsTarifa/wsTarifa.asmx

WSDL

Sistemas Servicios en Línea

03 de octubre de 2013

5  de 8

Métodos
listaMarcas

Método que permite obtener el listado de las marcas una tarifa.

Los parámetros de entrada son todos de tipo cadena.

Parámetro
cUsuario
cTarifa

Características
Obligatorio
Obligatorio

Ejemplo:
Datos proporcionados:
Usuario: “usuario”
Tarifa: “XXXX”

La salida es un XML, que regresa los nodos cMarca y cMarcaLarga.

<?xml version="1.0" encoding="utf-8" ?>

- <salida>
- <datos>
- <Elemento>
  <cMarca>AI</cMarca>
  <cMarcaLarga>AUDI</cMarcaLarga>

  </Elemento>

- <Elemento>
  <cMarca>AR</cMarca>
  <cMarcaLarga>ALFA ROMEO</cMarcaLarga>

  </Elemento>

- <Elemento>
  <cMarca>AT</cMarca>
  <cMarcaLarga>ASTON MARTIN</cMarcaLarga>

  </Elemento>

- <Elemento>
  <cMarca>BW</cMarca>
  <cMarcaLarga>BMW</cMarcaLarga>

  </Elemento>

- <Elemento>
  <cMarca>BY</cMarca>
  <cMarcaLarga>BENTLEY</cMarcaLarga>

  </Elemento>

- <Elemento>
  <cMarca>CR</cMarca>
  <cMarcaLarga>CHRYSLER</cMarcaLarga>

  </Elemento>

- <Elemento>
  <cMarca>CS</cMarca>
  <cMarcaLarga>CHASIS CABINA (MULTIMARCAS)</cMarcaLarga>

  </Elemento>

- <Elemento>
  <cMarca>CS</cMarca>

6  de 8

Sistemas Servicios en Línea

03 de octubre de 2013

  <cMarcaLarga>HINO MOTORS</cMarcaLarga>

  </Elemento>

- <Elemento>
  <cMarca>DA</cMarca>
  <cMarcaLarga>DINA</cMarcaLarga>

  </Elemento>

- <Elemento>
  <cMarca>EQ</cMarca>
  <cMarcaLarga>EQUIPO PESADO</cMarcaLarga>

  </Elemento>

- <Elemento>
  <cMarca>FD</cMarca>
  <cMarcaLarga>FORD</cMarcaLarga>

  </Elemento>

- <Elemento>
  <cMarca>FI</cMarca>
  <cMarcaLarga>FERRARI</cMarcaLarga>

  </Elemento>

- <Elemento>
  <cMarca>FM</cMarca>
  <cMarcaLarga>FAW MOTORS</cMarcaLarga>

  </Elemento>

- <Elemento>
  <cMarca>FR</cMarca>
  <cMarcaLarga>FRONTERIZOS</cMarcaLarga>

  </Elemento>

- <Elemento>
  <cMarca>FT</cMarca>
  <cMarcaLarga>FIAT</cMarcaLarga>

  </Elemento>

- <Elemento>
  <cMarca>FW</cMarca>
  <cMarcaLarga>FAW</cMarcaLarga>

  </Elemento>

- <Elemento>
  <cMarca>GH</cMarca>
  <cMarcaLarga>GH MOTORS</cMarcaLarga>

  </Elemento>

- <Elemento>
  <cMarca>GS</cMarca>
  <cMarcaLarga>GENERAL MOTORS</cMarcaLarga>

  </Elemento>

- <Elemento>
  <cMarca>GT</cMarca>
  <cMarcaLarga>GIANT MOTORS</cMarcaLarga>

  </Elemento>

- <Elemento>
  <cMarca>HA</cMarca>
  <cMarcaLarga>HONDA</cMarcaLarga>

  </Elemento>

- <Elemento>
  <cMarca>HM</cMarca>

7  de 8

Sistemas Servicios en Línea

03 de octubre de 2013

  <cMarcaLarga>HINO MOTORS</cMarcaLarga>

  </Elemento>

- <Elemento>
  <cMarca>IO</cMarca>
  <cMarcaLarga>IVECO</cMarcaLarga>

  </Elemento>

- <Elemento>
  <cMarca>JP</cMarca>
  <cMarcaLarga>JEEP</cMarcaLarga>

  </Elemento>

- <Elemento>
  <cMarca>JR</cMarca>
  <cMarcaLarga>JAGUAR</cMarcaLarga>

  </Elemento>

- <Elemento>
  <cMarca>LI</cMarca>
  <cMarcaLarga>LAMBORGHINI</cMarcaLarga>

  </Elemento>

- <Elemento>
  <cMarca>LR</cMarca>
  <cMarcaLarga>LANDROVER</cMarcaLarga>

  </Elemento>

- <Elemento>
  <cMarca>LS</cMarca>
  <cMarcaLarga>LOTUS</cMarcaLarga>

  </Elemento>

- <Elemento>
  <cMarca>LX</cMarca>
  <cMarcaLarga>LEXUS</cMarcaLarga>

  </Elemento>

- <Elemento>
  <cMarca>MA</cMarca>
  <cMarcaLarga>MAZDA</cMarcaLarga>

  </Elemento>

- <Elemento>
  <cMarca>MG</cMarca>
  <cMarcaLarga>MORGAN</cMarcaLarga>

  </Elemento>

- <Elemento>
  <cMarca>MH</cMarca>
  <cMarcaLarga>MAYBACH</cMarcaLarga>

  </Elemento>

- <Elemento>
  <cMarca>MI</cMarca>
  <cMarcaLarga>MITSUBISHI</cMarcaLarga>

  </Elemento>

- <Elemento>
  <cMarca>MO</cMarca>
  <cMarcaLarga>BARRUCHI</cMarcaLarga>

  </Elemento>

- <Elemento>
  <cMarca>MO</cMarca>

8  de 8

Sistemas Servicios en Línea

03 de octubre de 2013

  <cMarcaLarga>BMW</cMarcaLarga>

  </Elemento>

- <Elemento>
  <cMarca>MO</cMarca>
  <cMarcaLarga>HUSABERG</cMarcaLarga>

  </Elemento>

- <Elemento>
  <cMarca>MO</cMarca>
  <cMarcaLarga>HYUNDAI</cMarcaLarga>

  </Elemento>

- <Elemento>
  <cMarca>MO</cMarca>
  <cMarcaLarga>KYMCO</cMarcaLarga>

  </Elemento>

- <retorno>
  <codigo>0</codigo>
  <descripcion>115</descripcion>

  </retorno>
  </salida>

listaTarifas

Los parámetros de entrada son todos de tipo cadena, y es posible filtrar por cada uno de ellos con el fin de obtener una
selección más pequeña.
Parámetro
cUsuario
cTarifa
cMarca

Características
Obligatorio
Obligatorio
Opcional, solo si se desea filtrar por el valor Marca. Para filtrar se debe
proporcionar el valor del campo completo, se puede filtrar por la marca
corta (ejemplo: VW) o por la marca larga (ejemplo: VOLKSWAGEN), y se
devolverá todos los elementos que tengan el valor de Marca exactamente
igual al dato proporcionado.
Opcional, solo si se desea filtrar por el valor Tipo. Para filtrar se debe
proporcionar el valor del campo completo (ejemplo: POLO) y se devolverá
todos los elementos que tengan el valor de Tipo exactamente igual al dato
proporcionado.
Opcional, solo si se desea filtrar por el valor Versión. Para filtrar se debe
proporcionar el valor que se desea buscar en el campo (ejemplo: Sedan), y
se devolverán todos los elementos que contengan en el campo de Versión
el valor proporcionado.
Opcional, solo si se desea filtrar por el valor Modelo. Para filtrar se debe
proporcionar el valor del campo completo (ejemplo: 2005) y se devolverá
todos los elementos que tengan el valor de Modelo exactamente igual al
dato proporcionado.
Opcional, solo si se desea filtrar por el valor AMIS. Para filtrar se debe
proporcionar el valor del campo completo (ejemplo: 07003) y se devolverá
todos los elementos que tengan el valor de AMIS exactamente igual al dato
proporcionado.
Opcional, solo si se desea filtrar por el valor Categoría. Para filtrar se debe
proporcionar el valor del campo completo (ejemplo: 100) y se devolverá
todos los elementos que tengan el valor de Categoría exactamente igual al
dato proporcionado.
Opcional, solo si se desea filtrar por el valor NvaAMIS. Para filtrar se debe
proporcionar el valor del campo completo (ejemplo: B0280041) y se

cTipo

cVersion

cModelo

cCAMIS

cCategoría

cNvaAMIS

Sistemas Servicios en Línea

03 de octubre de 2013

9  de 8

devolverá todos los elementos que tengan el valor de NvaAMIS
exactamente igual al dato proporcionado.

Ejemplo:
Datos proporcionados:
Usuario: “usuario”
Tarifa: “0605”
cMarca: “VW”
cTipo: “POLO”
cVersion: “Sed”
cModelo: “2005”
cCAMIS: “”
categoría: “”
cNvaAMIS: “”

La salida es un XML con la siguiente estructura:
<?xml version="1.0" encoding="utf-8" ?>

- <salida>
- <datos>
- <Elemento>
  <cTarifa>1102</cTarifa>
  <cMarca>VW</cMarca>
  <cTipo>POLO</cTipo>
  <cVersion>1.6L SEDAN EE CD STD., 05 OCUP.</cVersion>
  <cModelo>2005</cModelo>
  <CAMIS>07003</CAMIS>
  <cCategoria>100</cCategoria>
  <cTransmision>S</cTransmision>
  <cOcupantes>05</cOcupantes>
  <nV1>139000</nV1>
  <nV2>59000</nV2>
  <cNvaAMIS>B0980079</cNvaAMIS>
  <cMarcaLarga>VOLKSWAGEN</cMarcaLarga>

  </Elemento>

- <Elemento>
  <cTarifa>1102</cTarifa>
  <cMarca>VW</cMarca>
  <cTipo>POLO</cTipo>
  <cVersion>1.6L SEDAN EE CD C/A AC STD., 05 OCUP.</cVersion>
  <cModelo>2005</cModelo>
  <CAMIS>07004</CAMIS>
  <cCategoria>100</cCategoria>
  <cTransmision>S</cTransmision>
  <cOcupantes>05</cOcupantes>
  <nV1>150000</nV1>
  <nV2>64000</nV2>
  <cNvaAMIS>B0980080</cNvaAMIS>
  <cMarcaLarga>VOLKSWAGEN</cMarcaLarga>

  </Elemento>

- <Elemento>
  <cTarifa>1102</cTarifa>
  <cMarca>VW</cMarca>
  <cTipo>POLO</cTipo>
  <cVersion>1.6L SEDAN COMFORTLINE EE CD C/A AC RA S</cVersion>

10  de

Sistemas Servicios en Línea

03 de octubre de 2013

  <cModelo>2005</cModelo>
  <CAMIS>07005</CAMIS>
  <cCategoria>100</cCategoria>
  <cTransmision>S</cTransmision>
  <cOcupantes>05</cOcupantes>
  <nV1>155000</nV1>
  <nV2>66000</nV2>
  <cNvaAMIS>B0980080</cNvaAMIS>
  <cMarcaLarga>VOLKSWAGEN</cMarcaLarga>

  </Elemento>

- <Elemento>
  <cTarifa>1102</cTarifa>
  <cMarca>VW</cMarca>
  <cTipo>POLO</cTipo>
  <cVersion>1.6L SEDAN COMFORTLINE EE CD C/AAC RA SP</cVersion>
  <cModelo>2005</cModelo>
  <CAMIS>01227</CAMIS>
  <cCategoria>111</cCategoria>
  <cTransmision>S</cTransmision>
  <cOcupantes>05</cOcupantes>
  <nV1>155000</nV1>
  <nV2>60000</nV2>
  <cNvaAMIS>B0980080</cNvaAMIS>
  <cMarcaLarga>VOLKSWAGEN</cMarcaLarga>

  </Elemento>

- <Elemento>
  <cTarifa>1102</cTarifa>
  <cMarca>VW</cMarca>
  <cTipo>POLO</cTipo>
  <cVersion>2.0L SEDAN EE CD C/A AC RA SERVPUB STD.,</cVersion>
  <cModelo>2005</cModelo>
  <CAMIS>01228</CAMIS>
  <cCategoria>111</cCategoria>
  <cTransmision>S</cTransmision>
  <cOcupantes>05</cOcupantes>
  <nV1>161000</nV1>
  <nV2>61000</nV2>
  <cNvaAMIS>B0980080</cNvaAMIS>
  <cMarcaLarga>VOLKSWAGEN</cMarcaLarga>

  </Elemento>

- <Elemento>
  <cTarifa>1102</cTarifa>
  <cMarca>VW</cMarca>
  <cTipo>POLO</cTipo>
  <cVersion>2.0L SEDAN EE CD C/A AC RA STD., 05 OCUP</cVersion>
  <cModelo>2005</cModelo>
  <CAMIS>07006</CAMIS>
  <cCategoria>100</cCategoria>
  <cTransmision>S</cTransmision>
  <cOcupantes>05</cOcupantes>
  <nV1>161000</nV1>
  <nV2>67000</nV2>

11  de

Sistemas Servicios en Línea

03 de octubre de 2013

  <cNvaAMIS>B0980080</cNvaAMIS>
  <cMarcaLarga>VOLKSWAGEN</cMarcaLarga>

  </Elemento>

- <Elemento>
  <cTarifa>1102</cTarifa>
  <cMarca>VW</cMarca>
  <cTipo>POLO</cTipo>
  <cVersion>1.6L SEDAN SERVPUB STD., 05 OCUP.</cVersion>
  <cModelo>2005</cModelo>
  <CAMIS>07009</CAMIS>
  <cCategoria>111</cCategoria>
  <cTransmision>S</cTransmision>
  <cOcupantes>05</cOcupantes>
  <nV1>139000</nV1>
  <nV2>54000</nV2>
  <cNvaAMIS>B0980079</cNvaAMIS>
  <cMarcaLarga>VOLKSWAGEN</cMarcaLarga>

  </Elemento>

- <Elemento>
  <cTarifa>1102</cTarifa>
  <cMarca>VW</cMarca>
  <cTipo>POLO</cTipo>
  <cVersion>1.6L SEDAN C/A AC SERVPUB STD., 05 OCUP.</cVersion>
  <cModelo>2005</cModelo>
  <CAMIS>07010</CAMIS>
  <cCategoria>111</cCategoria>
  <cTransmision>S</cTransmision>
  <cOcupantes>05</cOcupantes>
  <nV1>150000</nV1>
  <nV2>58000</nV2>
  <cNvaAMIS>B0980080</cNvaAMIS>
  <cMarcaLarga>VOLKSWAGEN</cMarcaLarga>

  </Elemento>
  </datos>
- <retorno>
  <codigo>0</codigo>
  <descripcion>8</descripcion>

  </retorno>
  </salida>

Sistemas Servicios en Línea

03 de octubre de 2013

12  de

Catálogo de Errores del Web Service Tarifas

En el nodo retorno, se devuelven los nodos código y descripción. Si no hay error, en código se
devuelve un cero, y en descripción la cantidad de elementos devueltos. Si ocurre algún error, en el
nodo código se devuelve el No. de Error, y en descripción la descripción del error, como se muestra
en el siguiente ejemplo:

  <?xml version="1.0" encoding="utf-8" ?>
- <salida>
  <datos />
- <retorno>
  <codigo>1</codigo>
  <descripcion>Datos de Usuario y Tarifa obligatorios. </descripcion>
  </retorno>
  </salida>

Cod Error  Mensaje Error

1

2

3

4

Datos de Usuario y Tarifa obligatorios.

No se encontraron elementos para el criterio
de selección especificado.

El usuario especificado no existe.

El usuario no tiene permisos para la Tarifa

li i d

Sistemas Servicios en Línea

03 de octubre de 2013

13  de

