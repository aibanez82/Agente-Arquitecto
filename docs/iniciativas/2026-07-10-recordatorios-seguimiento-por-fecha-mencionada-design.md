# Iniciativa — Recordatorios de seguimiento cuando el cliente menciona una fecha futura

> Estado: 🟡 Handoff enviado a Juan (16 jul) — ver `docs/2026-07-16-handoff-juan-recordatorios-fecha-mencionada.md`.
> Nada implementado todavía, pero ya no es solo una idea: hay un caso real (lead 1385) que la
> motivó a pasar de "documentada" a "lista para implementar". Encaja en el rol ya reservado de
> "Agente Conversión" (⏳ Futuro en la tabla de arquitectura de agentes de `CLAUDE.md`).
> Autor: Arquitecto-IA-Qualitas · 10 jul 2026 (diseño original), ampliado 16 jul 2026.

## Motivación

En conversaciones reales de WhatsApp, algunos clientes explican por qué no van a contratar
*todavía*, dando una referencia temporal concreta:

- *"El seguro que tengo se vence en un mes"* → follow-up natural: ~30 días después.
- *"Estoy esperando a cobrar la quincena para contratar"* → follow-up natural: el día 15 o el 30
  del mes, el que esté más próximo (en México el pago de nómina típico cae esos dos días).
- *"Lo retomamos el día sábado 18"* → follow-up natural: esa fecha exacta, sin ambigüedad. **Caso
  real, no hipotético** (ver abajo).

Hoy esas conversaciones simplemente se cierran (`[phase:greeting]` o `[phase:completed]` según el
punto en que se corte) y el lead se pierde de vista —no hay ningún mecanismo que recuerde volver a
contactarlo en la fecha que el propio cliente dio. Es una oportunidad de recuperación de leads que
hoy se tira.

## Caso real que motivó pasar de diseño a implementación (16 jul 2026)

**Lead 1385 / cotización 2837** (Toyota Sienna 2012, tel. `527712197809`), conversación real del 16
jul: el cliente preguntó por la cobertura amplia y luego escribió *"lo retomamos el día sabado 18"*.
El bot contestó *"Perfecto, te espero el sábado 18"* y la sesión quedó en `[phase:greeting]` — sin
ningún mecanismo que la retome. `2026-07-18` es sábado, confirmado (`datetime` de Python), consistente
con lo que dijo el cliente.

**Hallazgo que amplía el diseño original:** este NO es ni `vencimiento_1mes` ni `quincena` — es una
tercera categoría, **`fecha_explicita`**, donde el cliente da directamente el día (y a veces el día
de la semana) en el que quiere que lo contactemos. Es, de hecho, el caso más fácil de resolver de
los tres: no hay que inferir nada, solo extraer el número de día que dio el cliente.

**Hallazgo operativo que bloquea el envío, no solo el diseño:** el último mensaje del cliente fue el
16 jul a las 16:53. La ventana de 24h de WhatsApp para texto libre se cierra el 17 jul ~16:53 —
**antes** del sábado 18. Cualquier recordatorio para una fecha futura, por construcción, casi
siempre va a caer fuera de la ventana de 24h (esa es la naturaleza de "recordarle en el futuro").
Hoy **no existe ninguna plantilla de Meta aprobada para re-enganche/recordatorio** — se propuso una
el 5 jul (`docs/2026-07-05-rescate-leads-1046-1103.md`, rescate del Bug #12) y se descartó
deliberadamente en ese momento. Sin plantilla, este sistema completo no puede enviar nada una vez
implementado. Ver sección "Bloqueante" más abajo — deja de ser un "abierto" y pasa a ser el primer
paso a resolver, con tiempo de aprobación de Meta por delante.

## Decisión de arquitectura: detección en batch/offline, NO dentro del AI Agent conversacional

**No** meter esto como una tool call más del AI Agent principal (n8n). Ese prompt ya tiene ~24K
caracteres a `temperature: 0.7` y ya produjo el Bug #10 (VIN↔ciudad) y el Bug #14 (deflect fuera de
alcance) por sobrecarga/inconsistencia del modelo bajo esas condiciones. Añadirle una responsabilidad
más —detectar la mención, clasificarla, y calcular una fecha— es exactamente el tipo de complejidad
que ya le está costando caro.

En su lugar: un **proceso separado, en batch, que lee conversaciones ya guardadas** — mismo patrón
que ya usa el Agente Mejoras Conversación (lectura de Postgres, sin tocar el flujo en vivo).

**Regla dura, no negociable:** el LLM (Haiku) solo **extrae datos crudos del texto** — una
**categoría** (`vencimiento_1mes`, `quincena`, `fecha_explicita`) y, si aplica, los componentes
literales de una fecha mencionada (número de día del mes, nombre del día de la semana) — **nunca
calcula la fecha objetivo ni hace aritmética él mismo**. Esa aritmética la hace Python de forma
determinista, siempre. Es el mismo aprendizaje del Bug #10: no confiar en que un LLM haga bien un
cálculo mecánico cuando se puede hacer con código normal.

## Diseño — 3 piezas

### 1. Tabla nueva `qualitas_lead_reminder` (Django, migración de Juan)

| Columna | Tipo | Nota |
|---|---|---|
| `id` | PK | |
| `lead_id` | FK → `qualitas_lead` | |
| `cotizacion_id` | FK → `qualitas_cotizacion` | |
| `motivo` | text | fragmento original del cliente, para trazabilidad/depuración |
| `categoria` | varchar | `vencimiento_1mes`, `quincena`, `fecha_explicita`, etc. — catálogo abierto, se amplía según se vea uso real |
| `fecha_objetivo` | date | calculada por Python, no por el LLM |
| `estado` | varchar | `pending` / `sent` / `cancelled` / `needs_review` (ver categoría `fecha_explicita` abajo) |
| `mensaje_sugerido` | text | plantilla renderizada, o solo la categoría si se prefiere renderizar al momento de enviar |
| `created_at` / `sent_at` | timestamptz | igual que el resto del esquema — siempre con zona horaria (ver regla de convención en `CLAUDE.md`) |

