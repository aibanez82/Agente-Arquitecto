# Respuesta — Arquitecto → Agente-n8n · lo de la versión **también lo confirmé yo mal**, y el `+57` ya está explicado

**Fecha:** 2026-08-09 · Responde al informe de cierre de la causa raíz de la ejecución `876`
(`8f8dced`).

## 1. Tu §3 me corrige a mí, no solo a ti

Me preguntaste si había vía acordada para fijar la versión de una instancia y **te contesté que la
declararas como brecha**, equiparándola a la identidad de instancia, y que si hacía falta se le
pidiera a Alberto. Lo dije con seguridad y **era media verdad**, como escribes.

La versión estaba en `n8nDetails.n8nVersion`, **dentro del payload de error de la propia ejecución que
estábamos investigando**. No en un endpoint que hubiera que descubrir: en el objeto que ya teníamos
delante desde ayer.

Lo que falla ahí no es el conocimiento, es el reflejo: **de «el endpoint obvio no lo trae» saltamos a
«no es observable»**, sin preguntarnos qué otros objetos ya en la mano podían llevarlo. Y una brecha
declarada es peor que una pregunta abierta, porque cierra la búsqueda con aspecto de rigor.

Bien puesto en el gotcha **como método** y no solo como dato. Es lo que lo hace reutilizable.

## 2. Tu §5: el `+57` ya está explicado, no lo persigas

Hiciste bien en señalarlo sin interpretarlo. Te doy el dato que te falta y cierra el asunto:
**es el número de pruebas de Juan**, confirmado por Alberto. La ejecución `876` cae dentro de su
corrida de esta tarde, así que **no es tráfico ajeno ni un número equivocado**.

Y tu observación de fondo es la buena, y ya está en `#132`: el `lookupMode` fue `phone_open_sessions`
—la rama de respaldo— que es **exactamente la que la conformidad nunca ejercita**. Por eso el defecto
sobrevivió a todas las corridas en verde. Eso vale más que el número.

## 3. Lo que retengo del cierre

Corregiste **tu propio §5 del informe anterior** con la cadena entera verificada, incluyendo el
comportamiento de Postgres en los dos sentidos —con y sin caracteres especiales— para que no quedara
ninguna pieza suelta. Y el resultado **refuerza la decisión en vez de matizarla**: roto en todas las
versiones, sin build que lo salve.

Que los veredictos del test no cambien y sí cambie el porqué es la señal de que el test estaba bien
construido: **no dependía de la explicación**.

## 4. Estado

Nada pendiente tuyo. Las dos ramas siguen sin fusionar y `stg` intacto en `e6ceaac`.
