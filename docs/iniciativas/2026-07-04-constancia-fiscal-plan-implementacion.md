# Constancia de Situación Fiscal (CSF) en n8n — Plan de Implementación

> Basado en la spec `2026-07-04-constancia-fiscal-integracion-n8n-design.md` (aprobada).
> **Ecosistema multi-ejecutor:** las fases tienen dueño distinto (infra = Alberto+Arquitecto; workflows = Agente n8n). No es un plan de un solo repo con TDD pytest; cada fase termina en un entregable verificable.

**Goal:** Que un lead suba su Constancia de Situación Fiscal (PDF SAT) durante la captura y el bot autocomplete sus datos personales + domicilio + RFC (y fecha_nac/género derivados del CURP), con confirmación obligatoria antes de emitir.

**Architecture:** Enfoque desacoplado (B). Extractor Docker en el VPS Hostinger (junto a n8n). Ingesta CSF aislada (Execute Workflow) que escribe a `whatsapp_sessions.captured_data`. El bot principal solo lee `captured_data`.

**Tech Stack:** FastAPI/Docker (extractor, ya construido), n8n (workflows), Postgres Heroku (`whatsapp_sessions.captured_data`), Meta WhatsApp Cloud API (descarga de media).

## Global Constraints (aplican a TODAS las tareas)

- **Extractor:** solo PDF (`application/pdf`), ≤5MB, **persona física** (`v2-persona-fisica`), escucha en **puerto 8000**, requiere env `SUPABASE_URL` y `SUPABASE_SECRET_KEY`.
- **Contrato `/extract` (v3, vigente):** `POST` multipart `file`+`phone`+`session` → JSON con `ok, rfc, curp, nombre, primer_apellido, segundo_apellido, codigo_postal, tipo_vialidad, nombre_vialidad, exterior, interior, colonia, localidad, municipio, entidad_federativa, fecha_emision, fecha_inicio_operaciones, estatus, regimenes, actividades, confidence, needs_review`.
- **NO correr `setup.sh` del repo** — regenera una versión vieja (v1-regex, persona moral) y pisa el código actual.
- **La ruta CSF es ADITIVA y OPCIONAL:** ante cualquier fallo (foto, PDF ilegible, `ok:false`, `confidence` baja, persona moral, extractor caído/timeout) → **fallback a captura manual**. El flujo manual actual nunca se elimina.
- **Confirmación SIEMPRE** antes de emitir (resumen de todos los datos, el usuario confirma/corrige), sin importar `confidence`.
- **Testing solo en Staging (Fase 1 del entorno de pruebas)** — jamás probar en prod.
- Zona horaria: `timestamptz`/UTC en BD; convertir a México solo al mostrar.

---

## Fase 0 — Precondición externa: Staging Fase 1

La implementación se puede **construir** sin staging, pero **no se puede probar ni desplegar a prod** sin él. Ver `entorno-pruebas-staging.md` (2 huecos: pestaña Test dashboard + sandbox Quálitas). Esta feature es un motivo más para montar staging.

**Bloquea:** Fase 3 (testing E2E) y el paso a prod. NO bloquea Fase 1 (deploy extractor) ni el desarrollo de los workflows (Fase 2/3), que se pueden preparar antes.

---

## Fase 1 — Desplegar el extractor en el VPS Hostinger (dueño: Alberto + Arquitecto)

**Entregable:** el extractor corriendo como contenedor, alcanzable por n8n en `http://insurmind-extractor:8000`, con `/health` OK.

- [ ] **Paso 1 — Clonar el repo en el VPS** (SSH):
  ```bash
  ssh <usuario>@srv1325340.hstgr.cloud
  git clone https://github.com/aibanez82/insurmind_extractor.git
  cd insurmind_extractor
  ```
- [ ] **Paso 2 — Crear `.env`** (NO commitear; `.gitignore` ya lo excluye) con las credenciales de Supabase:
  ```bash
  cat > .env <<'EOF'
  SUPABASE_URL=<tu-url-supabase>
  SUPABASE_SECRET_KEY=<tu-secret-key-supabase>
  EOF
  ```
- [ ] **Paso 3 — Identificar la red Docker de n8n** (para que n8n alcance el extractor por nombre de contenedor):
  ```bash
  docker inspect -f '{{range $k,$v := .NetworkSettings.Networks}}{{$k}}{{end}}' <nombre-contenedor-n8n>
  ```
  Anota el nombre de red (ej. `root_default` o similar).
- [ ] **Paso 4 — Build de la imagen:**
  ```bash
  docker build -t insurmind-extractor .
  ```
- [ ] **Paso 5 — Correr el contenedor en la MISMA red de n8n** (reemplaza `<red-n8n>`):
  ```bash
  docker run -d --name insurmind-extractor --restart unless-stopped \
    --network <red-n8n> --env-file .env insurmind-extractor
  ```
  (No hace falta publicar puerto al host; n8n lo alcanza por la red interna.)
