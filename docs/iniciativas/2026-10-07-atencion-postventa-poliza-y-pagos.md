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

## Segundo caso, del mismo día (medido en PROD, 7 oct)

Teléfono `524641184076`. Póliza **`7620103892`** (Jetta, VIN `3VWBV09M4CM039303`), emitida el 5 oct a las 10:41
CDMX, `PAGADO`, de contado.

- Ese mismo día y el siguiente, el cliente abrió **tres cotizaciones más** (`4316`, `4318` y `4321`).
- En la `4321` llegó hasta emitir. `Issue_Policy` contestó que **ese VIN ya tenía póliza**, y el bot le respondió
  *«En este momento solo emitimos pólizas nuevas, no renovaciones de pólizas Quálitas existentes»*. Es falso para
  este cliente: la póliza es **nuestra** y tiene un día.
- Después el cliente pidió «el link para pagar» y lo atendió una persona.
- No tengo capturado el VIN de la sesión `4321`. Que sea el mismo coche es la lectura obvia (mismo cliente, mismo
  modelo), pero no está medido.

**Lo que enseña:** el cliente que vuelve no siempre pregunta; a veces **vuelve a empezar a cotizar**. Sin el Router,
el bot intenta venderle una segunda póliza del mismo coche y, cuando Quálitas lo para, le da una explicación falsa.

## Cuántos casos hay: no se puede medir con fiabilidad desde la BD

Dos mediciones fallaron su control positivo, porque ninguna recoge el caso origen:
- `whatsapp_sessions.last_activity` **no se actualiza** en sesiones legacy: la del caso origen sigue en el 6 jul
  aunque el cliente escribió el 6 oct;
- `n8n_outbound_dispatch` **no registra** las respuestas del carril legacy/fallback: el caso origen no tiene ni una
  fila.

Con lo que sí se ve, hay **2 casos en dos días** (5-6 oct) entre 30 pólizas `PAGADO`. **Propuesta:** que el propio
Router cuente cada desvío a postventa, para que el volumen se mida desde el primer día y no se reconstruya después.

## Por qué importa

El embudo falla al cobrar recibos, no al emitir: de 46 pólizas reales, 20 las canceló Quálitas por recibos
impagados (censo del 6 sep). El cliente que pregunta por su pago es, a menudo, el que está a punto de dejar de
pagar. Hoy le ofrecemos cotizar.

## Propuesta de diseño (a validar)

### Dónde vive cada cosa (decidido con Alberto, 7 oct)

**Restricción que manda:** solo hay un disparador de WhatsApp por app de Meta, el del bot principal
(`WhatsApp Insurance Quotation Bot`). Todo mensaje entra por ahí. Django no está en el camino de entrada (Meta → n8n
directo). Así que **el punto de reparto tiene que estar en el bot principal**, pero **la lógica no**: ese workflow
tiene 418 nodos y viaja entero en cada cambio (el `#551` tuvo que esperar el 7 oct porque cualquier import cambia
su versión bajo otras pruebas).

Tres piezas:

1. **Bot principal: solo dos nodos, que se tocan una vez.** Una llamada a sub-workflow y un desvío. Van **después
   de `Session Resolution`**, que ya dejó el teléfono canónico, la sesión y el estado de toma humana (si la hay,
   manda la persona y no se desvía nada). Van **antes del carril del descuento y del `Intent Router`**, para que un
   cliente que ya pagó no caiga en el flujo de cotizar. Y van **después del buffer**: una consulta por ráfaga, no por
   mensaje suelto.
2. **Sub-workflow «Router de Cliente».** Llama a Django («¿este teléfono tiene póliza vigente?»). Si no la tiene,
   devuelve `cotizacion` y el bot sigue como hoy. Si la tiene, un clasificador (Haiku) desempata solo entre
   «pregunta por su póliza o sus pagos» y «quiere otra cotización». Devuelve `cotizacion` o `postventa`. **Se ajusta
   e importa sin tocar el bot principal.**
3. **Sub-workflow «Atención Postventa».** Consulta a Django el detalle, responde con agente y prompt propios y solo
   tools de consulta, y escala lo que no puede resolver.

**Descartado:**
- **Marcar al cliente en la sesión** en vez de preguntar a Django: falla con el caso origen, que compró por la web
  y cuya sesión de WhatsApp nunca pasó por el pago. Además, `whatsapp_sessions` es de n8n, y la verdad sobre quién
  pagó la tiene Django.
- **Partir ya el bot principal en una puerta de entrada fina con dos workflows hijos:** es la arquitectura buena a
  largo plazo, pero supone rehacer el bot con el `#551` y el VIN de foto en vuelo. El Router en sub-workflow es el
  primer paso hacia ella sin ese riesgo.

### Django: endpoint de consulta por teléfono

Autenticado con el Bearer de n8n y solo lectura, en dos niveles:
- **existencia** para el Router: sí o no, y cuántas pólizas;
- **detalle** para Postventa: por cada póliza vigente del teléfono canónico, número, vehículo, cobertura, vigencia,
  forma de pago, los recibos del **ledger v2** (número, vencimiento, importe y estado vigente), los enlaces a
  documentos y, si existe, la liga de pago del recibo pendiente (`qualitas_receiptpaymentlink`).

**Contrato versionado**, como el de Recovery.

### Atención Postventa: reglas

- **Sin** tools de cotizar ni de emitir. Las cifras las pone el grafo, no el modelo (la lección del #341/#324:
  fidelidad de dígito).
- **Escalado:** lo que el bot no puede resolver (cambio de forma de pago, aclaraciones de cobro, cancelación) va al
  contact center de Metepec (`metepecaten@qualitas.com.mx`, WhatsApp `55 3751 1678`). Los siniestros, al
  `800 800 2880` o Quali Bot. Son los datos de contacto que fijó el #554.
- **Lo que no hace:** no cambia la forma de pago, no cancela y no promete nada sobre el cobro que no esté en el
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

- **Vocabulario de recibos**, ya medido el 14 sep: `promesa_de_pago` aparece **después de generarse una liga de
  pago**; `rechazado` es un recibo **reemitido**, no un cobro fallido. Para el estado vigente se toma la última
  observación por `receipt_identity_id`.
- **Interacción con `Session Resolution`:** con sesiones legacy, varias `open` o ninguna `active`.
- **Que los seguimientos de cotización no le escriban a un cliente que ya pagó.**
- **Latencia de la consulta de existencia por ráfaga.** Si se nota, el Router solo llama a Django cuando la sesión no
  tiene una cotización en curso.
- **`Payment Confirmation`:** hoy pone la sesión en `completed`. Desde ese momento debería ir a postventa.
