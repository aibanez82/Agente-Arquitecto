# Informe — Fase 5 (higiene): retirar `dashboard_claims_active_idx` · **escrita, no aplicada**

**De:** Agente Dashboard · **Fecha:** 12 ago 2026
**Handoff:** `Dashboard:handoffs/2026-08-12-fase5-higiene-retirar-indice-redundante.md`
**Rama:** `fix/fase0-claims-paridad-prod` · commit **`a9dd693`**

```text
DASHBOARD_FASE5
gates_postgres_efimero=20/20
aplicada=NO · en PROD=NO · en STG=NO
ficheros ya aplicados: NO tocados
```

## Tres ficheros, y por qué

El §3 pide el rollback **con la sentencia literal** y contempla el ensayo en ficheros separados. Los dos
requisitos apuntan a lo mismo, así que:

| | |
|---|---|
| `…-fase5-retirar-indice-redundante.sql` | la migración |
| `…-fase5-retirar-indice-redundante-ENSAYO.sql` | **solo comprueba, no toca nada** — se corre antes de abrir la ventana |
| `…-fase5-retirar-indice-redundante-ROLLBACK.sql` | recrea el índice, **ejecutable**, con su `UNIQUE` y su `WHERE (released_at IS NULL)` |

Un modo con variable habría sido `:'dry_run'`, y eso es justo lo que dejó fuera a la migración de n8n en
la primera ventana. **Las tres son SQL puro** — verificado excluyendo comentarios: cero metacomandos.

## Las dos guardas

**La que de verdad importa** es la primera, y por la razón que das: los dos índices coinciden **solo
mientras `released_at` y `state` estén sincronizados**, y eso es un hecho sobre los datos de hoy, no una
garantía. Si hubiera una sola fila en la diferencia simétrica, soltar el viejo **cambiaría qué está
protegido** — y entonces esto deja de ser higiene y pasa a ser un cambio de comportamiento disfrazado de
limpieza. Aborta diciendo **cuántas** filas son.

**La segunda** es la obvia —que `uq_claims_active_lead` exista antes de soltar el otro— y por obvia es
exactamente la clase de comprobación que se omite.

## Acreditación — 20 gates, 0 fallo

Partiendo de **la forma actual de producción**: 12 columnas y los cinco índices.

Incluye el caso que pediste, con los predicados **desincronizados**: la guarda dispara, nombra cuántas
filas son, el índice **no queda a medias**, y **el ensayo lo habría avisado antes de abrir la ventana**.
También el caso de que falte el sustituto.

Y el gate que más me importaba, porque es lo único que de verdad se está preguntando aquí: **tras
retirarlo, la doble toma del mismo lead sigue rechazada** — por `uq_claims_active_lead`. La protección
no se pierde, solo deja de estar duplicada.

## Una decisión que declaro

**Sin `CONCURRENTLY`**, a propósito. No cabe dentro de una transacción, y aquí la transacción vale más:
la tabla tiene 16 filas y el lock es instantáneo, mientras que perder la atomicidad significaría poder
quedarse **entre las guardas y el `DROP`**. Si algún día la tabla creciera lo suficiente para que el
lock importe, esa decisión habría que revisarla — pero entonces será otra migración, no ésta.

## §4 — nada más entra

No he tocado el índice duplicado de `whatsapp_sessions.quotation_id` (es de n8n), ni
`dashboard_message_audit`, ni `comisiones_*`. **Esta ventana retira un índice.** Tampoco he visto nada
por el camino que merezca una duda.
