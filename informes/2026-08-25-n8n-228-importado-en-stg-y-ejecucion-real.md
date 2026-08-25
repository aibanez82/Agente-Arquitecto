# Informe — `#228` importado en STG, ejecución real limpia, PROD intacto. Y un hallazgo que degrada la premisa del filtro.

**De:** Agente n8n · **Para:** Arquitecto-IA-Quálitas · **Fecha:** 2026-08-25 (UTC)
**Handoff:** `2026-08-25-import-228-solo-stg.md` · **Issue:** `aguayo-co/HYL-WAI#228`

> Nota de secuencia: Alberto ordenó el import en sesión directa antes de que el handoff aterrizara;
> el handoff llegó con el import ya hecho. Todo lo que exige quedó cumplido igualmente, y lo que
> faltaba (copia pre-import en rama, lectura de PROD, ejecución real) se hizo al recibirlo.

## §6.1 · Antes y después, con código HTTP

| Lectura | HTTP | versionId | active | nodos |
|---|---|---|---|---|
| STG antes del import | 200 | `4fe4c3ee-5bea-4666-85f5-6956eddebaad` | true | 232 |
| STG después del import | 200 | `a0e2595c-2a79-4e95-96fc-17c28f20f44d` | true | 232 |
| **PROD (confirmación §6.4)** | 200 | **`8c43fdd0-fd0b-4392-aab4-11ca188f3ccc` — intacto, no tocado** | true | 229 |

Copia del grafo vivo pre-import, para revertir: rama `backup/2026-08-25-stg-pre-228-import`
(`backups/2026-08-25-stg-bot-pre-228-import.json`), pusheada a origin.

## §6.2 · Tabla de §3

| # | Comprobación | Resultado |
|---|---|---|
| 1 | `versionId` distinto | ✅ `4fe4c3ee…` → `a0e2595c…` |
| 2 | Nodos (contados sobre `nodes` parseado, gotcha 36) | ✅ 232 |
| 3 | `active` | ✅ true antes y después |
| 4 | `AI Agent` contiene `NO EXISTE para el cliente` | ✅ |
| 5 | `AI Agent` contiene `MARCA DE MEDICIÓN` y `NI NINGUNA VARIANTE` | ✅ |
| 6 | `RAG IA Agent` contiene `NO EXISTE para el cliente` | ✅ |
| 7 | `Filter System Leaks` contiene `paramRe` | ✅ (bloque 2.b tras `// 2. Remove policy IDs`) |
| 8 | Disparador `Get Quotation Data` vivo en los dos agentes | ✅ — conteo ≠ 0 |

Extra: `webhookId` de los 10 nodos con webhook idénticos pre/post; `settings` campo a campo
(`errorWorkflow`, `timezone`, `executionOrder`); `binaryMode` conservado por el merge del PUT (gotcha 37).

## §6.3 · Ejecución real

**Precondición verificada antes de lanzar:** la sesión activa del número de prueba
(`525551074144`) apunta a la cotización **2207**, y `/api/cotizacion/detalle/` de Django STG
devuelve `discount_context.current.qualitas_parameter = {value: 30}` — el mismo «30» de las
capturas. La ejecución ejercita el campo.

- Sonda: `scripts/probe-228-parametro-qualitas-stg.py` (rama `fix/228-sonda-e2e-stg`, PR #92,
  sin mergear) — webhook firmado, patrón de probe-197, entrada literal `se puede mas descuento?`.
- **Ejecución `16142`** de `dNqtM20ij6ecZYAX`, `success`, 18:19:55–18:20:07Z, 72 nodos, con
  `Get Quotation Data` ejecutado y WhatsApp real aceptado por Meta (wamid devuelto).

**Texto saliente literal** (idéntico byte a byte en `RAG IA Agent` → `Stash/Restore Main Reply
Payload` → `Send message`):

> Por el momento no puedo acreditar una comparación de ahorro porque aún no eliges un paquete y forma de pago. Tu cotización ya está al mejor precio disponible. ¿Quieres que revisemos juntos una forma de pago para avanzar? 😊

- Término (búsqueda `/i`): **ausente**. Y no por redacción del filtro: el modelo ya no lo intentó
  — `curado en este turno, no solo tapado`.
- Mutilación: ninguna — el texto enviado es el del agente íntegro. (Sin cifras de pago porque
  `commercial_comparison.available=false` por `selection_missing`: no había cifras que conservar,
  y la respuesta es exactamente la conducta que prescribe la regla nueva para ese caso.)

## HALLAZGO NUEVO — la premisa de §5 del handoff original es falsa para el carril RAG

Tu §5 decía: `AI Agent / RAG IA Agent → … → Filter System Leaks → … → Send message`. **Medido
sobre el grafo (BFS sobre `connections`) y confirmado por la ejecución real:**

- Carril `AI Agent` → … → `Authority Lost?` → `Sanitize Output PII` → … → `Filter System Leaks` ✅
- Carril `RAG IA Agent` → `Detect Failed Tool Call1` → `Increment KB Counter` → … →
  `Format KB Response` → `Phase Extractor1` → `Stash Main Reply Payload` → … → `Send message` —
  **`Filter System Leaks` es INALCANZABLE desde este carril** (BFS: False).
- La ejecución `16142` salió por ese carril: 72 nodos y el filtro no corrió.

Es decir: **hoy el silencio del carril RAG descansa solo en el prompt** (que en esta sonda
obedeció). La garantía determinista cubre el carril del `AI Agent`, no el del RAG/KB. No lo he
tocado (§5: no ampliar alcance); queda con los otros dos hallazgos abiertos de tu adenda
(el `EDGE CASE` en mayúsculas y la descripción de la tool). Los tres apuntan al mismo cierre:
o el filtro se muda a la confluencia (`Stash/Restore Main Reply Payload`, por donde pasa TODO
lo que sale), o se replica en el carril KB.

## §6.5 · Export de sincronización

El mecanismo (`sync-workflow-export.py stg … --go`) no vio diferencias semánticas: el export
`workflows/WhatsApp Insurance Quotation Bot_stg.json` de `origin/stg` (merge `ecd569c`) ya es el
estado vivo. Sin commit nuevo. Ramas nuevas: `backup/2026-08-25-stg-pre-228-import` y
`fix/228-sonda-e2e-stg` (PR #92, sin mergear).

**PROD sigue apagado, como ordena Alberto: nada importado, versionId confirmado intacto por lectura.**
