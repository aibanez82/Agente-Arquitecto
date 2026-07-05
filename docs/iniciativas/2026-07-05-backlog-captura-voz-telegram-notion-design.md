# Diseño — Backlog por captura de voz (Telegram → Claude → Notion)

> Spec aprobada por Alberto el 5 jul 2026 (brainstorming).
> Herramienta interna del equipo (Alberto + Juan). Independiente del flujo de clientes Quálitas.

## Objetivo

Capturar ideas y pendientes del proyecto **sin fricción** — hablándole al móvil — y que se **auto-organicen y se guarden** en un backlog compartido. A Alberto le llegan muchas ideas al día (técnicas, de producto y de negocio) y hoy se pierden o cuesta ordenarlas (Notion se le queda corto en captura, inteligencia y vistas).

## Alcance

**Fase A (MVP — esta spec):** captura sin fricción para Alberto. Nota de voz (o texto) por Telegram → transcripción → Claude clasifica y estructura → fila en una base de Notion → confirmación en Telegram.

**Fase B (crecer, sin rediseño):** que Juan use el mismo bot y ambos sincronicen/prioricen/asignen en la misma base de Notion. El diseño de la Fase A ya es multiusuario (campo Autor por Telegram user id), así que B se activa cuando Juan empiece a usar el bot — sin rediseño.

**Restricción dura:** aunque A se use solo (Alberto) al inicio, el cimiento debe ser **multiusuario/compartible** desde el diseño (si B no se puede incorporar, A no sirve). No mover a Juan de Notion por ahora.

## Decisiones tomadas (brainstorming 5 jul)

1. Corazón = **captura sin fricción (a)**, pero extensible a **compartido/priorizar/asignar (b)**.
2. Notion falla en captura > inteligencia > vistas (en ese orden), pero **se mantiene como store** (Juan lo usa).
3. Canal de captura: **Telegram** (bot dedicado).
4. Cerebro: **Claude** clasifica/estructura detrás del bot.
5. Store/vista: **Notion** (base compartida).
6. Orquestación: **n8n** (Hostinger), workflow nuevo con Telegram Trigger — nativo, sin choque con el bot de WhatsApp.

## Arquitectura

```
Telegram (nota de voz o texto) → [Workflow n8n nuevo — trigger de Telegram]
   → descarga el audio (Telegram file) → OpenAI Whisper (transcribe a texto)
   → Claude clasifica y estructura (structured output)
   → crea fila en la base de Notion (API/nodo Notion)
   → responde en Telegram: "✅ Guardado: [categoría] «título» · prioridad X"
```
Nota técnica: **Claude no transcribe audio** (API de texto) → el paso de speech-to-text lo hace **OpenAI Whisper**. n8n tiene nodos nativos para Telegram, OpenAI (transcribe), Anthropic/HTTP (Claude) y Notion, así que la cadena entera vive en n8n sin construir un servicio aparte.

## Componentes e interfaces

- **Telegram Trigger (n8n):** recibe el mensaje. Si es voz → descarga el file (`.ogg`); si es texto → usa el texto directo.
- **Transcripción (OpenAI Whisper vía nodo n8n):** audio → texto.
- **Clasificador (Claude, structured output):** entrada = texto transcrito; salida JSON = `{ titulo, descripcion, categoria, prioridad, dueño_sugerido }`.
- **Notion (nodo/API):** crea una página en la base con las propiedades del esquema de abajo.
- **Respuesta Telegram:** confirma lo guardado (para que Alberto sepa que cayó bien y corrija en Notion si hace falta).

### Esquema de la base de Notion
| Propiedad | Tipo | Notas |
|---|---|---|
| Título | title | corto, generado por Claude |
| Descripción | text | transcripción limpia + resumen |
| Categoría | select | **Técnico** / **Producto (feature)** / **Negocio** |
| Prioridad | select | Alta / Media / Baja (sugerida por Claude) |
| Estado | select | Idea / Por hacer / En curso / Hecho (default: Idea) |
| Autor | select | Alberto / Juan (según Telegram user id) |
| Dueño | select | Alberto / Juan / (sin asignar) |
| Fecha | date | auto (fecha de captura) |
| Transcripción cruda | text | respaldo por si la limpieza pierde algo |

### Clasificación con Claude
De la transcripción, Claude devuelve título corto, descripción limpia, **categoría** (Técnico/Producto/Negocio), **prioridad** sugerida, y **dueño** sugerido si se menciona ("esto es para Juan"). Structured output para que siempre encaje en el esquema de Notion.

## Multiusuario (Fase B, casi gratis)
El bot identifica al remitente por su **Telegram user id** → rellena "Autor". Notion ya es compartido. Cuando Juan empiece a mandar notas al mismo bot, ambos capturan al mismo backlog y ven/priorizan/asignan en Notion. **El cimiento ya es multiusuario — B no requiere rediseño.**

## Manejo de errores
- Audio inaudible / transcripción vacía → el bot pide repetir.
- Claude o Notion caído/timeout → el bot avisa "no pude guardar, reintenta" — **nunca perder la nota en silencio**.
- Clasificación dudosa → igual se guarda (default Categoría/Prioridad si Claude no está seguro); Alberto corrige en Notion.

## Corrección / confianza
El bot confirma en Telegram lo que entendió. Correcciones se hacen **directo en Notion** (es el store). MVP sin flujo de corrección por chat (YAGNI).

## Testing
Herramienta interna, independiente del flujo de clientes → se prueba sola: mandar notas de prueba (voz y texto) y verificar que caen bien clasificadas en Notion. **NO depende del entorno de staging de Quálitas.** Casos: voz clara, texto, idea con dueño mencionado ("para Juan"), audio inaudible (pide repetir), Notion caído (avisa), categoría de cada tipo (técnico/producto/negocio).

## Dependencias
- Bot de Telegram (token de BotFather).
- API key de OpenAI (Whisper).
- API key de Anthropic (ya en n8n).
- Integration token de Notion + base creada con el esquema + compartida con la integración.
- Telegram user ids de Alberto (y Juan cuando entre) para el campo Autor.

## Fuera de alcance (futuro)
- Flujo de corrección por chat.
- Priorización/asignación asistida por IA (por ahora manual en Notion).
- Deduplicación automática de ideas repetidas.
- Migrar a una herramienta mejor que Notion (Linear, etc.) — descartado por ahora (Juan sigue en Notion).
