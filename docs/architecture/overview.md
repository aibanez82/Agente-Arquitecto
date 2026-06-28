# Arquitectura — Dashboard de Leads Qualitas

> Última actualización: junio 2026
> Este documento se actualiza en el mismo commit/PR que cambia la arquitectura.

## Vista general

```mermaid
graph TD
    subgraph Fuentes de datos
        GS[Google Sheet<br/>Leads y Pólizas]
        GA[Google Analytics 4<br/>Tráfico landing]
    end

    subgraph "Cuenta de servicio Google Cloud"
        SA[leads-reader@dashboard-qualitassegurodeauto<br/>.iam.gserviceaccount.com<br/><i>solo lectura</i>]
    end

    subgraph "Vercel — Next.js"
        API1[/api/leads/]
        API2[/api/analytics/]
        UI[Dashboard React<br/>pages/index.js]
    end

    U[Usuario / Equipo comercial]

    GS -->|Sheets API<br/>read-only| SA
    GA -->|Analytics Data API<br/>read-only| SA
    SA --> API1
    SA --> API2
    API1 --> UI
    API2 --> UI
    UI --> U

    style GS fill:#E3F2FD
    style GA fill:#FFF3E0
    style SA fill:#FCE4EC
    style UI fill:#E8F5E9
```

## Componentes

| Componente | Tecnología | Rol |
|---|---|---|
| Google Sheet | Hoja de cálculo | Fuente de verdad de leads (vivo, actualizado por el equipo/bot de WhatsApp) |
| Google Analytics 4 | GA4 | Tráfico de la landing por canal (Paid Search, Direct, etc.) |
| Cuenta de servicio | Google Cloud IAM | Credencial de **solo lectura** compartida por ambas fuentes |
| `/api/leads` | Next.js API Route | Lee el Sheet, lo transforma a JSON, cachea 5 min |
| `/api/analytics` | Next.js API Route | Lee GA4 por rango de fechas, cachea 2 min |
| Dashboard | React (Next.js, Vercel) | UI: resumen, kanban, funnel dual, tabla de leads |

## Principios de diseño

1. **El dashboard nunca escribe** en ninguna fuente de datos — solo lectura, siempre.
2. **Aislamiento de producción**: el dashboard no se conecta directo a ningún sistema transaccional crítico (ver `django-mirror.md` para el caso de la base de datos de conversaciones).
3. **Una sola cuenta de servicio** con permisos mínimos (`SELECT`/lectura) reutilizada entre Sheets y GA4, en vez de credenciales distintas por integración.
4. **Filtrado de período centralizado**: el selector de fecha (Hoy/Semana/Mes/Personalizado) vive en el cliente y filtra tanto leads como GA4 con el mismo rango, para que las métricas sean comparables.

## Diagramas relacionados

- [`data-flow.md`](./data-flow.md) — detalle del flujo de datos por endpoint
- [`django-mirror.md`](./django-mirror.md) — arquitectura propuesta para la futura base de datos espejo de Django (pendiente de definir motor y modo de replicación)
