# Duda — `#285`: medidas las piezas en STG, dos no son como dice el handoff (no construyo nada)

**De:** Agente n8n · **Para:** Arquitecto · **9 oct 2026 (UTC)**
**Sobre:** `Agente-n8n:handoffs/2026-10-05-285-contestar-a-quien-escribe-en-sesion-cerrada.md` + adenda `c06383df`.
**Medido en:** bot STG `dNqtM20ij6ecZYAX` `18073441` (466 nodos), BD de STG y `migrations/` de Agente-n8n (`origin/stg`).

## Lo que cuadra

- **`GUARDA_DELIBERADA_285`:** está en **8** nodos `Claim * Outbound`. Son los 6 originales (`Main Reply`, `Agent Error Fallback`, `Disambiguation`, `Generic Error`, `Not Available`, `Quote Document`) más los 2 calcados después (`Liga Sin Poliza`, del #552, y `Recovery Ver Promo`, del #551). `Claim Recovery Outbound` la omite a propósito (#481).
- **`n8n_outbound_reserve` (las 2 sobrecargas) y `conversation_control_v1` son nuestras.**
  - El DDL está versionado en `Agente-n8n/migrations/156/`: la reserva nace en `003-outbound-fence.sql` y su definición vigente es `014-fence-elegibilidad-una-sola-fuente.sql` (389e1fba); la vista está en `002` y `013`.
  - En la BD, el dueño es el usuario de la conexión de la app (el mismo `current_user` con el que trabajo).
  - No paro por esto.
- **El camino de hoy en STG:** sin sesión `open`/`active` → `Identity Terminal?`[falso] → `Fallback Flag` → `Merge Session Data` → … → el agente **sí corre** → `Claim Main Reply Outbound` → la reserva da `solicitud_invalida` → la guarda **lanza**. Se paga el modelo y el cliente no recibe nada.

## Lo que NO cuadra

1. **No existe «el carril del `#285`, ocho nodos calcados del `240`, con su copy».** No hay ningún nodo del #285 aparte de las 8 guardas. Mi duda del 5 oct (`dudas/2026-10-05-n8n-542-…`) tampoco lo menciona.
   - **Lo que hay es el carril del propio `#240`**: los «8 nodos (4 pg)» de su commit `2ed4b06e`, de `Resolve Terminal 240 Session` a `Mark Terminal 240 Persist Failed`.
   - **Sus copys son de botón no vigente o autoridad caducada:** «Esa opción ya no está disponible. ¿En qué puedo ayudarte?» y «Se cruzó una actualización… ¿Me lo repites?».
   - **Sin sesión viva** hace `ruta: 'silencio'` (`sin_sesion_vigente`).
   - **Consecuencia:** para el **contacto en frío** no hay ninguna «respuesta honesta» construida. **Falta el texto**, y es un copy al cliente: ¿lo redacta Mejoras y lo firma Alberto, o tienes uno?
2. **«Dejar rastro en el historial» sin crear sesión no es posible tal como está el grafo.**
   - El trigger `trg_n8n_chat_histories_advisory_lock` descarta las filas sin sesión autoritativa; está documentado en el `Persist Human Row` del #342.
   - Y la reserva exige identidad de sesión: sin ella, `solicitud_invalida`.
   - Para el contacto en frío puedo dejar rastro en `n8n_outbound_dispatch` con la sobrecarga reactiva nueva, que es DDL nuestra y que el handoff ya prevé, pero **no en `n8n_chat_histories`** sin una sesión.
   - ¿Basta con el dispatch (el `turn_uid`/wamid + el copy) como rastro del frío, o quieres el historial, que obliga a otra pieza (por ejemplo, una tabla de turnos sin sesión)?

## Mi propuesta de diseño, sin construir hasta tu respuesta

- **Sesión `closed` y reactivo:**
  - `Resolve Session` admite, **solo si** no hay `open`/`active`, la `closed` más reciente del teléfono. Se marca `modo_reactivo`; la sesión **sigue `closed`**.
  - **Sobrecarga reactiva de la reserva** (migración `156/018`): autoriza `session_status='closed'` solo si se cumplen tres condiciones, y las comprueba la función, no el carril:
    - `p_turno_reactivo_wamid` está presente;
    - es el inbound de **ese** teléfono;
    - no se ha usado ya.
    Los proactivos (Retomar, recordatorios, poller de descuentos) llaman a las firmas actuales y siguen bloqueados.
  - El agente contesta con su contexto normal.
- **Frío (sin ninguna sesión):**
  - un carril que no pasa por el agente: el copy firmado, la reserva reactiva sin sesión (identidad = teléfono + wamid) y el envío, con rastro en `n8n_outbound_dispatch`;
  - sin historial (punto 2), salvo que digas otra cosa.
- **Controles:** los 5 de tu aceptación, con el negativo (un proactivo sobre la `closed` sigue bloqueado) medido en la función.

**Pregunto:**
- (1) el copy del frío;
- (2) el rastro del frío: solo dispatch, o historial con otra pieza;
- (3) si la propuesta de diseño vale.

Agente: Agente-n8n
