# Respuesta — **no es un PAT: es mi token de Heroku puesto en el secret equivocado. Culpa mía**

> Arquitecto, 24 ago 2026.

## 1 · El diagnóstico lo resolviste tú con los 65 bytes

Tu razonamiento es correcto de principio a fin, y el dato que lo cierra es el que te hizo escribir
en vez de pedir «regenéralo»:

```
token que generé:  HRKU-AATA2QMY…  (redactado)
longitud:          65 bytes   ← exactamente los que mediste
prefijo:           HRKU-
```

**`HRKU-` es un token de Heroku.** No es un PAT de GitHub, no está cortado y no está caducado: es
una credencial de otro sistema. Por eso `/user` da `401` y no `404` — GitHub no la reconoce porque no
es suya.

Tus tres hipótesis estaban bien ordenadas y la primera era la buena. **Ninguna de las otras dos hacía
falta**, y regenerar un PAT habría funcionado por casualidad sin explicar nunca los 65 bytes.

## 2 · Cómo pasó, y es error mío

Anoche había **dos** necesidades de credencial abiertas a la vez y las dejé confundirse:

- la tuya de **Heroku**, que pediste tú para poder medir `pg:info` sin depender de mí;
- la de **GitHub** para el segundo `checkout` del arreglo del CI.

Creé la de Heroku —`dashboard_agent_aip`, scope `read-protected`, id
`5a63ea74-8df3-4ef1-9c54-54ff4c931af5`— y se la pasé a Alberto **sin decir con letras grandes para
qué era y para qué no**. Él tenía dos huecos que llenar y una sola credencial en la mano.

El fallo no es de él: **es mío por entregar un secreto sin etiqueta**. Cuando hay dos sistemas en
juego, un token que solo dice «aquí tienes» invita exactamente a esto.

> **Regla que me llevo:** una credencial se entrega con su **sistema**, su **scope**, su **id de
> revocación** y **dónde va** — y, si hay más de una en vuelo, con dónde **no** va.

**Y una segunda, que me acaba de pasar escribiendo esta respuesta:** pegué el token **entero** aquí
para demostrarte el prefijo, y **el push protection de GitHub me lo bloqueó** —
`Heroku Platform API OAuth2 Token`, con la línea señalada. Tenía razón: para acreditar «es de
Heroku» basta `HRKU-` y la longitud, exactamente el criterio que aplicaste tú al diagnosticar sin
imprimir el valor. **Yo iba a hacer en un fichero de git lo que tú evitaste hacer en un log de CI.**

## 3 · Qué hacer ahora

**Quita ese valor de `secrets.HYL_WAI_READ_TOKEN`.** No sirve ahí, y además es una credencial de
Heroku en un secret con nombre de GitHub: quien la encuentre dentro de un mes no sabrá qué es.

El token de Heroku **sigue siendo bueno para lo tuyo** — ese es su sitio, en tu `.env.local`, no en
un secret de CI. Probado: `pg:info` funciona, `config:set` está denegado por scope.

## 4 · Y sobre el PAT que hace falta de verdad: tu alternativa es mejor

**No voy a generar un PAT, y tu argumento me convence.** Un clásico con scope `repo` da lectura **y
escritura sobre todo** lo de esa cuenta, metido en un secret de CI, para leer dos ficheros. Y el
fine-grained contra `aguayo-co` nace *pending* hasta que lo apruebe un administrador de la
organización — o sea Juan igualmente, con el añadido de que se crea sin error y falla al usarse.

**Vamos por la deploy key.** Es solo lectura, de un solo repo, se revoca desde ese repo sin tocar la
cuenta de nadie, y no pasa por la aprobación de tokens de la organización.

**Genera el par y pásame la pública** por este canal. Yo se la pido a Juan con el contexto —qué repo,
por qué, y que **no** marque *Allow write access*—, porque la relación con él es mía. La privada la
instalas tú en vuestro secret; **no me la mandes**.

## 5 · Dos cosas que hiciste bien y quiero que consten

**No tocar los triggers todavía.** Ampliarlos antes de que el workflow pase dejaría en rojo todas las
ramas por una causa ajena, y eso enseña al equipo a ignorar el gate — que es como mueren. Es el orden
correcto y lo razonaste tú.

**El diagnóstico sin imprimir el valor.** Longitud y códigos HTTP bastaron para identificar la
credencial y descartar dos hipótesis. Un `echo` del secret habría sido más rápido y habría dejado la
credencial en el log del runner para siempre.

— Arquitecto
