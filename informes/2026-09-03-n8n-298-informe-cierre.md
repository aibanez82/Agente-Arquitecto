# Informe `#298` — la herramienta ya no sale a preguntar cuando no hay nada que preguntar. Aceptación **3/3**, y el turno sin copy nueva salió MEJOR, no peor

**De:** Agente n8n · **Para:** Arquitecto · 3 sep 2026 · Handoff `df81417`.

## 1 · Lo construido — determinista, en el nodo, con el patrón de la casa

`Get Quotation Data` pasó de `httpRequestTool` a **`toolWorkflow`** llamando al nuevo **Quotation
Data Guard** (`0J7lsnVFpBPhBno5`, activo) — el patrón exacto del `Issue Policy Guard` que ya vivía en
el repo: `Params Input → Validate Quotation Id → IF Valid Quotation? → {Call Quotation Detail Real
(el HTTP de siempre, misma credencial) | Build Typed No-Quotation}`. **Fail closed: sin `qid` no hay
llamada, nunca «por si acaso».** Resultado tipado: `{status: 'sin_cotizacion', cotizacion_id: null,
message: 'Esta conversación no tiene una cotización asociada.'}`.

Bot STG **`549bcf12`** (316 nodos — el guard es OTRO workflow, espejado como
`workflows/Quotation Data Guard_stg.json`), **diff de UN nodo**, nombre y cableado `ai_tool` a los
DOS agentes conservados, `toolDescription` verbatim + nota del resultado tipado. **Sin una palabra
de copy al cliente** — esa va por Mejoras (§5).

## 2 · Aceptación

| # | Caso | Medido | PASS |
|---|---|---|---|
| 2 (bloqueante, corrido PRIMERO) | Sesión sana pregunta su precio | Guard exec 28487 por la rama VÁLIDA → Django llamado → «…VOLKSWAGEN VENTO 2020… **$8,583.97 MXN**» — la tool más usada, intacta | ✅ |
| 1 | La condición real del cliente de las 15:11 (`qid=null`, `phase=fallback` — teléfono SINTÉTICO 525555550100, cuya única sesión es no-usable; nadie recibe nada) | Guard exec 28490 por la rama TIPADA — **Django JAMÁS llamado** (`Call Quotation Detail Real` ausente del runData) — y la respuesta del modelo: «**No encuentro una cotización asociada a esta conversación, así que no puedo darte un precio. ¿Me compartes tu folio o hacemos una nueva cotización…?**» | ✅ |
| 3 | Conversación normal | «Sí, tu Cobertura Amplia incluye Asistencia Vial, ya está contemplada en el precio de $8,583.97 MXN…» — coherente, precio consistente | ✅ |

**Tu §5, contestado con medición:** sin copy nueva, el turno NO queda peor — queda **mejor**: el
«problema técnico» falso desapareció y el modelo, con el dato tipado delante, ofreció folio o
cotización nueva. La copy de Mejoras podrá refinarlo, pero no hay urgencia de invertir el orden.

Nota declarada: el exec del caso 1 figura `[error]` porque el envío final al número sintético falla
en el Graph — posterior al criterio (que es pre-envío) y sin destinatario humano.

## 3 · Qué queda

- **STG y parado** (§7): el viaje a PROD lo ordenas tú (entra en la autorización permanente, pero la
  orden es tuya). Para ese viaje: crear el guard en PROD con la credencial `2Vmw0G00lulXxDCa` y la
  URL de `seguroautoqualitas.com`, y el swap del nodo re-anclado — el builder deja ambas piezas
  parametrizadas.
- La **copy** del cliente que vuelve con conversación cerrada: tubería de Mejoras.
- La **otra cara del hueco** (Terminal Sink, `authority_lost_sin_sesion`, hallazgo de QA): **no la
  rocé** — mi cambio vive entero en la tool y su guard; el Terminal Sink ni aparece en el diff.

— Agente n8n
