# Informe — qué construye hoy mi camino de Retomar que el otro no tendría

**De:** Agente Dashboard · **13 ago 2026**
**Responde a:** `dudas/2026-08-13-dashboard-el-tercer-disparo-puede-duplicar-el-mensaje-respuesta.md` §«lo que sí quiero de ti».
**`atencion-humana-enviar` sigue sin cablear**, como pediste.

---

## 1. Lo que el camino actual construye, pieza a pieza

Todo esto lo hace `lib/s1/retomarBuilder.js` **antes de tocar la red**, y `n8n-proactive-message.js`
después. Ordenado por lo que costaría más perder:

| | Qué hace hoy | Si desaparece |
|---|---|---|
| **1. Acreditación de entrega** | El eco se valida: exige `success===true` **y `status==='sent'`** **y** `session_id` idéntico al enviado **y** `conversation_id` coherente con el `identity_mode`. Si algo falla → **502** y no se da por enviado | Es lo único que hoy garantiza que el mensaje salió **y salió por la conversación correcta** |
| **2. Resolución exacta de la sesión** | `resolveExactSession`: sin `LIMIT 1`, sin «más reciente gana». Cero candidatas → 400; más de una → 409; identidad contradictoria → 409 | El otro camino resuelve el teléfono **desde el claim** (`Validate Claim And Resolve Phone`), que es otro criterio. No digo que sea peor: **digo que es otro**, y nadie ha comparado los dos |
| **3. Coherencia lead ↔ cotización ↔ fila** | Compara con `idEquals` (BigInt) el `lead_id`/`quotation_id` del request contra la fila resuelta → 409 si contradice | Se pierde el gate que impide despachar sobre **otra** conversación cuando el request trae un selector incoherente |
| **4. `identity_mode` explícito en el wire** | `legacy` \| `shadow` \| `v2`, calculado y enviado | n8n dejaría de recibir con qué modelo de identidad se construyó el envío |
| **5. `conversation_id` en el wire** | `''` en legacy, el valor real en shadow/v2 | Ídem |
| **6. Transporte validado antes de la red** | `phone_number` de dígitos, ≥6, o **400 sin llamar a nadie** | Se perdería el corte barato: hoy un teléfono inválido no llega ni a salir |
| **7. Auditoría** | `dashboard_message_audit` con `lead_id`, `session_id`, `agent_id`, **`claim_id`** y `webhook_ok` | Depende de si el otro camino registra lo mismo. Su ledger es `dashboard_outbound_dispatch`, que es **otra** tabla y otro propósito |

## 2. Lo que el otro camino tiene y el mío no

Justo es decirlo, porque el cambio no es solo pérdida:

- **`sent` real y `provider_message_id`** — hoy yo infiero la entrega de un eco; allí viene el dato.
- **Reserva e idempotencia de dispatch** (`Reserve Or Retry Dispatch`, el ledger), que es el **fence**
  que el contrato de control pide y que mi camino **no tiene**.
- Está **dentro** del flujo de Atención Humana, así que el control humano y el envío comparten estado.

## 3. Mi lectura, con el coste delante

**Lo que de verdad se pierde no son campos: es la acreditación de entrega por identidad.** Mi eco no
dice solo «se envió», dice **«se envió por esta sesión y esta conversación»** — y falla en cerrado si
no coincide. Ese es el trabajo de S1 v1.1, el que costó seis rondas de dictamen en agosto.

Si el otro camino devuelve `sent` + `provider_message_id` pero **no** permite comprobar que salió por
la conversación esperada, el cambio **relaja** una garantía que costó cara. No digo que no se haga:
digo que se decida sabiéndolo, y que la pregunta para n8n es concreta:

> **¿El eco de `atencion-humana-enviar` permite verificar que el envío salió por la sesión y la
> conversación esperadas, o solo que salió?**

Con eso encima de la mesa, las dos salidas son defendibles:

- **Si lo permite**, el cambio es una mejora neta: gano `sent` real, `provider_message_id` y el fence
  de idempotencia, y no pierdo la garantía de identidad.
- **Si no lo permite**, cambiar de vía es un retroceso en identidad a cambio de un avance en
  idempotencia — y entonces yo propondría **no** sustituir hasta que el otro camino acredite identidad,
  porque el fallo que evita el punto 1 (mandar el mensaje a la conversación equivocada) es más grave
  que el que evita el fence (mandarlo dos veces).

## 4. Y una cosa que no depende de la decisión

Sea cual sea el corte, **el operador nunca debe ver «enviado» si `sent` es `false`**. Ya está
implementado así en el cliente (`clase: 'no_enviado'` para `dispatched` sin `sent`), y es la razón por
la que agradezco la precisión: sin ella habría pintado «enviado» mirando `outcome`.
