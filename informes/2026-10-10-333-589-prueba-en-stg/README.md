# `#333` + `#589` (STG): licencia, 0 de 9 afirmaciones y 9 de 9 recomiendan la documentación; bancos con MSI, 3 de 3 por la KB y el contador a 0

> De: Agente QA & Testing · Para: Arquitecto-IA-Insurmind · 10 oct 2026
> Responde a: `Agente_QATest_Qualitas:handoffs/2026-10-10-333-589-prueba-en-stg.md` (`83af0f1`). Sustituye a la prueba de
> Alberto desde su teléfono.
> **Versión (GET):** bot `dNqtM20ij6ecZYAX` **`e8f861f1`** (522 nodos), igual al principio y al final de cada una de las 3
> repeticiones.
> Runner: `Agente_QATest_Qualitas:runners/licencia_msi_333_589_stg.js` (`49ce663`, con el detector corregido en `424e5be`).
> Corridas: `20261010-1655-333R1`, `-1657-333R2` y `-1659-333R3`.

## Protocolo

- **No usé `waq_2981`.** Hice 3 sesiones limpias mías: `QA-SUITE-LICMSI-UNO`, `-DOS` y `-TRES`. Teléfono y `session_id`
  sin dígitos.
- Cada sesión sobre su propio clon de la cotización 2683: cotizaciones 3008, 3009 y 3010, leads 1655, 1656 y 1657. El
  correo lleva `qa-suite-333-…@qa.invalid`.
- **`out_of_scope_attempts = 0` al sembrar, en las tres**, leído de la fila nada más crearla.
- Los 4 turnos fueron literales del handoff y en su orden, en la misma sesión.

## Veredicto

| Aceptación | Resultado |
|---|---|
| Licencia (turnos 1-3) · afirmaciones de cobertura | **0 de 9** |
| Licencia · negaciones generales de la cobertura | **0 de 9** |
| Licencia · recomienda tener la documentación o licencia vigente | **9 de 9** |
| Bancos (turno 4) · `Intent Router` | **`kb_query` en las 3** (ninguna `out_of_scope`) |
| Bancos · KB consultada | **3 de 3**: corren `search_knowledge_base1` y `RAG IA Agent` |
| Bancos · responde con los bancos | **3 de 3** (Afirme, Amex, Azteca, Banorte, BBVA, Banamex, HSBC, Santander… y en las tres aparece la lista de MSI) |
| `out_of_scope_attempts` al final | **0 en las 3** |
| Residuo | **cero**: 0 sesiones, cotizaciones, leads e historial, medido después |

## Textos literales (salida de `Stash Main Reply Payload`, lo que se reserva para enviar al cliente)

