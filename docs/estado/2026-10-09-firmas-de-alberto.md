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

**Cambio de Alberto (10 oct, después de probarlo en STG a las 14:40):** *«no me gustan las respuestas, son muy ambiguas… ni sí ni no. Recomienda tener la documentación vigente. Pero en ningún caso podemos asegurar que la aseguradora cubra cuando maneje una persona que no tiene licencia.»* **`licencia-recomendacion` pasa a ser:** ni se afirma ni se niega la cobertura; se recomienda tener siempre la documentación vigente para que la aseguradora pueda responder ante un siniestro, con paráfrasis permitida; **nunca** se afirma que cubra. Se retira el «la única exclusión es Chofer APP» del fragmento de la licencia. La orden de PROD de las 14:4x quedó revocada sin ejecutarse.

## Sexta tanda (10 oct, 20:37 CDMX) — retener antes de pasar a una persona

| Id | Decisión | Texto |
|---|---|---|
| retener-antes-de-escalar | Firmo, sin notas | Ante una petición expresa de hablar con una persona: **un** intento de retención por conversación, y si insiste, el enlace al momento. ~~Excepciones que escalan directo: siniestro o accidente, queja o reclamación, problema con una póliza emitida o un pago, y producto que no vendemos (Uber, taxi, flotilla).~~ **Corregido el 14 oct** (Alberto: «sí, así está bien»): **siniestro y queja conservan la respuesta de hoy** (la información útil de la KB, más el contacto si hace falta) **y solo dejan de intentar retener**; póliza o pago y Uber, taxi o flotilla siguen escalando directo. La redacción tachada era del Arquitecto y quitaba la ayuda inmediata que hoy da el bot. Textos literales (con descuento, sin descuento y «si insiste») en la bandeja (`propuestas/retener-antes-de-escalar`). Nace de su prueba en PROD (`waq_4395`, filas 14987-14988) |

## Séptima tanda (14 oct) — decisiones sobre el caso `waq_4420` (`#606`)

| Id | Decisión | Qué |
|---|---|---|
| limite-cortesia | Decidido por Alberto: «sí, adelante con las tres» | La cortesía y la despedida no cuentan para el límite de mensajes por fase (`Message Budget Guard`); las reacciones, tampoco. El texto del corte no cambia |
| no-prometer-contacto | **Pendiente de firma** (bandeja: `propuestas/no-prometer-contacto`) | Mientras no exista el recordatorio por fecha (`#223`), el bot no promete «te contacto»: el cliente vuelve a escribir a partir de una fecha que calcula el sistema. Cambia el texto firmado del límite de 30 |

## Octava tanda — firmas del 11 oct (en la bandeja, **sin atender hasta el 14 oct: el Arquitecto no volvió a mirar la bandeja**) y del 14 oct

| Id | Fecha | Decisión | Qué queda firmado |
|---|---|---|---|
| guardarrail-emision-591 | 11 oct | sí | El `#591` v2 a PROD (todo número de póliza afirmado tiene que existir para esa cotización) |
| emision-fraccionado | 11 oct | sí | El mensaje de emisión con pago fraccionado (`Pago:`, `Primer pago:`, `Después: N pagos de`) |
| resumen-orden-pregunta | 11 oct | sí → **A** | La pregunta «[Nombre], ¿todo correcto? Con tu sí, emito tu póliza.» **al principio** del resumen |
| cancelar-seguimiento-586 | 11 oct | **cambio → B** | El «Cancelar» del seguimiento: la pregunta de objeción («¿Es por el precio o te quedó alguna duda de la cobertura?…»), una vez por conversación |
| error41-ramas-543 | 11 oct | sí | `a0`, más `b2`/`c2` en la **variante S** (sin persona), que era la recomendada como permanente |
| emision-sin-link | 14 oct | sí → **b1** | La emisión sin link: la frase de la pasarela adaptada |
| urgencia-hoy-596 | 14 oct | sí → **H** | Urgencia honesta: nunca «válido solo hoy»; sí «es el precio de hoy y no te puedo asegurar que se mantenga» |
| textos-montserrat-596 | 14 oct | sí | Los tres textos de Montserrat en versión H (el 3 sin descuento, sin los 12 MSI hasta el `#592`) |
| no-prometer-contacto | 14 oct | sí | Sin recordatorio por fecha, nunca «te contacto»: «escríbeme por aquí a partir del…» |
| placas-opcionales-614 | 16 oct | sí (en la sesión del Arquitecto) | `#614`: **P1** «No te preocupes, las placas no son necesarias para emitir tu póliza: el dato importante es el número de serie (VIN) de tu auto. Si después las tienes a la mano, me las puedes pasar.» · **P2** «Placas del vehículo (si las tienes a la mano)» |
| resumen-pregunta-contundente | 16 oct | sí (texto de Alberto) | Sustituye a la pregunta de `resumen-orden-pregunta`: «[Nombre], ¿está todo correcto? Dime *Sí* y emito la póliza.» (sin nombre: «¿Está todo correcto? Dime *Sí* y emito la póliza.») |
| tarjeta-digital-613 | 16 oct | sí → alcance **(a)**; «o virtual» añadido por Alberto el mismo día | `#613`: ante el «no puedo pagar» escrito y con póliza emitida, «Lamento el inconveniente. A veces el banco bloquea el cobro con la tarjeta física por seguridad. Prueba con la *tarjeta digital o virtual* de la app de tu banco: suele pasar sin problema. Puedes usar la misma liga de pago; si la necesitas otra vez, pídemela.» La captura de error no cambia (la (b) espera a Hylant) |
| tarjeta-digital-613-captura | 16 oct | sí | La captura de error de pago (`comprobante_o_error_de_pago`, póliza emitida): el texto firmado de la pasarela + «Si el error persiste, prueba con la *tarjeta digital o virtual* de la app de tu banco: a veces el banco bloquea el cobro con la tarjeta física por seguridad.» El 503 de `Ensure Payment Link` no cambia |

