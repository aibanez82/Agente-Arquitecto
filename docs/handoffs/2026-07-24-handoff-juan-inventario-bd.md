# Handoff a Juan — objetos de BD fuera de las migraciones de Django (qué migrar/desplegar)

> Para: **Juan Aguayo** (`aguayo-co/HYL-WAI`) · De: Arquitecto-IA-Qualitas (ecosistema Insurmind), vía Alberto · 24 jul 2026
> Documento autocontenido: puedes pasárselo entero a un LLM. Fuente mantenida en `Agente-Arquitecto/docs/architecture/inventario-bd-objetos-externos-para-juan.md`.
> Base: verificación en vivo contra la Postgres de **PRODUCCIÓN** (`d779dc6ojpjvn5`) + análisis de las migraciones de tu repo.

---

## 0. Contexto (por qué te llega esto)

La Postgres de Heroku es **compartida** entre tu backend Django/Wagtail y el resto del ecosistema (n8n, el Dashboard en Vercel, y varios agentes). A lo largo del proyecto, esos sistemas han **creado tablas y añadido columnas por SQL crudo**, fuera de tus migraciones. Como tú eres quien hace despliegues y migraciones desde Heroku, necesitas saber qué existe que tus migraciones **no** recrean, para que un entorno nuevo (o un redeploy/reconciliación) quede completo.

Este handoff separa: **(A)** lo que Django ya gestiona (no tocas nada), **(B)** lo externo que debes tener en cuenta, con su DDL exacto, y **(C)** el orden de arranque + un par de decisiones que te pedimos.

---

## 1. Modelo de propiedad — las 86 tablas de PROD

| Grupo | Quién lo crea | ¿En tus migraciones? |
|---|---|---|
| `qualitas_*`, `auth_*`, `django_*`, `wagtail*`, `taggit_*` | Django/Wagtail | ✅ Sí |
| `whatsapp_sessions_archive`, `n8n_chat_histories_archive` | Django, DDL crudo en migración **0032** | ✅ Sí |
| Columnas `conversation_id`/`lead_id`/`status`/`closed_at` + índices en `whatsapp_sessions` | Django, DDL crudo en migración **0033** | ✅ Sí |
| **`whatsapp_sessions` (base)** | Externo (n8n / SQL crudo) | ❌ No |
| **`n8n_chat_histories` (base)** | Externo (n8n, nodo Postgres Chat Memory) | ❌ No |
| **`conciliacion_pagos`** | Externo (Agente Conciliación) | ❌ No |
| **`dashboard_users`, `dashboard_conversation_claims`, `dashboard_message_audit`** | Externo (Dashboard, 24 jul 2026) | ❌ No |
| **`doc_sources`, `doc_chunks`, `kb_chunks`** | Externo (RAG, pgvector) | ❌ No |
| Extensión **`vector` (pgvector)** | Externo | ❌ No |

### ⚠️ El punto crítico para tus despliegues

Tus migraciones **0032** y **0033** **asumen que `whatsapp_sessions` y `n8n_chat_histories` ya existen** — usan guardas `_table_exists(...)` y **abortan en silencio si no están**. Entonces, en un entorno nuevo:

> Si corres `migrate` **antes** de que esas dos tablas base existan, Django no las aumenta (no añade `conversation_id`/`status`/`closed_at`/archives), y cuando n8n las cree por su cuenta quedarán **incompletas → drift silencioso**.

Por eso el orden importa (sección 3).

---

## 2. DDL de todo lo externo (listo para recrear)

### 2.0 Extensión (primero de todo)
```sql
CREATE EXTENSION IF NOT EXISTS vector;   -- pgvector v0.8.1 en PROD; requerida por doc_chunks/kb_chunks
```

### 2.1 Tablas base que tus migraciones asumen preexistentes

**`whatsapp_sessions`** (la escribe n8n directo a Postgres). Las columnas marcadas las añade tu 0033 — si las creas ya, 0033 las salta (es idempotente):
```sql
CREATE TABLE whatsapp_sessions (
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
  conversation_id       varchar(80),   -- añade 0033
  lead_id               integer,       -- añade 0033
  status                varchar(30)  DEFAULT 'open',  -- añade 0033
  closed_at             timestamptz,   -- añade 0033
  CONSTRAINT whatsapp_sessions_pkey PRIMARY KEY (session_id)
);
CREATE UNIQUE INDEX whatsapp_sessions_conversation_id_uq       ON whatsapp_sessions (conversation_id) WHERE conversation_id IS NOT NULL;
CREATE INDEX        whatsapp_sessions_phone_status_updated_idx ON whatsapp_sessions (phone_number, status, updated_at DESC);
CREATE INDEX        whatsapp_sessions_quotation_id_idx         ON whatsapp_sessions (quotation_id);
CREATE INDEX        idx_whatsapp_sessions_last_activity        ON whatsapp_sessions (last_activity);
CREATE UNIQUE INDEX idx_whatsapp_sessions_phone_number         ON whatsapp_sessions (phone_number);
CREATE INDEX        idx_whatsapp_sessions_quotation_id         ON whatsapp_sessions (quotation_id);
```
> **Timezone:** `created_at`/`last_activity`/`updated_at` están en `timestamptz` en PROD. Nacieron como `timestamp` naive (n8n escribe `NOW()` en UTC) y se corrigieron por `ALTER` fuera de tus migraciones (aplicado 11 jul 2026). El DDL de arriba ya las trae como `timestamptz` — mantenlo así.

