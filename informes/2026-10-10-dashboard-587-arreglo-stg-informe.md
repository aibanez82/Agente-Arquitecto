# Informe (Dashboard): `#587` — el arreglo en `stg`: el Resumen vuelve a cargar los datos de Meta

**De:** Agente Dashboard · **Para:** Arquitecto · **10 oct 2026**
**Responde a** `dudas/2026-10-10-dashboard-587-590-respuesta.md`, parte `#587`.

## Estado

En `stg` = `ecd7719` (rama `fix/587-troceo-y-ventana-utc`). Suite **891/891**, los dos verificadores y el `build` en verde. **No está en `main`.**

## Qué

1. **Troceo en grupos de 10** `template_ids`, sumando **todos**. Había un fallo latente que lo habría estropeado: `processTemplateAnalytics` leía
   solo `data[0]`. Con el troceo llega una entrada por petición, así que ahora suma todas (`flatMap`).
2. **Ventana en días UTC completos** (`ventanaUtc`): de `startDate 00:00Z` hasta `min(endDate + 1 día, hoy 00:00Z)`. Termina en el último día
   cerrado y **nunca en el futuro**. Si no queda ningún día cerrado (por ejemplo, solo «hoy»), no se llama a Meta y se responde vacío, no 500.
3. **Retirados `max_ids`, `variante` y `trocear`.** Se quedan el diagnóstico solo admin (ahora también dice los `grupos` y la `ventana`) y el
   registro estructurado del error.
4. **Tests** (7): 11 → 10+1 y 25 → 10+10+5; los totales de todas las peticiones (11 y 25 enviados, no 10); la ventana nunca termina después
   de ahora y siempre cae en medianoche UTC; solo hoy, sin llamada; un `4182001` simulado en el registro con `code` y `error_subcode`; el
   diagnóstico sin token ni IDs, y `max_ids`/`variante` ignorados.

## Control en el Preview (sesión admin de Alberto)

- `GET /api/meta-analytics` (7 días) → **200**, `ok: true`, **7 días**, totales `sent 64 · delivered 63 · read 52` (98 % entregados, 81 % leídos).
- `?diagnostico=1` → `plantillas: 11`, `grupos: [10, 1]`, `ventana: 2026-10-04 → 2026-10-11 (excl.)`. En UTC ya era día 11, así que el 10
  es el último día cerrado.

**A PROD, con orden de Alberto.** Mismo control después: el Resumen de Production carga Meta con 200.

Agente: Dashboard
