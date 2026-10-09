# Duda — `#285`: ¿de dónde saca la función la prueba de «inbound de ese teléfono»?

**De:** Agente n8n · **Para:** Arquitecto · **9 oct 2026 (UTC)**
**Sobre:** `dudas/2026-10-09-n8n-285-estado-de-las-piezas-respuesta.md` (c7906f0): diseño aceptado; la sobrecarga `156/018` comprueba **en la función** tres condiciones: wamid presente, inbound de ese teléfono y un solo uso.

## Lo medido (STG)

- **La reserva hoy:** `n8n_outbound_reserve` (8 args) rechaza la `closed` en `automation_gate <> 'eligible'` → `sesion_no_elegible`. Las 65 `closed` de STG dan `blocked` / `stable_automation` / `v2`. La guarda del #285 solo salta con `solicitud_invalida`, que hoy viene de que `Resolve Session` no devuelve la `closed` y los binds llegan vacíos.
- **No hay en la BD de la app ningún registro de inbound con su teléfono** que la función pueda leer:
  - el buffer de entrada (`Buffer Persist`/`Buffer Claim`/`Buffer Mark Done`) vive en una **Data Table de n8n** (`CeNELxKMTPb632g7`), que está fuera del Postgres de la app;
  - `n8n_chat_histories.wamid` solo lo escriben los carriles con `Persist Human Row` (#342) y exige sesión autoritativa;
  - `n8n_inbound_media` solo guarda imágenes.
- **Consecuencia:** si el que llama pasa el wamid y la función no tiene contra qué comprobarlo, «inbound de ese teléfono» lo afirma el que llama. Eso es lo que no queremos.

## Propuesta

- **Tabla nueva** `n8n_inbound_turn(wamid PK, phone_canonical, received_at, used_at, used_by_dispatch)`, en la migración `156/018`.
- **Un nodo lateral al inicio del bot** (rama lateral, sin transformar el ítem; fail-open: si falla, el turno sigue y solo se pierde el modo reactivo de ese turno) que inserta el wamid y el `from` de cada inbound con `ON CONFLICT DO NOTHING`. Coste: un INSERT por turno.
- **`n8n_outbound_reserve(…, p_turno_wamid)`** (9 args): solo para una sesión con `session_status='closed'`, y si todo lo demás pasa (identidad, `stable_automation`, epoch), autoriza cuando se cumple todo esto:
  - existe la fila del wamid;
  - con el mismo teléfono canónico que la sesión;
  - recibida hace 15 minutos o menos;
  - con `used_at IS NULL`, que **marca** en la misma transacción.
- **Lo que no cambia:** con sesión `open`, la sobrecarga se comporta igual que la de 8; las firmas actuales no se tocan, así que los proactivos siguen bloqueados.
- **Por qué los proactivos no pueden usarlo:** Retomar, los recordatorios y el poller **no escriben** en `n8n_inbound_turn`, y la función exige esa fila.

**Pregunto:**
- (1) ¿Vale una tabla nueva y un INSERT lateral por turno?
- (2) ¿La ventana de 15 minutos te parece bien? Cubre la latencia del buffer y del agente.
- (3) Alternativa más barata: que el inbound lo registre el propio carril reactivo antes del Claim. La descarto, porque es circular: quien escribe la prueba es quien pide permiso.

Mientras tanto preparo fuera de línea `Resolve Session`/`Session Resolution` (la `closed` más reciente solo sin `open`/`active`, `modo_reactivo`) sin aplicar nada.

Agente: Agente-n8n
