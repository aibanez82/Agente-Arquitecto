# Informe — SESIÓN A · viaje 4 a PROD: emisión determinista ((c) + adenda 12)

**De:** Agente n8n · A · **Para:** Arquitecto · **16 oct 2026**
**Orden:** `Agente-n8n:handoffs/2026-10-16-A-orden-prod-614-406-emision.md` + adenda 6.
**Confirmación de Alberto en mi sesión:** «Sí, importa».

| Workflow PROD | Antes → después |
|---|---|
| Bot `BtOaZm7WlZT-24V7hqCnF` | **`f398537a`** → **`cc0f03f5-4fc9-47c7-b4a7-b2e8737ad68a`** |

- **Candidato:** el bot vivo con `cambio_emision.aplicar(con_url_guard=False)` encima, mediante `import-viaje-prod.py 11`. Lleva la adenda 12.
- **Respaldo:** `backups/viajes-prod/viaje11-bot-prod-f398537a-prePUT-20261016T185729Z.json`.

## Después del PUT (contra el respaldo)

| | Medido |
|---|---|
| Nodos nuevos | `IF Componer Emision?`, `Lee Poliza Emitida`, `IF Hay Poliza Del Turno?`, `Pide Liga Emision`, `Compone Mensaje Emision` |
| Nodos cambiados / quitados | **ninguno** |
| Prompts | `AI Agent` y `RAG IA Agent` intactos |
| `Pide Liga Emision` | `https://seguroautoqualitas.com/api/n8n/payment-link/ensure/`, con `httpHeaderAuth` «Django N8N_TOKEN PROD» (`2Vmw0G00lulXxDCa`). Es la configuración de la tool `Ensure Payment Link` de PROD |
| Activo | sí |

**Aristas: las únicas `connections` que cambian.**

| Origen | Antes | Ahora |
|---|---|---|
| `Apply Guardrail Result` | → `Strip Guardrail Marker` | → **`IF Componer Emision?`** |
| `IF Componer Emision?` (nuevo) | — | verdadero → `Lee Poliza Emitida` · falso → **`Strip Guardrail Marker`** |
| `Lee Poliza Emitida` (nuevo) | — | → `IF Hay Poliza Del Turno?` |
| `IF Hay Poliza Del Turno?` (nuevo) | — | verdadero → `Pide Liga Emision` · falso → `Compone Mensaje Emision` |
| `Pide Liga Emision` (nuevo) | — | → `Compone Mensaje Emision` |
| `Compone Mensaje Emision` (nuevo) | — | → **`Strip Guardrail Marker`** |

Las dos vueltas a `Strip Guardrail Marker` son la rama falsa de `IF Componer Emision?` y la salida de `Compone`.

**Espejo:** `main` en `de147b50`, y `stg`.

## Para observar en PROD
- **La primera emisión real.** `Compone Mensaje Emision` deja `console.log('EMISION_DETERMINISTA', {variante, poliza, liga, fuente_liga})`. Lo esperado es `fuente_liga: turno` con una liga `https://seguroautoqualitas.com/pagar/…`.
- **Sin `URL Fidelity Guard`** (no existe en PROD), el mensaje sale entero: lo demostró el arnés `--como-prod`, 12/12.

Agente: Agente n8n · A
