# Spec para Code Agent — Dashboard: conversación de WhatsApp completa (n8n + Django) en una sola línea de tiempo

> Autor: Arquitecto-IA-Qualitas · Fecha: 1 julio 2026
> Repo destino: `aibanez82/Dashboard_seguroautoqualitas`
> Ejecutor: Agente Dashboard (Nivel 3)
> Supersede el alcance de `docs/estrategia/2026-07-01-fix-dashboard-mostrar-envios.md`: aquella spec
> proponía una sección aditiva separada ("Mensajes enviados"); esta pide **fusionar** ambas fuentes
> en una sola vista cronológica de la conversación. Esta spec absorbe y reemplaza esa anterior.

---

## Problema

El modal del lead en el Dashboard solo muestra la conversación de WhatsApp que vive en
`n8n_chat_histories`. Pero hay mensajes salientes que Django manda directo (saludo inicial,
follow-ups por template) y que quedan en **`qualitas_whatsappmessage`**, tabla que el Dashboard
no lee. Resultado: la vista de conversación de un lead está incompleta — se ven las respuestas
del cliente y lo que contestó el bot de n8n, pero no siempre se ve qué le mandó Django antes de
que n8n entrara en juego.

Se quiere una sola conversación, en orden, con ambas fuentes mezcladas — no dos paneles separados.

---

## Paso 0 — Verificar el schema real antes de escribir código (bloqueante)

Este es el riesgo principal de la spec y hay que resolverlo primero, con una query directa vía
`lib/db.js`, antes de tocar UI:

```sql
\d n8n_chat_histories
```

**Por qué importa:** el patrón estándar de la Postgres Chat Memory de n8n (LangChain) **no incluye
columna de timestamp** — solo `id` (autoincremental), `session_id`, `message` (JSONB). La regla ya
documentada en CLAUDE.md es "ordenar por `id`", nunca por fecha, porque no hay fecha.
`qualitas_whatsappmessage`, en cambio, sí tiene `sent_at`/`failed_at` (`timestamptz`) reales.

Si se intenta fusionar ambas fuentes ordenando una por `id` y otra por `sent_at`, el orden relativo
entre las dos fuentes **no está garantizado** — solo el orden interno de cada una por separado.

**Verificar además:**
```sql
SELECT message->'response_metadata', message->'additional_kwargs'
FROM n8n_chat_histories
ORDER BY id DESC LIMIT 5;
```
Es posible que n8n esté escribiendo algo utilizable ahí (algunas configuraciones de LangChain
incluyen metadata de tiempo de ejecución). Si esos campos vienen vacíos (`{}`), confirma que no
hay timestamp real disponible y hay que usar la Opción B de la sección siguiente.

---

## Opción A — Si `n8n_chat_histories` sí tiene timestamp real

Fusionar directo por timestamp real de ambas tablas, unificado por `America/Mexico_City`, orden
`ASC`. Este es el caso simple; si el Paso 0 confirma esto, saltar a la sección "UI" abajo con esta
lógica de merge.

## Opción B — Si NO hay timestamp real en n8n (caso más probable)

No inventar una fecha falsa para los mensajes de n8n. En vez de eso:

1. Traer los mensajes de `n8n_chat_histories` ordenados por `id` (orden relativo correcto entre
   ellos) — **sin** asignarles hora de reloj.
2. Traer los mensajes de `qualitas_whatsappmessage` con su `sent_at`/`failed_at` real.
3. Anclar los mensajes de n8n a un punto conocido del tiempo: el primer mensaje de n8n de una
   sesión ocurre siempre *después* de que el cliente respondió al saludo/follow-up de Django (ver
   `docs/estrategia/2026-07-01-mejora-conversion-leads.md` — el 93%+ de sesiones n8n solo existen
   cuando el humano contesta). Usar como ancla el `sent_at` del mensaje de Django inmediatamente
   anterior al primer registro de `n8n_chat_histories` de esa sesión, y desde ahí insertar el
   bloque completo de n8n como un solo tramo posterior, en su orden interno por `id`.
