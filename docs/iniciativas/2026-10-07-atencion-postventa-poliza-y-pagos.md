# Iniciativa — Atención postventa: el cliente que ya compró pregunta por su póliza o sus pagos

**Abierta:** 7 oct 2026, por encargo de Alberto. **Estado:** registrada; diseño propuesto; decisiones abiertas abajo.
**Dueños previstos:** Django (Juan), endpoint de consulta · n8n (Agente n8n), carril nuevo · Arquitecto, diseño y
contrato.

## El caso que la origina (medido en PROD, 7 oct)

Teléfono `524444277224`. Póliza **`7620098214`**, origen Landing Web, emitida el 6 jul, `estatus_pago = PAGADO`,
forma de pago mensual (12 recibos).

- **Mensaje del cliente** (6 oct, 09:16 CDMX, ejecución `79235`): *«tengo pago domiciliado no?»*.
- **Respuesta del bot:** *«No tienes una cotización activa en este momento, así que no puedo confirmarte eso.
  ¿Quieres que iniciemos o retomemos una cotización…?»*. Le ofrece cotizar a quien ya es cliente y lleva tres
  recibos pagados.
- **Por qué:**
  - la única sesión del teléfono es legacy (`session_id = 524444277224`, sin `conversation_id`, `greeting`, `open`,
    sin actividad desde el 6 jul);
  - el `[CTX:]` llegó con `qid=null` y `phase=fallback`;
  - `Get_Quotation_Data` devolvió `sin_cotizacion`;
  - el bot solo sabe hablar de cotizar y emitir.
- **Lo que el sistema sí sabía** (ledger v2 de recibos, `qualitas_qualitasproviderreceiptobservation`, último
  `snapshot` por `receipt_identity_id`):
  - recibo 1 pagado el 13 jul con tarjeta;
  - recibos 2 y 3 pagados **en su misma fecha de vencimiento** (7 ago y 7 sep), sin tarjeta registrada;
  - recibo 4 (vence 7 oct, $990.54) en `promesa_de_pago`;
  - recibos 5 a 12 `por_cobrar`.

  Con eso se podía contestar algo útil, y justo el día antes de un vencimiento.
- **Trampa medida:** la tabla v1 `qualitas_qualitasproviderreceipt` dejó de actualizarse el 4 sep (relevo al ledger
  v2). Ahí el recibo 3 sale `por_cobrar`, que es **falso**. Cualquier consulta debe leer el v2.
- **Aparte:** el Dashboard marca la conversación con `identity_contradiction`, coherente con una sesión legacy sin
  `conversation_id` en modo `dual`.

## Por qué importa

El embudo falla al cobrar recibos, no al emitir: de 46 pólizas reales, 20 las canceló Quálitas por recibos
impagados (censo del 6 sep). El cliente que pregunta por su pago es, a menudo, el que está a punto de dejar de
pagar. Hoy le ofrecemos cotizar.

## Propuesta de diseño (a validar)

1. **Detección determinista, no por intención sola.** Al entrar un mensaje, n8n pregunta a Django si **ese teléfono
   tiene alguna póliza emitida vigente**. Si la tiene y el mensaje no es claramente una cotización nueva, el turno va
   al **carril postventa**. Un clasificador (Haiku) solo desempata entre «postventa» y «quiere otra cotización», y
   solo cuando hay póliza.
2. **Django: endpoint de consulta por teléfono** (autenticado con el Bearer de n8n, solo lectura). Por cada póliza
   vigente del teléfono canónico devuelve:
   - número, vehículo, cobertura y vigencia;
   - forma de pago;
   - recibos del **ledger v2**: número, vencimiento, importe y estado vigente;
   - enlaces a documentos y, si existe, la liga de pago del recibo pendiente (`qualitas_receiptpaymentlink`).

   **Contrato versionado**, como el de Recovery.
3. **n8n: carril/sub-workflow «Atención postventa»**, separado del de cotización y emisión.
   - Agente con prompt propio y tools solo de consulta: resumen de póliza y recibos, reenvío de documentos y liga de
     pago.
   - **Sin** tools de cotizar ni de emitir.
   - Las cifras las pone el grafo, no el modelo (la lección del #341/#324: fidelidad de dígito).
4. **Escalado:**
   - lo que el bot no puede resolver (cambio de forma de pago, aclaraciones de cobro, cancelación) va al contact
     center de Metepec (`metepecaten@qualitas.com.mx`, WhatsApp `55 3751 1678`);
   - los siniestros, al `800 800 2880` o Quali Bot.

   Son los datos de contacto que fijó el #554.
5. **Lo que no hace:** no cambia la forma de pago, no cancela y no promete nada sobre el cobro que no esté en el
   ledger.

## Decisiones abiertas (de Alberto)

1. **Verificación de identidad.** Identificamos solo por teléfono: el mensaje llega desde ese número, pero puede
   haber teléfonos compartidos o varias pólizas por teléfono. ¿Basta el teléfono para dar el resumen? ¿O pedimos un
   segundo dato (placas, o nombre del asegurado) antes de dar importes y estados de pago?
2. **Alcance de la v1:** ¿solo consulta (póliza, recibos y documentos), o también la acción de mandar la liga de
   pago del recibo pendiente?
3. **«Domiciliado»:** el ledger no tiene un campo que lo diga. Hay indicios (pago en la fecha exacta, sin tarjeta),
   pero un indicio no es un dato. ¿Lo contestamos solo si Django/Quálitas lo expone, o se escala?
4. **Prioridad y tracker:** abro el issue en `HYL-WAI` (Django + n8n) cuando lo decidas.

## Por medir antes del diseño final

- **Cuántos casos hay:** mensajes entrantes de teléfonos con póliza `PAGADO` posteriores a su pago, en 30 días.
- **Vocabulario de `promesa_de_pago`** y del resto de estados (ver la referencia de vocabulario de recibos: «rechazado»
  = reemitido).
- **Interacción con `Session Resolution`:** con sesiones legacy, varias `open` o ninguna `active`.
- **Que los seguimientos de cotización no le escriban a un cliente que ya pagó.**
