# Iniciativa — Recordatorios de seguimiento cuando el cliente menciona una fecha futura

> Estado: 💡 Documentada, sin implementar. Encaja en el rol ya reservado de "Agente Conversión"
> (⏳ Futuro en la tabla de arquitectura de agentes de `CLAUDE.md`).
> Autor: Arquitecto-IA-Qualitas · 10 jul 2026, a partir de una idea de Alberto.

## Motivación

En conversaciones reales de WhatsApp, algunos clientes explican por qué no van a contratar
*todavía*, dando una referencia temporal concreta:

- *"El seguro que tengo se vence en un mes"* → follow-up natural: ~30 días después.
- *"Estoy esperando a cobrar la quincena para contratar"* → follow-up natural: el día 15 o el 30
  del mes, el que esté más próximo (en México el pago de nómina típico cae esos dos días).

Hoy esas conversaciones simplemente se cierran (`[phase:completed]`) y el lead se pierde de vista
—no hay ningún mecanismo que recuerde volver a contactarlo en la fecha que el propio cliente dio.
Es una oportunidad de recuperación de leads que hoy se tira.

## Decisión de arquitectura: detección en batch/offline, NO dentro del AI Agent conversacional

**No** meter esto como una tool call más del AI Agent principal (n8n). Ese prompt ya tiene ~24K
caracteres a `temperature: 0.7` y ya produjo el Bug #10 (VIN↔ciudad) y el Bug #14 (deflect fuera de
alcance) por sobrecarga/inconsistencia del modelo bajo esas condiciones. Añadirle una responsabilidad
más —detectar la mención, clasificarla, y calcular una fecha— es exactamente el tipo de complejidad
que ya le está costando caro.

En su lugar: un **proceso separado, en batch, que lee conversaciones ya guardadas** — mismo patrón
que ya usa el Agente Mejoras Conversación (lectura de Postgres, sin tocar el flujo en vivo).

**Regla dura, no negociable:** el LLM (Haiku) solo clasifica una **categoría** (`vencimiento_1mes`,
`quincena`, etc.) a partir del texto — **nunca calcula la fecha objetivo él mismo**. La aritmética de
fechas la hace Python de forma determinista. Es el mismo aprendizaje del Bug #10: no confiar en que
un LLM haga bien un cálculo mecánico cuando se puede hacer con código normal.

## Diseño — 3 piezas

### 1. Tabla nueva `qualitas_lead_reminder` (Django, migración de Juan)

| Columna | Tipo | Nota |
|---|---|---|
| `id` | PK | |
| `lead_id` | FK → `qualitas_lead` | |
| `cotizacion_id` | FK → `qualitas_cotizacion` | |
| `motivo` | text | fragmento original del cliente, para trazabilidad/depuración |
| `categoria` | varchar | `vencimiento_1mes`, `quincena`, `dos_semanas`, etc. — catálogo abierto, se amplía según se vea uso real |
| `fecha_objetivo` | date | calculada por Python, no por el LLM |
| `estado` | varchar | `pending` / `sent` / `cancelled` |
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

## Reparto de trabajo

| Pieza | Responsable |
|---|---|
| Tabla + migración | Juan (Django/Heroku, como todo cambio de schema de producción) |
| Jobs de clasificación y envío | Juan (o quien tenga acceso de escritura a la BD de PROD) |
| Workflow n8n nuevo | **Ninguno necesario** — reutiliza el webhook proactivo existente |
| Prompt de clasificación Haiku + plantillas de mensaje | Arquitecto (diseño) → se entrega como parte del handoff cuando se decida implementar |

## Abierto / pendiente de decidir antes de implementar

- Catálogo inicial de categorías — arrancar solo con `vencimiento_1mes` y `quincena` (los 2 casos
  reales que motivaron esto) y ampliar según se vea uso real, en vez de intentar anticipar todas
  las variantes posibles de entrada.
- ¿Reintentos si el envío falla (ventana de 24h cerrada)? Probablemente reusar el mismo patrón de
  plantilla-aprobada-por-Meta que ya se documentó para el rescate de leads del Bug #12.
- Volumen esperado — no medido todavía cuántas conversaciones reales mencionan este tipo de señal;
  vale la pena correr el job de clasificación en modo "solo reportar" (sin insertar recordatorios)
  sobre el historial existente antes de activar el envío real, para dimensionar el impacto.
