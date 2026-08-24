# Informe — `s1-conformidad` en verde, y **no queda nada rojo detrás**

> Agente Dashboard · 24 ago 2026
> Cierra `informes/2026-08-23-dashboard-gate-envio-acreditacion-ci-y-el-gate-lleva-11-dias-rojo.md`
> `stg` = `aaebc90` · PR `#7` fusionado **por orden de Alberto**, ejecutado por mí.

## 1 · La causa está demostrada, no supuesta

**Mismo commit, dos resultados, nada tocado entre medias:**

| Run | SHA | Hora (UTC) | Resultado |
|---|---|---|---|
| `32687328943` | **`f8dfb78e`** | 03:41 | **failure** |
| `32754201562` | **`f8dfb78e`** | 17:01 | **success** |

El árbol es idéntico —el mismo SHA— y entre las dos ejecuciones **no se cambió una línea**. Lo único
que ocurrió fue que Juan instaló la deploy key a las 16:59.

Eso no es «creemos que era la clave». Es un experimento con una sola variable: **es la clave,
medido**. Un rojo que llevaba desde el 12 de agosto.

## 2 · Qué quedó rojo que no era esto: **nada, y lo prueba la aritmética**

Preguntas —bien— si el `fail 1` que medí en `stg` por su cuenta sigue ahí, porque un gate declarado
sano con un rojo dentro es peor que un gate rojo.

**No sigue ahí, y no porque lo diga yo: `stg` está medido.**

| Run | Rama / SHA | tests | pass | fail |
|---|---|---|---|---|
| `32666027230` | `stg` `ac999942` (control, 23 ago) | 209 | 208 | **1** |
| `32687328943` | rama, sin la clave | 213 | 212 | **1** |
| `32754793693` | **`stg` `aaebc905`, tras el merge** | **229** | **229** | **0** |

Y las cifras cuadran exactamente:

```
209  (stg antes)
+  4  mis tests del gate del envío        -> 213
+ 16  los de continuation.test.js, que abortaba y se llevaba los suyos fuera del recuento
= 229
```

**El `fail 1` de `stg` y el `fail 1` de mi rama eran el mismo defecto**, con el mismo error, el mismo
fichero y la misma línea — lo comprobé cuando lancé el control precisamente para descartar que fuera
una regresión mía. No había dos rojos: había uno, contado dos veces.

La última fila es `stg` mismo, después del merge: **229 de 229, cero fallos.** No queda nada detrás.

## 3 · Los triggers se demuestran solos

El run `32754379968` sobre `4a14bc18` **no lo lancé yo**: se disparó por `push` a una rama `fix/**`,
que antes no estaba cubierta. Y el `32754793693` se disparó por el push del merge a `stg`.

**Es la primera vez que un merge a `stg` de este repo queda verificado por CI.**

Los triggers pasan de `feature/s1-v11-**`, `fix/s1-v11-**` y `ci/s1-v11-**` a `feature/**`, `fix/**`,
`chore/**`, `ci/**`, `stg` y `main`. `docs/**` queda fuera a propósito: la suite no los ejerce y un
build por cada nota es gasto sin señal.

## 4 · El arreglo, en tres piezas

- **Segundo `checkout`** de `aguayo-co/HYL-WAI` por el SHA pineado con `fetch-depth: 1` —baja ese
  commit y solo ese— y `HYL_WAI_REPO` apuntando ahí.
- **Comprobación del commit del productor en el paso de diagnóstico**, antes de la suite, para que una
  falta se diga ahí y no enterrada en un fallo de test.
- **Deploy key de solo lectura**, verificada contra la API: es la nuestra y `read_only=true`.

Y el paso de diagnóstico temporal se retiró en cuanto hizo su trabajo. Vale la pena decir cuál fue:
**identificó dos credenciales equivocadas por su longitud y su forma, sin imprimir nunca un valor** —
primero un token de Heroku de 65 bytes con prefijo `HRKU-`, después 64 caracteres en una línea que no
eran ni pública ni privada.

## 5 · Autoría del merge, para tu registro

```
decisión  : Alberto  («mergea 7», en su conversación conmigo)
ejecución : Agente Dashboard
resultado : stg 5c42fec -> aaebc90, gates 229/229 antes de empujar
```

Abrí el PR y me detuve a pedir la orden, como marcaba tu instrucción. Tu redacción no indujo a error:
el verde autorizaba abrir el PR, no fusionarlo, y así lo entendí.

## 6 · Lo que sigue sin cubrir, dicho por si acaso

El gate corre `node --test` y el build. **No ejerce nada contra BD ni red**, por diseño. Así que
sigue sin cubrir lo que solo se ve en un entorno vivo — es la clase de hueco que F6 cubre y este
workflow no pretende cubrir. Lo digo para que «el gate está verde» no se lea como más de lo que es.

— Agente Dashboard
