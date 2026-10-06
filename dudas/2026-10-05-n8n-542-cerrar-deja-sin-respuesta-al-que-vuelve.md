# Duda #542 — PARO en el punto 3: cerrar la sesión hoy deja sin respuesta al cliente que vuelve a escribir (#285)

**De:** Agente n8n · **Para:** Arquitecto · **5 oct 2026**
**Responde a:** `handoffs/2026-10-05-542-cerrar-la-sesion-al-declinar-o-derivar.md` (Agente-n8n `36a845f7`), punto 3: «si el
comportamiento hoy es malo, PARA y dímelo antes de cerrar nada». **No he tocado STG**, que sigue congelado por el QA del `#536`.
Todo lo de abajo está medido en lectura sobre el bot STG `f21ff7a2`.

## 1 · Qué pasa hoy si el cliente escribe tras el cierre: se queda sin respuesta

- `Resolve Session`, en modo `phone_open_sessions`, **solo admite** `status IN ('open','active')`. Una sesión `closed` no entra.
- `Session Resolution`: si no queda ninguna candidata utilizable, el turno cae a `Fallback Flag`, el camino de sesión nueva.
- La reserva de salida exige que la sesión sea `eligible`. `conversation_control_v1` marca toda sesión cerrada como
  `automation_gate='blocked'`, y el `Claim *Outbound` se para en la `GUARDA_DELIBERADA_285`. **El cliente no recibe nada.**
- `HYL-WAI#285` («Un mensaje de un teléfono SIN sesión viva deja al cliente sin respuesta») sigue **ABIERTO**, con criticidad
  `crítico`. Lo reproduje en STG el 3 sep. El arreglo está **parado desde el 6 sep** a la espera de una decisión de Alberto: gate
  reactivo o reabrir en Django.
- **En PROD no he podido contarlo:** la API no devuelve ejecuciones con error del bot (0). Django tampoco registra los mensajes
  entrantes, porque `qualitas_whatsappmessage` solo tiene `OUTBOUND`.

**Consecuencia:** el `#542` haría que **más** sesiones acaben en `closed`. Cada cliente que, tras declinar o ser derivado, vuelva a
escribir (por ejemplo «¿y si lo pongo a nombre de mi papá?») caería en el silencio del `#285`. **El `#285` va antes que el `#542`.**

## 2 · Inventario (punto 1), por si sirve para cuando se desbloquee

**Declinaciones y derivaciones** (en el `systemMessage` del AI Agent):

| Texto (literal) | Cuándo | ¿Cierre permanente? |
|---|---|---|
| «Para tu caso, te recomendamos contactar directamente con un agente especializado…» (escalamiento) | lista de ESCALAMIENTO INMEDIATO | **depende del motivo**: ver la nota de abajo |
| «Gracias por el dato. En este momento solo emitimos pólizas nuevas, no renovaciones… Lamento no poder ayudarte en esta ocasión.» | renovación Quálitas, CASO B | **no**: lo cambia el `#543` |
| Declinación explícita del lead («ya no me interesa», «ya contraté con otra»): mensaje breve | DECLINACIÓN EXPLÍCITA | sí; hoy ya pide `Mark Session Closed` |

**El escalamiento es el MISMO texto para casos de naturaleza distinta.** Comparten ese copy literal:
- por alcance (permanentes): menor de edad; auto importado, fronterizo o regularizado; uso comercial o de plataforma;
- no permanentes: «quiere hablar con una persona», «mi caso es especial», «se niega a dar datos», «quiere cancelar».

Además, el prompt dice: *«si tras un mensaje de escalamiento el cliente sigue conversando sobre la cotización … retoma el servicio
normal»*. **Mirando solo el texto enviado, el grafo no puede separar la derivación por alcance de la que no lo es.** Cerrar por ese
texto cerraría también a quien solo pidió una persona y luego sigue por aquí; ese cliente caería en el `#285`.

**Respaldos técnicos con el mismo enlace: NO cierran.** Son:
- `Issue Policy` (description);
- `Get Quotation Data` (description);
- `Send Generic Error Message`;
- `Apply Guardrail Result`;
- `Rebuild Summary From Record` (copy técnico del `#536`);
- `RAG IA Agent` («No conozco esta respuesta…»).

Hay dos que **no son ni declinación ni respaldo técnico**: `Message Budget Guard` y `KB Budget Guard`, que derivan al humano al
llegar al tope de mensajes. Necesitan tu criterio.

## Lo que necesito

1. **Orden:** ¿se espera a la decisión de Alberto sobre el `#285` (gate reactivo o reabrir en Django)? Mi lectura: sí, antes de
   cerrar nada.
2. **Cómo distinguir la derivación por alcance**, si el `#542` sigue. Hay dos formas, y ninguna la tomo sin ti:
   - **(a)** un texto distinto para la derivación por alcance (toca el prompt, así que en PROD firma Alberto), para que el grafo
     la reconozca;
   - **(b)** un marcador interno que el modelo emite y una guarda retira, como `[phase:…]`. Es más frágil porque depende del modelo.
3. **Lo que no cierra la sesión pero sí podría frenar el seguimiento** necesitaría tocar Django: hoy solo mira `status` en
   `CLOSED_N8N_SESSION_STATUSES`, y cualquiera de esos estados también deja fuera a `Resolve Session`. Es de Juan, así que no lo
   propongo como camino.

— Agente n8n
