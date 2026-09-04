# Banco de clasificación del carril de descuentos — 54 frases contra el clasificador vivo de STG

> De: Agente QA & Testing · Para: Arquitecto-IA-Quálitas
> Responde a: `handoffs/2026-09-04-set-frases-carril-descuentos.md` (vía (b), autorizada por ti el 4-sep)
> Set: `Agente-MejorasConversacion:informes/2026-09-04-frases-descuento-para-qa.md` @ `d214b5a`,
> transcrito literal a `Agente_QATest_Qualitas:fixtures/frases_descuento_50.json` (commit `9319b83`).
> Corrida: `20260904-0658` (hora MX) · runner `runners/descuentos_clasificador_stg.js` (rejugable).

## ⚠️ RÓTULO — y es la conclusión, no la letra pequeña

**Esto mide la INTENCIÓN del clasificador, no el routing del carril.** Que el clasificador acierte
no implica que el carril corra: el claim de fase 2 (`n8n_discount_phase2_claim`) deniega sesiones
sintéticas **antes** del clasificador (`sesion_inexistente` si el teléfono no canonicaliza — execs
25350/25353), y detrás quedan los gates de `conversation_control_v1`. Es el patrón del `#307`:
barrera determinista detrás de puerta probabilística. **Un «24/24 correctas» aquí jamás
significaría «el carril funciona».** (Y no salió 24/24.)

## Resultado en tres líneas

- **35 de 50 frases con esperado clasifican como deben (70%).** Las 4 de zona gris van aparte, registradas sin dictamen.
- **El clasificador falla CONSERVADOR: 14 falsos negativos y solo 1 falso positivo.** Coherente con su prompt («no_match en cualquier duda») — y con el `#270` y el `#307`: lo que se pierde son entradas legítimas, no se inventan descuentos.
- **La frase 15 —el caso literal del `#270`— sigue en `no_match`.** Reproducido hoy con el prompt y catálogo vivos: la medición del 31-ago no era ruido.

## Qué se midió exactamente (ámbito)

- **Grafo vivo** `dNqtM20ij6ecZYAX` (STG), **`versionId 549bcf12-c8c8-428e-8866-2cce2f9a2229`**,
  updatedAt 2026-09-03T00:09Z, 316 nodos — el grafo cambió tras la redacción del set (carril nuevo
  del `#273` incluido); una medición de prompt sin versionId caduca en silencio.
- **Modelo del nodo vivo:** `claude-sonnet-5` (`Discount Classifier Model`, options vacías).
  Invocado por CLI local con el mismo systemMessage y template del nodo `Discount Intent
  Classifier`, leídos del grafo por API en el momento de la corrida.
- **Catálogo vivo** de Django STG (`GET /api/v1/discounts/ai-use-cases`, Bearer): válido,
  clasificable, con `PRICE_OBJECTION` como único código soportado (allowlist del validador).
- **Puertas y parseo:** ports fieles de `Validate Discount Catalog` y `Parse Discount
  Classification` (regla §3.3 del 14-ago; extensión local `COVERAGE_DOWNGRADE` → intent
  `PRICE_OBJECTION` + signal `coverage_downgrade`), con el hash del `jsCode` vivo vigilado por el
  runner (deriva → WARN). `consultar_disponibilidad` derivada con la regla de
  `n8n_discount_phase2_classify` (leída de `pg_get_functiondef`): **true ⟺ `PRICE_OBJECTION`**.
- **Cero escrituras en cualquier base y cero inyecciones**: n8n API GET, catálogo GET, modelo por
  CLI. Sin residuo en STG.
- **Una sola pasada por frase**: la tasa de consistencia (lección `QA-CONV-003`/`#271`) no se mide
  en esta corrida — un borderline puede saltar de lado entre corridas.

## Los 15 fallos, por patrón

**14 falsos negativos** (debían entrar y quedaron en `no_match`):

| Patrón | Frases |
|---|---|
| Caso literal del `#270` (comparativa + preferencia + petición) | **15** |
| Peticiones indirectas / suaves («ya es lo menos?», «bajaría de precio?», presupuesto) | 10, 11, 22 |
| «Promoción» sin banco (el set dice: promoción = descuento si no nombra banco) | 7 |
| Typo («Descuentod») | 8 |
| Comparativa con agencia / ex-cliente con precio viejo | 19, 20, 21 |
| M50 ruta 2a: «más económico» sin nombrar cobertura → debía ser DESCUENTO | 23 |
| M50 ruta 1 no reconocida: «que cubra a terceros» / «una básica» → debía ser `COVERAGE_DOWNGRADE` | 34, 35 |
| Referido («descuento adicional» de parte de alguien) → debía dar el 40% normal | 41 |
| Despedida con competidor tras tener el 40% → debía entrar (NO-MÁS lo decide después el carril) | 50 |

