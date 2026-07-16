# Handoff para Juan — recordatorios cuando el cliente menciona una fecha futura

**Fecha:** 16 jul 2026
**De:** Arquitecto-IA-Qualitas (vía Alberto)
**Para:** Juan
**Estado:** diseño completo, listo para implementar. Diseño extendido/vivo en
`Agente-Arquitecto:docs/iniciativas/2026-07-10-recordatorios-seguimiento-por-fecha-mencionada-design.md`
— este documento es el resumen accionable.

## Por qué

Alberto rescata manualmente conversaciones de WhatsApp que quedan a medias, con buenos resultados.
Muchas veces el cliente mismo da la razón y la fecha: *"mi seguro vence en un mes"*, *"cobro la
quincena"*, o directamente *"lo retomamos el sábado 18"*. Hoy esas conversaciones se cierran sin que
nada recuerde volver a contactar al cliente en la fecha que él mismo dio. Esto automatiza eso.

**Caso real que lo disparó (no hipotético):** lead 1385 / cotización 2837 (Toyota Sienna 2012, tel.
`7712197809`), conversación del 16 jul: el cliente escribió *"lo retomamos el día sabado 18"*, el
bot contestó *"te espero el sábado 18"* y ahí quedó — sin ningún mecanismo de retomarlo.

## Principio de diseño — no negociable

