# Duda — Agente-n8n → Arquitecto · **«Execute workflow» guarda el workflow**, y por eso el experimento del §3 no basta

**Fecha:** 2026-08-09 · Responde a `handoffs/2026-08-09-prep-escenario-pin-por-api.md` (`86739e6`).
**Estado:** nada ejecutado, nada tocado. Solo lectura de código. Main y Payment como los dejaste.

## 1. Tus dos verificaciones: confirmadas por mi lado

- **`lib/cliente.js` no expone ninguna operación de ejecutar.** Las seis son `obtenerWorkflow`,
  `ponerWorkflow`, `identidad`, `listarEjecuciones`, `obtenerEjecucion` y `obtenerPins`, y no hay
  ninguna mención a `run`, `execute` ni `activate` en todo el fichero.
- **`executionVerify` acredita el contenido vivo**: `lib/operativa.js:998` llama a
  `acreditarTargetVivo` con `fase: 'aplicado'`.

Tu encadenado del §2 se sostiene: el envío ocurriría en el paso de UI y la denegación después.

## 2. El hallazgo: *Execute workflow* **guarda**, y a veces sin avisar

Fui a la fuente de n8n (`packages/frontend/editor-ui/src/app/composables/useRunWorkflow.ts`). Antes
de lanzar la ejecución hay exactamente esto:

- si el workflow **no** es nuevo, el estado está **dirty** y el autoguardado está **desactivado** →
  sale un diálogo de confirmación «guardar antes de ejecutar»; **si el usuario cancela, la función
  retorna sin ejecutar**;
- si el estado está **dirty** y el autoguardado está **activado** (el comportamiento por defecto) →
  **`saveCurrentWorkflow()` se llama en silencio, sin diálogo**, y la ejecución continúa.

Dos consecuencias que no estaban sobre la mesa:

1. **No existe un camino «ejecutar sin guardar».** Si aparece el diálogo y se cancela, no se ejecuta
   nada. El diálogo no es una forma de esquivar el guardado: es un STOP.
2. **Con autoguardado activo, el guardado es silencioso.** Ahí el escenario daría exactamente tu
   peor orden —guardado (drift) → ejecución (envío real) → `execution-verify` denegando— **sin que
   nadie vea un aviso**.

## 3. Por eso el experimento del §3, tal como está, no decide

Tu experimento pregunta: *¿abrir el editor re-serializa, o hace falta editar?* Es la pregunta
correcta, y ahora sé **por qué** lo es: está midiendo si abrir deja el estado `dirty`.

Pero le falta la otra mitad. Aunque abrir salga limpio, hay una pregunta que decide igual de fuerte:

> **¿Esta versión de n8n fuerza el guardado al ejecutar, con independencia de `dirty`?**

Lo pregunto porque el comentario del propio código dice, literalmente, que con el autoguardado
desactivado «el editor **ya no** fuerza el guardado antes de ejecutar». Ese *ya no* implica que
**antes sí lo forzaba siempre**. Si el n8n de STG es anterior a ese cambio, *Execute* guardaría
**siempre** —dirty o no— y el escenario del pin por API estaría muerto de entrada: el drift llegaría
junto con el envío.

Y no lo puedo resolver por API: `identidad()` devuelve `n8n_version: null` porque la API pública no
lo expone (es el `BLOCKED` que ya levanté el 7 ago). El `2.28.7` que manejamos es metadata
comprometida por el owner, no algo leído del servidor.

**Aviso importante sobre lo que leí:** la fuente que consulté es la rama principal de `n8n-io/n8n`,
**no** la versión desplegada en STG. El mecanismo «guardar si dirty antes de ejecutar» es estable,
pero la condición exacta y el diálogo pueden diferir. No doy esto por cierto para nuestra instancia
sin comprobarlo ahí.

## 4. Lo que propongo añadir al experimento

Con el workflow ya abierto para tu paso 2, y **sin ejecutar nada**, se puede leer casi todo:

1. **Abrir y cerrar sin editar** → releer fingerprints por API. *(tu §3, tal cual)*
2. **Con el workflow abierto, mirar si el botón de guardar aparece activo / si la UI marca cambios
   sin guardar.** Eso es `stateIsDirty` de forma observable, sin tocar nada.
3. **Comprobar en la UI si el autoguardado está activo** — determina si un futuro *Execute* avisaría
   o guardaría en silencio.

Con esas tres respuestas el escenario se decide sin enviar un solo mensaje. Si sale que abrir no
ensucia el estado **y** que el autoguardado está desactivado, entonces un *Execute* mostraría el
diálogo —y ahí sabríamos, antes de enviar, que algo iba a guardarse—. Eso sí sería una red.

## 5. Lo que sigue igual

Nada ejecutado y nada tocado: Main `active=false` con el pin de P1 y 4/14 drift, Payment intacto
0/5, cero ejecuciones, cero envíos. La evidencia del hallazgo de anoche la tengo además respaldada
en local por si alguien restaura Main.

**No ejecuto el experimento**: tu §6 dice que nada se hace sin GO escrito, y el paso 2 lo tiene que
hacer Alberto. Cuando lo autoricéis, que sea con la ampliación del §4 de arriba — o al menos
sabiendo que sin ella el escenario puede fallar justo después del punto de no retorno.

Sin secretos ni PII.
