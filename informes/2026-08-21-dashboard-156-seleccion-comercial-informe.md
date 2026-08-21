# Informe — Selección comercial vigente en STG (HYL-WAI#156, Plan A reducido)

**Handoff que lo ordena:** `Dashboard:handoffs/2026-08-21-156-mostrar-seleccion-comercial.md` (`c669d02`).
**Orden de origen:** handoff de Juan en `aguayo-co/HYL-WAI#156`, [issuecomment-5370435898](https://github.com/aguayo-co/HYL-WAI/issues/156#issuecomment-5370435898).
**Orden escrita de Alberto para subir a `stg`:** dada en la sesión de trabajo del 21 ago 2026 («sube a origin/stg»), después de leer la revisión previa al merge.
**Estado:** cerrado por el lado del Dashboard. Los otros dos carriles del `#156` (n8n y el E2E cruzado) no son míos y no los toco.

---

## 1 · SHA de `origin/stg` y qué arrastra

`origin/stg` = **`52f3ad7`**.

```
52f3ad7 merge: muestra la seleccion comercial vigente en solo lectura (#156) -- feature -> stg
55d6daf feat(dashboard): show current commercial selection
87fe841 merge: oculta la pestana Metepec (#177) -- fix -> stg   <- stg anterior
```

**No arrastra nada más.** La rama de Juan `feature/issue-156-commercial-context-selection-v1` tenía `55d6daf` como único commit sobre `87fe841`, que era el `stg` vigente; verificado con `git merge-base --is-ancestor`: fast-forward limpio. Se mergeó igualmente con `--no-ff` porque es lo que manda el gitflow desde el 14 ago, así que el merge commit `52f3ad7` existe pero no aporta cambios propios.

Diff efectivo entrado en `stg`: **6 ficheros, +107 / −8**.

## 2 · Las tres suites

Corridas sobre `55d6daf` antes del merge y repetidas sobre `52f3ad7` después:

```
$ node --test scripts/s1/test/discount-ui.test.js
✔ UI cablea cadena/estado/documento/entrega y distingue historial heredado de actual
ℹ tests 1  ℹ pass 1  ℹ fail 0

$ node --test --test-name-pattern='^inbox' scripts/s1/test/handlers.test.js
✔ inbox: solicita y conserva selección comercial, incluidos null, sin multiplicar A/B
✔ inbox r6(b): ?lead=…993 -> bind SQL exacto "…993" (string), nunca el vecino …992
✔ inbox r6(b): el SQL castea a bigint, no integer
✔ inbox r6(b): ?lead presente pero no numérico -> 400
ℹ tests 4  ℹ pass 4  ℹ fail 0

$ node --test scripts/s1/test/continuation.test.js
ℹ tests 17  ℹ pass 17  ℹ fail 0
```

**1 / 4 / 17**, que es exactamente la cifra que Juan anunció como PASS de su revisión local.

Gate completo del repo sobre `stg` ya mergeado: **`npm test` → 225/225**, más `check:claude-md` OK (9660 / 10240 bytes, sin rutas muertas).

### Dos notas de método, porque las dos podrían haberme hecho reportar en falso

**`continuation.test.js` falló en el primer intento**, y no era la rama: el test exige el clon del productor con el SHA `e7b97e77` y yo lo corrí desde un worktree, donde no lo encuentra. Con `HYL_WAI_REPO=/Users/AIP/claude-projects/HYL-WAI` da 17/17. Es la trampa ya documentada en `docs/convenciones-de-rama.md`; la dejo escrita otra vez porque el mensaje de error se parece mucho a un fallo real de la rama.

**El gate marca 225/225 tanto en `stg` como en la rama**, y eso parece delatar que los tests nuevos no corren. No es el caso: la rama **no añade tests, reescribe dos existentes** — el de inbox pasa a llamarse «solicita y conserva selección comercial…» y `discount-ui` se amplía en el sitio. Verifiqué que el test nuevo aparece por nombre en la salida del gate completo, y no me quedé con que el número cuadrase.

## 3 · Confirmación explícita: el panel no escribe ni calcula

Lo confirmo, y esto es exactamente lo que hace con los cuatro campos.

**No escribe.** En todo el diff no hay un solo `fetch`, `POST` ni `PUT` nuevo. El único cambio de servidor es en `apps/operacion/pages/api/inbox.js`, y son **cuatro líneas, las cuatro columnas del `SELECT`**:

```sql
c.paquete        AS paquete,
c.forma_pago     AS forma_pago,
c.precio_total   AS precio_total,
c.primer_pago    AS primer_pago,
```

Esas cuatro columnas ya las leía `pages/api/db-leads.js` desde antes de esta rama, así que la lectura del Dashboard **no depende de la migración `0078`** ni de ninguna columna nueva.

**No calcula.** `DiscountContextPanel.js` recibe la selección por prop e imprime los cuatro valores tal cual: `{commercialSelection.paquete}`, `.forma_pago`, `.precio_total`, `.primer_pago`. Sin aritmética, sin `parseFloat`, sin formateo de moneda, sin derivar ahorro y sin fallback a `precio_poliza`. El único cómputo del bloque es un `!= null` sobre los cuatro campos para decidir si están completos.

**Cuándo se ve.** Gate `continuation.is_current_leaf === true` estricto:

| Situación | Qué pinta |
|---|---|
| leaf vigente + los cuatro campos presentes | «Selección comercial vigente · solo lectura» y los cuatro valores |
| leaf vigente + falta alguno | «Selección comercial no persistida» |
| no es leaf vigente | nada: el bloque no se renderiza |

`ConversationModal.js` y `ConversationWorkspace.js` son solo fontanería: pasan `lead.<campo>` a la prop.

**Y no depende de que yo lo haya leído bien hoy.** La suite lo blinda por negación: `assert.doesNotMatch(panel, /precio_poliza|parseFloat|\bahorro\b/i)` y `assert.doesNotMatch(selectionBlock, /<(?:input|select|textarea)\b/)`. Si alguien mete un cálculo o un campo editable en ese bloque mañana, el gate cae. Es la garantía que pedías contra la segunda definición del precio conviviendo con la de Django.

### Un cambio fuera del alcance descrito, señalado antes de mergear

La rama cambia además una etiqueta que no es ninguno de los cuatro campos:

```
- `Descuento autorizado ${authorizedPercentage}%`
+ `Parámetro Quálitas ${authorizedPercentage}%`
```

Está fijado en el test (`assert.match(panel, /Parámetro Quálitas/)` y su `doesNotMatch` complementario), o sea intencionado. Va en la dirección de la doctrina —ese porcentaje es un parámetro de Quálitas, no un descuento que autoricemos nosotros— pero es copy que ve el operador y no figuraba en el encargo. **Lo reporté antes del merge** y Alberto ordenó subir con él dentro. Queda anotado aquí para que no aparezca como sorpresa en el `#156`.

**Nota menor, sin bloqueo:** `precio_total` y `primer_pago` se pintan crudos como vienen de `numeric` (p. ej. `12345.67`, sin símbolo ni separador de miles). Es la consecuencia coherente de no formatear nada en el front. Si Hylant lo quiere con formato, es decisión aparte y de quién manda el dato.

## 4 · El deployment

**Sí se disparó**, como anoche con el `#177`.

| | |
|---|---|
| Deployment de Vercel | **`33hecUCtm48cFC6DoR1twrj22bCJ`** |
| Deployment de GitHub | `6024503646` |
| Entorno | **Preview** |
| SHA | `52f3ad7` |
| Estado final | **`success`** — «Deployment has completed» |
| Creado | 2026-08-21 15:39:29 UTC |

El dato sale de los deployment statuses que Vercel publica en GitHub (`gh api repos/.../commits/52f3ad7/status` y `.../deployments`), no del CLI de Vercel: el token de esa máquina sigue caducado.

Dato colateral que puede interesar al `#156`: el mismo listado muestra un deployment **Production** (`6024066211`) para `c669d02` a las 15:12:45 UTC. Es un commit del `main` del repo de handoffs, no código nuestro — lo digo para que nadie lo lea como que el `#156` haya tocado producción. **No ha tocado producción.**

---

## Lo que queda fuera de mi parte

Sin autorización y sin tocar: PROD, merge a `main`, DDL manual, el import del Main de n8n y el E2E sintético cruzado. `origin/main` del Dashboard sigue donde estaba.

*Informe del agente Dashboard. Ruta absoluta: `/Users/AIP/claude-projects/Agente-Arquitecto/informes/2026-08-21-dashboard-156-seleccion-comercial-informe.md`*
