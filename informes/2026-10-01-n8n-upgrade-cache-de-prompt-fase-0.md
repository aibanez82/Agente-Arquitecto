# Informe — upgrade de n8n para el caché de prompt · FASE 0: reconocimiento (solo lectura)

**De:** Agente n8n · **Para:** Arquitecto · **1 oct 2026**
**Responde a:** `Agente-n8n:handoffs/2026-10-01-upgrade-n8n-cache-de-prompt-fase-0.md` (`94b14b67`).
**No se ha tocado nada** en ninguno de los dos entornos. Cada fila lleva su fuente: «vivo» quiere decir medido hoy
en la instancia; «fuente n8n» quiere decir leído en `github.com/n8n-io/n8n` en la etiqueta indicada.

## Lo esencial, antes de las tablas

1. **No hace falta subir la `typeVersion` de los nodos.** En n8n ≥ **2.37.0**, la opción `Prompt Caching`
   (`disabled`, `5m` o `1h`) vive en la colección `Options` **sin condición de `@version`**: aparece también en
   nuestros nodos **1.3**. Bastaría con actualizar n8n y fijar `options.promptCaching` en los nodos que
   queramos. Así no arrastramos los cambios de la 1.5 y la 1.6: selector de modelo, `Thinking Mode` y `Effort`.
2. **Al actualizar cambia la métrica de tokens de n8n, aunque no se active nada.** Desde la 2.37.0,
   `promptTokens` = `input_tokens + cache_creation + cache_read`; hoy solo cuenta `input_tokens`. Como
   `autocache` ya cachea, después del upgrade el `promptTokens` del AI Agent subirá unas **3 veces sin que suba
   lo que se paga**. Cualquier comparación «antes/después» tiene que hacerse con la API de Anthropic o con la
   misma fórmula en los dos lados, nunca con el `promptTokens` crudo.
3. **El riesgo nuevo de verdad es el doble caché.** El nodo pone `cache_control` en el **nivel superior** de la
   petición, y el proxy (si es `montevive/autocache`) inyecta `cache_control` **en bloques**. Cómo convive eso
   con el límite de 4 breakpoints de la API **no lo sé**, y es la primera prueba de la fase 1. La alternativa es
   no activar la opción del nodo y quitar el proxy, o al revés.

## 1. Versiones (vivo)

| Dato | PROD | STG | Fuente |
|---|---|---|---|
| n8n | **2.28.7** | **2.28.7** | vivo: `release` de la meta `n8n:config:sentry` del HTML del editor (`n8n@2.28.7` en los dos). Es un método nuevo: la API pública no da la versión, y esta meta sí |
| `lmChatAnthropic`, `typeVersion` | 5 nodos, todos **1.3** | 5 nodos, todos **1.3** | vivo: API, bot `632c0a3a` / `c9501d23` |
| Nodos y opciones | Anthropic Chat Model → AI Agent `{maxTokensToSample: 8000}` · Anthropic Chat Model2 → RAG IA Agent `{}` · Discount Classifier Model → Discount Intent Classifier `{}` · Anthropic Chat Model1 → Intent Router `{}` · Haiku → Detect Jailbreak `{}` | igual | vivo |
| Inactivos con estos nodos | `#135 CANDIDATO PROD — NO ACTIVAR` (5 nodos 1.3; el AI Agent sigue con 2000) | — | vivo |

## 2. El nodo y el caché, en el código fuente (fuente n8n)

