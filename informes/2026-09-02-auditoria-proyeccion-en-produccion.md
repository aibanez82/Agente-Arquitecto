# Auditoría de la proyección de estados del lead en PRODUCCIÓN — los 1.346 del cutover

> De: Agente QA & Testing · Para: Arquitecto-IA-Quálitas
> Responde a: `handoffs/2026-09-02-auditoria-proyeccion-en-produccion.md`
> **Solo lectura cumplida: cero INSERT/UPDATE, cero DDL. La sesión de Postgres se abrió con
> `default_transaction_read_only=on`, así que un write habría fallado por construcción. Residuo: ninguno.**
> Fuentes: Postgres de PROD (la `DATABASE_URL` de `hyl-wai-production`, cotejada contra la config var
> vía API de Heroku, GET) · código en `aguayo-co/HYL-WAI@9105f92f` (= release v382, el deploy vigente
> en PROD desde el 2-sep 04:03Z; citado con `git show 9105f92f:…`) · config vars de
> `hyl-wai-production` vía API de Heroku (GET).
> Medición: 2 sep 2026, ~22:0x UTC. Base: **1.349 leads** (1.346 convertidos + 3 nuevos post-cutover).

## Respuesta corta a las tres preguntas

- **(a)** **90 leads infra-declarados con tu criterio fijado, literal** — 89 en `COTIZACION_GENERADA`
  y 1 en `LEAD_CREADO`. Es el **6,7% de los 1.346** frente al **27,6% de STG** (34/123): **crece en
  absoluto, cae mucho en proporción** — y cambia de naturaleza: los de STG eran mayormente teléfonos
  de prueba; estos son clientes reales. **El criterio no encaja del todo en PROD** (hay una fase
  `completed` que en STG no existía): con el criterio ajustado que la cuenta salen **105**. Las dos
  cifras van abajo, separadas.
- **(b)** **Cero contradicciones duras**, en cinco cruces (los cuatro de STG más un quinto de
  retroceso contra el ledger). Todos a cero.
- **(c)** **Confirmado en PROD, y con una consecuencia que en STG no se veía:** la reproyección usa
  solo hechos durables de Django (verificado en el código desplegado `9105f92f`, que no lee
  `whatsapp_sessions` ni `captured_data`) y por eso el cutover **degradó a 125 leads** que en el
  vocabulario viejo estaban en `DATOS_EMISION_*` hasta `COTIZACION_GENERADA`/`LEAD_CREADO`. Hoy
  124 siguen en `COTIZACION_GENERADA` y 1 en `LEAD_CREADO`: **ninguno ha remontado**.

**Y sobre tus dos hechos del §5: el de `PAGO_PENDIENTE` se confirma por tres vías. El de
`POLIZA_EMITIDA` se confirma en el fondo con un matiz en la letra que te va a interesar: las ligas
no faltan — existen y están en `failed`. La generación de la liga es lo que revienta.** Detalle abajo.

---

## Ámbito y método

- Tablas leídas: `qualitas_lead` (1.349), `whatsapp_sessions` (1.111 sesiones, 647 con `lead_id`),
  `qualitas_polizaemitida` (61), `qualitas_leadfunnelevent` (1.361 = 1.346 `cutover_convertido` +
  15 orgánicos), `qualitas_receiptpaymentlink` (10), `qualitas_leadfunnelcutovercontrol` (1).
- Cutover en PROD: `mode=COMPLETED`, run `47620663-5125-4d30-9cce-c9b703ddc8f2`,
  eventos escritos entre las **18:20:52Z y las 18:21:06Z del 1-sep**, `expected_fingerprint ==
  applied_fingerprint`. Las 5 flags `LEAD_FUNNEL_*` de `hyl-wai-production` en `true`
  (incluida `LEAD_FUNNEL_S2_PROJECTION_ENABLED`).
- El deploy vigente (`9105f92f`) es **posterior** al que ejecutó el cutover (release 382, 2-sep
  04:03Z; el cutover corrió el 1-sep bajo el release anterior). Cito el código vigente; la mecánica
  de `_projection_for_lead` es la misma que auditée en STG.

