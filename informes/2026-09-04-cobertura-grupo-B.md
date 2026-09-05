# Preguntas de cobertura, grupo B — 17×2 ejercitadas; cola Limitada apagada por créditos

> De: Agente QA & Testing · Para: Arquitecto-IA-Quálitas
> Set de Mejoras (grupo B, 19 frases ×2). Grafo `ec5052cf` · RAG/agente `claude-sonnet-5`.
> KB verificada por mí ANTES de correr: chunks 36/37 corregidos (updated_at 02:20-02:21Z) — los
> esperados de B1/B3-Lim se escribieron ya alineados con las CG.
> 43 turnos gastados, primer plano por bloques. Fixture: 41 clones + reuso (GO 31-ago).

## ⚠️ ALERTA OPERATIVA PRIMERO — STG SIN CRÉDITOS ANTHROPIC

**Ventana medida, no estimada (corrección del Arquitecto, tenía razón):** última ejecución
BUENA = exec 31761, terminada 02:41:59Z; primera FALLIDA = exec 31763, iniciada **02:42:43Z**.
El corte empezó en esos 44 segundos — mi «~02:35Z» inicial era estimación y estaba mal. Desde
entonces todo turno muere en `Detect Jailbreak` con **«Your credit balance is too low to access
the Anthropic API»** (verbatim de la exec 31776; igual en 31763-31774). No es cosa
de mis sesiones sintéticas: es el primer nodo LLM del grafo — **el bot de STG está caído para
cualquier conversación** hasta recargar créditos. Los 7 últimos turnos de esta corrida (la cola
Limitada entera) murieron ahí: **B1×2, B2×2, B3-Lim×2 y el turno de contexto quedan SIN MEDIR.**
(El error de A2 de ayer-tarde, exec 31344, fue OTRA cosa: un 503 transitorio a las 21:29Z.)

## Dos hallazgos de método antes de la tabla

1. **`Save Quotation Selection` NO dispara por texto libre en sesiones sintéticas**: dos turnos
   («quiero la limitada» → «la limitada de contado», execs 31758/31761, respuestas correctas con
   los precios exactos de la Limitada) y `qualitas_cotizacion.2307.paquete` sigue vacío. La
   selección probablemente exige quick-reply. Consecuencia: la precondición «Limitada elegida»
   se construyó CONVERSACIONALMENTE (sesión con la Limitada citada) — y luego el apagón la mató.
   **Corrección de mi residuo declarado: la 2307 NO quedó con Limitada elegida** (mejor de lo
   anunciado: sigue virgen de selección).
2. **La KB de STG no tiene los topes de Asistencia Vial** (cero chunks con «80 km», «ponchadura»,
   «5 eventos»). Tu advertencia 3 aplicada: en B8/B9/B10 la OMISIÓN de topes no es fallo del bot;
   la AFIRMACIÓN de ilimitado sí lo es.

## Resultado de las 34 ejercitadas: 26 PASS · 4 FAIL-293 · 1 FAIL-271 (par) · 1 no exigible · 2 REGISTRAR

**Los fallos, cada uno con su exec:**

| Caso | Veredicto | Evidencia |
|---|---|---|
| B8a | **FAIL-293** | AV «disponible **las veces que lo necesites**» (exec 31715) — ilimitado sin fuente; la CG dice 5 eventos/año, tope $200, 80 km |
| B10a | **FAIL-293** | mismo «las veces que lo necesites» (exec 31718) |
| B16a | **FAIL-293** | describe la Extensión de RC como «suma asegurada mayor a la básica» (exec 31726) — ese es RC en exceso, no la Extensión al Titular (CG 8.1) |
| B16a↔B16b | **FAIL-271 de libro** | B16b la describe BIEN (conducir otro vehículo similar, exec 31750). Dos conceptos distintos a la misma frase — el caso más limpio de inestabilidad del set |
| B18a | **FAIL-293** | añade «cuente con licencia vigente» como condición (exec 31728) — C4 del propio set acredita que esa condición no está en KB ni CG localizada. B18b (31753) contesta sin inventarla |
| B8b | **NO EXIGIBLE** | lista servicios sin topes (exec 31740) — el chunk de topes no existe en STG (hueco de KB, no fallo del bot) |
| B11a/b | **REGISTRAR** | EUA/Canadá: DM/RT/GM/EE sí, «RC solo México» + «debe estar contratado expresamente» (31719/31744) — coherente con CG 9ª; anotado sin dictamen (Hylant pendiente) |

**Los 26 PASS incluyen varios que eran trampas caras y las superó:**
- B6×2: Robo Total **sin** el falso límite «2 eventos/$5.000» (la trampa del set evitada).
- B15×2: el 3.5 t razonado por categoría del OTRO vehículo, no por el peso del Ioniq (la trampa del caso PROD, evitada dos veces).
- B19×2: la Amplia SIN «Equipo Especial» (el fallo PROD de `526861706122`, no reproducido).
- B3×2: inundación y desbielamiento cubiertos, citando fenómenos naturales.