**1 falso positivo:** la **25** («hay algun descuento si es pago de contado?») entró como
`PRICE_OBJECTION` — la trampa M49 del contado **no la aguantó**; el resto de trampas (MSI ×5,
INFO ×6, KB ×3, DERIVAR ×2, contado 26) sí.

**Los aciertos también dibujan el borde:** las objeciones claras (1–6, 9, 12–14, 16–18, 24), la 33
y la 36 (downgrade con «quiero»/«cuánto es» explícitos), la 49 («Está muy cara» → entra; el NO-MÁS
es trabajo del carril, no del clasificador) y TODAS las preguntas informativas puras pasaron.

**Formato: 54/54 `output_shape=bare`.** El modelo obedece el contrato JSON a la perfección; el
problema no es de forma, es de criterio de entrada.

## Zona gris (registro, sin dictamen — las decide Alberto)

| # | Frase | Clasificó | `consultar_disponibilidad` |
|---|---|---|---|
| G1 | «Sigo viendo precios» | `no_match` | false |
| G2 | «Ok muchas gracias estamos checando nuestro presupuesto» | `no_match` | false |
| G3 | «el precio» | `PRICE_OBJECTION+price` | true |
| G4 | «Porque es más cara que una que me acaban de enviar» | `PRICE_OBJECTION+price` | true |

(La expectativa del emisor era DESCUENTO en G1/G2/G4 y ACLARAR→DESCUENTO en G3: salieron 2 de 4,
y G3 clasificó directo sin aclarar — anotado, no dictaminado.)

## Tabla completa — una fila por frase

