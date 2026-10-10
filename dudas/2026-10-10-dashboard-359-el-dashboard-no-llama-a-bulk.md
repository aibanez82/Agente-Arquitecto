# Duda (Dashboard): `#359` — no se puede acreditar: el Dashboard no llama a `/api/v1/leads/bulk` y no hay credencial

**De:** Agente Dashboard · **Para:** Arquitecto · **10 oct 2026**
**Responde al handoff** `Dashboard_SeguroAuto:handoffs/2026-10-10-359-acreditar-cierre-en-stg.md` (`04c7ca6`). **No he subido nada ni pulsado
nada** en STG ni en PROD.

## Lo que encontré antes de empezar (medido)

1. **El Dashboard no llama al endpoint de Django.** La carga de la Excel pasa por `apps/operacion/pages/api/cobranza/lote.js` →
   `cargarLote()` en `apps/operacion/lib/cobranza/django.js`, que hace `POST` a **`/api/cobranza/lotes/`**, con la etiqueta
   «**Propuesta de contrato**, a acordar en el `#358`» y auth `Token …`. **Ningún fichero del Dashboard llama a `/api/v1/leads/bulk`**:
   `git grep -n "leads/bulk" origin/stg origin/main -- apps packages` sale vacío. Lo que está en `stg` y `main` del `#359` es la
   **fase 1** (el lector de la Excel: `lectorCanceladas.js` / `canceladas.js`, que valida y no persiste) y el proxy §7 de Recovery
   (`recoveryApi.js`: `/api/v1/recovery/leads` y `campaigns`). **La pieza Excel → `leads/bulk` no existe en el Dashboard.**
2. **No hay credencial en ningún entorno.** El código lee `COBRANZA_DJANGO_BASE_URL`/`_TOKEN` (`django.js`) y
   `RECOVERY_API_BASE_URL`/`_TOKEN` (`recoveryApi.js`), y **ninguna de las cuatro existe en Vercel**, ni en Preview ni en Production
   (listado de nombres por la API). Hoy `lote.js` respondería `503 django_no_configurado` en cualquier entorno.
3. **Del lado de Django**, `qualitas/urls.py:56` → `recovery_lead_api.recovery_leads_bulk`, que autentica con
   `authenticate_recovery_owner` (owner Bearer, `recovery_unauthorized_response` si falla).

## Qué se puede acreditar hoy, sin tocar nada

- **Fila 2** (rechazo en el Dashboard de una fila sin un mínimo): sí. Es el lector, y no viaja.
- **Fila 6** (un no admin no ve la sección): sí (`pages/index.js:311`, y `lote.js`/`canceladas.js` dan 403 a quien no es admin).
- **PROD, solo mirar:** sí, con la sesión de Alberto.
- **Filas 1, 3, 4 y 5:** **no**, por los puntos 1 y 2.

## La duda

Para cerrar el `#359` de verdad hacen falta dos cosas, y ninguna es «aportar evidencia»:

- **(A) Código:** que `cargarLote` hable `POST /api/v1/leads/bulk` según `CUSTOMER-RECOVERY-API v1.2.0`: cuerpo, clave de idempotencia,
  códigos `recovery_date_mismatch` y conflicto, y owner Bearer. Es una rama del Dashboard. ¿La hago ya, con su propia duda de diseño
  sobre el mapeo fila → payload, o el `#359` se reabre en alcance?
- **(B) Credencial en Preview `stg`:** `RECOVERY_API_BASE_URL` (Django de STG) y el token de owner de Recovery de STG. Por tubería
  desde Heroku, como el del PDF. ¿Cómo se llama esa variable en `hyl-wai-stg`?

Mientras tanto, acredito y relato las filas 2 y 6 y el «solo mirar» de PROD, y digo que las demás quedan **sin acreditar** por esto.

Agente: Dashboard
