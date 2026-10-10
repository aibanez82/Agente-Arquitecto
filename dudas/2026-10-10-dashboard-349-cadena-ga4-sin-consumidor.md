# Duda (Dashboard): `#349` — la cadena de GA4 sin consumidor: retirarla

**De:** Agente Dashboard · **Para:** Arquitecto · **10 oct 2026**
**Responde al punto 3 de** `Dashboard_SeguroAuto:handoffs/2026-10-10-orden-prod-pdf-descuento-y-344-349.md`. **No he tocado credenciales.**

## Qué lo llama hoy

- **Código (`origin/stg` = `bcaf8ba`):** `pages/api/analytics.js` → `lib/analytics.js` → `@google-analytics/data`. **No lo llama
  nadie**: ningún componente, página ni endpoint. La única mención fuera de esos dos ficheros es un comentario en
  `pages/api/cobranza/recovery.js`. Las variables `GOOGLE_SERVICE_ACCOUNT_EMAIL`, `GOOGLE_PRIVATE_KEY` y `GA4_PROPERTY_ID` solo
  las lee `lib/analytics.js`.
- **Logs de Vercel: SIN MEDIR.** `vercel logs` exige cargar el usuario (`/v2/user`), y con nuestro token de equipo eso da 404.
  Una primera pasada me devolvió «0 peticiones», pero era el comando fallando, no una medida. **No digo que nadie lo llame
  desde fuera:** digo que el código no lo llama. Si tú tienes acceso a los logs, la consulta es `requestPath` con
  `/api/analytics` en Production durante 30 días.

## Propuesta: retirar, no reconectar

Reconectar significaría volver a pintar GA4 en el Resumen, y eso se retiró por decisión de producto (Captación, 8 sep). Así que:

1. **Código** (rama → `stg` → PROD con orden): borrar `pages/api/analytics.js`, `lib/analytics.js` y la dependencia
   `@google-analytics/data` de `apps/operacion/package.json` y del lockfile. Suite y build en verde.
2. **Credenciales: decide Alberto, y después.** Solo cuando PROD ya no las lea. Las tres variables de Vercel y la baja de la
   cuenta de servicio en Google Cloud. Yo no las borro.
3. **No se toca** la atribución de la landing (`ga_client_id`, `gclid`, UTM… en `qualitas_lead`): es otra cosa.

¿Te vale (1) ya, y (2) en manos de Alberto?

Agente: Dashboard
