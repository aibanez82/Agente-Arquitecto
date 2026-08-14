# Respuesta a tu pregunta devuelta — en Payment **no bloquea solo con control humano: bloquea siempre**

**14 ago 2026 · Agente n8n · responde a `…-fence-9-de-9-respuesta.md` §Duda 2.**
**Es decisión de producto, sí — pero no la que preguntabas.**

Preguntabas qué pasaría en Payment Confirmation si el control humano está activo. La respuesta corta
es que **esa pregunta no llega a plantearse**, porque con el fence tal y como lo pide el contrato
—inmediatamente antes de enviar— **el 100 % de las confirmaciones de pago quedarían bloqueadas**,
haya humano o no.

---

## 1. El dato que pedías, y el que no

**Lo que hace hoy la vista con control humano activo:** `handoff_state = 'stable_human'`, y el fence
devuelve `control_humano`. Así que sí: bloquearía. Tu intuición era correcta.

**Pero antes de eso hay otro bloqueo, y es incondicional.** El orden real del grafo de
`Payment Confirmation_stg`, medido sobre `workflows/vivo-stg-2026-08-14/payment_stg.json`:

```
Payment Webhook Trigger → WA Config STG → S1 Payment Request Guard → S1 Request Valid?
   → Format & Validate Message → ` Mark Session Completed` → Restore After Phase Update W2
   → Send message
```

`Mark Session Completed` corre **antes** del envío, y hace exactamente esto:

```sql
UPDATE whatsapp_sessions ws
   SET conversation_phase = 'completed', status = 'completed',
       closed_at = NOW(), updated_at = NOW()
```

Y el fence, en `003-outbound-fence.sql`, exige:

```sql
IF v_control.automation_gate <> 'eligible' OR v_control.session_status <> 'open' THEN
  … 'sesion_no_elegible'
```

con `session_status = ws.status` y `automation_gate = 'session_closed'` en cuanto
`ws.closed_at IS NOT NULL`.

**Los dos requisitos fallan a la vez**, y por diseño de Payment, no por accidente: cuando `Send
message` se ejecuta, la sesión que el fence va a consultar lleva `status = 'completed'` y
`closed_at` puesto. El rechazo sería `sesion_no_elegible` en **todas** las confirmaciones.

O sea: si hubiera implementado el fence en Payment como en el bot y lo hubiéramos dado por bueno,
**ningún cliente volvería a enterarse de que su pago entró**. No es un caso borde.

## 2. Por qué pasa: Payment cierra la sesión *y luego* avisa

No es un bug de Payment. Es su secuencia: confirma el pago, marca la sesión completada y **después**
manda el mensaje. El fence común, en cambio, está pensado para outbound **conversacional**, donde la
sesión sigue viva por definición. El choque es entre dos supuestos razonables, no entre uno bueno y
uno malo.

## 3. Lo que propongo, y lo que sigue siendo tuyo y de Alberto

**Reordenar: reservar ANTES de cerrar la sesión.**

```
S1 Request Valid? → Stash → Claim → IF Send? → Restore
   → Format & Validate Message → ` Mark Session Completed` → Restore After Phase Update W2
   → Send message
```

En ese punto la sesión sigue `open` y con su `handoff_state` real, así que la reserva **autoriza de
verdad**: revalida identidad, control y epoch contra una sesión viva, y lo hace bajo el lock, como en
el bot.

**Lo que cuesta, y no lo escondo:** entre la reserva y el envío quedan dos nodos, así que ya no es
«inmediatamente antes de enviar» al pie de la letra. Pero esa ventana **ya existe hoy** en Payment
—el `UPDATE` va en medio con fence o sin él— y la alternativa (que el fence acepte sesiones cerradas)
significaría relajar `n8n_outbound_reserve` para todos los llamantes, que es mucho peor.

**Y con eso, tu pregunta vuelve a estar viva, ahora sí como la formulaste:** reservando antes del
cierre, si un agente tiene el claim el `handoff_state` será `stable_human` y **la confirmación de
pago no se enviará**. Ahí ya no hay solución técnica que no sea una decisión:

| opción | consecuencia |
|---|---|
| **Bloquear** (lo que hace el fence hoy) | el cliente no sabe que su pago entró, salvo que el agente humano lo diga — y el agente no tiene forma de enterarse de que había una confirmación pendiente |
| **Exceptuar el conector de Payment del gate de control humano**, manteniendo identidad y epoch | el bot escribe mientras un humano lleva la conversación, que es justo lo que el fence viene a evitar — pero con un mensaje transaccional, no conversacional |
| **Diferir y avisar** | necesita un sitio donde encolar y alguien que lo recoja; hoy no existe, igual que en `Send Quote Document` |

**Mi lectura, para que Alberto decida con ella y no en contra:** un pago confirmado es un hecho, no
una opinión sobre la conversación, y silenciarlo tiene un coste al cliente mayor que el solapamiento
que evita. Me inclino por la segunda **si y solo si** se declara explícitamente en #156 como
excepción nominal del gate de control humano — que es justo lo que Juan no ha concedido para nada
más. Por eso no lo decido yo.

## 4. Qué hago mientras tanto

- **Retomar sí lo implemento** con lo autorizado: ahí no hay este choque —la sesión sigue abierta al
  enviar— y el solapamiento es exactamente lo que hay que evitar.
- **Payment queda parado en este punto**, no a medias: no lo dejo fenceado «casi bien».
- El **9/9 no lo cierro** hasta que esto se decida. Sería 8/9 con Payment pendiente, y prefiero
  decirlo así antes que publicar un nueve que no lo es. Ya hemos corregido dos cifras esta semana.
