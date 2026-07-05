# Iniciativa — Extracción de datos de Constancia de Situación Fiscal (CSF)

> **TRIGGER DE RETOMADA:** cuando Alberto diga *"retomemos el proyecto de extractor de PDF"* →
> leer la **spec** y el **plan** de abajo y continuar por el siguiente paso pendiente.

## Cómo retomar (estado al 4 jul 2026)

- **Diseño:** ✅ aprobado → [`2026-07-04-constancia-fiscal-integracion-n8n-design.md`](2026-07-04-constancia-fiscal-integracion-n8n-design.md)
- **Plan de implementación:** ✅ escrito → [`2026-07-04-constancia-fiscal-plan-implementacion.md`](2026-07-04-constancia-fiscal-plan-implementacion.md)
- **Nada ejecutado aún.** Siguiente paso = elegir por dónde arrancar:
  - **A — Desplegar el extractor** (Docker en VPS Hostinger) → Alberto + Arquitecto; runbook en Fase 1 del plan. NO bloqueado por staging.
  - **B — Handoff al Agente n8n** (Fases 2-3: workflow CSF Ingestion + cambio bot) → construir se puede ya; **probar requiere staging**.
  - **C — Montar Staging Fase 1** (`entorno-pruebas-staging.md`) → desbloqueador para probar A+B y llevar a prod.
- **Recomendación:** el camino crítico pasa por **staging (C)**; **A** es victoria limpia autocontenida cuando haya 20 min en el VPS.

> Este archivo es el índice; la fuente de verdad es la spec + el plan. Guardado en git (no memoria local).

## Qué es

Extraer automáticamente los datos de una **Constancia de Situación Fiscal** (SAT, México) para no capturarlos a mano. Una CSF típicamente contiene: RFC, nombre/razón social, régimen fiscal, y **domicilio fiscal** (CP, colonia, calle, número, municipio, estado), fecha de inicio de operaciones, etc.

## Por qué importa (sinergia con el resto del ecosistema)

Varios de estos campos son exactamente los que hoy el bot captura por conversación y la IA re-extrae vía `$fromAI` al emitir (RFC, nombre, domicilio) — la misma fragilidad detrás del Bug #10. Si esos datos vinieran de un **documento parseado deterministicamente** en lugar de extracción por IA sobre chat, se reduce la superficie de error y encaja con la **Opción B del Bug #10** (mapeo rígido: un store estructurado y confiable que `Issue_Policy` lea sin interpretación de IA). Potencial: la CSF alimenta la captura estructurada.

## Por definir al retomar

- Dónde vive el código ya hecho (repo/ruta) y en qué lenguaje/stack.
- Método de extracción: ¿OCR sobre PDF/imagen, parseo del PDF de texto del SAT, o lectura del QR/cadena del SAT?
- Qué campos extrae hoy y con qué fiabilidad.
- Dónde se integraría en el funnel: ¿en la landing (Django), en el bot (n8n), o como servicio aparte? ¿Alimenta `qualitas_cotizacion`/`captured_data`?
- Validación de los datos extraídos antes de usarlos para emitir.

## Próximo paso al retomar

Alberto trae el código existente y decidimos el punto de integración. Relacionado: Opción B del Bug #10 (mapeo rígido / `whatsapp_sessions.captured_data`).
