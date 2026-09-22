# Informe — el embudo ya no pierde un pago en un lead intermedio (`#304`)

**De:** Agente Dashboard · **Para:** Arquitecto-IA-Quálitas · **Fecha:** 22 sep 2026
**Responde a:** `Dashboard_seguroautoqualitas:handoffs/2026-09-22-el-embudo-no-puede-perder-un-pago-de-la-cadena.md` (`7fd966b`)

## Estado

Hecho y mergeado a **`stg` = `0ce3983`**. **NO promovido a `main`.** Tu handoff dice «promoción a
`main` con la misma autoridad», citando un «tienes autoridad» de Alberto del 22 sep; a mí no me
consta esa orden en mi sesión, y la regla que sigo es que `main` solo se toca con su palabra
directa. Se lo he pedido; en cuanto la dé, promuevo y añado a este informe los números de PROD
antes y después.

## Lo construido

`apps/operacion/lib/s1/continuation.js`, en `leadsPorRootConfirmado`:

- La fila sigue siendo la del leaf, pero **hereda el hito más avanzado de la cadena**. Sigue siendo
  **una** adquisición: se hereda evidencia, no se añaden filas.
- Si el leaf no tiene póliza, hereda `numero_poliza`, `estatus_pago`, `conversation_phase` y
  `fecha_emision` del intermedio más avanzado (`poliza_en_intermedio`).
- Si un intermedio está **pagado**, la adquisición cuenta como pagada aunque el leaf tenga su propia
  póliza pendiente (`pago_en_intermedio`), y se conserva `poliza_pagada_en_intermedio` para poder
  auditar cuál se pagó. El `numero_poliza` que se muestra sigue siendo el del leaf, que es la vigente.
- Pagada mantiene la definición literal del Bug #7: `PAGADO` **o** `completed`, y nunca sin
  `numero_poliza`.
- `computeResumenApi` publica **`pagosEnIntermedio`** y **`polizasEnIntermedio`**.

## Una corrección sobre la marcha, y por qué importa

Mi primera versión (`3465d11`) solo heredaba cuando el leaf **no** tenía póliza. Con ese criterio, el
caso de tu handoff —intermedio pagado, hoja emitida sin pagar— **seguía contando como no pagada**. Lo
descubrí midiendo STG, no razonando: la cadena **836 → 837** es exactamente ese caso. Corregido en
`74e64df`, con su test.

## Aceptación

- **Fail-first:** 3 de los 5 casos iniciales fallaban contra el código anterior (el del intermedio
  pagado, el de dos pagos en la cadena y el de la póliza emitida en el intermedio).
- **Controles:** pago en la hoja igual que hoy; lead sin cadena intacto; dos pagos en la misma cadena
  cuentan **una** adquisición pagada y el marcador vale 1.
- IDs **string** en todos los stubs.
- **Suite: 508/508** con `HYL_WAI_REPO`, 0 saltadas.

## Números

| | Total | Contestan | Emitidas | Pagadas | `pagosEnIntermedio` |
|---|---|---|---|---|---|
| STG, código anterior (misma BD, hoy) | 158 | 55 | 47 | **14** | — |
| STG, código nuevo | 158 | 55 | 47 | **15** | **1** |

El +1 es la cadena 836 → 837: un pago real que hasta hoy no se contaba.

**PROD: sin medir todavía**, porque no está promovido. Tu medición del 21 sep (0 intermedios con
póliza) dice que no debería moverse ningún número y que el marcador debe dar 0; lo verificaré contra
`/api/db-leads` en cuanto se promueva.

— Agente Dashboard
