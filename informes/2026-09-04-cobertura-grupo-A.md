# Preguntas de cobertura, grupo A — 15 frases contra su propia cotización (STG)

> De: Agente QA & Testing · Para: Arquitecto-IA-Quálitas
> Responde a: tu encargo del 4-sep sobre el set `Agente-MejorasConversacion:informes/2026-09-04-set-50-preguntas-cobertura-para-qa.md`
> **Solo grupo A, como ordenaste.** B espera tu aviso del `#320`; C y D, tu palabra.
> Grafo vivo `dNqtM20ij6ecZYAX` **`versionId ec5052cf`** · agente conversacional y RAG en
> `claude-sonnet-5`, router/jailbreak en Haiku 4.5 (leído del grafo en la corrida).
> Fixture: 14 clones `QA-SUITE-COB-*` de `QA-SUITE-S1` (cotización **2307**), bajo el **GO del
> 31-ago** (prefijo QA-SUITE-, teléfonos sin dígitos, borrado por IDs exactos pendiente, solo STG).
> Ejecución **en primer plano por bloques** (los kills de tareas de fondo siguen sin causa).
> Corridas: `cob-smoke`, `20260904-COB-A`, `-b2`, `-b3`, `-r2` (16:xx–19:xxZ del 4-sep, hora MX 4-sep tarde).

## La verdad contra la que se juzgó (leída ANTES de inyectar, como manda el set)

`POST /api/cotizacion/detalle/` de la 2307 — Amplia: DM 5% / $169.200 · RT 10% / $169.200 ·
RC 0 / $2.500.000 · GM 0 / $200.000 · GL 0 / $3.000.000 · AV 0 / $20.000 · `tipo_suma=2` (sin
nombre) · vigencia 2026-09-01 → 2027-09-01 · precios C/S/T/M de Amplia y C/S de Limitada anotados
en `fixtures/preguntas_cobertura_A.json`. **Nota previa que afecta a leer el set:** el formato del
deducible en STG es `5`/`10`/`0` (no `0005`/`00010` como el ejemplo de PROD del set); la verdad es
el valor, no el formato.

## Resultado: 8 PASS · 4 FAIL-293 · 1 FAIL-292 · 1 REGISTRAR · 1 no ejercitable

| # | Frase | Veredicto | Evidencia (verbatim esencial) |
|---|---|---|---|
| A1 | deducible de la amplia | **PASS** | «DM 5% y RT 10%… RC, GM, GL y AV no llevan deducible» (exec 31341) |
| A2 | «¿pago el 5% de deducible?» | **FAIL-292** (2º intento) + **error de grafo** (1º) | 1º: exec 31344 **status=error en `Detect Jailbreak`** — el turno NI CORRIÓ. 2º (exec 31371): «no es un porcentaje fijo… revisa tu PDF de cotización» — **deflecta al PDF teniendo el 5% en `coberturas_detalle`**. Ni confirmó ni corrigió |
| A3 | «conocer los deducibles» | **PASS** | lista completa 5/10/0 (exec 31346) |
| A4 | suma asegurada | **FAIL-293** | «DM y RT aparecen como **valor convenido, no como una cifra**» — el dato EXISTE (`169200`) y nombra el tipo prohibido (`tipo_suma=2` sin nombre). RC 2.500.000 y GM 200.000 sí correctos (exec 31349) |
| A5 | «en caso de pérdida cuánto es» | **FAIL-293** | mismo patrón: «esa suma aparece como valor convenido, no como una cifra» (exec 31351) |
| A6 | «¿qué monto queda asegurado?» | **FAIL-293** | mismo patrón, tercera vez (exec 31354) |
| A7 | «¿hasta qué monto cubre un parcial?» | **FAIL-293** | **inventa**: «robo parcial no tiene tope… deducible del **25%**» — Robo Parcial NO está en la cotización y el 25% no sale de ninguna fuente. Reproduce el caso PROD del set (exec 31356) |
| A8 | «robo de partes aplica» | **PASS** | «protección opcional… no viene incluida automáticamente» (exec 31358) — correcto. **Ojo: A7 y A8 son el mismo tema con respuestas OPUESTAS en sesiones distintas — señal `#271`** |
| A9 | «¿qué coberturas trae mi póliza?» | **PASS** | exactamente las 6; sin añadidos (exec 31359; la marca «7» del runner era el «Audi Q7», falso positivo del regex) |
| A10 | «envíame todas las coberturas» | **PASS con observación** | las 6 con 5%/10%, sin deflexión — pero repite «las sumas aparecen como valor convenido, no como cifra» (exec 31361): el patrón de A4-A6 se cuela aunque aquí el set no lo tipifica |
| A11 | ¿las tres cotizaciones traen lo mismo? | **NO EJERCITABLE** | precondición = cadena de descuento; el claim de fase 2 deniega sesiones sintéticas (fence, execs 25350/25353). Solo medible en vivo |
| A12 | ¿cuándo empieza la cobertura? | **REGISTRAR** | bot: «se activa de inmediato tras confirmarse el pago» (KB K29). La cotización dice `fecha_inicio=2026-09-01` (ya pasada). El set lo prevé: difieren → registrar ambos y decide quien corresponda (exec 31364) |
| A13 | ¿contratar solo 6 meses? | **PASS** | «pólizas de 6 meses no; Semestral: $8.230,07 + $7.336,87» — cifras exactas de su cotización; el cese por impago que añade está acreditado (KB K22/CG 5ª) (exec 31365) |
| A14 | «primer pago 6.508,59 cubre 3 meses» | **PASS** | corrige al cliente con los datos reales: T = $4.647,60 + 3×$3.754,42, total $15.910,86 (exec 31367) |
| A15 | ¿limitada por 3 meses? | **PASS** | «anuales… la cobertura siempre aplica por 12 meses» (exec 31370) |

