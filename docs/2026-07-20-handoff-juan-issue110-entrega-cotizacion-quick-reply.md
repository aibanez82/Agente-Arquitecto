## Estado de la integración n8n para tu runbook de entrega de cotización

Hola Juan, soy el Arquitecto (agente de Alberto). Seguimiento a tu doc
`docs/instrucciones-alberto-n8n-entrega-cotizacion-whatsapp.md` — te dejo el estado completo de
lo que se construyó del lado de n8n, dónde estamos y qué sigue.

### Qué se construyó (STG del bot de n8n, `dNqtM20ij6ecZYAX`)

Insertamos la rama `quoteDocumentAction?` justo después de resolver la sesión (antes de que el
mensaje llegue al agente de IA) — 108 nodos en total (88 originales + 20 nuevos/tocados). Cubre
exactamente el flujo de tu runbook:

1. Extrae `interactive.button_reply.id` (esto ya existía, reusado de la resolución por
   `conversation_id` de mediados de julio — nunca usa `.title`).
2. Valida consistencia `quotation_id`/`lead_id` entre el payload `qc:` y la sesión resuelta.
3. Idempotencia real por `messages[0].id` (tabla propia, nunca reenvía dos veces por el mismo
   clic).
4. Consulta `POST /api/cotizacion/detalle/` con `Authorization: Bearer <N8N_TOKEN>` (credencial
   dedicada en n8n, nunca en texto plano).
5. Decide entrega / no disponible / error según tu tabla exacta de la sección 4.
6. Entrega el documento a Meta o manda `mensaje_no_disponible`, según corresponda.
7. Registra el historial en `n8n_chat_histories`, sin exponer el token ni la URL firmada.

### Verificación

**Matriz completa de los 9 casos de tu runbook (sección 10), verificada en vivo end-to-end contra
Django y la Graph API reales en STG** — incluyendo entrega exitosa, documento no disponible, dos
cotizaciones con el mismo teléfono, clic repetido, token inválido, payload malformado, modo
`pdf_adjunto` sin reenvío, y error temporal (probado con un 500 real de Django).

En el camino encontramos y corregimos 3 bugs reales del lado de n8n (nada relacionado con tu
código Django):
- Un bug de idempotencia que habría bloqueado reintentos legítimos de un clic fallido.
- Un error de sintaxis al insertar el historial.
- Un bug de orden en el grafo que hacía que `mensaje_no_disponible` nunca se disparara.

Los tres quedaron corregidos y reverificados.

### Estado actual

**STG queda listo y validado. PROD no se ha tocado — nada de esto está activo en producción
todavía.**

### Qué sigue — necesitamos coordinar contigo el orden

Tu migración `0045` deja `resumen_quick_reply` como default. Antes de que mergees `stg`→`main` en
HYL-WAI (lo que activaría ese default en PROD), necesitamos tener esta misma rama ya desplegada y
validada en el n8n de PROD — si no, un cliente real haría clic en el botón y no recibiría nada
(el bot seguiría conversando normal, pero nunca entregaría el PDF).

Propuesta: avísanos con unos días de margen antes de mergear a `main`, para desplegar y validar
esta rama en PROD primero. Si tienes una fecha en mente, dínosla y nos organizamos.

Cualquier duda de negocio (mensajes exactos, qué cuenta como "no autorizado", etc.) mejor
coordinarla con Alberto/el Arquitecto antes que directo con el ejecutor que construyó esto en
n8n — así mantenemos una sola fuente de verdad del lado de n8n.

---

**Enviado como GitHub Issue:** https://github.com/aguayo-co/HYL-WAI/issues/110 (20 jul) — sin
acceso de push directo al repo de HYL-WAI todavía (PAT pendiente), se usó Issues como canal.
