# Inventario de objetos de BD creados FUERA de las migraciones de Django

> Para: Juan Aguayo (despliegues/migraciones desde Heroku) · De: Arquitecto-IA-Qualitas · 24 jul 2026
> Verificado en vivo contra la BD de **PRODUCCIÓN** (`d779dc6ojpjvn5`) + análisis de las migraciones del repo `aguayo-co/HYL-WAI`.
> **Propósito:** listar todo lo que existe en la Postgres de Heroku que **NO** producen las migraciones de Django, para que al desplegar/recrear un entorno sepas qué crear a mano.

---

## TL;DR — modelo de propiedad de la BD

La BD tiene **86 tablas**. Se dividen así:

| Grupo | Quién lo crea | ¿En tus migraciones? |
|---|---|---|
| `qualitas_*`, `auth_*`, `django_*`, `wagtail*`, `taggit_*` | Django/Wagtail (tus modelos + framework) | ✅ Sí — ya lo tienes |
| `whatsapp_sessions_archive`, `n8n_chat_histories_archive` | Django, por DDL crudo en migración **0032** | ✅ Sí — ya lo tienes |
| Columnas `conversation_id`/`lead_id`/`status`/`closed_at` + índices en `whatsapp_sessions` | Django, por DDL crudo en migración **0033** (idempotente, solo si la tabla existe) | ✅ Sí — ya lo tienes |
| **`whatsapp_sessions` (base)** | Externo (n8n / SQL crudo) | ❌ **No** |
| **`n8n_chat_histories` (base)** | Externo (n8n, nodo Postgres Chat Memory) | ❌ **No** |
| **`conciliacion_pagos`** | Externo (Agente Conciliación) | ❌ **No** |
| **`dashboard_users`, `dashboard_conversation_claims`, `dashboard_message_audit`** | Externo (Dashboard, creadas 24 jul 2026) | ❌ **No** |
| **`doc_sources`, `doc_chunks`, `kb_chunks`** | Externo (iniciativas RAG, pgvector) | ❌ **No** |
| Extensión **`vector` (pgvector)** | Externo (para las tablas RAG) | ❌ **No** |

**El punto crítico para ti:** tus migraciones **0032** y **0033** dan por hecho que `whatsapp_sessions` y `n8n_chat_histories` **ya existen** (usan guardas `_table_exists` y abortan en silencio si no). Es decir, en un entorno nuevo, **esas dos tablas base deben crearse ANTES de correr las migraciones**, o Django no las aumentará y n8n las creará luego incompletas → drift.

---

## 1. Extensión requerida (antes que nada)

```sql
CREATE EXTENSION IF NOT EXISTS vector;   -- pgvector v0.8.1 en PROD; necesaria para doc_chunks / kb_chunks
```
(También hay `pg_stat_statements`, que Heroku suele habilitar solo; no requiere acción.)

---

## 2. Tablas base externas que TUS migraciones asumen preexistentes

Créalas **antes** de correr las migraciones de Django. DDL con la estructura **original externa** (las columnas que Django añade luego por 0032/0033 van marcadas — si las creas ya, esas migraciones las saltan por ser idempotentes).

### `whatsapp_sessions` (la escribe n8n directo a Postgres)

```sql
CREATE TABLE whatsapp_sessions (
  -- columnas base (externas, n8n):
  phone_number          varchar(20)  NOT NULL,
  quotation_id          integer      NOT NULL,
  conversation_phase    varchar(50)  DEFAULT 'initial',
  captured_data         jsonb        DEFAULT '{}'::jsonb,
  policy_data           jsonb        DEFAULT '{}'::jsonb,
  last_activity         timestamptz  DEFAULT now(),
  created_at            timestamptz  DEFAULT now(),
  updated_at            timestamptz  DEFAULT now(),
  session_id            varchar(255) NOT NULL,
  quotation_data        jsonb,
  out_of_scope_attempts integer      DEFAULT 0,
  is_banned             boolean      DEFAULT false,
  rate_limit_data       jsonb        DEFAULT '{}'::jsonb,
  -- columnas añadidas por tu migración 0033 (inclúyelas o deja que 0033 las agregue):
  conversation_id       varchar(80),
  lead_id               integer,
  status                varchar(30)  DEFAULT 'open',
  closed_at             timestamptz,
  CONSTRAINT whatsapp_sessions_pkey PRIMARY KEY (session_id)
);
-- índices (los de conversation_id/phone_status/quotation también los crea 0033):
CREATE UNIQUE INDEX whatsapp_sessions_conversation_id_uq   ON whatsapp_sessions (conversation_id) WHERE conversation_id IS NOT NULL;
CREATE INDEX        whatsapp_sessions_phone_status_updated_idx ON whatsapp_sessions (phone_number, status, updated_at DESC);
CREATE INDEX        whatsapp_sessions_quotation_id_idx      ON whatsapp_sessions (quotation_id);
CREATE INDEX        idx_whatsapp_sessions_last_activity     ON whatsapp_sessions (last_activity);
CREATE UNIQUE INDEX idx_whatsapp_sessions_phone_number      ON whatsapp_sessions (phone_number);
CREATE INDEX        idx_whatsapp_sessions_quotation_id      ON whatsapp_sessions (quotation_id);
```

