# `#536` adenda 2 — póliza emitida desde el registro; los dos resúmenes rehechos y el `request_hash` cuadra. La memoria es NO COMPROBABLE

> De: Agente QA & Testing · Para: Arquitecto-IA-Qualitas · 5 oct 2026
> Responde a: `Agente_QATest_Qualitas:handoffs/2026-10-04-536-e2e-emision-desde-el-registro.md`, adenda 2 (`69c70bf`)
> Autorización: la firma de Alberto en el fichero; Alberto, en mi sesión: «retoma».
> Versiones medidas por GET justo antes de la corrida: bot `dNqtM20ij6ecZYAX` **`f21ff7a2`** (417 nodos) · guard
> `PuogahK4qv9YOiF4` **`86086e91`** (17 nodos). Coinciden con la adenda 2. El runner repite la medición y para si no cuadra.
> Runner: `Agente_QATest_Qualitas:runners/e2e_emision_registro_stg.js` (`d871488`), `QA_536_PATERNO=Pérez`. Corrida: **`20261005-2006-536`**, N=1.

## Veredicto: 16 PASS · 0 FAIL · 1 NO COMPROBABLE · 1 WARN (residuo declarado)

| # | Aceptación | Resultado | Dónde |
|---|---|---|---|
| 1 | Cuerpo de `Call Issue Policy Real`: Fresno / 150 / `""`, y CP, teléfono, paquete y forma de pago idénticos a la cotización | **PASS** | guard 78188 |
| 2 | El primer resumen dijo Roble 222 / Int. 4B y el cuerpo no lleva Roble | **PASS** | bot 78181 frente al guard 78188 |
| 3 | Ningún resumen enseña el teléfono | **PASS** | los 2 resúmenes |
| 4 | Póliza creada en el QA de Quálitas | **PASS — `7620103881`** | respuesta de Django = fila en BD |
| 5 | Detectores «Continuamos con», «\*Domicilio:\*», «emitida exitosamente» | **PASS, los 3** | |
| A | Resumen del paso 5 por `Summary Reply? → Read Summary Record → Rebuild Summary From Record`, con Roble 222 / Int. 4B | **PASS** | bot 78181 |
| A | Resumen del paso 7 por esa misma ruta, con Fresno 150 y sin interior | **PASS** | bot 78185 |
| A2 | El `request_hash` que reserva `Claim Main Reply Outbound` es el del texto **rehecho** | **PASS en ambos** | paso 5: `494eb875…4ea3`; paso 7: `5dc33727…7c93`. Los dos son reservado = recalculado, y el texto del ítem es el de `Rebuild` |
| A2 | Tras el segundo resumen, `n8n_chat_histories` guarda el texto rehecho | **NO COMPROBABLE** | ver abajo |

Con «Pérez» como apellido, el RFC llegó como `PEQA900101` y Quálitas lo aceptó. El `#545` no se cruzó en esta corrida, como pretendía la adenda.

## Por qué la memoria es NO COMPROBABLE

1. `Sync Memory With Sent Reply` **no se ejecutó**. Depende de `Send message [0]`, y el fence corta el envío en la sesión
   sintética sin dígitos (`fence_corto: true`, motivo del Claim `control_contradictorio`). Así que no se ejercitó lo que la
   aceptación quiere medir.
2. Además, en esta corrida el texto del modelo y el texto rehecho **son iguales** (`igual_a_rehecho` e `igual_a_agente` son
   ambos `true`). Aunque la fila contiene Fresno 150, no permite saber cuál de los dos textos se guardó.

Para medirla hacen falta dos cosas a la vez: un envío real que el fence deje pasar y un turno en el que el modelo escriba
algo distinto de lo que rehace el grafo. Hoy el arnés no sabe fabricar ninguna de las dos.

## Observación fuera de las aceptaciones: el monto emitido no es el cotizado

- Monto en el registro (`precio_total`) y en los dos resúmenes: **$10,858.25**.
- Monto que devolvió Django al emitir (`monto_total` y `primer_pago`), y que el bot le dijo al cliente: **$11,775.69**.
  Son +$917.44, un +8.45 %.

No lo trato como defecto. La cotización 2938 es un **clon** de la 2683, y su precio puede estar caducado frente a lo que
Quálitas cobra hoy. Con esta corrida no puedo separar ese efecto de una discrepancia real entre cotización y emisión.
Busqué en `aguayo-co/HYL-WAI` (issues abiertos y cerrados, términos «monto emisión cotizado / prima emitida / monto_total»)
y no apareció ningún issue que lo recoja. Si interesa, propongo medirlo contra una cotización **recién hecha**, no clonada.

## Residuo

En STG queda `qualitas_leadfunnelevent` 760–763, que es append-only. Eso arrastra también al lead 1585 y a su asegurado y
cotización, por la FK. Es el mismo residuo que se declaró la vez anterior. La póliza `7620103881` sigue viva en el QA de
Quálitas: desde aquí no se puede borrar.

Archivos: `e2e-emision-registro-536.json`, `traza.json` y `corrida.log` en esta carpeta.

Agente: QA & Testing
