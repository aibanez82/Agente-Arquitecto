# Suite conversacional STG — primera corrida sobre la cotización dedicada 2307

> De: Agente QA & Testing · Para: Arquitecto-IA-Quálitas
> Encargo: `2026-08-31-suite-conversacional-stg.md` §2.b · GO: `2026-08-31-GO-fixture-sesiones-sinteticas.md`
> Reporte máquina: `Agente_QATest_Qualitas/reports/20260831-1634/conversacional-stg.json`
>
> **Corrida ejecutada sobre workflow `versionId ec9d73c2`** (298 nodos, updatedAt 31-ago 22:23:23Z).
> El grafo cambió DESPUÉS de la corrida a `97a8cca5` (fix del carril de descuentos); ese estado
> posterior NO está medido aquí — estampo lo que corrí, no lo que existe ahora.
> **Modelos bajo prueba** (leídos del workflow vivo en el arranque): agente principal
> `claude-sonnet-5` · RAG `claude-sonnet-5` · clasificador descuentos `claude-sonnet-5` ·
> router/jailbreak `claude-haiku-4-5`.

---

## Lo más importante primero

**La corrida destapó un crítico vivo: [qualitas-issues#88](https://github.com/aibanez82/qualitas-issues/issues/88).**
Desde el cambio de modelos de las 22:02Z, **todo turno enrutado al agente conversacional principal
(intent `contracting`) muere con 400 de la API de Anthropic** — el nodo `Anthropic Chat Model`
conserva `options: {"maxTokensToSample":2000,"temperature":0.7}` y `claude-sonnet-5` rechaza
`temperature` (error literal en runData: «\`temperature\` is deprecated for this model»). El RAG y el
clasificador, mismo modelo con `options: {}`, funcionan. Invisible desde arriba: la ejecución acaba
`success` porque `onError=continueErrorOutput` absorbe el error, y el cliente recibe el fallback
genérico. **Cualquier validación del carril principal en STG posterior a las 22:02Z midió el
fallback, no el bot.**

## Resultados por caso

| Caso | Mensaje | Resultado | Qué pasó |
|---|---|---|---|
| QA-CONV-001 | `y si son las mismas condiciones? cubre lo mismo?` | ✅ **PASS** | RAG (exec 25349): «Un descuento no cambia lo que cubre cada paquete: las condiciones y coberturas de tu póliza se mantienen exactamente igual, solo se recalcula el precio…» — checks duros OK, sin afirmar equivalencia Amplia/Limitada |
| QA-CONV-002 | `en cobertura limitada también tienes descuento?` | ⚠️ FAIL **de mi suite, no del bot** (corregido) | RAG (exec 25350): «No tengo un dato fresco de descuento para tu cotización… Sí te puedo dar el precio vigente de Limitada: anual $7,718.70 o semestral con primer pago de $4,459.17». Mi conjunto de cifras válidas solo tenía primas ANUALES; 4459.17 es real (`xml_limitada_semestral`, 8025.15 = 4459.17 + 3565.98). Fix aplicado: entran los `PrimaTotal` de las 6 columnas XML de la cadena. **Nota**: la respuesta es veraz para la 2307, que aún no tiene descuento — la expectativa del handoff («sí, re-cotiza todo») presupone descuento ya aplicado, como en la 2302. El caso queda condicionado al estado de la cotización |
| QA-CONV-003 | `¿qué cubre la limitada?` | ❌ **FAIL de contenido, real** | RAG (exec 25351) listó lo que la Limitada incluye (RC, gastos médicos, asistencia vial/legal, robo total) pero **no dijo lo que NO cubre** — tu criterio del handoff era explícito: «explicación real, incluido lo que no cubre». Respuesta completa en el reporte máquina |
| QA-CONV-004 | `¿cuánto ahorro con el descuento?` | ❌ **BLOQUEADO por #88** | Intent `contracting` → agente principal → 400 (exec 25353). El fallback que habría llegado a un cliente real fue denegado por el fencing (`Agent Error Fallback Fence Denied`) al ser la sesión sintética. Re-ejecutar tras el fix de #88 |

## El aislamiento funcionó — en el camino feliz y en el de error

- **Cero nodos de envío en las 4 trazas** (contrato verificado nodo a nodo, incluida la guarda
  nueva `Send Remite Reply` que entró con `ec9d73c2`).
- En el turno con error de agente (25353), la salida degradada TAMBIÉN quedó silenciada por el
  fencing (`n8n_outbound_reserve` → denied): el aislamiento aguanta el caso que no diseñamos.
- El runner ahora **se niega a correr** si el grafo vivo trae nodos de envío que sus listas no
  conocen (envejecimiento ruidoso del contrato, no silencioso).

## Sobre tu aviso del carril de descuentos (fix `97a8cca5`)

Tu aviso llegó con mi corrida ya lanzada (sobre `ec9d73c2`). Dato que te sirve: **mi caso 2 entró
al carril de fase 2 y se detuvo en `IF Classify Discount?` → `Discount Reply Terminal`** — el claim
de fase 2 se negó (0 filas en `n8n_discount_phase2_attempt` para mi sesión; coherente con la sesión
sintética en `contradiction`). **Nunca llegó a `Check Live Discount`**, así que mi corrida ni sufrió
el bug de `$2` ni acredita tu fix. Freno aplicado: los casos con intención de descuento quedan en
SKIP en el runner hasta tu confirmación con turno real (`QA_SUITE_RUN_DISCOUNT=1` para levantar).

## Residuo declarado (condición 3 del GO)

| Qué | Estado |
|---|---|
| `whatsapp_sessions` | `QA-SUITE-S1` **viva a propósito** (re-corridas pendientes: #88 y descuentos). Borrado por IDs exactos en `scripts/fixture_qa_suite.sql` sección LIMPIAR al cerrar la suite |
| `n8n_chat_histories` de `QA-SUITE-S1` | 0 → **10 filas** (memoria conversacional de los 4 turnos; se borra con la sesión) |
| `n8n_outbound_dispatch` | **0 filas** (todo denegado antes de reservar) |
| `n8n_discount_phase2_attempt` | **0 filas** |
| Meta / correos / destinatarios externos | **cero** |
| Ejecuciones n8n | 25349, 25350, 25351, 25353 (la 25352 es del poller programado, no mía) |

Escrituras del bot como consecuencia de la inyección (historial, `Update Phase in DB` sobre la
sesión sintética): dentro del perímetro `QA-SUITE-` del GO.

## Qué hace falta para cerrar el punto (b)

1. **Fix de #88** (Agente n8n) → re-correr QA-CONV-004 y validar el carril principal.
2. **Tu confirmación en vivo del carril de descuentos** (`97a8cca5`) → levantar el freno y correr
   QA-CONV-002/004 con intención de descuento real sobre la 2307 (las escrituras del carril sobre
   la dedicada se declaran por turno, según lo acordado).
3. Decidir si el FAIL de contenido de QA-CONV-003 va a issue o a ajuste de prompt/KB — es
   exactamente la clase de hueco que el handoff quería cazar, pero la redacción del criterio es
   tuya y no lo abro sin tu lectura.

```
🧪 QA REPORT — 31 ago 2026, 16:45 MX
Triggered by: suite conversacional STG — primera corrida (handoff 31-ago + GO fixture)
Workflow: dNqtM20ij6ecZYAX @ ec9d73c2 · Modelos: principal/RAG/clasificador=sonnet-5, router=haiku-4.5

✅ PASS  1  (QA-CONV-001)
❌ FAIL  2  (QA-CONV-003 contenido real · QA-CONV-004 bloqueado por #88)
⚠️ WARN  1  (residuo declarado; QA-CONV-002 reclasificado: bug de suite, corregido)

FALLOS:
❌ [n8n STG] agente principal 400 en todo turno contracting desde 22:02Z
   Query/Check: exec 25353, runData del nodo Anthropic Chat Model
   Resultado: NodeApiError «temperature is deprecated for this model» · Esperado: respuesta del agente
   Issue: qualitas-issues#88 (crítico)
❌ [bot STG] «¿qué cubre la limitada?» sin mencionar exclusiones
   Query/Check: exec 25351, respuesta verbatim en reports/20260831-1634
   Resultado: solo inclusiones · Esperado: «explicación real, incluido lo que NO cubre»

SISTEMAS SIN CAMBIOS:
✅ cero Meta real · ✅ cero dispatch · ✅ workflows/config sin tocar · ✅ residuo solo QA-SUITE-
```

— Agente QA & Testing
