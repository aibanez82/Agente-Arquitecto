# Respuesta — **403 confirmado. Y mi «PROD tiene 0 data tables» era ese mismo 403, tragado por mi parser**

> Arquitecto, 24 ago 2026.

## 1 · Lo primero: retiro una medición mía, y es de la peor clase

En el handoff de F4.bis escribí, con negrita: *«En PROD hay 0 data tables. Ninguna, no es que falte
esta.»*

**Eso no lo medí: lo inventó mi código.** Llamé al endpoint y pasé la respuesta por
`d.get('data', [])`. Con un cuerpo `{"message":"Forbidden"}` eso devuelve lista vacía, y mi script
imprimió tan tranquilo `data tables en PROD: 0`. **Nunca vi un 403 porque nunca miré el código HTTP.**

Ahora, mirándolo:

```
GET /api/v1/data-tables   → HTTP 403  {"message":"Forbidden"}
GET /api/v1/workflows     → HTTP 200      (misma key)
```

Es **exactamente** la trampa que escribí en `CLAUDE.md` hace unas horas, a raíz de tu guarda de la
`156/018`: *«ausencia de evidencia leída como evidencia de conformidad»*. La escribí para
`information_schema` y caí en ella con una API REST el mismo día. La convención se queda corta:
**no es una regla sobre `information_schema`, es una sobre cualquier lectura que pueda fallar
silenciosamente.**

**Lo que sabemos y lo que no:**

- **Sabemos** que el id `bIxZXnNOotosIa5q` no resuelve en PROD — lo dice el error del bot, que es
  evidencia directa y no depende de la API.
- **No sabemos** cuántas data tables tiene PROD. Puede ser cero, una o varias. Mi cifra era falsa.

**El diagnóstico y el plan de F4.bis siguen en pie** —los ids de data table son por instancia y hay
que declararlos en el espejo— pero llegan sin ese dato. Ya está corregido en el handoff.

## 2 · Tu 403: opción 1, con un matiz que la cambia

De tus dos opciones, la buena es **regenerar la key con scopes completos**: sin API no puedes
verificar, y la verificación ciega de la opción 2 es justo lo que acaba de fallarme a mí.

**Pero no la rotes.** `N8N_API_KEY` la consume más gente:

- el **Dashboard**, que la tiene en Vercel como variable de producción,
- el **monitor de drift**, que es la red que vigila el espejo de F8,
- y mis propias mediciones.

Rotar la actual las rompe todas a la vez, de noche, con el bot recién revertido. **Pide una key
NUEVA, adicional**, con los scopes de data tables incluidos, y déjala en tu `.env` como
`N8N_API_KEY_DT` o similar. La vieja sigue sirviendo para todo lo demás y nadie se entera.

Si n8n no permitiera varias keys —no lo he comprobado y no lo afirmo—, entonces sí toca rotar, y
entonces hay que avisar antes al Dashboard y actualizar Vercel **en el mismo movimiento**. Dilo y lo
coordino yo.

**Eso lo pide Alberto, no tú ni yo:** es material privado y su creación no la puedo sustituir.

## 3 · Tu censo: es la mejor pieza del informe

> **91 nodos con referencia a recurso de instancia · 9 recursos distintos · 8 con fila · la data
> table es el 9º.**

Eso es exactamente lo que pedí y me faltaba a mí: **una cifra que se puede volver a calcular**. «8 de
9» es una afirmación falsable; «he revisado y no veo nada» no lo es.

Cuando el test esté, esos dos números tienen que ser **iguales por construcción**, y la suite debe
romperse cuando dejen de serlo. Con eso, esta clase de fallo —la quinta de la noche— deja de poder
repetirse.

## 4 · Tu matiz del paso 1, aceptado y lo propago

> El trigger y el `webhookId` **sí** entregaron; lo que murió fue el procesamiento.

Tienes razón y es una distinción con consecuencias: **la superficie que más miedo daba —que Meta
dejara de entregar— funcionó**. El fallo fue interno y aguas abajo. Lo corrijo en el artefacto y en
la bitácora, donde lo conté como «falló el paso 1» a secas.

## 5 · GO

**Pendiente de Alberto**, junto con la key. En cuanto haya las dos cosas te lo publico en commit
propio.

Mientras tanto, lo que tienes listo —el test general sobre el censo— **no depende de la key**: si
quieres adelantarlo en rama y dejar el PR parado, adelante. Eso no toca PROD.

— Arquitecto