| Pregunta | Respuesta | Fuente |
|---|---|---|
| ¿Desde qué versión? | **n8n 2.37.0**. La 2.36.0 no la tiene. | `LmChatAnthropic.node.ts` en `n8n@2.36.0` (sin `promptCaching`) y en `n8n@2.37.0` |
| ¿Qué `typeVersion`? | Aparece con la **1.6** (nueva `defaultVersion`), pero la opción **no está restringida por versión**: sirve en la 1.3 | `n8n@2.37.0` y `n8n@2.41.5`: `promptCaching` dentro de `Options`, sin `displayOptions` de versión |
| ¿Qué envía? | `invocationKwargs.cache_control = {type: 'ephemeral', ttl: '5m'\|'1h'}`: **un único campo en el nivel superior de la petición**, no `cache_control` por bloque. La descripción de la opción dice que cachea «system prompt, tool definitions, and conversation history». No he verificado cómo coloca la API ese breakpoint de nivel superior | `supplyData`, 2.37.0 |
| ¿Cambia algo más en un nodo **1.3**? | **thinking:** sin cambio para nosotros. Desde alguna versión entre 2.28.7 y 2.41.5 solo se envía `thinking: disabled` si el nodo tiene `thinking === false` **explícito**; los nuestros no tienen la clave, así que siguen sin mandar `thinking` y Sonnet 5 sigue en adaptive, como hoy. **max_tokens:** sin cambio. **Formato de herramientas:** no hay cambio en este fichero; lo que haga la versión de `@langchain/anthropic` que trae el upgrade **no lo he leído**. **Métrica:** cambia `promptTokens` (punto 2 de arriba). **Red:** el cliente pasa a usar `getSecureEgressFilter()` (ver §3) | diff de `supplyData` entre `n8n@2.28.7` y `n8n@2.41.5` |
| ¿Sirve para `Extract VIN Vision`? | **No.** Es un `httpRequest` a mano a `api.anthropic.com/v1/messages` (Sonnet 4.5, `max_tokens` 300); la opción del nodo no le llega. Habría que poner `cache_control` en su `jsonBody`. Coste despreciable: 8 llamadas en 216 ejecuciones | vivo |

## 3. `autocache:8080`

| Dato | Lo que sé | Fuente |
|---|---|---|
| Dónde está configurado | Es la **URL de la credencial** Anthropic (`credentials.url` → `baseURL`), no un parámetro del nodo. Las peticiones salen con `anthropic_api_url: "http://autocache:8080"` | `inputOverride` de las ejecuciones (67628, 67660) + `supplyData` |
| Desde cuándo | **Primera evidencia: 19 sep, 01:00 UTC** (PROD 50074, nodo Haiku). Antes de eso no tengo ejecuciones retenidas que mirar | traza `scripts/monitores/trazas-325/traza-PROD-50074.json` |
| Qué es | **Candidato fuerte, sin confirmar: `montevive/autocache`.** Proxy para n8n que «inyecta cache-control en los breakpoints óptimos», puerto 8080, imagen en GHCR, estrategias `conservative`/`moderate`/`aggressive` y cabeceras `X-Autocache-*` en la respuesta. **No sé qué imagen ni qué versión hay desplegada, ni quién lo levantó** | `gh search repos autocache anthropic` + README del repo |
| ¿Toca algo más que el caché? | **Lo que sí medí:** no toca `max_tokens`, porque las 3 llamadas que agotaron el tope cortaron exactamente en 2000. **Lo que no sé:** si toca `thinking`, el modelo o las cabeceras | ejecuciones del `#504` |
| ¿Funciona hoy? | **Sí, y mucho** (§4): el AI Agent registra el 31 % de lo estimado y el clasificador de descuentos un ~0 % | vivo |

**Acceso que haría falta para cerrar §3:** shell en los dos hosts, y lo teclea Alberto, como en el upgrade del
10 ago. Comandos de solo lectura:
`docker ps --format '{{.Names}} {{.Image}} {{.Status}}'` ·
`docker inspect autocache --format '{{.Config.Image}} {{.Created}} {{json .Config.Env}}'` (**redactando** las
claves antes de pegarlo) · el bloque `autocache` del compose · `curl -s http://autocache:8080/health` desde el
contenedor de n8n (devuelve versión y estrategia).

## 4. Coste de referencia hoy (vivo, PROD, 216 ejecuciones retenidas 61140→70089)

`promptTokens` es lo que registra n8n hoy, sin la caché leída. «Estimados» es el `estimatedTokens` que calcula
n8n por caracteres.

| Nodo | Llamadas | `promptTokens` mediana / suma | Estimados mediana / suma | Registrado / estimado (mediana) | Salida, suma |
|---|---|---|---|---|---|
| AI Agent (Sonnet 5) | 205 | 7.946 / 1.655.750 | 25.484 / 5.248.877 | **0,31** | 65.052 |
| RAG IA Agent (Sonnet 5) | 38 | 5.720 / 252.729 | 10.378 / 416.707 | **0,55** | 7.600 |
| Discount Intent Classifier (Sonnet 5) | 143 | **2** / 286 | 1.449 / 207.892 | **~0,00** | 5.316 |
| Intent Router (Haiku 4.5) | 141 | 1.422 / 200.980 | 1.132 / 160.070 | 1,26 | 2.136 |
| Detect Jailbreak (Haiku 4.5) | 141 | 1.084 / 153.345 | 962 / 136.048 | 1,13 | 3.336 |

