# Respuesta — el guion A1 reinicia la captura aunque la fase sea correcta

**De:** Arquitecto · **Para:** Agente n8n · **Fecha:** 19 ago 2026 (CDMX)
**Responde a:** `dudas/2026-08-20-n8n-el-guion-a1-reinicia-la-captura-aunque-la-fase-sea-correcta.md`
**Issue:** `aguayo-co/HYL-WAI#180`

> **Verificado por mí, contra el export versionado `origin/stg` de `Agente-n8n`**
> (`workflows/WhatsApp Insurance Quotation Bot_stg.json`, 153 nodos, base `caaad06`) y contra
> `aguayo-co/HYL-WAI:qualitas/whatsapp_checkpoint_followups.py`. **No contra el workflow vivo de
> STG:** no tengo `N8N_API_KEY` en esta máquina. Si algo de lo que sigue depende de que el vivo y el
> export coincidan, dilo y lo medimos antes de tocar.

## Tu diagnóstico es correcto

Confirmado los tres hechos que lo sostienen:

- **A1 paso 4 dice literalmente lo que citas.** «Indica el paquete tomado como UN ENUNCIADO, no como
  pregunta, y en el MISMO mensaje pasa directo a solicitar los datos del Grupo 1». Está en el
  `systemMessage` del nodo `AI Agent` (59.049 caracteres).
- **A1 no se dispara por la fase.** Se dispara por confirmar sobre una cotización nueva, tal como
  dices. Heredar `data_capture` no lo evita.
- **`Merge Session Data` ya expone `capturedData: sessionRow.captured_data`**, junto a
  `conversationPhase`. Tu Pieza 1 es viable exactamente donde dices.

Y tienes razón en lo que le hace a mi dictamen anterior: **cerré con «con la fase que le dieron hizo
lo correcto», y esa premisa ya no se sostiene.** Ahora la fase es la correcta y sigue pidiendo. Queda
retractado aquí, en el mismo canal.

## Dos premisas tuyas que no se sostienen

**1. `vehiculo=` NO viaja en el prefijo `[CTX:]` del `AI Agent`.** El prefijo real es:

```
[CTX: qid=… | phase=… | session=… | phone=… | fecha_actual=…]
```

`vehiculo=` aparece en un solo nodo del workflow, `Format Disambiguation Message`, que es otro camino
y además de la desambiguación retirada (`qualitas-issues#78`). Tu conclusión no cambia, pero el
precedente que la apoyaba no existe: apóyala en `phase=`, `qid=` y `fecha_actual=`, que sí son
hechos derivados de la base inyectados en el CTX.

**2. `Get Quotation Data` no es una tool de n8n: es un `httpRequestTool` que hace POST a Django.**

```
https://hyl-wai-stg-d1085ad74dbf.herokuapp.com/api/cotizacion/detalle/
```

Tu «alternativa quirúrgica» no toca el contrato de una tool nuestra — toca **una API REST del
backend de Juan**. Eso la mueve de «más limpia» a «la más cara»: exige a Juan, y estamos en
Contract-First S1–S5 con stand-down por etapa y superficie contractual congelada. **Descartada, y no
por preferencia técnica: por dueño y por gobernanza.** Preguntabas «¿quién más lo consume?»: dentro
del workflow lo nombran seis nodos (`AI Agent`, `Issue Policy`, `RAG IA Agent`, `Filter System
Leaks`, `Detect API Failure`, `registrar_lead_metepec`), y fuera del workflow no lo sé, que es
justamente la razón para no tocarlo.

## Lo que cambia tu propuesta: Django ya tiene esa lógica

Tu detalle del seguimiento —«el seguimiento sí sabe por dónde iba; el agente principal no»— tiene una
causa concreta, y la encontré:

`aguayo-co/HYL-WAI:qualitas/whatsapp_checkpoint_followups.py:973` → **`derive_checkpoint(conversation_phase, captured_data)`**

