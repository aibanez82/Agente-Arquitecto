# Variables de entorno — Dashboard (Vercel)

> Movido desde `CLAUDE.md` el 19 ago 2026: es material de consulta del Dashboard, no una regla que
> el Arquitecto necesite en cada turno.

Proyecto: `Dashboard_seguroautoqualitas` (Vercel). Clon local: `~/claude-projects/Dashboard_SeguroAuto`.

| Variable | Para qué |
|---|---|
| `DATABASE_URL` | Postgres compartido con Django y n8n (read-only desde el Dashboard) |
| `GOOGLE_SERVICE_ACCOUNT_EMAIL` · `GOOGLE_PRIVATE_KEY` | Credencial de la service account de Google |
| `GA4_PROPERTY_ID` | Propiedad de GA4 que se consulta |
| `META_WABA_ID` · `META_ACCESS_TOKEN` · `META_PHONE_NUMBER_ID` | WhatsApp Business / Meta Graph API |
| `DASHBOARD_PASSWORD` | Acceso a la UI |
| `GITHUB_ISSUES_TOKEN` | Lectura/escritura del tracker desde el Dashboard |
| `N8N_API_KEY` | API de n8n — **la key es distinta en PROD y en STG** |
| `N8N_PROACTIVE_WEBHOOK_URL` · `PROACTIVE_MESSAGE_PASSWORD` | Webhook proactivo de n8n (única vía de escritura indirecta del Dashboard) |

⚠️ **Solo environments `Production` y `Preview` — nunca `Development`.**

⚠️ El CLI de Vercel no es autoritativo para env/deployments: usar la API REST.
