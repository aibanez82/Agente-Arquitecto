# Informe n8n · STG: la credencial de Anthropic pasa por `autocache` (HECHO)

**Orden:** `Agente-n8n:handoffs/2026-10-09-stg-credencial-anthropic-a-autocache.md` (`3ff581c6`). Hecho **antes** de la prueba real
de Alberto en `waq_2981_ac9b378a53dc`, según tu corrección.

## Qué cambió

- **Credencial:** una sola, `Anthropic STG` (`aHI51VvnRnPixCx5`, `anthropicApi`). La usan 6 nodos del bot STG: `Anthropic Chat
  Model`, `Anthropic Chat Model1`, `Anthropic Chat Model2`, `Haiku`, `Discount Classifier Model` y `Extract VIN Vision`. Ningún
  otro workflow de STG la usa. `Extract VIN Vision` lleva la URL escrita en el nodo (solo toma de la credencial la autenticación),
  así que **no cambia**, como en PROD.
- **`url`: `https://api.anthropic.com` → `http://autocache:8080`. La clave NO se ha tocado ni leído:**
  - `PATCH /credentials/{id}` con `isPartialData: true` y `apiKey = CREDENTIAL_BLANKING_VALUE`. En n8n 2.28.7
    (`credentials.service.ts`, `unredactRestoreValues`), ese marcador se sustituye por la clave guardada; es el mismo mecanismo
    que usa la interfaz.
  - El PATCH con solo la URL lo rechaza el esquema («requires property apiKey»), y uno con `data` completo exigiría mandar la
    clave.
  - `updatedAt` 2026-10-09T18:26:25Z.
- **Estado previo** (sin secreto): `Agente-n8n/backups/firmas/credencial-anthropic-stg-previa-20261009T182552Z.json`. La URL previa
  es la de la exec 83641. **Revertir** = el mismo PATCH con `url: https://api.anthropic.com`.

## Aceptación (arnés sin envíos: copia del bot STG `5d152d69`, todos los Send neutralizados)

- **`anthropic_api_url = http://autocache:8080` en 9/9 ejecuciones** (todas las que corrieron nodos de modelo). Las llamadas
  respondieron, así que la clave se conserva: es la prueba funcional que pide el gotcha 11.
- **Regresión N=3**, comparada con la misma batería del arnés antes del cambio:

| Caso | Antes | Ahora |
|---|---|---|
| CASO A (frase de Alberto) | literal | **3/3 literal** (con el saludo de Carla) |
| L1 | 5/5 | **3/3** |
| K3 | «financiamiento» 4/5; dos cifras **0/5** (`b4a0f6cf`) | «financiamiento» **3/3**; dos cifras **0/3** |

  **No cambia el comportamiento.** K3 no da las dos cifras en el arnés ni antes ni ahora: la sesión sembrada no trae
  `quotation_data`. Las cifras de la prueba real de Alberto (exec 83640) salieron de una sesión con cotización completa.
- **Cabeceras `X-Autocache-*`:** no aparecen en los datos de ejecución de n8n (el nodo de modelo no expone las cabeceras de
  respuesta). Para verlas haría falta mirar en el contenedor o en los logs del proxy.

Evidencia: rama `fix/firmas-paquete-prompt-stg` de Agente-n8n (`scripts/firmas/c1/aceptacion-autocache-5d152d69.json`).

Agente: Agente-n8n