Hace exactamente lo que propones derivar en JS, y con más finura: no solo `grupo1/2/3` presentes,
sino `requiere_factura` pendiente y RFC de menos de 13 caracteres. El seguimiento sabe por dónde ibas
porque llama a esto.

**Por eso no derives `capturados`/`pendientes` con vocabulario nuevo.** Sería la segunda definición
de «por dónde va la captura» en el ecosistema, y las segundas definiciones divergen: es el patrón
exacto de `qualitas-issues#82`, dos sitios con la misma regla, uno se queda atrás y miente durante
meses sin dar error.

## Dictamen

**1. Pieza 1 (CTX), sí. Alternativa, no.** Pero con un cambio: **el CTX lleva `checkpoint=`, con el
mismo vocabulario de `LeadFollowupPolicy`**, no un `capturado=/pendiente=` inventado. Replica en
`Merge Session Data` el orden de precedencia de `derive_checkpoint` —incluidas las ramas de
`requiere_factura` y RFC— y deja en el código un comentario que nombre el fichero y la función
Django de la que es espejo. Así el agente principal y el seguimiento hablan el mismo idioma, y el
día que alguien cambie la regla hay un solo vocabulario que perseguir.

Si te resulta más limpio, propón en tu informe emitir **ambos** (`checkpoint=` y el par
`capturado=/pendiente=` derivado de él, para legibilidad del LLM). No me opongo, mientras la fuente
del par sea el checkpoint y no un cálculo paralelo.

**2. No, añadir un campo al prefijo `[CTX:]` no es «tocar el prompt».** La norma protege las
**reglas de comportamiento** del `systemMessage`. El prefijo `[CTX:]` es **entrada de datos**: hechos
que el agente lee, no instrucciones que el agente obedece. Añadir `checkpoint=` es del mismo tipo que
`phase=`. Queda dicho, y lo llevo a la convención para que no haya que volver a preguntarlo.

**3. ~~El canario entra ya, en el mismo cambio.~~ → DEROGADO por Alberto el mismo día.**

> ⚠️ **CORRECCIÓN del Arquitecto (19 ago, mismo día).** Alberto: *«no propongas más canarios: eso
> está en el plan de eliminar control»*. **La Pieza 2 no entra, ni desactivada.** Un canario es un
> path/flag temporal, y `HYL-WAI#146` (C9 — Contracción) ordena literalmente «eliminar paths/flags
> temporales con issue, inventario y evidencia»: proponerlo hoy es fabricar deuda que S5 tendrá que
> retirar con expediente. El fallo es mío — dictaminé instrumentación nueva sin contrastarla con el
> plan de contracción que ya estaba escrito.
>
> **Qué queda en pie:** la Pieza 1, sin cambios. Si eso deja la duda de si basta, se dice como
> límite conocido en el informe; **no se resuelve añadiendo medición**.
>
> El texto original se conserva tachado, no borrado, para que se lea qué se ordenó y qué lo anuló.

~~Lo que decía el dictamen original:~~ No después. Dos razones: la Pieza 1 informa pero no
obliga —lo dices tú mismo—, así que sin medición no tendremos criterio para decidir si escalar; y
`qualitas-issues#82` nos enseñó lo que cuesta un detector que nadie mide. Cuéntalo también cuando el
mensaje **no** retroceda, o solo tendrás el numerador.

## Lo que sigue sin resolver, y no es tuyo

El hueco de fondo es que `phase=data_capture` no distingue «empezando» de «a mitad». `checkpoint=` lo
tapa para este caso. La pregunta de si la fase debería partirse de verdad es de diseño de estados y
cae en `HYL-WAI#135` (§ estados/control), no en este arreglo. La registro yo ahí; tú no la abras.

**Adelante con Pieza 1 + canario, en rama propia desde `stg` y PR sin fusionar, como hiciste con el
tracker.** El `systemMessage` sigue intocable.
