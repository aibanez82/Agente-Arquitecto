# Diseño — Comisiones v2: comisión por recibo pagado (no 7% plano sobre la póliza)

> Autor: Arquitecto-IA-Qualitas · 26 jul 2026 · Estado: **diseño, aprobado en concepto por Alberto** (decisión: facturar sobre comisiones de recibos pagados).
> Ejecuta (cuando se apruebe el handoff): Dashboard Code Agent + un DDL que corre Alberto.

## Problema con Comisiones v1

La pestaña actual calcula **7% plano sobre `qualitas_polizaemitida.precio_total`**, un número por póliza. Dos fallos:

1. **Bug `$NaN`:** `precio_total` es **texto con coma de miles** (`"8,924.62"`). `Number("8,924.62")` = NaN → toda la tabla muestra `$NaN` / `$0`.
2. **Incorrecto de negocio:** comisiona el total aunque la póliza sea a plazos. Ej. real póliza **7620098887** (MAZDA): `precio_total` "8,924.62" pero **1 de 12 recibos pagados** (solo 1,530.42 cobrado). Comisionar 8,924.62 sería cobrar comisión sobre dinero que no ha entrado.

## Decisión

La comisión se gana **cuando el cliente paga cada recibo**. Comisión = **7% (editable) del importe de cada recibo `PAGADO`**. Se factura sobre comisiones de **recibos ya pagados**.

## Fuente de datos: `conciliacion_pagos` (no `precio_total`)

El dato correcto ya existe, en numérico limpio, poblado por el Agente Conciliación:

`conciliacion_pagos` (numero_recibo PK, numero_poliza, importe **numeric**, fecha_pago, estado…). Es literalmente la tabla de recibos de la vista Conciliación.

- Filtro de comisionable: **`estado = 'PAGADO'` exacto** (la columna tiene ruido del scraping: `CANCELADO`, `VENCIDO`, `VENCIDO: HOY 12 HORAS`, `PENDIENTE`, `PAGADO`).
- Universo hoy: 22 recibos pagados en 22 pólizas (de 233 recibos / 48 pólizas).

**Dependencia dura:** Comisiones v2 = f(`conciliacion_pagos`). Una póliza que el Agente Conciliación aún no scrapeó no tiene recibos → no aparece su comisión. La **completitud de Comisiones = completitud de Conciliación**. Esto acopla ambas features (coherente: las dos son de Admin/dinero de Insurmind y en la separación de apps van juntas al panel Admin).

## Modelo de datos (cambio de grano: póliza → recibo)

`comisiones_polizas` (vacía, 0 filas) se **reemplaza** por `comisiones_recibos`. `comisiones_facturas` se mantiene (ahora agrupa comisiones de recibos).

**Principio:** la comisión "sin facturar" se **calcula en vivo** desde `conciliacion_pagos` (7% × importe de recibos PAGADO). Solo se **persiste** al facturar, con **snapshot** de los importes para que la factura sea inmutable aunque el scraping cambie después.

### DDL (lo corre Alberto como `ufdg7frlrnm5on`, igual que las tablas anteriores)

```sql
-- comisiones_polizas está vacía; se retira en favor del grano por recibo
DROP TABLE IF EXISTS comisiones_polizas;

CREATE TABLE IF NOT EXISTS comisiones_recibos (
  numero_recibo        text PRIMARY KEY,          -- referencia laxa a conciliacion_pagos.numero_recibo (sin FK; snapshot)
  numero_poliza        text NOT NULL,
  importe_recibo       numeric(12,2) NOT NULL,     -- snapshot del importe pagado al facturar
  porcentaje_comision  numeric(5,2)  NOT NULL DEFAULT 7,
  monto_comision       numeric(12,2) NOT NULL,     -- importe_recibo * porcentaje/100 (snapshot)
  factura_id           integer REFERENCES comisiones_facturas(id),
  creado_por           text,
  creado_en            timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_comisiones_recibos_factura_id   ON comisiones_recibos(factura_id);
CREATE INDEX IF NOT EXISTS idx_comisiones_recibos_numero_poliza ON comisiones_recibos(numero_poliza);
```

Sin FK a `conciliacion_pagos` (mismo criterio de snapshot que se usó con `precio_poliza`): si el portal re-scrapea o cambia un recibo, la comisión ya facturada no se mueve.

## Flujo y vista

**Vista Comisiones (por póliza, expandible a recibos — como la tabla de Conciliación):**
- Por póliza con recibos pagados: lista de recibos `PAGADO` con importe, % (editable, default 7), comisión de cada uno, y si ya está facturado (factura_id) o no.
- Tiles: **comisión cobrable ya** (recibos pagados no facturados), **facturado pendiente de cobro**, **cobrado**.

**Acciones:**
- **Agrupar en factura:** seleccionar recibos pagados **no facturados** → transacción: crea `comisiones_facturas` + inserta filas en `comisiones_recibos` (snapshot importe/pct/monto, con `factura_id`). `monto_total` factura = suma de comisiones.
- **Marcar cobrada:** sobre la factura (total/parcial), sin cambios respecto a v1.

## Cambios en endpoints (`apps/operacion/pages/api/comisiones*`)

- `GET /api/comisiones`: reemplazar `POLIZAS_PAGADAS_SQL` por un **RECIBOS_PAGADOS_SQL** que sale de `conciliacion_pagos WHERE estado='PAGADO'`, `LEFT JOIN comisiones_recibos` para saber cuáles ya están facturados. Agrupar por póliza para la UI. Importe ya es numérico → **adiós NaN**.
- `POST /api/comisiones/facturar`: input = lista de `numero_recibo` pagados no facturados + metadata. Transacción crea factura + inserta snapshots en `comisiones_recibos`.
- `POST /api/comisiones/cobrar`: sin cambios.
- `POST /api/comisiones/calcular`: **se retira** — en v2 la comisión no es un paso de "calcular y guardar" por póliza; se deriva en vivo y se persiste al facturar.

## Frontend (`components/ComisionesView.js`)

Rehacer la tabla "Pólizas pagadas sin comisión calculada" → vista por póliza con desglose de recibos pagados (estilo Conciliación), comisión por recibo, checkboxes de recibos no facturados → "Agrupar en factura". Tiles recalculados sobre comisión cobrable / facturada / cobrada.

## Pendientes que genera

- **Inventario BD + delta a Juan:** `comisiones_polizas` se elimina y aparece `comisiones_recibos` → actualizar `inventario-bd-objetos-externos-para-juan.md` y avisar a Juan.
- El bug `$NaN` queda absorbido (fuente numérica limpia). No se parchea v1.
- En la separación de apps (P1b), Comisiones y Conciliación viven juntas en el panel **Admin** y comparten `conciliacion_pagos`.
