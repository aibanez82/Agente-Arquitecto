# Duda · Agente n8n · A · #586 B: cómo se «detienen los seguimientos» sin cerrar la sesión

**Orden:** `Agente-n8n:handoffs/2026-10-14-A-firmas-orden-prod-591-y-cola.md` §2d. Firma `cancelar-seguimiento-586` → **B**: «Entendido. ¿Es por el precio o te quedó alguna duda de la cobertura? Si prefieres dejarlo aquí, no pasa nada: tu cotización queda guardada.», una vez por conversación. «Detiene los seguimientos y no hay `Mark_Session_Closed` decidido por el modelo ni enlace.»

**No he construido nada.** Lo que he medido:

1. **Cómo llega el «Cancelar».** En PROD, `waq_4383` h 14817, el «Cancelar» llega como **texto plano** justo después de un seguimiento de Django: h 14798, con `metadata.source = django_checkpoint_followup_v06` y `alternative = checkpoint_message`.
   - **Es el único caso** en `n8n_chat_histories` de PROD; busqué las respuestas exactas «Cancelar», «Avanzar», «Continuar» y «Aceptar».
   - **Los seguimientos sin oferta no llevan payload de botón:** `build_n8n_payload` solo pone `dsc:v1:o:<id>:accept|decline` cuando hay `discount_offer_id`.
   - **Para distinguirlo en el grafo:** «el último mensaje `ai` es un `django_checkpoint_followup_v06` sin oferta, y el cliente responde "cancelar"». `Resolve Session` hoy solo da `prev_ai_texto`; habría que añadir `prev_ai_source`.
   - **El «Cancelar» de la oferta de descuento** (`dsc:v1:…:decline`) es de la sesión B y no lo toco.
2. **Cómo detener los seguimientos.** En Django `stg` (`d3b97aa`):
   - `ineligible()` corta por `missing_*`, por `n8n_session_not_open` (sesión cerrada) y por `conversation_followup_paused`;
   - **la pausa solo acepta `reason = "blocked_issuance"`**: el DTO es cerrado (`whatsapp_followup_control_api.py:124`) y la `CheckConstraint` del modelo solo admite ese `reason`.

   **Sin cerrar la sesión no hay hoy ninguna forma limpia** de detenerlos.

## Opciones

| | cómo | ventaja | coste |
|---|---|---|---|
| **1** (la que recomiendo) | **Juan añade un `reason`** al contrato de la pausa (p. ej. `followup_declined`). n8n hace el `PUT` al enviar la B, con el patrón del `#577`: `2xx` antes del envío y `pause_failed` si falla | detiene **solo** los seguimientos; la sesión sigue abierta, como dice la bandeja («por si vuelve») | una pieza de Django |
| 2 | El **grafo** cierra la sesión (`Mark Session Closed`, decidido por el grafo y no por el modelo) | sin Django | contradice «la sesión sigue abierta». Si el cliente vuelve, entra por la búsqueda de sesiones abiertas y no la encuentra |
| 3 | Reusar `blocked_issuance` | sin Django | **falso**: la emisión no está bloqueada, y ensucia la métrica de Juan. No lo propongo |

**Mientras tanto se puede adelantar el carril** (detección + texto B una vez + sin modelo + sin enlace + sin cierre), que ya arregla lo que le pasó al cliente de `waq_4383`, y añadir el `PUT` cuando exista el `reason`. Serían **dos imports, una causa cada uno**.

## Dos preguntas más

- **El segundo «Cancelar»**, con la B ya usada: ¿qué sale? Propongo el texto **A** («De acuerdo, dejamos tu cotización tal como está. Si cambias de idea, aquí sigo.»), que es el del «Cancelar» del descuento. Pero **Alberto eligió B, no A**, así que necesita tu decisión o su firma.
- **Si el cliente contesta a la B** («es por el precio» o una duda), sigue la conversación normal: el carril de descuentos o el agente. No hay nada nuevo que construir.

**Espero tu decisión** antes de construir: opción 1, 2 o 3; si adelanto el carril; y el segundo «Cancelar».

— Agente n8n · A
