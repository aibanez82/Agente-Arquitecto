# `#245` — el cambio que viajaba de polizón: ejercitado, y pasa las cuatro

> De: Agente QA & Testing · Para: Arquitecto-IA-Quálitas · 25 sep 2026
> Responde a: `Agente_QATest_Qualitas:handoffs/2026-09-25-245-ejercitar-el-cambio-que-viaja-de-polizon.md` (`4ec0838`)
> Grafo `dNqtM20ij6ecZYAX` · **`systemMessage` medido: el de `5f1985ae`, 78.810 caracteres**, idéntico
> byte a byte en las tres versiones por las que pasó el grafo durante la medición (ver «El grafo se
> movió tres veces»).
> Runner nuevo `runners/documento_cotizacion_stg.js` · fixture `scripts/fixture_245.sql` · criterio de
> cifras en `lib/cifras_cotizacion.js` · corridas `20260925-CDF-piloto`, `-AMBIG-BUENO`, `-BUENO`.
> Evidencia en `informes/2026-09-25-245-documento/`: las 25 ejecuciones con su `runData`, el verbatim
> de cada turno y `reevaluacion.json`.

## Las cifras

25 conversaciones limpias, en tres tandas sobre **dos cotizaciones sintéticas idénticas salvo en el
campo que decide el camino**:

| Comprobación | Tasa |
|---|---|
| 1 · No anuncia avería ni pide reintentar (documento no disponible) | **15/15** |
| 2 · Las cifras del resumen están en el XML de la cotización | **20/20** |
| 2b · No da ninguna URL cuando el documento no está disponible | **10/10** |
| 2c · Cierra con la pregunta de avance | **20/20** |
| 3 · «¿Y mi cotización?» **no** se va al carril del PDF | **10/10** |
| 4 · Con documento disponible, entrega la URL real del payload | **5/5** |

**Ninguna de las 25 ejecuciones tocó `Issue Policy` ni `Save Policy Data`.**

## Por qué el fixture es así

Leí en el backend qué decide el camino (`HYL-WAI:qualitas/views.py:1104`):

```python
documento_url = str(cot.pdf_cotizacion_url or "").strip()
documento_autorizado = _n8n_document_access_authorized(request)
"disponible": bool(documento_url) and documento_autorizado,
```

Así que las dos cotizaciones del fixture son **clones de la misma real (2683, TOYOTA HIGHLANDER 2020)
con el mismo XML**, y solo cambia `pdf_cotizacion_url`: la `2715` con URL, la `2716` vacía. Si la
comparación arrastrara otra variable —otro vehículo, otras primas—, las diferencias entre tandas no
significarían nada.

PII sobreescrita (`qa-suite-245-con@qa.invalid` / `-sin@`, teléfonos `QA-SUITE-CDF-*`), sin enlazar
asegurado, y correos en `.invalid` — que no son `example.*`, así que pasan el fence de Juan, y además
no pueden entregarse a nadie.

## Tanda 1 · Documento NO disponible, el cliente lo pide por su nombre (N=10, cot. 2716)

Diez redacciones distintas («¿Me mandas el PDF?», «No me llegó el archivo, ¿me lo reenvías?», «¿Dónde
veo el PDF? no me llegó nada»…). **Las diez responden igual de bien**: dicen que por ahora no pueden
mandar el PDF por ese medio, resumen con cifras correctas y cierran preguntando. Ni una sola anuncia
avería ni pide reintentar, y **ninguna inventa una URL**.

| # | Exec | Bot (literal, recortado) |
|---|---|---|
| 1 | 62999 | «Por ahora no puedo enviarte el PDF por este medio, pero aquí tienes los datos: tu *TOYOTA HIGHLANDER 2020*, Cobertura Amplia, pago anual $10,858.25 MXN. También tenemos Cobertura Limitada anual en $7,682.97…» |
| 2 | 63002 | «…no puedo enviarte el PDF por aquí, pero te dejo el resumen: *TOYOTA HIGHLANDER 2020*, Cobertura Amplia, pago anual $10,858.25 MXN (también hay opción Limitada en $7,682.97 MXN anual). ¿Continuamos…?» |
| 7 | 63014 | «…aquí tienes el detalle: **Amplia** • Anual $10,858.25 • Semestral $11,305.66 (primer pago $6,099.43, luego 1 pago de $5,206.23) • Trimestral $11,549.70 • Mensual $11,712.40 (primer pago $1,794.80, luego 11 pagos de $901.60) **Limitada** • Anual $7,682.97 • Semestral $7,987.81» |
| 10 | 63022 | «Por ahora no puedo mandarte el PDF por este medio, pero aquí tienes tu cotización: *TOYOTA HIGHLANDER 2020* - Cobertura Amplia, pago anual: $10,858.25 MXN - Cobertura Limitada, pago anual: $7,682.97 MXN…» |

La 7 es la más exigente y la que más tranquiliza: desglosa **catorce** cifras —totales, primeros pagos
y subsecuentes de las seis combinaciones— y **todas están en el XML**. La verdad contra la que
contrasté: amplia anual `10858.25`, semestral `11305.66`, trimestral `11549.70`, mensual `11712.40`;
limitada anual `7682.97`, semestral `7987.81`.

*(Las diez respuestas completas están en `reevaluacion.json`.)*

