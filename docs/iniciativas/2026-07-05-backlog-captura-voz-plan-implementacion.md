# Backlog por captura de voz (Telegram → Claude → Notion) — Plan de Implementación

> Basado en la spec `2026-07-05-backlog-captura-voz-telegram-notion-design.md` (aprobada).
> Es un **build de workflow n8n** (no un repo con pytest). Ejecutor: Alberto directo en n8n, o el Agente n8n. Cada tarea termina en un entregable verificable.

**Goal:** Que Alberto mande una nota de voz (o texto) a un bot de Telegram y quede una idea/pendiente clasificada y guardada en una base de Notion, con confirmación de vuelta.

**Architecture:** Un workflow n8n con Telegram Trigger → (si voz) OpenAI Whisper transcribe → Claude clasifica (structured output) → crea página en Notion → responde en Telegram.

**Tech Stack:** n8n (Hostinger), Telegram Bot API, OpenAI Whisper (`whisper-1`), Anthropic Messages API (`claude-haiku-4-5`, structured outputs), Notion API.

## Global Constraints

- **Claude no transcribe audio** → la voz pasa SIEMPRE por Whisper primero.
- **Notion es el store** (no mover a Juan de Notion). Base compartida.
- **Multiusuario desde el diseño:** el campo `Autor` se rellena mapeando el **Telegram user id** → Alberto/Juan. Habilita la Fase B sin rediseño.
- **Nunca perder una nota en silencio:** ante fallo (transcripción vacía, Claude/Notion caído) → el bot avisa.
- **Modelo del clasificador:** `claude-haiku-4-5` (tarea simple, rápido y barato). Structured output vía `output_config.format` (json_schema).
- Herramienta interna → se prueba sola, NO depende del staging de Quálitas.
- Categorías: **Técnico / Producto (feature) / Negocio**. Prioridad: Alta/Media/Baja. Estado default: Idea.

---

## Task 1 — Prerrequisitos y credenciales

**Entregable:** bot de Telegram creado, base de Notion con el esquema + integración, keys listas, user ids capturados.

- [ ] **Paso 1 — Crear el bot de Telegram.** En Telegram, hablar con `@BotFather` → `/newbot` → nombre y username → guardar el **token** (`123456:ABC...`).
- [ ] **Paso 2 — Obtener tu Telegram user id.** Enviar cualquier mensaje al bot, luego:
  ```bash
  curl -s "https://api.telegram.org/bot<TOKEN>/getUpdates" | python3 -m json.tool
  ```
  Anota `message.from.id` (tu id numérico). (Repetir con Juan cuando entre en Fase B.)
- [ ] **Paso 3 — Crear la base de Notion** con estas propiedades (exactas):
  - `Título` (title), `Descripción` (text), `Categoría` (select: `Técnico`, `Producto`, `Negocio`), `Prioridad` (select: `Alta`, `Media`, `Baja`), `Estado` (select: `Idea`, `Por hacer`, `En curso`, `Hecho`), `Autor` (select: `Alberto`, `Juan`), `Dueño` (select: `Alberto`, `Juan`, `Sin asignar`), `Fecha` (date), `Transcripción cruda` (text).
- [ ] **Paso 4 — Crear la integración de Notion** (notion.so/my-integrations → New integration) → guardar el **Internal Integration Token** (`secret_...` / `ntn_...`). En la base creada: `•••` → Connections → añadir la integración. Anota el **Database ID** (de la URL de la base, los 32 chars).
- [ ] **Paso 5 — API key de OpenAI** (para Whisper) desde platform.openai.com. La key de Anthropic ya está en n8n.
- [ ] **Verificar:** con `curl` la query de `getUpdates` devuelve tu id; la base de Notion existe con las 9 propiedades; la integración aparece en Connections de la base.

---

## Task 2 — Workflow n8n: Telegram Trigger + transcripción

**Entregable:** el workflow recibe la nota, y si es voz la transcribe a texto.

**Interfaces:**
- Produce (para tareas siguientes): `texto` (string, la nota transcrita o el texto crudo), `telegram_user_id` (number), `chat_id` (para responder).

