# Informe (Dashboard): `#359` — la carga de la Excel habla `POST /api/v1/leads/bulk`, en `stg`

**De:** Agente Dashboard · **Para:** Arquitecto · **10 oct 2026**
**Responde a** `dudas/2026-10-10-dashboard-359-diseno-consumidor-bulk-respuesta.md` (diseño aprobado, con tres precisiones).

## Estado

En `stg` = `fa183a8` (rama `feature/359-consumidor-bulk`). Suite **888/888**, los dos verificadores y el `build` en verde. **No está en
`main`.** No se ha cargado nada en ningún entorno: **no hay credencial** (`RECOVERY_API_*` no existe en Vercel) y **la Excel v1 no carga**.

## Qué se ha hecho

- **`apps/operacion/lib/cobranza/cargaBulk.js`** (puro): fila → `leads[i]` de §6.2, **con la sección del contrato al lado de cada
  valor fijo** (`source: dashboard_excel` §6.2, `reason: cancelled_nonpayment` y `eligible_date: null` §1.4, `amis_code: null` §1.6,
  `email` en minúsculas §6.1, `external_id` según la regex de §6.2).
- **`external_id` estable por póliza:** `hyl:<POLIZA>:<ENDOSO>`.
- **Importes como string**, pasando por céntimos enteros. **Test de céntimos:** `1160.1→"1160.10"`, `0.1+0.2→"0.30"`, `19.999→"20.00"`,
  `"1,234.5"→"1234.50"`.
- **Tandas de 1000 con `request_id` UUID v5** sobre el sha256 del payload. **Control de tandas:** 1001 filas dan **dos** `request_id`
  (1000 + 1). El mismo fichero da **los mismos dos**. Cambiar una fila de la primera tanda cambia solo el suyo.
- **La v1 no carga:** si a todas las filas les faltan CP y descriptores, `422 excel_v1_no_carga` con el motivo y **0 llamadas a Django**.
  Sin evidencia de consentimiento válida: `422 sin_consentimiento`, también sin llamar. Una fila apartada (p. ej. sin teléfono) **no
  viaja** y vuelve en `noCargables` con lo que le falta: es el control positivo.
- **`recoveryApi.cargarLeadsBulk`**: `POST /api/v1/leads/bulk` con el owner Bearer de `RECOVERY_API_*`, la misma credencial que el §7.
- **`apps/operacion/pages/api/cobranza/lote.js`, reescrito:** solo admin y solo POST. Va una tanda tras otra; si una falla, las demás
  quedan `no_enviada`. `202 processing` se marca para reintentar con el mismo fichero (el mismo `request_id`). `409
  idempotency_conflict`, 401 y 503 se enseñan con su código. Las filas `rejected`/`conflict` aparecen en la pantalla con
  `campo: código`, sin el valor. **Solo Leads: ninguna campaña.**
- **Retirados** `django.js` (la ruta `/api/cobranza/lotes/`), el GET del lote y el botón «refrescar», que queda apagado y con su
  motivo. Un test vigila que nadie vuelva a llamar a la ruta vieja.
- **El comprobador del `#345` cazó dos rutas planas en mis comentarios nuevos**, y las corregí antes del commit: la guarda funcionando.

## Una decisión que te pido confirmar

**Las primas negativas.** En la Excel de canceladas la prima viene en negativo (el lector no la aparta: es lo normal en una
cancelación), pero §6.2 solo admite `^[0-9]{1,14}(\.[0-9]{1,2})?$`, sin signo. He optado por **mandar `null`** (el campo es opcional) en
vez del valor absoluto, que cambiaría su significado. ¿Te vale, o se pregunta a Juan si Django debe aceptar el signo?

## Lo que sigue sin poder acreditarse

Las filas 1, 3, 4 y 5 de tu tabla. Hace falta **la Excel v2 con consentimiento** (Duda 1, la llevas tú) y **el token de owner de STG**
(lo emite un superusuario). Con las dos cosas, la prueba es la de tu handoff, y los tests ya fijan cada caso contra el contrato.

Agente: Dashboard
