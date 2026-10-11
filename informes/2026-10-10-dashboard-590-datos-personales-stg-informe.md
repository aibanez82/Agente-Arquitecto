# Informe (Dashboard): `#590` — «dio datos personales» es un dato guardado, en `stg`

**De:** Agente Dashboard · **Para:** Arquitecto · **10 oct 2026**
**Responde a** `dudas/2026-10-10-dashboard-587-590-respuesta.md`, parte `#590`.

## Estado

En `stg` = `fe08367` (rama `fix/590-datos-personales-guardados`). Suite **897/897**, los dos verificadores y el `build` en verde. **No está en `main`.**

## Qué

- **Una sola función:** `apps/operacion/lib/datosPersonales.js`. `senalPropia` = asegurado **o** `grupo1_capturado`; `adjuntarDatosPersonales`
  la **hereda de la raíz a la hoja** en `discount.chain` (no al revés) y suma 1 a `nivel_compromiso`; `datosPersonalesDe` es lo que
  leen los consumidores.
- **`db-leads.js`** expone `grupo1_capturado` (`captured_data->'grupo1'->>'nombre'` no vacío, en la sesión viva **o** en la archivada) y aplica
  la función después del enriquecimiento de descuentos, que es el que trae la cadena. El SQL ya no suma ese hito a `nivel_compromiso`:
  lo hace la función, porque la herencia no se ve en SQL.
- **Consumidores:** `embudoFuga.js` (etapa «Datos de emisión») y `LeadModal.js` (el icono 👤) leen la misma fuente.
  `dio_datos_personales` queda como **alias del mismo valor durante un viaje**.
- **Fuera el LIKE** «tengo… Nombre:», de `db-leads.js` (las dos tablas) y de `vinVigilancia.js`.

## Comprobaciones

- **El SQL contra la BD de STG** (la suite no parsea SQL, lección del 42P08): `EXPLAIN` de la consulta completa de `db-leads`, planificada sin
  error. Recuento real sobre 350 leads: `grupo1` 29, asegurado 64, **unión 79**.
- **El Preview de `stg`** con la sesión admin de Alberto: `/api/db-leads` → 200, 350 leads, **79** con `datos_personales_guardados`, el mismo
  número que la consulta directa. Heredados solos: 0 en STG hoy (las raíces de las cadenas tampoco tenían datos).
- **Tests** (6, `scripts/s1/test/datos-personales-590.test.js`): control positivo (`grupo1` sin asegurado, y asegurado sin `grupo1`), negativo,
  herencia de una sesión de descuento vacía cuya raíz tiene `grupo1`, la herencia que no va de la hoja a la raíz, el embudo con la misma
  fuente, y que el LIKE ya no exista. Ajustados `hitos-solo-del-agente` (de 5 a 4 detectores de texto por tabla) y `confirmo-cobertura-502`.

**A PROD, con orden de Alberto.** Tras el despliegue, tu consulta de PROD (unión 28 de 297 en 21 días) se puede comparar con lo que pinte
`db-leads`.

Agente: Dashboard
