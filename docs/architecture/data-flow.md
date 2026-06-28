# Flujo de datos

> Última actualización: junio 2026

## Secuencia de carga del dashboard

```mermaid
sequenceDiagram
    participant U as Usuario
    participant D as Dashboard (React)
    participant L as /api/leads
    participant A as /api/analytics
    participant GS as Google Sheet
    participant GA as GA4

    U->>D: Abre el dashboard / cambia período
    D->>L: GET /api/leads
    L->>GS: sheets.values.get (read-only)
    GS-->>L: filas crudas
    L-->>D: { resumen, leads[] }

    D->>A: GET /api/analytics?startDate&endDate&channel
    A->>GA: runReport (Analytics Data API)
    GA-->>A: usuarios por día y canal
    A-->>D: { totalChannelUsers, byDay }

    D->>D: Filtra leads por rango de fecha (cliente)
    D->>U: Renderiza métricas, kanban, funnel, tabla
```

## Funnel de conversión (lógica de negocio)

Dos flujos posibles según el canal de origen del lead:

```mermaid
graph LR
    subgraph "Flujo Landing"
        L1[COTIZACION_INICIADA] --> L2[WHATSAPP_SALUDO] --> L3[PAGO_APROBADO]
    end

    subgraph "Flujo WhatsApp"
        W1[COTIZACION_INICIADA] --> W2[WHATSAPP_SALUDO] --> W3[DATOS_EMISION_INICIADOS] --> W4[CONFIRMACION_DATOS] --> W5[DATOS_EMISION_COMPLETADOS] --> W6[POLIZA_EMITIDA] --> W7[PAGO_APROBADO]
    end
```

**Nota clave:** `WHATSAPP_SALUDO` no es un estado "frío" — implica que el lead **ya cotizó** en la landing. El saludo es la primera interacción de la IA de WhatsApp con un lead que ya entregó sus datos iniciales.

## Variables de entorno requeridas

| Variable | Usado por | Descripción |
|---|---|---|
| `GOOGLE_SERVICE_ACCOUNT_EMAIL` | `lib/sheets.js`, `lib/analytics.js` | Email de la cuenta de servicio |
| `GOOGLE_PRIVATE_KEY` | `lib/sheets.js`, `lib/analytics.js` | Llave privada (rotar periódicamente) |
| `SHEET_ID` | `lib/sheets.js` | ID del Google Sheet de leads |
| `SHEET_NAME` | `lib/sheets.js` | Nombre de la pestaña (ej. `Hoja 1`) |
| `GA4_PROPERTY_ID` | `lib/analytics.js` | Property ID numérico de GA4 |

## Caché

- `/api/leads` — `s-maxage=300` (5 min) en el edge de Vercel
- `/api/analytics` — `s-maxage=120` (2 min)

El botón "Actualizar" del dashboard fuerza una nueva petición desde el cliente, pero puede seguir sirviendo la respuesta cacheada de Vercel hasta que expire.
