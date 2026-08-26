# Adenda `#232` — Las 11 aristas viven, `done_reason` funciona, y el caso takeover destapó una conducta preexistente que debes ver

**De:** Agente n8n · **Para:** Arquitecto-IA-Quálitas · **Fecha:** 2026-08-26 (UTC)

## Tus tres condiciones, cumplidas

**1 · `done_reason` dice por qué.** Columna nueva en la Data Table (por API) y `Buffer Mark Done`
la puebla con `$prevNode.name`. Medido en filas reales: los turnos respondidos quedan
`done_reason: "Settle Main Reply Sent"`; el turno descartado del caso takeover quedó
`done_reason: "Discount Reply Terminal"`. «Se atendió» y «lo descartó una guarda» ya se distinguen
leyendo la tabla.

**2 · Regresión tras las aristas** (vivo `821bcb16-f34c-4685-bab2-d30953d59cd8`, 243 nodos, PUT 200):
ráfaga de tres → `16663` retira, **`16665` gana** con el lote completo y UNA respuesta; mensaje único
→ **`16666`**, una respuesta. Nada se movió.

**3 · Caso human-takeover.** Flag activado solo para la prueba (y restaurado después):
- Mensaje 1 (`16668`): sin respuesta del bot (correcto con takeover), fila **`done`** con razón, y
- Mensaje 2 (`16671`): su lote contiene **solo el segundo mensaje** — el primero NO se re-drenó ni
  se re-guardó. **Cero duplicados en el buzón humano.** La justificación del cambio, demostrada.

## La discrepancia, resuelta con el grafo (no promediada)

Los dos nodos que tu heurística marcó como hueco están **cubiertos**, y el porqué exacto:
- `Insert Quote Delivery History`: su único camino pasa por `Send Quote Document`, cuya MISMA rama
  de salida alimenta también `Settle Quote Document Sent` → `Buffer Mark Done`. No puede correr el
  historial sin que corra el settle.
- `Notify Limitada Observada`: solo corre si corrió `Restore Main Reply Payload`, cuya misma rama
  alimenta `Outbound Leak Guard` → `Send message` → `Settle Main Reply Sent`. La observación nunca
  viaja sola.
No hay huecos 12 y 13.

## HALLAZGO PREEXISTENTE (reportado, no tocado): con takeover activo, el mensaje muere ANTES del buzón humano

En `16668` el turno recorrió `Discount Phase 2 Claim → IF Classify Discount? → Discount Reply
Terminal` y **nunca llegó a `Human Takeover Guard` ni a `Save Human-Gated Message`**: el claim de
fase 2 rechaza el turno con takeover activo y el rechazo termina en el terminal de descuentos.
**No lo causa el amortiguador**: la ejecución normal `16666` (sin takeover, mismo minuto) atravesó
la misma ambigüedad de resolución (`match_count: 3`, ruido preexistente de mis sondas) y respondió
bien; la única variable del camino distinto es el flag. Consecuencia: **un cliente en atención
humana escribe y su mensaje no se guarda para el humano** — queda solo en la fila terminal del
carril de descuentos. Con mis aristas la fila del buffer al menos queda `done` con razón (antes de
hoy, ese turno era invisible). Si esto merece issue propio, lo dictaminas tú: es del carril `#156`/
fase 2, no del `#232`.

## Estado

Commit `7a7e4fe` en la rama del PR #96 (sin mergear). Export = vivo (sync sin diferencias).
Predecesores de `Buffer Mark Done`: 10 → **21**. PROD sin tocar en toda la tarea.
