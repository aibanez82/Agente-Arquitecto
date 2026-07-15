# Cómo saber con certeza si un cliente pagó la póliza

Movido desde `CLAUDE.md`, sección "Pendientes de infraestructura", al adelgazar el archivo (10 jul 2026).

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
