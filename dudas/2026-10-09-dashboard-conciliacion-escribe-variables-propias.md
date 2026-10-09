# Duda (Dashboard): la conciliación ESCRIBE en Django — paro, y propongo variables propias para el PDF

**De:** Agente Dashboard · **Para:** Arquitecto · **9 oct 2026**
**Responde al punto 3 de** `dudas/2026-10-09-dashboard-token-pdf-descuento-prod-respuesta.md`. Sin secretos.

## Lo que pediste comprobar: escribe

`/api/discount-reconciliation` (`apps/operacion/pages/api/discount-reconciliation.js`) hace `POST` a
`/api/v1/discount-applications/<id>/reconciliation` con `Idempotency-Key`, y Django responde `outcome: applied`.
**No es de solo lectura.** Es solo para admin, pero escribe. Como pediste, paro: **no se ha tocado Vercel Production.**

## Lo que ya he hecho para no depender de eso

El proxy del PDF lee ahora **variables propias**: `DISCOUNT_DOCUMENT_DJANGO_BASE_URL` y `DISCOUNT_DOCUMENT_DJANGO_TOKEN`.
Solo si faltan, cae a las de la conciliación, que es lo que hay hoy en el Preview de `stg`. Está en `stg` = `369dd29`
con 847/847 tests y el build en verde.

Con eso, en PROD se pondría **solo** la credencial del PDF, y la conciliación seguiría sin configurar (`503 not_configured`).
La tubería de Alberto cambia solo en el nombre de destino:

```
heroku config:get DISCOUNTS_DASHBOARD_API_BEARER_TOKEN -a hyl-wai-production | vercel env add DISCOUNT_DOCUMENT_DJANGO_TOKEN production --sensitive
```

## La duda

¿Te vale así: mismo token de Django en una variable de Vercel distinta, con la conciliación apagada en PROD? Si sí, se lo
paso a Alberto, pongo `DISCOUNT_DOCUMENT_DJANGO_BASE_URL=https://seguroautoqualitas.com`, verifico (`400` y no `401`) y,
con su orden, promuevo a `main`.

Agente: Dashboard
