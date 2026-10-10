# Firmas de Alberto — 9 oct 2026

**De:** Arquitecto-IA-Insurmind · **Fuente:** la página [Firmas del bot](https://claude.ai/artifact/G4D8psUfUYCYFbSMeheHs9),
colección `firmas`, leída por el Arquitecto el 9 oct. Las diez decisiones son **«Firmo»** y ninguna lleva nota.
Alberto firmó entre las 06:17 y las 06:20 CDMX.

Los textos firmados son **literalmente** los de `informes/2026-10-07-textos-para-firma-461-418-261-543-340.md` (Agente
Mejoras Conversación) y los que se citan abajo.

| Id | Qué firmó | Textos |
|---|---|---|
| 461 | Quitar del prompt las tres apariciones de «¿Continuamos con esta opción, o prefieres ver otra cobertura o forma de pago?» | L1 a L5 del informe |
| 418 | Respuestas fijas a la despedida; el gancho de la pausa, una vez por conversación | D1, D3, D4 y D5 del informe; D2 como regla |
| 261 | Quitar el EDGE CASE de `pdf_cotizacion_url`; regla anti-URL ampliada a cualquier URL | U1, U2, U4, U4b; respaldo de la guarda «[U4] ¿Continuamos con la contratación?» |
| 543 | Quitar el texto fijo del caso B | R0, a1, a2, b1 y c1 del informe (b2 y c2 siguen pendientes de la prueba con Quálitas) |
| 340 | Reconocer la corrección del cliente | K1, K3 y K4 del informe |
| renov | Regla de renovación | «…NUNCA ofrezcas el link de agente especializado en este flujo.» (se quita «ni el WhatsApp de renovaciones antiguo (5537511678)») |
| 545 | Plantilla del RFC | «- Formato: [1ra letra apellido paterno][1ra vocal interna apellido paterno][1ra letra apellido materno][1ra letra nombre][AAMMDD]» (el ejemplo PEGJ921203 se queda) |
| 473 | El correo, solo si el cliente lo pregunta | El bloque que ya está en el prompt de STG |
| 553c9 | Seguro de la agencia o del financiamiento | «Si tu auto está financiado, revisa con tu financiera si tu crédito pide un seguro específico antes de cambiarlo. Con gusto te dejo la cotización para que compares.» |
| 285frio | Contacto en frío (el issue sigue en pausa) | «¡Hola! 👋 Soy el asistente de Seguro Auto Quálitas. Para darte tu cotización necesito que la generes aquí, en menos de un minuto: https://seguroautoqualitas.com — te llega por este mismo WhatsApp y seguimos desde ahí.» |

**Sin firmar todavía:** el texto «sin atención humana» del `#257` y los textos b2 y c2 del `#543`.

Agente: Arquitecto-IA-Insurmind

---

## Segunda tanda (9 oct, 12:42-12:45 CDMX)

| Id | Decisión | Texto |
|---|---|---|
| resumen-inicio-vigencia | Firmo | «Inicio de vigencia: [DD/MM/AAAA]» en el resumen previo a emitir, solo si la póliza no empieza hoy |
| 567-franjas | Firmo | Regla de horarios: hora explícita; «en la tarde» 17:00; «en la noche» 20:00; «al rato» +2 h; «mañana» 10:00 si cabe en las 24 h; envío solo de 9:00 a 21:00; se cancela si el cliente vuelve antes |
| 567-recordatorios-pendiente | Firmo | Los recordatorios nombran solo lo que falta («solo me falta el número de serie», «…las placas», «…el número de serie y las placas») |
| 567-retomar | **Cambiar** | Nota de Alberto para el texto «si no se pudo agendar»: «Sin problema, [NOMBRE]. Aquí te espero cuando lo tengas 🙂 / Solo recuerda que la oferta vence *hoy*, apúrate para que nos respeten el precio!». **Aclarado por Alberto (9 oct):** «la oferta vence hoy se envía tanto si hubo o no descuento, porque la cotización ya la ofrecemos a un precio especial». Se aplica **siempre**, tal cual. Los otros dos textos de la tarjeta quedan firmados sin cambios |

## Tercera tanda (9 oct, 13:21 CDMX)

| Id | Decisión | Texto |
|---|---|---|
| pasarela-caida | Firmo | «Ups, la pasarela de pago está fallando en este momento, no es nada de tu lado. Tu póliza ya está emitida y reservada. Prueba de nuevo con la misma liga en unos minutos; si te vuelve a salir el error, escríbeme y te ayudo.» Solo con un error temporal de la liga y la póliza ya emitida |

## Cuarta tanda (10 oct, 12:44-12:46 CDMX) — petición de llamada (caso `waq_4379`)

Firmadas las cinco, sin notas: `llamada-regla`, `llamada-a`, `llamada-b`, `llamada-c` y `llamada-d`. Textos literales en la
bandeja y en `informes/2026-10-10-mejoras-conversacion-peticion-de-llamada.md`. Alberto confirmó (vía Mejoras, y lo firma
aquí) que por teléfono no se aplica el descuento: el argumento de B va tal cual. No se ofrece devolución de llamada. B puede
cambiar si Hylant indica otra cosa.

## Quinta tanda (10 oct, 14:2x CDMX) — licencia ausente o vencida (`#333`)

| Id | Decisión | Texto |
|---|---|---|
| licencia-recomendacion | Firmo (dictado por Alberto en la sesión del Arquitecto) | Ante «no tengo licencia» o «la tengo vencida»: «Te recomendamos que siempre tengas tu documentación presente y con vigencia para que no presentes ningún inconveniente». La única exclusión por licencia es en Chofer APP / Chofer APP PLUS (decisión del 10 oct en el `#333`). Va en un fragmento propio de la KB (`Agente-n8n:handoffs/2026-10-10-333-kb-licencia.md`, adenda 1) |

**Precisión de Alberto (10 oct, misma tanda):** *«me gusta que parafrasee para que se sienta humano»*. Para `licencia-recomendacion` **vale la paráfrasis** con el mismo sentido: no se fija por el grafo. Medido en STG (Agente n8n, N=15): 10 literales, 5 parafraseadas y 0 con exclusión general.
