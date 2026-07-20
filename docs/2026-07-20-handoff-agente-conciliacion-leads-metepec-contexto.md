# Handoff Arquitecto → Agente Conciliación — Contexto: tabla `leads_metepec`

> Autor: Arquitecto-IA-Qualitas · 20 jul 2026
> Ejecutor: **Agente Conciliación**.
> Gobernanza: reportas al Arquitecto **a través de Alberto**. No hablas con otros agentes.
> Copia canónica: `Agente-Arquitecto:docs/iniciativas/2026-07-20-leads-metepec-seguimiento-comisiones.md` — deja también copia de este handoff en `Agente-Conciliacion/handoffs/`.
> **Tipo: contexto + trabajo futuro, NO urgente.** No bloquea los pendientes actuales de `conciliar.js` (mover a GitHub Actions, etc. — ver `CLAUDE.md`, "Estado actual").

## Objetivo de este handoff

Darte contexto de que existe una segunda tabla, `leads_metepec`, que en algún momento vas a
tener que conciliar además de `qualitas_polizaemitida`. No hace falta que implementes nada
todavía — esto es para que lo tengas presente cuando retomes este repo y para que no se pierda
entre laptops.

## Qué es `leads_metepec`

Tabla standalone (no es de Django, mismo criterio de propiedad que tu propia
`conciliacion_pagos`) donde InsureMind registra los leads que le pasa a **METEPEC** — el
contact center que Highland tiene aparte — cuando el bot de WhatsApp no puede cerrar la venta
por sí solo. Hoy: casos de "plataforma digital" (Uber/Didi/taxi/flotilla). Más adelante:
renovaciones de póliza.

- Script de creación: `Agente-Arquitecto:scripts/2026-07-20-crear-tabla-leads-metepec.sql`
- Diseño completo: `Agente-Arquitecto:docs/iniciativas/2026-07-20-leads-metepec-seguimiento-comisiones.md`
- El INSERT inicial (cuando se entrega el lead a METEPEC) lo hace n8n automáticamente — ver
  `Agente-Arquitecto:docs/iniciativas/2026-07-20-agente-mtp-correo-metepec.md`. Eso ya está
  resuelto, no es parte de tu trabajo.

## Por qué te toca a vos

InsureMind quiere poder demostrarle a Highland cuántos de esos leads sí se cerraron gracias al
trabajo previo hecho en la landing/WhatsApp, para negociar una comisión por haber participado en
la venta — aunque el cierre final lo haga METEPEC. Sin verificación automática, esto se queda en
un reporte manual (como el de Laura de Hylant, pero peor: nadie lo está llevando hoy).

Encaja en tu rol porque ya tenés acceso al mismo portal (`agentes360.qualitas.com.mx`) donde se
puede confirmar si una póliza efectivamente se emitió — solo cambia el criterio de búsqueda.

## Diferencia técnica clave frente a `conciliacion_pagos`

Hoy conciliás pólizas **ya conocidas** (tenés el número de póliza, viene de
`qualitas_polizaemitida`) y buscás en el módulo `/group/guest/consulta-de-polizas` con el campo
`#numberPolicy`. Para `leads_metepec` NO hay número de póliza — la emite METEPEC por su cuenta.
Hay que **buscarla** por otro identificador.

Alberto confirmó en vivo (20 jul, pantalla "Consulta de póliza") que el buscador del portal
permite filtrar por: Número de póliza, **Número de serie (VIN)**, RFC, Nombre, o Placas — un
solo campo de búsqueda con checkboxes para elegir el filtro. **No existe** un listado de todas
las pólizas por clave de agente (27614) — se descartó esa opción.

`leads_metepec` ya captura el VIN de cada lead, así que el mecanismo queda: por cada fila con
`estado_metepec = 'pendiente'`, buscar por VIN en ese mismo buscador (probablemente el mismo
campo `#numberPolicy` que ya usás, pero con el checkbox de "Número de serie" marcado en vez de
"Número de póliza" — falta confirmar en el HTML real si es literalmente el mismo input o uno
distinto; no lo tengo confirmado a nivel de selector, solo a nivel de comportamiento del portal).

## Qué hacer cuando retomes esto (no ahora)

1. Terminar primero los pendientes actuales de `conciliar.js` (cron en GitHub Actions, etc.) —
   esto es una extensión, no reemplaza ni bloquea ese trabajo.
2. Mapear el selector real del checkbox "Número de serie" en `/group/guest/consulta-de-polizas`
   (o confirmar si es un módulo distinto al que usás hoy).
3. Nueva función (o script aparte, a tu criterio): leer `leads_metepec` donde
   `estado_metepec = 'pendiente'`, buscar cada VIN en el portal, y si aparece una póliza:
   - `UPDATE leads_metepec SET estado_metepec = 'vendida', fecha_cierre_metepec = ...,
     monto_cierre_metepec = ...`
   - Si no aparece nada, dejar como está (sigue pendiente, no es un error)
4. **Nunca tocar `qualitas_polizaemitida`** — igual que hoy, esto se queda en tablas standalone.
5. Avisar al Arquitecto antes de activar esto en un cron — primero una corrida manual de
   verificación, mismo patrón que usaste para `conciliacion_pagos` el 14-15 jul.

## Fuera de alcance de este handoff

- No hace falta tocar nada del código todavía — esto es solo contexto para que no se pierda.
- El caso "renovación" en `leads_metepec` (para cuando exista) sigue el mismo mecanismo por
  VIN — no hace falta tratamiento distinto de tu lado.