- [ ] **Paso 1 — Telegram Trigger.** Nodo `Telegram Trigger` con la credencial del token (Task 1). Updates: `message`. Esto dispara con cada mensaje al bot.
- [ ] **Paso 2 — Ramificar voz vs texto.** Nodo `IF`: `{{ $json.message.voice }}` existe → rama VOZ; si no → rama TEXTO (usa `{{ $json.message.text }}`).
- [ ] **Paso 3 (rama VOZ) — Descargar el audio.** Nodo `Telegram` → resource `File`, operation `Get`, `File ID` = `{{ $json.message.voice.file_id }}`. Devuelve el binario `.ogg`.
- [ ] **Paso 4 (rama VOZ) — Transcribir con Whisper.** Nodo `OpenAI` → resource `Audio`, operation `Transcribe`, modelo `whisper-1`, input = el binario del paso anterior, idioma `es`. Salida: `text`.
- [ ] **Paso 5 — Unificar.** Un nodo `Set` (o Merge) que deje en un campo común `texto` = transcripción (rama voz) o `message.text` (rama texto), más `telegram_user_id = {{ $json.message.from.id }}` y `chat_id = {{ $json.message.chat.id }}`.
- [ ] **Verificar:** activar el workflow, mandar una nota de voz al bot → en la ejecución de n8n, el campo `texto` contiene la transcripción correcta en español. Probar también con un mensaje de texto.

---

## Task 3 — Clasificación con Claude (structured output)

**Entregable:** de `texto`, obtener un JSON estructurado que encaja en el esquema de Notion.

**Interfaces:**
- Consume: `texto` (string).
- Produce: `clasificacion` = `{ titulo, descripcion, categoria, prioridad, dueno }` (todos string; `categoria` ∈ Técnico/Producto/Negocio; `prioridad` ∈ Alta/Media/Baja; `dueno` ∈ Alberto/Juan/Sin asignar).

- [ ] **Paso 1 — Nodo HTTP Request a Anthropic.** `POST https://api.anthropic.com/v1/messages`. Headers: `x-api-key: <ANTHROPIC_KEY>`, `anthropic-version: 2023-06-01`, `content-type: application/json`. Body (JSON):
  ```json
  {
    "model": "claude-haiku-4-5",
    "max_tokens": 1024,
    "system": "Eres el clasificador del backlog de un proyecto de software (bot de seguros WhatsApp/Quálitas). Recibes una idea o pendiente dictado por voz. Devuelve título corto (≤80 chars), una descripción limpia (reformula la transcripción, corrige dictado), la categoría, la prioridad sugerida y el dueño si se menciona explícitamente (si no, 'Sin asignar'). Categoría: 'Técnico' (bugs, deuda técnica, infra), 'Producto' (nuevas funcionalidades del bot/dashboard/landing) o 'Negocio' (crecimiento, procesos, no-código). Prioridad: 'Alta'/'Media'/'Baja'.",
    "messages": [{ "role": "user", "content": "{{ $json.texto }}" }],
    "output_config": {
      "format": {
        "type": "json_schema",
        "schema": {
          "type": "object",
          "additionalProperties": false,
          "required": ["titulo", "descripcion", "categoria", "prioridad", "dueno"],
          "properties": {
            "titulo": { "type": "string" },
            "descripcion": { "type": "string" },
            "categoria": { "type": "string", "enum": ["Técnico", "Producto", "Negocio"] },
            "prioridad": { "type": "string", "enum": ["Alta", "Media", "Baja"] },
            "dueno": { "type": "string", "enum": ["Alberto", "Juan", "Sin asignar"] }
          }
        }
      }
    }
  }
  ```
- [ ] **Paso 2 — Parsear la respuesta.** El texto estructurado viene en `content[0].text` (string JSON garantizado por `output_config.format`). Nodo `Code`:
  ```js
  const raw = $json.content[0].text;
  const c = JSON.parse(raw);
  return [{ json: { ...$('Set').item.json, clasificacion: c } }];
  ```
  (Ajusta `$('Set')` al nombre real del nodo que trae `texto`/`telegram_user_id`/`chat_id`.)
- [ ] **Verificar:** con la transcripción de prueba, el JSON sale bien clasificado (p. ej. "hay que arreglar lo del VIN" → categoría `Técnico`, prioridad `Alta`).

---

## Task 4 — Crear la página en Notion (con Autor por Telegram id)

