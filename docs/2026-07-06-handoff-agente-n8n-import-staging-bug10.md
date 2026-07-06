# Handoff Arquitecto → Agente n8n — Import del workflow (fix Bug #10) a la instancia de staging

> Autor: Arquitecto-IA-Qualitas · 6 jul 2026
> Ejecutor: **Agente n8n** (end-to-end vía API — decisión de Alberto 6 jul).
> Gobernanza: el Agente n8n reporta resultados al Arquitecto **a través de Alberto**. No habla con otros agentes.
> Iniciativa madre: `docs/iniciativas/entorno-pruebas-staging.md`.

## Objetivo

Importar el workflow principal del bot (con el fix del Bug #10 ya aplicado) a la **instancia n8n de staging**, dejándolo **inactivo**, con todas las referencias repuntadas a gemelos de staging (nunca prod). Fin último: validar el Bug #10 end-to-end en staging antes de mergear a prod.

## Instancia de staging (destino)

- **UI/API base:** `https://n8n-xlqk.srv1810257.hstgr.cloud`
- **API:** REST `…/api/v1/…`, header `X-N8N-API-KEY`. Estado verificado: viva (`/healthz` 200), **vacía (0 workflows)**.
- **Aislada de prod:** servidor Hostinger `srv1810257` ≠ prod `srv1325340`; BD n8n y encryption key propias. (Cierra el riesgo del Bug #12.)

**Secretos a provisionar en TU proyecto (Agente n8n) — Alberto los pone en tu `.env.local` (gitignored):**
- `N8N_STG_API_KEY` — API key de ESTA instancia (Settings → n8n API). Distinta de la de prod.
- `STG_DATABASE_URL` — `postgres://…` del addon de `hyl-wai-stg` (solo para verificación; la credencial ya está creada, ver abajo).

## Fuente del JSON

- Repo: `aibanez82/Agente-n8n` · rama **`stg`** · archivo **`workflows/WhatsApp Insurance Quotation Bot.json`**.
- Contiene la cadena de commits del Bug #10 (`591569f` Opción A → `a5da2e2` neverError → `2570dea` línea load-bearing → `d370365` reconcile VIN-17 → …). HEAD verificado `405cec3`.

## Diagnóstico del JSON (hecho por el Arquitecto — NO re-investigar)

1. **El fix está correcto en los nodos vivos.** `.nodes[12] 'Validate Personal Data'` tiene la regex VIN-17 canónica `^[A-HJ-NPR-Z0-9]{8}[0-9X][A-HJ-NPR-Z0-9]{8}$`. `{5,20}` = **0** en `.nodes`. Los "5-20" que aparecen en un grep crudo son las fechas de model-IDs (`claude-*-4-5-2025…`), falsos positivos.
2. **El JSON es un export estilo-BD, NO importable tal cual.** 19 claves top-level: `updatedAt, createdAt, name, description, active, isArchived, nodes, connections, settings, staticData, meta, pinData, versionId, activeVersionId, versionCounter, triggerCount, shared, tags, activeVersion`.
3. **`.activeVersion`** es un snapshot duplicado (61 nodos) que arrastra el único `{5,20}` stale y `workflowPublishHistory`. **Se descarta al reducir.**
4. **`pinData`** presente en `WhatsApp Message Trigger` → PII; **se descarta al reducir.**

## Transform a aplicar (spec exacto)

**Paso 1 — reducir a la forma de import** (esto solo ya elimina `activeVersion`+5-20 stale y `pinData`):
```
workflow_import = { name, nodes, connections, settings }   // descartar TODO lo demás
```
`settings` puede quedar `{}` si no existe. NO enviar `active`, `id`, `tags`, `shared`, `pinData`, `activeVersion`, `versionId`, etc. (el POST los rechaza). El `name` ya es `WhatsApp Insurance Quotation Bot_stg` ✅.

**Paso 2 — remap de credenciales** (en cada nodo de `.nodes`, sustituir el bloque `credentials`):

| type | id prod (a reemplazar) | destino en staging |
|---|---|---|
| `postgres` | `FbodkhT9DijVcqpB` | ✅ **YA creada: id `5wlLe3gD07CLIM7U`, name "Postgres STG"** — reusar este id |
| `anthropicApi` | `aWrCOYz0wHIk5GSd` | crear en stg (key prod reusable → `STG_ANTHROPIC_KEY`) y usar el id nuevo |
| `whatsAppTriggerApi` | `bUWR11VM0seHo63P` | crear en stg desde la **2ª Meta App (test)** — ⏳ bloqueado |
| `whatsAppApi` | `PbzXr53disA74eew` | crear en stg desde la **2ª Meta App (test)** — ⏳ bloqueado |

> El bot principal usa 4 credenciales. `httpHeaderAuth` ("Header Auth account") NO está en este workflow — vive en el de Payment Confirmation (fuera de este handoff).

**Paso 3 — reescrituras de parámetros hardcodeados** (en `.nodes`):
- `seguroautoqualitas.com` (×4, incl. el tool `Issue Policy` → `/api/emitir-externo/`) → **`hyl-wai-stg-d1085ad74dbf.herokuapp.com`** (host de `hyl-wai-stg`).
- `1028815256982638` (×3, phoneNumberId WhatsApp) → phoneNumberId del número de test. ⏳ Hasta tener la Meta App, poner un placeholder inequívoco (p. ej. `STG_PHONE_NUMBER_ID_PENDING`) para que un envío accidental falle en vez de pegar al número de prod.

**Paso 4 — import inactivo:** `POST /api/v1/workflows`. Verificar 200 + id. NO activar hasta tener las 2 credenciales WhatsApp y validar.

## Receta de creación de credenciales por API (validada por el Arquitecto)

- Endpoint: `POST /api/v1/credentials` con `{name, type, data}`. Esquema por tipo: `GET /api/v1/credentials/schema/{type}`.
- **Postgres (ya hecha, NO recrear):** type `postgres`, `data` con host/database/user/password/port + **`ssl:"require"` y `allowUnauthorizedCerts:true`** (Heroku Postgres usa cert self-signed). Parseada de `STG_DATABASE_URL`.
- **Anthropic:** type `anthropicApi`, `data:{ apiKey: STG_ANTHROPIC_KEY }`. Reusar la key de prod es válido (las llamadas LLM no tienen efectos secundarios).
- **WhatsApp (Trigger y Send):** desde la 2ª Meta App de test (access token, phoneNumberId, verify token/app secret). ⏳ Bloqueado hasta que Alberto cree la Meta App.

## Bloqueador upstream (fuera de tu control)

**2ª Meta App + número de test** (Meta Business, tarea de Alberto). De ahí salen las 2 credenciales WhatsApp y el phoneNumberId real. **Puedes avanzar SIN ella:** importa el workflow reducido con Postgres+Anthropic repuntadas, Django reescrito, phoneNumberId placeholder, inactivo. Las 2 creds WhatsApp y la activación quedan pendientes de la Meta App.

## Verificación al terminar (reportar al Arquitecto vía Alberto)

1. `GET /api/v1/workflows` → aparece `WhatsApp Insurance Quotation Bot_stg`, id nuevo, inactivo.
2. Confirmar que ningún nodo referencia ids/hosts de prod (`FbodkhT9DijVcqpB`, `seguroautoqualitas.com`, `1028815256982638`, `bUWR11VM…`, `PbzXr53…`).
3. Confirmar 0 `{5,20}` y regex VIN-17 presente en el nodo `Validate Personal Data` importado.
4. Reportar: id del workflow importado, ids de credenciales creadas, qué quedó pendiente por la Meta App.

## Después (no en este handoff)
- Importar los otros 2 workflows (Payment Confirmation, Retomar Conversacion) — necesitan `httpHeaderAuth` + Postgres + WhatsApp.
- E2E: "hola" desde número verificado → captura → serie mala (re-pregunta 2-3×) → emisión sandbox Quálitas → simular webhook de pago.
- Merge `stg`→`main` + re-export a `docs/n8n-workflows/` cuando pase E2E.
