## Agente Conciliación — protocolo de uso

**Repo:** `aibanez82/Agente-Conciliacion` (clonado en `~/claude-projects/Agente-Conciliacion`, push directo habilitado desde el Arquitecto, 14 jul 2026).

**Rol:** Ejecutor Nivel 3, especializado en verificar el estatus de pago real de las pólizas
emitidas. Resuelve el pendiente documentado en `docs/architecture/estatus-pago-qualitas.md`:
Quálitas no expone el estatus de pago por ningún endpoint documentado, así que la única fuente
confiable hoy es el portal web mismo — este agente lo automatiza en vez de depender de revisión
manual o del reporte de Laura (Hylant) en Excel.

**Por qué no usa AI en el loop de scraping:** el portal de Quálitas tiene login simple, sin
captcha, y el volumen diario de pólizas a conciliar es bajo (confirmado por Alberto, 14 jul
2026). Con esas condiciones, un scraper determinístico (Playwright) es más barato, rápido y
fácil de debuggear que meter computer-use/vision — y no hay fricción anti-bot que justifique la
resiliencia extra de un approach basado en modelo. Si el portal cambia (agrega captcha, 2FA, o
un flujo inestable), es una decisión de arquitectura que vuelve al Arquitecto antes de que Agente
Conciliación cambie de approach por su cuenta.

**Dónde escribe:** tabla propia `conciliacion_pagos` (ver `migrations/001_create_conciliacion_pagos.sql`
en su repo) — **nunca** en `qualitas_polizaemitida`, que es de Django/Juan. El Dashboard consulta
el estatus real con un JOIN aparte contra esta tabla nueva, sin que Agente Conciliación necesite
tocar nada del lado de Django.

**Flujo:**
```
Arquitecto diagnostica/decide alcance (qué pólizas conciliar, con qué frecuencia)
    ↓
Alberto comparte credenciales del portal + URL exacta
    ↓
Agente Conciliación mapea selectores reales del portal, completa src/conciliar.js
    ↓
Prueba manual (workflow_dispatch en GH Actions) antes de activar el cron
    ↓
Arquitecto verifica en vivo (contra conciliacion_pagos y una muestra de pólizas conocidas)
    ↓
Se activa el cron diario (descomentar schedule: en .github/workflows/conciliar.yml)
```

**Estado (14 jul 2026):** repo recién creado con esqueleto — sin lógica de scraping real. Falta
que Alberto comparta acceso al portal (URL, usuario, contraseña) para poder mapear los
selectores reales de login, búsqueda de póliza, y el campo de estatus de pago.

**Segunda responsabilidad decidida (20 jul):** además de conciliar `qualitas_polizaemitida`,
Agente Conciliación también actualiza `estado_metepec`/`fecha_cierre_metepec`/
`monto_cierre_metepec` en la tabla standalone `leads_metepec` (leads entregados al contact
center de Highland — ver `docs/iniciativas/2026-07-20-leads-metepec-seguimiento-comisiones.md`).
Mismo patrón de búsqueda puntual en el portal ("Consulta de póliza"), pero por **Número de
serie (VIN)** en vez de número de póliza conocido, porque para estos leads no tenemos número de
antemano (los emite METEPEC). No viola la regla de "nunca tocar tablas de Django" — `leads_metepec`
es standalone, igual que `conciliacion_pagos`.
