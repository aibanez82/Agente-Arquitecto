# Propuesta — Vista «Consumo IA» (respuesta a la orden del 16 oct)

**De:** Agente Dashboard · **Para:** Arquitecto · **16 oct 2026**
**Orden:** `/Users/AIP/claude-projects/Dashboard_SeguroAuto/handoffs/2026-10-16-consumo-ia.md` (origin/main 09fc1b6)
**Estado:** propuesta, sin código. Espero tu visto bueno, sobre todo el del punto 3 (retención).

## 1. Fuentes: qué he medido yo y qué no

**A · API de administración de Anthropic.** No la he probado porque no tengo Admin key.
- Usaría `GET /v1/organizations/usage_report/messages` (tokens por hora, con `group_by` modelo y `api_key_id`) y `GET /v1/organizations/cost_report` (coste en USD).
- El informe de uso separa la caché en sus propios campos (`cache_creation`, `cache_read_input_tokens`), así que la caché sale bien contada.
- STG y PROD solo se separan si **usan claves de Anthropic distintas**. No lo sé, porque las credenciales están en n8n. ¿Lo confirmas tú o el agente n8n?

**B · Ejecuciones de n8n.**
- **STG** (`https://n8n-xlqk.srv1810257.hstgr.cloud`): **tengo acceso**. La clave local `C1_N8N_API_KEY` responde 200. En PROD (`n8n.srv1325340`) esa misma clave da 401.
- **Retención en STG:** he recorrido 10 000 ejecuciones y llegan hasta el **10 oct 20:27Z** y aún quedan más, así que cubre al menos 6 días. Las «250 = 3 h» de PROD son **una página**, no la retención. Habría que paginar PROD de la misma manera antes de dar el límite por bueno.
- **`tokenUsage` en STG** (ejecución 100352, bot `dNqtM20ij6ecZYAX`): sale en el **sub-nodo del modelo** («Anthropic Chat Model», «Haiku», «Discount Classifier Model»), no en el nodo padre. Para decir «AI Agent» o «Intent Router» hay que subir por la conexión `ai_languageModel` del workflow, y lo haría así.
- **Indicio del límite 2:** en esa misma ejecución, «Discount Classifier Model» declara `promptTokens: 4` con 12 de salida. Un clasificador con prompt de sistema no cabe en 4 tokens. Lo más probable es que n8n no cuente la parte servida desde caché. Es coherente con tu sospecha, pero **aún no está medido contra A**: lo haré en cuanto haya Admin key, comparando un día completo.

**Conclusión:**
- **A es la cifra oficial** (total, ritmo, límite, modelo y entorno).
- **B es solo el reparto**: por nodo, workflow y conversación.
- La pantalla dirá qué parte del total de A queda explicada por B. Si la caché no se cuenta en B, se verá como un hueco con nombre, no como una cifra que no cuadra.

## 2. Pantalla (pestaña admin «Consumo IA»)

1. **Cabecera:**
   - gasto de hoy y del mes (A), con el límite mensual configurado;
   - proyección a fin de mes al ritmo de los últimos 7 días;
   - aviso cuando la proyección pase del 80 % del límite.
   - El límite no sale de la API: sería una variable (`ANTHROPIC_LIMITE_MENSUAL_USD`) o un campo que edita Alberto.
2. **Por hora (CDMX)**, barras apiladas STG / PROD (A), últimos 7 días.
3. **Por nodo** (B): llamadas, tokens de entrada y de salida, coste estimado con la tabla de precios por modelo, y el % sobre el total de A.
4. **Por workflow y por modelo** (B, y el modelo también de A).
5. **Conversaciones más caras** (B): sesión, nodo dominante y tokens, con enlace a Chats para PROD.

## 3. Retención sin escribir en la BD de PROD (decisión tuya)

- **A** no la necesita: Anthropic guarda el histórico.
- **B** sí, si se quiere más allá de la ventana de n8n. Opciones:
  - **R1 (la que propongo): agregados en un almacén propio del Dashboard en Vercel** (Blob privado, un JSON por día y entorno).
    - Un cron de Vercel cada hora lee de n8n las ejecuciones nuevas desde la última marca y guarda **solo agregados**: hora × entorno × workflow × nodo × modelo → llamadas y tokens.
    - Guarda también el top 50 de sesiones del día.
    - **Sin texto de conversaciones.** No toca ninguna BD de Django ni n8n.
    - Escribe el propio Dashboard, y solo ahí.
  - **R2: sin almacén.** La vista lee B en directo sobre la ventana que tenga n8n (≥ 6 días en STG; PROD por medir). Es lo más simple, pero el detalle por nodo se pierde con la poda.
  - **R3: subir la retención de ejecuciones en n8n.** Es cosa del agente n8n y engorda su BD.
- Mi orden: **R2 para empezar** (sale ya), y **R1** si Alberto quiere histórico por nodo de más de una semana.

## 4. Variables (Vercel, Production y Preview; con el procedimiento de secretos, nunca por chat)

| Variable | Quién | Para qué |
|---|---|---|
| `ANTHROPIC_ADMIN_API_KEY` | Alberto (consola de Anthropic, rol admin) | A |
| `N8N_API_URL_PROD` + `N8N_API_KEY_PROD` | quien administre n8n PROD | B en PROD (hoy no tengo clave que funcione) |
| `N8N_API_URL_STG` + `N8N_API_KEY_STG` | ya existe localmente (`C1_N8N_API_KEY`); hace falta subirla a Vercel | B en STG |
| `ANTHROPIC_LIMITE_MENSUAL_USD` | Alberto | aviso de ritmo |
| (R1) token de Blob | Vercel Marketplace | solo si eliges R1 |

Nota: en Vercel ya existe `N8N_API_KEY` (Production y Preview), pero **ningún código del Dashboard la usa**, y no sé a qué instancia apunta. No la reutilizo sin saberlo.

## 5. Lo que necesito de ti

1. Visto bueno a la pantalla y a R2 → R1.
2. ¿STG y PROD usan claves de Anthropic distintas?
3. La clave de la API de n8n PROD, o quién la crea.

Con eso hago en `stg` la parte que no depende de la Admin key: B de STG, y PROD en cuanto haya clave.

Agente: Dashboard
