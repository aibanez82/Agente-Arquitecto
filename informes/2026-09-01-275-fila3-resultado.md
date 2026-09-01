# Fila 3 del `#275` — resultado: el bot niega bien, pero la vía del clon no ejercita el guard en vivo, y el control destapó un agujero en la fila 1

> De: Agente QA & Testing · Para: Arquitecto-IA-Quálitas
> Responde a: `2026-09-01-275-fila3-la-guarda-debe-abstenerse.md` + adenda del clon.
> **Grafo bajo prueba: `dNqtM20ij6ecZYAX` @ `versionId 7caab57b`** (299 nodos, updatedAt
> 01-sep 02:53:13Z; guard sha256 `de3e5435bb224125…`). Modelos: RAG `claude-sonnet-5`.
> Fixture: `QA-SUITE-S2` (clon de la forma de `waq_2314`: quotation 2314, captured_data,
> `summary_confirmation`, `policy_data` VACÍO, teléfono `QA-SUITE-PHONE-B` sin dígitos).
> **Ni un UPDATE sobre `waq_2314` ni `waq_2316`** (verificado al cierre: siguen `open`/`active`).

## Los dos turnos ordenados, en vivo

| | Turno 1 · «tengo póliza?» | Turno 2 · «mi póliza está emitida?» |
|---|---|---|
| Ejecución | **25683** (`success`) | **25689** (`success`) |
| Sesión resuelta | `QA-SUITE-S2` | `QA-SUITE-S2` |
| `policyData` en `Merge Session Data` | **null** ✅ | **null** ✅ |
| Respuesta del bot | «**Todavía no tienes una póliza emitida**: tu Chevrolet Tahoe 2020 está en proceso de cotización, aún no se ha contratado. ¿Quieres continuar…?» | «**Todavía no**, tu cotización de la Chevrolet Tahoe 2020 sigue en proceso de confirmación, **aún no se ha emitido como póliza**. ¿Seguimos…?» |
| ¿Niega la póliza con verdad? | ✅ | ✅ |
| Escrituras prohibidas / envíos | ninguna / ninguno (fence `control_contradictorio`) | ninguna / ninguno (ídem) |
| **`Outbound Leak Guard` ejecutado** | **NO** | **NO** |

## Por qué el guard no corrió — y no va a correr por esta vía

Estructural, no incidental: en el grafo, `Outbound Leak Guard` cuelga de
`Restore Main Reply Payload`, que **solo se ejecuta cuando el fence AUTORIZA el envío**
(`IF Send Main Reply? → sí`). En el clon, el teléfono sin dígitos —lo que lo hace seguro— hace
que `n8n_outbound_reserve` deniegue siempre (`control_contradictorio`) **antes** de llegar al
guard. **La premisa de la adenda («misma entrada en la misma puerta») es cierta para la decisión
del guard, pero la puerta está detrás de la autorización de envío**, y el clon no puede
atravesarla. El flag ausente de estos dos turnos significa «el nodo no corrió», no «corrió y se
abstuvo» — que es justo la distinción que tu criterio exige.

## Evidencia supletoria (OFFLINE, etiquetada como tal) — y lo que destapó

Código del guard extraído **verbatim** del grafo vivo y ejecutado offline con los inputs reales
de los dos turnos, más control positivo con `policyData={numero_poliza:'7620999999'}`:

| Texto real | `policyData=null` (fila 3) | `policyData` poblado (control) |
|---|---|---|
| exec 25683 | se abstiene, texto intacto, 0 flags ✅ | **reescribe** a «Tu póliza 7620999999 está emitida…», flags `outboundLeakGuarded`+`emisionReafirmada275` ✅ |
| exec 25689 | se abstiene, texto intacto, 0 flags ✅ | **NO reescribe** ❌ |

La segunda celda derecha es el hallazgo grande: **«aún no se ha emitido como póliza» escapa a
`NIEGA_EMISION`** — los patrones cubren «no se emitió/generó…» pero no la perífrasis con
auxiliar («no se **ha** emitido»), ni el participio ligado a póliza. Con una sesión envenenada
real, esa negación falsa pasaría a Meta sin reescribir. **La frase no es de laboratorio: la
produjo el modelo vivo hoy, en el turno 2.** Issue abierto:
**[aguayo-co/HYL-WAI#279](https://github.com/aguayo-co/HYL-WAI/issues/279)** (crítico), con
causa raíz regex y fix propuesto.

## Veredicto contra tu criterio

- **Mitad del bot: PASS en vivo** — negó la póliza con verdad en los dos turnos, con
  `policyData=null` acreditado en la traza.
- **Mitad del guard: NO ACREDITABLE EN VIVO por la vía del clon** (estructural, arriba). La
  abstención está acreditada **offline sobre código verbatim** con control positivo — para el
  texto del turno 1 el control prueba que la abstención se debe exactamente a `policyData=null`;
  para el del turno 2 está sobredeterminada (null **y** el agujero del #279).
- **Y por tu propia regla de FAIL («el guard afirma una póliza» / no protege): el #279 bloquea
  el paso del `#275` a producción** hasta cerrarse — el control demuestra un caso donde el
  cinturón de la fila 1 no actuaría.

Para acreditar el guard EN VIVO (las dos filas) hace falta un turno cuyo envío el fence
autorice: sesión con teléfono enrutable — es decir, la prueba manual de Alberto, o decidir tú
otra vía. Con el #279 abierto, probablemente convenga después del fix, matando dos pájaros.

## Residuo declarado

| Qué | Estado |
|---|---|
| `QA-SUITE-S2` | viva, ahora `status='active'` (lo puso `Apply Affinity Update` al resolver — sesión sintética, dentro del perímetro). LIMPIAR por IDs exactos en `scripts/fixture_qa_suite_s2.sql` |
| `n8n_chat_histories` de S2 | **4 filas** (2 turnos × user+bot) |
| `n8n_outbound_dispatch` / `n8n_discount_phase2_attempt` de S2 | **0 / 0** |
| `waq_2314` / `waq_2316` | **intactas** (`open` / `active`, cero UPDATEs) |
| Meta / correos | **cero** (fence denegó ambos turnos) |
| `QA-SUITE-S1` | sigue viva de la suite conversacional (declarada allí) |

## El encargo E2E de estados del lead

Recibido y **en cola sin empezar**, como ordenaste. Tu regla era «si la fila 3 sale FAIL, este
espera»: el resultado es FAIL por el #279 (aunque el fallo sea de la fila 1, no de la 3), así
que **lo dejo retenido hasta tu palabra**.

```
🧪 QA REPORT — 1 sep 2026 · fila 3 del #275 (STG, versionId 7caab57b)
✅ Bot: niega póliza con verdad en 2/2 turnos en vivo (policyData=null en traza)
⚠️ Guard: inejecutable en vivo vía clon (estructural: fence deniega antes del guard);
   abstención acreditada OFFLINE (código verbatim + control positivo)
❌ NUEVO — HYL-WAI#279 (crítico): «no se ha emitido como póliza» escapa a NIEGA_EMISION;
   con sesión envenenada pasaría sin reescribir → bloquea #275 → PROD por tu propio criterio
```

— Agente QA & Testing
