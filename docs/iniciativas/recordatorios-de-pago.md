# Iniciativa — Recordatorios de pago por WhatsApp (D-7, D-48h, D-24h, día D)

> **Issue canónico (estado y discusión): `aguayo-co/HYL-WAI#144`** — decisión de Alberto 31 jul: la iniciativa vive en el repo de Juan porque la implementación propuesta es Django. Este archivo es el cuaderno técnico local; no lleva estado.
> Pedido del negocio: recordar al cliente con póliza emitida y no pagada que le quedan 7 días / 48h / 24h / "hoy vence si no pagas antes de las 12:00", con enlace de pago en cada mensaje.
> Base técnica: servicios Quálitas validados en vivo el 31 jul — `docs/qualitas-api/api-rest-link-de-pago.md`.

## Restricción que gobierna el diseño

**Los links de pago de Quálitas caducan a ~24h** (validado vía `searchlink`: `cancellink` automático al día siguiente del `genlink`). Por tanto **cada recordatorio genera su link fresco en el momento del envío** — nunca se reutiliza un link entre hitos.

## Algoritmo por envío (cada hito)

Candidatas: pólizas emitidas con `estatus_pago != 'PAGADO'` cuya fecha límite D coincida con el hito (D-7, D-2, D-1, D-0).

1. **Verificar pago real antes de enviar** — `api.php m=listrecs` (funciona con el `QUALITAS_WPTOKEN` actual):
   - algún recibo `status_rec='pagado'` → NO enviar; marcar pagada (alimenta además la conciliación).
   - recibo `cancelado` → sacar del ciclo de recordatorios.
   - solo `por cobrar`/`rechazado` → procede el recordatorio. `m=fareceipt` da el monto exacto para el copy.
2. **Generar link fresco** — `m=genWebPay` (póliza, email, `usucces`/`ufail`) → `urlwbpy`. Mismo método que ya usa `generar_link_pasarela()` en Django.
3. **Enviar WhatsApp** por la vía proactiva existente (webhook n8n del Dashboard/followups) → INSERT en `n8n_chat_histories` con `metadata.source='payment_reminder_<hito>'` (visibilidad en Dashboard + idempotencia: un hito no se envía dos veces).
4. Confirmación de pago: el redirect `usucces` sigue siendo la señal inmediata; `listrecs` en el siguiente hito es la red de seguridad si el redirect se pierde.

Hito D-0: enviar a primera hora de la mañana `America/Mexico_City` (el copy dice "antes de las 12:00") — aquí el horario SÍ importa, a diferencia de los checkpoint followups actuales.

## Dónde corre

**Recomendación: Django (Juan).** Razones: ya existe el scheduler de checkpoint followups enviando en real en PROD (20 jul), tiene las credenciales Quálitas y el código de `genWebPay`, y es dueño de `qualitas_polizaemitida`. Esto es un nuevo tipo de checkpoint basado en fecha límite de pago en vez de inactividad. Alternativa n8n (Schedule Trigger + Postgres + HTTP) posible pero duplicaría lógica que Django ya tiene.

## Bloqueantes / decisiones previas

| # | Qué | Estado |
|---|---|---|
| 1 | **Plantilla de Meta** para mensaje proactivo fuera de ventana 24h. Una sola plantilla con variables (nombre, días restantes, monto, link) sirve para los 4 hitos — y desbloquea también "Recordatorios por fecha mencionada" | 🔴 Mismo bloqueante conocido desde el 16 jul. Meta la ejecuta Juan. **⚡ Alternativa detectada 31 jul: `genlinkWSP`/`genlinkSMS` (api.php v1.4.1) — Quálitas genera Y envía el link por SU canal WhatsApp/SMS, sin ventana 24h nuestra ni plantilla Meta. Probable en QA (`pagosqa`). Ver `docs/qualitas-api/api-rest-link-de-pago.md` §v1.4.1** |
| 2 | **Fuente de la fecha límite D** ("vence tu póliza"). Las APIs no la dan: `fareceipt`/`listrecs` ruedan `fcr`/`fcobro` a hoy mientras el recibo siga cobrable; la cancelación por impago es regla de negocio de Quálitas (¿emisión + N días naturales? ¿varía contado vs fraccionado?). Opciones: confirmar regla con Laura/Quálitas, o tomarla de Q360 si el portal la muestra (preguntar al Agente Conciliación qué campos ve) | 🔴 Sin D fiable no hay cuenta atrás |
| 3 | Decisión formal Django vs n8n como lanzador | ⏳ Alberto/Juan |
| 4 | Copy de los 4 mensajes (tono, urgencia creciente) | ⏳ Tubería Agente Mejoras Conversación → Arquitecto → plantilla |

## Interacciones con lo existente

- **Agente Conciliación:** `listrecs` en el paso 1 es la misma verificación que su cruce API — no duplicar: los resultados del paso 1 pueden registrarse como señal, pero `conciliacion_pagos` sigue siendo suya y de su cron.
- **Checkpoint followups:** ciclo independiente (inactividad conversacional vs impago de póliza). Un cliente puede estar en ambos; revisar que no se solapen mensajes el mismo día.
- **Bug #7 / phase completed:** estos recordatorios NO deben depender de `conversation_phase` — solo de `estatus_pago` + verificación `listrecs`.

## Decisión pendiente — canal de envío (1 ago 2026)

Planteada a Alberto: ¿envía Quálitas (`genlinkWSP`, disponible ya, copy/canal suyo), enviamos nosotros (plantilla Meta, bloqueada, hilo propio), o híbrido (Quálitas ya + migrar a canal propio)? Recomendación del Arquitecto: híbrido, previa prueba en QA.

**⚠️ Instrucción de Alberto: NO recordarle esta decisión — la retomará él cuando quiera.** Queda aquí solo para no perderla entre máquinas.
