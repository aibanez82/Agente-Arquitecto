# Iniciativa — Entorno de pruebas / staging end-to-end

> Estado: **⛔ PAUSADA 7 jul 2026 — Bug #15: el número de WhatsApp de test comparte `phone_number_id` con producción.** Toda ejecución de prueba en staging se está duplicando en producción (escritura real en `n8n_chat_histories`/`whatsapp_sessions` de prod, aunque sin llegar a emisión). NO correr más pruebas hasta que Juan aísle de verdad el número de test en su propia WABA. Detalle: fila Bug #15 en `CLAUDE.md`.
> Guardado en git (no en memoria local) para persistir entre las 3 laptops de Alberto.

## Objetivo

Staging end-to-end para replicar bug fixes antes de subir a prod (gitflow: rama `stg` → `main`). El staging del 2 jul era parcial (ejecución manual con datos "pineados", no conversación WhatsApp real). Se busca cubrir **landing → conversación WhatsApp real → captura → emisión sandbox**.

## Principio rector

Stack paralelo completo; cada componente de staging apunta SOLO a gemelos de staging, nunca a prod. Riesgo #1 = un componente de staging escribiendo/disparando contra prod (p. ej. staging Django disparando al n8n de prod → WhatsApps reales a leads reales; o staging n8n escribiendo en la BD de prod, o llamando al Django de prod).

## Mapa prod → staging (actualizado 6 jul)

| Componente | Producción | Staging |
|---|---|---|
| Backend/landing | `hyl-wai-production` (`main`) | `hyl-wai-stg` (deploy desde `stg`) — ya existe |
| Base de datos | Heroku Postgres prod | Postgres addon PROPIO en `hyl-wai-stg` (jamás la BD prod) |
| n8n (bot WA) | Instancia Hostinger (`n8n.srv1325340.hstgr.cloud`), 3 workflows prod | **INSTANCIA n8n SEPARADA** (decisión 6 jul — ver abajo). NO más `_STG` en la misma instancia |
| Número WhatsApp | Número real (phoneNumberId `1028815256982638`) | **Segunda Meta App + número de test** de Cloud API (gratis, hasta 5 destinatarios verificados) |
| Quálitas | Endpoint productivo | Sandbox vía `QUALITAS_AMBIENTE_FLAG` — **pendiente confirmar con Juan** |
| Dashboard | Vercel prod (`main`) | **Vercel Preview con `DATABASE_URL`→BD stg** (decisión 6 jul) — entra en F2 |
| Pago | Link real Quálitas | Simular el webhook de confirmación (curl), no pagar |

## Decisiones tomadas

### 6 jul 2026 (al retomar)

1. **n8n = instancia SEPARADA (no misma instancia con `_STG`).**
   **Por qué cambió:** la decisión previa (4 jul) era "workflow `_STG` en la misma instancia". El **Bug #12** demostró que ese patrón es peligroso: los duplicados `_STG` compartían el `webhookId 18c1b498` con prod; al activar/desactivar un `_STG`, n8n des-registraba la ruta compartida y dejaba prod **huérfano** (`active:true` sin webhook). Fue el 2º apagón silencioso de inbound en una semana. El 5 jul se borraron los 12 duplicados y la instancia quedó solo con los 3 workflows de prod. Reintroducir `_STG` ahí repetiría el fallo recién erradicado.
   **Beneficio de instancia separada:** aislamiento total — sin `webhookId` compartido, sin credenciales globales compartidas (en n8n las credenciales son globales a la instancia). Elimina de raíz la clase de fallo del Bug #12.
   **Sub-decisión (fijada 6 jul):** la instancia de staging vivirá en **otra instancia de n8n en Hostinger** (separada de `n8n.srv1325340.hstgr.cloud`).
   ⚠️ **Requisito de aislamiento para que cuente como instancia separada:** debe ser un proceso n8n independiente con **su propia base de datos n8n** y **su propia `N8N_ENCRYPTION_KEY`** — no basta con reusar la misma BD/instancia n8n. Solo así el espacio de `webhookId` y las credenciales quedan aislados del prod y no puede recaer el Bug #12. Subdominio/puerto propio para el webhook base. Si es en el mismo VPS, ojo con la contención de recursos (no comparte estado, solo hardware).

