# Handoff Arquitecto → Agente n8n — Fix leak "KB"/link indebido (#53) + fix "[Nombre]" literal (#54)

> Autor: Arquitecto-IA-Qualitas · 20 jul 2026
> Ejecutor: **Agente n8n**.
> Gobernanza: reportas al Arquitecto **a través de Alberto**. No hablas con otros agentes.
> Copia canónica: `Agente-Arquitecto:docs/2026-07-20-handoff-agente-n8n-fixes-leak-kb-y-nombre.md` — deja también copia en `Agente-n8n/handoffs/`.
> **Prioridad: crítica** (según Alberto) — evidencia real en PROD hoy, 2 conversaciones distintas.
> **Rama destino: `stg` primero**, como siempre.

Dos bugs distintos, mismo lote porque ambos son ediciones de `systemMessage` en los mismos
nodos y conviene probarlos juntos.

---

## Fix 1 — Issue #53: leak de "KB" + link prohibido en pregunta de descuento específico

### Evidencia real

`n8n_chat_histories`, cotización 3037, tel. 7771894869, 20 jul ~22:31 UTC, msg id 7732. Cliente
pregunta "Y de cuánto es el descuento" (Sedena) → `search_knowledge_base1` devuelve chunks
genéricos sin el % exacto → el bot responde:
```
"La KB no especifica el porcentaje exacto del descuento Sedena. El monto varía según tu perfil
y la póliza. Para conocer el descuento exacto que aplica a tu cotización, te recomiendo
contactar con un agente especializado: [link]..."
```

### Dos violaciones en el mismo mensaje

1. Menciona "la KB" literalmente — filtra terminología interna.
2. Ofrece el link de agente especializado en un contexto donde el propio prompt ya lo prohíbe
   explícitamente (regla EDGE CASE de "promociones/descuentos", ver abajo) — no siguió esa
   regla ni tampoco usó el texto EXACTO de fallback ya definido para el caso NOT_FOUND real.

### Dónde vive (confirmado en el workflow vivo de PROD vía API — nodos `AI Agent` y `RAG IA
### Agent`, ambos tienen reglas equivalentes, aplicar el fix en los dos)

**Regla 3 (o equivalente) — "nunca reveles la fuente":** hoy dice (`RAG IA Agent`):
```
3. Responde con seguridad y naturalidad — NUNCA uses frases como "según la información
disponible", "según nuestra base de conocimiento", "de acuerdo a mis fuentes" ni similares
```
Cambiar a (agrega la prohibición explícita de la palabra "KB" y sinónimos sueltos, no solo las
3 frases de ejemplo):
```
3. Responde con seguridad y naturalidad — NUNCA uses frases como "según la información
disponible", "según nuestra base de conocimiento", "de acuerdo a mis fuentes" ni similares.
NUNCA menciones la palabra "KB", "base de conocimiento", "documento" ni "fuente" en tu
respuesta al cliente, ni siquiera de forma aislada (ej. "la KB no especifica..." está
PROHIBIDO) — esas palabras son para tu razonamiento interno, nunca para el mensaje final.
```
Aplicar el mismo agregado en `AI Agent` (que también usa "la KB" varias veces en sus propias
instrucciones — mismo riesgo de que el modelo lo repita).

**Regla equivalente al fallback NOT_FOUND (regla 2 en `RAG IA Agent`, sección de
`get_quotation_data`/KB en `AI Agent`):** reforzar que cuando no hay un dato específico
(ej. un porcentaje exacto), el modelo debe usar el texto EXACTO ya definido de fallback —
nunca una paráfrasis propia. Agregar una línea explícita tipo:
```
Si la KB (razonamiento interno) no tiene el dato específico que te piden (ej. un porcentaje o
monto exacto) pero sí confirma que el beneficio/cobertura existe en términos generales: usa
EXACTAMENTE el texto de fallback definido arriba ("No conozco esta respuesta, pero si lo
deseas...") — NUNCA inventes una explicación propia de por qué no tenés el dato.
```

### Nota de producto que dejo abierta, no la resolví yo

La regla EDGE CASE de "promociones/descuentos" (`AI Agent`) dice "NUNCA ofrezcas el link... el
bot ya tiene toda la información necesaria" — pensada para preguntas genéricas sin contexto.
Acá el cliente venía de un hilo específico (convenio Sedena), donde SÍ tiene sentido que el bot
intente responder con el KB en vez de redirigir a MSI. No cambies el alcance de esa regla EDGE
CASE sin que Alberto lo pida — el fix de arriba (nunca improvisar, usar el texto exacto) ya
resuelve el síntoma real sin tocar esa decisión de producto.

---

