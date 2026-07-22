# Handoff Arquitecto → Agente n8n — M49 (descuento/recargo) + Adenda 9 de M19 (saludo duplicado CASO B)

> Autor: Arquitecto-IA-Qualitas · 22 jul 2026
> Ejecutor: **Agente n8n**.
> Gobernanza: reportas al Arquitecto **a través de Alberto**. No hablas con otros agentes.
> Copia canónica: `Agente-Arquitecto:docs/2026-07-22-handoff-agente-n8n-m49-adenda9.md` — deja
> también copia en `Agente-n8n/handoffs/`.
> **Destino: STG primero** (`n8n-xlqk.srv1810257.hstgr.cloud`). No tocar PROD hasta validar.
> Sin bloqueantes técnicos — a diferencia de M47/M48 (que dependen de un cambio en Django,
> manejados aparte), estos dos van listos para implementar.
> Diagnóstico completo con la verificación contra PROD vivo: `docs/2026-07-22-diagnostico-m47-m48-m49-adenda9.md`.

## M49 — reforzar bloque de descuento/pago de contado (existe, incompleto)

**Dónde:** nodo `AI Agent`, bloque `EDGE CASE — Cliente pregunta por "promociones", "descuentos",
"precio especial", u "ofertas"` (dentro de CASO A1, dentro de `parameters.options.systemMessage`).
Reemplazar ese bloque completo por:

```
  EDGE CASE — Cliente pregunta por "promociones", "descuentos", "precio especial", "ofertas", o
  "descuento por pago de contado" (incluye preguntas de seguimiento sobre el mismo tema, ej.
  "¿cuánto es?" tras la primera pregunta):
  Trátalo como pregunta de MSI — NO busques en la KB genérica ni dependas del resultado de
  search_knowledge_base ni de search_doc_corpus. PROHIBIDO mencionar "tipo de negocio" ni
  contenido sobre pólizas corporativas/flotillas — es irrelevante para este cliente. Responde
  SIEMPRE con este orden: (1) el precio ya es preferencial por ser digital, (2) fraccionar tiene
  un recargo, excepto si es MSI, (3) MSI:
  "Tu cotización con Quálitas ya tiene un precio preferencial por ser una contratación 100%
  digital. Fraccionar el pago tiene un pequeño recargo — la única forma de fraccionar sin costo
  extra de financiamiento es pagando de contado y usando Meses Sin Intereses (MSI) con tarjeta de
  crédito participante (3, 6 o 12 meses según tu tarjeta — participan AMEX, BBVA, Banorte, HSBC,
  Santander, Scotiabank y más). ¿Con qué tarjeta cuentas para confirmarte el plazo?"

  NUNCA ofrezcas el link de agente especializado en este contexto — el bot ya tiene toda la
  información necesaria para responder completo.
```

**Además — el gap real:** este guardrail solo existe en `AI Agent`. `RAG IA Agent` no tiene nada
equivalente, y por ahí es por donde probablemente se coló "tipo de negocio" en L1668 (rama de
KB/RAG). Agregar como nueva regla numerada (después de la regla 9, antes de `FORMATO (WhatsApp)`)
en el `systemMessage` de `RAG IA Agent`:

```
10. PROMOCIONES / DESCUENTOS / PAGO DE CONTADO: Si el cliente pregunta por "promociones",
    "descuentos", "precio especial", "ofertas", o "descuento por pago de contado" (incluye
    preguntas de seguimiento sobre el mismo tema, ej. "¿cuánto es?"), NO uses
    search_knowledge_base ni search_doc_corpus para esto — responde directo, sin buscar.
    PROHIBIDO mencionar "tipo de negocio" ni contenido sobre pólizas corporativas/flotillas.
    Responde ÚNICAMENTE:
    "Tu cotización con Quálitas ya tiene un precio preferencial por ser una contratación 100%
    digital. Fraccionar el pago tiene un pequeño recargo — la única forma de fraccionar sin
    costo extra de financiamiento es pagando de contado y usando Meses Sin Intereses (MSI) con
    tarjeta de crédito participante (3, 6 o 12 meses según tu tarjeta — participan AMEX, BBVA,
    Banorte, HSBC, Santander, Scotiabank y más). ¿Con qué tarjeta cuentas para confirmarte el
    plazo?"
```

**Prueba:** sesión `522217830671` (lead 1668) — preguntar "¿hay descuento por pago de contado?"
y luego insistir "¿cuánto es?". Verificar que confirme tarifa digital + recargo por fraccionar,
sin "tipo de negocio", sin importar si la respuesta pasa por `AI Agent` o `RAG IA Agent`.

## Adenda 9 de M19 — CASO B necesita la misma excepción que ya tiene CASO A

**Dónde:** nodo `AI Agent`, sección `SALUDO Y SELECCIÓN DE PAQUETE (FASE: GREETING)`, bloque
`CASO B — paquete tiene valor (cliente seleccionó en la landing)`.

**No es un caso de faltante de dato de contexto** (no hace falta ningún flag nuevo de
`canal`/`quote_document_sent`) — la detección ya existe: `paquete` no-null ya es exactamente el
criterio que separa CASO B de CASO A. El WhatsApp inicial que manda Django (plantilla gestionada
en Wagtail) ya incluye la presentación de Uriel también para estos leads, igual que en CASO A —
solo que CASO A ya tiene la excepción de "no te vuelvas a presentar" y CASO B nunca la tuvo.

Reemplazar:
```
CASO B — paquete tiene valor (cliente seleccionó en la landing):
1. Saluda al cliente mencionando el vehículo y la cobertura ya seleccionada
2. Muestra el resumen: paquete, forma de pago y precio_total
3. Avanza directamente a DATA_CAPTURE sin preguntar por paquetes
```
por:
```
CASO B — paquete tiene valor (cliente seleccionó en la landing):

IMPORTANTE — igual que en CASO A, el sistema ya le envió al cliente su cotización (con la
presentación de Uriel incluida) antes de este primer mensaje de respuesta. En este primer mensaje
NO vuelvas a presentarte ni repitas "Soy Uriel" — empieza directo con el saludo del vehículo.
Esta excepción aplica solo al primer mensaje de respuesta de la sesión; en cualquier mensaje
posterior, sigue las reglas normales de PERSONA Y TONO.

1. Saluda al cliente mencionando el vehículo y la cobertura ya seleccionada (sin repetir "Soy
   Uriel")
2. Muestra el resumen: paquete, forma de pago y precio_total
3. Avanza directamente a DATA_CAPTURE sin preguntar por paquetes
```

**Prueba:** sesión `523317911845` (lead 1674) — reproducir: cotización ya enviada por landing con
paquete pre-seleccionado, lead escribe un comentario (no una confirmación) como primer mensaje —
verificar que el bot no reintroduzca "Soy Uriel, de Quálitas". Confirmar también que un caso
normal de CASO A (sin paquete) sigue sin duplicar el saludo — no debería regresionar, pero
verifícalo.

## Fuera de alcance

- M47/M48 (renovación con activación diferida) — bloqueados por un cambio pendiente en Django
  (`fecha_inicio`), se manejan en handoff aparte cuando Juan confirme.
- Cualquier cambio a los nodos `qdr-*` (entrega de cotización por quick reply) — ya está
  desplegado y activo en PROD, no tocar en este handoff.
