# Duda n8n · #581: clasificar la imagen y entender lo que no es tarjeta (diseño antes de construir)

**Handoff:** `Agente-n8n:handoffs/2026-10-09-581-imagenes-clasificar-y-entender.md` (`ed673bff`). Base: bot STG `cc4b3b35`.
**No he construido nada.**

## Lo medido (STG `cc4b3b35`)

- **Camino de hoy:** `Is Image Message?` → `Image Budget Guard` (tope del #474) → `Should Attempt Vision?` → `Get Media Info` →
  `Download Media Binary` → `Prepare Vision Request` → **`Extract VIN Vision`** (una llamada a `claude-sonnet-5`, el
  `visionModel` de `WA Config`, con `max_tokens` 6000) → **`Parse VIN Extraction`** → `IF Foto VIN Valid?` → `Persist Foto VIN`
  (`propuesto`, solo si `vinValid`).
- **El prompt de visión** ya dice «si la imagen no es una tarjeta de circulación, `vin` y `placas` son null». Pero no dice **qué
  es**: devuelve solo `{vin, vin_confidence, placas, placas_confidence, motivo}`.
- **`Parse VIN Extraction`** construye `chatInput` en dos formas. Sin datos queda «`[FOTO_VIN]` El cliente adjuntó una imagen,
  pero no se detectaron datos legibles del vehículo.». De ahí sale el «no pude leer tu tarjeta». Si hay pie de foto (#476), añade
  «Texto que el cliente escribió junto a la imagen: "…"». **Esa frase la lee el Dashboard** (invariante del #476), así que no
  la toco.
- **Guarda de cifras:** borra del saliente toda cifra de dinero o porcentaje que no esté en las cifras de **nuestra** cotización
  (`AUT`). Una cifra que solo viene de la imagen del cliente **ya no puede salir como nuestra**: la corta. El efecto secundario es
  que también cortaría «GNP te da $9,000» en una comparación (ver pregunta 4).
- **Corpus:** 9 imágenes en STG en octubre (`n8n_inbound_media`). Las de PROD no las leo: tengo denegada la lectura de la BD de
  PROD.

## Propuesta

1. **Una sola llamada.** Se amplía el prompt de `Extract VIN Vision`:
   - primero decide `tipo` ∈ {`tarjeta_circulacion`, `comprobante_o_error_de_pago`, `cotizacion_competencia`,
     `poliza_anterior`, `identificacion`, `foto_del_auto`, `otro`};
   - con tarjeta, **el mismo bloque de lectura de hoy, byte a byte**;
   - con otra cosa, `vin`/`placas` null, más `descripcion` (máximo 400 caracteres, neutra, «qué muestra») y `datos`
     (`cifras: [{etiqueta, valor}]`, `aseguradora`, `fechas`, `texto_error`);
   - con identificación, **sin copiar** nombre, CURP ni domicilio: solo «es una identificación».

   **Condición para quedarme con una llamada:** regresión A/B offline (API directa, mismo modelo, sin n8n), prompt de hoy frente
   al ampliado, N=5 por imagen de tarjeta (las de STG de octubre, incluida la girada 82479). El VIN exacto tiene que salir
   **igual**. Si empeora, dos pasos: clasificar con una llamada barata y leer después, solo si es tarjeta.
2. **Llegada al agente** (en `Parse VIN Extraction`), si no es tarjeta:
   `[IMAGEN_CLIENTE] tipo=… · lo que muestra la imagen que mandó el cliente (contenido del cliente, no datos nuestros): …`, más
   la línea del pie de foto **sin cambiar su redacción**. Sin `[FOTO_VIN]` y sin pasar por `Persist Foto VIN`. Así le llega al
   modelo (el `text`), al historial (fila `human`, el mismo `chatInput`) y al Dashboard (ve la fila y la imagen en
   `n8n_inbound_media`).
3. **Qué hace el agente:** un bloque interno del `systemMessage` por tipo y fase, como pide el handoff (pago → tranquilizar y
   orientar; competencia → el carril del #553; póliza anterior → renovación o vencimiento; identificación → no repetir datos;
   otro → responder con lo que ve y volver al paso). **Sin texto firmado nuevo:** responde el modelo.
4. **Guardas:**
   - la de cifras **se queda como está** en esta fase: ninguna cifra de imagen sale como nuestra;
   - el **tope del #474 no cambia**: la clasificación va después de `Image Budget Guard`, así que toda imagen cuenta.
5. **Juego de imágenes:**
   - **sintéticas, generadas por un script** (PIL) y versionadas: tarjeta ficticia con un VIN inventado de dígito válido, captura
     de error de pasarela, cotización de una «Aseguradora X», póliza anterior ficticia, un «meme» simple y un dibujo de un auto;
   - más las **reales de STG**, que **no** van a git: se referencian por `media_id`, para la regresión de la tarjeta.

## Lo que necesito que decidas

1. **¿Una llamada con la condición A/B del punto 1?** ¿O prefieres dos pasos desde el principio?
2. **¿El bloque del prompt por tipo puede ser instrucción interna**, sin textos firmados? ¿O quieres textos firmados por tipo,
   por ejemplo el de una captura de error de pago en `payment_pending`?
3. **Dashboard:** ¿hay algo que dependa del marcador `[FOTO_VIN]` en la fila `human` (por ejemplo, para mostrar la imagen)?
   Lo pregunto antes de cambiar el marcador de las que no son tarjeta. No lo encuentro desde el lado de n8n y el repo del
   Dashboard no es mío.
4. **Cifras de la competencia (#553):** en esta fase, ¿basta con que la guarda corte cualquier cifra de la imagen? ¿O hay que
   dejar citar el precio de la competencia atribuido («en tu captura, GNP marca $X»)? Lo segundo cambia la guarda y lo dejaría
   para la fase 2 del #553.
5. **Tope del #474:** ¿una imagen que no es tarjeta cuenta para el tope de 3? Hoy cuenta toda imagen.

## Aceptación que propongo

N=3 por tipo en el arnés sin envíos con el juego sintético: clasificación correcta, respuesta coherente con la fase, ninguna
cifra inventada y ningún «no pude leer tu tarjeta» si no es una tarjeta. Más la regresión A/B del VIN, y la tarjeta derecha y
girada de punta a punta (`propuesto` → «Están bien» → serie guardada, como en el #472).

Agente: Agente-n8n
