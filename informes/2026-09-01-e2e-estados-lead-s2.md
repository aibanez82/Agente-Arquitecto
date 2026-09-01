# E2E de estados del lead (embudo S2) en STG — qué escribe Django, hito por hito

> De: Agente QA & Testing · Para: Arquitecto-IA-Quálitas (orden de Alberto, 31-ago/1-sep)
> Responde a: `handoffs/2026-09-01-e2e-estados-lead-s2-stg.md`
> **Camino real, vía WEB pura** (aprobada): lead nuevo desde la landing STG por HTTP + selección
> y emisión web. **Cero Meta, cero WhatsApp, y no produje yo ningún evento** — todos los mide
> Django. Solo lectura salvo la creación del lead y la selección/emisión autorizadas; **cero
> UPDATE sobre `qualitas_lead.estado`**. Código citado siempre de `origin/stg` (tip `18f4ece`).
>
> **Teléfono del lead: `525500000099`** (formato válido, sin colisión con ninguna sesión viva —
> condición del Arquitecto). **Sesión que resolvió: ninguna** — la vía web no crea sesión de
> WhatsApp, así que no hay ambigüedad de resolución que declarar.

## Tabla hito por hito

| Hito | Evento escrito | source/channel | occurred vs created | Estado del lead después | Evidencia (tipo·pk) |
|---|---|---|---|---|---|
| 1 · lead_creado | ✅ **`lead_creado`** | django · LANDING | occurred=created (03:54:50) | `LEAD_CREADO` | cotizacion · 2318 |
| 2 · cotizacion_generada | ✅ **`cotizacion_generada`** | django · LANDING | occurred=fecha del XML, created +5s | `COTIZACION_GENERADA` | cotizacion_respuesta_xml · 866 |
| 3 · interes_confirmado | ✅ **`interes_confirmado`** | django · LANDING | occurred≈created (03:55:15) | `INTERES_CONFIRMADO` | cotizacion_seleccion · 2318 |
| 4 · dato_emision_persistido | ❌ no escrito | — | — | (sin cambio) | — |
| 5 · datos_emision_validados | ❌ no escrito | — | — | (sin cambio) | — |
| 6 · poliza_emitida | ❌ no escrito | — | — | (sin cambio) | — |
| 7 · pago_pendiente | ❌ no escrito | — | — | (sin cambio) | — |
| 8 · pago_observado | ❌ no alcanzado | — | — | — | — |
| 9 · pago_confirmado | ❌ no alcanzado | — | — | — | — |

Medido sobre el lead **965 / cotización 2318** (HONDA CIVIC 2020). El lead **964 / cotización 2317**
es un primer intento que quedó en `COTIZACION_GENERADA` (misma medición de hitos 1-2; ver residuo).

## Los tres eventos que SÍ ocurrieron — sin saltos de estado

`LEAD_CREADO → COTIZACION_GENERADA → INTERES_CONFIRMADO`, en orden, monótono, cada uno con su
evidencia. **Ningún salto** (no se pisó ningún estado intermedio). El hito 2 confirma en positivo
la parte medible de tu pregunta (a): **`cotizacion_generada` no estaba roto** — con
`LEAD_FUNNEL_WEB_EVENTS_ENABLED=true` (verificado en Heroku) y un lead orgánico con oferta válida,
dispara limpio. Que nunca hubiera ocurrido en vivo era ausencia de tráfico por la landing, no un
defecto del emisor. Los 94 del cutover en ese estado tienen ahora dos hermanos orgánicos (964, 965).

## Dónde se detuvo, y por qué (los hitos que NO produjeron evento)

**Hitos 4-6 — muro en la emisión web: `consultar_serie` de Quálitas QA.**
`emitir_poliza` (`qualitas/views.py:639`) llama `service.consultar_serie(datos['serie'])` sin flag de
salto (`views.py:693`); si devuelve `existe`, renderiza el modal «serie existente» (`views.py:695-712`)
y **no emite**. En el entorno QA de Quálitas, `consultar_serie` marcó como existentes **todos** los
VINs que probé (uno real del corpus y uno sintético estructuralmente válido). Sin serie que QA
acepte como nueva, el flujo se detiene antes de `emitir_nueva_poliza`.

- **Distinción falta-de-llamada vs precondición-rechazada:** para el hito 4 es **precondición
  rechazada aguas arriba**. `persist_emission_insured` (`qualitas/lead_funnel.py:1472`) es quien
  escribiría `dato_emision_persistido` + `datos_emision_validados` (`lead_funnel.py:1490-1491`,
  bajo `producer_enabled`, que para LANDING es el flag WEB_EVENTS = ON). **Pero no se creó ningún
  `Asegurado` para la cotización 2318** (0 filas) — luego esos facts nunca se intentaron.
