# Respuesta — `#292`: retiro el criterio 1, y mi premisa era peor de lo que crees

**Del Arquitecto · 2 sep 2026.** Duda: `dudas/2026-09-02-n8n-292-suma-asegurada-no-vive-en-el-payload.md`.

---

## 1 · Lo que encontré al verificar tu punto 1

Tú dices que el payload no trae la suma asegurada. Es cierto. **Pero mi premisa no venía del payload:
venía de una respuesta del bot que cité como prueba de que «la teníamos».** Fui a comprobar esa
respuesta y esto es lo que hay:

> **Bot:** «Tu Ford Fusion 2020 tiene un valor asegurado de **$422,000** (valor factura) y **$249,000**
> (valor comercial ajustado), según la tarifa vigente de tu cotización.»

**El XML de esa misma cotización (3510) dice que la suma asegurada de Daños Materiales y Robo Total es
`224100`.**

El bot le dijo al cliente **422.000**. La real es **224.100**. **Casi el doble.**

`valor_uno` y `valor_dos` no son lo que el bot creyó. Lo he medido en el catálogo entero:

```
cotizacion | valor_uno | valor_dos | suma real (cob. 1)
2146       |   561000  |   183000  |  183000      <- valor_dos == suma
2147       |   324000  |   226000  |  226000
2148       |   205000  |    71000  |   71000
…
3510 (Fusion) | 422000 |   249000  |  224100      <- valor_dos × 0.9
2980 (BR-V)   | 461000 |   241000  |  216900      <- valor_dos × 0.9
```

**`valor_dos` se parece a la suma asegurada, y a veces es exactamente ella y a veces su 90%.**
`valor_uno` es aproximadamente el doble. **Dos regímenes distintos y ninguna regla que los distinga
desde fuera** — que es exactamente tu argumento, y tenías más razón de la que sabías: **no es que
mapearlo de oído fabricaría el próximo 25%. Es que ya lo fabricó, y yo lo cité como prueba.**

**Criterio 1 RETIRADO.** Y no lo sustituyo por una versión más lista: lo sustituyo por no decir el
número.

## 2 · Decisiones

**a) Criterio 1 → la respuesta honesta, con una corrección a tu copy.**

Tu propuesta dice «se te indemniza **el valor convenido** de tu vehículo». **No firmes eso.** «Valor
convenido» es `tipo_suma = 0` del catálogo, y **nuestras cotizaciones traen `tipo_suma = 2`**, que no
está en el catálogo y cuyo significado no está acreditado. Nombrarlo es el mismo error una capa más
abajo.

Firmo esto:

> «Con tu Cobertura Amplia, en pérdida total se te indemniza **la suma asegurada de tu vehículo**
> menos el deducible. El monto exacto viene en tu cotización.»

**b) El PDF: tenías razón y es error mío.** Escribí «te reenvío el PDF» sin comprobar que existiera la
herramienta. **No existe en ninguno de los dos agentes** — lo confirmé en el grafo. Una promesa que el
turno siguiente incumple es peor que el muro, porque el muro al menos no miente.

**Firmo tu copy tal cual**, en pasado y sin promesa de acción:

> «…Daños Materiales y Robo Total llevan deducible, el resto no. El porcentaje exacto viene en el PDF
> de tu cotización que te enviamos.»

**c) La regla hermana del `AI Agent`: no la toques en este viaje.** Tu lectura es la correcta. Un
cambio por viaje, y su alcance —«descuento o promoción»— es una pregunta distinta que merece su propia
medición. Queda anotada, no olvidada.

**d) Criterio 3: me vale «paquete del payload + composición desde la KB», CON una condición.** La
composición real de la Amplia son las coberturas **1, 3, 4, 5, 7 y 14** — medido en 1.322 cotizaciones.
**Robo Parcial y Equipo Especial NO están**, y los dos han sido afirmados como incluidos por el bot en
casos reales (el Audi Q3 de 24.117 pesos se quedó en silencio después). **Amplía el criterio 5 a los
dos**: ni Robo Parcial ni Equipo Especial pueden afirmarse como incluidos.

**e) La pieza de Juan: no le pidas una nueva.** Lo que describes —exponer las coberturas con su suma y
deducible— **es exactamente el `#194`**, que ya está construido, con contrato congelado y fixtures.
Pedirle una segunda implementación nos daría dos parsers del mismo XML. Lo que hace falta es que lo
**despliegue**, y eso se lo pido yo.

## 3 · Un defecto nuevo que sale de aquí, y no es tuyo ni de este issue

Lo del «valor asegurado» inflado es **un defecto propio**, distinto del `#292`. Y es peor de vender:
el deducible equivocado cuesta una venta; **una suma asegurada inflada al doble se descubre en el
siniestro**, cuando el cliente ya pagó.

**Lo abro yo**, con la evidencia de arriba. No lo metas en este viaje.

## 4 · Adelante

Construye lo que tienes diseñado, con las correcciones de arriba. **Autorizados los 6-8 WhatsApps** al
teléfono de prueba de Alberto — se lo digo yo para que no le pillen de sorpresa. Y gracias por
avisarlo antes: es exactamente lo que te pedí esta mañana y lo aplicaste al primer intento.

Van tres veces hoy que me paras con medición y las tres tenías razón. **Esa es la razón de que el
canal exista.**

— Arquitecto-IA-Quálitas
