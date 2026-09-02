# Informe `#297` — la red (c) acreditada SOBRE EL EJEMPLAR: la sesión clavada contestó

**De:** Agente n8n · **Para:** Arquitecto · 2 sep 2026 · Handoff `bd278ea` + tus dos SÍes (ancla por
condición; flip de acreditación).

## 1 · La red (STG `823cacef`, 310→316 nodos, 13/13)

Por agente: error → `Repair Window` (UNA sentencia: predicado ¿fila 120-desde-el-final = `tool`? +
INSERT condicional de la fila inerte; `onError` fail-open al fallback) → `Restore Retry` (item
original desde la rama de error, `$('X').all(1)`) → `IF Repaired?` → reintento o el fallback de
siempre. **Cero parámetros de nodos previos tocados** (verificado por ti también). La nota de la
guarda 3 vive en el SQL del nodo: el 400 es PRE-TOOL, la seguridad del reintento viene del SITIO.
Fila inerte DEL CORPUS REAL («Aquí estoy cuando quieras retomar 🙂», dicha por el bot hoy) con
`source='window_repair_297'` contable.

## 2 · La acreditación, medida en el caso real (con tu flip, conteos y reversión)

| paso | medido |
|---|---|
| flips (con tu SÍ) | 2300 active→open, 2316 open→active; ejemplar en 123 filas |
| **gasto del ejemplar** — «sigo pensando, ¿me esperas?» (NO-de-póliza, para rutar al agente y no al carril del `#275f`) | **exec 28395, UNA ejecución**: `AI Agent` run0 muere en el 400 → `Repair Window` `{huerfano: true, repair_id: 6319}` → `Restore` → `IF` → **run1 CONTESTA**: «Claro que sí, tómate tu tiempo. Solo te recuerdo: tu cotización con Quálitas hoy tiene precio preferencial… (MSI)…» — **la sesión que llevaba horas muda, respondida en el mismo turno** |
| **tu condición 2** — «una duda: ¿puedo pagar con tarjeta de débito?» | exec 28397: **Repair NO corrió** (la condición se apagó sola — la garantía estructural, en acto), un solo run de agente, respuesta normal y útil: «Sí, José, puedes pagar con tarjeta de débito VISA, MasterCard o American Express.» — **ni una palabra sobre la fila inerte** |
| conteos finales | 130 filas (el gasto ordenado), **exactamente 1** con `source=window_repair_297` |
| reversión | 2300 `active`, 2316 `open` — como los encontré |

**El desbrickeo con número (tu §3):** sesiones clavadas en STG antes de la red: **1** (el ejemplar).
Después de su primer inbound: **0**. La reparación es 1 fila por sesión minada (racha `tool` máx = 1,
medido en ambos entornos), y cada una queda contada en la metadata.

## 3 · Qué queda

- El ejemplar está gastado **y salvado**: las 123 filas íntegras con la constancia del borde viven en
  `evidencia/297/waq_2316_ejemplar_123_filas.json` (commit en `stg` ANTES del gasto).
- **La (a)** — dejar de escribir trazas — sigue pendiente como propuesta para Juan (trigger BD +
  `tool_calls` fuera JUNTOS, o huérfano inverso), con el contador de reparaciones como termómetro:
  si `window_repair_297` crece, pasa de higiene a urgencia.
- PROD del `#297`: cuando lo ordenes. Ahora sigo con el viaje del `#299` a PROD (1d892de) y la
  medición de alcanzabilidad de los 44 que pediste antes del guion de Alberto.

— Agente n8n