## Fix 2 — Issue #54: "[Nombre]" literal cuando el nombre no está disponible

### Evidencia real

`n8n_chat_histories`, cotización 3040, tel. 7471006470, 20 jul ~22:32 UTC, msg id 7734.
**Primer mensaje de la conversación** (fase `greeting`, antes de cualquier dato capturado).
Cliente dice "Gracias quedo pendiente" → bot responde:
```
"¡Perfecto! Aquí estoy cuando quieras continuar, [Nombre]. Solo te recuerdo: tu cotización..."
```

### Causa raíz (confirmado leyendo Django, no solo el prompt)

`get_quotation_data` (`HYL-WAI:qualitas/views.py:api_obtener_detalle_cotizacion`, línea ~774,
endpoint `/api/cotizacion/detalle/`) **nunca devuelve el nombre del cliente** — el dict de
respuesta completo trae email, teléfono, CP, datos del vehículo, opciones de cotización, etc.,
pero ningún campo de nombre. El nombre real solo se conoce después de que el cliente lo da en
el Grupo 1 de `DATA_CAPTURE`.

El `systemMessage` de `AI Agent` instruye "usa el nombre real del cliente (de
get_quotation_data)" y usa `[Nombre]` como placeholder en varias plantillas (saludo, cierre
MSI, cancelación, corrección de datos, resumen), varias marcadas para disparar "en CUALQUIER
fase". Cuando ninguna de las dos fuentes tiene el nombre todavía (como en este caso, fase
`greeting`, primer mensaje), el modelo no tiene nada que sustituir y repite el placeholder
literal de sus propias instrucciones.

**No es un caso raro** — cualquier plantilla personalizada con nombre que dispare antes del
Grupo 1 va a fallar igual mientras el cliente no haya dado su nombre.

### Fix propuesto

Agregar una regla explícita de seguridad en `AI Agent` (no requiere tocar Django ni
`get_quotation_data` — ver nota abajo), cerca de donde se explica el uso de `[Nombre]`:
```
REGLA DE SEGURIDAD — NOMBRE NO DISPONIBLE:
Si NO conocés el nombre real del cliente todavía (get_quotation_data no lo trae — nunca lo
trae antes del Grupo 1 — y el cliente tampoco lo ha dado en la conversación), NUNCA escribas
"[Nombre]" literalmente en tu respuesta. Omití el nombre y redactá la frase sin él. Ejemplo:
en vez de "Aquí estoy cuando quieras continuar, [Nombre]." → "Aquí estoy cuando quieras
continuar."
```
Aplicar el mismo criterio a TODAS las plantillas con `[Nombre]` en el prompt (saludo, MSI,
cancelación, corrección, resumen) — no es una plantilla aislada, es una regla general.

### Nota — no propongo tocar Django

No está claro que el nombre exista en Django antes del Grupo 1 (el landing no necesariamente
lo captura al cotizar). Agregar el campo a `get_quotation_data` podría no resolver nada si el
dato simplemente no existe ahí. Si Alberto confirma que sí existe en algún punto anterior del
funnel, es una mejora aparte — este fix (omitir en vez de leakear) es correcto de todos modos
como safeguard, incluso si más adelante se agrega una fuente real de nombre.

---

## Tareas

1. Aplicar los 2 fixes en `stg`:
   - Fix 1: reforzar regla 3 (anti-leak) + regla de fallback exacto, en `AI Agent` Y `RAG IA
     Agent` (ambos tienen el riesgo).
   - Fix 2: agregar la regla de seguridad de nombre no disponible en `AI Agent`, aplicable a
     todas las plantillas con `[Nombre]`.
2. Probar en STG:
   - Simular una pregunta de descuento específico donde el KB no tenga el número exacto —
     confirmar que la respuesta usa el texto exacto de fallback, sin mencionar "KB" y sin
     mezclar explicaciones propias.
   - Simular el primer mensaje de una conversación (fase greeting, antes de Grupo 1) que
     dispare una plantilla con nombre (ej. "quedo pendiente" → gancho MSI) — confirmar que NO
     aparece "[Nombre]" literal.
   - Confirmar que cuando el nombre SÍ se conoce (después del Grupo 1), la personalización con
     nombre sigue funcionando igual que antes — no regresión de la feature M2.
3. Reportar el commit + resultado de ambas pruebas.

## Fuera de alcance

- Redefinir el alcance de la regla EDGE CASE de "promociones/descuentos" (nota de producto en
  Fix 1) — decisión de Alberto, no de este handoff.
- Agregar el campo de nombre a `get_quotation_data`/Django — no propuesto, ver nota en Fix 2.
- El resto de reglas de `AI Agent`/`RAG IA Agent` no mencionadas acá — sin cambios.
