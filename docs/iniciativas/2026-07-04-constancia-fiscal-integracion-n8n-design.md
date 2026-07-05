# Diseño — Integración de subida de Constancia de Situación Fiscal (CSF) en el workflow de cotización n8n

> Spec aprobada por Alberto el 4 jul 2026 (proceso de brainstorming).
> Supersede el placeholder `constancia-situacion-fiscal-extraccion.md`.
> Ejecutor del/los workflow(s): **Agente n8n**. Despliegue del extractor: **Alberto + Arquitecto (infra)**.

## Objetivo

Permitir que el lead, en la fase de captura de datos para emitir, **suba su Constancia de Situación Fiscal (PDF del SAT)** y que el bot autocomplete sus datos, en lugar de teclearlos uno a uno. Reduce fricción y errores de captura.

## Alcance

**Dentro:**
- **Solo PDF oficial del SAT** (el extractor usa `pdfplumber` = texto real del PDF, NO OCR).
- **Solo persona física** (el extractor es `v2-persona-fisica`).
- Autocompleta: datos personales + domicilio + RFC (y, derivados del CURP: fecha de nacimiento y género).

**Fuera (futuro):**
- **OCR / foto de la constancia** — se evalúa si se ve que muchos leads mandan foto en vez de PDF.
- **Persona moral.**
- El vehículo (serie/placas) NO viene en la CSF → sigue siendo captura manual.

## Decisiones tomadas (brainstorming 4 jul)

