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

### Fase 0 — Prerrequisitos (Alberto) — ✅ completa
- [x] Plan de Heroku Postgres soporta pgvector — verificado en vivo 17 jul (ver §3).
- [x] `OPENAI_API_KEY` provisionada 17 jul, entregada directo a Agente n8n (nunca pasó por el Arquitecto).

### Fase 1 — Extracción de contenido (Arquitecto) — ✅ completa
- 112 pares `{section, question, content, source_clause}` extraídos del código real (no ~114, número exacto tras parseo determinista). Entregados en `Agente-n8n/handoffs/2026-07-17-kb-chunks-extracted.json`.

### Fase 2 — Backfill en STG (Agente n8n) — ✅ completa, verificado en vivo por el Arquitecto
- Extensión `vector` + tabla `kb_chunks` (schema exacto al diseño) creadas en Postgres STG.
- 112/112 chunks insertados con embeddings de `text-embedding-3-small` — verificado directo: conteo por sección idéntico al JSON fuente, 0 filas con dimensión de embedding ≠ 1536, 112 preguntas distintas.
- Nodo `search_knowledge_base1` reemplazado. **Drift real vs. este diseño:** no existe ya un nodo separado `toolVectorStore` en la versión de n8n de STG — quedó consolidado dentro de `vectorStorePGVector` en modo "Retrieve Documents (As Tool for AI Agent)" (`mode: retrieve-as-tool`). Confirmado en la UI real por Agente n8n, y verificado por el Arquitecto vía API (`GET /workflows/dNqtM20ij6ecZYAX`): conexión `Embeddings OpenAI --ai_embedding--> search_knowledge_base1 --ai_tool--> RAG IA Agent` intacta, `systemMessage` con la regla `NOT_FOUND` sin tocar. `k` no aplica igual que en el diseño original — el modo "as tool" deja que el LLM decida relevancia sobre los documentos recuperados, no hay corte duro configurado; a vigilar en el barrido de QA.

### Fase 3 — Validación en STG (Agente QA) — 🟡 parcial, superada por decisión de Alberto (ver Fase 4)
- **Ya hecho, verificado en vivo por el Arquitecto contra `n8n_chat_histories` real (no solo el resumen):** Alberto probó 4 casos reales por WhatsApp (17 jul, 19:29-19:34 UTC, sesión `525551074144`) — variante de M33 sin la palabra "promoción" ("algún descuento si pago con tarjeta?"), pregunta con fraseo informal sin ninguna keyword literal ("si choco y es mi culpa, qué pasa con el otro carro?"), y sin querer, **el caso M36** ("cubres extension de RC?" + "Y si voy manejando un camión?"). Los 4 recuperaron contenido relevante y correcto, ninguno cayó en el fallback indebidamente.
  - **Hallazgo no planeado sobre M36:** el modo de falla cambió — antes el bot daba una respuesta que sonaba completa pero omitía la restricción real; ahora responde "depende del tipo específico de vehículo" y pregunta uso personal/comercial, en vez de afirmar cobertura sin fundamento. **No es M36 resuelto** (sigue sin existir el dato real de la restricción de categoría/peso — Juan sigue sin confirmarlo, sigue sin chunk dedicado), pero el riesgo de que el cliente crea que está cubierto cuando no lo está bajó con la migración misma, sin que fuera el objetivo.
- **Barrido sistemático de Agente QA (11 secciones) — nunca se corrió.** Alberto decidió no esperarlo y pidió el deploy a PROD directo (18 jul) — ver Fase 4. Las 4 pruebas de Alberto en STG (17 jul) fueron el gate real que se usó.

### Fase 4 — Deploy a PROD — ✅ completa (18 jul 2026)

> 🔴 **Gap de proceso:** ejecutado por Agente n8n a pedido directo de Alberto ("Go"), sin pasar por handoff formal del Arquitecto ni por el barrido de QA de Fase 3. Detectado y verificado en vivo por el Arquitecto a raíz de que Alberto preguntó "¿ya está en PROD?" y este doc decía que no — no se detectó por seguimiento proactivo. Mismo patrón que el gap de `conversation_id` (`docs/iniciativas/conversation-id-whatsapp-n8n.md`): cuando Alberto instruye directo a un ejecutor, el estado real puede divergir de este repo hasta la próxima verificación.

**Hallazgo antes de desplegar (Agente n8n, `Agente-n8n:docs/2026-07-18-migracion-rag-prod-preparada-drift-contenido-encontrado.md`):** el KB del nodo `Code` viejo de PROD ya tenía contenido más nuevo que el `kb_chunks` de STG (118 preguntas en 13 secciones vs. 112 en 11) — el fix de M33 (MSI por banco) se había aplicado el 17 jul directo al código de PROD, sin pasar por STG. Reemplazar con el `kb_chunks` de STG tal cual habría borrado ese contenido. Se reconstruyó `kb_chunks` desde el código real de PROD antes de migrar (con un efecto secundario detectado y corregido: revirtió sin querer el fix de contenido de M36 en STG, arreglado el mismo día).