2. **Dashboard test = Vercel Preview → BD stg.** Un Deploy Preview del dashboard con `DATABASE_URL` apuntando a la Postgres de staging. Es la única forma de que vea las conversaciones de staging y no las de prod. (Se mantiene en **F2** según el fasing.)

### 4 jul 2026 (previas, vigentes)

- **WhatsApp:** staging usa una **Meta App distinta** → webhook distinto → no choca con el trigger de prod. (Con instancia separada esto es aún más limpio.)
- **Quálitas:** existe la variable `QUALITAS_AMBIENTE_FLAG`, pero el flag ≠ las credenciales sandbox.

## Hallazgos del código `stg` (6 jul — leídos vía `gh` / GitHub API)

> El Arquitecto tiene acceso de **lectura al repo** `aguayo-co/HYL-WAI` vía `gh` (permiso `pull`). La nota del CLAUDE.md "PAT pendiente para código" está desactualizada. **NO** hay acceso a la Heroku Platform API (sin token) → los *valores reales* de config vars de `hyl-wai-stg` no son visibles; el código solo revela **qué vars lee y sus defaults**.

**Inventario de config vars que lee la app (rama `stg`):**

| Var | Fuente | Default en código | Qué hacer en staging |
|---|---|---|---|
| `WEBHOOK_URL` | `qualitas/views.py:904` | **PROD n8n** (`n8n.srv1325340.hstgr.cloud/.../payment-confirmation`) | 🔴 **DEBE** apuntar a la instancia n8n de staging. Si no, Django stg dispara al n8n de PROD → WhatsApps a leads reales |
| `N8N_TOKEN` | `qualitas/views.py:905` | ⚠️ token real hardcodeado en el código | usar el de la instancia stg; ver nota de seguridad |
| `QUALITAS_URL` (emisión) | `services.py:275/692/733` | `https://qa.qualitas.com.mx:8443/WsEmision/...` (**ya es QA**) | dejar default o apuntar a QA |
| `QUALITAS_WSDL_TARIFAS` (cotización) | `services.py:125/190` | `qbcenter.qualitas.com.mx/wsTarifa/...` (QA) | dejar default o QA |
| `QUALITAS_URL_OPL`, `QUALITAS_URL_PAGO` | `services.py:810/893` | — | endpoints de pago QA |
| `QUALITAS_USER_TARIFA`, `QUALITAS_PASSWORD_TARIFA` | `services.py:126/191` | — | credenciales QA (confirmar con Juan) |
| `QUALITAS_WPUID`, `QUALITAS_WPTOKEN` | `services.py:811/812/894` | — | credenciales pago QA |
| `QUALITAS_AGENTE`, `QUALITAS_NO_NEGOCIO`, `QUALITAS_DERECHO` | `services.py:476-478` | — | parámetros de negocio QA |
| `QUALITAS_AMBIENTE_FLAG` | `services.py:479` | `"1"` | **NO es el selector de ambiente** — es un valor SOAP (`NoConsideracion="4"/TipoRegla 1`). ✅ Confirmado 7 jul: `0` = prueba, ya seteado en Heroku `hyl-wai-stg` |
| `QUALITAS_BDEO_URL/USER/PASS` | `services.py:1022-1024` | — | inspección BDEO (si aplica) |
| `WHATSAPP_PHONE_NUMBER_ID`, `WHATSAPP_ACCESS_TOKEN` | `services.py:1094/1095` | — | Django también tiene creds Meta; en stg → número/app de test |
| `DATABASE_URL` | `settings/base.py:170` | — | Postgres addon PROPIO de stg |
| `AMBIENTE_PRUEBAS` | `settings/base.py:29` | `"0"` | **poner `"1"`** → muestra banner de entorno no-productivo |

**Corrección clave sobre Quálitas (invalida supuesto previo):** el selector sandbox↔prod es **`QUALITAS_URL`/`QUALITAS_WSDL_TARIFAS`**, NO `QUALITAS_AMBIENTE_FLAG`. El default del código ya es el entorno **QA** de Quálitas. Staging solo necesita endpoints QA + credenciales QA; el flag es una bandera *dentro* de Quálitas cuyo valor de "prueba" hay que confirmar con Juan.

