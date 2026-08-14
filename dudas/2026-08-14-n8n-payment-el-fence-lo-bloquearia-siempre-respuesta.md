# Respuesta — Payment: reordenar **sí**, excepción **no**

**14 ago 2026 · Arquitecto → Agente n8n.** Hallazgo verificado y decidido. Puedes cerrar el 9/9.

---

## 1. Confirmo tu hallazgo, medido por mi lado

Reproduje el grafo sobre `workflows/vivo-stg-2026-08-14/payment_stg.json`:

```
Payment Webhook Trigger → WA Config STG → S1 Payment Request Guard → S1 Request Valid?
   → Format & Validate Message → ` Mark Session Completed` → Restore After Phase Update W2 → Send message
```

y el `UPDATE`: `SET conversation_phase='completed', status='completed', closed_at=NOW()`. Contra un
fence que exige `session_status='open'` y `automation_gate='eligible'`, con `closed_at` no nulo ⇒
`session_closed`. **Los dos requisitos fallan a la vez, en el 100 % de los casos.**

Que lo encontraras **antes** de implementarlo es la diferencia entre un hallazgo y un incidente: si
Payment se hubiera fenceado como el bot y lo hubiéramos dado por bueno, ningún cliente volvería a
enterarse de que su pago entró, y lo habríamos descubierto por una queja.

## 2. Reordenar: **autorizado**

Reserva **antes** de `Mark Session Completed`, con tu secuencia:

```
S1 Request Valid? → Stash → Claim → IF Send? → Restore
   → Format & Validate Message → ` Mark Session Completed` → Restore After Phase Update W2 → Send message
```

**Sobre el «inmediatamente antes de enviar»:** tu argumento es el que decide y lo hago mío — esa
ventana **ya existe hoy**, el `UPDATE` va en medio con fence o sin él, y la alternativa (relajar
`n8n_outbound_reserve` para que acepte sesiones cerradas) degradaría el fence **para todos los
llamantes** por un caso. Se declara en el diff semántico: *en Payment la reserva ocurre dos nodos
antes del conector, y por qué*.

## 3. La excepción: **no. Decisión de Alberto (14 ago)**

Le presenté las tres opciones con sus costes, incluida tu recomendación y tu razonamiento —«un pago
confirmado es un hecho, no una opinión sobre la conversación»—. **Decide fence completo, sin
excepción.**

Así que **con control humano activo, la confirmación de pago no se envía.** Implementa el fence tal
cual, sin caso especial.

**No lo implementes como si fuera gratis.** La consecuencia, dicha con todas las letras y en tu
entrega también: *si un agente tiene la conversación tomada cuando entra una confirmación de pago, el
cliente no se entera de que su pago entró, y el agente tampoco se entera de que había una confirmación
que se silenció.* Queda **registrado como riesgo conocido y aceptado**, no como efecto no previsto.

**Y sube a bloqueante para la promoción a PROD** — junto con el duplicado de los 7 conectores. En STG
es aceptable porque los clientes son pruebas; en producción es un cliente real que pagó y no lo sabe.
El día que exista el camino de «diferir y avisar» que hoy falta (el mismo que `Send Quote Document`),
**Payment debería usarlo**: es el destinatario natural.

## 4. El 9/9 y cómo se declara

Ciérralo. Y en el inventario y en #156, con estas palabras y no otras:

- **8 puntos** por `n8n_outbound_reserve`;
- **1 punto** (`Atencion Humana` / `Send Human Agent Message`) por `dashboard_outbound_dispatch`,
  unificación de ledgers **diferida a rollout**;
- **Payment:** reserva **dos nodos antes** del conector, por la secuencia propia del workflow;
- **con control humano activo, Payment no envía** — decisión de producto de Alberto, con su coste
  declarado.

**Gracias por no cerrar un 9/9 que era 8/9.** Es la tercera cifra que se corrige esta semana antes de
publicarse, y las tres las has corregido tú.
