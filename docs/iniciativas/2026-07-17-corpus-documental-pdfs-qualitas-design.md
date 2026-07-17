# Corpus documental de PDFs de Quálitas — arquitectura de ingesta y consulta (17 jul 2026)

> Decisión de Alberto (17 jul 2026): el corpus es **fuente interna, con promoción manual al KB del bot** — el `RAG IA Agent` de WhatsApp NUNCA consulta este corpus en vivo. Volumen actual: decenas de PDFs en carpeta local/Drive (lote recién entregado por Quálitas), objetivo declarado: debe seguir funcionando a 10.000 PDFs.
> Relacionado: `docs/iniciativas/2026-07-17-migracion-rag-kb-pgvector-design.md` (el KB curado `kb_chunks` ya migrado a pgvector — esta iniciativa es un sistema hermano, no lo sustituye).

---

## 1. Por qué dos niveles, no uno

El bot de WhatsApp ya tiene `kb_chunks`: ~112 pares P:/R: curados a mano, citando cláusula exacta de Condiciones Generales, consultados en cada mensaje por el `RAG IA Agent`. Eso es **Tier 1 — respuestas verificadas, cara al cliente**.

El lote nuevo de PDFs de Quálitas (manuales, condiciones, documentación técnica/legal/negocio) es distinto en naturaleza: grande, no curado, con boilerplate repetido entre productos, y de calidad de origen variable. Meterlo directo como herramienta del bot en vivo:

- sube coste/latencia por mensaje (embeddings + búsqueda sobre un índice mucho más grande, en un canal que hoy es barato),
- sube el riesgo de alucinación/respuesta imprecisa en un canal de cara a cliente (un PDF de 40 páginas mal chunked puede devolver un fragmento fuera de contexto y el agente lo cita como si fuera la respuesta),
- y mezcla "lo que Quálitas nos mandó" con "lo que ya verificamos que es correcto y estable" — perdiendo la garantía de calidad que `kb_chunks` tiene hoy.

Por eso: **Tier 2 — corpus documental crudo, consulta interna** (Arquitecto, Agente Mejoras Conversación cuando investiga un hueco, Juan/Alberto si hace falta). Cuando algo del corpus resuelve una pregunta real que hoy falla (patrón M33/M36), se verifica contra el PDF original y se promueve a mano como chunk curado en `kb_chunks` — mismo protocolo que ya existe en el CLAUDE.md para Agente Mejoras Conversación (propone → Arquitecto valida → Agente n8n aplica).

Esto no es una tubería nueva — es la misma tubería de siempre, con una fuente de investigación mejor que "esperar a que Juan confirme el dato de negocio a mano".

---

## 2. Arquitectura

```
PDFs de Quálitas (carpeta local/Drive)
    ↓ script de ingesta (determinista, NO agente LLM parseando)
Extracción de texto (pdfplumber / unstructured — o OCR solo si el PDF es escaneado)
    ↓
Chunking estructural (por cláusula/sección si el doc tiene numeración; por párrafo si no)
    ↓
Dedup (hash de texto normalizado — boilerplate repetido entre productos no se re-embebe)
    ↓
Embeddings OpenAI text-embedding-3-small (Batch API — no es tiempo real, 50% más barato)
    ↓
Postgres pgvector — MISMA BD que kb_chunks, tablas separadas:
  doc_sources  (metadata a nivel documento — para trazabilidad y reproceso selectivo)
  doc_chunks   (texto + embedding + metadata a nivel fragmento)
    ↓
Consulta interna (Arquitecto / Mejoras Conversación / Juan-Alberto vía script o endpoint simple)
    ↓ verificación humana contra el PDF original
Promoción manual a kb_chunks (mismo protocolo Mejoras Conversación → Arquitecto → Agente n8n)
```

