# Duda (Dashboard): token de Dashboard para el Django de PROD — PDF con descuento (#529)

**De:** Agente Dashboard · **Para:** Arquitecto · **9 oct 2026**
**Sin secretos en este fichero.** Alberto cree que el valor lo tienes tú.

## Contexto

- Django sirve el PDF privado del descuento desde el 3 oct (`HYL-WAI#529`, cerrado por Juan): `GET /api/v1/dashboard/discount-applications/<id>/document`, autenticado con `DISCOUNTS_DASHBOARD_API_BEARER_TOKEN` (`qualitas/discount_api.py:_authenticate_dashboard`).
- El consumidor del Dashboard está hecho: proxy `/api/discount-document/<id>?session=…`, en `stg` = `c79fe8e`. **Alberto lo probó en el Preview de `stg` el 9 oct y el PDF se abre.**
- El proxy usa la misma credencial que la conciliación de descuentos: `DISCOUNT_RECONCILIATION_DJANGO_TOKEN` + `DISCOUNT_RECONCILIATION_DJANGO_BASE_URL`. En Vercel **solo existen en Preview `stg`**, no en Production.
- El endpoint existe en PROD: sin credencial, `https://seguroautoqualitas.com/api/v1/dashboard/discount-applications/1/document` responde `401` con `WWW-Authenticate: Bearer` (medido el 9 oct).

## La duda

1. ¿Tienes el valor de `DISCOUNTS_DASHBOARD_API_BEARER_TOKEN` del Django de **PROD**? ¿Es distinto del de STG? Y, si no lo tienes, ¿está siquiera configurado en PROD?
2. ¿Cómo prefieres que llegue a Vercel Production, sin pasar por ficheros ni chat?
   - **(a)** Lo añades tú: `DISCOUNT_RECONCILIATION_DJANGO_TOKEN`, entorno `production`, tipo `sensitive`. La URL base (`https://seguroautoqualitas.com`) la pongo yo.
   - **(b)** Se lo das a Alberto en persona y él lo pega en un diálogo de macOS con campo oculto que le abro yo. Lo verifico sin datos: una petición sin cabeceras de identidad responde `400` si el token es bueno (Django autentica antes de validar) y `401` si no lo es.
3. Efecto colateral: con esa variable en Production, la **conciliación de descuentos** (solo rol admin) también queda activa en PROD. ¿Algún inconveniente?

## Qué me desbloquea

Con el token en Production y la orden de Alberto, promuevo `c79fe8e` a `main` y compruebo en PROD que el PDF se abre (caso de Alberto: cotización #4379, que sustituye a la #4375).

Agente: Dashboard
