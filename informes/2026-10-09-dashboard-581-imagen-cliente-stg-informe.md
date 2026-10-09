# Informe (Dashboard): `#581` — el timeline reconoce `[IMAGEN_CLIENTE]`, en `stg`

**De:** Agente Dashboard · **Para:** Arquitecto · **9 oct 2026**
**Responde al handoff** `Dashboard_SeguroAuto:handoffs/2026-10-09-581-marcador-imagen-cliente.md` (nuestro `main` = `3bb6b9e`).

## Estado

En `stg` = `bcaf8ba` (rama `feature/581-imagen-cliente`, commit `1c394e6`). Suite 856/856 y `build` en verde. **No está en `main`.**
Viaja a PROD solo junto con n8n y con la orden de Alberto.

## Formato: coincide con el informe de n8n

Lo contrasté con `Agente-n8n:informes/2026-10-09-n8n-581-imagenes-stg.md` (`e133026f`): las tres líneas, los seis `tipo` y la variante
`[FOTO_VIN] TOPE DE LECTURAS DE TARJETA ALCANZADO…`. No hace falta tocar nada.

## Qué hace (punto 2: la propuesta de producto)

- **Una línea del sistema, siempre**, también con la burbuja de la imagen al lado (es justo lo que la burbuja no dice):
  «🖼️ Imagen del cliente: Cotización de otra aseguradora». Lleva el mismo estilo que la nota del sistema de `[FOTO_VIN]`.
- **Etiquetas:** `comprobante_o_error_de_pago` → «Comprobante o error de pago» · `cotizacion_competencia` → «Cotización de otra
  aseguradora» · `poliza_anterior` → «Póliza anterior» · `identificacion` → «Identificación» · `foto_del_auto` → «Foto del auto» ·
  `otro` → «Otra imagen». Si el `tipo` falta o no se conoce: «Imagen del cliente», sin inventar.
- **La descripción y los «Datos legibles»**, solo al pasar el ratón. En `identificacion`, **ni eso**: lleva datos personales.
- **El texto del cliente** va entero en su burbuja. Mandar la imagen sola cuenta como respuesta del cliente.
- **Bandeja:** la vista previa dice «🖼️ <etiqueta>», o el texto del cliente si lo hay. Nunca el marcador en crudo.
- **Regresión:** `[FOTO_VIN]` se ve igual. La variante del tope cuenta como texto del sistema, también con pie de foto.

## Lo que NO está comprobado

- **Con filas reales:** en `n8n_chat_histories` de STG hay **0** filas con `[IMAGEN_CLIENTE]` y 0 con «TOPE DE LECTURAS» (medido
  el 9 oct, después del informe de n8n). Las 21 de aceptación no dejaron historial. Los tests usan el formato del informe; con la
  primera imagen real que no sea tarjeta en STG, lo vuelvo a pasar por el analizador.
- **Pintado en pantalla:** el Preview pide contraseña. Si Alberto manda en STG una imagen que no sea tarjeta, lo ve en Chats.

Agente: Dashboard
