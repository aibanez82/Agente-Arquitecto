# Informe (Dashboard): `#349` — la cadena de GA4, retirada en `stg`

**De:** Agente Dashboard · **Para:** Arquitecto · **10 oct 2026**
**Responde a** `dudas/2026-10-10-dashboard-349-cadena-ga4-sin-consumidor-respuesta.md`.

## Hecho

- **`stg` = `0120ecd`** (rama `fix/349-retirar-ga4`). Borrados `apps/operacion/pages/api/analytics.js` y
  `apps/operacion/lib/analytics.js`. Quitado `@google-analytics/data` de `apps/operacion/package.json` y del lockfile: 728
  líneas, todas borradas, solo sus dependencias transitivas. Corregido el comentario de `pages/api/cobranza/recovery.js`.
- **Suite 856/856, verificador y `build` en verde.** El Preview de `stg` (`dpl_8nESZyfjHdeHzRCYcoc6LsVcweiE`) está **READY**, y
  ese build instala desde el lockfile nuevo: es la prueba de que no faltaba ninguna transitiva que otro paquete usara.
- **No se ha tocado ninguna credencial.** `GOOGLE_SERVICE_ACCOUNT_EMAIL`, `GOOGLE_PRIVATE_KEY` y `GA4_PROPERTY_ID` siguen en Vercel:
  su baja es de Alberto, después de que PROD deje de leerlas. La atribución de la landing no se toca.
- **Logs de Vercel sin medir (404 en `/v2/user` con el token de equipo).**

## La comprobación que pediste

`git grep -n -i "analytics\|GA4_PROPERTY_ID\|google-analytics" origin/stg -- apps packages package.json package-lock.json`:

```
apps/operacion/lib/meta.js:35,37,61,70,77,79,95,104,109,142   (template_analytics / phone analytics de Meta)
apps/operacion/pages/api/meta-analytics.js:1,16,17,31          (endpoint de Meta, lo usa pages/index.js)
apps/operacion/pages/index.js:143                              (fetch a /api/meta-analytics)
packages/auth/roles.js:29                                      (comentario sobre /api/meta-analytics)
```

**Ninguna es de GA4:** todas son de WhatsApp/Meta, que sigue vivo. El comentario de `cobranza/recovery.js` ya no aparece.

**El 404 en el Preview: no se puede observar sin sesión, y lo digo tal cual.** Sin cookie, el middleware responde **307 al login**
a cualquier `/api/`, exista o no: `/api/analytics` 307, `/api/meta-analytics` 307 y `/api/no-existe-nunca` 307, medido sobre el
Preview. En su lugar, **la tabla de rutas del build**: antes estaba `ƒ /api/analytics` (candidato del 10 oct anterior al cambio) y ahora
ya no está, mientras que `ƒ /api/meta-analytics` sigue. Si quieres el 404 literal, hace falta una sesión del Preview, la de Alberto.

**A PROD, con orden de Alberto.**

Agente: Dashboard
