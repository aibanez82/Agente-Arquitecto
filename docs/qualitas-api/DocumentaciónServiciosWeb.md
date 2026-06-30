Documentación
QUÁLITAS

Servicios Web
v.3.0

01/Julio/2017

Control de Cambios

Versión  Responsable

Fecha

Comentarios

V1.0

V2.0

V.3.0

Valente
Hernández
Hernández

Valente
Hernández
Hernández

Valente
Hernández
Hernández

31  de  Enero
2015

•  Creación del documento

1 de Julio 2017

•  Se agregan comentarios

1 Junio 2021

•  Se actualiza el
documento

Quálitas Compañía de Seguros

Página 2/9

Contenido

1. PROPÓSITO ................................................................................................................................................... 4
Contenido

1.1 Objetivos del Documento....................................................................................................................... 4

1.2 Alcance del Documento ......................................................................................................................... 4

2. Introducción ................................................................................................................................................. 5

3. SW Web ........................................................................................................................................................ 6

4. Servicio Web Cotización /Emisión ................................................................................................................ 6

5. Como consumir el Servicio Web ................................................................................................................... 6
5.1  WSDL............................................................................................................................................... 7

5.2

5.3

5.4

Transacción: plantilla XML .............................................................................................................. 7

Reglas para la generación del XML ................................................................................................. 9

Catalogo de errores del Servicio Web ............................................................................................ 9

5.5  Métodos disponibles ...................................................................................................................... 9

Quálitas Compañía de Seguros

Página 3/9

1. PROPÓSITO

1.1 Objetivos del Documento

•  El objetivo  de este  documento  es  dar  a conocer la documentación necesaria para el consumo
del  Servicios  Web,  los  requisitos  necesarios,  así  como  los  estándares  para  el  envío  de
información entre el Sistema del cliente y el Sistema de  QUALITAS.

1.2 Alcance del Documento

•  El  alcance  de  este  documento  abarca  el  consumo  del  Servicio  Web  a  través  del  envió  de

peticiones desde el sistema del cliente.

Quálitas Compañía de Seguros

Página 4/9

2. Introducción

El  siguiente  documento  tiene  la  finalidad  de  explicar  el  funcionamiento  del  Servicio  Web,  contiene  la
información necesaria para consumir el Servicios Web desde el sistema del cliente hacia el sistema de
QUÁLITAS.

Quálitas Compañía de Seguros

Página 5/9

3. SW Web

Un Servicio Web es un programa de Internet que permite la comunicación directa entre los sistemas.

El Servicio Web está dirigido a clientes con la capacidad de desarrollar en sus sistemas el acceso a los
Servicios Web, y la administración desde sus sistemas de las cotizaciones, emisiones e impresiones.

En  la  compañía  existen  distintos  Servicios  Web  como  son:  cotización/emisión,  cobranza,  tarifas  e
impresión de documentos ligados a la póliza, que tienen comunicación directa con el Sistema Principal
de Quálitas.

Ventajas

•
•
•
•
•

Comunicación en línea con los sistemas de Quálitas de manera permanente.
Respuesta inmediata al cliente.
Flexibilidad en la configuración de productos.
Administración desde el sistema del cliente de las cotizaciones y emisiones.
Protección de la información a nivel infraestructura.

4. Servicio Web Cotización /Emisión

Permite la cotización, emisión y consulta de pólizas en línea, Pólizas individuales y Flotillas, Residentes,
Fronterizos, Legalizados, Equipo Pesado, Motos, Servicio Público, Turistas.

Funcionalidades

•
•

Cotización, emisión y consulta de pólizas en línea.
Integrado a ambiente de alta disponibilidad.

5. Como consumir el Servicio Web

Para consumir el Servicio Web de cotización/emisión los clientes deberán acceder a través de sus
aplicaciones a la siguiente URL de acuerdo con el ambiente:

Pruebas:

https://qa.qualitas.com.mx:8443/WsEmision/WsEmision.asmx

Producción

   http://sio.qualitas.com.mx/WsEmision/WsEmision.asmx

Quálitas Compañía de Seguros

Página 6/9

Y a través del método de ObtenerNuevaEmision, se envía la petición: Muestra información sobre la
5.1
aplicación, como la versión, descripción y ensamblados cargados.

WSDL

Para enviar la transacción al Servicio Web, se debe enviar un archivo tipo XML.
5.2

Transacción: plantilla XML

Quálitas Compañía de Seguros

Página 7/9

Quálitas Compañía de Seguros

Página 8/9

Para construir el archivo XML que podrá ser usado vía Servicio Web, consultar el archivo:
5.3
Reglas para la generación del XML
AnalisisDeEsquemaDeSistemasUsuarios.pdf

Para la identificación del cliente, articulo 492:

ResumenConsideracionesIdentificacionClienteServicioWeb.pdf

Consultar el archivo: CatalogoErroresSW.xlsx
5.4
Catálogo de errores del Servicio Web

5.5

EnviaMail: Envía correo electrónico a una cuenta interna de Quálitas.

Métodos disponibles
•
• HolamundoAux: Método que utilizan los clientes para la comprobación del consumo de la URL

•
•

del servicio.
Test: Método que utilizan los clientes para la comprobación del consumo de la URL del servicio.
obtenerNuevaEmision: Se encarga de procesar las peticiones de acuerdo al tipo de movimiento
que se encuentra definido en el documento de Análisis de Esquemas de Sistemas.

Quálitas Compañía de Seguros

Página 9/9