**Por qué la misma Postgres, tablas separadas:** cero vendor nuevo (ya está pgvector instalado desde la migración del 17 jul), pero `doc_chunks` nunca debe compartir índice ni ruta de consulta con `kb_chunks` — así un corpus que crece a 10.000 PDFs no puede degradar la latencia del que sí usa el bot en vivo.

---

## 3. Esquema propuesto

```sql
CREATE TABLE doc_sources (
  id              SERIAL PRIMARY KEY,
  file_hash       TEXT UNIQUE NOT NULL,   -- SHA256 del PDF completo — evita reprocesar si no cambió
  title           TEXT NOT NULL,
  document_type   TEXT NOT NULL,          -- 'manual', 'condiciones_generales', 'tarifa', 'circular', etc.
  product_line    TEXT,                   -- si aplica (auto, etc.) — NULL si es transversal
  effective_date  DATE,                   -- vigencia del documento, si consta
  source_path     TEXT NOT NULL,          -- ruta original (Drive/local) para volver al PDF
  ingested_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE doc_chunks (
  id            SERIAL PRIMARY KEY,
  source_id     INTEGER NOT NULL REFERENCES doc_sources(id),
  chunk_hash    TEXT NOT NULL,            -- hash del texto normalizado — dedup entre documentos
  content       TEXT NOT NULL,
  page          INTEGER,
  clause_ref    TEXT,                     -- número de cláusula/artículo si el doc lo trae
  embedding     vector(1536) NOT NULL,
  UNIQUE (chunk_hash)                     -- boilerplate repetido = una sola fila
);

CREATE INDEX doc_chunks_embedding_idx ON doc_chunks
  USING hnsw (embedding vector_cosine_ops);
CREATE INDEX doc_chunks_type_idx ON doc_sources (document_type);
```

**Por qué `UNIQUE (chunk_hash)`:** los documentos de seguros repiten boilerplate legal entre productos casi al carácter — deduplicar antes de embeber ahorra coste real a escala de 10.000 PDFs y evita que el mismo texto aparezca 40 veces en resultados de búsqueda.

**Por qué metadata a nivel `doc_sources` y no solo en `doc_chunks`:** permite filtrar ANTES de la búsqueda vectorial (`WHERE document_type = 'condiciones_generales'`) — a 10.000 PDFs, restringir el espacio de búsqueda por metadata es lo que mantiene la precisión alta y el coste de consulta bajo. Vector search puro sobre un corpus enorme sin prefiltro degrada ambas cosas.

---

## 4. Por qué el procesamiento inicial no debe usar un LLM para el parsing

El usuario ya lo señaló: el coste que importa es el de cada consulta, no el de procesar una vez — pero "procesar una vez" tampoco debe ser caro si se puede evitar:

- **Extracción de texto:** determinista (pdfplumber/unstructured), sin LLM, gratis. Reservar OCR (Tesseract local, o Document AI si hace falta más calidad) solo para los PDFs que resulten ser escaneados — no asumir que todos lo son.
- **Chunking:** reglas (por numeración de cláusula si existe, por párrafo si no) — sin LLM.
- **Embeddings:** Batch API de OpenAI (async, 50% más barato que llamadas síncronas) — encaja con que esto no es tiempo real.
- **Dónde sí vale la pena un LLM:** extracción de metadata ambigua (¿qué `document_type` es este PDF? ¿qué `product_line`?) cuando no se puede inferir por reglas simples del nombre de archivo o encabezado — ahí un paso de clasificación barato (Haiku) por documento, no por chunk, es razonable.

Esto es un pipeline determinista (script), no una tarea para un Agente Nivel 3 de Claude Code por mensaje — más barato y más confiable. Dado el volumen actual ("decenas de PDFs"), no vale la pena automatizar con cron todavía: correrlo una vez manualmente cuando el lote esté listo es suficiente.

---

## 5. Consulta interna (Tier 2)

