# Informe (Dashboard): `#359` — filas 2 y 6 acreditadas en código; lo vivo, pendiente de sesión

**De:** Agente Dashboard · **Para:** Arquitecto · **10 oct 2026**
**Responde a** `dudas/2026-10-10-dashboard-359-el-dashboard-no-llama-a-bulk-respuesta.md` (`21850ce`): «acredita ya las filas 2 y 6 y
el solo mirar de PROD». No se ha subido nada a ningún entorno.

## Fila 2 — una fila sin un mínimo obligatorio se rechaza en el Dashboard y no viaja: ACREDITADA (código y tests)

- `apps/operacion/lib/cobranza/lectorCanceladas.js`: `apartar()` marca `SIN_TELEFONO` («sin teléfono utilizable») cuando el teléfono
  no tiene 10 dígitos. Junto a él, `VIN_LONGITUD`, `VIN_CARACTERES`, `PRIMA_POSITIVA` e `INTERNO`, siempre con el motivo. Las
  apartadas no se envían: «se manda sólo lo utilizable» (`cargarLote`, `django.js`).
- Tests verdes en `origin/stg` (`node --test scripts/s1/test/lector-canceladas.test.js cobranza-endpoint.test.js cobranza-carga.test.js`:
  **41/41**). Entre ellos: «teléfono: diez dígitos o nada», «ninguna fila se pierde: leídas = aceptadas + apartadas», «una fila con dos
  defectos se cuenta UNA vez, y conserva los dos motivos» y «la pantalla enseña las apartadas y por qué».
- **Lo vivo (subir una Excel de prueba en la pantalla de STG y ver el motivo):** pendiente. Hace falta la sesión de Alberto en el
  Preview y su sí a subir el fichero. Lo pido en la sesión.

## Fila 6 — un no admin no ve la sección: ACREDITADA (código y tests)

- La pestaña: `apps/operacion/pages/index.js:311` solo la añade si `me?.role === 'admin'`.
- **Y ocultarla no es la defensa:** los tres endpoints cierran en el servidor con `role !== 'admin'` → 403
  (`pages/api/cobranza/lote.js:19`, `canceladas.js:46`, `recovery.js:19`).
- Tests: «la pestaña es de admin, y ocultarla no es la defensa», «el endpoint se cierra a admin, no solo a `agente`», «cargar y refrescar
  están cerrados a admin, como la lectura».
- **Lo vivo con un usuario no admin:** sin hacer. No tengo credenciales de un usuario no admin de STG y no las pido; queda acreditado por
  el control de servidor y sus tests.

## PROD, solo mirar: PENDIENTE

Hace falta la sesión de Alberto en PROD. Lo miro en cuanto entre y lo añado como adenda.

## Filas 1, 3, 4 y 5: SIN ACREDITAR

Por lo que dice la duda: el Dashboard no llama a `/api/v1/leads/bulk` y no hay credencial. Lo siguiente es la duda de diseño (A), sin
código, que preparo a continuación.

Agente: Dashboard

---

## Adenda (10 oct 2026) — PROD, solo mirar: la sección existe para admin

Con la sesión de Alberto en Production (`/api/me` → `role: admin`): el menú «Administración» se despliega en **«Agentes»** y
**«Cobranza vencida»**. **No se ha subido nada.** Una carga en PROD crearía Leads reales de Recovery, y eso va con el `#551` y con
orden de Alberto.

Agente: Dashboard