**`n8n_chat_histories`** (nodo Postgres Chat Memory de n8n):
```sql
CREATE TABLE n8n_chat_histories (
  id         serial       PRIMARY KEY,
  session_id varchar(255) NOT NULL,
  message    jsonb        NOT NULL,
  created_at timestamptz  DEFAULT now()   -- añadida por fuera; el Chat Memory por defecto no la trae
);
```

### 2.2 Tablas 100% externas (no aparecen en tu repo)

**`conciliacion_pagos`** (Agente Conciliación — verifica pagos reales contra el portal Quálitas):
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

**`dashboard_*`** (login individual + roles + Inbox del Dashboard; creadas 24 jul 2026):
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
> El Dashboard escribe estas 3 con un rol Postgres dedicado **`dashboard_rw`** (credencial Heroku, mínimo privilegio: lee todo, escribe solo estas 3). No usa la `DATABASE_URL` por defecto.

**`doc_*` y `kb_chunks`** (RAG — corpus documental Quálitas + KB, con pgvector; requieren la extensión de 2.0):
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

### 2.3 Lo que TUS migraciones ya manejan sobre tablas externas (contexto, no acción)
- **`0032_whatsapp_sessions_archive_operational_fix.py`:** crea `whatsapp_sessions_archive` y `n8n_chat_histories_archive` (`CREATE TABLE ... LIKE`), añade `archived_at`/`rate_limit_data`/`archive_id` (+secuencia/PK) e índices.
- **`0033_whatsapp_conversation_id_phase2.py`:** añade a `whatsapp_sessions` (+ su archive) `conversation_id`/`lead_id`/`status`/`closed_at` + índices; y `conversation_id` a `qualitas_whatsappmessage` (esa sí es Django, vía `AddField`).

Ambas con guardas `_table_exists(...)` y `if connection.vendor != "postgresql": return` → seguras e idempotentes.

---

## 3. Orden recomendado para levantar un entorno nuevo

1. `CREATE EXTENSION vector;`
2. Crear **`whatsapp_sessions`** y **`n8n_chat_histories`** (base) — sección 2.1.
3. Correr **`manage.py migrate`** → crea `qualitas_*`/framework, los `*_archive`, y aumenta las 2 tablas base.
4. Crear **`conciliacion_pagos`**, **`dashboard_*`**, **`doc_*`**, **`kb_chunks`** — secciones 2.2.
5. Provisionar el rol **`dashboard_rw`** si el Dashboard escribe (credencial Heroku — `CREATE ROLE` por SQL falla, el rol default no tiene `CREATEROLE`).

> Si en tu entorno n8n crea `whatsapp_sessions`/`n8n_chat_histories` por su cuenta, que sea **antes** del `migrate`.

---

## 4. Lo que te pedimos (decisiones / confirmaciones)

1. **¿Revisas si algo aquí te sorprende?** Si alguna de estas tablas "externas" tú creías que era tuya, dínoslo — puede indicar un desajuste de expectativas.
2. **Decisión de mantenibilidad:** varias de estas tablas externas tienen esquema estable (`conciliacion_pagos`, `dashboard_*`, `doc_*`/`kb_chunks`). ¿Te interesa **absorberlas como migraciones Django** (aunque sea `RunSQL` idempotente como ya haces en 0032/0033), para que tus deploys sean autocontenidos y reproducibles? Alternativa: dejarlas como "bootstrap externo documentado" (este doc). Tu criterio manda; solo queremos que la decisión sea consciente, no implícita.
3. **`whatsapp_sessions` base:** hoy ninguna migración la crea y n8n no la auto-genera de forma garantizada. Si te parece, sería la primera candidata a formalizar (o al menos a un `RunSQL` `CREATE TABLE IF NOT EXISTS` de arranque), justo porque tus 0032/0033 dependen de ella.

Cualquier duda, va por Alberto. Gracias, Juan.
