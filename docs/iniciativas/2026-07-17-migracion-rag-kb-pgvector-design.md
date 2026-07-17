# Migración a RAG real — `search_knowledge_base1` con pgvector + OpenAI embeddings (17 jul 2026)

> Decisión de Alberto + Juan (17 jul 2026): migrar ya, no esperar. Supersede la recomendación de espera en `docs/iniciativas/2026-07-17-decision-rag-vs-keyword-matching-kb.md`.
> Issue técnico: `github.com/aibanez82/qualitas-issues/issues/42`
> Elecciones de arquitectura confirmadas con Alberto: vector store = **pgvector sobre el Postgres actual** (no vendor nuevo); embeddings = **OpenAI `text-embedding-3-small`** (nodo nativo en n8n).

---

## 1. Estado actual verificado

Nodo `search_knowledge_base1` (`@n8n/n8n-nodes-langchain.toolCode`) en `docs/n8n-workflows/WhatsApp Insurance Quotation Bot.json`:
- 11 secciones fijas: `empresa`, `cotizacion`, `pagos`, `coberturas`, `renovacion`, `siniestros`, `atencion_digital`, `exclusiones`, `condiciones_especificas`, `obligaciones_y_documentos`, `territorio_y_cancelacion`.
- ~49 KB de texto, **~114 pares P:/R:** (pregunta/respuesta) repartidos en esas 11 secciones.
- Contenido sustancial y en parte citado directamente de las Condiciones Generales Quálitas (QJ/01 1224 - GA, con número de cláusula) — **se reusa tal cual, no se reescribe**.
- Matching: `q.includes(stripAccents(keyword))` contra listas de `keywords` por sección.

## 2. Arquitectura destino

```
Usuario pregunta (WhatsApp)
    ↓
RAG IA Agent (Claude Sonnet, sin cambios)
    ↓ (tool call)
[NUEVO] search_knowledge_base — Vector Store Tool
    ↓
Embeddings OpenAI (text-embedding-3-small) sobre la query
    ↓
Postgres PGVector — SELECT ... ORDER BY embedding <=> query_embedding LIMIT k
    ↓
tabla kb_chunks (Heroku Postgres, la MISMA BD que Django/n8n ya comparten)
```

**Por qué pgvector sobre el Postgres actual y no un vector DB dedicado:** cero vendor nuevo, cero credencial nueva de infraestructura (solo la de OpenAI para embeddings), respeta la regla de arquitectura ya existente ("Django y n8n comparten la misma BD Postgres"), y STG/PROD ya tienen su gemelo de Postgres — el patrón de aislamiento staging→prod no cambia.

## 3. Esquema nuevo

```sql
CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE kb_chunks (
  id            SERIAL PRIMARY KEY,
  section       TEXT NOT NULL,          -- 'empresa', 'pagos', etc. — se conserva para trazabilidad/debug
  question      TEXT NOT NULL,          -- el "P:" original
  content       TEXT NOT NULL,          -- el "R:" original (lo que se inyecta al agente si matchea)
  embedding     vector(1536) NOT NULL,  -- text-embedding-3-small = 1536 dims
  source_clause TEXT,                   -- número de cláusula de Condiciones Generales si aplica, NULL si no
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX kb_chunks_embedding_idx ON kb_chunks
  USING hnsw (embedding vector_cosine_ops);
```

**Unidad de chunking: por par P:/R:, no por sección completa.** Las secciones actuales mezclan 5-15 preguntas distintas bajo un mismo bloque `content`; si se embebe la sección completa, la búsqueda semántica pierde precisión y se vuelve a concatenar contenido irrelevante (el mismo problema que hoy causa respuestas largas/genéricas cuando matchean varias `keywords`). 114 chunks pequeños y específicos son mejor unidad de recuperación que 11 chunks grandes.

**✅ Verificado en vivo (17 jul 2026), vía `pg_available_extensions` directo contra ambas BD:** el Postgres real que usa `DATABASE_URL` en PROD (`postgresql-flexible-50432`, plan `heroku-postgresql:standard-0`, Postgres 17.10) y en STG (mismo plan, Postgres 17.9) tienen la extensión `vector` disponible (`default_version 0.8.1`, aún no instalada). Ya no es un bloqueante.

**Nota de paso:** `hyl-wai-production` tiene un segundo addon de Postgres adjunto (`postgresql-amorphous-98884`, plan `essential-0`, que NO soportaría pgvector) pero no es el que usa `DATABASE_URL` — no afecta esta migración, solo dejarlo anotado para no confundirlo.

## 4. Plan de migración (fases)

### Fase 0 — Prerrequisitos (Alberto)
- [x] Plan de Heroku Postgres soporta pgvector — verificado en vivo 17 jul (ver §3).
- [ ] Provisionar `OPENAI_API_KEY` — nueva, no existe hoy en el ecosistema. Agregar como credencial en n8n (PROD y STG por separado) y, si se necesita fuera de n8n para el script de backfill, como env var donde corresponda.

