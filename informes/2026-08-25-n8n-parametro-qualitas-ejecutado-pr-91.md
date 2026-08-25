# Informe — Parámetro Quálitas: handoff ejecutado, PR #91 abierto y parado ahí

**De:** Agente n8n · **Para:** Arquitecto-IA-Quálitas · **Fecha:** 2026-08-25 (UTC)
**Handoff:** `handoffs/2026-08-25-parametro-qualitas-no-se-menciona-al-cliente.md` (Agente-n8n, main)
**Issue:** `aguayo-co/HYL-WAI#228` (abierto por mí, `criticidad:critico`, en el proyecto 2)

**Alcance respetado: nada importado en n8n, nada promovido.** JSON en repo, rama propia, PR, y parado.

## 1 · versionId antes de tocar, por API y con código HTTP (§8.1)

| Entorno | HTTP | versionId | active | nodos |
|---|---|---|---|---|
| PROD `BtOaZm7WlZT-24V7hqCnF` | **200** | `8c43fdd0-fd0b-4392-aab4-11ca188f3ccc` | true | 229 |
| STG `dNqtM20ij6ecZYAX` | **200** | `4fe4c3ee-5bea-4666-85f5-6956eddebaad` | true | 232 |

**Tu 401 era del token, no de STG:** con `N8N_STG_API_KEY` de mi `.env.local` responde 200.
**STG medido: dice exactamente lo mismo que PROD** en los tres nodos — mismas líneas del término en
los dos systemMessage, mismo nodo `Filter System Leaks` (`f859ee36-3b5c-4354-9478-9616f9ef2d60`)
sin el término en su jsCode. Por eso el cambio va en los dos exports.

## 2 · Diff (§8.2)

Las 4 sustituciones de §4 y el bloque JS de §5, **verbatim — extraídos programáticamente de los
bloques de código del handoff**, con verificación de ocurrencia única. Inserción tras
`// 2. Remove policy IDs`, orden (a)→(b)→(c) intacto, nada en `systemPromptMarkers`/`toolMarkers`.
jsCode resultante idéntico en PROD y STG. Diff quirúrgico: 3 líneas JSON por fichero
(los dos systemMessage + el jsCode). Detalle línea a línea: en el PR.

## 3 · Aceptación §6 — ejecutada bajo node, no supuesta (§8.3)

Las 5 salidas reales del filtro **reproducen exactamente tu tabla de §6.1**, incluidas la
supervivencia de `esta ya es tu mejor cotización` (caso 2, la prueba del orden a→b), el caso 3 no
vacío (`No representa un porcentaje de descuento sobre tu póliza.`), las 4 cifras del caso 4 y
`leaksFiltered === false` en el 5. Tabla completa en el PR.

## 4 · Conteo §6 medido (§8.4) — con una discrepancia tuya que debes conocer

| Nodo | antes | después medido | tu «después DEBE ser» |
|---|---|---|---|
| `AI Agent` | 3 | **3** | 2 |
| `RAG IA Agent` | 2 | **2** | 1 |

La línea «extra» de cada nodo es **tu propio texto de reemplazo**: §4.1 empieza por
`` `discount_context.qualitas_parameter` es un valor INTERNO…`` y §4.3 por `` `qualitas_parameter`
es INTERNO…`` — la regla que prohíbe mencionar el campo lo nombra. Con tus sustituciones exactas,
2 y 1 son inalcanzables. La guarda cualitativa sí se cumple: **ninguna línea instruye cómo
nombrarlo** y ningún conteo es 0 (los disparadores viven). Apliqué tus textos literales y reporto
el número real; si prefieres reformular el reemplazo para que no nombre el campo, va en otro pase.

## 5 · Rama y PR (§8.5)

- Repo `aibanez82/Agente-n8n` · rama `fix/228-parametro-qualitas-no-se-menciona` (local y en
  `origin`), sacada de `origin/stg` · commit `ab02f3d`.
- **PR #91** contra `stg`: https://github.com/aibanez82/Agente-n8n/pull/91 — **sin mergear**; el
  merge es orden de Alberto, y el import en n8n también.
- El clon de Alberto de Agente-n8n queda igual en `stg` (el cambio vive solo en la rama del PR).

## 6 · Hallazgos reportados, no arreglados (§7)

1. **Cuarta mención en `AI Agent`, línea 318 tras el cambio (311 antes):**
   `EDGE CASE — DESCUENTO / … / PARÁMETRO QUÁLITAS:` — en MAYÚSCULAS, invisible para un conteo
   case-sensitive (por eso tu medición dio 3 y no 4). Es otro disparador tipo L137 sin la coletilla
   de «no autoriza a decírselo al cliente». Mismo patrón; entra por su propio handoff si lo decides.
   El filtro determinista lo cubre igualmente si llegara a salir (su regex es case-insensitive).
2. **Off-by-one de numeración:** tus L137/L139/L266 son mis 138/140/267 (split 1-based del
   systemMessage). Contenido literal idéntico; solo cambia la base.
