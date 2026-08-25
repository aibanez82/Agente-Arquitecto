# Informe — Fuentes secadas en STG, y la sonda produjo la prueba definitiva: el guard capturó un leak real

**De:** Agente n8n · **Para:** Arquitecto-IA-Quálitas · **Fecha:** 2026-08-25 (UTC)
**Handoff:** `2026-08-25-secar-las-dos-fuentes-del-parametro.md` · **Issue:** `HYL-WAI#228`

## Qué hay vivo en STG

Las dos sustituciones **verbatim** (extraídas programáticamente del handoff): la descripción de la
tool `Get Quotation Data` (tu tesis de la traducción es consistente con lo medido) y el `EDGE CASE`
en mayúsculas con su paréntesis y los dos puntos movidos a la segunda línea.

- Import por API: PUT 200. `versionId` `bbf5a809-…` → **`55597fe6-a87f-44ca-9b13-97a6ac2fe48a`**,
  `active: true`, **233 nodos**.
- Git: rama `fix/228-secar-fuentes` **apilada sobre `fix/228-outbound-leak-guard`** (mismo JSON,
  sin conflicto que resolver, como pediste). **PR #94** (base: la rama del PR #93). Orden de merge
  cuando Alberto lo ordene: #93 → #94. Export de la rama = vivo (sync sin diferencias).

## Aceptación

| # | Comprobación | Resultado |
|---|---|---|
| 1 | Barrido `/i` sobre el workflow entero | ✅ 11 ocurrencias: disparadores (AI L138, L318-nuevo, RAG L92, tool L3), prohibiciones (AI L140, RAG L95, tool L3) y maquinaria de las dos guardas (jsCode). **Ninguna instruye cómo nombrarlo ni lo describe al cliente** |
| 2 | Tool llamable, esquema sin cambio | ✅ método/url/jsonBody idénticos; solo texto de descripción |
| 3 | Disparadores vivos (dos agentes + tool) | ✅ conteo ≠ 0 en los tres |
| 4 | `Outbound Leak Guard` y `Filter System Leaks` intactos | ✅ jsCode idéntico pre/post |
| 5 | Nodos STG | ✅ 233 |
| 6 | Ejecución real con la pregunta literal de Alberto | ✅ ver abajo |
| 7 | PROD | ✅ HTTP 200, `8c43fdd0-…` intacto |

## §6 · La ejecución que importa — `16159`, y es la prueba definitiva de tu tesis

Sonda con la pregunta **literal** de las 10:15: `que significa el parametro qualitas?`
(webhook firmado, sesión del número de prueba, cotización 2207). `success`, carril RAG,
Meta devolvió wamid.

**Lo que el RAG generó (crudo, medido en `runData`):**

> El "parámetro Quálitas" es un dato interno que usamos para nuestros cálculos y no afecta lo que tú pagas. Tu cotización ya está al mejor precio disponible. ¿Quieres que avancemos con una forma de pago? 😊

**Es decir: el modelo siguió el fondo prescrito (dato interno, no afecta, mejor precio, forma de
pago) pero VOLVIÓ a repetir el término, violando el «no repitas el término» del prompt.** Tercera
evidencia de que el prompt solo no garantiza nada — esta vez con las tres capas de prompt ya secas.

**Lo que salió por WhatsApp (tras `Outbound Leak Guard`, `outboundLeakGuarded: true`):**

> Tu cotización ya está al mejor precio disponible. ¿Quieres que avancemos con una forma de pago? 😊

Sin término (`/i`), reconduce al precio, redacción quirúrgica a nivel de oración, mensaje natural,
no vacío. **Primera captura real del guard en el pipeline, y justo en el carril RAG — el que hasta
esta tarde no tenía guarda determinista ninguna.** El apilado de los tres handoffs de hoy cerró
exactamente el hueco por el que esto habría salido al cliente.

## Observación (no es una quinta fuente; no la he tocado)

En la `16159` el RAG **no llamó a `Get Quotation Data`** pese a que la pregunta nombra el parámetro
y el disparador lo exige («EN ESTE MISMO TURNO ANTES DE RESPONDER»). Respondió el fondo correcto sin
consultar. Misma familia de conducta que el eco del término: obedece a medias. Con el guard en el
borde el riesgo de fuga queda contenido igualmente; lo dejo anotado por si quieres que el funnel lo
vigile.

## Estado del apilado #228 al cierre

| Capa | Estado |
|---|---|
| Prompts (2 agentes) + `Filter System Leaks` extendido | vivo en STG (`ecd569c` mergeado a `stg`) |
| `Outbound Leak Guard` (borde, dos carriles) | vivo en STG; PR #93 sin mergear |
| Fuentes secadas (tool + EDGE CASE) | vivo en STG; PR #94 apilado sin mergear |
| PROD | **todo apagado**, `8c43fdd0-…` confirmado en tres lecturas hoy |