4. Si llegan más envíos de Django (ej. un follow-up) con `sent_at` posterior al bloque de n8n ya
   ubicado, van después de ese bloque, no intercalados dentro de él (no hay forma de saber en qué
   punto exacto del intercambio de n8n cayó un follow-up de Django que Meta rechazó por ventana
   cerrada, por ejemplo).
5. **En la UI, marcar visualmente qué mensajes tienen hora exacta (Django) y cuáles son de orden
   aproximado (n8n)** — un ícono o tooltip "hora aproximada" es preferible a fingir precisión que
   no existe. No hay que resolver el problema de fondo (falta de timestamp en n8n) en el Dashboard;
   solo no ocultar la limitación.

---

## Fuentes de datos

### `qualitas_whatsappmessage` (Django, saliente)

| Columna | Tipo | Uso |
|---|---|---|
| `template_name` | varchar | Nombre de plantilla (ej. `cotizacion_followup_15m`) |
| `direction` | varchar | `OUTBOUND` |
| `status` | varchar | `sent` / `failed` |
| `sent_at` | timestamptz | Hora real de envío |
| `failed_at` | timestamptz | Hora real de fallo |
| `error_code` / `error_message` | varchar / text | Detalle de fallo (Meta) |
| `provider_message_id` | varchar | `wamid...`, acuse de Meta |
| `lead_id` / `cotizacion_id` | bigint | FKs |

### `n8n_chat_histories` (n8n, bidireccional)

| Columna | Tipo | Uso |
|---|---|---|
| `id` | bigint | Orden relativo (NO hora) |
| `session_id` | varchar | Teléfono con prefijo país — cruzar con `whatsapp_sessions.session_id` |
| `message` | jsonb | `message->>'type'` (`human`/`ai`), `message->>'content'` |

### Join de identidad (ya documentado en CLAUDE.md, repetido aquí por completitud)

```
n8n_chat_histories.session_id
  → whatsapp_sessions.session_id
  → whatsapp_sessions.quotation_id = qualitas_cotizacion.id
  → qualitas_lead.cotizacion_id = qualitas_cotizacion.id
  → qualitas_whatsappmessage.lead_id / cotizacion_id
```

> Usar siempre `lib/db.js`. Read-only — ninguna de las dos tablas se escribe desde el Dashboard.

---

## UI en el modal del lead

- Un solo timeline, no dos secciones.
- Cada entrada muestra: quién habla (Django saliente / n8n-bot / cliente), contenido, hora (exacta
  o aproximada según Opción B), y si es un envío de Django con `status=failed`, badge rojo con
  `error_message`.
- Etiqueta legible de plantillas técnicas (`cotizacion_followup_15m` → "Recordatorio 15 min").
- Si el lead tiene envíos de Django pero cero respuesta del cliente, dejarlo explícito: "Le
  escribimos N veces, sin respuesta" — no debe leerse como "no se le mandó nada".
- No exponer `raw_response` de Meta en la UI.

---

## Criterios de aceptación

1. El modal del lead 952 (cotización 2404) muestra en **una sola línea de tiempo** el saludo
   inicial, el follow-up de los 15 min, y cualquier mensaje de n8n/cliente de esa sesión, en orden.
2. Si Paso 0 confirma que no hay timestamp real en n8n, los mensajes de n8n se muestran marcados
   como "orden aproximado" en vez de con una hora inventada.
3. Un envío `failed` de Django se ve en rojo con su `error_message`, dentro del mismo timeline.
4. La vista funciona aunque `n8n_chat_histories` esté vacío para ese lead (fallback a solo
   Django).
5. Horas en `America/Mexico_City`.
6. Reemplaza — no coexiste con — cualquier implementación previa de la sección separada
   "Mensajes enviados" si ya se había construido a partir de la spec anterior.

## Nota para el Arquitecto (reportar de vuelta)

Cuando el Agente Dashboard corra el Paso 0, que reporte el resultado exacto de `\d
n8n_chat_histories` — esto resuelve una duda abierta de arquitectura (si n8n realmente no guarda
timestamp, vale la pena evaluar a futuro pedirle a Juan/n8n que agregue una columna
`created_at DEFAULT now()` en esa tabla, para eliminar el problema de raíz en vez de mitigarlo en
el Dashboard).