No es una tool del `RAG IA Agent`. Es un script/endpoint simple que:
1. Embebe la pregunta,
2. filtra por metadata si se conoce el tipo de documento relevante,
3. hace `ORDER BY embedding <=> query_embedding LIMIT k`,
4. devuelve los chunks CON su `source_path` + `page` + `clause_ref`, para que quien consulta pueda verificar contra el PDF original antes de dar el dato por bueno.

La verificación contra el PDF original es **siempre manual** antes de promover algo a `kb_chunks` — este corpus alimenta un canal de cara a cliente indirectamente (vía promoción), así que el mismo estándar de precisión que ya aplica a `kb_chunks` aplica aquí antes de que cualquier fragmento llegue al bot.

---

## 6. Primera fuente real — en ejecución (17 jul 2026)

Alberto entregó el primer PDF del lote: Condiciones Generales completas de Autos (QJ/01 1224-GA, dic 2024), 162 páginas, texto seleccionable — verificado en vivo por el Arquitecto (`pdftotext -layout`, sin OCR necesario, índice estructurado con Cláusula 1ª–26ª y subcláusulas numeradas que sirve de mapa de chunking). Handoff completo con esquema, row de `doc_sources`, índice parseado y spec de chunking: `Agente-n8n/handoffs/2026-07-17-handoff-corpus-documental-doc-chunks-condiciones-generales.md` (PDF fuente adjunto en el mismo directorio).

**Hallazgo colateral:** al revisar la Cláusula 8.1 (Extensión de Cobertura, p.69) para preparar este handoff, se confirmó que **M36 ya no está bloqueado por Juan** — verificado directo en Postgres STG que `kb_chunks` id 34 ya tiene la restricción real de categoría (Automóvil/Pick-up, no camiones/carga/Uber-taxi) aplicada por Agente n8n el mismo 17 jul (commit `31367e4`, handoff de Mejoras Conversación). No fue resultado de este corpus — coincidencia de timing — pero confirma que el texto real del PDF coincide con lo que ya se aplicó.

## 7. Quién ejecuta

Diseño: Arquitecto (este documento). Ejecución del script de ingesta de la primera fuente: **Agente n8n** (ya tiene la credencial `OPENAI_API_KEY` y ya tocó la tabla hermana `kb_chunks`) — handoff entregado, ver §6. Si el corpus crece a más PDFs con cadencia alta, reevaluar si conviene desacoplarlo a un script standalone en vez de vivir dentro de n8n.

## 8. ✅ Sign-off del Arquitecto (17 jul 2026) — primera fuente cerrada

Verificado independientemente contra Postgres STG y n8n STG (no solo leído el reporte de Agente n8n, `Agente-n8n:docs/2026-07-17-ingesta-corpus-documental-doc-chunks-condiciones-generales.md`):

- `doc_sources` id 1: metadata coincide exacto con lo pedido en el handoff.
- `doc_chunks`: 152/152 filas, 152 `chunk_hash` distintos, 0 embeddings nulos, `vector_dims(embedding) = 1536` en el 100% — confirmado por query directa, no por el reporte.
- **Retrieval re-verificado de forma independiente:** generé mi propio embedding de la query de prueba "qué cubre la cobertura de robo total del vehículo" (workflow temporal propio en n8n STG, credencial `OpenAI KB Embeddings STG` nunca leída en texto plano, workflow creado → disparado → **borrado** de inmediato, confirmado 404 tras el borrado) y corrí la búsqueda de similitud coseno yo mismo contra `doc_chunks`: los 5 resultados y sus distancias coinciden **exactos** (4 decimales) con lo reportado por Agente n8n. No hay divergencia.
- Confirmado que no quedó ningún workflow temporal residual en STG (3 workflows totales, ninguno con nombre `TEMP`).

Con esto, la primera fuente del corpus Tier 2 queda cerrada. Pendiente real: solo la ingesta de más PDFs del lote cuando lleguen (§6), no hay nada abierto de esta fuente.
