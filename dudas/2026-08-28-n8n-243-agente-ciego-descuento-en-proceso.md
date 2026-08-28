# Aviso: HYL-WAI#243 — el agente responde a ciegas mientras el descuento se procesa (STG)

**De:** Agente n8n
**Fecha:** 2026-08-28 (UTC)
**Tipo:** aviso de bug abierto + pista de solución a validar. No bloquea nada mío.

## Resumen

Prueba E2E en STG de hoy (AVEO 2014, cotización 2278 → descuento → 2279). El descuento
funcionó a nivel de tarificación: PrimaTotal $7,657.57 → $6,897.14 (−9.9%), PDF entregado
y confirmado por Meta. Pero en los ~11 minutos entre la aceptación de la oferta y la
entrega del PDF, los turnos del usuario volvieron por `normal_handoff` y el AI Agent
respondió leyendo la cotización vieja (CTX con `qid=2278`): repitió el precio viejo y
llegó a afirmar «el precio sigue siendo el mismo — no aplicó un descuento adicional»,
contradiciendo el descuento que él mismo acababa de tramitar. Para el tester fue
indistinguible de «el descuento no sirvió».

Evidencia completa y tabla temporal: **aguayo-co/HYL-WAI#243**
(`sistema:n8n`, `criticidad:alto`, `reportado-por:agente-n8n`).

## Qué te pido

1. **Validar la pista de solución** propuesta en el issue: cuando haya una
   `discountapplication` no terminal sobre la sesión, que el turno que vuelve por
   `normal_handoff` lleve una señal determinística en el CTX (p. ej.
   `descuento=en_proceso`) para que el agente conteste «se está procesando» en vez de
   afirmar sobre la cotización vieja. Guardrail determinístico, sin tocar el prompt.
   Tiene pieza n8n (CTX/ruteo) y posiblemente pieza Django (exponer el estado in-flight).
2. **Dato adicional para #205:** en esta misma prueba se envió una segunda oferta
   idéntica *después* de que la primera ya estaba aceptada (no solo «viva sin responder»).
   Dejé comentario con la evidencia en el propio #205.

Sin urgencia: es defecto de percepción/confianza, no de dinero — el precio entregado fue
el correcto. Sigo con lo mío; si decides que se construya, me llega como handoff normal.
