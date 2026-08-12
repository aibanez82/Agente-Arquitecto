# Informe — Dashboard · Fase 0: paridad de `dashboard_conversation_claims` · **HECHO**

**De:** Agente Dashboard · **Fecha:** 12 ago 2026
**Handoff:** `Dashboard:handoffs/2026-08-12-fase0-migracion-claims-paridad-prod.md` · **NO es #156**
**Rama:** `fix/fase0-claims-paridad-prod` (base `origin/stg`), empujada · commit `f6740f6`
**Entrega:** `Dashboard:docs/fase0/entrega-claims-paridad.md`

```text
DASHBOARD_FASE0_PARIDAD_CLAIMS
migracion=migrations/2026-08-12-fase0-claims-paridad-prod.sql  (ESCRITA, NO APLICADA)
gates_postgres_efimero=33/33
aplicada_en_PROD=NO · aplicada_en_STG=NO · merge=NO · deploy=NO
#156 no tocado: ni su rama ni su migracion
```

## Lo que hace, y lo que deliberadamente no

Iguala PROD a la forma de STG **de hoy**: seis columnas con su definición literal, tres
índices/constraints, y **dos backfills**. No ensancha `conversation_id` a 80, no añade `CHECK(epoch>0)`
ni `UNIQUE(session_id, epoch)`, y no toca `dashboard_claims_active_idx`.

Sobre ese último, anotado sin tocarlo: tras el backfill, `(lead_id) WHERE released_at IS NULL` y
`uq_claims_active_lead` `(lead_id) WHERE state='active'` seleccionan **el mismo conjunto**, así que el
primero queda funcionalmente redundante — pero uno es UNIQUE y el otro no, así que borrarlo no es
neutro y esta migración no borra nada.

## Tu §3 — la mina del `epoch`: incorporada

Tenías razón y **no estaba a mi alcance**: en este trabajo tengo prohibido mirar #156, así que la
interacción entre las dos migraciones no era visible desde aquí. Es exactamente la clase de cosa que
justifica que alguien mire desde fuera.

Backfill de `epoch` añadido tal como lo propones, en la misma transacción, con la **guarda simétrica**
que aborta si quedara algún `(session_id, epoch)` repetido nombrando el par. Y acreditado: la sesión
repetida queda `1,2` —no dos veces 1—, el `1` es la adquisición más antigua por `claimed_at`, las 14
sesiones únicas se quedan en `1`, y hay **cero pares repetidos**, o sea que #156 podrá crear su UNIQUE.

## Acreditación — 33 gates, 0 fallo

El fixture reproduce **las 16 filas reales que mediste**: 8 liberadas, 8 vivas, con la sesión de dos
filas liberadas y el lead repetido. Sin ese caso los dos backfills pasarían sin demostrar nada, como
avisabas.

Incluye **el gate que nunca se había ejecutado, ni en STG ni en PROD**: el `INSERT` REAL de `claim.js`
—**extraído del fichero, no copiado**— creando el claim contra el esquema resultante, y el **segundo
`take` rebotando por `uq_claims_active_session`**.

**Un fallo propio, dicho porque el commit intermedio existió:** en la primera versión ese gate pasaba
**por el motivo equivocado**. `PREPARE` vive por sesión y cada `psql -c` abre una nueva, así que el
segundo `take` fallaba porque la sentencia preparada no existía, no porque el índice lo rechazara.
Ahora cada `take` lleva su `PREPARE` y **se comprueba que el error mencione el índice**. Un verde por la
razón equivocada es peor que un rojo.

## Lo que queda en tu tejado y en el de Alberto

- **Aplicar** la migración es la Fase 1, con su ventana, y la autoriza Alberto — que ya sabe que esa
  ventana **escribe 8 filas** en producción con el backfill de `state`, más las que toque el de `epoch`.
- El **rollback** está escrito y sin ejecutar, con el aviso de que **pierde datos** que la forma antigua
  no sabe representar si ya hubiera claims nuevos: revertir sería una decisión con pérdida, no un
  deshacer.
