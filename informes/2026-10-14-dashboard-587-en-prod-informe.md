# Informe (Dashboard): `#587` en PROD — el Resumen vuelve a cargar los datos de Meta

**De:** Agente Dashboard · **Para:** Arquitecto · **14 oct 2026**
**Responde a** `/Users/AIP/claude-projects/Dashboard_SeguroAuto/handoffs/2026-10-14-orden-prod-587-meta.md`.

## Hecho

1. **Base:** `git diff f5f07cd origin/main -- . ':!handoffs'` vacío. El código de `main` era el de `f5f07cd`.
2. **Qué viaja:** un commit, `e792724`, con el cambio neto de `apps/operacion/lib/meta.js` y `apps/operacion/pages/api/meta-analytics.js`: troceo de 10, ventana en días UTC cerrados y registro estructurado del error. Lleva un test propio, `scripts/s1/test/meta-587.test.js`.
3. **Qué no viaja:** ni `?diagnostico=1`, ni `max_ids`, ni `variante`. Tampoco los recuentos del diagnóstico (`diag`, `hayMas`), que en `stg` iban dentro de `templates` en la respuesta: los he quitado de `meta.js`.
   - **Diferencia con `stg`:** allí desaparecía el 400 cuando faltan `startDate`/`endDate`. En PROD se queda como estaba en `main`.
   - El test de `stg` sobre el diagnóstico se ha cambiado por otro: `?diagnostico=1` se ignora y la respuesta no lleva ni `diagnostico` ni `templates.diag`.
4. **Verificación:** suite **879/879**, verificador de `CLAUDE.md`, verificador de rutas en comentarios y `build` en verde. `s1-conformidad`, lanzado a mano sobre la rama (run `38625135795`): `success`. Preview del PR: `pass`.
5. **Merge:** PR **#37** con `--merge` → `main` = **`1eda3e6`**. Lo fusioné con la orden de Alberto dada en mi sesión («fusiona el #37»): el clasificador de permisos frenó el primer intento porque la orden me llegaba por ti.
6. **Production:** **`dpl_Ae8aK81QGWXxjWXXREYg5dHJUtSp` READY**, commit `1eda3e6`, rama `main`. Sacado de la API REST de Vercel (`/v6/deployments`).

## Control en PROD (sesión de Alberto, 14 oct)

`GET /api/meta-analytics?startDate=2026-09-14&endDate=2026-10-14`:

- **200**, `ok: true`, **11 plantillas**, 25 días con datos.
- Totales: **enviados 206, entregados 204, leídos 149**. Entrega 99 %, lectura 72 %, sin leer 55.
- Sin `templates.diag`. Con `&diagnostico=1` la respuesta es la normal, sin campo `diagnostico`.

## Pendiente

Nada del `#587`. En `stg` siguen el diagnóstico y el 400 retirado. Si quieres que `stg` se parezca a PROD, lo hago en una rama aparte.
