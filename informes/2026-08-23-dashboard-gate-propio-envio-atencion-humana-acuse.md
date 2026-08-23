# Acuse — gate del envío: aceptado, con una petición antes de la firma

> Arquitecto, 23 ago 2026. Acusa
> `informes/2026-08-23-dashboard-gate-propio-envio-atencion-humana-informe.md`.

**Aceptado.** Verifiqué el PR `#6` por mi cuenta antes de leer tu informe, y coincide en todo.

## Lo que medí yo

| Condición | Verificado |
|---|---|
| Gate **solo** en `operator-send.js` | diff limpio: no toca `lib/s1/n8nOperatorWebhook.js`, `callOperatorWebhook`, `operatorWebhookConfigured()` ni `claim.js` |
| `reason_code` distinto | `control_send_disabled` frente a `control_module_off` |
| Colocación | tras la guarda de transporte y **antes** de la validación de parámetros — o sea antes de la primera lectura y de cualquier efecto |
| Disciplina | rama de `stg@ac99994`, 1 commit, PR contra `stg` **abierto y parado**; `origin/stg` sigue en `ac99994`; `main` intacto |

Dos cosas que no pedí y que suben el listón, dichas para que consten:

- **La verificación por mutación.** Retirar el gate y comprobar que los tests nuevos **fallan**
  (`404 !== 503`) descarta lo único que un test de guarda no puede descartar solo: estar verde por
  vacuidad. Es más convincente que un check verde.
- **El cuerpo válido en el caso apagado.** Con cuerpo vacío el test pasaría igual aunque el gate
  estuviera mal colocado detrás de la validación, y no acreditaría la colocación. Ese detalle es la
  diferencia entre probar el `if` y probar *dónde está* el `if`.

Y la justificación del `reason_code` por familias —`control_*` para estado del módulo,
`human_send_*` para desenlaces de un envío intentado, y este caso nunca llega a intentar— es
correcta y mejor argumentada que mi propuesta original. Se queda.

## Lo que falta, y es lo único

**El `229/229` no está acreditado de forma independiente.** Los únicos checks del PR `#6` son los de
Vercel. `s1-conformidad.yml` **no se disparó**, y no por avería: sus triggers son
`feature/s1-v11-**`, `fix/s1-v11-**` y `ci/s1-v11-**`, y esta rama se llama
`feature/gate-propio-envio-atencion-humana`.

No dudo de tu ejecución local — la mutación pesa más que un check. Pero **no puedo certificárselo a
Alberto como medido si solo existe en tu terminal**, y él tiene que firmar el merge.

**Petición, y es lo que Alberto pide antes de firmar:**

**Lanza `workflow_dispatch` de «S1 conformidad Dashboard» sobre `feature/gate-propio-envio-atencion-humana`.**
Comprobado que se puede: el fichero está en `main`, el workflow figura `active` en la API, y al
despacharlo sobre la rama correrá **la versión de esa rama**. Cuando termine, pásame el enlace de la
ejecución por este canal — con eso queda acreditado y Alberto firma.

## Y una observación que va más allá de este PR

Que el gate no se dispare en las ramas donde de verdad se trabaja **no es un detalle de
configuración: es el gate no existiendo**. Un check que solo corre en `feature/s1-v11-**` deja fuera
todo lo que no sea S1 v1.1 — o sea, el trabajo de hoy y el de mañana. Ya tenemos escrito el mismo
aprendizaje en `manual-migracion-stg-aprendizajes.md §2.10`: **un gate que nunca ha pasado no
protege, enmascara**; este es su hermano, el que sí pasa pero casi nunca corre.

**No lo arregles en este PR** — no se mete alcance nuevo en una rama que está esperando firma. Pero
dime si quieres que abra la tarjeta para ampliar los triggers, o la abro yo.

— Arquitecto
