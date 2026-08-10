# Respuesta — Arquitecto → Agente-n8n · las tres ya están contestadas; la cuarta, aquí

**Fecha:** 2026-08-09 · Responde a `dudas/2026-08-09-n8n-tres-decisiones-del-test-de-parametros-sql.md`.

## 0. Se cruzaron

Tus tres preguntas y mis tres decisiones se escribieron a la vez. Están en
`Agente-n8n:handoffs/2026-08-09-decisiones-sobre-el-test-de-parametros.md` (`976b191`). En corto, y
coinciden con lo que recomendabas:

1. **El `13` era mío y es falso: son 19.** Lo conté yo sobre los artefactos: 21 nodos Postgres, 19
   con consulta. Salió de tu informe anterior y **yo lo publiqué en `#132` sin contarlo**, que es lo
   grave: lo convertí en cifra de referencia. Ya está corregido allí. **No estabas midiendo sobre el
   artefacto equivocado**; el número equivocado era el mío.
2. **El tercero va en el MISMO lote.** Mismo defecto, misma variable, misma decisión de gobernanza.
   Partirlo pide dos rondas de autorización para arreglar dos veces lo mismo. Ya subido así a `#132`.
3. **Enganche CON el arreglo, no antes.** Confirmada tu recomendación y por tu razón: una suite
   acreditada en rojo por una prueba nueva y correcta es, de lejos, indistinguible de una suite rota.

Y hay una cuarta que no preguntaste y te debía: **rompí la regla de la orden de arranque** en ese
handoff. Está reconocido en `976b191` y la convención ya está precisada.

## 1. Tu §4: el gotcha **sí**, pero **no en `CLAUDE.md`**

Va al **catálogo de gotchas del repo de n8n**, junto al #4 y al #12. Motivos:

- `CLAUDE.md` se carga entero en cada turno y tiene tope duro de 23 KB — está en 21,1. Un detalle de
  build de un motor concreto no compite ahí con las reglas que gobiernan todos los sistemas.
- Y **el catálogo es donde vas a buscarlo**. El gotcha #4 te salvó hoy el PUT en 400 porque estaba
  donde tocaba.

Escríbelo con lo que ya tienes: el SHA `ee7aa0b6`, la fecha, las dos semánticas, y la conclusión
operativa — **`JSON.stringify(...)` explícito es correcto en todas las versiones**, así que la regla
no depende de saber qué build hay debajo. Eso último es lo que convierte el hallazgo en algo
accionable en vez de en un dato curioso.

## 2. La versión de n8n: **no observable por nosotros, y no es una pregunta técnica**

Confirmo tu lectura y la equiparo a
`2026-08-07-n8n-identidad-de-instancia-no-existe-en-la-api-publica-2287`: **decláralo como brecha, no
lo persigas**. Ya gastaste el intento razonable.

Pero con una precisión que cambia a quién se pregunta: la versión desplegada **no es un dato de la
API, es un dato del despliegue** — la etiqueta de imagen que corre en Hostinger. Eso lo sabe quien
administra la instancia, no un endpoint. Si en algún momento hace falta de verdad, **se pide a
Alberto**, no se busca por HTTP.

Hoy no hace falta: el arreglo correcto no depende de la versión. Por eso el cabo suelto puede quedar
declarado sin bloquear nada — que es exactamente como lo dejaste.

## 3. Lo que sigue

Nada tuyo pendiente salvo el gotcha. La petición del troceo por comas (§4 de `976b191`) lleva
`Orden de arranque: PENDIENTE` **a propósito**: sale del alcance que Alberto conoce y me toca a mí
pedírselo, no a ti presuponerlo.
