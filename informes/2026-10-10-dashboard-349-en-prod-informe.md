# Informe (Dashboard): `#349` en PROD — cadena de GA4 retirada; Production READY con `4ed6168`

**De:** Agente Dashboard · **Para:** Arquitecto · **10 oct 2026**
**Responde a la orden** `Dashboard_SeguroAuto:handoffs/2026-10-10-orden-prod-349-retirar-ga4.md` (`28cc4aa`).

## Las comprobaciones, una por una

1. **Antes:** `git diff --stat 313d375 origin/main -- . ':!handoffs'` sale **vacío**, y
   `git merge-base --is-ancestor 313d375 origin/main` se cumple.
2. **Candidato** (cherry-pick de `86d051a` sobre `main`, rama `promocion/349-retirar-ga4`): son 5 ficheros, +2 y −979, y **nada del
   `#344` ni del `#345`** (los busqué en la rama: ningún rastro). Suite 856/856, verificador y `build` en verde. `s1-conformidad`
   en verde (run `38080221146`).
3. **Después:** PR #34 fusionado, `main` = **`4ed6168`**. **Production `dpl_Hk69ur3sckJMLp19BbeDuYz1dkjr` = `READY`** con
   `4ed6168`, según la API REST de Vercel (`/v6/deployments`).
4. **En `origin/main`:**
   ```
   git show origin/main:apps/operacion/pages/api/analytics.js  -> fatal: path ... does not exist in 'origin/main'
   git show origin/main:apps/operacion/lib/analytics.js        -> fatal: path ... does not exist in 'origin/main'
   git show origin/main:apps/operacion/package.json | grep -c google-analytics          -> 0
   git grep -n -i "GA4_PROPERTY_ID\|google-analytics\|api/analytics\b\|lib/analytics" origin/main -- apps packages package.json package-lock.json | wc -l  -> 0
   ```
5. **Control positivo (Meta en el Resumen de PROD): PENDIENTE.** Hace falta la sesión de Alberto en Chrome y ahora mismo no
   está. Lo mido en cuanto entre, junto con el PDF de la #4379, y lo añado a este informe como adenda. Mientras tanto, lo que
   sí está medido es que `/api/meta-analytics` sigue en la tabla de rutas del `build` y que su código (`lib/meta.js`) no se
   ha tocado.

**No se han tocado las credenciales** de Google ni la cuenta de servicio. Logs de Vercel sin medir (404 en `/v2/user` con el
token de equipo).

Agente: Dashboard
