# Informe — promoción de #493, #506 y #510 fusionada en `main`. Y el #513 en `stg`

**De:** Agente Dashboard · **Para:** Arquitecto-IA-Quálitas · **1 oct 2026**
**Responde a:** `handoffs/2026-10-01-promocion-493-506-510.md` (`8458a95`) y `handoffs/2026-10-01-513-…` (`3da928c`)
**Orden de Alberto, en mi sesión, literal:** *«sí, fusiona el PR #18»*.

## La promoción

| | |
|---|---|
| PR | **#18**, fusionado con commit de merge. El **#17** quedó cerrado sin fusionar, con comentario a tu handoff |
| `main` | `3da928c` → **`85cf8d5`**, padres `3da928c` + **`89fc957`** |
| Deploy de PROD | `dpl_zVoyBd9pKgBo2W9HkxbTDR84hmfH` **READY**; el dominio `dashboard-seguroautoqualitas.vercel.app` apunta a él |

**Aceptación:**
1. `stg` no se había movido de `89fc957`; `main` solo con coordinación; entran **12 commits y los 14 ficheros** de tu lista.
2. Candidato real (`main` + `89fc957`): **716/716, 0 saltados**, verificador y `build` en verde. Lo que quedó en `main`
   es ese candidato, con los padres exactos.
3. **El #495 sigue entero fuera**: sus siete ficheros, idénticos a `main`; sus tres módulos no existen; en
   `conversation.js` no reaparece el filtro `webhook_ok IS TRUE`, ni el aviso de liberación en ningún sitio. En PROD,
   sin sesión, `POST /api/sistema/liberar-inactivas` va al login (307).
4. Deploy READY y dominio apuntando a él.
5. **SHA nuevo de `main`: `85cf8d5`.**

**Lo que te toca a ti, como dijiste:** comprobar en PROD que **2125 y 2208** salen en «Tomadas» con «Hoy». Y Alberto,
mirarlo con sus ojos.

## ⚠️ El check en rojo del PR, y una nota mía de memoria que estaba desfasada

GitHub marcaba el PR como `UNSTABLE` por `s1-conformidad`. Antes de fusionar lo miré: falla **un solo test**,
*«nuestras copias son FIELES al commit anclado»*, y falla **igual en `main`** (run de `3da928c`). Es un problema del
entorno del CI —su copia de HYL-WAI no está en el commit fijado—, anterior a este PR y ajeno a él. El PR no añade
ningún fallo.

Y una corrección: yo tenía anotado que `s1-conformidad` fallaba porque le faltaba `HYL_WAI_REPO`. **Ya no es así**: el CI
lo tiene. Lo que queda en rojo es ese test de copias. No lo he tocado; si quieres que mire por qué el CI no clona el
commit anclado, va con su handoff.

## El #513, después de la promoción

Fusionado en `stg` una vez terminada la promoción: rama `fix/513-enlace-directo-sin-carrera` = **`9a94cc8`**, `stg` =
**`bcdce3c`**, desplegado. **744 tests, 742 pass, 0 fail**, `build` en verde.

- **(a)** `InboxTab`: el foco del enlace directo solo se da por atendido cuando el lead **está** en los datos. Si no
  llega, se espera sin bucle: tras **2 respuestas** sin el lead se suelta, y la pantalla lo dice («No se pudo abrir la
  conversación del lead X: no está en la bandeja con el periodo elegido»).
- **(b)** `fetchInbox`: solo vale la respuesta de la **última** petición que salió; una vieja que llega tarde se descarta,
  también su error y su fin de carga.
- Las dos decisiones viven en `lib/focoDeBandeja.js`, puras, para que el fail-first reproduzca la secuencia medida
  (la petición sin lead llega antes que la que lo lleva) contra la regla antigua y contra la nueva. El cableado de los
  componentes fallaba contra el código anterior.
- **Sigue igual:** el polling de 30 s y el recorte por periodo (test). El cambio de pestaña no toca nada de esto.
- **No visto en pantalla:** como siempre, sin login en navegador remoto.

— Agente Dashboard
