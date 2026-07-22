# Casuística de renovación — diseño de negocio (confirmado con Alberto, 22 jul 2026)

> Reemplaza el marco original de M47/M48 (que asumía "siempre ofrecer emisión con activación
> diferida" sin condición) y saca a "renovación" por completo del alcance de METEPEC (que la
> tenía listada como uno de sus motivos de entrega — ver corrección abajo).

## Regla de negocio

Solo podemos renovar una póliza si la vendió Hylant — se identifica porque el número de póliza
empieza por `76200` (validado 22 jul contra datos reales: 40/40 pólizas en
`qualitas_polizaemitida` cumplen el prefijo, sin excepción).

## Disparador — no es "M47 vs M48", es "¿la póliza mencionada es Quálitas?"

La distinción relevante no es mención pasiva vs. intención explícita de renovar — es si el
cliente identifica la póliza actual/vieja como **Quálitas** (de cualquier agente) o no:

- **No es Quálitas** (GNP, AXA, cualquier otra aseguradora, o el cliente no especifica
  aseguradora): sin restricción. Se puede ofrecer la póliza nueva con fecha de inicio en la
  fecha que el cliente indique que vence la vieja, sin pedir número de póliza ni verificar nada
  — no hay conflicto de canal, no le estamos quitando nada a nadie.
- **Sí es Quálitas** (lo mencione de pasada o lo pida explícitamente): siempre se pide el número
  de póliza y se aplica el filtro `76200`. Si diéramos fecha de inicio conveniente sin este
  filtro, estaríamos efectivamente quitándole la renovación a otro agente Quálitas aunque lo
  empaquetemos como "póliza nueva".

## Flujo — caso "sí es Quálitas"

1. Pedir número de póliza actual. Siempre se asume que el cliente lo tiene a la mano si está
   pidiendo renovar/preguntando por su póliza vigente — no hay ruta alterna de búsqueda por
   teléfono/nombre si no lo tiene.
2. Verificar prefijo `76200`:
   - **Si es Hylant:** pedir también el día exacto de vencimiento de la póliza actual. Ofrecer
     emitir la póliza nueva **hoy**, con `fecha_inicio` = esa fecha de vencimiento, para que el
     cliente no se quede sin cobertura ni pague doble. **Bloqueado técnicamente** — depende de
     que Django exponga `fecha_inicio` como parámetro (Issue #114 `aguayo-co/HYL-WAI`, pedido a
     Juan 22 jul, sin respuesta todavía). Mientras tanto se puede validar el copy/conversación en
     STG, sin promover a PROD, mismo guardrail que ya usamos en M47/M48 originalmente.
   - **Si NO es Hylant:** responder ÚNICAMENTE:
     *"Lamentablemente no te puedo ayudar, esa póliza fue emitida por otro agente, te
     recomendamos que contactes con él para ver tu renovación."*
     y cerrar la sesión (misma tool que se usa hoy para "ya no me interesa" /
     declinación explícita del lead) — decidido así 22 jul, sin dejar la conversación abierta.

## METEPEC — corrección de alcance

Ningún caso de renovación va a METEPEC. El plan original del 20 jul
(`docs/iniciativas/2026-07-20-agente-mtp-correo-metepec.md`) listaba "renovación" como uno de
los dos motivos de entrega (junto con plataforma digital) — queda descartado para renovación:
si es Hylant, se resuelve directo con esta casuística; si no es Hylant, no hay nada que mandarle
a METEPEC, no es un lead que podamos convertir. Esa iniciativa se actualiza para reflejar que
solo cubre plataforma digital.

## Pendiente de diseño — no cerrado todavía

- **Ruteo:** hoy "renovación" se clasifica como `kb_query` en el Intent Router (Haiku) y por eso
  casi nunca llega al bloque correcto del `systemMessage` — la mayoría de las conversaciones
  reales terminan en `RAG IA Agent` (sin ninguna regla de renovación) dando respuestas
  inconsistentes, incluyendo un número de atención al cliente (800 288 0042) que el bot completa
  por su cuenta sin que aparezca en el fragmento de la KB recuperado (viola su propia regla de
  grounding). Evidencia real: sesiones `525516912320`, `525548807995`, `526673203643`,
  `527712197809`, `524521272940`, `526641611728`, `528681305040` en `n8n_chat_histories`. Este
  flujo nuevo necesita su propio intent (`renovacion`) en el Router para no depender de que el
  clasificador acierte por accidente — no se ha diseñado el detalle todavía.
- Falta decidir el copy exacto de cada mensaje (petición de número de póliza, petición de fecha
  de vencimiento, mensaje de oferta de emisión con activación diferida) — se redacta cuando se
  arme el handoff a Agente n8n.