> ⚠️ **Timezone:** las columnas de tiempo (`created_at`, `last_activity`, `updated_at`) están en **`timestamptz`** en PROD. Nacieron como `timestamp` naive (n8n escribe `NOW()` en UTC) y se corrigieron por `ALTER` fuera de tus migraciones (aplicado 11 jul 2026). Si recreas la tabla, créalas ya como `timestamptz` (arriba ya está así).

### `n8n_chat_histories` (nodo Postgres Chat Memory de n8n)

```sql
CREATE TABLE n8n_chat_histories (
  id         serial       PRIMARY KEY,          -- base n8n
  session_id varchar(255) NOT NULL,             -- base n8n
  message    jsonb        NOT NULL,             -- base n8n
  created_at timestamptz  DEFAULT now()         -- añadida por fuera (no la trae el Chat Memory por defecto)
);
```
> El nodo Postgres Chat Memory de n8n crea `id`/`session_id`/`message`; el `created_at` (timestamptz) se añadió después por SQL crudo. Ordenar hitos por `id`.

---

## 3. Tablas 100% externas (no aparecen en el repo — créalas completas)

### `conciliacion_pagos` (Agente Conciliación — verificación de pagos contra el portal Quálitas)

```sql
CREATE TABLE conciliacion_pagos (
  numero_recibo       text PRIMARY KEY,
  numero_poliza       text NOT NULL,
  numero_endoso       text,
  fecha_vencimiento   date,
  remesa              text,
  fecha_pago          date,
  importe             numeric,
  estado              text NOT NULL,
  tipo_movimiento     text,
  estado_crudo_portal text,
  verificado_en       timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_conciliacion_pagos_numero_poliza ON conciliacion_pagos (numero_poliza);
```

### `dashboard_*` (login individual + roles + Inbox del Dashboard — creadas 24 jul 2026)

```sql
CREATE TABLE dashboard_users (
  id            serial PRIMARY KEY,
  username      varchar(50)  UNIQUE NOT NULL,
  password_hash text NOT NULL,
  display_name  varchar(100) NOT NULL,
  role          varchar(20)  NOT NULL DEFAULT 'agente',   -- 'agente' | 'admin' | 'hylantt'
  active        boolean      NOT NULL DEFAULT true,
  created_at    timestamptz  NOT NULL DEFAULT now()
);

CREATE TABLE dashboard_conversation_claims (
  id          serial PRIMARY KEY,
  lead_id     integer NOT NULL,
  session_id  varchar(255),
  agent_id    integer NOT NULL REFERENCES dashboard_users(id),
  claimed_at  timestamptz NOT NULL DEFAULT now(),
  released_at timestamptz
);
CREATE UNIQUE INDEX dashboard_claims_active_idx
  ON dashboard_conversation_claims(lead_id) WHERE released_at IS NULL;

CREATE TABLE dashboard_message_audit (
  id         serial PRIMARY KEY,
  lead_id    integer NOT NULL,
  session_id varchar(255),
  agent_id   integer NOT NULL REFERENCES dashboard_users(id),
  claim_id   integer REFERENCES dashboard_conversation_claims(id),
  message    text NOT NULL,
  webhook_ok boolean,
  sent_at    timestamptz NOT NULL DEFAULT now()
);
```
> Nota: estas tablas las escribe el Dashboard con un rol Postgres dedicado **`dashboard_rw`** (credencial Heroku, mínimo privilegio: lee todo, escribe solo estas 3). No es la credencial `DATABASE_URL` por defecto.

### `doc_*` y `kb_chunks` (RAG — corpus documental Quálitas + KB, con pgvector)

Requieren `CREATE EXTENSION vector` (sección 1) antes.

```sql
CREATE TABLE doc_sources (
  id             serial PRIMARY KEY,
  file_hash      text UNIQUE NOT NULL,
  title          text NOT NULL,
  document_type  text NOT NULL,
  product_line   text,
  effective_date date,
  source_path    text NOT NULL,
  ingested_at    timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX doc_chunks_type_idx ON doc_sources (document_type);

CREATE TABLE doc_chunks (
  id         serial PRIMARY KEY,
  source_id  integer NOT NULL REFERENCES doc_sources(id),
  chunk_hash text UNIQUE NOT NULL,
  content    text NOT NULL,
  page       integer,
  clause_ref text,
  embedding  vector(1536) NOT NULL
);
CREATE INDEX doc_chunks_embedding_idx ON doc_chunks USING hnsw (embedding vector_cosine_ops);

CREATE TABLE kb_chunks (
  id            serial PRIMARY KEY,
  section       text NOT NULL,
  question      text NOT NULL,
  content       text NOT NULL,
  embedding     vector(1536) NOT NULL,
  source_clause text,
  updated_at    timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX kb_chunks_embedding_idx ON kb_chunks USING hnsw (embedding vector_cosine_ops);
```

