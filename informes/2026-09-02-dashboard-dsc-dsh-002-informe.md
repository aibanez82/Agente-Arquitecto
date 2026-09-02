# Informe — `DSC_DSH_002`: mecanismo del interruptor y la `N` declarada

**Handoff:** `Dashboard_SeguroAuto:handoffs/2026-09-01-dsc-dsh-002-el-embudo-por-api.md` · Issue `HYL-WAI#290`
**Ejecutor:** Agente Dashboard · 1–2 sep 2026

**Entrega:** PR `aibanez82/Dashboard_seguroautoqualitas#12` → `stg`, **abierto y sin mergear**.
Va por PR porque toca `apps/operacion/lib/s1/continuation.js`, que es código del `#156`. Suite **339/339**.

## Lo hecho

Lo que no dependía de la API de Juan, que es lo que pedía el punto 3 del handoff.

- **Mecanismo del interruptor** `sql` / `dual` / `api`, uno por función, por defecto `sql`, en
  `apps/operacion/lib/desacople/`. Comparación en **un solo origen**, no por endpoint.
- **El modo vive en una tabla nuestra y no en una variable de entorno.** Cambiar una variable en
  Vercel **no afecta al despliegue vivo**: se aplica a despliegues nuevos. Acreditado en casa el
  8 ago con `S1_DASHBOARD_MODE`, que exigió redesplegar el Preview de `stg`. Como de «la vuelta atrás
  no despliega» cuelga toda la seguridad del plan, había que resolverlo antes de escribir código.
- **Migración escrita y NO aplicada** (`migrations/2026-09-01-desacople-interruptor-por-funcion.sql`),
  con el `GRANT` de PROD **sin rellenar a propósito** y el `SELECT` a `role_table_grants` que hay que
  correr antes: en STG no hay ACLs que ejercitar y por eso el `#284` pasó entero allí.
- **34 pruebas** nuevas, offline.

## «El conjunto vacío no es iguales, es sin evidencia»

Pediste verlo en el código. Está en tres sitios y los tres tienen prueba: la comparación devuelve
`sin_evidencia` **antes de mirar nada más**; el registro lo suma a `sin_evidencia` y **nunca** a
`con_evidencia`; y la puerta a `api` cuenta `con_evidencia`. **Cien comparaciones vacías dejan la
puerta cerrada.** No es teórico: la función que lo estrena devuelve **cero filas en STG hoy**.

## La `N`, declarada el 1 sep, sin datos delante

En código (`lib/desacople/umbrales.js`), no solo en un documento. Para `descuentos_continuacion`:

1. **50 comparaciones con evidencia.**
2. **10 identidades distintas** — `N` comparaciones de la misma fila no son cobertura.
3. **Cero `diferente` y cero `incompleto`**, con **la ventana reiniciándose en cada uno**.
4. **Tasa de respuesta de la API ≥ 99 %** sobre **≥ 200 intentos**.

## Enmienda a mi propia propuesta

«Se sirve SQL en cuanto está; si la API no ha llegado, se abandona», **al pie de la letra no recoge
casi ninguna comparación**: con un SQL rápido la API está pendiente siempre. Sustituido por un tope
acotado — **`dual` alarga la respuesta como mucho 400 ms**. Aceptada por ti el 2 sep.

## Pendiente

- **Aplicar la migración** en los dos entornos, con el `GRANT` de PROD confirmado antes.
- **La subruta de la API** para la vista terminal, de Juan. Hasta que exista, el adaptador es
  `api: null` y el modo se queda en `sql`.
- Las **tres condiciones de aceptación** de la API están puestas en el `#290`.

**Línea base del acoplamiento:** esta entrega **no la mueve**. No retira ninguna consulta: construye
el mecanismo con el que se retirarán.

— Agente Dashboard
