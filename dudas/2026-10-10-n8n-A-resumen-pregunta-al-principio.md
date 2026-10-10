# Duda · Agente n8n · A · la pregunta del resumen sale al principio (diagnóstico, sin tocar nada)

**Caso:** E2E de Recovery de Alberto en STG, `waq_2983`, fila **16911** (22:46 UTC), exec **88013**. La burbuja empieza por «Persona,
¿todo correcto? Con tu sí, emito tu póliza.» y después viene «¡Excelente! Ya tenemos todo 🎉». Contexto: `#551`.

## Qué nodo la compone
**El modelo, no el carril de Recovery ni el grafo.**
- La fila 16911 no lleva `source`: sale por el camino normal del `AI Agent`, no por `Recovery Resumen Copy` (que pone la pregunta al final
  y lleva `source: recovery_resumen`).
- En la exec 88013, la salida del `AI Agent` ya empieza por la pregunta. `Rebuild Summary From Record` («reconstruido») rehace solo el
  bloque de datos, desde «Vehículo:» hasta el domicilio, y **conserva tal cual** lo que el modelo escribió antes. No reordena ni antepone
  nada.

## Por qué: el prompt se contradice desde el viaje 6
Las dos instrucciones están en el `systemMessage`, igual en STG (`e8f861f1`) y en PROD (`1b869a0f`):
- «Envía UN solo mensaje… **con la pregunta de confirmación AL INICIO del mensaje (no al final)** — WhatsApp trunca mensajes largos…».
- La plantilla «MENSAJE ÚNICO - RESUMEN COMPLETO», firmada en el viaje 6, termina en **«[Nombre], ¿todo correcto? Con tu sí, emito tu
  póliza.»**, al **final**. La regla del cierre también habla de lo que va después del domicilio.

**Cómo lo resuelve el modelo, medido en todos los resúmenes de STG (`*Domicilio:*`):**

| época | resúmenes | qué va antes de «Vehículo:» |
|---|---|---|
| hasta el 6 oct (plantilla vieja) | 19 | «¡Listo! Ya tenemos todo 🎉 ⏎ [Nombre], confírmame que todo está bien y procedemos a la emisión:», la confirmación al inicio y después de la apertura |
| desde la plantilla nueva | 3 | 15258 (Sonnet 5, 18:06): solo la apertura; 16901 (Sonnet 5.5, Recovery): solo la apertura; **16911 (Sonnet 5.5, Recovery): la pregunta de cierre DELANTE de la apertura** |

- **En PROD** (Sonnet 5) los 12 últimos resúmenes son de antes del viaje 6 y siguen la forma vieja. Desde el viaje 6 no ha habido
  ninguno, como dices.

## Respuestas
1. **El nodo:** el `AI Agent`. `Rebuild Summary From Record` solo conserva el texto que el modelo puso delante del bloque.
2. **¿Pasa fuera de Recovery?** El mecanismo no tiene nada de Recovery: es el prompt general. Fuera de Recovery solo hay un resumen con la
   plantilla nueva (15258), y salió bien. Es **1 de 3** desde la plantilla nueva, los dos con Sonnet 5.5 y en Recovery. Con N tan bajo no
   se puede atribuir al modelo ni a Recovery: hace falta un arnés (N=20 con cada modelo, sesión normal y de Recovery).
3. **¿Está en PROD?** Sí, las dos instrucciones están en `1b869a0f`. Puede pasar en PROD en cuanto haya resúmenes.

## Propuesta (para decidir; no construyo)
- **(a) Prompt** (firma de Alberto): quitar la contradicción y decidir **dónde** va la pregunta. La razón de «al inicio» era que WhatsApp
  corta los mensajes largos con «Leer más». La plantilla firmada la pone al final.
- **(b) Grafo:** que `Rebuild Summary From Record` componga **todo** el mensaje (apertura + bloque + pregunta, en el orden firmado), como
  ya hace `Recovery Resumen Template` en el carril determinista. Así el orden no depende del modelo. Es la filosofía del `#536`, extendida
  al marco del resumen.
- En los dos casos, primero el arnés N=20 para medir la frecuencia real con Sonnet 5 y con 5.5.

## Preguntas
1. ¿Dónde va la pregunta: inicio o final? Lo decide Alberto.
2. ¿(a), (b) o las dos? Recomiendo (b) con el orden que firme Alberto, y (a) para quitar la contradicción.
3. ¿Mido antes la frecuencia con el arnés (N=20 × 2 modelos × normal/Recovery)?

Agente: Agente n8n · A