---

## 4. Lo que TUS migraciones ya manejan sobre tablas externas (contexto, no acción)

Para que el panorama quede completo — esto NO lo tienes que crear a mano, lo hacen tus migraciones idempotentes **si la tabla base existe**:

- **Migración `0032_whatsapp_sessions_archive_operational_fix.py`:** crea `whatsapp_sessions_archive` y `n8n_chat_histories_archive` (`CREATE TABLE ... LIKE ...`), añade `archived_at`, `rate_limit_data`, `archive_id` (+secuencia/PK) e índices de archive.
- **Migración `0033_whatsapp_conversation_id_phase2.py`:** añade a `whatsapp_sessions` (y su archive) las columnas `conversation_id`, `lead_id`, `status`, `closed_at` + índices; y añade `conversation_id` a `qualitas_whatsappmessage` (esa sí es tabla Django, vía `AddField`).

Ambas usan guardas `_table_exists(...)` y `if connection.vendor != "postgresql": return` → seguras y no destructivas.

---

## 5. Orden recomendado para levantar un entorno nuevo

1. `CREATE EXTENSION vector;`
2. Crear **`whatsapp_sessions`** y **`n8n_chat_histories`** (base) — sección 2.
3. Correr las **migraciones de Django** (`manage.py migrate`) → crea `qualitas_*`/framework, los `*_archive`, y aumenta las dos tablas base.
4. Crear **`conciliacion_pagos`**, **`dashboard_*`**, **`doc_*`**, **`kb_chunks`** — secciones 3.
5. Provisionar el rol **`dashboard_rw`** si el Dashboard va a escribir (credencial Heroku, no `CREATE ROLE` por SQL — el rol default no tiene `CREATEROLE`).

> Si en tu entorno n8n crea `whatsapp_sessions`/`n8n_chat_histories` por su cuenta, asegúrate de que sea **antes** del `migrate`, o las migraciones 0032/0033 no las aumentarán.

---

## Anexo — clasificación completa de las 86 tablas

- **Django/Wagtail framework (ya en tus migraciones):** `auth_group`, `auth_group_permissions`, `auth_permission`, `auth_user`, `auth_user_groups`, `auth_user_user_permissions`, `django_admin_log`, `django_content_type`, `django_migrations`, `django_session`, `taggit_tag`, `taggit_taggeditem`, y todas las `wagtail*` (`wagtailcore_*`, `wagtailimages_*`, `wagtaildocs_*`, `wagtailredirects_*`, `wagtailforms_*`, `wagtailsearch_*`, `wagtailadmin_*`, `wagtailembeds_*`, `wagtailusers_userprofile`).
- **Negocio Django `qualitas_*` (ya en tus migraciones):** `qualitas_abtestinginternalemail`, `qualitas_asegurado`, `qualitas_catalogoerrorqualitas`, `qualitas_catalogovehiculo`, `qualitas_cotizacion`, `qualitas_cotizacionrespuestaxml`, `qualitas_experimentdailymetric`, `qualitas_experimentvisitorassignment`, `qualitas_landingexperiment`, `qualitas_landingexperimentvariant`, `qualitas_lead`, `qualitas_leadactionevent`, `qualitas_leadadminsecuritysettings`, `qualitas_leadcheckpointfollowupattempt`, `qualitas_leadfollowuppolicy`, `qualitas_leadfollowuppolicyaudit`, `qualitas_leadoperationalinfo`, `qualitas_numbersblacklist`, `qualitas_numeropruebawhatsapp`, `qualitas_polizaemitida`, `qualitas_qualitaslandingpage`, `qualitas_sepomex`, `qualitas_trackingsettings`, `qualitas_whatsappmessage`, `qualitas_whatsappquotepreviewfragment`.
- **Creadas por Django vía DDL crudo (migración 0032 — ya en tus migraciones):** `whatsapp_sessions_archive`, `n8n_chat_histories_archive`.
- **EXTERNAS (no en tus migraciones — este documento):** `whatsapp_sessions`, `n8n_chat_histories`, `conciliacion_pagos`, `dashboard_users`, `dashboard_conversation_claims`, `dashboard_message_audit`, `doc_sources`, `doc_chunks`, `kb_chunks`.