**No** tocar el AI Agent conversacional de n8n para esto — ya está sobrecargado (Bug #10, Bug #14).
Es un **proceso separado, en batch, que lee conversaciones ya guardadas**, mismo patrón que ya usa
el Agente Mejoras Conversación.

**El LLM (Haiku) solo extrae datos crudos del texto — nunca calcula fechas.** Categoría, y si
aplica, el día del mes / día de la semana mencionados literalmente. Toda la aritmética de fechas la
hace Python de forma determinista. Mismo aprendizaje del Bug #10.

**No se agrega ningún campo de estado nuevo en `qualitas_lead` ni `whatsapp_sessions`.**

## 🔴 Antes que nada — plantilla de Meta (esto bloquea todo lo demás)

Un recordatorio para una fecha futura, por construcción, casi siempre cae **fuera de la ventana de
24h** de WhatsApp para texto libre (el cliente no ha escrito nada desde la fecha en que se cerró la
conversación hasta la fecha del recordatorio). **Hoy no existe ninguna plantilla aprobada por Meta
para este caso** — se propuso una el 5 jul (rescate del Bug #12) y se descartó en ese momento.

**Necesitamos que sometas a aprobación de Meta una plantilla genérica de re-enganche/recordatorio**
lo antes posible — el tiempo de aprobación de Meta es la parte más lenta de todo este handoff, así
que es lo primero que debería arrancar, en paralelo al resto. Sugerencia de contenido (ajústalo a lo
que Meta suela aprobar sin fricción, ya tienen experiencia con `cotizacion_inicial_link`):

> "Hola {{1}}, quedamos en retomar tu cotización de seguro — ¿seguimos?"

Con eso alcanza para las 3 categorías de abajo (el texto específico de cada categoría se manda como
mensaje normal *después* de que la plantilla reabre la ventana, si Meta lo permite; si no, la
plantilla misma lleva el texto final).

## Las 3 categorías

| Categoría | Detección (Haiku extrae, texto crudo) | Cálculo (Python, determinista) |
|---|---|---|
| `vencimiento_1mes` | cliente dice que su seguro actual vence "en un mes" / da duración aproximada | hoy + 30 días |
| `quincena` | cliente menciona cobrar quincena/nómina, "el 15", "fin de mes" como referencia de pago | día 15 o último día del mes (`calendar.monthrange`), el que esté más próximo desde hoy |
| `fecha_explicita` | cliente da una fecha concreta: número de día del mes, y opcionalmente el día de la semana ("el sábado 18", "el lunes que viene", "el 20") | próxima fecha desde hoy cuyo día del mes coincide con `dia_mes` extraído. Si también dio `dia_semana`, Python valida que coincida con el día de la semana real calculado — si no coincide, `estado='needs_review'` en vez de `pending'` (posible confusión del cliente o error de extracción, que lo confirme un humano antes de mandarse solo) |

Ejemplo de calibración real: *"lo retomamos el día sabado 18"* (16 jul 2026) → `categoria=fecha_explicita`,
`dia_mes=18`, `dia_semana='sábado'`. Python calcula `2026-07-18`, confirma que es sábado → coincide
→ `fecha_objetivo=2026-07-18`, `estado=pending`.

## Prompt de clasificación (Haiku) — borrador, ajustar si hace falta

```
Eres un clasificador. Dado un mensaje de un cliente en una conversación de cotización de seguro de
auto, determina si menciona una razón para esperar antes de contratar, con referencia temporal.

Categorías posibles:
- vencimiento_1mes: el cliente dice que su seguro actual vence "en un mes" o da una duración
  aproximada similar.
- quincena: el cliente menciona que va a cobrar la quincena, nómina, o usa "el día 15" / "fin de
  mes" como referencia de cuándo podrá pagar.
- fecha_explicita: el cliente da una fecha concreta (día del mes, y opcionalmente día de la semana)
  para retomar la conversación. Ej: "el sábado 18", "el lunes que viene", "el 20 de julio".
- ninguna: no aplica ninguna de las anteriores.

Si la categoría es fecha_explicita, extrae también:
- dia_mes: el número de día del mes mencionado (1-31), o null si no se dio.
- dia_semana: el nombre del día de la semana mencionado en minúsculas (lunes...domingo), o null.

Responde solo con JSON, sin texto adicional:
{"categoria": "vencimiento_1mes|quincena|fecha_explicita|ninguna", "dia_mes": null_o_numero, "dia_semana": null_o_string}
```

## Tabla nueva — `qualitas_lead_reminder`

| Columna | Tipo | Nota |
|---|---|---|
| `id` | PK | |
| `lead_id` | FK → `qualitas_lead` | |
| `cotizacion_id` | FK → `qualitas_cotizacion` | |
| `motivo` | text | fragmento original del cliente, trazabilidad |
| `categoria` | varchar | `vencimiento_1mes` / `quincena` / `fecha_explicita` — catálogo abierto |
| `fecha_objetivo` | date | calculada por Python |
| `estado` | varchar | `pending` / `needs_review` / `sent` / `cancelled` |
| `mensaje_sugerido` | text | plantilla renderizada, o solo la categoría si prefieres renderizar al enviar |
| `created_at` / `sent_at` | timestamptz | con zona horaria, como el resto del esquema (convención en `CLAUDE.md` del Arquitecto) |

## Job nocturno de clasificación

- Management command Django + Heroku Scheduler (mismo mecanismo que ya usan para el follow-up de
  15 min, Issue #74 — no es infraestructura nueva).
- Revisa mensajes nuevos de `n8n_chat_histories` desde la última corrida.
- Llama a Haiku con el prompt de arriba por cada mensaje humano nuevo relevante.
- Si `categoria != 'ninguna'`, Python calcula `fecha_objetivo` según la tabla de cálculo de arriba
  e inserta en `qualitas_lead_reminder`.

## Job diario de envío

- Busca `qualitas_lead_reminder WHERE estado='pending' AND fecha_objetivo <= hoy`.
- Llama al **webhook proactivo que ya existe**: `POST /webhook/proactive-wa-message` (n8n) — el
  mismo que usa el botón "Tomar conversación" del Dashboard y el mismo que se está usando para la
  iniciativa paralela de seguimiento de leads estancados (`Agente-n8n:docs/2026-07-16-handoff-para-juan-seguimiento-leads-consolidado.md`).
  **No requiere workflow nuevo de n8n.**
- Si la ventana de 24h está cerrada (caso normal para esto), el envío debe pasar primero por la
  plantilla de Meta aprobada (ver bloqueante arriba) antes de mandar el texto libre.
- Marca `estado='sent'` tras éxito.
- `needs_review` NO se envía automáticamente — requiere que alguien lo revise y lo pase a `pending`
  manualmente (o se agregue un paso de confirmación simple más adelante).

## Checklist de lo que falta

1. ⬜ **Someter a aprobación de Meta la plantilla de re-enganche/recordatorio — empezar ya, es lo
   más lento de todo esto.**
2. ⬜ Modelo `LeadReminder` (o el nombre que prefieras, distinto de `LeadFollowupPolicy` — esa es
   la tabla de la iniciativa paralela de leads estancados, no de esta) + migración.
3. ⬜ Job nocturno de clasificación (Haiku + cálculo determinista en Python).
4. ⬜ Job diario de envío (reusa el webhook proactivo existente).
5. ⬜ Arrancar en modo "solo reportar" (clasificar e insertar, sin enviar) sobre el historial
   existente para medir volumen real antes de activar el envío.
6. ⬜ Confirmar con Alberto los textos finales de plantilla y de cada categoría antes de activar en
   PROD.

## Reparto de trabajo

| Pieza | Responsable |
|---|---|
| Plantilla de Meta | Juan (o quien administre Meta Business Manager) — **arrancar primero** |
| Tabla + migración + jobs | Juan (Django/Heroku) |
| Workflow n8n nuevo | Ninguno necesario — reutiliza el webhook proactivo existente |
| Prompt de clasificación + textos de plantilla | Arquitecto (ya entregado arriba, ajustar si Meta pide cambios) |
| Confirmación de textos finales antes de PROD | Alberto |
