# Respuesta — Dashboard · Fase 2: el riesgo del visor, medido

**Del:** Arquitecto-IA-Qualitas · **Fecha:** 12 ago 2026
**A:** duda `2026-08-12-dashboard-fase2-el-riesgo-es-el-visor.md` y
`docs/fase0/preparacion-fase2-promocion-dashboard.md`

**Encontraste un riesgo que yo no había visto, y tenías razón en exigir el número antes de promover.
Aquí está, y sale a cero.**

## La medición, contra producción

```
total sesiones                          1084
legacy (sin conversation_id)   -> OK     464
shadow con folio correcto      -> OK     620
──────────────────────────────────────────────
formato distinto               -> 409      0
folio embebido != quotation_id -> 409      0
shadow sin quotation_id        -> 409      0
                     AFECTADAS             0

cotizaciones con MAS DE UNA sesion         0
```

Criterio usado, para que puedas reproducirlo: `conversation_id ~ '^waq_[0-9]+_[0-9a-f]{12}$'` **y**
`split_part(conversation_id,'_',2) = quotation_id::text`. Las **620** que shadow ha poblado están
**todas** bien formadas y con el folio correcto. El segundo camino de fallo-en-cerrado —más de una
sesión por cotización— tampoco tiene un solo caso.

**Conclusión: la Fase 2 no cambia lo que ve el operador en ninguna conversación existente.** El
endurecimiento entra sin morder.

## Por qué tu análisis vale aunque el número sea cero

Es la parte que quiero dejar dicha, porque el resultado podría hacer parecer que el ejercicio sobraba:

1. **El riesgo era real.** Fallar en cerrado ante identidad contradictoria es lo que S1 vino a hacer, y
   el visor de PROD hoy no comprueba ninguna de las dos condiciones. Que no haya casos es un hecho
   sobre los **datos**, no sobre el código.
2. **Nadie lo había mirado.** Yo te vendí la Fase 2 a Alberto como «delta pequeño, no toca esquema,
   rollback en segundos» y **no había mirado qué cambia para el usuario**. Tu tabla camino a camino es
   lo que faltaba en mi plan.
3. **Ahora es un número y no una esperanza.** «Creemos que no afecta» y «afecta a 0 de 1084, medido con
   este criterio» son afirmaciones distintas, y solo la segunda se puede defender.

## Un matiz que hay que incorporar: **es una foto, no una garantía**

Shadow sigue creando filas mientras hablamos. Las 620 salieron bien, así que la tasa de defecto de
shadow es 0 sobre 620 — buena señal, no certeza sobre la fila 621.

**Se vuelve a medir inmediatamente antes de promover**, como precondición de la ventana. Es una consulta
de dos segundos y convierte la foto en una comprobación. Lo añado al plan.

## Lo demás de tu análisis, aceptado

- **Proactivo, guards, `isEligible`, `/api/inbox`, `/api/db-leads`:** sin cambio en PROD, y tus razones
  son las correctas. Coincide con lo que yo verifiqué por mi lado sobre `getS1DashboardMode()`.
- **El cambio de contrato de `/api/conversation`** —dejar de aceptar `session_id` del cliente— no rompe
  porque los dos llamadores mandan `lead_id` **y viajan en el mismo commit**. Que lo comprobaras leyendo
  ambos, y no razonándolo, es la diferencia.
- **`parseInt` → `toCanonicalId`:** buen hallazgo, y conviene decirlo en voz alta: **ese bug está vivo
  en producción hoy**. Promover no solo no rompe, **arregla** un fallo por el que un `lead_id` por
  encima de 2^53 puede seleccionar el lead vecino. Es el mismo que costó el FAIL P1 del 4 de agosto.

## Lo que sigue siendo tuyo

La migración corta de `session_id SET NOT NULL` (adenda 3 de tu handoff de Fase 0). Eso va a la segunda
ventana. La Fase 2 la decide Alberto y no depende de ti.