- **Anomalía que no pude resolver desde fuera, y te la dejo para Juan:** por lectura del código,
  `persist_emission_insured` corre **antes** de `consultar_serie` y su `transaction.atomic()`
  debería dejar el `Asegurado` committeado aunque después aparezca el modal. Observé lo contrario:
  modal presente **y** cero `Asegurado`. O `persist_emission_insured` revierte, o la vista captura
  una excepción previa y renderiza el modal por otra rama. No lo puedo determinar sin ver el
  manejo de excepciones de `emitir_poliza` / `_prepare_emission_mutation` en ejecución. **Lo
  pregunto a Juan.**

**Hito 7 — `pago_pendiente`: no alcanzado (sin emisión), y causa por código confirmada.**
Tu sospecha se sostiene: `prepare_issuance_payment_link` (`qualitas/issuance_payment_links.py:79`)
corre `run_policy_receipt_poll_for_policy` **antes** de preparar el link; si el proveedor QA ya
reporta el primer recibo pagado, o bien la cuota deja de estar `PENDING` y el link ni se crea
(`issuance_payment_links.py:112-119` → `record_issuance_payment_link` no se invoca), o bien se crea
`ACTIVE` y `reconcile_active_payment_links` lo pasa a `PAID` (`due_payment_links.py:624-650`) y
`_validate_evidence` lo veta (`lead_funnel.py:651-660`, además veta si la póliza queda
`estatus_pago=PAGADO`). Los ~2s del síntoma encajan con la latencia del poll SOAP.

**Hitos 8 y 9 — no alcanzados (sin emisión), pero ambos tienen productor automático.**
- `pago_observado`: lo produce el **redirect de retorno del navegador** `pago_exitoso` →
  `observe_payment_redirect` (`qualitas/payment_confirmation.py:107-166`, evidencia
  `PaymentEvidence` `SOURCE_REDIRECT`). No es un poll; lo dispara el cliente al volver de la pasarela.
- `pago_confirmado`: **corrijo una lectura previa mía.** No es solo la aprobación manual en Wagtail
  admin — hay un **camino automático por poll del recibo**:
  `first_receipt_confirmation.py:524` → `apply_locked_provider_poll_first_receipt_funnel_effect`
  con `PaymentEvidence.SOURCE_PROVIDER_POLL`, disparado por el scheduler de
  `first_receipt_polling.py` (`claim_next_first_receipt_poll`). Es coherente con el evento de la
  cadena A3 (`pago_confirmado · django · channel=SYSTEM`, sin operador). **El hito 9 se cierra sin
  intervención** — no hay que pedirle a nadie que apruebe nada.

## Nota de fidelidad (para no prometer de más)

Lo medido en los hitos 1-3 lleva `channel=LANDING`. La cadena del A3 midió los mismos eventos con
`channel=WHATSAPP`. **Lo acreditado es el evento y su evidencia, no que ambos canales sean
intercambiables** — son productores distintos con el mismo contrato de estado.

## Qué falta para cerrar 4-8 en vivo, y la decisión es tuya

El único muro es `consultar_serie` marcando toda serie como existente en QA. Opciones:
1. Una **serie (VIN) que el QA de Quálitas acepte como nueva** — si Juan/Alberto conocen una que no
   dispare el modal, emito por HTTP y capturo 4-7 de una pasada (y el 8 con el redirect `pago_exitoso`).
2. **Confirmar el modal desde el navegador** (el flujo real ofrece continuar) — implicaría
   Claude-in-Chrome sobre el form de emisión; lo hago si lo autorizas.
3. Que **la emisión la dispare Alberto/Juan** por el form real mientras yo mido los eventos que
   quedan — cierra 4-9 con datos reales y a mí me deja el rol de medir, no de fabricar.

No sigo disparando VINs a ciegas contra el SOAP de Quálitas: sería el ruido del §2.12 que quieres evitar.

## Residuo declarado

| Qué | Estado |
|---|---|
| Leads creados | **964** (cot 2317) y **965** (cot 2318), ambos `COTIZACION_GENERADA`/`INTERES_CONFIRMADO`; teléfono `525500000099` |
| Cotizaciones | 2317, 2318 · XML de respuesta 865, 866 |
| Eventos vivos añadidos | 5 (`lead_creado`+`cotizacion_generada` en 964; +`interes_confirmado` en 965) |
| `Asegurado` / `PolizaEmitida` | **ninguno** (la emisión no completó) |
| Sesiones de WhatsApp | **ninguna** (vía web pura) · Meta/correos: **cero** |
| `whatsapp_sessions` `QA-SUITE-*` | S1 sigue viva (suite conversacional); S2 ya se limpió ayer |
| Intentos de emisión sobre la 2318 | **dos**: (1) con VIN del corpus/sintético → modal «serie existente»; (2) con la serie de Alberto `1GTEC19097E561364` → sin modal pero sin emisión. Ninguno creó `Asegurado` ni póliza |

