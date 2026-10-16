# Informe (Dashboard): `#614` en PROD — `dio_vin` solo con «Serie:»

**De:** Agente Dashboard · **Para:** Arquitecto · **16 oct 2026**
**Responde a** `/Users/AIP/claude-projects/Dashboard_SeguroAuto/handoffs/2026-10-16-614-dio-vin-solo-serie.md`, adenda 1. **Cierra** `/Users/AIP/claude-projects/Agente-Arquitecto/informes/2026-10-16-dashboard-614-dio-vin-stg-informe.md`.

## Hecho

- **PR #39**, rama `promocion/614-dio-vin-prod`, commit `205d235`: solo el neto del `#614`.
  - Los tres sitios de `dio_vin`, la fila de `dio_vin` en la doc y el test.
  - Aplicado **a mano sobre `main`**: el cherry-pick de `2e831ec` chocaba porque `main` no lleva el `#590`. Por eso **en PROD no viaja** la corrección de la fila de `dio_datos_personales` en la doc, que allí sigue siendo un `LIKE`.
- **Test** `dio-vin-614`: daba un falso rojo sobre `main`, porque la regex de la vigilancia arrancaba en otra métrica. Ahora va limitada a una línea, en el PR y en `stg` (`39e1517`).
- **Verificación:** suite **885/885**, verificadores y `build` en verde. `s1-conformidad` (run `38949879799`): `success`.
- **Merge:** con la orden de Alberto en mi sesión («fusiona el 39») → **`main` = `aba9ff1`**. El Dashboard salió **antes** que el bot, como pediste (es compatible hacia atrás).
- **Production:** **`dpl_48CGPxVrmEYM9r7vJa6Usx2FAqdj` READY**, commit `aba9ff1`, rama `main`. Lo saqué yo de la API REST de Vercel (`/v6/deployments`); tu token da `forbidden`, así que queda acreditado solo con esta lectura.

## Recuento en PROD

Lo **midió el Arquitecto** con SQL contra PROD el 16 oct, después del deploy; yo no lo he repetido:

| Regla | Sesiones |
|---|---|
| Nueva: solo «Serie:» | **84** |
| Vieja: «Placas» y «Serie:» | **81** |

- Por la mañana eran 83 y 80. Entre medias entró una sesión con resumen, y la **diferencia de 3** se mantiene: son los resúmenes sin placas que el detector viejo no contaba.

## Pendiente

Nada del `#614` en el Dashboard.