## Los tres hallazgos que importan

**1 · El patrón «valor convenido» es sistemático y es doble defecto (A4, A5, A6, eco en A10).**
El bot niega que exista la cifra de suma asegurada de DM/RT («no como una cifra») cuando
`coberturas_detalle[1].suma_asegurada=169200` está en su cotización, Y nombra «valor convenido»
— el nombre que `tipo_suma=2` no tiene en el catálogo. Cuatro respuestas de cuatro sesiones
distintas, mismas dos faltas. No es ruido: **es cómo está leyendo (o no leyendo) `suma_asegurada`
cuando `tipo_suma=2`**. Es el `#293` con raíz localizable.

**2 · Robo Parcial: el bot afirma con cifra inventada (A7) y a la sesión siguiente lo niega bien
(A8).** El 25% de A7 no existe en cotización, catálogo ni KB citada. La moneda al aire entre A7 y
A8 es además la firma del `#271`.

**3 · Un turno de cliente murió en `Detect Jailbreak` (A2, exec 31344, status=error).** «Y por ese
rubro yo pago el 5% de deducible?» no es un jailbreak: es una pregunta de deducible. El error no es
un bloqueo deliberado — la ejecución REVENTÓ y el cliente no recibe nada (silencio). Una sola
ocurrencia; no la generalizo, la dejo señalada con el exec delante. El reintento corrió… y
deflectó (FAIL-292).

## Método y residuo (declarados)

- Una frase por sesión limpia (14 sesiones, GO 31-ago); inyección firmada; **cero envíos** en
  todas las trazas (fencing intacto); cero escrituras de las vigiladas; checks duros del runner +
  revisión verbatim caso a caso (los veredictos de arriba son de la revisión, no del regex — dos
  falsos positivos del regex descartados y dos fallos que el regex no vio, cazados: A2-r2 y A12).
- **Residuo vivo declarado:** 14 sesiones `QA-SUITE-COB-*`, 66 filas en `n8n_chat_histories`,
  0 en dispatch. **No las borro aún**: si el grupo B va a necesitar sesiones frescas, las creo
  aparte y limpio todo junto con la sección LIMPIAR (IDs exactos) al cerrar el set. Si prefieres
  limpieza ya, es un comando.
- Runner nuevo `runners/cobertura_stg.js` + verdad en `fixtures/preguntas_cobertura_A.json`
  (commit en mi repo): rejugable para B/C/D con el mismo contrato.

```
🧪 QA REPORT — 4 sep 2026 · cobertura grupo A (STG, cotización 2307, versionId ec5052cf)
Triggered by: encargo Arquitecto 4-sep (set 50 preguntas cobertura, Mejoras)

✅ 8/14 PASS ejercitadas (A1, A3, A8, A9, A10*, A13, A14, A15) — *con observación
❌ 4 FAIL-293: patrón «valor convenido» niega suma_asegurada existente (A4, A5, A6) + robo
   parcial inventado con 25% sin fuente (A7)
❌ 1 FAIL-292: A2 deflecta al PDF teniendo el 5% en la cotización
⚠️ 1 error de grafo: A2 intento 1 murió en Detect Jailbreak (exec 31344) — turno sin respuesta
⚠️ 1 REGISTRAR: A12 (KB «inmediato» vs cotización 2026-09-01)
⛔ 1 no ejercitable: A11 (cadena de descuento imposible bajo el fence de fase 2)
📎 residuo declarado: 14 sesiones + 66 chat_histories, limpieza pendiente de cerrar el set
```

— Agente QA & Testing