- [ ] **Paso 6 — Verificar `/health` desde la red de n8n:**
  ```bash
  docker exec <nombre-contenedor-n8n> sh -c "wget -qO- http://insurmind-extractor:8000/health"
  ```
  Esperado: `{"status":"ok","service":"insurmind-extractor"}`
- [ ] **Paso 7 — Verificar `/extract` con un PDF real de constancia** (persona física):
  ```bash
  curl -s -X POST http://insurmind-extractor:8000/extract \
    -F "file=@constancia_prueba.pdf;type=application/pdf" \
    -F "phone=5218717955153" -F "session=test-session" | python3 -m json.tool
  ```
  Esperado: JSON con `rfc`, `curp`, `nombre`, domicilio y `ok:true`.
- [ ] **Paso 8 — Registrar la URL interna** para los workflows: `http://insurmind-extractor:8000/extract`. (Si Alberto prefiere URL pública/otra red, ajustar aquí — es el único valor que consume la Fase 2.)

---

## Fase 2 — Workflow "CSF Ingestion" (dueño: Agente n8n; handoff del Arquitecto)

**Entregable:** un workflow n8n (invocado con **Execute Workflow** desde el bot principal cuando llega un documento) que descarga el PDF, extrae, deriva CURP y escribe `whatsapp_sessions.captured_data`.

> ⚠️ **Restricción de un solo WhatsApp Trigger por Facebook App:** este workflow NO tiene su propio WhatsApp Trigger. El documento llega al trigger del bot principal, que ramifica por tipo de mensaje (documento → invoca este workflow con Execute Workflow, pasándole `media_id`, `phone`, `session_id`). Ver Fase 3.

**Interfaces:**
- **Consume:** `{ media_id, phone, session_id }` (del bot principal).
- **Produce:** fila actualizada en `whatsapp_sessions.captured_data` (objeto estructurado, ver Paso 5) + un flag de resultado para que el bot sepa si autocompletar o caer a manual.

- [ ] **Paso 1 — Descargar el media de Meta.** Dos llamadas al Graph API (credencial WhatsApp existente):
  1. `GET https://graph.facebook.com/v21.0/{media_id}` → devuelve `{ url, mime_type, ... }`.
  2. `GET {url}` con header `Authorization: Bearer <META_ACCESS_TOKEN>` → bytes del PDF (binary).
  - Validar `mime_type == "application/pdf"`. Si no → devolver flag `fallback:"not_pdf"` y terminar (el bot pedirá manual).
- [ ] **Paso 2 — Llamar al extractor.** HTTP Request node: `POST http://insurmind-extractor:8000/extract`, multipart: `file` = binario del PDF, `phone` = phone, `session` = session_id. Timeout 30s; **onError → continuar** (no lanzar). Si error/timeout → flag `fallback:"extractor_down"`, terminar.
- [ ] **Paso 3 — Evaluar el resultado.** Si `ok == false` o `rfc == null` o `confidence < 0.75` (o `needs_review == true`) → flag `fallback:"low_confidence"`, terminar (bot pide manual). Nunca escribir datos parciales dudosos.
- [ ] **Paso 4 — Derivar fecha_nacimiento + género del CURP** (Code node determinista). Código EXACTO:
  ```js
  // CURP: 4 letras + AAMMDD + sexo(H/M) + 5 letras + [dígito|letra](homoclave) + dígito
  function derivarDeCURP(curp) {
    if (!curp || curp.length !== 18) return { fecha_nacimiento: null, genero: null };
    const yy = curp.substring(4, 6);
    const mm = curp.substring(6, 8);
    const dd = curp.substring(8, 10);
    const sexoChar = curp.charAt(10);           // H o M
    const homoclave = curp.charAt(16);          // dígito => <2000 ; letra => >=2000
    const siglo = /[0-9]/.test(homoclave) ? '19' : '20';
    const genero = sexoChar === 'H' ? 'M' : (sexoChar === 'M' ? 'F' : null); // Issue_Policy usa M/F
    const fecha_nacimiento = `${siglo}${yy}-${mm}-${dd}`; // YYYY-MM-DD
    return { fecha_nacimiento, genero };
  }
  const d = derivarDeCURP($json.curp);
  return [{ json: { ...$json, ...d } }];
  ```
  Casos de prueba (validar el Code node manualmente antes de seguir):
  - `HEGL830412MDFRRR08` → `{fecha_nacimiento:"1983-04-12", genero:"F"}` (M en pos 10 → Femenino → "F").
  - `SASH610226HDFNNN01` → `{fecha_nacimiento:"1961-02-26", genero:"M"}` (H → Masculino → "M").
  - `PEGA050101HDFRRR0A` → `{fecha_nacimiento:"2005-01-01", genero:"M"}` (homoclave letra → siglo 20).
  - `null` / longitud ≠ 18 → `{fecha_nacimiento:null, genero:null}` (no romper).
  > Ojo: el bot mapea género como `M`/`F` (ver `Issue_Policy`). En CURP `H`=hombre → `"M"` (Masculino), `M`=mujer → `"F"` (Femenino). No confundir la letra del CURP con el valor final.
