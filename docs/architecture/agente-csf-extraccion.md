# Agente CSF — Extracción de Constancia de Situación Fiscal

## Qué es

Servicio FastAPI (`aibanez82/insurmind_extractor`) que extrae datos del PDF de 
Constancia de Situación Fiscal (CSF) emitido por el SAT México.

Desplegado en Railway: `insurmindextractor-production.up.railway.app`

## Decisiones de arquitectura

- **Opción elegida:** regex-only con pdfplumber, sin Claude vision fallback
- **Rechazo de imágenes:** el bot rechaza explícitamente imágenes ("solo aceptamos el PDF descargado del SAT")
- **Almacenamiento:** Supabase — tabla `sat_documents` + `sat_extractions` + bucket `sat-pdfs`

## Límites

| Parámetro | Código | Bucket Supabase |
|---|---|---|
| Tamaño máximo PDF | 5MB | 2MB |

⚠️ Mismatch pendiente de resolver — alinear a 2MB en el código.

## Datos extraídos

- RFC
- Razón social / nombre
- Régimen de capital
- Código postal
- Fecha de emisión del documento
- Regímenes fiscales

## Integración con n8n

Pendiente — requiere decisión de Juan Aguayo sobre entorno de pruebas n8n 
(n8n Cloud trial vs instancia Railway).
