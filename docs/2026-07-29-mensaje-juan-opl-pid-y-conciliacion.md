# Borrador — mensaje a Juan: credenciales OPL (Janderson) + doc de oplConciliation

> Estado: BORRADOR — Alberto decide canal y momento.
> Actualizado 31 jul tras recuperar el paquete de alta del negocio (correo "27614_ALTA DE NEGOCIO", nov 2025) con la spec `Api REST - Link de Pago v1.4`.
> Contexto interno: `docs/qualitas-api/api-rest-link-de-pago.md`, `docs/qualitas-api/opl-servicios-web.md` y `docs/architecture/estatus-pago-qualitas.md`.

---

Hola Juan,

Recuperamos el paquete del alta del negocio OPL (correo de Samuel Díaz de nov 2025, "27614_ALTA DE NEGOCIO") y con él la documentación oficial del API REST de pagos (`api.php`, v1.4). Tres cosas:

1. **Ya no hace falta pedir doc a Quálitas para lo que preguntaste a Laura el 23 jul.** El API REST que ya usáis en `generar_link_pasarela` tiene métodos documentados para exactamente eso: `searchlink` (consultar el link de una póliza), `cancellink` (cancelarlo), `genlink` (regenerarlo y que Quálitas lo mande por email), y sobre todo **`listrecs`: status de todos los recibos de una póliza** (`pagado`/`rechazado`, fecha de pago, banco, autorización). Todo con el mismo `wptoken` de siempre. Estamos validando `listrecs` en vivo — si funciona, tenemos confirmación de pago por API sin depender del redirect del navegador.

2. **Credenciales OPL — pregunta interna antes que a Quálitas.** En ese correo Samuel dice que el 25 nov 2025 enviaron a `janderson.gomez@aguayo.co` las llaves del ambiente QA y las llaves de encriptación. Los servicios SOAP de lectura (`oplListReceipts`, `getRefOpl`) nos piden un `pid`+`token` "de OPL" que hoy nos rechaza (`Negocio Inexsistente o Token Invalido`). ¿Puedes revisar con Janderson si entre lo que recibió está ese Pid/token (QA y/o PROD) para el negocio 08545?

3. **Sigue pendiente con Quálitas solo una cosa:** la spec de `oplConciliation` y `oplListPols` — operaciones que el WSDL de producción (`https://pagos.qualitas.com.mx/ws/wsCollection.php?WSDL`) expone pero que no están en el PDF v1.3.2. Un servicio llamado "conciliation" es justo lo que querríamos para verificar pagos sin scraping de Q360.

No es urgente ni bloquea nada.

Gracias!