Los leads 964/965 y sus cotizaciones **quedan vivos** (no hay borrado autorizado de `qualitas_lead`
en esta orden, y son solo-lectura salvo lo que ya escribió Django). Se mantienen declarados; **no
propongo borrarlos** — son las dos primeras cadenas orgánicas del embudo y valen como evidencia.

```
🧪 QA REPORT — 1 sep 2026 · E2E estados del lead S2 (STG, vía web pura) · ENTREGA (no parcial)
✅ Hitos 1-3 medidos en vivo (lead_creado, cotizacion_generada, interes_confirmado) — sin saltos
✅ (a) cotizacion_generada NO estaba roto: dispara con lead orgánico (WEB_EVENTS=on)
⛔ Hitos 4-8 no medibles en vivo: EL BLOQUEO NO ES LA SERIE — con la serie que consultar_serie acepta
   como nueva, sigue sin crearse Asegurado ni póliza. Fallo del flujo de emisión del servidor (Juan).
📄 (b) pago_pendiente: causa por código = carrera del recibo (confirmada, con cita)
📄 (c) pago_observado=redirect · pago_confirmado=poll automático SOURCE_PROVIDER_POLL (corrijo lectura previa)
```

— Agente QA & Testing

---

## Actualización — reintento con la serie desbloqueada de Alberto (`1GTEC19097E561364`)

El muro de `consultar_serie` **se levantó**: con esa serie el modal «serie existente» **no
aparece** (`mostrar_modal_serie_existente=false`) y el form pasa validación sin campos inválidos.
**Pero la emisión sigue sin completar**, y esto es lo importante: aislado ya de la serie,

- **cero `Asegurado`** para la cotización 2318 (0 filas),
- **cero `PolizaEmitida`**,
- lead 965 sigue en `INTERES_CONFIRMADO`, con los mismos 3 eventos,
- la respuesta HTTP 200 re-renderiza el **formulario de emisión** (no una página de éxito, no el
  modal), con el puntero de sesión intacto (`cotizacion_id=2318`).

**Conclusión medida: el bloqueo de la emisión NO era (solo) la serie.** Es exactamente la anomalía
que quedó escalada a Juan — `persist_emission_insured` (`lead_funnel.py:1472`) corre en su propio
`transaction.atomic()` antes de `consultar_serie`/SOAP y debería dejar el `Asegurado` committeado,
pero no queda ninguno. Descartado el rollback global de request (no hay `ATOMIC_REQUESTS` en
settings), la causa está dentro del flujo de emisión del servidor y **no es diagnosticable ni
resoluble desde fuera** — es del lado de Juan.

**Efecto sobre el E2E:** los hitos **4-8 no son medibles en vivo** por la vía web hasta que se
resuelva esa anomalía. No repetí disparos: un segundo POST con serie válida reprodujo el mismo
resultado, y más intentos no cambiarían nada del lado cliente.

**Corrección de las opciones del informe:** la opción 3 (que Alberto/Juan disparen la emisión por
el form real mientras yo mido) **también está bloqueada por esta misma anomalía**: si el servidor
no crea el `Asegurado`, no lo creará tampoco con Alberto delante. Ninguna de las tres vías propuestas
sirve mientras el fallo del servidor siga en pie. **El desbloqueo de los hitos 4-8 depende
exclusivamente de que Juan resuelva la anomalía del `Asegurado`** — no hay maniobra por mi lado.

---

## Estado de esta entrega

**Esto es la entrega, no un borrador a la espera.** Lo medido queda cerrado: hitos 1-3 acreditados
en vivo (con la pregunta (a) respondida), hitos 4-9 con su causa por código y cita. Lo que falta —la
medición en vivo de 4-8— **está bloqueado por un fallo del servidor (la anomalía del `Asegurado`),
no por esta prueba**, y su seguimiento vive en la escalada a Juan, no en este informe. Si Juan tarda,
esta entrega se sostiene tal cual; cuando resuelva, reabro solo el tramo 4-8 con una corrida nueva.

> **Para Juan, en una línea:** el bloqueo de la emisión **NO es la serie**. Con la serie
> `1GTEC19097E561364` (que `consultar_serie` acepta como nueva) el modal desaparece y aun así no se
> crea `Asegurado` ni póliza. No hay que revisar el catálogo de series; el fallo está en el flujo de
> `emitir_poliza`/`persist_emission_insured` del lado servidor.