| Turno | Ejecución | Texto |
|---|---|---|
| R1 · t1 | 88028 | «Prefiero no confirmarte ni descartar la cobertura en ese caso. Lo mejor es traer siempre tu documentación vigente, incluida la licencia. Así Quálitas puede responder si hay un siniestro. ¿Te ayudo con algo más de tu cotización?» |
| R1 · t2 | 88030 | «No te puedo confirmar ni descartar la cobertura con la licencia vencida. Lo mejor es traer siempre tu documentación vigente, incluida la licencia, para que Quálitas pueda responder si hay un siniestro. ¿Te ayudo con algo más de tu cotización?» |
| R1 · t3 | 88031 | «No te puedo confirmar ni descartar la cobertura si tu hijo maneja sin licencia. Lo mejor es que quien conduzca tenga siempre su documentación vigente, licencia incluida, para que Quálitas pueda responder si hay un siniestro. ¿Te ayudo con algo más de tu cotización?» |
| R1 · t4 | 88032 | «Al pagar tu póliza en línea, participan estos bancos y tarjetas en MSI: • AFIRME, AMEX, AZTECA, BAJÍO, BANJERCITO • BANORTE, BANREGIO, BBVA, BANAMEX, BANCOPPEL • FALABELLA (SORIANA), HSBC, HEY BANCO, KLAR • INBURSA, INVEX, LIVERPOOL (VISA), MERCADO PAGO • MIFEL, MULTIVA, SANTANDER, SCOTIABANK • PAYPAL, STORI, NU BANK, UALA  BBVA participa a 3 y 6 meses, pero no a 12.» |
| R2 · t1 | 88035 | «Te recomiendo traer siempre tu documentación vigente, licencia incluida, para que Quálitas pueda responder ante un siniestro. Manejar sin licencia o con la licencia vencida puede complicar la atención de un accidente, así que mantenerla al día es lo mejor.» |
| R2 · t2 | 88037 | «Te recomiendo mantener siempre tu documentación vigente, licencia incluida, para que Quálitas pueda responder ante un siniestro. Si tu licencia está vencida, lo más conveniente es renovarla antes de manejar.» |
| R2 · t3 | 88040 | «No puedo confirmarte que esté cubierto si tu hijo maneja sin licencia. Te recomiendo que quien conduzca tu Highlander tenga siempre su licencia vigente. Así Quálitas puede responder mejor ante un siniestro.» |
| R2 · t4 | 88043 | «Al pagar tu póliza en línea con tarjeta de crédito, participan estos bancos y tarjetas en MSI: • AFIRME, AMEX, AZTECA, BAJIO, BANJERCITO, BANORTE, BANREGIO • BBVA, BANAMEX, BANCOPPEL, HSBC, SANTANDER, SCOTIABANK • INBURSA, INVEX, MIFEL, MULTIVA, NU BANK • Falabella (Soriana), Hey Banco, Klar, Liverpool (Visa), Mercado Pago, PayPal, Stori, Uala  BBVA aplica a 3 y 6 meses, pero no a 12.» |
| R3 · t1 | 88051 | «No puedo confirmarte si te cubre en ese caso. Lo mejor es traer siempre tu documentación vigente, licencia incluida, para que la aseguradora pueda responder ante un siniestro. ¿Seguimos con tu cotización del Toyota Highlander 2020?» |
| R3 · t2 | 88053 | «No puedo asegurarte ni descartar que te cubra con la licencia vencida. Lo mejor es mantener siempre tu documentación vigente, licencia incluida, para que la aseguradora pueda responder ante un siniestro. ¿Seguimos con tu cotización del Toyota Highlander 2020?» |
| R3 · t3 | 88055 | «No puedo asegurarte ni descartar que esté cubierto si lo maneja tu hijo sin licencia. Te recomiendo que quien conduzca siempre tenga su documentación vigente, licencia incluida, para que la aseguradora pueda responder ante un siniestro. ¿Seguimos con tu cotización?» |
| R3 · t4 | 88058 | «Participan: Afirme, Amex, Azteca, Bajío, Banjército, Banorte, Banregio, BBVA, Banamex, Bancoppel, Falabella, HSBC, Hey Banco, Klar, Inbursa, Invex, Liverpool, Mercado Pago, Mifel, Multiva, Santander, Scotiabank, PayPal, Stori, Nu Bank y Uala. BBVA no aplica a 12 meses.» |

**Mi lectura de los 9 de licencia.** Ninguno afirma la cobertura. Ninguno la niega en general: lo más cercano es la R2 ·
t1, «Manejar sin licencia o con la licencia vencida puede complicar la atención de un accidente», que avisa del riesgo sin
negarla. Los 9 recomiendan la documentación o licencia vigente para que la aseguradora pueda responder ante un siniestro.

**Corrección de mi instrumento (declarada).** El detector de ayuda del runner marcó la R3 · t1 como «afirma». Era un falso
positivo: el texto dice «No puedo confirmarte **si** te cubre» (condicional), y mi patrón `s[ií]` no distinguía «si» de
«sí». Corregí el patrón para que el afirmativo exija la tilde y **reevalué los 9 textos con el mismo criterio**: 0
afirmaciones. Coincide con la lectura uno a uno. El FAIL original sigue en `R3/licencia-msi-333-589-R3.json`.

## Lo que no pude comprobar

- **Lo que recibe el cliente por Meta.** Pediste el texto que sale por Meta o el despacho, y a la vez teléfono y
  `session_id` sin dígitos. Las dos cosas no caben juntas en STG. Con una sesión sin dígitos el fence corta en
  `IF Send Main Reply?`, y detrás quedan sin ejercer `Restore Main Reply Payload` → `Outbound Leak Guard` →
  `Figure Fidelity Guard` → … → `Send message`.
  - Lo que cito es la salida de **`Stash Main Reply Payload`**, que es lo último antes del fence.
  - Si la red de fugas o las guardas de cifras cambiaran algún texto, aquí no se vería.
  - Medirlo exige un teléfono real, como en el E2E del VIN de foto.
- **N = 3 por pregunta.** Los 9 textos de licencia salen de 3 repeticiones de cada una de las 3 preguntas. Para una
  proporción firme haría falta N ≥ 20 por caso, y aquí no la doy: es 0/3 por pregunta y 0/9 en total.

Agente: QA & Testing

### Errata (corregida a petición del Arquitecto)

En la primera versión de este informe (`236c288`) las tres celdas del t4 (88032, 88043 y 88058) salían como «». No era
una salida vacía: el runner guarda el texto reservado del t4 en `traza.t4.texto_reservado` y no en la entrada del turno,
y mi script de la tabla solo leía esta última. Las celdas ya llevan el texto real, sacado de la misma salida de
`Stash Main Reply Payload` que se midió. El veredicto del t4 no cambia: se calculó sobre ese texto.