- [ ] **Paso 5 — Construir el objeto `captured_data` y escribirlo.** Postgres node, `UPDATE whatsapp_sessions SET captured_data = $1::jsonb WHERE session_id = $2`. El objeto:
  ```json
  {
    "nombre": "<nombre>", "primer_apellido": "<primer_apellido>", "segundo_apellido": "<segundo_apellido>",
    "fecha_nacimiento": "<YYYY-MM-DD>", "genero": "<M|F>", "rfc": "<rfc>",
    "calle": "<tipo_vialidad + nombre_vialidad>", "numero_exterior": "<exterior>", "numero_interior": "<interior>",
    "colonia": "<colonia>", "codigo_postal": "<codigo_postal>", "municipio": "<municipio>", "estado": "<entidad_federativa>",
    "fuente": "csf", "confidence": <confidence>, "extracted_at": "<now UTC ISO8601>"
  }
  ```
- [ ] **Paso 6 — Mensaje al usuario** (WhatsApp Send): *"✅ Ya leí tu constancia. Ahora revisa que tus datos estén correctos 👇"* (el resumen y confirmación los produce el bot principal en Fase 3, no este workflow).
- [ ] **Paso 7 — Entrega:** commit/push del JSON a su repo; documentar nodos y rutas. Alberto importa en n8n **staging** primero.

---

## Fase 3 — Cambio mínimo al bot principal (dueño: Agente n8n)

**Entregable:** el bot ofrece la subida al inicio de la captura, ramifica documentos hacia CSF Ingestion, y usa `captured_data` para confirmar + pedir solo lo que falta.

- [ ] **Paso 1 — Ramificar por tipo de mensaje en el trigger.** Tras el WhatsApp Trigger, añadir una rama: si el mensaje es **documento** (PDF), invocar **Execute Workflow → "CSF Ingestion"** con `{media_id, phone, session_id}`; si es **texto**, seguir el flujo normal.
- [ ] **Paso 2 — systemMessage del AI Agent (2 cambios):**
  1. Al iniciar la captura (Grupo 1), ofrecer: *"Para agilizar, ¿quieres subir tu Constancia de Situación Fiscal (el PDF del SAT) y lleno tus datos automáticamente? O si prefieres, me los das uno a uno."*
  2. Instrucción: si `captured_data` (de `Load Session`) trae `fuente:"csf"` con datos → **mostrar un resumen de TODOS esos datos y pedir confirmación/corrección**, y luego pedir **solo el vehículo (serie/placas)** — no volver a pedir personales/domicilio. Si el usuario corrige algo, usar el valor corregido.
- [ ] **Paso 3 — Fallback:** si CSF Ingestion devolvió un flag de fallback (not_pdf / extractor_down / low_confidence), el bot informa amablemente y **continúa con captura manual** como hoy.
- [ ] **Paso 4 — Entrega:** commit/push; Alberto importa en staging.

---

## Fase 4 — Testing E2E en Staging (dueño: Alberto + Arquitecto)

**Precondición:** Staging Fase 1 arriba + extractor desplegado (Fase 1) + workflows importados en staging (Fases 2-3).

Casos (mandar desde el número de test de Meta a n8n staging):
- [ ] **CSF válida (persona física):** subir PDF real → verificar `whatsapp_sessions.captured_data` poblado correcto (nombre, domicilio, rfc, fecha_nac/género del CURP) → bot muestra resumen → confirmar → pide serie/placas → emite en sandbox Quálitas con datos correctos.
- [ ] **Foto en vez de PDF:** enviar imagen → bot responde "necesito el PDF, no foto" → cae a manual.
- [ ] **Persona moral / PDF ilegible / confidence baja:** → cae a manual, sin datos basura.
- [ ] **Extractor caído:** parar el contenedor → subir PDF → bot cae a manual sin trabarse.
- [ ] **Usuario corrige un campo** del resumen → el valor corregido es el que se emite.
- [ ] **CURP→fecha/género:** verificar los 3 casos del Paso 4 de Fase 2 con constancias reales.

Solo tras pasar todos → importar workflows a prod (junto con el resto), extractor ya desplegado.

---

## Riesgos / notas
- **Supabase:** el extractor persiste ahí (auditoría propia); n8n usa la respuesta HTTP, no depende de Supabase. Requiere que las credenciales Supabase estén en el `.env` del contenedor.
- **`calle`:** la CSF trae `tipo_vialidad` + `nombre_vialidad` por separado; concatenar para `calle` (o mantener separados si el flujo de emisión los pide así — verificar contra lo que espera `Issue_Policy`).
- **Coincidencia con Bug #10 Opción B:** una vez `captured_data` existe y es confiable, `Issue_Policy` debería leer `serie` (y estos campos) de `captured_data` en vez de re-extraer con `$fromAI`. Tarea separada, pero este trabajo la habilita.
