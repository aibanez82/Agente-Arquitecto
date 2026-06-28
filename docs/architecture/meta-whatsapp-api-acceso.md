# Meta / WhatsApp Business API — Acceso y Limitaciones

## Configuración actual

| Parámetro | Valor |
|---|---|
| WABA ID | En variable de entorno `META_WABA_ID` |
| Phone Number ID | En variable de entorno `META_PHONE_NUMBER_ID` |
| Access Token | En variable de entorno `META_ACCESS_TOKEN` |

## Limitaciones conocidas

- La API de analytics de Meta solo devuelve datos de los últimos 7 días
- Los conteos (enviados, entregados, leídos, respondidos) tienen una ventana de reporte con lag de ~24h
- El token de acceso fue revocado accidentalmente (expuesto en chat) — requiere regenerar

## Métricas disponibles

| Métrica | Descripción |
|---|---|
| `sent` | Mensajes enviados desde el número de WhatsApp Business |
| `delivered` | Mensajes entregados al dispositivo del destinatario |
| `read` | Mensajes abiertos por el destinatario |
| `replied` | Mensajes a los que el destinatario respondió |

## Estado actual

⚠️ Token revocado — Meta Business API desconectada hasta regenerar token.
Endpoint `pages/api/meta-analytics.js` retorna error hasta reconexión.
