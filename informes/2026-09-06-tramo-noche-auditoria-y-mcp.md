# Tramo de noche — auditoría de `CLAUDE.md`, el scraper muerto y el arranque del MCP

> Arquitecto-IA-Qualitas · 6-7 sep 2026. Continúa `informes/2026-09-06-cierre-del-dia.md`.

## 1 · Auditoría de coherencia de `CLAUDE.md` — PR #91

Siete incoherencias. **Seis reales, una mía.**

| # | Qué pasaba |
|---|---|
| 1 | Fecha de cabecera: decía «4 agosto» y el cuerpo llegaba al 3 de septiembre |
| 2 | **Estado FALSO**: «Seguimiento leads estancados: en STG apagado/dry-run». Los **dos** entornos encendidos y sin dry-run; en STG **disparó 5 veces** el 6 sep |
| 3 | Contradicción interna: sacaba `qualitas-issues` del barrido y cuatro líneas después mandaba barrerlo |
| 4 | Pendiente `fecha_inicio` apuntando a `qualitas-issues#66`, tracker congelado: **sin issue vivo** |
| 5 | «No ejecuto nada» vs «promuevo a PROD» — desambiguado, y añadido que **un freno de permisos de un ejecutor no convierte la acción en mía** |
| 6 | **La que reporté mal**: dije que se pasaba del techo de 30 KB. `scripts/verifica-claude-md.sh` lee 30 KB como 30×1024 = 30.720 y el fichero cumplía. Usé 30.000 |
| 7 | **El Agente Conciliación figuraba «✅ Operativo, cron diario» llevando 19 días muerto** |

### La séptima, con su medición

- Última escritura en `conciliacion_pagos`: **18 ago 06:59**. Cero filas en 14 días.
- Cron de GH Actions: **fallando a diario del 22 al 26 ago**, y sin ejecuciones después.

**No la encontró mi auditoría: la destapó el propio ejecutor** al reescribir su `CLAUDE.md`. El motivo de que se me escapara, dicho sin adornos: **comprobé lo que sospechaba, no lo que el fichero afirma.** La tabla de sistemas está llena de ✅ y no verifiqué ni uno.

Queda como regla en `CLAUDE.md`: *todo ✅ es una afirmación de estado y caduca; al auditar, verificar cada uno contra su fuente.*

### Dos tropiezos del propio arreglo

Empujé un commit **con el gate en FALLA** (me pasé del techo al añadir la corrección), y al comprimir para volver **borré un ancla vigilada** (`solo el Arquitecto cierra/certifica`). Las dos las cazó el verificador del repo. **La herramienta funcionó; yo no la corrí antes de empujar.**

## 2 · Arranque del MCP de Insurmind — las nueve mediciones

Sesión nueva (`Insurmind_MCP`) construyendo un MCP remoto que expone cotización y consulta a ChatGPT/Claude. Me hizo nueve preguntas de arquitectura. **Todo lo de abajo está medido el 6 sep**, y es reutilizable.

### Latencia de cotización — decide síncrono vs submit+poll

Elapsed `qualitas_cotizacion.fecha_creacion` → fila de `qualitas_cotizacionrespuestaxml`, excluidas recotizaciones de descuento:

| | n | p50 | p95 | máx |
|---|---|---|---|---|
| **PROD** | **1.332** | **3,83 s** | **5,09 s** | **10,91 s** |
| STG | 109 | 4,96 s | 5,76 s | 6,17 s |

**Criterio dado:** síncrono con presupuesto de ~8 s y salida de escape a `estado: procesando`. Diseñar todo asíncrono por un caso entre mil es pagar de más.

### Dónde está cada dato

- **Desglose por cobertura: NO en columnas.** Vive en `qualitas_cotizacionrespuestaxml`, seis columnas `text` con SOAP escapado (amplia anual/semestral/trimestral/mensual, limitada anual/semestral). Forma: `<Coberturas NoCobertura="1"><SumaAsegurada>…</SumaAsegurada><TipoSuma>2</TipoSuma><Deducible>0005</Deducible><Prima>…</Prima></Coberturas>`.
- **La cobertura se identifica por número, no por nombre.** No hay mapa número→nombre en la BD.
- **El deducible trae ceros a la izquierda** (`0005`, `00010`).
- **Prima: en columnas solo totales** (`precio_total`, `primer_pago`, `monto_subsecuente`) y **todos `varchar`**. El desglose (`PrimaNeta`, `Derecho`, `Impuesto`, `PrimaTotal`) está en el XML.

### Identidad, permisos e idempotencia

- **`qualitas_cotizacion.public_token` es `uuid NOT NULL`** y ya se usa para el PDF público. **Es el identificador externo**; el `id` es `bigint` secuencial y no sale nunca.
- **No hay Redis** en el ecosistema: addons medidos = `advanced-scheduler` + `heroku-postgresql` (PROD suma `mailgun` y `papertrail`). El store va en Postgres.
- **La idempotencia del descuento ya está en la base**, no en la conversación: índices únicos parciales `uniq_discount_root_slot (root_quote_id, slot_number)` y `uniq_discount_live_source (source_lead_id, source_quote_id)`, más `maximum_discounts_snapshot = 1`.
- **`canal_atencion` solo tiene `LANDING` y `WHATSAPP`** (`varchar(20)`). Un canal nuevo exige valor nuevo, y es **campo de Django: lo confirma Juan**.
- **Catálogo de versiones: `qualitas_catalogovehiculo`**, 39.901 filas (`clave_amis, marca_id, nombre_marca, modelo, submarca, version, categoria, activo`).
- **Vinculación lead↔WhatsApp: no viaja en el texto del `wa.me`.** Django crea del lado servidor `waq_<qid>_<hex>` en `whatsapp_sessions`; el bot **resuelve por teléfono** y desambigua si hay varias. Si el usuario borra el texto prellenado, no se pierde nada.
- **Staging tiene gemelos completos, incluido Quálitas**: `QUALITAS_URL = https://qa.qualitas.com.mx:8443/…`, `AMBIENTE_PRUEBAS=1`, y `N8N_BASE` STG `https://n8n-xlqk.srv1810257.hstgr.cloud`.

### Avisos que le di y valen para cualquier consumidor

- **`valor_uno` y `valor_dos` están PROHIBIDOS de mostrar** (`HYL-WAI#293`): son opacos del catálogo, no son suma asegurada ni valor factura.
- **`paquete` y `forma_pago` vienen vacíos** hasta que el cliente elige.
- **`uncertain` en una aplicación de descuento es TERMINAL**, no «procesando» (`HYL-WAI#343`).

## 3 · Lo que queda esperándome

- **Validar el cambio de oficio del Agente Conciliación** — de scraper a reportes sobre el ledger, 100 % lectura. Con el scraper muerto desde el 18 ago, la pregunta ya no es si cambia: **el viejo no existe**. Su rama: `docs/cambio-de-oficio-ledger`.
- **Revisar `src/clients/contrato.ts` del MCP** y decirle qué campos no puede entregar hoy la orquestación. Su pregunta de frontera: si el parseo del SOAP debe vivir en el MCP o en n8n — su instinto (no meter un tercer parser) coincide con lo aprendido hoy con el literal único.

Agente: Arquitecto-IA-Qualitas
