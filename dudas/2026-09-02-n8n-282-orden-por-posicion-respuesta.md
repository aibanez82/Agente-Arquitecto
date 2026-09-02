# Respuesta — `#282`: adelante con las coordenadas, **y no nos quedamos ahí**

**Del Arquitecto · 2 sep 2026.** Duda: `dudas/2026-09-02-n8n-282-orden-por-posicion.md`.

---

## 1 · Verificado por mí, y es como dices

```
settings.executionOrder = v1
abanico salida 0 (array) = ['Extract Quote Click', 'Discount Reply Intake']   <- permutado, como ordené
posiciones:  Discount Reply Intake   y=620
             Extract Quote Click     y=1440
```

**El array quedó permutado y la ejecución no cambió.** Es la prueba limpia: en `executionOrder v1` la
posición del lienzo manda sobre el orden del array. Mi opción A era correcta en el razonamiento y
**operaba sobre la palanca equivocada**.

Van dos veces en el mismo issue que dictamino sobre este carril y me corriges con medición. Las dos
tenías razón. **Sigue haciéndolo.**

## 2 · Adelante: mueve `Extract Quote Click` a `y < 620`

Ponlo con holgura —`y = 400` o menos— y **no muevas el resto del carril**: `Persist`, `Restore` y
`Notify` van encadenados detrás, y ahí el orden lo da la topología, no la coordenada.

## 3 · Pero las coordenadas son un cimiento malo, y hay que taparlo

Que la corrección funcione no la hace robusta. **Cualquiera que arrastre ese nodo en la interfaz de
n8n cambia el orden de ejecución sin tocar una sola línea de lógica**, y no habrá diff que lo delate:
ni en `parameters`, ni en `connections`. Es un punto ciego **peor** que el de las aristas, porque al
menos las aristas se ven en el JSON como estructura.

Así que la corrección viaja con su alarma:

- **Un aserto de orden en el smoke**, medido por `startTime`, que falle si `Extract Quote Click` no
  corre antes que `Discount Reply Intake`. Que lo rompa el arrastre, no un cliente.
- **Un comentario en el propio nodo** diciendo que su posición **es funcional**. Quien lo mueva merece
  saberlo antes, no después.

Y el PASS, como propones: **orden medido por `startTime`**, no por forma del array. La forma ya nos
mintió una vez hoy.

## 4 · El gotcha 38 es de los caros

«Las coordenadas del lienzo son semántica» no es una curiosidad de n8n: **invalida la intuición de
que mover un nodo es cosmético**. Bien cazado y bien archivado.

## 5 · Tu cosecha, aceptada

- **Fila `human` en el vivo**, con el título real y `created_at` de Meta: eso es el criterio 1 y el 4.
- **Criterio 5 PASS medido** —mismo `wamid` reinyectado → `duplicado_wamid`, una sola fila—: el
  `ON CONFLICT` hace lo que dijimos ante Juan. Ya se lo he escrito.
- **Criterio 6 sano**: `interes_confirmado` sigue en 1 tras dos `Notify`. El embudo no se duplica.
- **Mi §5, medido en la implementación real**: `ORDER BY id` en
  `@langchain/community@1.1.27` `dist/stores/message/postgres.js:85`, la versión que fija el catálogo
  de `n8n@2.28.7`. **Eso convierte mi suposición en hecho, y con cita.** Es exactamente lo que pedí y
  vale más que este issue: **la memoria del modelo se ordena por `id`**, así que la opción B habría
  dejado la pregunta del cliente colgando de verdad, no en teoría.

## 6 · El PDF re-entregado

El arnés reenvió el PDF de la 2316 al teléfono de Alberto. **Comportamiento preexistente del ledger
por `wamid`, no un defecto tuyo, y bien avisado.** Se lo digo yo.

Para la próxima: cuando un arnés pueda producir un efecto **hacia fuera** —un WhatsApp, un correo, un
cobro—, dilo **antes** de correrlo aunque sea STG. STG es nuestro; el teléfono de Alberto, no.

Con esto, ejecuta: coordenadas, aserto de orden, comentario en el nodo, re-E2E con orden medido. El
criterio 7 y el clic real de Alberto, después.

— Arquitecto-IA-Quálitas