- **Lectura:** los tres nodos Sonnet ya se benefician del caché del proxy. Los dos Haiku no. Mi hipótesis, sin
  verificar: sus prompts no llegan al mínimo cacheable del modelo.
- **Lectura y escritura de caché por la API:** **no las tengo.** n8n 2.28.7 no guarda `cache_read_input_tokens`
  ni `cache_creation_input_tokens`, y mis llamadas directas a la API saltan el proxy. La referencia exacta sale
  de la consola de uso de Anthropic, o de las cabeceras `X-Autocache-*` si es ese proxy.
- **Referencia de la llamada directa sin caché** (`#504`, 67628): 44.810 tokens de entrada, frente a 4.912
  registrados vía proxy.

## 5. Filas del §1 del manual

| Fila | PROD | STG | Fuente |
|---|---|---|---|
| Escenario de despliegue | Docker; compose en `/docker/n8n/docker-compose.yml` | Docker genérico (plantilla distinta) | informe del 10 ago, **no re-verificado hoy**: no tengo shell |
| BD interna de n8n | **SQLite**: copiar `.sqlite`, `-wal` y `-shm` juntos | **sin verificar** (ya lo estaba el 10 ago) | informe del 10 ago |
| Clave de cifrado | **fichero** `/home/node/.n8n/config` (56 B, `600`) dentro del volumen | sin verificar | informe del 10 ago |
| Tags de las imágenes | n8n y Traefik **fijados** el 10 ago (antes sin tag) | sin verificar | informe del 10 ago |
| Otros servicios del compose | Traefik, y ahora **`autocache`**: no sé si está en el mismo compose ni si su imagen lleva tag. Si comparte compose y va sin tag, un `pull` lo arrastra | sin verificar | — |
| Protección SSRF de salida (nueva) | Desde una versión posterior a la 2.28.7, el nodo pasa por `getSecureEgressFilter()`. **`N8N_SSRF_PROTECTION_ENABLED` vale `false` por defecto** en 2.41.5, así que `http://autocache:8080` (red privada) **no** se bloquea salvo que el entorno la active. Hay una regla de *breaking change* `v3/ssrf-default-blocked-ranges`: en n8n 3 el defecto puede cambiar | sin verificar el entorno | fuente n8n `ssrf-protection.config.ts`, `n8n@2.41.5` |
| ¿Misma versión en STG y PROD? | Sí, **2.28.7** | Sí | vivo (§1) |

## 6. Lo que el upgrade cambiaría en la API que usan mis herramientas

| Cambio (`workflow.yml` y esquemas, 2.28.7 → 2.41.5) | Efecto | Fuente |
|---|---|---|
| `settings` gana `credentialResolverId` (derivado, «se ignora al escribir») | `detect-drift.py` compara `settings` entero (lista blanca de nivel superior): **drift falso en todos los workflows**, la misma mina que `nodeGroups` el 10 ago. Mis builders filtran `settings` con una lista blanca al hacer PUT y no se ven afectados. `write_export` metería la clave nueva en todos los espejos: un commit de ruido | diff de esquemas en `packages/cli/src/public-api/v1/handlers/workflows/spec/schemas` |
| `binaryMode`, `timeSavedMode`, `availableInMCP` | **Ya aparecen hoy** en 2.28.7 (medido): no son nuevos | vivo |
| `callerPolicy: any`, deprecado («se quita en la versión 3») | Hoy **ningún** workflow usa `any`: PROD tiene 7 sin clave y 4 `workflowsFromSameOwner`; STG, 11 sin clave y 1 `workflowsFromSameOwner`. Sin efecto dentro de 2.x | vivo + `workflowSettings.yml` |
| `activeVersion` gana `name`, `description` y `autosaved` | Está fuera de la lista blanca del detector; sin efecto | esquemas |
| Desaparecen `workflowCreate.yml`, `tagIds.yml` y `workflowTags.yml` como ficheros | Reorganización del spec; **no verifico** que el `PUT` admita exactamente el mismo cuerpo. Es la prueba 0 de la fase 1 en STG | esquemas |

## Lo que no he podido medir y quién lo cierra

- §3 entero salvo la URL y la fecha de la primera evidencia: Alberto con shell, con los comandos de arriba.
- §5 para STG, y la re-verificación de PROD: Alberto con shell.
- Lectura y escritura de caché reales: consola de Anthropic, o cabeceras `X-Autocache-*`.
- Cambios de comportamiento de `@langchain/anthropic` entre las dos versiones: no lo he leído; va en las pruebas
  de la fase 1.

Agente: Agente-n8n
