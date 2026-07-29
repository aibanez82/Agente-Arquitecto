# Borrador — mensaje a Juan: credencial Pid OPL + doc de oplConciliation

> Estado: BORRADOR — Alberto decide canal y momento (¿checkpoint del 30 jul? ya está cargado con el NO-GO).
> Contexto interno: `docs/qualitas-api/opl-servicios-web.md` y `docs/architecture/estatus-pago-qualitas.md`.

---

Hola Juan,

Conseguimos la doc del webservice de pago OPL de Quálitas (v1.3.2) y estuvimos explorándolo — dos cosas que quizá tú puedas destrabar con tu contacto en Quálitas:

1. **Pid de negocio OPL.** Los servicios de lectura (`oplListReceipts`, `getRefOpl`) usan una credencial distinta del `wpuid`/`wptoken` que ya usa Django: un `pid` + `token` "proporcionados por OPL". Con nuestras credenciales actuales responden `Negocio Inexsistente o Token Invalido`. ¿Puedes pedir a Quálitas el Pid/token OPL del negocio 08545? Nos habilitaría consultar recibos por API (y `getRefOpl` abriría a futuro la ficha de pago referenciado — pago en efectivo — por WhatsApp).

2. **Documentación de `oplConciliation` y `oplListPols`.** El WSDL de producción (`https://pagos.qualitas.com.mx/ws/wsCollection.php?WSDL`) expone estas operaciones que no aparecen en el PDF v1.3.2. Un servicio llamado "conciliation" es exactamente lo que necesitamos para verificar pagos reales sin scraping del portal Q360. ¿Puedes pedir la spec (o una versión más nueva del PDF)?

No es urgente ni bloquea nada: mientras tanto ya validamos que `api.php m=fareceipt` (el que ya usa `generar_link_pasarela`) nos sirve de verificación cruzada con el token actual.

Gracias!
