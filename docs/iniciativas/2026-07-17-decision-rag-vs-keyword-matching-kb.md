# Decisión — RAG real vs. keyword matching en `search_knowledge_base1` (17 jul 2026)

> Responde a: `Agente-MejorasConversacion/docs/2026-07-17-pregunta-arquitecto-rag-vs-keyword-matching.md`
> Issue técnico: `github.com/aibanez82/qualitas-issues/issues/42`

## Verificación

Confirmado contra el export real de producción (`docs/n8n-workflows/WhatsApp Insurance Quotation Bot.json`, nodo `search_knowledge_base1`, no la copia `pre-deploy-2026-07-14/`): es un objeto JS con 11 secciones, cada una con `keywords` fijas y `q.includes(stripAccents(kw))`. Sin nodo de embeddings ni vector store en el workflow. El hallazgo de Mejoras Conversación es preciso.

## Decisión

**Por ahora, NO migrar a RAG real. Mantener y ampliar keyword matching.** Revisar esta decisión si se cumple el trigger de abajo.

**Por qué:**
- Volumen actual bajo: 4 hallazgos de hueco de KB en 2 semanas (M21, M23, M33, M36) — no un patrón de alto volumen todavía, es detectable y parcheable caso por caso.
- El contenido base (11 secciones, citando Condiciones Generales QJ/01 1224 - GA) es reusable sea cual sea el mecanismo de recuperación — no se pierde nada por esperar.
- Migrar a RAG real implica tocar el nodo central de respuestas del bot en producción (elegir vector store, generar embeddings, cambiar el tool, probar regresión de las 11 secciones) — costo y riesgo no triviales para un problema que hoy se mitiga con una lista de sinónimos.
- El patrón de fallo (reformulación → NOT_FOUND → deflect a humano) es doloroso pero no silencioso: cada caso ya se está detectando (Mejoras Conversación) y parcheando (Agente n8n) en menos de 24-48h.

**Trigger para reabrir esta decisión:** si en las próximas 2 semanas aparecen >3 hallazgos nuevos de tipo "reformulación no matchea keyword existente" (patrón M33/M36), o si ampliar keywords empieza a causar colisiones (una keyword nueva hace matchear secciones no relacionadas), reconsiderar RAG real como mediano plazo.

## Respuesta a las 3 preguntas

1. **¿Migrar a RAG real ahora?** No todavía — ver decisión arriba. Mantenimiento manual de keywords es aceptable al volumen actual.
2. **¿Quién revisa/actualiza las keywords?** Misma tubería ya establecida para copy (`CLAUDE.md` § Agente Mejoras Conversación): Mejoras Conversación detecta el hueco y propone las keywords/sinónimos exactos → Arquitecto valida (evita colisión con otras secciones, confirma que el `content` correcto ya existe) → **Agente n8n** aplica el cambio en el JS del nodo `search_knowledge_base1` y hace commit/push → Alberto importa en n8n. No es un canal nuevo, es el mismo protocolo.
3. **M36 (Extensión RC al Titular, restricción de categoría/peso):** no es un problema de arquitectura de búsqueda — la sección `coberturas` sí matchea, el `content` simplemente nunca incluyó esa restricción. Sigue pendiente de Juan (dato de negocio real, no un fix de código). Fuera del alcance de esta decisión.

## Seguimiento

- Issue #42 en `qualitas-issues` queda **abierto, sin cerrar** — es deuda de arquitectura real, esta decisión solo pospone la migración, no la descarta. Comentado con el link a este doc.
- Cuando Mejoras Conversación proponga las keywords de M33 ("promoción", "descuento", "precio especial", "oferta" → sección `pagos`) y M36 (ampliar `content` de Extensión RC al Titular una vez Juan confirme la restricción), pasan por Agente n8n como cualquier otro parche.