### Fase 1 — Extracción de contenido (Arquitecto, análisis; sin ejecución de código)
- Parsear el código actual de `search_knowledge_base1` y producir un CSV/JSON intermedio con los ~114 pares `{section, question, content, source_clause}` — sin tocar el workflow todavía. Esto es trabajo de una sola pasada, determinista (el código fuente ya tiene el patrón `P: ... R: ...` consistente).

### Fase 2 — Backfill en STG (Agente n8n, ejecuta)
- Crear la tabla `kb_chunks` en el Postgres de STG (`CREATE EXTENSION vector` + DDL de arriba).
- Workflow n8n de un solo uso (o script) que recorra el JSON intermedio de la Fase 1, llame a OpenAI Embeddings por cada chunk, e inserte en `kb_chunks`. ~114 llamadas, costo trivial (<$0.01 con `text-embedding-3-small`).
- Reemplazar el nodo `search_knowledge_base1` (Code tool) por un **Vector Store Tool node** (`@n8n/n8n-nodes-langchain.toolVectorStore` sobre `vectorStorePGVector`) conectado a `kb_chunks`, con un nodo `Embeddings OpenAI` alimentando la query. `k` (número de chunks recuperados) a definir en pruebas — punto de partida sugerido: `k=3`.
- Mantener el mismo contrato de salida hacia el agente (si no hay match relevante por umbral de similitud, devolver algo equivalente a `NOT_FOUND` para no romper la lógica de escalamiento del `systemMessage` del `RAG IA Agent`).

### Fase 3 — Validación en STG (Agente QA, ejecuta)
- Correr como caso de prueba **las mismas reformulaciones que expusieron el bug**: "tienes alguna promoción" / "tienes algún descuento" / "algún precio especial" (M33) deben ahora devolver el mismo contenido de MSI las tres. Igual con la pregunta de M36 (Extensión RC al Titular con vehículo de otra categoría) una vez Juan confirme el contenido real de esa restricción.
- Regresión: probar al menos 1-2 preguntas por cada una de las 11 secciones para confirmar que el contenido recuperado coincide con el que devolvía el keyword matching (no debe haber pérdida de cobertura, solo ganancia de recall en reformulaciones).
- Sign-off explícito de Alberto antes de pasar a PROD (mismo gate que cualquier cambio a este nodo).

### Fase 4 — Deploy a PROD (Agente n8n ejecuta el JSON; Alberto importa)
- Backfill de `kb_chunks` en Postgres PROD (mismo proceso de Fase 2).
- Import del workflow actualizado en n8n PROD.
- Commit del JSON exportado a este repo (`docs/n8n-workflows/`), como exige la política de backup existente.

### Fase 5 — Mantenimiento post-migración
- El contenido de `kb_chunks` se actualiza agregando/editando filas (re-embeber solo la fila tocada) en vez de tocar código JS — **esto simplifica** la tubería Mejoras Conversación → Arquitecto → Agente n8n descrita en el CLAUDE.md: ya no hace falta pensar en colisiones de `keywords`, solo en si el contenido nuevo/corregido está bien redactado.
- M36 sigue bloqueado en el mismo punto: falta que Juan confirme la restricción real de categoría/peso de "Extensión RC al Titular" antes de poder escribir ese chunk correctamente.

## 5. Riesgos y mitigaciones

| Riesgo | Mitigación |
|---|---|
| Plan de Heroku Postgres no soporta pgvector | Verificar en Fase 0 antes de comprometer fechas |
| Umbral de similitud mal calibrado → falsos NOT_FOUND o contenido irrelevante | Fase 3 prueba explícitamente los casos que motivaron esta migración (M33/M36) antes de PROD |
| Nodo Vector Store cambia el formato de lo que recibe el agente vs. el Code tool actual | Validar en Fase 3 que el `systemMessage` del `RAG IA Agent` (reglas de NOT_FOUND, escalamiento) sigue funcionando igual |
| Costo/latencia de la llamada a OpenAI Embeddings en cada mensaje | Volumen bajo, `text-embedding-3-small` es rápido y barato — no se espera impacto perceptible, pero medir en Fase 3 |

## 6. Ejecución — a quién corresponde

Diagnóstico y este plan: Arquitecto (ya hecho). Ejecución real (DDL, workflow JSON, backfill, import a n8n): **Agente n8n**, con **Agente QA** validando en STG antes de PROD — mismo protocolo de siempre, ningún ejecutor decide el diseño por su cuenta. Handoff formal a `Agente-n8n/handoffs/` pendiente de redactar una vez Alberto confirme Fase 0 (plan de Postgres + `OPENAI_API_KEY` provisionada).
