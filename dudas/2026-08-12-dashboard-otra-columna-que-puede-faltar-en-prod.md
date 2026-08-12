# Duda — Dashboard · ¿`dashboard_message_audit.claim_id` existe en PROD?

**De:** Agente Dashboard · **Fecha:** 12 ago 2026 · **No bloquea**: sigo avanzando.

## Por qué lo pregunto

Tu reconocimiento concluye que «el único bloqueo del Dashboard es la forma de la tabla de claims», y
eso se apoya en que las demás tablas **existen**. Pero la lección de la Fase 0 fue justamente que
**existir no es tener la forma**, así que barrí el código de `stg` buscando columnas que pudieran
haberse añadido a mano en STG igual que las de claims.

**El barrido automático es ruidoso** —alias SQL de una letra que colisionan con variables JS— así que no
te traigo la lista entera: te traigo el único candidato que sobrevive a mirarlo de cerca.

## El candidato

`apps/operacion/pages/api/n8n-proactive-message.js:177`:

```sql
INSERT INTO dashboard_message_audit (lead_id, session_id, agent_id, claim_id, message, webhook_ok)
VALUES ($1, $2, $3, $4, $5, true)
```

**`claim_id` es una referencia al claim**, así que tiene toda la pinta de haberse añadido en la misma
tanda que el fencing del 28 jul — la que se aplicó a mano y no se versionó. Tu reconocimiento listó
`dashboard_message_audit` (18 filas) pero no sus columnas.

```sql
SELECT a.attname, format_type(a.atttypid, a.atttypmod)
FROM pg_attribute a JOIN pg_class c ON c.oid = a.attrelid
WHERE c.relname = 'dashboard_message_audit' AND a.attnum > 0 AND NOT a.attisdropped
ORDER BY a.attnum;
```

## Por qué importa menos que claims, y por qué aun así importa

El `INSERT` está dentro de un `try/catch` que solo hace `console.error`. **Si la columna falta, el envío
no se rompe: se pierde la auditoría en silencio.**

Eso es peor que fallar, no mejor. Un envío proactivo que sale a un cliente real y no queda registrado
—con qué agente lo mandó y bajo qué toma— es exactamente el rastro que hace falta el día que alguien
pregunte quién escribió qué. Y como no rompe nada, nadie se enteraría.

## Qué propongo

- Si `claim_id` **existe**: cerrado, y tu conclusión del reconocimiento queda confirmada también a nivel
  de columna.
- Si **falta**: es un `ADD COLUMN IF NOT EXISTS claim_id integer` de una línea. Dime si lo añado a la
  migración de Fase 0 —encaja, es el mismo origen y la misma ventana— o si prefieres artefacto aparte
  para no ensanchar algo ya acreditado. **No lo toco hasta que decidas**: la Fase 0 está acreditada con
  33 gates y no la modifico por mi cuenta.

Las demás tablas del inventario (`comisiones_*`, `conciliacion_pagos`, `leads_metepec`,
`whatsapp_sessions_archive`) no me preocupan: las de comisiones sí tienen migración versionada en el
repo, y las otras llevan tiempo en producción.
