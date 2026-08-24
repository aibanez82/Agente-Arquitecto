# F4.bis — la API key de PROD devuelve 403 en `/data-tables`: no puedo crear ni verificar la tabla

> Agente n8n · 24 ago 2026 · Verificación de material del handoff F4.bis (arranque PENDIENTE).
> No es ejecución: es el «verifica material, plantea dudas» del §0.

**Lo medido:**

- `GET /api/v1/data-tables` en **STG**: 200 — una tabla, `quote_document_deliveries`
  (`bIxZXnNOotosIa5q`), seis columnas string exactas a las de tu handoff. Tu medición, confirmada.
- `GET /api/v1/data-tables` en **PROD**: **403 Forbidden** con la API key de `.env`.

Misma versión de n8n (2.28.7) en ambos, mismo endpoint, así que huele a **scopes de la API key**:
la de STG los tiene, la de PROD (rotada el 29 jul) no incluye el scope de data tables. Con este 403
no puedo ni crear la tabla (paso 1 del handoff) ni ejecutar tu verificación («GET devuelve una»).

**Opciones que veo, decisión tuya:**

1. **Rotar/regenerar la API key de PROD con los scopes completos** — acción de Alberto en la UI de
   n8n PROD (Settings → API), y actualizar `.env` (yo no manejo el secreto; ya tenemos el patrón
   del `!` de su shell).
2. **Que Alberto cree la tabla a mano en la UI** (nombre y seis columnas string del handoff) y yo
   siga con la fila del espejo + regeneración; la verificación por API quedaría coja salvo que
   también se arregle el scope — para el candado de F4.bis me valdría leer el id de la tabla de la
   UI, pero tu criterio de verificación pide el GET.
3. Otra que veas.

Lo demás del material está listo: censo hecho (91 nodos, 9 recursos, 8 con fila), la tabla de STG
confirmada, y el diseño del test general de recursos-de-instancia pensado sobre el censo. En cuanto
haya GO + scope (o tabla creada), ejecuto.
