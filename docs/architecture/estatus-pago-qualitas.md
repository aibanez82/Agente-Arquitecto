# Cómo saber con certeza si un cliente pagó la póliza

Movido desde `CLAUDE.md`, sección "Pendientes de infraestructura", al adelgazar el archivo (10 jul 2026).

## ✅ Mecanismo real confirmado (17 jul 2026) — no es un webhook, es un redirect de navegador

Se revisó la documentación oficial estructurada de Quálitas (`aguayo-co/HYL-WAI:docs/qualitas-documentacion-webservices/`, entregada 17 jul) buscando si Quálitas notifica el pago por webhook u otro medio — **no lo documenta en absoluto**, esa carpeta solo cubre cotización/emisión/tarifas/impresión, no el webservice de pago (OPL).

Cruzando esto con el código real de Django (`qualitas/services.py`), se confirmó el mecanismo real:

1. `generar_link_pasarela()` llama a `genWebPay` de Quálitas (`QUALITAS_URL_PAGO`) pasando **URLs de redirección del navegador**: `usucces`/`ufail` (`request.build_absolute_uri(reverse('pago_exitoso'))` / `pago_fallido`).
2. Cuando el cliente termina de pagar en la pasarela de Quálitas, **el navegador del cliente** es redirigido a `pago_exitoso` (o `pago_fallido`) con el número de póliza en el query string — no hay llamada servidor-a-servidor de Quálitas hacia Django.
3. `pago_exitoso` (`qualitas/views.py:945`) es lo que realmente marca `estatus_pago='PAGADO'`, dispara la descarga de documentos, y — si `origen == 'WhatsApp IA'` — llama a `enviar_webhook_whatsapp(poliza_obj)` (el webhook hacia n8n que actualiza `conversation_phase='completed'`).

**Por qué esto es frágil, no solo "no documentado":** depende de que el navegador del cliente complete el round-trip de vuelta a Django después de pagar. Si cierra la pestaña, pierde conexión, o la app de WhatsApp/navegador móvil mata la sesión antes de la redirección, Quálitas procesó el pago pero **Django nunca se entera** — no hay ningún mecanismo de respaldo servidor-a-servidor (ni webhook, ni polling de estatus) encontrado en el código ni en la documentación. Esto no es un vacío de documentación que se pueda resolver pidiéndole el dato a Quálitas — es una limitación real de cómo está construida la integración hoy, y es exactamente la razón de fondo por la que hace falta un mecanismo independiente de verificación (ver Agente Conciliación abajo).

## ⏳ En construcción — Agente Conciliación (14 jul 2026)

Alberto confirmó que el portal de Quálitas es un login simple, sin captcha, y que el volumen
diario de pólizas a conciliar es bajo. Se decidió resolver esto con un scraper determinístico
(Playwright, sin AI en el loop) en vez de un mecanismo automático del lado de Quálitas — repo
nuevo `aibanez82/Agente-Conciliacion`, protocolo completo en
`docs/protocolos/agente-conciliacion.md`. Escribe en una tabla propia (`conciliacion_pagos`),
nunca en `qualitas_polizaemitida`. Aún sin lógica real de scraping — falta que Alberto comparta
acceso al portal.

## Fila original de la tabla de pendientes

| Cómo saber con certeza si un cliente pagó la póliza — la doc oficial SOAP de Quálitas (`docs/qualitas-api/`: WsEmision, WsTarifas, WsImpresion, Matriz de Captura) **no documenta ningún endpoint ni campo de consulta de estatus de pago** (verificado 7 jul). Solo cubre `FormaPago` (método/frecuencia) y los recibos generados al emitir — nada sobre si un recibo/link de pago fue efectivamente pagado. Hoy la única señal automatizada es `qualitas_polizaemitida.estatus_pago`, que depende de un webhook externo de Quálitas hacia Django no documentado en su spec (ver Bug #7 y su workaround). Detectado por Alberto al revisar una conversación con póliza emitida y link de pago enviado, sin forma de confirmar el pago desde ahí. **No es dependencia de Juan** — la resolución probable es manual: Laura (Hylant) reporta ventas/pagos confirmados en una hoja Excel al día siguiente. | 💡 Sin investigar — definir si conviene formalizar el reporte de Laura como fuente de verdad (p. ej. cargarlo al Dashboard) en vez de perseguir un mecanismo automático de Quálitas |
