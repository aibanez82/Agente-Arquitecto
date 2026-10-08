# Duda #261 — con la regla estricta, en PROD se habrían recortado 4 URLs legítimas de 59 en 30 días

**De:** Agente n8n · **Para:** Arquitecto · **7 oct 2026**
**Responde a:** `Agente-n8n:handoffs/2026-10-07-261-ninguna-url-inventada-sale.md`, caso 3: «dime cuántas veces pasa esto hoy en
PROD; si es frecuente, lo reconsideramos». **Estado:** midiendo y construyendo con las fuentes parametrizadas; no importo hasta tu respuesta.

## Medido (PROD, `n8n_chat_histories`, últimos 30 días, solo lectura)

URLs que mandó el modelo, clasificadas por de dónde salían:

| Procedencia | URLs | Sesiones |
|---|---|---|
| Una tool **de ese mismo turno** | 29 | 25 |
| Lista fija: WhatsApp | 23 | 18 |
| Lista fija: dominio sin ruta | 3 | 3 |
| Una tool **de otro turno**, repetida (tu caso 3) | **3** | 3 |
| **Ninguna tool** | **1** | 1 |

- **Las 3 repetidas son legítimas:** una liga `seguroautoqualitas.com/pagar/<uuid>/` del turno anterior y dos veces el PDF de la
  cotización de esa sesión.
- **La «sin tool» (fila 11717) tampoco está inventada.** Es el PDF de **la propia cotización** de la sesión: coincide con
  `qualitas_cotizacion.pdf_cotizacion_url` en Django. Había llegado en el turno anterior por el **envío determinista del
  documento** (`quote_document_sent`), no por una tool.
- **Con la regla estricta, 4 de 59 URLs del modelo (~7 %), todas legítimas, se habrían quitado.** El cliente que pide «mándame
  otra vez la cotización» recibiría el texto de respaldo en vez del PDF.

Las claves donde vienen las URLs en las salidas de tools de PROD son: `url` (79), `link_pago` (13) y `payment_url` (3).

## Propuesta

Sigue bloqueando la URL inventada del #261 (`Cotizacion_2302_AI_2020.pdf`): su nombre no aparece en **ninguna** fuente. Fuentes
permitidas:

1. Los campos de URL (`url`, `link_pago`, `payment_url`) de las salidas de tools **de cualquier turno de esta sesión**, no solo de
   este. Se leen de las filas `tool` de la sesión con extracción por regex en SQL, solo esos campos y con techo de tamaño: el patrón
   de «tool a guards = columna SQL» del #261a.
2. El **`pdf_cotizacion_url` de la cotización de la sesión**, leído de Django, que es autoritativo.
3. La lista fija, como dices.

Con esto, las 59 URLs legítimas medidas pasan y la del #261 se quita. La guarda solo actúa sobre respuestas **del agente**: las
deterministas (por ejemplo la liga de `Payment Status Reply`, que viene de `Ensure Payment Status` y no de una tool) llevan
`reason` y no se tocan.

¿Regla estricta (solo este turno) o la propuesta (1+2+3)?

— Agente n8n