**Observaciones sin veredicto (para Mejoras):** B6b repite el patrón «valor convenido» del grupo A
(exec 31736 — el patrón cruza de grupo); B13×2 atribuye al CADE lo que la condonación de la CG 1.2
da de serie (omisión tolerada por el set, matiz de copy); B4b omite la mitad RC (daños al animal
de tercero); B9×2 sin el tope de 80 km (hueco KB, no exigible).

## Turnos y residuo (declarados)

43 turnos: 34 medidos + 2 de selección + 7 muertos por el apagón. Ningún limitador del banco
mordió (1-5 turnos/sesión, lejos de los topes). Cero envíos y cero nodos de emisión en todas las
trazas. Residuo vivo: 41 sesiones `QA-SUITE-COB-B*` + 4 `QA-SUITE-MSI-*` + las 14 del grupo A,
con sus chat_histories; limpieza única por IDs exactos al cerrar el set (LIMPIAR ya escrito en
`scripts/fixture_qa_cob*.sql`). La 2307 sin selección persistida.

## Qué falta del set

- **Cola Limitada (B1×2, B2×2, B3-Lim×2): lista para correr en cuanto haya créditos** — fixture y
  contexto reconstruibles en dos turnos.
- **Grupos C y D**: a tu palabra.
- A11 sigue no ejercitable (fence).

```
🧪 QA REPORT — 4 sep 2026 (noche) · cobertura grupo B (STG, 2307, ec5052cf)
🔴 STG SIN CRÉDITOS ANTHROPIC desde ~02:35Z — bot caído para TODA conversación (exec 31776 verbatim)
✅ 26/34 PASS — trampas B6 (2 eventos), B15 (3.5t), B19 (Equipo Especial) superadas ×2
❌ 4 FAIL-293: ilimitado en AV (B8a, B10a) · Extensión RC mal descrita (B16a) · condición «licencia
   vigente» inventada (B18a)
❌ 1 FAIL-271 de libro: B16a↔B16b, dos conceptos distintos a la misma frase
⚠️ 2 REGISTRAR (B11 EUA) · 1 no exigible (B8b, hueco KB topes AV en STG) · patrón «valor convenido»
   cruza al grupo B (B6b)
⛔ 6 turnos Limitada sin medir (apagón) · Save Quotation Selection no dispara por texto libre
```

— Agente QA & Testing

---

## Adenda — Cola Limitada + B8/B10 remedidos tras la recarga y el `#330` (5-sep, corridas `20260905-COB-B-*`)

Grafo `f1d9aedb` (el del `#328`), KB alineada verificada antes de correr. 11 turnos, primer plano.

**Cola Limitada: 7/7 PASS, y la KB corregida hizo exactamente su trabajo.**

| Caso | Ambas reps | Evidencia |
|---|---|---|
| B1 ×2 | **PASS** | «no cubre choques/vuelcos, cristales, vandalismo, animales… inundación SÍ queda cubierta a través de Robo Total, incluyendo desbielamiento» (execs 31817/31822) — la CG y el chunk 36 corregido, literal. **El REGISTRAR previsto (si negaba incendio/inundación) no hizo falta** |
| B2 ×2 | **PASS** | «no cubre choques ni vuelcos; eso es Daños Materiales (Amplia)» (31818/31824), consistente |
| B3-Lim ×2 | **PASS** | inundación cubierta vía Robo Total con desbielamiento (31820/31825); no citan el deducible de RT — omisión menor sin invento |

(El turno de contexto CTX2, exec 31821, respondió además con la respuesta completa de B1 — el contexto conversacional bastó como precondición.)

**B8/B10 remedidos con la fuente ya presente (`#330`): la escalada a `#292` puro NO se materializó.**

| Caso | Veredicto | Evidencia |
|---|---|---|
| B8r1 | **PASS** | «hasta 5 eventos al año cada uno, dentro de 80 km» (31826) — los topes aparecen |
| B8r2 | **PASS completo** | «5 eventos al año… 80 km… tope de $200 MXN por evento» (31828) — el chunk nuevo, usado entero |
| B10r1 | PASS con observación | GL completo; AV en lista sin topes, sin afirmar ilimitado (31829) |
| B10r2 | **PASS** | «disponible las 24 horas» (31830) — verificado: «24 horas» consta en 2 chunks de las CG (`doc_chunks`); no es cifra inventada. **«Las veces que lo necesites» desapareció en las 4 remediciones** |

Residuo acumulado actualizado: + 4 sesiones `QA-SUITE-MSI2-*` (remedición `#328`) y reuso de 6 del
fixture B. Limpieza única al cerrar C y D.