| # | G | Frase | Carril esperado | Clasificador esperado | Observado | `consultar` | Veredicto |
|---|---|---|---|---|---|---|---|
| 1 | A | Está muy cara, gracias | DESCUENTO | PRICE_OBJECTION+price | `PRICE_OBJECTION+price` | true | ✅ |
| 2 | A | No, esta muy caro | DESCUENTO | PRICE_OBJECTION+price | `PRICE_OBJECTION+price` | true | ✅ |
| 3 | A | Es muy elevado el costo | DESCUENTO | PRICE_OBJECTION+price | `PRICE_OBJECTION+price` | true | ✅ |
| 4 | A | Quiero pagar menos | DESCUENTO | PRICE_OBJECTION+price | `PRICE_OBJECTION+price` | true | ✅ |
| 5 | A | Algún descuento? | DESCUENTO | PRICE_OBJECTION+price | `PRICE_OBJECTION+price` | true | ✅ |
| 6 | A | Cuentan con algún descuento??? | DESCUENTO | PRICE_OBJECTION+price | `PRICE_OBJECTION+price` | true | ✅ |
| 7 | A | tienes alguna promoción | DESCUENTO | PRICE_OBJECTION+price | `no_match` | false | ❌ |
| 8 | A | Descuentod | DESCUENTO | PRICE_OBJECTION+price | `no_match` | false | ❌ |
| 9 | A | Vale y el costo puede mejorar? | DESCUENTO | PRICE_OBJECTION+price | `PRICE_OBJECTION+price` | true | ✅ |
| 10 | A | ya es lo menos? | DESCUENTO | PRICE_OBJECTION+price | `no_match` | false | ❌ |
| 11 | A | Cómo quedaría la cotización, bajaría de precio? | DESCUENTO | PRICE_OBJECTION+price | `no_match` | false | ❌ |
| 12 | A | Estás más caro que otras aseguradoras | DESCUENTO | PRICE_OBJECTION+price | `PRICE_OBJECTION+price` | true | ✅ |
| 13 | A | esta muy cara, gnp me la deja mejor | DESCUENTO | PRICE_OBJECTION+price | `PRICE_OBJECTION+price` | true | ✅ |
| 14 | A | Si está un poco elevado por k tengo una cotización de 13,100 con HDI entonces creo k es más baja | DESCUENTO | PRICE_OBJECTION+price | `PRICE_OBJECTION+price` | true | ✅ |
| 15 | A | Me cotizaron con otra compañía y me salía en mejor precio, pero la verdad a mí me gustaría Quálitas. ¿No tendrán alguna promoción? | DESCUENTO | PRICE_OBJECTION+price | `no_match` | false | ❌ |
| 16 | A | El banco me pide que sea el 20 % más barato, podría apoyarme con ello. | DESCUENTO | PRICE_OBJECTION+price | `PRICE_OBJECTION+price` | true | ✅ |
| 17 | A | Tengo esta poliza mas barata | DESCUENTO | PRICE_OBJECTION+price | `PRICE_OBJECTION+price` | true | ✅ |
| 18 | A | No está en mi presupuesto esa cantidad | DESCUENTO | PRICE_OBJECTION+price | `PRICE_OBJECTION+price` | true | ✅ |
| 19 | A | Me la checaron en la agencia y me cotizaron 14,082.90 por qué sube? | DESCUENTO | PRICE_OBJECTION+price | `no_match` | false | ❌ |
| 20 | A | Subieron sus costos? hace 2 años tenía asegurado con ustedes un Tiida cobertura amplia por 5,653 | DESCUENTO | PRICE_OBJECTION+price | `no_match` | false | ❌ |
| 21 | A | El seguro anterior fue con ustedes espero que me den mejor precio para asi contratar el seguro con ustedes | DESCUENTO | PRICE_OBJECTION+price | `no_match` | false | ❌ |
| 22 | A | Hola, dame oportunidad de revisar para poder ajustar mi presupuesto | DESCUENTO | PRICE_OBJECTION+price | `no_match` | false | ❌ |
| 23 | A | Existe un seguro más económico? | DESCUENTO | PRICE_OBJECTION+price | `no_match` | false | ❌ |
| 24 | A | Tienen más económicos | DESCUENTO | PRICE_OBJECTION+price | `PRICE_OBJECTION+price` | true | ✅ |
| 25 | B | hay algun descuento si es pago de contado? | CONTADO | no_match | `PRICE_OBJECTION+price` | true | ❌ |
| 26 | B | Cuánto es el descuento en pago de contado? | CONTADO | no_match | `no_match` | false | ✅ |
| 27 | B | Tienes meses sin intereses? | MSI | no_match | `no_match` | false | ✅ |
| 28 | B | Tienes una promocion con BBVA? | MSI | no_match | `no_match` | false | ✅ |
| 29 | B | Cual es la promoción con Banamex? | MSI | no_match | `no_match` | false | ✅ |
| 30 | B | Y si pago con TDC BBVA tienes meses sin intereses ? | MSI | no_match | `no_match` | false | ✅ |
| 31 | B | Solo quiero aplicar MSI | MSI | no_match | `no_match` | false | ✅ |
| 32 | B | No tengo tarjeta de crédito sólo débito | INFO | no_match | `no_match` | false | ✅ |
| 33 | B | Es mucho ahorita no tengo trabajo me interesa sólo daños a terceros | LIMITADA | PRICE_OBJECTION+coverage_downgrade | `PRICE_OBJECTION+coverage_downgrade` | true | ✅ |
| 34 | B | Buen día estoy buscando un seguro económico que cubra a terceros | LIMITADA | PRICE_OBJECTION+coverage_downgrade | `no_match` | false | ❌ |
| 35 | B | Me gustaría saber en cuanto me sale una básica la más económica que tengas. | LIMITADA | PRICE_OBJECTION+coverage_downgrade | `no_match` | false | ❌ |
| 36 | B | Está cara, la limitada cuánto es? | LIMITADA | PRICE_OBJECTION+coverage_downgrade | `PRICE_OBJECTION+coverage_downgrade` | true | ✅ |
| 37 | B | Ya con el descuento del adulto mayor | KB | no_match | `no_match` | false | ✅ |
| 38 | B | Para hacer válido el descuento del ISSFAM | KB / INFO | no_match | `no_match` | false | ✅ |
| 39 | B | Sería con el descuento de indriver | DERIVAR | no_match | `no_match` | false | ✅ |
| 40 | B | para trabajar en plataforma digital que costó tiene | DERIVAR | no_match | `no_match` | false | ✅ |
| 41 | B | Hola me dijo Rafa que si me pueden ayudar con un descuento adicional | DESCUENTO, sin «adicional» | PRICE_OBJECTION+price | `no_match` | false | ❌ |
| 42 | B | Ayer cotice y me marcaba un descuento adicional | INFO | no_match | `no_match` | false | ✅ |
| 43 | B | ¿cuánto ahorro con el descuento? | INFO | no_match | `no_match` | false | ✅ |
| 44 | B | ¿Que costo tiene el seguro mensual? | INFO | no_match | `no_match` | false | ✅ |
| 45 | B | Es el mismo costo si voy directamente a la aseguradora? | INFO | no_match | `no_match` | false | ✅ |
| 46 | B | Y se aprovechó esta oferta y cáncelo a los 15 días que pasa? | KB | no_match | `no_match` | false | ✅ |
| 47 | B | Con esta cobertura si yo tengo la culpa aun así pago deducible | KB | no_match | `no_match` | false | ✅ |
| 48 | B | y las tres cotizaciones traen las mismas coberturas o solo ha cambiado el precio? | INFO | no_match | `no_match` | false | ✅ |
| 49 | B | Está muy cara | NO-MÁS | PRICE_OBJECTION+price | `PRICE_OBJECTION+price` | true | ✅ |
| 50 | B | Muchas gracias creo cerraré trato con HDI gracias por la atención | NO-MÁS / cierre | PRICE_OBJECTION+price | `no_match` | false | ❌ |
| G1 | C | Sigo viendo precios | DESCUENTO (expectativa del emisor, no cerrada) | — (gris) | `no_match` | false | 📝 registro |
| G2 | C | Ok muchas gracias estamos checando nuestro presupuesto | DESCUENTO (expectativa del emisor, no cerrada) | — (gris) | `no_match` | false | 📝 registro |
| G3 | C | el precio | ACLARAR → DESCUENTO | — (gris) | `PRICE_OBJECTION+price` | true | 📝 registro |
| G4 | C | Porque es más cara que una que me acaban de enviar | DESCUENTO (expectativa del emisor, no cerrada) | — (gris) | `PRICE_OBJECTION+price` | true | 📝 registro |

