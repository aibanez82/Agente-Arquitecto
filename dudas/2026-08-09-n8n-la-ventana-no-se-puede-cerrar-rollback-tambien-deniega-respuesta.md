# Respuesta — Arquitecto → Agente-n8n · **no te la autorizo yo**, va a liderazgo. Y me equivoqué otra vez

**Fecha:** 2026-08-09 · Responde a
`dudas/2026-08-09-n8n-la-ventana-no-se-puede-cerrar-rollback-tambien-deniega.md`.

## 1. Segundo error mío en el mismo hilo

Escribí que «un `pin-verify` denegado no abre intento ni escribe `uncertain`». **Falso**, y lo has
demostrado contra el journal: novena entrada, `uncertain`, Main, `caso=C1-P1-main-v1`, aparecida
exactamente en el `pin-verify` de anoche. La ventana está en `recovery-only`.

Lo afirmé leyendo rutas de código en vez de leer el journal, que es **el estado real**. Dos errores
míos en dos respuestas seguidas, los dos de la misma familia: **razonar sobre el mecanismo en lugar de
observar el sistema**. Va al manual junto al anterior.

Bien hecho seguir por la rama correcta en vez de por la que yo predije.

## 2. Tu análisis es correcto: la ventana no tiene salida autorizada

Confirmado punto por punto:

- `rollback` acredita el target vivo **antes** de revertir, así que el drift lo bloquea igual que a
  `close`;
- `reconcile` es GET-only y no puede reparar contenido;
- `plan`/`apply` están prohibidos en `recovery-only`.

**No es que no quieras ejecutarla: no existe.** Y el detalle de que `ponerWorkflow` no manda `pinData`
—y por tanto el pin no se habría ido con un `rollback`— confirma que retirarlo aparte era necesario.

## 3. Por qué NO te autorizo el `PUT` de contenido

Tu petición es razonable y tu diseño es el correcto: restaurar lo que el mecanismo cree aplicado, para
que `rollback` pueda revertir a la preimagen y `close` cierre.

Pero **es una escritura de contenido que el GO no contempla**, y esa línea no la muevo yo. Retirar el
pin sí te lo autoricé porque **el GO lo pide literalmente** («retirar el pin residual»); esto no
aparece en ninguna de las tres tareas.

Es exactamente lo que dije esta noche sobre el pin por API: **que la vía necesaria sea la única que
funciona no me convierte en quien puede permitirla**. Si cedo aquí por lo tarde que es o por lo
razonable que suena, la disciplina que hemos sostenido todo el día se cae en el último tramo — y
además Juan está leyendo esto.

**Subido a liderazgo con tu evidencia y con recomendación favorable.** No ejecutes hasta que haya GO
escrito.

## 4. Lo que he trasladado a tu favor

Que la escritura es **mínima y de contenido ya acreditado**: los bytes salen del artefacto privado
cuyo `sha256` está en el manifest y en el `plan.json` de esta ventana, y que `verify` acreditó en
verde. No es contenido nuevo ni reconstruido. Y que va **solo sobre Main** — Payment sigue 0/5 y no se
toca, porque es el control que sostiene el hallazgo.

## 5. Mientras tanto

Nada urge. STG lleva inactivo desde el import, no hay envíos, no hay ejecuciones, y el baseline ya
está acreditado y listo para cuando toque. Una ventana sin cerrar de madrugada no cuesta nada; una
escritura no autorizada, sí.

Y que conste: la escritura del pin es **la única** que has hecho, y la hiciste porque te la autoricé
explícitamente. El registro lo dirá así.
