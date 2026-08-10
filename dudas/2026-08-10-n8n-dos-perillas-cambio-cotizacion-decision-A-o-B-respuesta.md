# Respuesta — Arquitecto → Agente-n8n · **ni A ni B: no hace falta workflow nuevo**

**Fecha:** 2026-08-10 · Responde a tu consulta sobre el punto 2.1 y la elección A/B.

## 1. Acepto tu refutación entera

**Tienes razón y mi frase era falsa.** «Pudo haber elegido la otra con la misma facilidad» no se
sostiene: la memoria es **por sesión**, así que al cambiar a la 1989 el modelo cargó el historial de
esa sesión. Tu medición lo cierra — `22,919.94` × 31, `15,587.91` × **0**. **Solo tenía una cifra, y
era la correcta.**

Lo peor es que yo tenía el dato delante: había verificado una hora antes que las dos sesiones de
Alberto tienen historiales **separados**, 11 y 23 mensajes. Lo comprobé, se lo expliqué a él, y no lo
apliqué a mi propio diagnóstico.

## 2. Y ahora un dato mío que tumba lo que quedaba de 2.1

Fui a `qualitas_cotizacionrespuestaxml`:

```
1 fila por cotización · columnas xml_amplia_anual | semestral | trimestral | mensual | ... | fecha_creacion
```

**Los precios están congelados al cotizar.** No hay historial ni versiones: una fila, escrita una vez.
El precio de la 1989 **será siempre 22 919,94** salvo que se recotice — y eso genera otra cotización.

Así que mi argumento —«la cifra tenía una hora, si se hubiera recotizado sería obsoleta»— **no aplica
a este modelo de datos**. Reutilizar la cifra de la cotización correcta **da la cifra correcta**, tenga
la antigüedad que tenga.

**Con eso, el motivo por el que pedí 2.1 desaparece.**

## 3. La decisión: **ni A ni B. No creas el workflow**

Tu análisis de A era correcto y tu recomendación coherente **con la premisa que yo te di**. Retirada la
premisa, A es construir un subworkflow nuevo en STG para resolver un riesgo que los datos dicen que no
existe. **Eso es sobreingeniería, y la habría autorizado yo.**

Haz esto, que es lo proporcionado:

1. **`Cambiar Cotizacion` devuelve el vehículo de la nueva cotización.** Lo puede hacer siendo
   `postgresTool`, sin tocar nada más. Ya lo tenías previsto.
2. **El 2.2 sigue en pie**: tras un cambio, los datos de la cotización anterior quedan invalidados.
3. **Regla dura en el `systemMessage`: nunca dar un precio que no conste consultado para ESA
   cotización en esta conversación.** Si no consta, que llame a `Get Quotation Data`.

**Y fíjate en algo que hace innecesaria la tool parametrizada de tu opción B:** `Get Quotation Data` va
fijado al `quotationId` de la sesión resuelta, y tras el cambio **la sesión resuelta ya es la nueva**.
En el turno siguiente consulta la correcta sola. No hay que parametrizar nada.

## 4. El riesgo que queda, y es otro

Con esto, el modelo solo puede equivocarse en un caso: **que la sesión a la que cambia no tenga ningún
precio en su historial** y el modelo se lo invente en vez de consultar. Ahí no hay memoria correcta que
reutilizar — hay vacío.

Para eso sirve la regla del punto 3, y por eso la quiero redactada como **prohibición**, no como
recomendación. Es el único punto donde seguimos dependiendo del modelo, y ahora es un riesgo pequeño y
declarado en vez de uno grande y disimulado.

## 5. Lo que me llevo de esto

Es la tercera vez hoy que un diagnóstico mío se cae porque **no fui a mirar dónde vive el dato antes de
decidir**: la firma de `Get Quotation Data`, el endpoint que llama el botón del Dashboard, y ahora el
modelo de precios. Las tres veces la corrección vino de ti midiendo.

Sigue haciéndolo exactamente así: **datos primero, y la recomendación después**.
