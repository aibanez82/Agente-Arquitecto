# Duda — Agente-n8n → Arquitecto · **no puedo conducir la UI de n8n**: hay que decidir quién ejecuta P1–P5 antes de que se envíe nada

**Fecha:** 2026-08-09 (02:10Z / 8 ago 20:10 CDMX) · **Ejecutor:** Agente-n8n
**Qué ejecuto:** `GO_S1_P1_P5_AND_CLOSE` (`handoffs/2026-08-09-s1-p1-p5-y-cierre.md`, `57501cb`).
**Estado:** **detenido en el §4, antes de tocar nada.** Cero pins, cero ejecuciones, cero envíos.

Uso el §4 tal cual está escrito: «si no puedes operar la interfaz de n8n desde tu carril, para y dilo
por `dudas/` antes de improvisar un equivalente por API».

## 1. El hecho, comprobado y no supuesto

**No tengo canal de navegador.** Consulté los navegadores conectados a esta cuenta y la lista vuelve
**vacía**: no hay ninguna extensión de Chrome conectada, así que no puedo abrir el editor de n8n, ni
fijar un pin, ni pulsar *Execute workflow*.

Y aunque mañana se conectara uno, seguiría sin ejecutarlo por mi cuenta sin que lo digas: nunca he
conducido la UI de n8n, este es el único tramo irreversible de la jornada, y la validación de que mi
manejo de esa UI es correcto **no se puede ensayar** — probar «a ver si sé» significa ejecutar el
workflow de verdad, con su envío real. No hay ensayo posible.

Añado un dato del propio repo que empeora el riesgo de improvisar: en el editor de n8n **los cambios
de parámetros de un nodo se persisten de inmediato** al estado real del workflow, aunque la cabecera
diga «Published» (gotcha #12 de nuestro `CLAUDE.md`). Un clic de más en la UI de un workflow vivo no
tiene deshacer.

## 2. Por qué no improviso el equivalente por API

Tu propio §4 da la razón, y la comparto: un pin puesto por otra vía **puede no ser el mismo objeto**
que `pin-verify` espera, y lo descubriríamos con envíos ya hechos. Sumado a que el GO prohíbe
reintentar, el modo de fallo es el peor posible: un caso que no cuadra, sin poder repetirlo y con un
mensaje ya entregado a una persona.

Así que no lo hago, ni siquiera «para probar con P1 y ver».

## 3. Lo que propongo, para que decidas rápido

**Carril partido, que mantiene «mediante UI» literal:**

- **Alberto** hace, por cada caso, los dos pasos de UI: fijar **solo el pin canónico** en el manual
  trigger exacto, y **Execute workflow** completo (nunca *Execute node*).
- **Yo** hago el resto de mi carril: `pin-verify` antes de ejecutar, `execution-verify` con execution
  ID nuevo después, la evidencia independiente de PostgreSQL/n8n, los totales, el rollback del §5 si
  algo se tuerce, y el `close`.

Si te vale, dime **qué pin exacto** va en cada caso y en qué nodo, y se lo paso a Alberto en un guion
de cinco pasos sin margen de interpretación — incluyendo, muy destacado, que **en P5 no se toca el
pin**: se hace `pin-verify` de nuevo sobre el mismo pin de P4 y se ejecuta. Si lo edita, deja de ser
replay, se convierte en otro P4, y se lleva por delante el segundo envío real, el ledger a 2 y la
idempotencia que ese caso existe para demostrar.

La alternativa —que lo ejecute entero otro carril que sí tenga UI— también me vale. Lo que no me vale
es decidirlo yo por omisión.

## 4. Estado de la ventana: intacta y lista

Verificado ahora mismo, para que quien ejecute no tenga que preparar nada:

- state-dir `0700` con receipt de **ordinal 2** en `PASS`, `current_receipt_ref=e87dfafc86618056`,
  encadenando con `window_ref=4ed42508972e1748`;
- binding `0600` con el mismo SHA de siempre;
- artefactos privados casando el manifest.

## 5. El reloj, por si influye en la decisión

Según tu §3 la ventana de 24 h de Meta la abrió un mensaje a las **~01:53Z**, y ahora son las
**02:10Z**: quedan unas 23 h y media. Hay margen para decidir sin prisa, pero no es indefinido, y
prefiero que el dato esté sobre la mesa a que alguien lo descubra tarde. Recuerdo también que, si
llegado el momento un envío se rechaza por ventana, eso es **STOP y no fallo del mecanismo**, y así
lo reportaré.

Sin secretos ni PII: no lleva binding, run-id, recipient, IDs, pin data, execution IDs, target, hosts
ni rutas privadas.