**🔒 Nota de seguridad (para Juan):** `N8N_TOKEN` tiene un token real como default hardcodeado en `qualitas/views.py:905`. Mover a solo-env y **rotar** el token. (Añadir a Pendientes de infraestructura del CLAUDE.md.)

**Andamiaje de pruebas ya existente en el repo (reusar, no reinventar):** `docker/pruebas.env.example`, comandos `bootstrap_pruebas_local.py` y `poblar_pruebas_dummy.py` (datos dummy), `feature/test-environment-banner`, `feature/local-docker-pruebas-env`. El gate VIN del Bug #10 vive en `qualitas/vehicle_series.py` (rama `stg`); el follow-up del Issue #74 en `qualitas/whatsapp_followups.py` + comando `enviar_seguimientos_whatsapp.py`.

## Hueco pendiente (dependencia externa)

**✅ RESUELTO (7 jul, confirmado por Alberto):** (a) las credenciales QA (`QUALITAS_USER_TARIFA`/`QUALITAS_PASSWORD_TARIFA`/`QUALITAS_WPUID`/`QUALITAS_WPTOKEN`) ya están puestas en Heroku `hyl-wai-stg` y son válidas contra el sandbox QA de Quálitas; (b) `QUALITAS_AMBIENTE_FLAG = 0` es el valor de prueba (**corrige el supuesto previo** de que el default `"1"` del código era el de prueba — `0` ya está seteado en Heroku `hyl-wai-stg`); (c) el QA de Quálitas cubre cotización Y emisión completas. Ya no bloquea el paso 6 del runbook — solo falta repuntar el nodo `Issue Policy` de n8n a `hyl-wai-stg` (eso depende de la Meta App, no de Quálitas).

---

## RUNBOOK — Fase 1 (MVP)

> Cubre: landing stg → conversación WhatsApp real (número test) → captura → emisión sandbox.
> Bugs que permite replicar antes de prod: **#9 (emisión 400), #7 (pago), #8 (teléfono en XML)**. (El **#10** ya está resuelto del lado n8n; staging servirá para regresión.)

**Orden de ejecución (cada paso deja el anterior verificado):**

1. **Postgres staging.** Provisionar addon Postgres PROPIO en `hyl-wai-stg` (nunca la BD prod). Correr migraciones Django. Verificar: `hyl-wai-stg` levanta y `DATABASE_URL` de stg ≠ la de prod.

