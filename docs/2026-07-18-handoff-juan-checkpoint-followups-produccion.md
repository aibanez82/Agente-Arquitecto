# Handoff para Juan — desplegar `checkpoint_followups` a producción

> De: Arquitecto (Agente-Arquitecto). Repo: `aguayo-co/HYL-WAI`, rama `stg` → `main`.
> Contexto: el sistema de seguimiento automático de leads estancados (`checkpoint_followups`) ya
> está completo y probado en `hyl-wai-stg` de punta a punta (Scheduler corriendo solo, entrega
> real por WhatsApp confirmada). Quedan 3 cosas antes de llevarlo a `hyl-wai-production`.

---

## 1. Interpolación de variables en el copy

Dos de los 18 mensajes activos en `qualitas_leadfollowuppolicy` usan placeholders literales que
hoy salen tal cual en WhatsApp (sin resolver):

- `quote_sent` / intento 1: `"...Tu cotización para tu [MARCA MODELO AÑO] por $[PRECIO] MXN..."`
- `summary_pending` / intento 1: `"...Tu resumen ya está listo: [MARCA MODELO AÑO], $[PRECIO] MXN..."`

**Qué hace falta:** que `render_policy_message()` (`qualitas/whatsapp_checkpoint_followups.py`)
exponga `vehiculo` y `precio` en el contexto de interpolación, y que las plantillas usen
`{vehiculo}` / `{precio}` en vez de los corchetes literales. Ya existe el patrón exacto a reusar
en `whatsapp_followups.py` (el scheduler viejo de 15 min): `resolver_opcion_cotizacion_whatsapp()`
para resolver la opción de cotización elegida, y `obtener_precio_anual_real()` /
`obtener_precio_mensual_real()` para el precio. `render_policy_message()` ya recibe el
`CheckpointFollowupCandidate` (que trae `cotizacion`), así que tiene lo necesario para llamar a
esas mismas funciones.

**No promover a PROD con los corchetes literales tal cual** — hay que resolver esto primero (o
al menos antes de activar envío real).

---

## 2. Respetar `whatsapp_sessions.status` en la elegibilidad

Hoy (18 jul) se desplegó a producción un mecanismo nuevo del lado de n8n: cuando un lead declina
explícitamente ("ya no me interesa", "no me escribas más", "ya contraté con otra compañía") o
pide cancelar, n8n marca `whatsapp_sessions.status = 'closed'` directo por SQL. Pero
`evaluate_checkpoint_followup_candidate()` (en `whatsapp_checkpoint_followups.py`) **nunca revisa
ese campo** — lo captura en metadata pero no lo usa para decidir elegibilidad. Sin este fix, un
lead que ya declinó seguiría recibiendo recordatorios automáticos.

**Ya existe el mismo patrón exacto en tu propio código**, en el scheduler viejo
(`qualitas/n8n_whatsapp_activity.py`, líneas 109-110):

```python
status = session.status.strip().lower()
if status in {"completed", "closed", "archived", "expired"}:
    return N8nActivityDecision(False, "n8n_session_not_open", metadata, session)
```

Agregar el equivalente en `evaluate_checkpoint_followup_candidate()` — mismo criterio, mismo
conjunto de valores. Cambio pequeño, con precedente directo en tu código, no es diseño nuevo.

---

## 3. Desplegar a `hyl-wai-production` — orden exacto de pasos

1. **Juan** — terminar los fixes de los puntos 1 y 2 arriba en la rama `stg`, verificar.
2. **Juan** — mergear `stg` → `main` (todo el feature de `checkpoint_followups` completo, no
   estaba en `main` todavía).
3. **Juan** — desplegar `main` a `hyl-wai-production` (el deploy normal de siempre).
4. **Juan** — correr la migración: `python manage.py migrate` contra `hyl-wai-production` (vía
   `heroku run` o el mecanismo de deploy que uses — **no crear las tablas por SQL directo**, eso
   deja a Django sin registro en `django_migrations` y rompe migraciones futuras).
5. **Alberto** — en cuanto Juan confirme que el paso 4 terminó, cargar el fixture de 21 filas en
   `qualitas_leadfollowuppolicy` (SQL ya preparado, ver tabla abajo). No depende de los pasos 6-7.
6. **Juan** — setear en `hyl-wai-production`: `WHATSAPP_CHECKPOINT_FOLLOWUPS_ENABLED=false`,
   `WHATSAPP_CHECKPOINT_FOLLOWUPS_DRY_RUN_DEFAULT=true` (arranque seguro, mismo patrón que STG).
7. **Juan** — crear el job del Heroku Scheduler en `hyl-wai-production`, a mano en el dashboard
   web (el Scheduler estándar no tiene API): `python manage.py enviar_seguimientos_whatsapp
   --message-key checkpoint_followups --limit 20`, cada 10 minutos.
