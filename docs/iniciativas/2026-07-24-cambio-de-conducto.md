# Cambio de conducto — registro de VIN cotizados y control de comisión

> Iniciativa creada: 24 julio 2026.
> Estado: **diseño aprobado por Alberto, sin construir.** Todo v1 es de nuestro lado (Dashboard), sin depender de Juan ni de Hylant.

---

## El caso de negocio

En el mercado mexicano, si Hylant cotiza un vehículo (Quálitas) y **después** otro broker cotiza esa misma póliza más barata, Quálitas lo considera **competencia desleal entre brokers**. Hylant puede reclamar el **cambio de conducto**: Quálitas le asigna la póliza a Hylant **junto con la comisión que se habría llevado el otro broker**. Es dinero fácil para Hylant.

**Campo clave: el VIN (número de serie).** Si Hylant demuestra que cotizó un VIN antes de que otro broker lo cotizara más barato, se pelea el cambio de conducto. Basta con haber **cotizado** ese VIN — no hace falta haber vendido/emitido.

**Objetivo de Alberto:** tener un registro de todas las cotizaciones con su VIN, para enviárselo a Hylant, que revise cuáles aplican; y cuando apliquen, llevar el control de la comisión que hay que cobrar.

**Prioridad núm. 1 declarada por Alberto:** *guardar el VIN en cuanto el lead lo dé*, exista o no emisión/pago después.

---

## Hallazgo decisivo — el VIN ya se está guardando (solo está enterrado)

Verificado contra la BD de producción el 24 jul 2026.

### 1. La columna `qualitas_cotizacion.serie_vehiculo` existe pero está vacía

| | Registros | Con VIN |
|---|---|---|
| `qualitas_cotizacion` | 1.044 | **0** |
| `qualitas_polizaemitida` (`serie_vehiculo`) | 46 | 45 |

Es lógico por el funnel: se cotiza con marca/modelo/año/versión (clave AMIS); el número de serie solo se pide **para emitir**. El cotizador de Quálitas (SIO) **sí** se llama al cotizar (por eso guardamos `clave_amis`, `nva_amis`, `tarifa`), pero para cotizar no se necesita VIN — solo para emitir. Confirmado con Alberto.

### 2. Pero el VIN SÍ cae en `whatsapp_sessions.captured_data`

Cuando el cliente da sus datos por WhatsApp, n8n los persiste en `captured_data` (JSONB). Ahí dentro ya está el número de serie en `grupo2.serie`:

```json
"grupo2": { "rfc":"PELM561017QUA", "serie":"9FBHS2FH0HM533222", "placas":"BVY149A", "requiere_factura":"SI" }
```

(Estructura observada: `grupo1` = datos personales, `grupo2` = vehículo + RFC, `grupo3` = domicilio → es el formulario de emisión.)

Cobertura actual medida (24 jul):
- **30 sesiones** con VIN real (17 chars) en `captured_data.grupo2.serie`
- **45 pólizas** con VIN en `qualitas_polizaemitida.serie_vehiculo`
- El hito de texto `Número de serie:` en `n8n_chat_histories` solo pilla **20** → `captured_data` es la mejor fuente

**Conclusión:** el dato existe. Nadie lo promueve de `captured_data` (blob de n8n) a una columna consultable. La captura no hay que construirla — hay que **rescatarla**.

### Techo natural de cobertura

El VIN en `captured_data` se captura cuando el cliente da datos **para emitir**, no en el instante de cotizar. Es decir:
- ✅ Cubre "el lead dio el VIN aunque no llegara a pagar" — que es exactamente lo que sirve para el cambio de conducto.
- ❌ NO cubre al lead que cotizó y se fue sin dar datos: de ese nunca hubo VIN.

Subir esa cobertura exigiría pedir el VIN **antes** en el funnel = fricción y caída de conversión. Se descarta para v1. Hay, pues, un techo natural sin tocar el flujo, y es aceptable.

---