## Notas declaradas

1. **Descuadre del set, medido:** el grupo B declara 22 frases pero contiene 26 filas (25–50);
   total real 54, no 50. Ejecuté las 54 tal como están escritas (las filas mandan). Lo llevas tú
   con Mejoras.
2. **Diferencia de invocación:** modelo por CLI, no por el nodo LangChain; el nodo vivo no fija
   parámetros (options vacías), pero los defaults de ambas vías pueden diferir. Si un borderline
   importa, se repite N veces (el runner acepta `QA_DESC_ONLY`).
3. **`STG_N8N_TOKEN` de mi `.env` está rotado** (huella distinta del vivo; el runner lo recibe
   efímero vía Heroku API). Que Alberto actualice el `.env` cuando toque.
4. Las precondiciones de 49/50 (40% ya aplicado) **no aplican a este banco**: aquí solo se juzga la
   clasificación del turno; el NO-MÁS es routing y queda sin medir, como todo lo que está detrás
   de la puerta.

```
🧪 QA REPORT — 4 sep 2026 · banco clasificador descuentos (STG, vía (b))
Triggered by: handoff 2026-09-04-set-frases-carril-descuentos.md + GO del Arquitecto (vía b)

⚠️ RÓTULO: mide INTENCIÓN del clasificador, NO routing del carril (claim deniega sintéticos antes)
✅ 35/50 con esperado correctas (70%) · zona gris 2/4 según expectativa del emisor
❌ 14 falsos negativos (incl. frase 15 = caso literal #270, reproducido con grafo vivo 549bcf12)
❌ 1 falso positivo: contado (M49) entra como PRICE_OBJECTION (frase 25)
✅ formato impecable: 54/54 output_shape=bare · catálogo vivo válido (PRICE_OBJECTION)
✅ cero escrituras, cero inyecciones, sin residuo · runner rejugable en regresión
```

— Agente QA & Testing

---

## Adenda — estabilidad N=5 sobre las 9 frases pedidas (corrida `20260904-0707-N5`)

Mismo runner, mismo grafo (`versionId 549bcf12`), 5 pasadas por frase:

| # | Frase | Esperado | N=5 | Veredicto |
|---|---|---|---|---|
| 7 | «tienes alguna promoción» | PRICE_OBJECTION+price | **5× no_match** | **DEFECTO estable** |
| 8 | «Descuentod» | PRICE_OBJECTION+price | **5× no_match** | **DEFECTO estable** |
| 15 | caso literal `#270` | PRICE_OBJECTION+price | **5× no_match** | **DEFECTO estable** |
| 19 | comparativa agencia | PRICE_OBJECTION+price | 3× no_match / 2× price | **BORDERLINE (3/2)** |
| 23 | «Existe un seguro más económico?» (M50 2a) | PRICE_OBJECTION+price | **5× no_match** | **DEFECTO estable** |
| **25** | **contado (falso positivo)** | no_match | **5× PRICE_OBJECTION+price** | **DEFECTO estable** |
| 34 | «económico que cubra a terceros» | +coverage_downgrade | **5× no_match** | **DEFECTO estable** |
| 35 | «una básica la más económica» | +coverage_downgrade | **5× no_match** | **DEFECTO estable** |
| G3 | «el precio» (zona gris) | — | 4× no_match / 1× price | **BORDERLINE (4/1)** |

Lecturas que cambian el dictamen:

- **La 25 es 5/5: el riesgo prospectivo es firme** — con el carril corriendo, el bot abrirá un
  escalón de descuento a quien solo pregunta por la forma de pago, cada vez.
- **La G3 desmiente su propia primera pasada:** en la corrida de 54 salió `PRICE_OBJECTION`; a N=5
  reparte 4 no_match / 1 price. El borderline aterrizó de casualidad en la primera corrida —
  exactamente el fallo que la repetición existe para cazar.
- Los 6 falsos negativos restantes son **estables**: defectos de criterio del prompt, no ruido.

(45 pasadas totales; formato `bare` en todas. Runner con `QA_DESC_REPEAT` committeado — la
repetición queda como capacidad permanente de la suite.)
