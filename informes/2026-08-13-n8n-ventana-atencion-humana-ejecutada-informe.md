# Informe de ventana — Atención Humana promovida · **creada INACTIVA**

**13 ago 2026 · Agente n8n · ejecutada. Pendiente de acreditación, de dos pasos manuales y de activación.**

Ventana abierta por Alberto. Registro completo en `Agente-n8n:docs/fase4/2-atencion-humana.md` §0
(`docs/fase4-preparacion@4f0d8f0`).

## A · El workflow — id **`B5ihE5xHg8bjeesl`**

| | |
|---|---|
| nodos | **19** · **`active = false`**, a propósito |
| rastros de STG | **cero**: ni el `phone_number_id` de staging, ni **una sola aparición** de la cadena `STG` en todo el objeto |
| `Send Human Agent Message.url` | `…/v21.0/**1028815256982638**/messages` — el de PROD |
| credenciales | `Atencion Humana Header Auth PROD` · `Postgres account` · `WhatsApp Send Message Hylant Account` |

```
atencion-humana-iniciar   136f886a-6239-41a9-b9d1-217506330902
atencion-humana-liberar   06ae92ab-9ad3-43c4-95e8-9a4e7b3520a7
atencion-humana-enviar    4c95417a-37df-46b2-adaa-21d0de28b6fa   ← creado y sin llamador, por decisión
```

## B · El bot

| | |
|---|---|
| nodos | 117 → **119**, ninguno perdido |
| `versionId` | `17fed145-…` → **`9c2de104-ebf2-4785-9e20-8b9322432252`** |
| cableado | `Phase Guard(1) → Human Takeover Guard → {Save Human-Gated Message, Ban Guard}` — **sin METEPEC**, las tres aristas medidas |
| los 7 `webhookId` | **idénticos** — sin Bug #12 |
| `Phone Number ID Guard` | presente · `registrar_lead_metepec` **ausente** |
| `Merge Session Data` | expone `humanTakeover` ✓ |
| `Resolve Session` | devuelve `human_takeover` ✓ |

**Un paso salió gratis:** el guion iba a añadir `human_takeover` al `SELECT` y lo encontró **no-op**,
porque tu pieza C de Multicotización ya había traído el `SELECT` entero de STG unas horas antes. Por una
vez dos promociones se ayudan en vez de estorbarse.

**Y el retrato lo rehice antes**, como estaba previsto: la foto del 12 ago describía 113 nodos y el bot
estaba en 117. El guion habría abortado en cerrado contra el `versionId` —no era un riesgo silencioso—
pero había que rehacerla, no aflojar la guarda.

## Lo que falta antes de que esto **funcione**, y no es mío

1. **Comprobar en la interfaz que los tres webhooks muestran la credencial.** Es la comprobación que yo
   mismo propuse y **la única posible**: el `id` (`DfhXSBqo38AZ00Wt`) va declarado a mano porque la API
   no expone `GET /credentials`. Si estuviera mal escrito, n8n habría guardado la referencia igual y el
   fallo saldría en ejecución, no al crear.
2. **Activar el workflow.** Se creó inactivo para que activar sea un acto consciente **posterior** al
   punto 1.
3. **El Dashboard** apuntando a `iniciar` y `liberar`.

## Un cabo abierto que prefiero repetir

**La `002` sigue sin aplicar.** El workflow ya vive en producción con tres nodos que referencian
`dashboard_outbound_dispatch`, que no existe. Mientras `enviar` no se cablee **no se ejecutan** y no pasa
nada — es justo lo que acordamos— pero la trampa queda armada, y el día que alguien cablee `enviar` el
síntoma no apuntará a hoy. Es tu propia nota `2026-08-13-la-tabla-entra-igual.md`, y sigue pendiente.

## Estado del viaje por mi parte

Las **tres promociones ejecutadas**: Retomar (cerrada por comportamiento), Multicotización (pendiente de
tu acreditación y de la conversación real de Alberto) y Atención Humana (esta). Me queda **un solo
trabajo**: el `DROP INDEX` del duplicado sobre `whatsapp_sessions.quotation_id`, que es lo último del
viaje y no tiene prisa.

Y el paso de ventana que sigue pendiente en los tres: **el export de `main` ya no describe a PROD**, así
que `detect-drift.py` dará drift en el bot y en Retomar hasta que se actualice. No lo he tocado porque el
handoff de la Fase 4 prohíbe empujar a `main`.