**Ejecutado** (`Agente-n8n:docs/2026-07-18-deploy-prod-migracion-rag-kb-chunks.md`), verificado de forma independiente por el Arquitecto contra la API de n8n PROD y Postgres PROD (no solo el reporte):
- Schema (`CREATE EXTENSION vector` + tabla `kb_chunks` + índice HNSW) en Postgres PROD.
- 118 filas backfilleadas reusando embeddings ya calculados en STG. Confirmado en vivo por el Arquitecto vía `pg_stat_user_tables`: 118 filas.
- Nodo `search_knowledge_base1` en PROD confirmado como `vectorStorePGVector` (modo `retrieve-as-tool`, `tableName: kb_chunks`) — ya no es el `toolCode` viejo. Nodo nuevo `Embeddings OpenAI` agregado, credencial `OpenAI KB Embeddings PROD`.
- Retrieval real verificado (3 queries, similitud coseno directa contra PROD) — top-1 correcto en las 3, incluidas las 2 secciones nuevas que no existían en el `kb_chunks` viejo de STG.
- `systemMessage` de `RAG IA Agent` no se tocó en este paso.

**El mismo 18 jul, también a PROD** (detalle en `Agente-n8n:docs/`, cada uno con su propio doc de deploy y verificación independiente del Agente n8n):
- **M33** (reemplazo puntual del bloque de promociones/MSI en `AI Agent`) — `2026-07-18-deploy-prod-m33-reemplazo.md`.
- **M36 (refuerzo) + M38** (edge cases de camión y confianza/legitimidad, + regla 7 de `RAG IA Agent`) — `2026-07-18-deploy-prod-m36-m38-y-fix-regresion-kb-chunks.md`.
- **Fallback de media no soportada** (sticker/video/audio/document/location/contacts) — `2026-07-18-deploy-prod-fallback-media-no-soportada.md`. Confirmado con sticker/audio/video reales por WhatsApp (mismo código que STG); document/location/contacts sin prueba real en ningún ambiente.
- **Fallback de `doc_chunks`** (corpus PDF completo, 152 chunks, solo si `kb_chunks` da `NOT_FOUND`, grounding estricto) — `2026-07-18-deploy-prod-fallback-doc-chunks.md`. Detalle de diseño y validación de grounding: `docs/iniciativas/2026-07-17-corpus-documental-pdfs-qualitas-design.md` §9. Confirmado en vivo por el Arquitecto: tabla `doc_chunks` existe en Postgres PROD, 152 filas (`pg_stat_user_tables`).

**Pendiente real (no cerrado):**
- Verificación conversacional E2E por WhatsApp en PROD — quedó marcada "pendiente" en los docs de deploy de RAG general, M33, M36/M38 y fallback `doc_chunks`. Solo el fallback de media no soportada tiene confirmación real en PROD (mismo código ya probado en STG).
- `requiere_factura` (fix) y **M39** siguen solo en STG, no promovidos — decisión aparte, a propósito.
- Commit a este repo (`docs/n8n-workflows/`) del JSON refrescado de PROD post-deploy, como exige la política de backup — pendiente de confirmar si Agente n8n ya lo hizo en su propio repo o si falta sincronizarlo aquí.

### Fase 5 — Mantenimiento post-migración
- El contenido de `kb_chunks` se actualiza agregando/editando filas (re-embeber solo la fila tocada) en vez de tocar código JS — **esto simplifica** la tubería Mejoras Conversación → Arquitecto → Agente n8n descrita en el CLAUDE.md: ya no hace falta pensar en colisiones de `keywords`, solo en si el contenido nuevo/corregido está bien redactado.
- **✅ M36 resuelto (17 jul 2026), sin esperar a Juan:** `kb_chunks` id 34 actualizado por Agente n8n (commit `31367e4`) con la restricción real de categoría (Automóvil/Pick-up del titular, NO camiones/carga/Uber-taxi), embedding regenerado, retrieval verificado. Corroborado independientemente por el Arquitecto contra la Cláusula 8.1 del PDF de Condiciones Generales — el texto coincide. Ver `docs/iniciativas/2026-07-17-corpus-documental-pdfs-qualitas-design.md` §6.

## 5. Riesgos y mitigaciones

| Riesgo | Mitigación |
|---|---|
| Plan de Heroku Postgres no soporta pgvector | Verificar en Fase 0 antes de comprometer fechas |
| Umbral de similitud mal calibrado → falsos NOT_FOUND o contenido irrelevante | Fase 3 prueba explícitamente los casos que motivaron esta migración (M33/M36) antes de PROD |
| Nodo Vector Store cambia el formato de lo que recibe el agente vs. el Code tool actual | Validar en Fase 3 que el `systemMessage` del `RAG IA Agent` (reglas de NOT_FOUND, escalamiento) sigue funcionando igual |
| Costo/latencia de la llamada a OpenAI Embeddings en cada mensaje | Volumen bajo, `text-embedding-3-small` es rápido y barato — no se espera impacto perceptible, pero medir en Fase 3 |

## 6. Ejecución — a quién corresponde

Diagnóstico y este plan: Arquitecto (ya hecho). Ejecución real (DDL, workflow JSON, backfill, import a n8n): **Agente n8n**, con **Agente QA** validando en STG antes de PROD — mismo protocolo de siempre, ningún ejecutor decide el diseño por su cuenta. Handoff formal a `Agente-n8n/handoffs/` pendiente de redactar una vez Alberto confirme Fase 0 (plan de Postgres + `OPENAI_API_KEY` provisionada).