## (a) ¿Cuántos leads están infra-declarados? — las dos cifras

**Criterio fijado (el de STG, literal):** sesión WA con `captured_data` no vacío **o** fase en
`data_capture`/`summary_confirmation`/`policy_issuance`/`payment_pending`, y lead en
`COTIZACION_GENERADA`/`LEAD_CREADO`. Cruce por `whatsapp_sessions.lead_id`.

| Criterio | Leads | % de 1.346 |
|---|---|---|
| **Original (fijado en el handoff)** | **90** (89 CG + 1 LC) | **6,7%** |
| Ajustado: + fase `completed` como avanzada | **105** | 7,8% |

**Por qué el ajuste:** en PROD existe la fase `completed` (38 sesiones), que en el vocabulario de
STG del 1-sep no aparecía. Es ambigua desde los datos: de los leads con sesión `completed`,
7 están en `PAGO_CONFIRMADO` (ahí "completed" = compró) y 16 en `COTIZACION_GENERADA` (¿conversación
terminada sin compra, o progreso perdido?). Por eso no la metí en la cifra principal y la doy aparte:
**+15 leads** (los `completed` sin captura; el 1 con captura ya cuenta en la original).

**Desglose de los 105, por fase más avanzada del lead** (ámbito: leads en CG/LC con alguna sesión
enlazada, fase máxima por rango, `updated_at` como desempate):

| Fase | Con captura | Sin captura |
|---|---|---|
| `policy_issuance` | 6 | 0 |
| `summary_confirmation` | 6 | 0 |
| `completed` | 1 | 15 |
| `data_capture` | 14 | 54 |
| `greeting` | 9 | — |

**`payment_pending`: cero leads en CG/LC.** Los peores casos de STG (sesión en `payment_pending`
con lead en `COTIZACION_GENERADA`) en PROD no existen: el cutover llevó esos leads a
`PAGO_PENDIENTE` (19 por `COTIZACION_INICIADA→PAGO_PENDIENTE` y 14 por `POLIZA_EMITIDA→…`).

**Casos concretos, los de más recorrido** (sesión = teléfono real del cliente; lo enmascaro aquí,
el `lead` y la `cotización` bastan para localizarlo):

| Lead | Estado | Cotización | Fase de la sesión | Captura |
|---|---|---|---|---|
| 1418 | `COTIZACION_GENERADA` | 2870 | **policy_issuance** | sí |
| 1567 | `COTIZACION_GENERADA` | 3019 | **policy_issuance** | sí |
| **1818** | **`LEAD_CREADO`** | 3270 | **policy_issuance** | sí |
| 1905 | `COTIZACION_GENERADA` | 3357 | **policy_issuance** | sí |
| 2059 | `COTIZACION_GENERADA` | 3511 | **policy_issuance** | sí |
| 2068 | `COTIZACION_GENERADA` | 3520 | **policy_issuance** | sí |
| 1325, 1329, 1423, 1437, 1668, 1685 | `COTIZACION_GENERADA` | 2777, 2781, 2875, 2889, 3120, 3137 | summary_confirmation | sí |

El **1818** es el más elocuente: el Dashboard lo pinta como `LEAD_CREADO` —ni cotización enseñada—
y su conversación está **emitiendo póliza**.

## (b) Contradicciones duras — cinco cruces, los cinco a cero

Ámbito: los 1.349 leads contra `qualitas_polizaemitida` (por `poliza_id` o `cotizacion_id`) y contra
el ledger completo.

| Cruce | Resultado |
|---|---|
| Póliza emitida con lead por debajo de `POLIZA_EMITIDA` | **0** |
| Póliza `PAGADO`/`fecha_pago` con lead ≠ `PAGO_CONFIRMADO` | **0** |
| Lead en `POLIZA_EMITIDA`/`PAGO_PENDIENTE`/`PAGO_CONFIRMADO` sin póliza detrás | **0** |
| Lead `PAGO_CONFIRMADO` sin póliza `PAGADO` | **0** |
| Retroceso: estado actual por debajo de algún `resulting_state` aplicado en su ledger | **0** |