1. Input: **solo PDF del SAT** (foto = futuro).
2. Entry point: al **inicio de la captura**, el bot ofrece *"¿subes tu constancia (PDF) y lleno tus datos, o me los das a mano?"*.
3. **Enfoque B — desacoplado**: sub-workflow de ingesta que escribe a `whatsapp_sessions.captured_data`; el bot principal solo lee ese campo.
4. **Confirmación siempre**: el bot muestra resumen de TODOS los datos extraídos y el usuario confirma/corrige antes de emitir (lección del Bug #10 — nunca emitir con datos extraídos sin confirmar, sin importar `confidence`).
5. Hosting del extractor: **VPS de Hostinger con SSH + Docker** (junto a n8n).

## Arquitectura (Enfoque B — desacoplado)

- **Extractor:** contenedor Docker en el VPS de Hostinger, alcanzable por n8n en la red local. `POST /extract` sin cambios en su código.
- **Ingesta CSF — lógica aislada (sub-workflow vía Execute Workflow, o rama dedicada):** recibe el PDF → extrae → escribe el resultado estructurado en `whatsapp_sessions.captured_data`.
  - ⚠️ **Importante (restricción de un solo WhatsApp Trigger por Facebook App):** el documento PDF llega al **MISMO** WhatsApp Trigger que los mensajes de texto — NO se crea un segundo trigger. El workflow principal **ramifica por tipo de mensaje** (documento → ingesta CSF; texto → flujo normal). "Sub-workflow" aquí = aislamiento lógico (idealmente un workflow separado invocado con **Execute Workflow**), no un trigger nuevo. El Agente n8n decide el mecanismo exacto (Execute Workflow vs rama interna).
- **Bot principal (cambio mínimo):** `Load Session` ya selecciona `captured_data`. El AI Agent: si hay datos CSF → resumen + confirmación + pide solo lo que falta (vehículo). Si no → captura manual como hoy.

## Flujo de datos

```
Usuario (en captura) → manda PDF por WhatsApp
  └─[Sub-workflow CSF Ingestion]
       doc → descarga media (Meta Graph API vía media_id) → POST /extract (PDF+phone+session)
       → JSON {rfc, curp, nombre, apellidos, domicilio…, confidence, needs_review}
       → deriva fecha_nacimiento + género del CURP (determinista)
       → UPDATE whatsapp_sessions SET captured_data = <objeto estructurado> WHERE session_id
       → mensaje al usuario: "Listo, ya leí tu constancia, revisa tus datos 👇"
  └─[Bot principal] Load Session lee captured_data
       → resumen para confirmar/corregir
       → pide solo el vehículo (serie/placas)
       → Validate → Issue_Policy  (con Opción B del Bug #10: serie sale de captured_data)
```

## Componentes e interfaces

- **`POST /extract`** (extractor, sin cambios): multipart `file` (PDF ≤5MB) + `phone` + `session` → JSON con rfc, curp, nombre, primer/segundo apellido, codigo_postal, tipo/nombre vialidad, exterior, interior, colonia, localidad, municipio, entidad_federativa, fechas, estatus, regimenes, actividades, `confidence`, `needs_review`.
- **`captured_data` (esquema estructurado)** — se vuelve el **store canónico de captura**: `{nombre, primer_apellido, segundo_apellido, fecha_nacimiento, genero, rfc, calle, numero_exterior, numero_interior, colonia, codigo_postal, municipio, estado, fuente:"csf", confidence, extracted_at}`. Es la misma pieza que arregla el **Bug #5** (`captured_data` hoy `{}`) y habilita la **Opción B del Bug #10** (mapeo rígido: `Issue_Policy` lee `serie` de un store confiable en vez de re-extraer por `$fromAI`).
- **Descarga de media de Meta:** el WhatsApp Trigger entrega `media_id`; un nodo HTTP lo baja del Graph API y lo manda al extractor.
- **Derivación CURP → fecha_nacimiento + género:** determinista (CURP posiciones 5-10 = AAMMDD, posición 11 = H/M). Unit-test.

## Manejo de errores / fallbacks (el "no rompamos nada")

La ruta CSF es **aditiva y opcional**. Ante CUALQUIER fallo, el flujo manual actual es el fallback y **nunca se elimina**.
- Foto en vez de PDF (content-type ≠ application/pdf) → "necesito el PDF oficial del SAT, no una foto" + ofrece manual.
- `ok:false` / falta RFC / `confidence` baja / persona moral → NO autocompletar → caer a captura manual (nunca datos-basura parciales).
- Extractor caído / timeout → caer a manual (el bot nunca se traba).
- Confirmación obligatoria: el usuario corrige cualquier campo antes de emitir.

## Testing (dependencia dura)

**Solo se puede probar de forma segura en el entorno de STAGING (Fase 1)** — número de test de Meta → n8n staging → extractor staging → `captured_data` staging → confirmar. **No se puede probar en prod sin arriesgar.** Esta feature está **gated en montar la Fase 1 del entorno de pruebas** (ver `entorno-pruebas-staging.md`).
Casos: CSF válida (persona física), foto (rechazada), persona moral (fallback), PDF ilegible/`confidence` baja (fallback), extractor caído (fallback), usuario corrige un campo, CURP→fecha/género (unit-test determinista).

## Ownership y despliegue

| Artefacto | Qué es | Quién lo hace | Cómo llega a prod |
|---|---|---|---|
| Sub-workflow CSF Ingestion + cambio mínimo al bot | JSON n8n | **Agente n8n** (spec/handoff del Arquitecto) | Alberto lo importa en n8n |
| Extractor | Contenedor Docker | **Alberto + Arquitecto (infra)** | `docker run`/compose en el VPS Hostinger |

## Dependencias / secuencia (antes de que el Agente n8n implemente)

1. **Desplegar el extractor** en el VPS Hostinger (Docker) — runbook a preparar (build de imagen, `docker run`/compose, env vars incl. Supabase, puerto, reachability desde n8n).
2. **Montar Staging Fase 1** (para probar sin romper prod).
3. Entonces: sub-workflow + bridge a `captured_data` + cambio mínimo en el bot principal (Agente n8n).

## Notas

- **Supabase:** el extractor persiste en Supabase (`sat_documents`/`sat_extractions`) como auditoría propia. n8n usa el **JSON de la respuesta HTTP**, no depende de Supabase. Se puede mantener como está (auditoría) o hacerlo opcional más adelante; no bloquea.
- **email/teléfono:** ya vienen de `get_quotation_data` (no son manuales hoy) — la CSF no los necesita.