## Diseño v1 — todo de nuestro lado (sin Juan, sin tocar n8n)

Dos problemas con dejar el VIN en `captured_data`: es un JSONB sin índice, y es **mutable y propiedad de n8n** (se puede sobrescribir). Para un registro que va a sustentar un reclamo comercial se quiere algo **inmutable y con fecha**.

### 1. Tabla propia append-only `registro_vin_conducto`

Nuestra (patrón `conciliacion_pagos` del Agente Conciliación — **nunca tocar las `qualitas_*` de Juan**). Snapshot append-only:

```
{ quotation_id, lead_id, conversation_id, vin, fecha_captura, canal, precio_cotizado, fuente }
```

- Append-only: aunque n8n sobrescriba `captured_data`, el registro queda.
- Clave única `(vin, quotation_id)` para idempotencia.
- `fuente` ∈ { `captured_data`, `polizaemitida`, `chat_histories` } para trazabilidad.

### 2. Barrido idempotente (cron Dashboard / Vercel)

Lee `whatsapp_sessions.captured_data->grupo2->>'serie'` + `qualitas_polizaemitida.serie_vehiculo` + (opcional) hito de chat, e inserta cada VIN nuevo.
- **Backfill inmediato:** las ~75 que ya existen (30 captured_data + 45 emitidas) entran de una.

### 3. Página en el Dashboard

Ver/exportar el registro (CSV/Sheet) para enviar a Hylant.

### 4. Tabla de cobro `cambio_conducto_caso` (cuentas por cobrar)

Esto sí es estado nuevo que hoy no vive en ningún sistema. Máquina de estados:

```
capturado → enviado_a_hylant → en_revision_qualitas → aprobado | rechazado
                                                          ↓
                                              comision_pendiente → comision_cobrada
```

Campos: `vin`/`quotation_id`, broker competidor (si se sabe), precio de ellos vs el nuestro, `comision_estimada`, `comision_cobrada`, fechas de cada transición. Tabla propia, nunca tocar `qualitas_*`.

---

## Fases

- **Fase 0 (v1, sin dependencias):** tabla append-only + barrido + backfill + página de registro + tabla `cambio_conducto_caso`. Da el registro poblado (~75 VINs) y el control de cobro sin Juan ni Hylant.
- **Fase 1 (externa):** cerrar las 3 casillas de abajo (formato Hylant, ventana, % comisión) e integrar el loop de veredictos.
- **Fase 2 (requiere Juan, opcional):** capturar VIN más temprano en el funnel para subir cobertura — solo si el techo de v1 se queda corto. Implica fricción; evaluar contra impacto en conversión.

---

## Casillas externas que Alberto está validando (no bloquean v1)

| Dato | Estado | Impacto |
|---|---|---|
| Cómo da feedback Hylant (qué VINs aplican) | ❓ Aún no se sabe | Formato de export + import de veredictos (Fase 1) |
| ¿Hay ventana de tiempo para el reclamo? (cotización del competidor dentro de N días) | ❓ Alberto pregunta | Qué se reporta y cuánto se retiene |
| Cálculo de la comisión | ⏳ "Es la comisión que le iban a dar al otro broker" — Alberto valida | Cómo se calcula `comision_estimada` |
| ¿Cotizador Django pega al SIO de Quálitas? | ✅ Sí (pero no requiere VIN para cotizar) | Descarta la opción "apoyarse solo en folio SIO" para el VIN |

---

## Referencias de esquema (verificadas 24 jul 2026)

- `qualitas_cotizacion.serie_vehiculo` (existe, vacío) · `qualitas_cotizacion.precio_total`, `fecha_creacion`
- `qualitas_polizaemitida.serie_vehiculo` (45/46 poblado)
- `whatsapp_sessions.captured_data` (JSONB) → `grupo2.serie` = VIN (30 sesiones)
- JOINs: `ws.quotation_id = qualitas_cotizacion.id`; `qualitas_lead.cotizacion_id = c.id`
