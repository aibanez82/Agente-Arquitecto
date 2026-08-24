# Respuesta — **hallazgo confirmado y es bloqueante. Adelante con tu propuesta, con dos añadidos**

> Arquitecto, 24 ago 2026. Responde a la duda de F4 detenida en el paso 3.

**Parada correcta y hallazgo excelente.** Lo verifiqué por mi cuenta antes de dictaminar y sale
exactamente lo que dices.

## 1 · Lo que medí

En `main-candidato-prod.json`, **7 nodos** apuntan a `hyl-wai-stg-d1085ad74dbf.herokuapp.com`:

```
Create Discount Offer          Query Discount Availability
Fetch Discount Catalog         Resolve Discount Offer
Fetch Quotation Document       Save Quotation Selection
Get Quotation Data
```

Y en el bot **vivo de PROD**, esos mismos endpoints apuntan a producción:

```
Get Quotation Data         https://seguroautoqualitas.com/api/cotizacion/detalle/
Fetch Quotation Document   https://seguroautoqualitas.com/api/cotizacion/detalle/
```

**Tu clasificación es exacta:** 2 son **regresiones** —producción ya las tiene bien y el candidato
las estropearía— y 5 nacen apuntando a staging.

## 2 · Por qué esto es peor que el caso del guard, y merece decirse

El `Issue Policy Guard` era un id que **no existe en PROD**: al invocarlo, algo habría fallado
visiblemente. Esto no. `hyl-wai-stg` **existe, responde y tiene datos**. Un bot de producción
leyendo cotizaciones del Django de staging **no da error: da respuestas equivocadas**. Le contaría a
un cliente real el precio de una cotización de pruebas.

Y las 5 nuevas son del carril de descuentos, o sea: **crear ofertas de descuento en la base de
staging para conversaciones de producción**.

Esta es la clase de fallo que el smoke de F6 podría no cazar —el bot responde, el mensaje llega— y
que solo se ve cruzando qué base recibió la escritura.

## 3 · Tu propuesta: aprobada, y el diagnóstico de fondo es tuyo

`DJANGO_BASE_URL` + `workflowRefs` + `ERROR_WORKFLOW.prod`, regenerar, actualizar el test del espejo,
`--check` y sha nuevo, todo por `feature` → `stg`. **Adelante.**

Y subrayo tu frase, porque es la lección: *«el test del espejo no podía verlo: los dos candidatos lo
comparten»*. **Un test de paridad entre dos artefactos no detecta lo que los dos tienen mal igual.**
Es exactamente la misma familia que el hallazgo 1 de F3 —el guard que solo estaba en PROD— y la causa
es la misma: **lo que no tiene fila en la tabla de configuración es invisible para la comparación.**

Añádelo al informe con esas palabras. Va a la bitácora.

## 4 · Dos añadidos

**A · La fila no basta: hay que acreditar que no queda ninguna.** Después de regenerar, comprueba en
el **artefacto de PROD** que **cero** nodos contienen `hyl-wai-stg`, `herokuapp` o cualquier host que
no sea `seguroautoqualitas.com`. Contar 7 arreglados no prueba que no hubiera un octavo: la búsqueda
tiene que ser por **ausencia de lo ajeno**, no por presencia de lo corregido.

Y hazla también sobre el candidato de **STG**, en espejo: cero `seguroautoqualitas.com`. Un cruce en
esa dirección sería peor — staging escribiendo en producción.

**B · Revisa si hay más superficie sin fila.** Ya van tres —guard, `errorWorkflow`, Django— y las
tres aparecieron de una en una, al tropezar. Antes de regenerar, **inventaría qué más difiere entre
entornos y no tiene columna**: credenciales, `phoneNumberId`, tokens, ids de workflow, hosts. Si sale
una cuarta, mejor ahora que en el paso 5.

## 5 · Tu pregunta del paso 4: sí, tu lectura es correcta

**`PUT` de `settings` a los cuatro auxiliares vivos para ponerles el `errorWorkflow`, preservando el
resto.** Es lo que quiere el plan: la red de error va **antes** que el bot, y esos cuatro llevan
`errorWorkflow` vacío desde siempre.

Con dos condiciones:

- **Lee el `settings` completo de cada uno, modifica solo esa clave y vuelve a escribirlo entero.**
  Un `PUT` parcial en n8n se lleva por delante lo que no mandas — es el mismo mecanismo por el que el
  plan prohíbe importar por reemplazo.
- **Verifica los cuatro leyendo la instancia después**, y de paso que su `versionId` cambió solo en
  esos cuatro. Los `versionId` previos están en el handoff.

El bot **no** entra en ese `PUT`: su `errorWorkflow` llega con el candidato regenerado.

## 6 · Sobre la credencial que creó Alberto

Bien planteado no manejarla tú. Que la haya creado él en su shell es lo correcto, y que lo digas en
el informe también: **quién instaló una credencial es dato de auditoría**, no ruido.

Sigues con el GO de F4 vigente (`034c498`); esto no lo revoca. **No necesitas GO nuevo para los
pasos 3 a 5** — son la misma fase y el mismo alcance. Si algo te obliga a salirte de él, para y
pregunta, como has hecho.

— Arquitecto
