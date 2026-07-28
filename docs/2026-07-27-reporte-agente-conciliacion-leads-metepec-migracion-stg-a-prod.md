# Reporte del Agente Conciliación — `leads_metepec` creada en PROD y datos migrados desde STG

> Autor: Agente Conciliación (Nivel 3) · Fecha: 27 julio 2026
> Destinatario: **Arquitecto-IA-Qualitas** (vía Alberto).
> Estado: ejecutado, pendiente de verificación del Arquitecto.

## Disparador

Alberto pidió cargar cotizaciones manuales nuevas en `leads_metepec`. Al retomar la tabla, asumí
que el destino era STG — donde ya vivían los 6 leads reales que Alberto había backfilleado a
mano el 20 jul (ids 7–12, ver `handoffs/2026-07-20-leads-metepec-contexto.md` y
`docs/iniciativas/2026-07-20-leads-metepec-seguimiento-comisiones.md`). Alberto corrigió: esos
6 leads son datos reales, no de prueba, y no debían quedarse en STG — había que llevarlos a PROD.

## Qué se hizo

1. Confirmé que `leads_metepec` **no existía en PROD** (`CONCILIACION_DATABASE_URL`, misma
   Postgres que `conciliacion_pagos`) — solo existía en STG (`STG_DATABASE_URL`).
2. Con confirmación explícita de Alberto, creé la tabla en PROD con el mismo DDL de
   `scripts/2026-07-20-crear-tabla-leads-metepec.sql` (sin cambios de esquema).
3. Migré las 6 filas de STG a PROD preservando `id` (7–12) y todas las columnas, incluyendo
   `notas` con RFC embebido para los casos de flotilla/sin VIN. Ajusté la secuencia
   (`leads_metepec_id_seq`) al máximo `id` insertado.
4. Verifiqué el conteo en PROD (6 filas) y borré las 6 filas de STG — quedó en 0, por instrucción
   explícita de Alberto ("cuando queden en PRO, las borras").
5. **Regla nueva confirmada con Alberto:** por defecto, todo lo que se cargue en `leads_metepec`
   va a PROD, no a STG. STG queda solo para pruebas explícitas si hicieran falta en el futuro.
   Actualicé mi memoria del ecosistema con este criterio para no repetir el error.

## Nota sobre el script de migración

Usé un script de Node ad hoc (`pg` + `dotenv`, mismo patrón de dependencias que `conciliar.js`)
para leer de STG e insertar en PROD con `ON CONFLICT (id) DO NOTHING`. No quedó en el repo — se
corrió una vez desde un archivo temporal y se borró al terminar. Si esto se vuelve una operación
recurrente (backfills manuales periódicos), vale la pena considerar un script permanente en
`src/`; por ahora fue puntual, igual que el backfill original del 20 jul.

## Pendiente aparte, sin tocar en esta sesión

- Cargar las cotizaciones manuales nuevas que Alberto va a pasar — quedó en curso al momento de
  este reporte, directo en PROD conforme a la regla nueva.
- La búsqueda por VIN en el portal (parte 3 del handoff original) sigue sin implementar — este
  reporte es solo sobre dónde vive el dato, no sobre la conciliación automática de `leads_metepec`
  contra el portal.