Coherente con la construcción que ya cité en STG (escritor autorizado + monotonía por
`S2_STATE_RANK`); en PROD además lo respalda el dato: 25 leads `PAGO_CONFIRMADO` y 25 pólizas
`PAGADO`, cuadran uno a uno por el cruce b4.

## (c) La reproyección: misma profundidad que en STG, y en PROD se ve el coste

**Reproyectó todo y bien, formalmente:** 1.346/1.346 eventos `cutover_convertido`, y **cero** leads
cuyo estado actual difiera del `resulting_state` de su conversión sin un evento orgánico aplicado
posterior. El vocabulario viejo no existe ya en `qualitas_lead.estado`.

**Pero la profundidad de evidencia es la que medí en STG**, ahora verificada sobre el código
desplegado: `_projection_for_lead` (`qualitas/lead_funnel_cutover.py:237` en `9105f92f`) deriva de
XML de cotización, ledger, `Asegurado`, póliza y ligas — **cero lecturas de `whatsapp_sessions` o
`captured_data`** (grep sobre el fichero completo en ese commit). La docstring sigue diciéndolo:
«without trusting legacy text» (línea 510).

**Lo que en STG era un matiz en PROD es una degradación medible.** Mapeo del cutover (completo):

| `previous_state` (viejo) | `resulting_state` (S2) | Leads |
|---|---|---|
| `COTIZACION_INICIADA` | `COTIZACION_GENERADA` | 1.135 |
| **`DATOS_EMISION_INICIADOS`** | **`COTIZACION_GENERADA`** | **108** |
| `COTIZACION_INICIADA` | `LEAD_CREADO` | 25 |
| `PAGO_APROBADO` | `PAGO_CONFIRMADO` | 19 |
| `COTIZACION_INICIADA` | `PAGO_PENDIENTE` | 19 |
| **`DATOS_EMISION_COMPLETADOS`** | **`COTIZACION_GENERADA`** | **16** |
| `POLIZA_EMITIDA` | `PAGO_PENDIENTE` | 14 |
| `COTIZACION_INICIADA` | `PAGO_CONFIRMADO` | 4 |
| resto (5 mapeos, incl. **`DATOS_EMISION_COMPLETADOS→LEAD_CREADO`**, 1) | | 5 |

Los marcados suman **125 leads que declaraban datos de emisión en curso o completados y hoy
figuran como si solo tuvieran cotización (124) o ni eso (1)**. Ninguno ha remontado orgánicamente
al 2-sep. Solo 8 de los 125 caen también en el criterio de sesión de (a): **son poblaciones casi
disjuntas** — (a) mide conversación no proyectada; esto mide texto legado deliberadamente
descartado. Si quieres una cota de «pintados más fríos de lo que estuvieron», la unión es
**207 leads** (90 + 125 − 8 solapados), con los dos ámbitos ya dichos.

**La proyección orgánica post-cutover funciona — con testigo real, lo que en STG no tenía:** los
3 leads nuevos (2075, 2076, 2077) escriben sus eventos con evidencia y transición aplicada:
`lead_creado → cotizacion_generada → interes_confirmado` los tres, y el **2076 llegó hasta
`POLIZA_EMITIDA` en vivo** (cadena de 6 eventos, `django`/`n8n_persisted_signal`, 1-sep
22:59→23:21Z). El lead **2074** (creado 17:48Z, 32 min antes del cutover) tiene sus 3 eventos con
`transition_applied=false` — el mismo gate pre-`COMPLETED` que expliqué en STG, luego su conversión
lo recogió. Coherente, no defecto.

## Tus dos hechos del §5 — uno confirmado, el otro confirmado con matiz que importa

**`PAGO_PENDIENTE` no lo produce ningún lead nuevo — CONFIRMADO por tres vías:** (1) los 34 leads
en `PAGO_PENDIENTE` tienen todos `cutover_convertido` con ese `resulting_state`; (2) eventos
orgánicos `pago_pendiente` en todo el ledger de PROD: **cero**; (3) leads creados tras el cutover
en ese estado: **cero**.

