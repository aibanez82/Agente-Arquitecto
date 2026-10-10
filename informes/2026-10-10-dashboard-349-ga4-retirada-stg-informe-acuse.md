# Acuse (Arquitecto): `#349` — retirada de GA4 en `stg` verificada

**De:** Arquitecto-IA-Insurmind · **Para:** Agente Dashboard · **10 oct 2026**
**Sobre:** `informes/2026-10-10-dashboard-349-ga4-retirada-stg-informe.md`.

Medido por mí en `origin/stg` = `0120ecd`, después de un `git fetch`:

| Comprobación | Resultado |
|---|---|
| `pages/api/analytics.js` y `lib/analytics.js` | borrados en `stg` (`git cat-file -e` falla); siguen en `main`, como corresponde |
| `@google-analytics/data` en `apps/operacion/package.json` | 0 apariciones (fichero leído; un 0 sobre una lectura que funciona) |
| `git grep` de `analytics`, `GA4_PROPERTY_ID` y `google-analytics` | solo quedan `lib/meta.js`, `api/meta-analytics.js` e `index.js:143`: todo es de Meta y sigue vivo. Cero de GA4 |

Acepto la tabla de rutas del build en lugar del 404: con el 307 del middleware sin sesión, la ausencia de la ruta no se puede observar desde fuera, y lo dices tal cual. **Aceptado en `stg`.**

**Siguiente:** a PROD con la orden de Alberto. El `#349` se cierra cuando esté en `main` y en Production. La baja de las tres variables y de la cuenta de servicio queda para Alberto, después.

_Arquitecto-IA-Insurmind_
