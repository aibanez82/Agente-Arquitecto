# Informe — el descuento con el ahorro real, en PROD

**De:** Agente Dashboard · **Para:** Arquitecto-IA-Quálitas · **3 oct 2026**
**Responde a:** `handoffs/2026-10-03-descuento-con-ahorro-real.md`
**Fusión:** orden de Alberto en mi sesión, literal: *«sí, fusiona el PR #26»*.

| | |
|---|---|
| Rama | `fix/descuento-con-ahorro-real` = **`f060126`**; `stg` = `3b562e9` |
| PR | **#26** (`promocion/descuento-ahorro-real` = `d7e8c84`) |
| `main` | `7f258d6` → **`8d6aa83`**; deploy `dpl_o9wtVf2dXFR54mCiNGg4DEagZHbq` **READY**, dominio apuntando a él |

## Lo hecho

- Título: **«🏷️ Descuento: ahorra $X (Y %)»**, o «🏷️ Descuento» sin cifra. **Nunca el parámetro.** El parámetro va al tooltip,
  rotulado «parámetro Quálitas».
- El ahorro se calcula en **`db-leads`, sobre la lista completa** (`adjuntarAhorro`). En el navegador no se podía: el funnel solo
  recibe los leads del periodo, y el original puede ser anterior.
- `precio_total`: se lee **solo** en el formato de Django (comas de miles, punto decimal). «12.318,35» o «pendiente» dan null,
  nunca 0 ni NaN. En STG, los 87 precios no vacíos se leen bien.
- Sin cifra si falta un precio, si cambian paquete o forma de pago, si el original no está en la lista, o si el precio no bajó.

## Una decisión que el handoff no fijaba

El handoff dice «origen − resultado». Lo mido **siempre frente a la cotización ORIGINAL de la cadena** (`root_lead_id`), que es la
que nombra el título:
- en un derivado, «viene del lead #original», con lo que ahorra ESA cotización;
- en el original, «sustituida por la del lead #vigente», con lo que ahorra la vigente.

Con las solicitudes salto a salto, una cadena de tres habría puesto el ahorro del primer salto junto al nombre del último. **En
cadenas de dos, que son todas las de STG con precio y las dos de PROD del handoff, el resultado es idéntico.** Fijado con su test.

## Aceptación

1. Fail-first: las dos cadenas del handoff dan **«ahorra $1,363.19 (10.9 %)»** y **«ahorra $5,382.81 (12.1 %)»**. Paquete distinto,
   forma de pago distinta o precio vacío dan «🏷️ Descuento». Ningún título contiene el parámetro. 8 de 11 tests fallaban contra el
   código de PROD.
2. **789/789**, verificador, `build` y `s1-conformidad` verde sobre `d7e8c84`.
3. **En vivo en STG:** 95 descuentos, 16 con cifra (del 22 % al 22,7 %, con parámetro 40 o 20) y 79 sin cifra. **Ningún título
   lleva el parámetro.** Los 79 sin cifra son, sobre todo, falta de precio: 251 de 338 cotizaciones de STG tienen `precio_total`
   vacío. **PROD sin medir.**

— Agente Dashboard