**`POLIZA_EMITIDA` es una alarma — CONFIRMADO en el fondo, pero «sin liga» no es exacto y la
diferencia señala la causa.** Los 2 leads en `POLIZA_EMITIDA` (1856, del cutover; 2076, orgánico
de anteayer) **sí tienen fila en `qualitas_receiptpaymentlink` — con `status='failed'`,
`generated_at` NULL**: la generación murió en `fareceipt_transport_pre_gen` (1856) y `fareceipt`
(2076). Nunca hubo URL. Y eso conecta tus dos hechos: `pago_pendiente` exige liga **activa**, y en
los dos únicos casos observables de PROD la liga **falla al generarse** — mecanismo distinto al de
STG (allí sospechábamos del recibo pagado a los 2 segundos). Con n=2 no generalizo: lo dejo como
hipótesis con sus dos filas delante. Contexto de la tabla entera (10 filas): 5 `failed` (todas
`fareceipt*`), 4 `expired`, 1 `active` — y la única activa es un recibo subsecuente del lead 1390,
ya `PAGO_CONFIRMADO` (por monotonía no proyecta nada; coherente).

## Hallazgos laterales

- **`fecha_actualizacion` también es ciega en PROD:** el cutover avanzó el estado de cientos de
  leads y **cero** filas tienen `fecha_actualizacion` en la ventana 18:00–19:00Z del 1-sep. La
  fuente temporal de estados sigue siendo `qualitas_leadfunnelevent.created_at`, como en STG.
- **`pago_observado`: cero eventos en todo PROD.** En STG tampoco había; sigue sin existir la huella
  entre emitir y cobrar (con solo 2 emisiones observables post-ledger, poco testigo aún).

## Lo que NO pude comprobar (declarado)

1. **La semántica de la fase `completed`** — desde los datos es ambigua (7 compraron, 16 no); no
   audité el código conversacional que la asigna. Por eso doy doble cifra en (a) en vez de decidir yo.
2. **Que los 90 estén «calientes» de verdad:** el criterio mide forma (captura/fase), no leí el
   contenido de las 90 conversaciones una a una. Los 12 casos concretos listados sí los verifiqué
   fila a fila.
3. **La causa raíz del `failed` en `fareceipt*`**: es hallazgo de datos; el código del transporte de
   recibos no estaba en el alcance de esta orden. Si lo quieres perseguido, es encargo aparte.
4. **`occurred_at` vs realidad** en los eventos orgánicos: doy fe del registro, no del instante.

```
🧪 QA REPORT — 2 sep 2026 · auditoría proyección #135 (PRODUCCIÓN, solo lectura)
Triggered by: handoff 2026-09-02-auditoria-proyeccion-en-produccion.md

✅ (b) 0 contradicciones duras en 5 cruces (1.349 leads, 61 pólizas, ledger completo)
✅ (c) cutover COMPLETED 1.346/1.346, fingerprints iguales, 0 divergencias sin evento posterior
✅ proyección orgánica CON testigo real: 3 leads post-cutover, 2076 hasta POLIZA_EMITIDA en vivo
✅ §5-2 confirmado ×3: PAGO_PENDIENTE solo por conversión (34/34), 0 eventos orgánicos, 0 leads nuevos
⚠️ (a) 90 leads infra-declarados criterio original (6,7% de 1.346; STG 27,6%) · 105 con fase
   'completed' (nueva en PROD) — clientes reales, casos top: 1818 (LEAD_CREADO emitiendo póliza)
⚠️ (c) 125 leads DEGRADADOS por el cutover desde DATOS_EMISION_* a CG/LC; 0 han remontado;
   unión con (a) = 207 leads pintados más fríos de lo que estuvieron
⚠️ §5-1 matiz: las ligas de los 2 POLIZA_EMITIDA no faltan — existen en status='failed'
   (fareceipt*); la generación de liga rota parece ser lo que bloquea pago_pendiente orgánico (n=2)
⚠️ fecha_actualizacion ciega también en PROD; pago_observado: 0 eventos
```

— Agente QA & Testing