2. **Backend `hyl-wai-stg`.** Confirmar deploy desde rama `stg`. Verificar landing accesible. ✅ **`WEBHOOK_URL`/`N8N_TOKEN` corregidos (7 jul, Bug #16)** — ahora apuntan a la instancia n8n de staging con token propio (`STG_N8N_TOKEN` en `.env.local`). `AMBIENTE_PRUEBAS=1` ya estaba correcto.

3. **Instancia n8n separada.** Levantar según sub-decisión (a/b/c). Importar los **3 workflows de prod** (`WhatsApp Insurance Quotation Bot`, `Payment Confirmation`, `Retomar Conversacion`) desde `docs/n8n-workflows/`.

4. **Repuntar TODAS las credenciales a gemelos de staging** (checklist abajo). Ningún nodo puede quedar apuntando a prod.

5. **Número WhatsApp test.** Crear 2ª Meta App + número de test de Cloud API. Registrar el `phoneNumberId` de test en la cred `WhatsApp Test`. Configurar el WhatsApp Trigger de staging con su **webhook propio** (de la Meta App de test). Verificar los hasta 5 destinatarios verificados.

6. **Quálitas sandbox.** ✅ Credenciales QA + `QUALITAS_AMBIENTE_FLAG=0` ya en Heroku `hyl-wai-stg` (confirmado por Alberto 7 jul). Solo falta repuntar el nodo `Issue Policy` para que llame al `/api/emitir-externo/` de **`hyl-wai-stg`** (no a `seguroautoqualitas.com` de prod) — mismo paso 4/5 del runbook, sigue atado a tener la Meta App para poder activar el workflow.

7. **Prueba E2E:** enviar "hola" desde un número verificado → conversación real → captura de datos → serie/VIN → emisión sandbox → simular webhook de pago (curl). Verificar en BD stg que se escribieron `qualitas_lead`/`qualitas_cotizacion`/`whatsapp_sessions`/`n8n_chat_histories`.

### Manifiesto de credenciales de los workflows (leído de los JSON, 6 jul)

Acceso API a la instancia stg **verificado** (`.env.local` → `N8N_STG_API_KEY`, gitignored). Instancia vacía (0 workflows). Credenciales a crear en stg y repuntar:

| Credencial (type · nombre · id prod) | Nodos | Repuntar a |
|---|---|---|
| `postgres` · "Postgres account" · `FbodkhT9DijVcqpB` | 11 (Check/Load/Update Session, Chat Memory, Search Colony, Update Phase/Scope, KB Counter) | ✅ **creada en stg → "Postgres STG" id `5wlLe3gD07CLIM7U`** (ssl require + allowUnauthorizedCerts) |
| `anthropicApi` · "Anthropic Hylant Account" · `aWrCOYz0wHIk5GSd` | 4 (Anthropic Chat Model ×3, Haiku) | ✅ **creada en stg → "Anthropic STG" id `aHI51VvnRnPixCx5`** (Agente n8n, 6 jul) |
| `whatsAppTriggerApi` · "WhatsApp Hylant Account" · `bUWR11VM0seHo63P` | WhatsApp Message Trigger (inbound) | ⏳ 2ª Meta App (test) |
| `whatsAppApi` · "WhatsApp Send Message Hylant Account" · `PbzXr53disA74eew` | Send message (outbound) | ⏳ 2ª Meta App (test) |
| `httpHeaderAuth` · "Header Auth account" · `VNlbUSCkIzgHFhLc` | Payment Webhook Trigger | ⏳ token = `N8N_TOKEN` de `hyl-wai-stg` |

Valores hardcodeados en parámetros a reescribir (no son credenciales): `1028815256982638` (phoneNumberId → número test, en los 3 workflows) y `seguroautoqualitas.com` (→ URL `hyl-wai-stg`, en el bot principal incl. `Issue Policy`).

**✅ WORKFLOW PRINCIPAL IMPORTADO A STAGING (6 jul, Agente n8n, verificado por el Arquitecto contra la API viva):** `WhatsApp Insurance Quotation Bot_stg` · id **`dNqtM20ij6ecZYAX`** · **inactivo** · 61 nodos. Creds repuntadas: Postgres `5wlLe3gD07CLIM7U` (9 nodos) + Anthropic `aHI51VvnRnPixCx5` (4 nodos). Django→`hyl-wai-stg`. phoneNumberId→placeholder. Las 2 credenciales WhatsApp de prod se **quitaron** en el import → esos 2 nodos (WhatsApp Message Trigger, Send message) quedan sin credencial a propósito hasta tener la Meta App. Verificación del Arquitecto: 0 refs a los 6 ids/hosts de prod, `{5,20}`=0, VIN-17 presente. Reporte del ejecutor: `Agente-n8n:docs/2026-07-06-resultado-import-staging.md`; script idempotente `Agente-n8n:scripts/import-stg-workflow.py` (commits `1ad877b`→`63692e1`).
> **⚠️ Gotcha de import por API (reutilizable para los otros 2 workflows):** el export trae en `settings` claves que el `POST /api/v1/workflows` **rechaza con 400** (`binaryMode`, `availableInMCP`). Filtrar `settings` a las válidas (conservar `executionOrder`). Idem: reducir el JSON a `{name,nodes,connections,settings}` (sin `active`/`id`/`tags`/`shared`/`activeVersion`/`pinData`).

**✅ Versión de los JSON RESUELTA (6 jul):** F1 importa el JSON con el fix desde `aibanez82/Agente-n8n` rama `stg` (`workflows/WhatsApp Insurance Quotation Bot.json`, HEAD `405cec3`). Diagnóstico del Arquitecto: (a) el fix Bug #10 está correcto en los nodos vivos (regex VIN-17 canónica en `Validate Personal Data`, `{5,20}`=0 en `.nodes`; los "5-20" del grep eran fechas de model-ID — falsos positivos); (b) el JSON es un export estilo-BD con 19 claves top-level → **NO importable tal cual**, hay que reducir a `{name,nodes,connections,settings}` (eso elimina de paso el `activeVersion` con el único `{5,20}` stale y el `pinData` con PII). **Ejecución: Agente n8n end-to-end vía API.** Spec completo: `docs/2026-07-06-handoff-agente-n8n-import-staging-bug10.md`.

**Bloqueadores upstream para que las credenciales tengan valores reales:**
1. BD Postgres STG (runbook paso 1) — ✅ addon propio existe; `STG_DATABASE_URL` en `.env.local`; credencial n8n creada.
2. 2ª Meta App + número test (paso 5) — ❌ sin crear (Meta Business). **ÚNICO bloqueador del E2E del bot principal:** de ahí salen las 2 credenciales WhatsApp + el phoneNumberId real + la activación.
3. URL pública de `hyl-wai-stg` — ✅ **`https://hyl-wai-stg-d1085ad74dbf.herokuapp.com/`** (ya reescrito en el workflow importado).
4. Valor de `N8N_TOKEN` de `hyl-wai-stg` — ⏳ para la credencial `httpHeaderAuth` del workflow de **pago** (no del bot principal).
5. Key Anthropic — ✅ credencial "Anthropic STG" creada (`aHI51VvnRnPixCx5`).

### Checklist de auditoría de credenciales (nodo por nodo)

Con instancia separada el riesgo de `webhookId` compartido desaparece, pero SIGUE siendo obligatorio verificar que ningún nodo apunte a un recurso de prod:

- [ ] **Postgres** (`Check Session Exists`, `Load Session`, `Update Activity`, `Postgres Chat Memory`, INSERT proactivo) → cred `Postgres STG` (BD stg), NUNCA `Postgres account` de prod.
- [ ] **WhatsApp Send** (bot + workflow proactivo) → cred `WhatsApp Test` (phoneNumberId de test), NUNCA `1028815256982638`.
- [ ] **WhatsApp Trigger** → webhook de la Meta App de test.
- [ ] **`Issue Policy` (httpRequest)** → URL de `hyl-wai-stg`, NUNCA `seguroautoqualitas.com`.
- [ ] **Claude (Anthropic)** — puede reusar la key de prod (solo hace llamadas LLM, sin efectos secundarios) o una key separada para trackear coste. Decisión menor.
- [x] **`WEBHOOK_URL` + `N8N_TOKEN`** en `hyl-wai-stg` → instancia n8n de staging (corregido 7 jul, Bug #16).
- [x] `QUALITAS_URL`/`QUALITAS_WSDL_TARIFAS` → endpoints QA; credenciales QA cargadas (confirmado 7 jul); `QUALITAS_AMBIENTE_FLAG=0`; `AMBIENTE_PRUEBAS=1`.
- [ ] Ningún workflow de staging activo comparte `webhookId` con la instancia de prod (con instancia separada es imposible por construcción; verificar igual).

---

## Fases

- **F1 (MVP):** pasos 1–7 de arriba → replica Bugs #9/#7/#8 y regresión de #10.
- **F2:** Dashboard **Vercel Preview → BD stg** (para "Tomar conversación", Kommo, tarjetas).
- **F3:** simulación del webhook de pago + GA4 test.

## Próximos pasos al retomar

1. ✅ Instancia n8n de staging PROVISIONADA y viva (6 jul): **`https://n8n-xlqk.srv1810257.hstgr.cloud/`** (Hostinger, servidor `srv1810257` ≠ prod `srv1325340` → aislada; BD n8n y encryption key propias por ser deploy fresco). Verificado: `/healthz` 200, API pública habilitada (`/api/v1/workflows` → 401 pide `X-N8N-API-KEY`). **Falta: API key de ESTA instancia** para que el Arquitecto opere por API (crear credenciales stg → reescribir refs de credencial en los 3 workflows → importar → dejar inactivos hasta validar).
2. ✅ Quálitas sandbox confirmado (7 jul) — ver "Hueco pendiente" arriba. Ya no bloquea.
3. **✅ 2ª Meta App de test creada (7 jul) — bloqueador de F1 resuelto.** Alberto y el Agente n8n están corriendo pruebas E2E directamente (handoff v2: `docs/2026-07-06-handoff-agente-n8n-fase-e2e-staging-bug10.md`). Pendiente reporte de resultado (nuevo webhookId, ids de credenciales WhatsApp STG, confirmación de Connect OAuth2 + `active=true`, resultado de las 3 pruebas del Bug #10). Relacionado: Bug #10 y su plan (en `CLAUDE.md`), Bug #12 (`docs/2026-07-05-consolidacion-workflows-n8n.md`).
4. **✅ Aislamiento re-confirmado en vivo (7 jul), por vía distinta a la planeada.** El handoff formal `docs/2026-07-07-handoff-agente-n8n-verificacion-aislamiento-staging.md` nunca llegó al Agente n8n (no se copió a `Agente-n8n/handoffs/`, quedó solo en este repo — gap de proceso registrado). Las verificaciones se cubrieron igual porque se re-pidieron directo en un mensaje de seguimiento: 0 refs a `seguroautoqualitas.com`, `Issue Policy` → `hyl-wai-stg`, 9 nodos Postgres → `Postgres STG`. **No confirmado todavía:** si se regeneró el `webhookId` heredado de prod (tarea 1 del handoff perdido) — revisar en el próximo reporte.
5. **✅ Drift de schema (`rate_limit_data` en `whatsapp_sessions`) resuelto (7 jul).** No era migración Django — tabla operativa de n8n. Fix aplicado por el Agente n8n en staging. Ver `docs/2026-07-07-respuesta-agente-n8n-rate-limit-data-no-es-migracion.md`.
6. **Script de reset de datos de prueba:** `scripts/reset-test-phone-stg.sql` — borra un número de `qualitas_cotizacion` (con CASCADE a Lead/Asegurado/PolizaEmitida/CotizacionRespuestaXml) + `qualitas_leadactionevent`/`qualitas_whatsappmessage` (SET_NULL, no cascadean, hay que borrarlos aparte) + `whatsapp_sessions`/`n8n_chat_histories`. Solo contra STG, correr en TablePlus. Reusable para cada ronda de pruebas E2E.
7. **Validación E2E del Bug #10 en curso (7 jul):**
   - ✅ "hola" enviado y confirmado — ejecución `success`.
   - ✅ **Serie inválida — PASA.** Probado 2 veces con el mismo VIN base: con espacio (`1HGCM82633 004352`) y truncado a 13 caracteres (`1HGCM82633A00`). El bot detectó ambos casos correctamente y re-preguntó sin intentar avanzar — nunca llegó a `Issue_Policy`.
   - ⏳ **Serie válida — en curso.** Alberto está enviando `1HGCM82633A004352` (17 caracteres válidos) para confirmar que el flujo completa hasta emisión en sandbox con el VIN correcto (no ciudad/estado) en el tool call.
   - Éxito final = 0 emisiones con ciudad en el campo `serie`.

---

## Consolidado desde CLAUDE.md (10 jul 2026, adelgazamiento)

Bloque movido verbatim desde `CLAUDE.md`, sección "Entorno de pruebas / staging (iniciativa activa)", al adelgazar el archivo. CLAUDE.md ahora solo referencia este documento con 3 líneas.

## Entorno de pruebas / staging (iniciativa activa)

Staging end-to-end para replicar bug fixes antes de prod (gitflow `stg`→`main`). Objetivo inmediato: validar el fix del **Bug #10** (VIN/serie) E2E antes de mergear. Detalle vivo: `docs/iniciativas/entorno-pruebas-staging.md`.

**Nuevo participante (8 jul): Agente QA & Testing** (`aibanez82/Agente_QATest_Qualitas`) se incorpora para **liderar las pruebas E2E en STG** — poder correr un flujo completo sin llenar la landing a mano, y validar cambios de `systemMessage` (¿el bot ahora se comporta como queremos?). Contexto del ecosistema y del entorno STG ya cargado en su `context/ARQUITECTO.md`. **Pendiente de diseño (Arquitecto):** el método para generar el lead+cotización inicial sin pasar por la landing — hoy ese flujo lo dispara el webhook "lead creado" de Django hacia n8n, y el payload/contrato exacto para simularlo sintéticamente en STG todavía no está documentado. **Aviso importante para cualquier prueba WhatsApp real en STG:** el Bug #15 sigue activo — cada mensaje a STG también se procesa en PROD hasta que se despliegue la mitigación retenida (`docs/2026-07-08-handoff-agente-n8n-bug15-filtro-phone-number-id-prod.md`).

**Principio rector:** stack paralelo completo; cada componente de staging apunta SOLO a gemelos de staging, nunca a prod (riesgo #1 = staging escribiendo/disparando contra prod).

**Mapa prod → staging:**

| Componente | Staging | Estado |
|---|---|---|
| Backend/landing | `hyl-wai-stg` (`https://hyl-wai-stg-d1085ad74dbf.herokuapp.com`, deploy desde rama `stg`) | ✅ existe |
| Base de datos | Addon Postgres propio de `hyl-wai-stg` | ✅ (`STG_DATABASE_URL`) |
| n8n (bot WA) | **Instancia SEPARADA** en Hostinger `https://n8n-xlqk.srv1810257.hstgr.cloud` (servidor `srv1810257` ≠ prod `srv1325340`; BD/encryption key propias) | ✅ viva, API habilitada. Decisión clave: instancia separada para NO recaer en el Bug #12 (webhookId compartido) |
| Número WhatsApp | 2ª Meta App + número de test (Cloud API) | ✅ creada (7 jul) — E2E en pruebas con Agente n8n |
| Quálitas | Sandbox QA (`QUALITAS_URL`→`qa.qualitas.com.mx`; el switch es la URL, NO `QUALITAS_AMBIENTE_FLAG`) | ✅ credenciales QA + `QUALITAS_AMBIENTE_FLAG=0` (valor de prueba) ya en Heroku `hyl-wai-stg` — confirmado por Alberto 7 jul |
| Dashboard | `stg` (Vercel git-branch alias fijo) → `hyl-wai-stg` (`dei0jssp8kr5kv`) | ✅ Consolidado (10 jul) — única rama/base/URL de STG, ver detalle en Bug #17 |

**Hecho y verificado por el Arquitecto (6 jul):**
- Instancia n8n stg aislada + API (`N8N_STG_API_KEY` en `.env.local`).
- Credencial **Postgres STG** `5wlLe3gD07CLIM7U` + **Anthropic STG** `aHI51VvnRnPixCx5`.
- Workflow del bot **con el fix Bug #10 importado** (desde `aibanez82/Agente-n8n` rama `stg`): `WhatsApp Insurance Quotation Bot_stg` id **`dNqtM20ij6ecZYAX`**, **inactivo**, 61 nodos, 0 refs a prod, VIN-17 presente, Django→`hyl-wai-stg`. Ejecutado por el Agente n8n vía API, verificado contra la instancia viva.

**✅ 2ª Meta App de test creada (7 jul) — bloqueador del E2E resuelto.** Alberto está corriendo pruebas E2E con el Agente n8n (handoff v2). Pendiente reporte de resultado.

**Fase E2E ya especificada (handoff v2, modelo OAuth2 nativo):** el trigger `whatsAppTrigger` de n8n es **OAuth2** (`clientId`=App ID / `clientSecret`=App Secret); `whatsAppApi` (Send) pide `accessToken`+`businessAccountId` (WABA). Modelo A (nativo) elegido porque prod usa ese trigger → staging debe ser gemelo fiel. Requiere: 6 secretos de Juan (`STG_WA_ACCESS_TOKEN`, `STG_WA_BUSINESS_ACCOUNT_ID`, `STG_WA_APP_ID`, `STG_WA_APP_SECRET`, `STG_WA_PHONE_NUMBER_ID`), whitelist de la redirect URL OAuth de n8n en la App, y un **"Connect" OAuth2 manual de Alberto** en la UI (la API no lo hace). Handoff: `Agente-n8n:handoffs/2026-07-06-fase-e2e-staging-bug10.md` (canónico en `docs/2026-07-06-handoff-agente-n8n-fase-e2e-staging-bug10.md`).


**Gotchas de import por API n8n (reutilizables):** (1) reducir el export a `{name,nodes,connections,settings}` (rechaza `active`/`id`/`tags`/`shared`/`activeVersion`/`pinData`); (2) filtrar `settings` a claves válidas — `binaryMode`/`availableInMCP` dan 400; (3) el import heredó el `webhookId 18c1b498` de prod (Bug #12) → regenerar en la fase E2E.
