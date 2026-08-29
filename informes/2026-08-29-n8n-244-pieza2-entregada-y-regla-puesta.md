# Informe — #244 pieza 2: la 2285 entregada (68 s tras la reapertura) y la regla puesta

**De:** Agente n8n · **Fecha:** 2026-08-29 ~04:2x UTC
**Responde a:** `handoffs/2026-08-29-244-pieza2-el-vin-entra-y-nadie-entrega.md`

## §4 — desatascada y entregada

Reapertura de la fila del espejo a las **04:09:33Z** (`safe_terminal` → `scheduled`, script con dry-run); el poller la reclamó en su pasada siguiente y el carril terminó **sin ninguna otra intervención**: conversación activada, documento verificado, y **`Cotizacion_2285_TY_2020_Descuento_2026-08-28.pdf` entregada a las 04:10:41Z** (`delivery_outcome=sent`, dispatch `d156.delivery.236`, reporte a Django `reported`). La 236 cerró `completed`. **Alberto ya tiene el mensaje.**

## §3 — elección: (b), y por qué

`provide_required_data` reabre la fila (nodo `Reopen Discount Poll` tras `Normal Guard Copy`, condición de éxito dentro de la query, `onError: continue` para no callar el mensaje al cliente). Justificación sobre la mecánica real del claim: la única puerta de salida de `pending_data` está en nuestro grafo, así que reabrir en la puerta cubre todas las salidas; la opción (a) rompe contra el **presupuesto de 8 sondeos** — sondear un estado que depende del cliente lo quema en minutos y muere en `poll_budget_exhausted` → `uncertain`, que es otra vez la familia del silencio. Declarado en el issue: si mañana se abre otra puerta de salida (dashboard), esa puerta también reabre.

Residuo conocido: si la reapertura misma falla (Postgres caído justo ahí), el espejo puede volver a congelarse — el `onError: continue` deja el rastro en la ejecución pero no reintenta. Lo anoto como límite, no lo tapo.

## Estado

STG en **`ecab128b`** (260 nodos; postgres estricto 51 — quinta entrada de la deuda anotada en `#238` junto con tu argumento del §6, con la 236 como caso). Export sincronizado; scripts en `chore/scripts-noche-232-243-244` (`1c887fc`). PROD intacto desde el #239 A (`1ed79dac`).

## Aceptación §5

(1) ✓ y (3) ✓. Quedan (2) el camino completo de cero —objeción → `POR_VIN_40` → aceptar → VIN → entrega sola— y (4) la no-regresión de `POR_PRECIO…`, que salen en la próxima pasada de Alberto junto con la ráfaga del #232.

— Agente n8n
