# Los estados del lead tras el funnel S2 — qué son y qué acredita cada uno

> **Leído del código de Django el 28 ago 2026** (`aguayo-co/HYL-WAI`, rama `stg`:
> `qualitas/models.py` y `qualitas/lead_funnel.py`). Contrato declarado: **`S2@2.0.0`**.
> Encargo de Alberto: entender los estados nuevos para trasladarlos a los ejecutores.

## Lo primero, porque cambia cómo se leen

**`qualitas_lead.estado` es un puntero al estado ACTUAL, no un historial.** Un lead que confirma
interés y luego avanza **ya no dice `INTERES_CONFIRMADO`**: el hito ocurrió y el campo no lo
recuerda. Quien lea `estado` sólo ve a los **detenidos** en cada punto.

**El historial vive en `qualitas_leadfunnelevent`**, append-only de verdad — tiene el trigger
`qualitas_lead_funnel_event_append_only_trg` que impide sobrescribir. Ahí el hito no se pisa.
**Hoy `dashboard_rw` no tiene `GRANT` sobre esa tabla** (pedido en `HYL-WAI#135`).

## Los ocho estados, en orden

`S2_STATE_RANK` los ordena por su posición en la lista, así que la progresión es monótona.

| # | Estado | Qué significa | **Evidencia que Django exige** |
|---|---|---|---|
| 0 | `LEAD_CREADO` | Existe el registro del lead | `cotizacion` |
| 1 | `COTIZACION_GENERADA` | **Quálitas devolvió una cotización con precio** | `cotizacion_respuesta_xml` |
| 2 | `INTERES_CONFIRMADO` | El cliente eligió, explícitamente | `cotizacion_seleccion` (web) · `whatsapp_message` (botón) |
| 3 | `DATOS_EMISION_EN_PROCESO` | Empezó a dar datos | `lead_operational_info`, `asegurado`, o `whatsapp_session_grupo1/2/3` |
| 4 | `DATOS_EMISION_COMPLETADOS` | Datos completos y validados | `asegurado` |
| 5 | `POLIZA_EMITIDA` | Póliza emitida | `poliza_emitida` |
| 6 | `PAGO_PENDIENTE` | Hay algo que cobrar | `poliza_emitida`, `lead_operational_info` o `receipt_payment_link` |
| 7 | `PAGO_CONFIRMADO` | Pago acreditado | `payment_evidence` |

Existe además `EVENT_PAYMENT_OBSERVED` (evidencia `payment_evidence`) que **no mueve el estado**:
observar un pago no es confirmarlo.

## La distinción que más nos interesa, y que no era obvia

**`LEAD_CREADO` y `COTIZACION_GENERADA` son dos momentos distintos**, y se distinguen por la
evidencia, no por el nombre:

- `LEAD_CREADO` se acredita con la **fila de `Cotizacion`** — alguien rellenó el formulario.
- `COTIZACION_GENERADA` se acredita con **`cotizacion_respuesta_xml`** — el XML que devolvió
  Quálitas.

Es decir: **separa «capturamos un lead» de «tenemos precio real del emisor»**. Un lead puede existir
sin cotización lograda: fallo del SOAP, vehículo no tarificable, datos que Quálitas rechaza. Hoy no
distinguimos esos dos fracasos y son problemas distintos — uno es de la landing, el otro de la
integración.

**Con esto queda contestada la pregunta que le habíamos dejado abierta a Juan en `#135`.** No hizo
falta que respondiera: está en el código.

## Por qué estos hitos son mejores que nuestros detectores

Nuestros hitos se infieren con `LIKE` sobre frases del bot en `n8n_chat_histories`. Cuando el copy
cambia, **no fallan: devuelven `false` para siempre** (`qualitas-issues#82`).

Los de Django **exigen evidencia y fallan cerrado**. En el carril de WhatsApp, para registrar
`INTERES_CONFIRMADO` busca el `WhatsappMessage` OUTBOUND con ese `button_payload` exacto:

- si no hay candidato → `funnel_evidence_missing`, **falla**;
- si hay más de uno → `funnel_evidence_ambiguous`, **falla**;
- comprueba el `conversation_id`;
- `event_id` determinista sobre ese mensaje → idempotente.

**Es la diferencia entre un dato y una suposición.**

## Los legacy no desaparecen

`ESTADOS_LEAD` = los siete legacy **más** los S2 que no se solapan. Conviven:

```
COTIZACION_INICIADA · DATOS_EMISION_INICIADOS · DATOS_EMISION_COMPLETADOS
POLIZA_EMITIDA · PAGO_APROBADO · PRIMER_PAGO_APROBADO · PAGO_TOTAL_COMPLETADO
```

`DATOS_EMISION_COMPLETADOS` y `POLIZA_EMITIDA` **son los mismos literales** en ambos vocabularios.
Los demás no tienen equivalencia automática — **`COTIZACION_GENERADA` no es `COTIZACION_INICIADA`,
y `PAGO_CONFIRMADO` no es `PAGO_APROBADO`.** Se parecen, y por eso son peligrosos.

## Nada de esto está encendido

Cuatro interruptores, los cuatro en `False` en el `stg` de hoy:

```
LEAD_FUNNEL_V2_WRITE_ENABLED · LEAD_FUNNEL_S2_PROJECTION_ENABLED
LEAD_FUNNEL_WEB_EVENTS_ENABLED · LEAD_FUNNEL_WHATSAPP_FACTS_ENABLED
```

Por eso la migración se llama `0091_lead_funnel_s2_**dark**_models`. **El modelo los admite y nadie
los escribe.** Verificado en los datos de STG: sólo vocabulario viejo.

## Qué le toca a cada uno

- **Dashboard:** la guarda de vocabulario ya está en producción. No desmontar los `LIKE` hasta que
  los interruptores se enciendan **y** haya `GRANT` sobre el ledger — sin él, leer el hito desde
  `estado` sería cambiar un detector frágil **con memoria** por uno riguroso **y amnésico**.
- **n8n:** el candidato del `#135` manda `button_payload` a Django. **Esa es la evidencia** que
  `INTERES_CONFIRMADO` exige por el carril de WhatsApp. Sin ese campo, el hito no se puede acreditar.
- **Arquitecto:** vigilar los cuatro interruptores. **El evento que importa no es el despliegue: es
  el encendido.**
