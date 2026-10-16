# Informe (Dashboard): `#614` — `dio_vin` solo con «Serie:», en `stg`

**De:** Agente Dashboard · **Para:** Arquitecto · **16 oct 2026**
**Responde a** `/Users/AIP/claude-projects/Dashboard_SeguroAuto/handoffs/2026-10-16-614-dio-vin-solo-serie.md`.

## Hecho

- **Rama:** `fix/614-dio-vin-solo-serie`, sacada de `stg`, commit `2e831ec`. Merge `--no-ff` a **`stg` = `8743abf`**. Preview `dpl_29R1HsaTtJo1YnTcz4PVBBzb84TG` **READY**.
- **Tres sitios**, ahora solo con `LIKE '%Serie:%'`:
  - `apps/operacion/pages/api/db-leads.js`: consulta viva y archivada.
  - `apps/operacion/lib/s1/vinVigilancia.js`: vigilancia de filas de sistema.
- **`grep -rn "Placas%"`:** no hay más sitios en el código. Solo queda «Placas» en un comentario que explica el cambio.
- **Doc**, `docs/arquitectura/superficie-de-bbdd-del-dashboard.md`:
  - `dio_vin` puesto al día.
  - **Lo que no pedías:** la fila de `dio_datos_personales` seguía diciendo `'%tengo%'` + `'%Nombre:%'`, y desde el `#590` ya no es un `LIKE`. La he corregido en el mismo commit.
- **Test** `scripts/s1/test/dio-vin-614.test.js`:
  - Lee las tres condiciones del propio fuente y evalúa sus `LIKE`.
  - Resumen sin «Placas» → `true`. Con placas → `true`. Sin «Serie:» → `false`. El filtro de agente se mantiene.
  - **Falla con el código anterior** (2 de 3 en rojo) y pasa con el nuevo.
- **Verificación:** suite **900/900**, los dos verificadores y el `build` en verde.

## Medido en STG (solo lectura, 16 oct)

- **SQL real de `db-leads`:** lo capturé ejecutando el handler y lo pasé por `EXPLAIN` en STG: OK.
- **Ejecutado:** 1357 filas, **22 con `dio_vin`**.
- **Sesiones en STG:** con «Placas» y «Serie:», 23; con «Serie:» a secas, 23. En STG no hay resúmenes sin placas, así que el cambio no mueve ningún número allí.

## Pendiente

- **El 80 → 83 de PROD lo he dejado sin medir.** No leo la BD de PROD: mido con `/api/db-leads` y la sesión de Alberto, y eso solo refleja el cambio cuando el código esté en `main`. Lo mido nada más desplegar.
- **PROD:** viaja junto con el `#614` de n8n, con la orden de Alberto, como dice el handoff.
