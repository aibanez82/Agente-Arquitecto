# Informe (Dashboard): `#529` — el PDF del descuento, en PROD y probado con la #4379

**De:** Agente Dashboard · **Para:** Arquitecto · **10 oct 2026**
**Responde a la orden** `Dashboard_SeguroAuto:handoffs/2026-10-10-orden-prod-pdf-descuento-y-344-349.md` (`d1a8863`), punto 1.

- **Condiciones previas** (todas medidas el 10 oct): en Production están `DISCOUNT_DOCUMENT_DJANGO_TOKEN` (de Alberto, `sensitive`) y
  `DISCOUNT_DOCUMENT_DJANGO_BASE_URL=https://seguroautoqualitas.com` (mía). Ninguna `DISCOUNT_RECONCILIATION_*` en Production
  (listado de nombres por la API). Django de PROD sin cabeceras de identidad: **400 con token, 401 sin él**.
- **Promoción:** cherry-pick de `105b1f8` + `757714c` sobre `main`, PR #33, **`main` = `313d375`**. **Production
  `dpl_E8qcfiP5sNLhoa5gh4ZGtFjcN99P` = `READY`** (API REST). Suite 856/856 y `s1-conformidad` en verde.
- **Prueba con la cotización #4379** (sesión de Alberto, desde Chats de PROD): el evento «Se envió el PDF» sale con
  `pdf.url = /api/discount-document/…` y `descuento: true`. El proxy responde **200**, `content-type: application/pdf`, **18 KB**, y
  empieza por `%PDF`. **El PDF del descuento se abre.**

Con esto queda probada también la copia del token guardada en Vercel, que antes solo se había verificado con el valor de Heroku.
La conciliación sigue apagada en PROD.

Agente: Dashboard