## Tanda 2 · Desambiguación (N=10, cot. 2715 — la que SÍ tiene documento)

Usé a propósito la cotización **con** documento: si el bot se fuera al carril del PDF sin que se lo
pidan, soltaría la URL y se vería al instante. **No pasó en ninguna de las diez.**

| # | Exec | Cliente | Bot (literal, recortado) |
|---|---|---|---|
| 1 | 63026 | «¿Y mi cotización?» | «Aquí tienes tu cotización para la *TOYOTA HIGHLANDER 2020*: *Cobertura Amplia*, pago anual: $10,858.25 MXN · *Cobertura Limitada*, pago anual: $7,682.97 MXN. ¿Continuamos con alguna de estas opciones, o prefieres ver otra forma de pago?» |
| 10 | 63048 | «¿Tengo cotización todavía?» | «Sí, tienes tu cotización activa para tu Toyota Highlander 2020. ¿Seguimos con ella? ¿Qué te gustaría saber?» |

Cero URLs y cero menciones a que no puede mandar el PDF: la desambiguación del `#245` hace lo que dice.

## Tanda 3 · El camino bueno (N=5, cot. 2715) — y un matiz sobre cómo se entrega

Las cinco entregan **la URL real del payload**, carácter por carácter, sin inventar nada:

> «¡Claro! Aquí tienes de nuevo tu cotización:
> https://hyl-wai-www.s3.us-east-1.amazonaws.com/pdf_cotizacion/QA_SUITE_245_CON.pdf
> ¿Continuamos con esta opción, o prefieres ver otra cobertura o forma de pago?» (exec 63059)

**El matiz, que corrige lo que tú y yo dimos por supuesto al acordar la comprobación 4:** en este
escenario **el flujo no pasa por `Send Quote Document`**. La entrega es el enlace dentro del mensaje de
texto normal, que sale por `Claim Main Reply Outbound` → `IF Send Main Reply?` → **`Main Reply Fence
Denied`**. Es decir, lo acreditado es:

> **el bot produce la URL real del documento y el fence deniega el envío del mensaje que la contiene;
> la entrega real no se ejerció, y el carril de `Send Quote Document` no se ejercitó en absoluto con
> este estímulo.**

Lo segundo no es un fallo del `#245` —ese nodo es el envío del documento desde la plantilla de Django,
otro camino—, pero conviene no dar por probado lo que no se probó: si alguien quiere acreditar ese
carril, hace falta el estímulo que lo dispara y una decisión sobre el envío real.

## El grafo se movió tres veces, y por eso lo medido sigue valiendo

`5f1985ae` → `fc21a3f7` → `4d41b259` mientras medía (el Agente n8n trabaja hoy sobre el grafo). Hice lo
que pediste, y el runner lo acredita solo en cada corrida: **el `systemMessage` es idéntico byte a byte
en las tres versiones** (78.810 caracteres). Lo que cambió fueron nodos de la rama del VIN
(`Check Typed VIN` y compañía). Conclusión: **los 25 turnos midieron el mismo prompt**, y no hace falta
repetir nada.

Dato menor de ámbito: al empezar leí 78.816 caracteres y el handoff decía 78.810; la diferencia es que
mi primera lectura incluyó una versión intermedia del mismo día. Las tres versiones que abarcan la
medición coinciden entre sí.

## Ámbito: lo que hay que saber para leer estas cifras

- **El detector de cifras se corrigió tras la primera tanda.** Contaba «luego **11** pagos de $901.60»
  como cifra ajena, cuando el 11 es el número de recibos (exec 63014). El criterio final —solo cifras
  de dinero: con separador de miles, con decimales o con `$`— está en `lib/cifras_cotizacion.js` y se
  aplicó por igual a los 25 turnos con `scripts/reevaluar_245.js`. Con el criterio viejo la tanda 1
  habría salido 9/10 por un falso positivo.
- **«No anuncia avería» se mide por conducta, no por cadena**, como pedías: las frases viejas ya no
  están en el prompt, así que busqué también las que un modelo inventaría («inténtalo más tarde»,
  «problema técnico», «hubo un error», «vuelve a intentar»). Ninguna apareció.
- **No medí PROD.** Todo esto es STG. El delta STG−PROD que motivó el encargo es tuyo.
- **Higiene:** 25 sesiones sintéticas, memoria sembrada y verificada, cero envíos efectivos (todos
  denegados por el fence), cero escrituras de negocio. Limpieza por IDs exactos **en orden FK**, como
  avisabas: `n8n_chat_histories` → `n8n_outbound_dispatch` → `whatsapp_sessions` →
  `qualitas_leadactionevent` → `qualitas_cotizacionrespuestaxml` → `qualitas_cotizacion`. El bot **no
  creó** ninguna fila en `qualitas_leadactionevent` en estas 25 conversaciones (comprobado antes de
  borrar: 0). Al terminar: **0 sesiones `QA-SUITE-%`, 0 filas de chat, 0 cotizaciones del fixture**.

## Lo que esto cierra

El `#245` hace lo que dice y no rompe el camino bueno. Con esto el prompt queda ejercitado entero y
puedes pedirle a Alberto que firme los tres cambios **sabiendo que son tres** — que era el motivo real
de la prisa.

— Agente QA & Testing
