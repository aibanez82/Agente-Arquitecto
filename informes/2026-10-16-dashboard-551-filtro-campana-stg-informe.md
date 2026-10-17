# Informe — Filtro «Campaña de recuperación» (#551) en stg

**De:** Agente Dashboard · **Para:** Arquitecto · **16 oct 2026**
**Orden:** `/Users/AIP/claude-projects/Dashboard_SeguroAuto/handoffs/2026-10-16-filtro-campana-recovery.md` (4147188)

## Dónde está

- **`stg`=`f83c5f3`** (merge de `feature/551-filtro-campana-recuperacion`, commit con el cambio dentro de la rama). Preview `dpl_CMtV4A66PyLpLsNWLi3gGu9DMaeu` en READY: https://dashboard-seguroautoqualitas-git-stg-albers-projects-52295059.vercel.app
- **Sin `main`.** A PROD, con orden de Alberto.
- **Pruebas:** suite 931/931 y build. El test nuevo, `/Users/AIP/claude-projects/Dashboard_SeguroAuto/scripts/s1/test/campana-recuperacion-551.test.js` (11 casos), da 4 rojos sin el cableado.

## Qué hace

- **La marca:** `/Users/AIP/claude-projects/Dashboard_SeguroAuto/apps/operacion/lib/campanaRecuperacion.js`.
  - Es tu consulta (`result_quote_id` de un participante → campaña), **por cotización, nunca por teléfono**.
  - Si una cotización saliera en dos participantes, gana la respuesta más reciente (hoy 0 en STG).
  - Un descuento posterior hereda la marca por la raíz de su cadena (`discount.continuation.root_quote_id`) y la etiqueta lo dice.
  - **Antes de leer**, una sonda comprueba que existen las dos tablas y que el rol puede leerlas (`has_table_privilege(current_user, …)`). Si falta algo, las filas salen sin marca y el motivo viaja (`tabla-ausente`, `sin-permiso`, `error`): un cero nunca sale de una consulta rota. **No lanza**: no puede tumbar ni el embudo ni la bandeja.
- **Endpoints:** `db-leads` e `inbox` añaden `campana_recuperacion` (`{ id, nombre, heredada }` o `null`) a cada lead, y un resumen por campaña (`resumen.campanaRecuperacion` / `campanaRecuperacion`).
- **Pantalla:**
  - **Etiqueta** «↺ Recuperación · <campaña>» en la fila de la bandeja, del embudo y de sus ventanas.
  - **Filtro** «Campaña de recuperación»: todas / solo campaña / sin campaña, más un selector por campaña si hay más de una, y el contador en el botón («Solo campaña · N conversaciones» en la bandeja, «N leads» en el embudo).
  - **En la bandeja** el filtro va **antes** de agrupar por teléfono, porque el cliente de la campaña comparte número con su cotización antigua. Si la marca está en otra cotización del mismo cliente, la etiqueta lo dice («· otra cotización»).
  - **En el embudo** el filtro recorta **embudo y tabla** a la vez, antes de la deduplicación, para ver cómo convierte la campaña.
  - El filtro solo aparece si en el periodo hay alguna conversación de campaña.
- **Solo lectura.** Superficie de BD actualizada en `/Users/AIP/claude-projects/Dashboard_SeguroAuto/docs/arquitectura/superficie-de-bbdd-del-dashboard.md`.

## Recuentos

**STG** (solo lectura, 16 oct):
- Las tablas existen y el rol las lee (`existe=t`, `legible=t`).
- Tu consulta da **3 cotizaciones**: 2579 (campaña 67), 2983 (101) y 2985 (134). Son los leads 1226, 1630 y 1632, los mismos 3 que marca el módulo.
- **Control positivo**, usado también en el test: el lead 1630 (cotización 2983) sale marcado; el 1628 (cotización 2981), mismo teléfono, no.

**PROD: no lo he medido.**
- El código no está en `main`, así que ningún endpoint de PROD lo devuelve.
- La BD de PROD solo la mido a través de la API con la sesión de Alberto.
- Tu cifra es la de referencia: 23 de la campaña 6, más 1 de la 5.
- En cuanto esté en PROD, comparo el contador del filtro con tu consulta.

**Rol de `DATABASE_URL`:** no puedo verlo desde aquí (la variable es de Vercel y no la leo). La sonda lo resuelve en ejecución: si el rol no tuviera `SELECT`, `campanaRecuperacion.motivo` diría `sin-permiso` en la respuesta de `/api/db-leads`, en vez de un cero. Lo miro en PROD junto con el recuento.

## Sin verificar en pantalla

El Preview pide sesión y yo no introduzco contraseñas. Lo veré cuando Alberto inicie sesión: la etiqueta en las tres conversaciones de STG y el contador.

Agente: Dashboard
