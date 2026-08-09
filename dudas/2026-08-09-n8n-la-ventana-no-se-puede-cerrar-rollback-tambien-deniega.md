# Duda — Agente-n8n → Arquitecto · la ventana **no se puede terminalizar**: `rollback` también deniega por el drift

**Fecha:** 2026-08-09 · Responde a tu secuencia autorizada en
`dudas/2026-08-09-n8n-el-baseline-del-1-no-es-el-baseline-y-close-tampoco-pasa-respuesta.md` (`b7aa05f`).
**Estado:** detenido en tu paso 3. **Una sola escritura hecha** —la que autorizaste— y ninguna más.

## 1. Paso 1 — el estado NO es el que esperabas: `recovery-only`

`estadoOperativo` devuelve **`recovery-only`**, con **1 intento abierto** y **1 entrada `uncertain`**.

Tu §3 decía que un `pin-verify` denegado «no abre intento ni escribe `uncertain`». **Sí lo hace**: la
novena entrada del journal es `uncertain`, del workflow Main, con `caso=C1-P1-main-v1`. El journal
pasó de 8 a 9 entradas exactamente en el `pin-verify` de anoche.

Es la rama que sí contemplaste, así que seguí por ella.

## 2. Paso 2 — pin retirado por API. **Hecho, y es lo único que he escrito**

`PUT` con la proyección writable de lo vivo más `pinData: {}` → **HTTP 200**. Antes: un pin. Después:
**cero pins**, `active=false` y los 160 nodos intactos. Ninguna otra escritura.

Nota que confirma tu criterio: el `ponerWorkflow` del mecanismo **no manda `pinData`** —solo
`{name, nodes, connections, settings}`—, así que el pin no se habría ido solo con un `rollback`.
Retirarlo aparte era necesario, no redundante.

## 3. Paso 3 — `rollback` deniega, y con eso la ventana queda sin salida

```
C1_NODE_FINGERPRINT_DRIFT: main: fingerprint distinto en un nodo acreditado   (salida 22)
```

**`rollback` acredita el target vivo antes de revertir** (`operativa.js:795-796`), igual que `close`
(`1271-1274`). O sea: **el drift bloquea las dos** salidas.

Y en `recovery-only` solo caben tres acciones:

| Acción | Estado |
|---|---|
| `reconcile` | GET-only: **no puede arreglar** el drift |
| `rollback` | **deniega** por el drift (comprobado) |
| `close` | denegaría por lo mismo (misma guarda) |

`plan`/`apply`, que sí restaurarían el contenido, están **prohibidos en `recovery-only`**
(`C1_APPLY_PARTIAL_OR_UNCERTAIN`, 24).

**No hay ninguna acción autorizada que termine esta ventana.** No es que no quiera ejecutarla: es que
no existe.

## 4. Lo que propongo, y por eso paro como me pediste

La única salida que veo es **deshacer el drift fuera del mecanismo**, igual que la retirada del pin:
un `PUT` de la proyección writable del artefacto `s1_stg_f1f4` **solo sobre Main** —Payment está en
0/5 y no se toca—. Eso repone las cuatro claves que el editor omitió, y a partir de ahí tu secuencia
corre entera: `rollback` → `close` → baseline → activar.

Es exactamente la escritura que dijiste que solo hiciera si el paso 1 demostraba que hacía falta, y
que en ese caso parara y te la pidiera. **Está demostrado y te la pido.**

Dos precisiones para que la autorices con los ojos abiertos:

- **No es un `apply`**: no pasa por el mecanismo, no escribe journal y no crea intento. Es el mismo
  tipo de acción que el `PUT` del pin que ya autorizaste.
- **Restaura contenido ya acreditado**: los bytes salen del artefacto privado cuyo `sha256` está en
  el manifest y en el `plan.json` de esta ventana, y que `verify` acreditó en verde el 8 de agosto.
  No es contenido nuevo ni reconstruido.

Si prefieres otra vía —o declarar la ventana no terminalizable y cerrarla por arriba— dímelo y la
ejecuto.

## 5. Estado exacto ahora

- **Main**: `active=false`, **cero pins**, drift 4/14, contenido `s1_stg_f1f4` con las cuatro claves
  omitidas por el editor.
- **Payment**: `active=false`, cero pins, **drift 0/5**, intacto.
- Cero ejecuciones, cero envíos, `db_writes=0`. STG sigue **inactivo**, como lleva desde el import: la
  restauración del baseline y la activación siguen pendientes, y nada de eso es urgente esta noche.
- Baseline acreditado y listo para cuando toque: preimágenes del state-dir del import ≡
  `workflows/s1/*-candidato.json` por fingerprint, la comparación que autorizaste.

Sin secretos ni PII.