**Entregable:** una fila nueva en la base de Notion con todas las propiedades.

**Interfaces:**
- Consume: `clasificacion`, `texto` (transcripción cruda), `telegram_user_id`.

- [ ] **Paso 1 — Mapear Autor.** Nodo `Code`: mapear `telegram_user_id` → nombre.
  ```js
  const MAP = { /* <TU_TELEGRAM_ID>: 'Alberto', <ID_JUAN>: 'Juan' */ };
  const autor = MAP[$json.telegram_user_id] || 'Alberto';
  return [{ json: { ...$json, autor } }];
  ```
  (Rellenar `MAP` con tu id real de Task 1 Paso 2.)
- [ ] **Paso 2 — Crear página en Notion.** Nodo `Notion` → resource `Database Page`, operation `Create`, `Database ID` = el de Task 1. Propiedades:
  - `Título` (title) = `{{ $json.clasificacion.titulo }}`
  - `Descripción` (text) = `{{ $json.clasificacion.descripcion }}`
  - `Categoría` (select) = `{{ $json.clasificacion.categoria }}`
  - `Prioridad` (select) = `{{ $json.clasificacion.prioridad }}`
  - `Estado` (select) = `Idea`
  - `Autor` (select) = `{{ $json.autor }}`
  - `Dueño` (select) = `{{ $json.clasificacion.dueno }}`
  - `Fecha` (date) = `{{ $now }}`
  - `Transcripción cruda` (text) = `{{ $json.texto }}`
- [ ] **Verificar:** ejecutar → aparece la fila en Notion con todos los campos correctos y `Autor = Alberto`.

---

## Task 5 — Confirmación en Telegram + manejo de errores + E2E

**Entregable:** el bot confirma lo guardado y avisa ante fallos; flujo completo probado.

- [ ] **Paso 1 — Confirmación.** Nodo `Telegram` → operation `Send Message`, `Chat ID` = `{{ $json.chat_id }}`, texto:
  ```
  ✅ Guardado: [{{ $json.clasificacion.categoria }}] «{{ $json.clasificacion.titulo }}» · prioridad {{ $json.clasificacion.prioridad }} · dueño {{ $json.clasificacion.dueno }}
  ```
- [ ] **Paso 2 — Transcripción vacía.** Tras Whisper, un `IF`: si `texto` está vacío o < 3 chars → responder en Telegram "🎙️ No te entendí bien, ¿me lo repites?" y terminar (no llamar a Claude/Notion).
- [ ] **Paso 3 — Fallos de Claude/Notion.** En los nodos HTTP/Notion, `Settings → On Error → Continue`. Añadir una rama de error que responda en Telegram "⚠️ No pude guardar tu idea, reintenta en un momento." Así nunca se pierde en silencio.
- [ ] **Paso 4 — E2E (casos):**
  - Voz clara técnica ("arreglar lo del VIN") → Notion `Técnico`/`Alta`.
  - Voz de producto ("el agente tiene que tener nombre de persona") → `Producto`.
  - Voz de negocio ("homologar forma de trabajo con Juan") → `Negocio`.
  - Con dueño ("esto es para Juan") → `Dueño = Juan`.
  - Texto (no voz) → funciona igual.
  - Audio inaudible → pide repetir.
  - Notion desconectado (quitar la conexión) → avisa, no truena.
- [ ] **Paso 5 — Activar el workflow** (Active) y guardar/exportar el JSON a git (`docs/n8n-workflows/` o el repo del Agente n8n).

---

## Self-review (cobertura vs spec)
- Captura voz/texto → Task 2. Transcripción (Whisper, Claude no hace audio) → Task 2. Clasificación Claude structured → Task 3. Notion store + esquema → Task 1/Task 4. Autor por Telegram id (multiusuario/Fase B) → Task 4. Confirmación + errores → Task 5. Testing interno → Task 5. Dependencias → Task 1. **Cobertura completa.**

## Notas
- **Fase B (Juan):** solo hay que añadir el id de Juan al `MAP` de Task 4 y compartirle el bot. Cero rediseño.
- **Costo:** Haiku 4.5 + Whisper por nota es de centavos; volumen bajo (uso interno).
- Modelo del clasificador: si se quiere más criterio, subir a `claude-sonnet-4-6`; para clasificar basta Haiku.
