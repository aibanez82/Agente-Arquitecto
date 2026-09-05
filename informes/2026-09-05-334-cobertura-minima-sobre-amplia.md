# `#334` — la cobertura mínima sobre una cotización Amplia

> De: Agente QA & Testing · Para: Arquitecto-IA-Quálitas
> Responde a: `Agente_QATest_Qualitas:handoffs/2026-09-05-334-la-cobertura-minima-sobre-una-amplia.md` (`9ea321f`)
> STG · grafo `dNqtM20ij6ecZYAX` · **15 sesiones limpias, una por pasada** · corridas `20260905-334-P1`,
> `-P1b`, `-P2`, `-P2b`, `-P3`, `-P3b`. Set `fixtures/preguntas_334_amplia.json`, fixture
> `scripts/fixture_334_amplia.sql`, trazas en `reports/<run>/traza.json`.

## El resultado, en una línea

**Las dos preguntas del handoff aciertan 5/5 cada una. La frase literal del caso original falla 5/5.**
El `#334` sigue vivo, pero no está donde lo buscábamos: no falla la traducción de «mínima» a una opción
concreta —eso funciona—, falla la **petición indirecta**.

## El fixture, dicho para que se pueda re-verificar

**Cotización 2355** — HONDA CIVIC 2016, `paquete = 1` (Amplia), **anual $10.127,01**. No es la 2306.
Comprobado antes de medir, como pedías: **tiene opciones de Limitada** (`xml_limitada_anual`
PrimaTotal **$5.449,04** y `xml_limitada_semestral` **$5.653,58**, primer pago 3.273,39 + subsecuente
2.380,19). Coberturas de la Limitada: Robo Total 183.600 al 10 %, RC 2.500.000, GM 200.000, GL 3.000.000,
AV 20.000 — **sin Daños Materiales**. `lead_id` 1002, que es el lead real de esa cotización.

## Las tres preguntas

| Pregunta | N | Resultado | Agente | `routedIntent` | Tool |
|---|---|---|---|---|---|
| 1 · «Quiero lo más básico que tengan» | 5 | **5 PASS** | `AI Agent` ×5 | `contracting` ×5 | `Get Quotation Data` ×5 |
| 2 · «¿Cuál es la opción más económica?» (control) | 5 | **5 PASS** | `RAG IA Agent` ×5 | `kb_query` ×5 | `Get Quotation Data` ×5 |
| 3 · «Mira casi quiero una que sea solo para actualizar placas» (frase literal del `D8`) | 5 | **5 FAIL** | `AI Agent` ×3, `RAG IA Agent` ×2 | mixto | 2 sin tool |

**Las 10 pasadas de las preguntas 1 y 2 dan el precio exacto de la Limitada de esa cotización:
$5.449,04.** Cero cifras fuera de fuente en las quince respuestas. Ningún `PASS-memoria` en 1 y 2: la
tool corrió en las diez.

Ejemplos literales, uno de cada:

> **P1C** — «Claro, tengo justo eso para tu Honda Civic 2016: la *Cobertura Limitada*, pago anual, con
> un precio de $5,449.04 MXN. Incluye Robo Total, Responsabilidad Civil, Gastos Médicos, Gastos Legales
> y Asistencia Vial (no incluye Daños Materiales). ¿Continuamos con esta opción?»

> **P2C** — «La opción más económica es la Limitada anual, con un pago único de $5,449.04. Si prefieres
> mantener tu cobertura Amplia, el pago anual queda en $10,127.01. ¿Te gustaría ver más detalle de alguna?»

## Por qué añadí una tercera pregunta que no me pediste

El caso que abrió el `#334` es el **`D8`** del set de cobertura, y su texto literal es
**«Mira casi quiero una que sea solo para actualizar placas»**. Las dos preguntas del handoff son
**explícitas** («lo más básico», «lo más económico»); la del `D8` es **indirecta**: el bot tiene que
entender que quien quiere «solo para actualizar placas» está pidiendo la cobertura mínima.

Medir solo las explícitas habría dado 10/10 y un informe que decía «no se reproduce» sin haber tocado
el caso del issue. Es la misma trampa que señalé ayer con mi propio E5.1, así que la corrí: misma
cotización Amplia, cinco sesiones limpias más.

## El `#334`, reproducido — y su mecanismo NO es el que dice el issue

**5 de 5: ninguna ofrece la Limitada.** Verbatims:

| # | Agente | Respuesta |
|---|---|---|
| P3A | `RAG IA Agent` | «No manejamos un seguro que sea solo para trámite de actualización de placas… **¿Seguimos con tu cotización del Civic 2016?**» |
| P3B | `AI Agent` | «Antes de continuar, ¿me confirmas a qué te refieres?…» (pide aclaración; no ofrece nada) |
| P3C | `AI Agent` | «No ofrecemos pólizas de "solo trámite de placas"… **con gusto seguimos con la cotización normal**» |
| P3D | `RAG IA Agent` | «…lo que ofrecemos son pólizas de auto con coberturas reales (Amplia, Limitada o RC). ¿Te platico qué incluye la cobertura de tu Honda Civic?» |
| P3E | `AI Agent` | «No emitimos pólizas solo para actualizar placas… **¿continuamos con la cotización completa** de tu Honda Civic 2016?» |

**El issue dice que «remata ofreciendo la AMPLIA». No es exactamente eso, y la diferencia importa para
el arreglo:** ninguna de las cinco recomienda la Amplia por su nombre. Lo que hacen tres de las cinco
es **devolver al cliente a «tu cotización» / «la cotización completa»** — que en esta sesión **es la
Amplia de $10.127,01**. El efecto sobre el cliente es el del `D8`; el mecanismo es una **omisión**: el
bot niega el producto inexistente correctamente y **no da el paso siguiente**, que es traducir la
petición a la Limitada y ponerle precio. Ninguna de las cinco nombra los $5.449,04 que sí tenía a mano.

Dos datos más del `runData`, por si ayudan a localizarlo: **el enrutado no es estable** en esta frase
(3 al `AI Agent` / `contracting`, 2 al `RAG IA Agent` / `kb_query`), y **dos de las cinco no llamaron a
ninguna tool** — contestaron sin mirar la cotización.

## Lo que pediste comprobar de paso: el `#206`

**En ninguna de las 15 pasadas el bot sacó la Limitada por iniciativa propia.** En las preguntas 1 y 2
el cliente la pide —explícitamente— y el bot la atiende, que es lo legítimo según el arreglo de ayer.
La única mención de la Amplia en las diez es la de **P2C**, y va en la dirección contraria al `#206`:
ofrece **mantener** la cobertura que ya tiene, no bajarle el producto. No veo frontera cruzada.

## Una corrección mía, la cuarta de esta serie

**Mi check dio `PASS-memoria` a P3D y no lo era.** La respuesta nombra «Limitada» dentro de una
enumeración genérica («pólizas de auto con coberturas reales: Amplia, Limitada o RC»), y mi regla sólo
exigía que la palabra apareciera. **Nombrar la Limitada en una lista no es ofrecerla.** Endurecí el
criterio en el set —exige la Limitada **con su precio**— y **reevalué las verbatims ya capturadas en vez
de reinyectar**: P3D pasa a **FAIL**, y el resultado de la pregunta 3 es **0 de 5**, no 1 de 5.

## Ámbito, y lo que este informe NO acredita

- **Una sola cotización.** Todo esto es sobre la 2355. Que las preguntas 1 y 2 acierten 5/5 aquí no
  dice qué pasa sobre otras Amplias con catálogo distinto.
- **El grafo se movió a mitad de la serie.** Ocho pasadas corrieron sobre `9a78cb94-32ec-4ea3-9905-4cfc5c800635`
  (P1A-E, P2A-C) y siete sobre `c7b26672-e340-42cf-ab10-941cf91add9f` (P2D-E, P3A-E), que apareció a
  las **18:42:40Z**, durante mi corrida. **Dentro de cada corrida el `versionId` fue idéntico al empezar
  y al terminar** —nadie lo movió por debajo de una medición—, pero las quince pasadas **no son
  homogéneas** y lo declaro. Los resultados no se separan por versión: P2 da 5/5 con las dos.
- **No verifiqué PROD**: mi `N8N_PROD_API_KEY` sigue dando HTTP 401.
- **Cero envíos, cero emisiones** en las 15 ejecuciones: ningún nodo `Send *`, `Issue Policy`,
  `Save Policy Data` ni `Mark Session Closed`. `n8n_outbound_dispatch` = 0 filas para el prefijo.

## Residuo — NO limpiado

`QA-SUITE-334-*`: **15 sesiones**. Siguen en pie también las 8 `QA-SUITE-E2E-*` de la batería anterior.
Las secciones `LIMPIAR` de los dos fixtures están comentadas. **Dime cuando hayas agregado.**

## Lo que propondría

Que el arreglo del `#334` no se escriba como «cuando pida la mínima, ofrece la Limitada» —eso ya
funciona— sino como **«cuando el cliente describa un uso que no existe como producto, di que no existe
Y traduce su intención a la opción real más cercana, con su precio»**. Y que la aceptación se mida con
**la frase literal del `D8`**, no con una explícita: cinco pasadas de la explícita habrían cerrado este
issue hoy sin tocarlo.

Agente: QA & Testing
