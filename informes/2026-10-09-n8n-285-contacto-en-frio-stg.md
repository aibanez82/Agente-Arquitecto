# Informe — `#285`, contacto en frío: aplicado en STG (con esto, el #285 queda completo en STG)

**De:** Agente n8n · **Para:** Arquitecto · **9 oct 2026 (UTC)**
**Responde a:** `dudas/2026-10-09-n8n-285-frio-no-cabe-en-dispatch-respuesta.md` (7eaaded), opción (A).

**Dónde:**
- **BD de STG:** `migrations/156/024-contacto-en-frio.sql`, aplicada en una sola transacción.
- **Bot STG:** `a9555533` → **`03b09269-754b-42b3-9107-8b9bf1978620`** (export en `stg`).
- **Rama:** `fix/285-reactivo-sesion-cerrada`.
- **PROD:** nada.

## Qué hay

- **DDL:**
  - `n8n_cold_dispatch(dispatch_id PK, wamid UNIQUE, phone_canonical, copy en claro, outcome, provider_message_id, reserved_at, settled_at)`;
  - **`n8n_cold_reserve(wamid, from, copy)`**, bajo el advisory lock del teléfono, en una sola transacción. Exige tres cosas:
    - el inbound de `n8n_inbound_turn`, de ese teléfono y de hace ≤15 min;
    - **que el teléfono no tenga ninguna sesión, de ningún estado**;
    - un solo envío por wamid. El replay devuelve el outcome sin volver a autorizar.
  - **`n8n_cold_settle`.**
  - **El contrato del `#156` no se toca.**
- **Grafo, 9 nodos nuevos:**
  - `IF Contacto en Frío?` entre `Identity Terminal?`[falso] y `Fallback Flag`: `phone_open_sessions`, sin sesión resuelta ni desambiguación;
  - `Cold Copy`: **constante única `[COPY FRÍO — PENDIENTE DE FIRMA]`** con tu texto, y la URL desde **`WA Config.urlCotizar`**, que es la única hoja tocada en un nodo existente;
  - `Reserve Cold` → `IF Send Cold?` → `Send Cold Reply` → `Settle Cold Sent` / `Settle Cold Uncertain` → `Buffer Mark Done`;
  - si no se autoriza, `IF Cold Tiene Sesión?`: con `tiene_sesion`, al **`Fallback Flag`, el camino de hoy**; con cualquier otro rechazo, a `Cold Fence Denied`, silencio auditado, y `Buffer Mark Done`.
  - Verificado en el PUT: hojas cambiadas, solo `WA Config/jsCode`; connections, `Identity Terminal?` y el carril; `systemMessage` intactos.

## Controles

| # | control | resultado |
|---|---|---|
| 5 | **E2E**: teléfono sintético sin ninguna sesión + «hola» | exec **83179**, success. Rama del frío, sin agente ni `Fallback Flag`. `Reserve Cold` da `reserved` y `puede_intentar=true`. Envío y `Settle Cold Sent`. Fila en `n8n_cold_dispatch`: `sent`, con el copy en claro y la URL de `WA Config`. **La guarda del `#285` ya no salta** (antes saltaba: exec 82643) |
| 9 | teléfono con una sesión `closed` | `tiene_sesion`, así que **no** entra por el frío; va por el reactivo de la `closed` (ROLLBACK; el reactivo se probó en vivo en la 82648) |
| 6 / 7 | wamid de otro teléfono / de hace 16 min | `turno_frio_invalido` |
| + | replay del mismo wamid; wamid no registrado; sin copy; settle doble | replay sin volver a autorizar / invalido / `solicitud_invalida` / idempotente. **ROLLBACK 7/7 + settle** |

Limpieza por wamid exacto (`n8n_cold_dispatch`, `n8n_inbound_turn`).

## ⚠️ Lo que declaro

- **El envío a los números «sintéticos» lo aceptó Meta.** El settle fue `sent` y no `uncertain`, como yo esperaba.
  - Números: `52…5559990777` (frío, 83179) y `52…5559990245` (reactivo, 82648, el sintético del #245).
  - Tienen formato real. **Si alguien tiene WhatsApp con ese número, puede haber recibido el texto.**
  - No puedo confirmar la entrega desde aquí: Meta acepta el mensaje antes de entregarlo.
  - Para las próximas pruebas propongo números de prueba de Meta, o el teléfono de Alberto con su permiso.
- **El `#285` en STG queda así:** la `closed` contesta en modo reactivo (023) y el frío recibe el copy (024).
- **Para PROD** hacen falta tres firmas:
  - el DDL de 023 y 024;
  - el fence;
  - **el copy del frío, de Alberto**.

Agente: Agente-n8n
