# Seguimiento de leads entregados a METEPEC — para negociar comisión con Highland

## Contexto de negocio

Modelo InsureMind/Quálitas: Highland paga pauta en Google Ads, los leads caen en la landing,
InsureMind cierra la venta (100% web, 100% WhatsApp, o mixto) y recibe comisión de Highland por
cada póliza vendida.

Hoy no todos los leads se pueden cerrar por WhatsApp con el bot actual — hay preguntas muy
concretas o clientes que no están listos para dar ciertos datos. Esos leads se le pasan a
**METEPEC**, un contact center que Highland tiene aparte, para que ellos intenten cerrar la venta
en vez de perder el lead. InsureMind quiere poder demostrarle a Highland cuántos de esos leads sí
se cerraron gracias al trabajo previo hecho en la landing/WhatsApp, para negociar una comisión por
haber participado en la venta — aunque el cierre final lo haga METEPEC.

## Qué se construyó

Tabla propia `leads_metepec`, standalone — **no es una tabla de Django**, sin FK real a
`qualitas_lead`/`qualitas_cotizacion` (referencia laxa por `id`), misma filosofía que
`conciliacion_pagos` (`Agente-Conciliacion:migrations/001_create_conciliacion_pagos.sql`): una
tabla que un agente/proceso propio mantiene, sin acoplarse al ciclo de vida de migraciones de
Django.

Script: `scripts/2026-07-20-crear-tabla-leads-metepec.sql` — **aplicar primero en STAGING**.

### Campos

- **Identificación y snapshot del lead**: `id`, `lead_id`/`cotizacion_id` (referencia laxa,
  opcional), `nombre`, `telefono`, `email`, `vehiculo_descripcion`, `vin` (número de serie del
  vehículo, para identificar el caso ante Highland/METEPEC), `codigo_postal` — snapshot al
  momento de la entrega, no un join en vivo, por si el dato en Django cambia después.
- **La oportunidad**: `fecha_oportunidad_creada` (cuándo nació el lead en nuestro funnel),
  `monto_poliza_cotizado` (precio cotizado al momento de la entrega).
- **La entrega a METEPEC**: `fecha_entrega_metepec`, `motivo_entrega` (por qué no se pudo cerrar
  internamente — para análisis futuro de qué tipo de preguntas/bloqueos son más comunes).
- **Seguimiento del resultado**: `estado_metepec` (`pendiente`/`vendida`/`no_vendida`/
  `declinada`, sin CHECK constraint todavía por si aparece un estado no previsto),
  `fecha_cierre_metepec`, `monto_cierre_metepec` (puede diferir del cotizado).
- **Para la negociación de comisión**: `considerada_en_comision` (boolean),
  `fecha_considerada_en_comision` — para llevar control de qué ventas de METEPEC ya se
  incluyeron en algún reporte/negociación con Highland y cuáles siguen pendientes de incluir.
- `notas`, `creado_en`.

## Decisiones de diseño

- **Sin FK real a Django**: mismo criterio que `conciliacion_pagos` — esta tabla vive y se
  actualiza por fuera del ciclo de Django (Alberto la llena/actualiza manualmente por ahora), no
  debe arriesgarse a romperse si cambia el esquema de `qualitas_lead`.
- **Snapshot, no join en vivo**: los datos del lead se copian al momento de la entrega. Si más
  adelante se decide mantenerlos siempre sincronizados con el dato vivo de Django, sería un
  cambio de diseño distinto (vista o proceso de sync), no lo que se pidió hoy.
- **`estado_metepec` como texto libre, no enum/CHECK**: se documentan los valores esperados en un
  comentario del script, sin forzarlos a nivel de esquema — mismo criterio que
  `conciliacion_pagos.estado`, para no bloquear un valor real no previsto todavía.
- **Sin columna `actualizado_en`**: se consideró, pero sin un proceso que la mantenga (Alberto
  actualiza a mano por ahora) quedaría stale silenciosamente — mejor omitirla que tener un campo
  que miente.

## Cómo se llena, por ahora

Manual — Alberto corre el `INSERT`/`UPDATE` en STG vía TablePlus, igual que el fixture de
`checkpoint_followups`. El `INSERT` inicial (entrega a METEPEC) se automatiza vía la nueva rama
de n8n descrita en [2026-07-20-agente-mtp-correo-metepec.md](2026-07-20-agente-mtp-correo-metepec.md).

**Decidido 20 jul — quién actualiza `estado_metepec`/`fecha_cierre_metepec`/`monto_cierre_metepec`:**
Agente Conciliación (no un agente nuevo), ya que `leads_metepec` es standalone igual que su propia
`conciliacion_pagos` — no viola la regla de "nunca tocar tablas de Django". Diferencia técnica clave
frente a lo que Agente Conciliación hace hoy: para `qualitas_polizaemitida` conocemos el número de
póliza de antemano; para `leads_metepec` no — METEPEC emite por su cuenta, así que hay que
**buscarla** en el portal (por VIN/teléfono/nombre, o listado por clave de agente 27614 si el
portal lo permite).

**Resuelto (20 jul, verificado en vivo por Alberto, pantalla "Consulta de póliza"):** el portal
NO permite listar por clave de agente — solo búsqueda puntual con un único campo, filtrable por
Número de póliza, **Número de serie (VIN)**, RFC, Nombre o Placas. Como `leads_metepec` ya
captura el VIN, el mecanismo queda: por cada fila con `estado_metepec = 'pendiente'`, Agente
Conciliación busca por VIN en ese mismo buscador — mismo patrón de búsqueda puntual que ya iba a
construir para `conciliacion_pagos`, solo cambia el identificador (VIN en vez de número de póliza
conocido). Falta mapear qué muestra la pantalla de resultado (estatus, fecha de emisión, prima)
una vez que se construya el scraper real — pendiente normal de Agente Conciliación, no un
bloqueante nuevo.

## Pendiente / a definir

- Confirmar en STAGING que el script corre limpio antes de replicarlo en PROD.
- Decidir si esto necesita un agente/proceso propio (tipo Agente Conciliación) más adelante, o si
  se mantiene manual — depende de cuántos leads reales se entreguen a METEPEC por semana.
  **En progreso:** ver [2026-07-20-agente-mtp-correo-metepec.md](2026-07-20-agente-mtp-correo-metepec.md)
  — automatización vía rama nueva del workflow n8n para los casos de plataforma digital y
  renovación (los que hoy el bot detecta o debería detectar de forma categórica, no el resto
  de escalamientos ad-hoc).
- Definir con Alberto/Highland qué constituye "vendida" de forma verificable (¿METEPEC reporta
  manualmente como Laura con las pólizas normales, o hay otro mecanismo?).
- Sin vista en el Dashboard todavía — si se necesita, es trabajo aparte para el Dashboard Code
  Agent.
