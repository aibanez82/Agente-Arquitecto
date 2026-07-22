# Handoff Arquitecto → Agente n8n — Renovación: ruteo (Intent Router) + copy de la casuística

> Autor: Arquitecto-IA-Qualitas · 22 jul 2026
> Ejecutor: **Agente n8n**.
> Gobernanza: reportas al Arquitecto **a través de Alberto**. No hablas con otros agentes.
> Copia canónica: `Agente-Arquitecto:docs/2026-07-22-handoff-agente-n8n-renovacion-ruteo-y-copy.md`
> — deja también copia en `Agente-n8n/handoffs/`.
> Diseño de negocio completo: `docs/iniciativas/2026-07-22-casuistica-renovacion.md`.
> **Destino: STG primero** (`n8n-xlqk.srv1810257.hstgr.cloud`).

## Por qué esto en dos fases — léelo antes de tocar nada

Toda promesa de "tu póliza nueva empieza el día X" depende de que Django exponga `fecha_inicio`
(Issue #114 `aguayo-co/HYL-WAI`, pedido a Juan 22 jul, **sin respuesta todavía**). Si desplegamos
esa parte a PROD antes de tiempo, el bot promete una fecha que el sistema real no cumple —mismo
riesgo que ya evitamos con M47/M48. Por eso:

- **FASE 1 (sin bloqueante — construir y promover a PROD cuando esté validado en STG):** arregla
  el ruteo para que "renovación" deje de caer casi siempre en `RAG IA Agent` por accidente.
  Con esto solo, el bloque `RENOVACIÓN DE PÓLIZA` que ya existe en `AI Agent` (el que dice
  "escribe al WhatsApp de renovaciones, 5537511678") empieza a dispararse de forma consistente
  — ya es una mejora real sobre el caos actual, sin depender de Juan.
- **FASE 2 (bloqueada por Issue #114 — construir y validar en STG, NO promover a PROD todavía):**
  reemplaza el contenido de ese bloque por la casuística completa (filtro 76200, pedir fecha de
  vencimiento, ofrecer emisión con activación diferida). Se promueve a PROD en un handoff aparte
  cuando Juan confirme el campo `fecha_inicio`.

## FASE 1 — Ruteo (Intent Router + Route by Intent)

### Por qué existe el bug

Evidencia real en `n8n_chat_histories` (sesiones `525516912320`, `525548807995`,
`526673203643`, `527712197809`, `524521272940`, `526641611728`, `528681305040`): el
`Intent Router` clasifica "renovación" como `kb_query` en su propio prompt (lo dice
textualmente en la lista de ejemplos), así que casi todo mensaje de renovación termina en
`RAG IA Agent`, que no tiene ninguna regla de renovación — responde con contenido de KB
inconsistente, incluyendo un teléfono (`800 288 0042`) que **el bot completa por su cuenta sin
que aparezca en el fragmento recuperado** (viola su propia regla de grounding).

### Cambio 1 — nodo `Intent Router`, campo `text`

Reemplazar el bloque `Valores permitidos para "intent":` completo por:

```
Valores permitidos para "intent":
- "renovacion": el cliente pide renovar su póliza, o menciona (aunque sea de pasada, sin
  pedirlo explícitamente) que tiene una póliza VIGENTE CON QUÁLITAS que está por vencer o ya
  venció. Si el cliente menciona un seguro de OTRA aseguradora (GNP, AXA, etc.) o no especifica
  cuál, NO uses este valor -- eso es "contracting" normal.
- "kb_query": preguntas sobre coberturas, pagos, siniestros, información de Quálitas, FAQs de
  seguros -- que NO sean sobre renovación (ver "renovacion" arriba)
- "contracting": quiere proceder con la compra, proporciona datos personales, confirma pasos,
  dice sí/no a preguntas de contratación, saludo inicial
- "out_of_scope": preguntas sobre temas no relacionados con seguros de auto (deportes, cocina,
  política, tecnología, etc.)
```

Y la línea de `Predeterminado` al final, cambiar:
```
Predeterminado: si tienes dudas, usa "contracting".
```
por:
```
Predeterminado: si tienes dudas entre "renovacion" y "kb_query", usa "renovacion". Para
cualquier otra duda, usa "contracting".
```

### Cambio 2 — nodo `Route by Intent` (IF)

Hoy la condición es `{{ $json.routedIntent }} equals "contracting"` (true → `AI Agent`, false →
`Check Out of Scope` → eventualmente `RAG IA Agent`). Cambiarla a una expresión booleana (mismo
patrón que ya usa el nodo `quoteDocumentAction?` de este workflow):

```
leftValue: ={{ $json.routedIntent === 'contracting' || $json.routedIntent === 'renovacion' }}
rightValue: true
operator: boolean / true (singleValue)
```

Así "renovacion" cae en `AI Agent`, que es donde viven las tools que este flujo necesita
(`Mark Session Closed`, y a futuro la emisión) — confirmado que `RAG IA Agent` no tiene acceso a
ninguna de las dos.

### Cambio 3 — `RAG IA Agent`, red de seguridad (por si el Router falla igual)

Agregar como nueva regla (después de la regla 10 ya agregada hoy para M49, antes de
`FORMATO (WhatsApp)`):

```
11. RENOVACIÓN — SI LLEGA AQUÍ POR ERROR DE CLASIFICACIÓN: Si el cliente pide renovar su póliza
    o menciona una póliza vigente con Quálitas por vencer, NO uses search_knowledge_base ni
    search_doc_corpus para esto. NUNCA completes un número de teléfono, dirección o dato que no
    esté escrito literalmente en el fragmento recuperado. Responde ÚNICAMENTE:
    "Para ayudarte con tu renovación, ¿me confirmas escribiendo la palabra 'renovar'? Así te
    conecto con el flujo correcto."
```

### Prueba FASE 1

Reproducir varias de las sesiones reales de la evidencia (mensaje tipo "quiero renovar mi
póliza", o "tengo un seguro con Quálitas que vence el [fecha]") y confirmar: (a) siempre
clasifica `renovacion`, (b) siempre llega a `AI Agent`, (c) siempre responde con el bloque
`RENOVACIÓN DE PÓLIZA` actual (WhatsApp de renovaciones) — sin variantes, sin números
inventados, sin romper tuteo. Confirmar también que un mensaje sobre "tengo un seguro con GNP
que vence..." NO clasifica como `renovacion` (sigue como `contracting` normal).

## FASE 2 — casuística completa (construir y validar en STG; NO promover a PROD)

Reemplazar el bloque `RENOVACIÓN DE PÓLIZA` de `AI Agent` (el mismo que toca FASE 1, contenido
completo) por:

```
RENOVACIÓN DE PÓLIZA (NO es escalamiento):

Si el cliente pide renovar su póliza, o menciona que tiene una póliza VIGENTE CON QUÁLITAS que
está por vencer o ya venció (aunque no pida renovarla explícitamente), sigue este flujo. NUNCA
ofrezcas el link de agente especializado ni el WhatsApp de renovaciones antiguo (5537511678) en
este flujo.

Si el cliente menciona un seguro de OTRA aseguradora (GNP, AXA, etc.) o no especifica cuál, esto
NO aplica -- es una cotización nueva normal, sin restricciones.

CASO A — el cliente menciona una póliza que NO es de Quálitas (u otra aseguradora, o no
especifica cuál):
Si aún no sabes la fecha exacta en que vence su seguro actual, pregúntala primero: "¿Qué día
exacto vence tu seguro actual?" Una vez que la tengas, responde:
"No hay problema. Puedes contratar esta nueva póliza y que inicie justo el [fecha], así no
queda tu auto sin cobertura.

¿Continuamos con esta cotización nueva? 🚗"

CASO B — el cliente menciona o pide renovar una póliza de Quálitas:
PASO 1: "Con gusto te ayudo. ¿Me compartes el número de tu póliza actual de Quálitas para
verificar tu renovación?"

PASO 2: evalúa los primeros 5 caracteres del número que dé el cliente:

  CASO B1 — empieza con "76200" (la manejamos nosotros):
  Pide la fecha exacta de vencimiento: "Perfecto, esa póliza sí la manejamos nosotros. ¿Qué día
  exacto vence tu póliza actual?"
  Una vez que la tengas, responde ÚNICAMENTE:
  "Listo, [Nombre]. Ya tengo que tu póliza vence el [fecha] -- vamos a preparar tu renovación
  para que tu cobertura nueva arranque justo ese día, sin que te quedes sin protección ni pagues
  de más. En breve uno de nuestros asesores te confirma los últimos detalles."
  Y termina tu turno ahí -- NO llames ninguna tool de emisión para este flujo todavía.

  CASO B2 — NO empieza con "76200" (la emitió otro agente):
  Responde ÚNICAMENTE:
  "Lamentablemente no te puedo ayudar, esa póliza fue emitida por otro agente, te recomendamos
  que contactes con él para ver tu renovación."
  Y en el mismo turno, cierra la sesión (usa la tool disponible para esto) -- mismo patrón que
  la declinación explícita del lead.
```

**Nota para cuando se promueva a PROD (no ahora):** el paso final de CASO B1 hoy es un mensaje
de espera, no dispara ninguna acción real -- hasta que exista `fecha_inicio`, esos leads no
tienen ningún seguimiento automático. Avísale a Alberto en el reporte de STG que, si se activa
temporalmente sin la parte de emisión, va a necesitar algún mecanismo manual para no perder esos
leads (no lo construyas tú, es decisión de Alberto).

### Prueba FASE 2 (en STG, con datos de prueba -- no hay sesiones de STG en la evidencia real)

1. Mensaje "quiero renovar mi póliza" → pide número de póliza.
2. Dar un número que empiece con 76200 → pide fecha de vencimiento → dar una fecha → confirma
   con el mensaje de espera, sin llamar ninguna tool.
3. Repetir con un número que NO empiece con 76200 → confirma el mensaje de rechazo → confirma
   que la sesión queda cerrada (mismo chequeo que se usa para declinación de lead).
4. Mensaje "tengo un seguro con GNP que vence el 15 de agosto, ¿afecta mi cotización nueva?" →
   confirma que NO pide número de póliza, va directo al mensaje de CASO A con esa fecha.
5. Confirmar que el resto de `RENOVACIÓN DE PÓLIZA` (antes de este cambio) no quedó huérfano en
   ninguna otra parte del prompt -- era un bloque único, reemplazado completo.

## Fuera de alcance

- Emisión real con `fecha_inicio` -- bloqueada por Issue #114, handoff aparte cuando Juan
  responda.
- Cualquier cosa de METEPEC -- renovación queda fuera de su alcance por completo (ver
  `docs/iniciativas/2026-07-20-agente-mtp-correo-metepec.md`, corrección del 22 jul).
