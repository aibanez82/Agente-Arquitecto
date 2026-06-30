Documentación
QUÁLITAS

ó

Servicio Web
n
de Impresi

v.2.0

01/Julio/2017

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

31  de  Enero
2015

•  Creación del documento

1 de Julio 2017

•  Se agregan comentarios

Quálitas Compañía de Seguros

Página 2/8

Contenido

Introducción ............................................................................................ 4
Propósito ..................................................................................................................................... 4
Alcance ........................................................................................................................................ 4
Como Consumir el Web Service Impresión ............................................. 5
WSDL ..................................................................................................................................... 5
Métodos................................................................................................................................... 6
Solicitud Impresión ................................................................................................................. 6
Respuesta Solicitud Impresión ................................................................................................ 7
Catálogo de Errores del Web Service Impresión ..................................... 8

Quálitas Compañía de Seguros

Página 3/8

Introducción

El siguiente documento tiene la finalidad de orientar al cliente sobre el Web Service Impresión, además
contiene  la  información  necesaria  para  consumir  el  Web  Service  desde  el  sistema  del  cliente  hacia  el
sistema de QUALITAS

Propósito

El objetivo de este documento es dar a conocer la documentación necesaria para el consumo del Web
Service Impresión, los requisitos necesarios, así como los estándares para el envío de información entre
el Sistema del cliente y el Sistema de QUALITAS.

Alcance

El alcance de este documento abarca el consumo del Web Service a través de peticiones por parte de
cliente.

Quálitas Compañía de Seguros

Página 4/8

Como Consumir el Web Service Impresión

Para consumir el Web Service Impresión los clientes deberán acceder a través de sus aplicaciones a la
siguiente URL de acuerdo con el ambiente:

Pruebas:

URL: https://qa.qualitas.com.mx:8443/QBCImpresion/Service.asmx

Produccion:

URL: http://qbcenter.qualitas.com.mx/QBCImpresion/Service.asmx

WSDL

Quálitas Compañía de Seguros

Página 5/8

Métodos

Método para el Web Service Impresión: Recupera Impresión M15

Solicitud Impresión

En esta sección se describe la forma en la cual se enviara la petición al Web Service Impresión por
cualquiera de los anteriores métodos.
Esta transacción se lleva a cabo cuando el Sistema del Cliente envía al Web Service Impresión la solicitud de
impresión  mediante la siguiente petición:

Solicitud de impresión QUALITAS

Origen: Sistema del Cliente
Destino: Web Service Impresión
Campo
nPoliza
URLPoliza
URLRecibo
URLTextos

Formato  Descripción
string
string
string
string

Número de Póliza a 10 dígitos
URL Póliza
URL Recibo
URL Textos

Inciso
ImpPol
ImpRec
ImpAnexo
Ramo

int
int
int
int
string

Número de Inciso
* Póliza individual 0001
* Póliza flotilla ####"
Sin uso
Sin uso
Sin uso
Ramo de la póliza

Formato de la impresión
Sin Logos
FormaPol = poliza_aut_emi_1
Con Logos
FormaPol = polizaf1_logoQ_pdf

Formato de la impresión
Sin Logos
FormaRec = recibo_pdf
Con Logos
FormaRec = recibo_logoQ_pdf

formaPol

string

formaRec

string

Ejemplo

1234567890

vacío
vacío
vacío

0001

04

0
0
0

poliza_aut_emi_1

recibo_pdf

Quálitas Compañía de Seguros

Página 6/8

Formato de la impresión
Sin Logos
FormaAnexo  = polizaf2_pdf
Con Logos
FormaAnexo  = polizaf2_logoQ_pdf

Número de endoso
* Póliza sin endoso= 000000
* Póliza con endoso =123456

formaAnexo

string

Endoso

string

NoNegocio

string

Número de negocio
Equivalente al atributo NoNegocio del XML

Agente
Usuario
Password

string
string
string

Clave de Agente
Equivalente al nodo Agente del XML
Sin uso
Sin uso

polizaf2_pdf

000000

vacío
vacío

123

12345

Respuesta Solicitud Impresión

Respuesta de impresión
Pruebas

Origen: Sistema del Cliente
Destino: Web Service Impresión
Campo
URLPoliza
URLRecibo
URLTextos

Formato
string
string
string

Descripción
URL Póliza
URL Recibo
URL Textos

Respuesta de impresión
Producción

Origen: Sistema del Cliente
Destino: Web Service Impresión
Campo
URLPoliza
URLRecibo
URLTextos

Formato
string
string
string

Descripción
URL Póliza
URL Recibo
URL Textos

Ejemplo
https://qa.qualitas.com.mx:8443/poliza/p1234567890.pdf

https://qa.qualitas.com.mx:8443/poliza/r1234567890.pdf
https:// qa.qualitas.com.mx:8443/poliza/t1234567890.pdf

Ejemplo
https://sio.qualitas.com.mx:8088/polizaSSL/p1234567890

https://sio.qualitas.com.mx:8088/polizaSSL/r1234567890

https://sio.qualitas.com.mx:8088/polizaSSL/t1234567890

Quálitas Compañía de Seguros

Página 7/8

Catálogo de Errores del Web Service Impresión

Cod Error  Mensaje Error

0002
0003

No existe el Negocio Registrado en el sistema
No mando el número de negocio

0004
0065

El agente no coincide con el negocio
No existe esta póliza

Origen
No se tiene registrado el negocio
Cuando el agente del cual
queremos imprimir la póliza
no está relacionado al número
de negocio

Se omitió el número de negocio
La póliza no existe

Quálitas Compañía de Seguros

Página 8/8

