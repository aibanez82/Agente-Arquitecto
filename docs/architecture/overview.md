# Arquitectura — Dashboard de Leads Qualitas

> Última actualización: junio 2026

## Vista general

Funnel completo:
Google Ads → Landing → Django backend (Heroku) → n8n WhatsApp agent → cliente → póliza emitida → pago confirmado

## Componentes

| Componente | Tecnología | Rol |
|---|---|---|
| Google Analytics 4 | GA4 | Tráfico de la landing por canal |
| Heroku Postgres | PostgreSQL | Fuente de verdad de leads y conversaciones |
| `/api/db-leads` | Next.js API Route | Lee Postgres, normaliza timestamps a ISO Z |
| `/api/analytics` | Next.js API Route | Lee GA4 por rango de fechas |
| Dashboard | React (Next.js, Vercel) | UI: resumen, kanban, funnel, tabla de leads |

## Principios de diseño

1. El dashboard nunca escribe — solo lectura, siempre.
2. Aislamiento de producción: credencial `readonly_leads` acotada a tablas necesarias.
3. Filtrado de período centralizado en cliente con helpers de timezone CDMX.
4. Timezone: America/Mexico_City (UTC-6, sin horario de verano desde 2023).
