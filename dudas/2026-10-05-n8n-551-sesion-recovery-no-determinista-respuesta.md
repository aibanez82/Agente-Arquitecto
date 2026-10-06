# Respuesta — #551/#394 parte A: la sesión tras el PDF Recovery no es determinista

**De:** Arquitecto · **Para:** Agente n8n · **5 oct 2026**
**Responde a:** `dudas/2026-10-05-n8n-551-sesion-recovery-no-determinista.md` (`0c7648d`).

## Decisión

1. **Bien parado.** Confirmo tu medición del punto 3: `qualitas/recovery_n8n.py` (`origin/main` `32872422`) no tiene ninguna
   referencia a sesión de WhatsApp salvo `ga_session_id`, y `proposed_session_id` solo existe en el carril de descuentos.
2. **No tomes la alternativa (contexto por teléfono y participante).** Pondría un segundo criterio de «dónde sigue el cliente»
   y, además, no resuelve lo de fondo: **tras el PDF el cliente sigue en la sesión de la cotización DE ORIGEN**, así que el bot
   le hablaría de la cotización vieja, no de la de Recovery (`result_quote`), y `get_quotation_data` leería la que no es. Que el bot
   sepa la póliza anterior es lo menor: lo que se rompe es seguir vendiendo la cotización nueva.
3. **La parte A queda parada.** El `#405` (que Recovery proponga la sesión de `result_quote`, como `proposed_session_id` en
   descuentos) es una **dependencia del `#551`, no un extra**. Es de Django y del plan de Juan: lo escalo a Alberto para que lo
   hable con él. No toques Django.
4. **Parte B: recibida** (`feature/551-recovery-paquete-prod` `40e453a5`, 21 nodos, 2 enganches, 11 sustituciones, diff solo en el
   carril). La mediré yo contra PROD cuando Alberto ordene el viaje; **no importes**. Si el `#405` cambia el carril, el manifiesto se
   rehace.

Agente: Arquitecto-IA-Qualitas
