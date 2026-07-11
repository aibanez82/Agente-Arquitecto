## Agente Mejoras Conversación — protocolo de uso

**Repo:** `aibanez82/Agente-MejorasConversacion`
**Rol:** especializado en CÓMO conversa el bot (abandono y tono/trato). Nunca modifica nada — solo analiza y propone. Dos modos de entrada, misma tubería de salida.

### Modo 1 — Análisis de abandono (Postgres)

**Credencial DB:** `readonly_leads` en Heroku `hyl-wai-production` (read-only, no puede modificar nada)

> **Patrón de permisos `readonly_leads`:** cada tabla nueva que crea Django NO tiene permiso para
> `readonly_leads` hasta que el dueño de la BD ejecute un `GRANT SELECT` específico. Cuando el
> Dashboard/reporting quiera leer una tabla nueva y dé `permission denied`, la solución es
> `GRANT SELECT ON <tabla> TO readonly_leads;` — **nunca** el grant masivo `ON ALL TABLES`
> (expondría `auth_user` con hashes de contraseñas). El rol dueño es el de `DATABASE_URL`
> (puede granear). Grants aplicados 1 jul 2026: `qualitas_whatsappmessage`, `qualitas_leadactionevent`.
**Output:** archivos en `informes/YYYY-MM-DD-analisis.md`

**Cómo activarlo:** Alberto abre el proyecto en Claude Code y dice:
> "Analiza las conversaciones del [fecha inicio] al [fecha fin]"

**Qué produce (4 pasos internos automáticos):**
1. Query A — leads con abandono (phase en greeting/data_capture/summary_confirmation + last_activity > 48h)
2. Query B — leads exitosos (referencia de conversaciones que llegaron a póliza)
3. Clasificación por outcome + análisis del último mensaje del bot antes del silencio
4. Informe Markdown con mapa de abandono + análisis de copy + hasta 5 recomendaciones concretas de cambio de texto en n8n

**Limitación activa — Bug #1:**
~76% de sesiones no tienen historial en `n8n_chat_histories` (medido 1 jul 2026: 154/203). El agente lo detecta y lo anota, pero el análisis de copy solo cubre el ~24% de conversaciones con datos. Nota: gran parte de ese "vacío" son leads que nunca respondieron (ver Bug #1 reinterpretado), no pérdida de datos. Los resultados son válidos pero parciales.

### Modo 2 — Análisis de tono/trato (capturas de pantalla)

Alberto le pasa capturas de pantalla de conversaciones WhatsApp reales cuando detecta un problema de tono (ej.: el bot trata de "usted" y el caso pide un trato más cercano). El agente identifica QUÉ parte del `systemMessage` del nodo **AI Agent** (n8n) está generando ese tono y propone la modificación EXACTA (frase, ubicación, redacción nueva) — igual que en Modo 1, solo propone, nunca escribe.

**Regla de acceso al `systemMessage`:** el Agente Mejoras Conversación NO tiene acceso directo a n8n. El `systemMessage` completo vive exportado en `docs/n8n-workflows/WhatsApp Insurance Quotation Bot.json` (fuente de verdad en este repo). Cuando este análisis lo requiera, **el Arquitecto extrae y entrega el fragmento relevante como contexto de solo lectura** para ese análisis puntual — consistente con "los ejecutores nunca se hablan entre sí, todo pasa por mí".

**Riesgo transversal que el Arquitecto valida antes de aprobar un cambio de tono (Mejoras no lo ve):**
- **Hitos por LIKE:** un cambio de tono puede tocar sin querer alguna de las frases exactas de las que dependen los hitos (`confirmo_cobertura`, `poliza_emitida_wa`, etc. — ver "Regla de estado real de un lead").
- **Bug #10/#14:** el `systemMessage` (~24K chars) también contiene las instrucciones de serie VIN-17, el manejo del `400 invalid_vehicle_serie` y las SECURITY RULES del deflect fuera de alcance — un cambio de tono cerca de esas secciones puede chocar con ellas.

### Tubería común — Mejoras → Arquitecto → Agente n8n (NO lateral)

Tanto las recomendaciones de copy (Modo 1) como las de tono (Modo 2) se traducen en cambios al `systemMessage` del nodo **AI Agent** en n8n. El **Agente n8n es el ejecutor** de ese cambio (no Mejoras, no Alberto a mano). Pero **Mejoras y n8n NO se comunican directamente** (regla de oro: los ejecutores no se hablan). La tubería es:

```
Agente Mejoras Conversación  → analiza abandono o tono, propone cambios de copy (informe)
        ↓
Arquitecto (yo)              → valida, traduce a cambio EXACTO (qué frase, qué nodo)
                               y CHEQUEA IMPACTO TRANSVERSAL antes de aprobar
        ↓
Agente n8n                   → aplica el cambio en el JSON, commit/push
        ↓
Alberto                      → importa en n8n
```

Es el mismo patrón usado para el Bug #10 (diagnóstico → prompt para el Agente n8n → ejecución). El punto de encuentro de los dos ejecutores es el Arquitecto, nunca el otro agente.