### 2. Job nocturno de clasificación (management command Django + Heroku Scheduler)

- Ya existe el mecanismo de Scheduler en Heroku (usado para el follow-up de 15 min, ver Issue #74)
  — se añade un job más, no infraestructura nueva.
- Revisa conversaciones de `n8n_chat_histories` nuevas desde la última corrida (o de leads en fase
  `completed`/abandonados sin recordatorio ya creado).
- Llama a **Claude Haiku** (barato, mismo patrón que los nodos Jailbreak Detection / Intent Router
  de n8n) con un prompt de clasificación acotado: dado el texto del cliente, ¿menciona una razón de
  espera con referencia temporal? Si sí, ¿qué categoría (de un catálogo cerrado de opciones)?
- Python calcula `fecha_objetivo` según la categoría:
  - `vencimiento_1mes` → hoy + 30 días.
  - `quincena` → el día 15 o el último día del mes, el que esté más próximo a partir de hoy
    (usar `calendar.monthrange` para el último día real del mes, no asumir "30" fijo — cubre
    febrero y meses de 30/31 días).
  - `fecha_explicita` → el LLM extrae `dia_mes` (1-31) y, si el cliente lo dijo, `dia_semana`.
    Python busca la próxima fecha (desde hoy) cuyo día del mes coincida con `dia_mes` (si ya pasó
    este mes, salta al mes siguiente). Si el cliente también dio `dia_semana`, Python valida que
    coincida con el día de la semana real de la fecha calculada — si coincide, `estado='pending'`
    normal; **si no coincide (señal de que el cliente se confundió, o de un error de extracción),
    `estado='needs_review'` en vez de `pending`**, para que un humano lo confirme antes de que se
    mande solo. Caso real usado para calibrar: lead 1385/cotización 2837, *"lo retomamos el día
    sabado 18"* → `dia_mes=18`, `dia_semana='sábado'`, `2026-07-18` es sábado → coincide, `pending`.
  - Categorías nuevas se agregan según patrones reales que aparezcan (no intentar cubrir todo de
    entrada).
- Inserta en `qualitas_lead_reminder` con `estado='pending'`.

### 3. Job diario de envío (mismo management command o uno separado)

- Busca `qualitas_lead_reminder WHERE estado='pending' AND fecha_objetivo <= hoy`.
- Para cada uno, llama al **webhook proactivo que ya existe**: `POST /webhook/proactive-wa-message`
  (n8n) — el mismo que usa el botón "Tomar conversación" del Dashboard. **No requiere ningún
  workflow nuevo de n8n**, ya está construido, probado, y documentado (`CLAUDE.md`, sección
  "Segundo workflow — mensajes proactivos desde Dashboard").
- Marca `estado='sent'` tras el envío exitoso.
- Respeta las reglas ya documentadas del workflow proactivo: si `last_activity > 24h` en
  `whatsapp_sessions`, Meta puede rechazar el mensaje libre (ventana cerrada) — en ese caso
  probablemente se necesite una plantilla aprobada por Meta en vez de un mensaje de texto libre,
  igual que se resolvió para el rescate de leads del Bug #12.

## Plantillas de mensaje por categoría (borrador, a refinar)

- `vencimiento_1mes`: *"Hola {nombre}, veo que se acerca el vencimiento de tu seguro anterior — ¿seguimos con tu cotización del {vehiculo}?"*
- `quincena`: *"Hola {nombre}, ya es quincena 🎉 — ¿continuamos con tu póliza del {vehiculo}?"*
- `fecha_explicita`: *"Hola {nombre}, quedamos en retomar hoy tu cotización del {vehiculo} — ¿seguimos?"*

## Reparto de trabajo

| Pieza | Responsable |
|---|---|
| Tabla + migración | Juan (Django/Heroku, como todo cambio de schema de producción) |
| Jobs de clasificación y envío | Juan (o quien tenga acceso de escritura a la BD de PROD) |
| Workflow n8n nuevo | **Ninguno necesario** — reutiliza el webhook proactivo existente |
| Prompt de clasificación Haiku + plantillas de mensaje | Arquitecto (diseño) → se entrega como parte del handoff cuando se decida implementar |

## 🔴 Bloqueante — plantilla de Meta aprobada (ya no es un "abierto", 16 jul)

Sin una plantilla de re-enganche/recordatorio aprobada por Meta, **este sistema no puede enviar
nada** en el caso general: un recordatorio para una fecha futura, por definición, casi siempre cae
fuera de la ventana de 24h de texto libre. Hoy no existe ninguna plantilla así (se propuso y se
descartó el 5 jul en el rescate del Bug #12). Este es el primer paso a resolver, no el último —
tiene tiempo de aprobación de Meta por delante y bloquea todo lo demás. Dueño: quien administra
Meta Business Manager (Juan, o quien él delegue).

## Abierto / pendiente de decidir antes de implementar

- Catálogo inicial de categorías — arrancar con `vencimiento_1mes`, `quincena` y `fecha_explicita`
  (los 3 casos reales que motivaron esto, el último con evidencia concreta del lead 1385) y ampliar
  según se vea uso real, en vez de intentar anticipar todas las variantes posibles de entrada.
- Volumen esperado — no medido todavía cuántas conversaciones reales mencionan este tipo de señal;
  vale la pena correr el job de clasificación en modo "solo reportar" (sin insertar recordatorios)
  sobre el historial existente antes de activar el envío real, para dimensionar el impacto.