8. **Ambos** — verificar unos días en dry-run, luego coordinar el cambio a envío real
   (`ENABLED=true`, `DRY_RUN_DEFAULT=false`).
- [ ] Setear los flags empezando seguro: `WHATSAPP_CHECKPOINT_FOLLOWUPS_ENABLED=false` y
      `WHATSAPP_CHECKPOINT_FOLLOWUPS_DRY_RUN_DEFAULT=true` primero — activar envío real después,
      coordinado con Alberto, mismo patrón que se siguió en STG.
- [ ] Crear el job del Heroku Scheduler en `hyl-wai-production` — **a mano en el dashboard web**
      (el Scheduler estándar de Heroku no expone sus jobs por la Platform API, solo por la UI):
      `python manage.py enviar_seguimientos_whatsapp --message-key checkpoint_followups --limit 20`,
      cada 10 minutos.

### Tabla de mensajes y `delay_mins` reales de PROD

`delay_mins` se mide desde el último mensaje del bot (no acumulado en la BD) — con estos 3
valores la cadena sale sola: intento 1 a los 5 min, intento 2 a los 5 min del intento 1 (~10 min
del mensaje original), intento 3 a los 10 min del intento 2 (~20 min del original). Mismo patrón
en los 6 checkpoints activos. `payment_link_sent` sigue **desactivado** — el estatus de pago no
es confiable todavía (sin webhook de Quálitas), decisión explícita de Alberto hasta que Agente
Conciliación lo resuelva.

| Checkpoint | Intento | `delay_mins` | Mensaje |
|---|---|---|---|
| `quote_sent` | 1 | 5 | "¡Hola! 😊 Tu cotización para tu {vehiculo} por {precio} sigue guardada — ¿seguimos con el trámite?" |
| `quote_sent` | 2 | 5 | "¿Seguimos con tu cotización? Nada más faltan un par de datos y queda lista tu póliza." |
| `quote_sent` | 3 | 10 | "Por ahora no te escribo más — tu cotización queda guardada, así que si quieres retomarla más adelante, contéstame por aquí cuando gustes." |
| `personal_data_captured` | 1 | 5 | "¡Seguimos por aquí! Ya tengo tus datos — solo me falta el VIN o las placas para avanzar con tu seguro." |
| `personal_data_captured` | 2 | 5 | "¿Me compartes el VIN o las placas cuando puedas? Es lo único que falta para seguir." |
| `personal_data_captured` | 3 | 10 | "Por ahora no insisto más — en cuanto me compartas el VIN o las placas, seguimos. Aquí quedo." |
| `vin_plates_captured` | 1 | 5 | "Ya con eso, solo me falta tu dirección para continuar con la emisión." |
| `vin_plates_captured` | 2 | 5 | "¿Me compartes tu dirección para seguir avanzando?" |
| `vin_plates_captured` | 3 | 10 | "Por ahora no insisto más — con tu dirección seguimos cuando quieras. Aquí quedo." |
| `address_captured` | 1 | 5 | "Ya casi terminamos — ¿necesitas factura para esta póliza?" |
| `address_captured` | 2 | 5 | "Solo me falta saber si requieres factura, ¿sí o no?" |
| `address_captured` | 3 | 10 | "Por ahora no insisto más — nada más dime si requieres factura y seguimos. Aquí quedo." |
| `rfc_digits_pending` | 1 | 5 | "Para tu factura necesito tu RFC completo con homoclave." |
| `rfc_digits_pending` | 2 | 5 | "¿Me compartes tu RFC completo para terminar tu factura?" |
| `rfc_digits_pending` | 3 | 10 | "Por ahora no insisto más — en cuanto tenga tu RFC, genero tu factura. Aquí quedo." |
| `summary_pending` | 1 | 5 | "Tu resumen ya está listo: {vehiculo}, {precio}. ¿Seguimos con la emisión de tu póliza?" |
| `summary_pending` | 2 | 5 | "Tu precio preferencial por contratar en digital solo está disponible hoy — ¿confirmamos y avanzamos con tu póliza?" |
| `summary_pending` | 3 | 10 | "Por ahora no insisto más — tu cotización sigue lista si decides retomarla. Aquí quedo." |
| `payment_link_sent` | 1-3 | — | ⛔ desactivado |

`rfc_digits_pending` solo aplica si el cliente pidió factura en `address_captured`; si dijo que
no, ese checkpoint se salta y va directo a `summary_pending`.

---

## Nota aparte, no bloqueante para este despliegue

Se identificó (18 jul) que un lead que declina (`status='closed'`) y luego regresa escribiendo
texto libre (sin botón/payload) a la misma cotización puede no resolver bien su sesión en el flujo
principal del bot — pendiente de abrir como issue formal, no hace falta resolverlo antes de este
despliegue de `checkpoint_followups`.

---

## Referencia

Detalle completo de todo el diseño e historial de esta iniciativa:
`Agente-Arquitecto:docs/iniciativas/seguimiento-leads-estancados.md`.
