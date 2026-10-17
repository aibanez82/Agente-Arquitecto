# n8n · A → Arquitecto: firma 40 (CP de otra residencia, doble deducible). Medición y propuesta de mecanismo

**Fecha:** 17-oct-2026 · **Orden:** `Agente-n8n:handoffs/2026-10-14-A-firmas-orden-prod-591-y-cola.md`, adenda 15 (`f0655af3`).

**No he tocado nada. 0 llamadas a modelo.** He leído:
- el bot vivo de STG (`606da14f`);
- en PROD, solo lectura: `n8n_chat_histories`, `qualitas_cotizacion` y `qualitas_sepomex`.

**Orden en la cola:** va detrás del E2E del `#551`. La 39 queda firmada y la 38 no la toco.

## Respuesta corta: comparte carril con el `#608`, pero necesita su propio detector

- **El detector del `#608` (`detectaCp608`) no sirve para este caso.** Solo salta con un CP de 5 dígitos o con «código postal». Ninguno de los tres mensajes de `waq_4500` habla del CP:
  - 16339: «Puedes respetar elmprecio andando en otra ciudad».
  - 16343: «Con placas de estado de México».
  - 16345: «Cambie de placas / Del estado de México».
- **El carril del `#608` sí sirve entero:**
  - `IF CP 608?` → `CP 608 Copy` → Claim → `Persist Human Row (CP 608)` → `Marca CP 608` → la pausa del `#577`.
  - `Marca CP 608` escribe `cp_distinto` + `emision_bloqueada`. Así no se emite con el CP equivocado, y la pausa deja la sesión a la persona. **Eso cumple también el `#610`**: con la sesión en pausa, el bot no le pide datos.
  - La marca es la misma para los dos casos, así que **solo hay una derivación por sesión**, sea por CP o por residencia.
  - La marca se limpia en los mismos casos que hoy: otra cotización, o el cliente confirma su CP.

## Mecanismo propuesto
1. **Fuente.** Una columna escalar en `Resolve Session`, junto a `cotizacion_cp` (`#608`): `cotizacion_estado`, por subconsulta a `qualitas_sepomex`.
   - Medido en PROD: ningún CP tiene más de un estado.
   - Las 957 cotizaciones de los últimos 30 días tienen su CP en `sepomex`.
2. **Detector puro** `detecta40(texto, estadoCotizado)`. Iría en un fichero fuente propio, copiado literal en `Merge Session Data` como el `#608`. Tres formas:
   - **Otro lugar sin nombre:** «vivo / radico / me mudé / circulo / ando / andando / manejo …» seguido, a 30 caracteres o menos, de «otro estado / otra entidad / otra ciudad / fuera del estado».
   - **Placas de otro estado:** «placas … de otro estado / foráneas».
   - **Estado con nombre,** distinto del de la cotización, con 32 estados y alias (CDMX, DF, Edomex…). Solo cuenta si va con un verbo de residencia («vivo en Jalisco») o de **cambio** de placas («cambié de placas … del estado de México»).
3. **Dentro de `cp608()`.** Si `detectaCp608` no salta, se mira `detecta40`.
   - Con `detectaCp608` primero, gana el CP explícito.
   - Si salta `detecta40`:
     - va la copia firmada de la 40 con el enlace del `#608` (o el marcador del `#257` si no hay atención humana);
     - la marca lleva `motivo='otra_residencia_40'` y `cp_cliente` vacío;
     - el `emision_bloqueada.code` sigue siendo `cp_distinto`.
4. **El modelo no parafrasea.** El turno lo contesta entero el grafo, como el `#608`.

## Batería contra el corpus de PROD (sin modelo)
- Busqué mensajes humanos de PROD con un filtro ancho («otro estado», «otra ciudad», «placas», «vivo en», «me mudé», «radico», «Edomex», «CDMX», «circul», «ando en»…). Salen **168**.
- **El detector salta en 2 de los 168,** y los dos son de `waq_4500`: el 16339 («otra ciudad») y el 16345 (cambio de placas al Estado de México, con una cotización de Nuevo León). La derivación saldría en 16339, el primer turno.
- **No salta**, que es lo que quiero:
  - direcciones con «Estado de México» o «CDMX» en la captura de datos;
  - placas dictadas con su estado («MZU-052-B del estado de México»);
  - «[FOTO_VIN] … placas detectadas»;
  - «Tiene cobertura en USA? Vivo en Frontera»;
  - «Voy a recaudación para comprar las placas»;
  - una petición de RC «para CDMX y estado de México».
- **Sintéticos.** Saltan:
  - «Ahora vivo en Jalisco», con una cotización de Nuevo León;
  - «me mudé a otro estado»;
  - «circulo en otro estado».

  No saltan:
  - «vivo en CDMX», con una cotización de CDMX;
  - «voy de viaje a Puebla, me cubre?»;
  - «Placas … del estado de México», con una cotización de CDMX.

## Lo que necesitas decidir
1. **¿Cuenta «otra ciudad»?** La firma dice «otro estado», y otra ciudad puede estar en el mismo estado. Pero el caso real que la motiva (16339) dice «otra ciudad», y el texto firmado es condicional («Si ahora vives en otro estado…»).
   - Mi propuesta: sí, junto a verbos de vivir o circular.
2. **Placas de otro estado sin cambio.** «Con placas de estado de México» (16343), con una cotización de Nuevo León, no salta por sí sola.
   - Es deliberado. Sin un verbo de cambio, las placas de otro estado son muy comunes en la zona CDMX ↔ Edomex. Saltaría con cada dictado de placas.
   - En `waq_4500` no cambia nada: la derivación ya sale en 16339.
   - ¿Lo dejamos así?
3. **«Nunca afirmar que el precio no cambia».** El grafo lo garantiza en el turno que detecta. **Si el detector no salta**, el modelo puede volver a decirlo, como en 16342 con la KB del doble deducible.
   - Mi propuesta: una línea en el `systemMessage` de los dos agentes («Nunca digas que el precio no cambia si el cliente vive o circula en otro estado: el precio se calcula con el CP de su residencia»).
   - Es prompt, y necesita la firma de Alberto o tu orden de que la regla firmada ya la cubre.
   - **Sin guarda de salida**, por el `#179`, hasta que el arnés la justifique.
4. **Dependencia de PROD.** El `#608` **no está en PROD**: `TEXTO_608` no aparece en el bot `1265f994`. La 40 se apoya en su carril, así que viaja con el `#608` o después.

**Arnés:**
- Primero, la batería offline: el detector en node contra los 168 mensajes más los sintéticos, y el SQL con `ROLLBACK`.
- Después, **3 casos con N≤3**: 16339, 16345 y «Ahora vivo en Jalisco».
- **Más una regresión N=1**: un dictado de placas con estado en la captura de datos.
- **Unas 30 llamadas o menos.**

Agente n8n · A