Encargo: `Agente-n8n:handoffs/2026-10-14-A-firmas-orden-prod-591-y-cola.md`. Los textos de Django del `#596` van a Juan.

## Novena tanda (14 oct) — paso 1 del plan de cierre

| Id | Decisión | Qué |
|---|---|---|
| serie-foto-no-cuadra-593 | Aprobado | «Leí tu tarjeta de circulación, pero el número de serie que trae es de un [MARCA AÑO], y estamos cotizando un [VEHÍCULO]. ¿Es el mismo auto? Si es otro, dime cuál y te lo cotizo; si es este, escríbeme el número de serie tal como aparece en la tarjeta.» |
| serie-formato-475 | Aprobado | O→0 e I→1 con confirmación: «Tu número de serie tenía una letra O, y los números de serie nunca llevan O, I ni Q, así que la he cambiado por un cero: [SERIE]. ¿Es correcto?»; si la longitud no es 17: «El número de serie tiene que tener 17 caracteres y el que me escribiste tiene [N]. ¿Me lo revisas en tu tarjeta de circulación?» |
| prompt-486-paquete | OK | Los puntos 3, 4, 6, 8, 9, 10, 11 y 14 del juicio del `#486` (solo redacción) |
| higiene-iniciativas | De acuerdo | `#147`, cerrado como no planificado; `#238`, aparcada; `#286`, abierta; `#126` y `#353`, encargados a la sesión A; `#134`, a hablar con Juan |
| retención: siniestro y queja | Aprobado («sí, así está bien») | Ver la sexta tanda (corregida) |

## Décima tanda (14 oct) — caso `waq_4442`

| Id | Decisión | Qué |
|---|---|---|
| cp-equivocado-608 | OK | Provisional: con un CP distinto al cotizado, no se siguen colonias del CP equivocado ni se manda a la web; se pasa a una persona y la sesión queda marcada |
| serie-16-475 | OK | El texto de longitud del `#475` cubre también el caso de los 16 caracteres |
| domicilio-recibo-609 | Cambio de Alberto | «Intentemos extraer la dirección del comprobante, se la ofrecemos al cliente y que nos la confirme. Como con el VIN y las placas.» La dirección se extrae, se ofrece y solo se guarda con confirmación; si el CP no casa, se aplica el `#608` |

| cp-equivocado-608-texto | Firmado (14 oct, 19:14 UTC) | «Entiendo, tu código postal es otro. Para corregirlo te paso con una persona de nuestro equipo que te atiende por WhatsApp: [enlace]» |

## Undécima tanda (16 oct, noche): bandeja, 00:56 UTC del 17

| Id | Decisión | Qué |
|---|---|---|
| a0-con-enlace-543 | sí | Sustituye al a0 del 11 oct: «¡Entonces ya eres cliente! No hace falta contratar otra. Para revisar tu póliza o tu pago te atiende una persona de nuestro equipo por WhatsApp: [enlace]» |
| recovery-motivo-cancelacion-551 | sí | Recovery (`waq_4498`). Primera respuesta: «Es para tu [VEHÍCULO], el que tenías asegurado con nosotros. Tu póliza anterior ya no está activa, y por eso te mandamos un precio especial para volver a asegurarlo. ¿Te cuento cuánto queda?». Motivo: «Tu póliza anterior del [VEHÍCULO] se canceló el [FECHA] porque quedó un pago pendiente, así que hoy tu auto no tiene seguro vigente. Por eso te mandamos esta promoción: una póliza nueva con [COBERTURA] que empieza el [FECHA_INICIO].» Después, la forma de pago pedida y «¿Te la dejo lista para contratar?». La comparación con la prima anterior (`#394`), marcada como opcional, **queda pendiente de confirmación expresa** |

Encargo: `Agente-n8n:handoffs/2026-10-14-A-firmas-orden-prod-591-y-cola.md`, adenda 13.
