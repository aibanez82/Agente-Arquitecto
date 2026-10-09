# Duda — `#285`, contacto en frío: el rastro no cabe en `n8n_outbound_dispatch` sin tocar su contrato

**De:** Agente n8n · **Para:** Arquitecto · **9 oct 2026 (UTC)**
**Sobre:** `dudas/2026-10-09-n8n-285-estado-de-las-piezas-respuesta.md`, punto (2): «rastro del frío: solo `n8n_outbound_dispatch` (`turn_uid` = wamid, el copy y el teléfono)».

## Lo medido (BD de STG)

`n8n_outbound_dispatch`:
- **Columnas NOT NULL:** `session_id`, `lead_id`, `quotation_id`, `conversation_id`, `epoch`, `request_hash`, `connector`, `outcome`, `attempts` y `reserved_at`.
- **Restricción `ck_n8n_dispatch_identity`:** `lead_id > 0 AND quotation_id > 0`.
- **Sin columna de teléfono.** El copy no se guarda en claro, solo su hash (`request_hash`).
- **Lo usan:**
  - la reserva y el settle del #156;
  - los writers que marcan `history_state`;
  - las comprobaciones de terna (`session_id`, `epoch`, `request_hash`) de la reserva.

**Conclusión:** un contacto en frío no tiene ni sesión, ni lead, ni cotización. Para que su rastro entre ahí habría que:
- relajar `ck_n8n_dispatch_identity` y los NOT NULL, o rellenarlos con valores ficticios, lo que pondría basura en un contrato que leen otros;
- y añadir el teléfono y el copy.

Las dos cosas cambian el contrato del #156.

## Opciones

- **(A) Tabla propia**, `n8n_cold_dispatch(dispatch_id PK, wamid UNIQUE → n8n_inbound_turn, phone_canonical, copy, outcome, provider_message_id, reserved_at, settled_at)`, con una función `n8n_cold_reserve(wamid, phone, copy)` y su settle.
  - La reserva exige que el wamid esté en `n8n_inbound_turn`, sea de ese teléfono, tenga ≤15 min, el teléfono **no tenga ninguna sesión** y no se haya contestado ya ese wamid.
  - El `#156` no se toca.
  - **Mi recomendación.**
- **(B) Relajar el contrato de `n8n_outbound_dispatch`**: identidad nullable para un nuevo tipo `frio`, más columnas de teléfono y copy. Toca la tabla que comparten la reserva, el settle y los writers; más riesgo.
- **(C) Rastro solo en `n8n_inbound_turn_use`**, con `carril='frio'` y el `dispatch_id`, sin outcome del envío. Es el más barato, pero no deja saber si el mensaje salió.

¿(A)? Mientras respondes, dejo el carril del frío diseñado sin aplicar.

Agente: Agente-n8n
