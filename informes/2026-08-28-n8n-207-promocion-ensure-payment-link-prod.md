# Informe — #207: `Ensure Payment Link` promovida a PROD

**De:** Agente n8n · **Fecha:** 2026-08-29 ~00:5x UTC (28 ago noche CDMX)
**Handoff:** `2026-08-28-promover-207-ensure-payment-link-prod.md` + Adenda 1 (`89a5cc8`)
**Orden de arranque:** DADA por Alberto en sesión (28 ago, chat): «Orden de arranque DADA: ejecuta el #207». Autoriza Juan en `HYL-WAI#207` (22:51Z).

## Qué queda dónde

- **PROD vivo** (`BtOaZm7WlZT-24V7hqCnF`): `c743c11f` (230 nodos) → **`01e5c0fb-ebbf-4938-9b60-8d1c4f48a081`** (231, `active: true`). Un nodo (`Ensure Payment Link`) y una arista (`ai_tool → AI Agent`, idx 0). Nada más tocado.
- **Respaldo pre-import:** `Agente-n8n:backup/2026-08-28-prod-pre-207-import` (`0028ea4`).
- **Espejos:** `origin/stg` y `origin/main` de Agente-n8n sincronizados con el vivo (`sync(#207)`, `6c90be2` en stg y su gemelo en main).
- **Script del deploy** (dry-run por defecto, parada de deriva contra `c743c11f`): rama `fix/207-promocion-prod` (`6856531`), sin mergear — espera orden.
- **Reporte para Juan:** dos comentarios en `HYL-WAI#207` (pre-import y aceptación §6 completa con los cinco puntos citados frase a frase).

## Aceptación §6: 8/8, números dichos antes de medir

231 nodos (ni uno más), `postgres` exacto 46→46 (Adenda 1; con tools 54→54, también intacto), `active: true`, tv 4.3, única tool de liga de pago en `nodes[]`, host `seguroautoqualitas.com`, credencial `2Vmw0G00lulXxDCa` sin crear ninguna, `timeout` 28000, `toolDescription` idéntica carácter a carácter al `_stg`, arista única.

**Gotcha nuevo encontrado al medir:** el export de la API duplica el grafo entero dentro del envoltorio `activeVersion`; un barrido de cadenas sobre el export completo doble-cuenta (mi fila 6 dio falso FALLO hasta restringirla a `nodes[]`). Anotado aquí para quien mida igual.

## Parada de §5

Saltó contra el `8c43fdd0` original del handoff; resuelta con evidencia (backup `e03efe2` = pre-#228 con 229 nodos; `c743c11f` = post-import #228, medido por ti en el handoff del #232; vivo ≡ espejo stg ≡ espejo main, hash `aba16d4e`) **antes** de que llegara tu Adenda 1, que la ratificó. No se importó nada hasta tener la parada resuelta y la orden de Alberto dada.

## Validación en vivo (§7), sanitizada

| Caso | Resultado |
|---|---|
| Sin credencial | `401 {"status":"error","code":"unauthorized"}` ✓ |
| Credencial PROD + cotización de prueba `3506` (teléfono de Alberto) | `200 {"status":"not_available"}` ✓ |
| Forma inválida (`cotizacion_id` no numérico) | `400 {"status":"error","code":"invalid_request"}` ✓ |
| `not_available` conversacional por WhatsApp | **PENDIENTE** — pedido a Alberto en la sesión en vivo (desde su 5551074144, ningún otro número); anotaré id de ejecución y respuesta al hacerse |
| `available` | **NO EJERCITADO**, y deliberadamente: exige póliza real con liga viva; no se fabrica, no se tocan flags, no se usa póliza de cliente (§7). Hueco declarado, no tapado |

Las tres llamadas API fueron directas al endpoint (curl), no ejecuciones de n8n: no generan ids de ejecución. Los ids llegarán con la prueba conversacional.

## §8, cumplido

Promoción grande (246→230): no tocada. Generación backend/flags/proveedor: no tocados. Amortiguador y vallas: no tocados. Ninguna `payment_url` en ningún informe (la única respuesta con datos fue `not_available`, sin URL).

Sigo en la sesión con la prueba conversacional; los handoffs del #239 A y B quedan en cola detrás.

— Agente n8n
