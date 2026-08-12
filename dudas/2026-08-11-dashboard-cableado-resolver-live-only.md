# Duda — Dashboard · #156 E1: cuándo se cablea el resolver live-only, y tres cabos menores

**De:** Agente Dashboard · **Fecha:** 11 ago 2026
**Sobre:** handoff `2026-08-11-hyl-wai-156-discounts-conversation-control-dashboard.md`, E1.
**Estado:** no me bloquea entero — sigo con E2 (migración de claims) mientras respondes.

Contratos verificados antes de escribir nada: los tres fingerprints del §2 coinciden exactamente.

---

## 1. La duda de verdad: el resolver nuevo no puede cablearse todavía sin apagar el Dashboard

E1 está implementado y probado (`apps/operacion/lib/s1/conversationControl.js`, 25 tests). Consulta
`public.conversation_control_v1` por igualdad exacta de `session_id`, columnas explícitas, `LIMIT 2`,
y devuelve los tres códigos del contrato.

**El problema es el cableado, no el resolver.** La vista **no existe todavía** —la publica n8n por SQL
versionado— y por contrato su ausencia cae en `dependency_unavailable`. Eso significa que **si hoy
sustituyo `resolveExactSession()` por el resolver nuevo en `/api/conversation`, `/api/inbox` y
`/api/db-leads`, todo devuelve 503 hasta que la vista esté publicada y con grant.** En STG eso deja el
dashboard inservible; en PROD sería un apagón.

Las tres salidas que veo, y no son equivalentes:

- **A · Dejarlo desconectado** (lo que he hecho): el módulo existe, está probado y no lo llama nadie.
  El resolver viejo sigue sirviendo. Coste: E1 queda acreditado como unidad pero **no** como camino
  real, y el trabajo de sustitución se hace después, contra una vista ya viva.
- **B · Cablearlo detrás de un gate de ambiente** (estilo `S1_DASHBOARD_MODE`): el camino nuevo corre
  solo donde se le diga, el viejo sigue de respaldo. Coste: dos resolvedores vivos a la vez, que es
  precisamente la clase de convivencia que nos ha costado dinero antes.
- **C · Cablearlo ya y sin red**: conforme al contrato desde el minuto uno, y el Dashboard queda
  apagado hasta que exista la vista. Solo tiene sentido si la vista llega antes que cualquier uso.

**Mi recomendación es A**, y sustituir en un paso posterior coordinado con la publicación de la vista,
porque B multiplica los caminos y C apaga la consola. Pero el contrato llama a E1 «precondición de
rollout», así que si por «corregir el resolver» entiendes *sustituido y en producción de STG*, dímelo
y lo hago de otra forma.

**Lo que necesito saber:** ¿E1 se considera entregado con el resolver probado y sin cablear (A), o
esperas la sustitución efectiva? Y si es lo segundo, ¿con qué gate?

## 2. HTTP del lado Dashboard — confirmar que replico la precedencia Django

El contrato fija la precedencia para Django (§Precedencia Django) pero no enuncia una para el
Dashboard. He replicado la única enunciada, para que dos consumidores no den códigos distintos ante el
mismo hecho:

| resultado | HTTP |
|---|---|
| `conversation_not_found` | 404 |
| `identity_contradiction` | 409 |
| `dependency_unavailable` | 503 |

Ojo a una consecuencia: hoy el Dashboard devuelve **400** para `conversation_not_found`
(`retomarBuilder.js`) y **409** para `conversation_contradiction`. Alinearme cambia un 400 por un 404
en un camino ya acreditado. ¿Confirmas la tabla, o el Dashboard conserva sus códigos actuales?

## 3. Código cuando no hay `session_id` que consultar

La lista de tres códigos es cerrada, y ninguno describe «el llamador no me pasó sesión». He devuelto
`conversation_not_found` sin consultar la base, con un `reason` interno (`session_selector_missing`)
que solo va al log y **no** es contractual.

Es defendible —no hay fila para ese selector— pero enmascara un bug del llamador como si fuera un dato
ausente. ¿Lo dejo así, o prefieres que un selector ausente sea `dependency_unavailable`, o un cuarto
código fuera de la lista de la vista?

## 4. E0 no tiene trabajo: la medición no se sostiene

Dice el handoff que `main` tiene 31 commits que `stg` no tiene y que **solo `MetepecView.js`** difiere,
por lo que se perdería en la promoción. **Los commits sí, el fichero no.** Verificado por dos caminos:

```
blob en stg : ffa5010a7a8963711e8a344df5bd52c56f00724e
blob en main: ffa5010a7a8963711e8a344df5bd52c56f00724e
```

El fichero es **idéntico**. Los dos fixes cosméticos ya están en `stg` como `e50e3ad` y `df744a4`,
gemelos por cherry-pick de `60ec67b` y `2f5f96c` de `main`. Y comprobado también al revés: **ningún**
fichero de `apps/` o `packages/` existe solo en `main`, así que la promoción de `stg` no perdería nada.

No he creado la rama `fix/metepec-view-a-stg`: estaría vacía, y una rama vacía que dice «portado»
miente. Si quieres el registro igualmente, dilo y la creo con el commit vacío y su explicación.

---

**Mientras tanto sigo** con E2 (migración de claims con epoch anti-ABA, SQL versionado y no aplicado),
que no depende de ninguna de estas respuestas.
