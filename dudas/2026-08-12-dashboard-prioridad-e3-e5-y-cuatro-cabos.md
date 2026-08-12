# Duda — Dashboard · #156: prioridad E3/E5 y cuatro cabos que el trabajo ha dejado

**De:** Agente Dashboard · **Fecha:** 12 ago 2026
**Estado:** E1 y E2 cerrados, E4 parcial (informe `2026-08-12-dashboard-156-e1-e2-informe.md`, con adenda).
Suite 120/120, 31 gates en PostgreSQL efímero. Ni merge, ni deploy, ni grants.

Ninguna de las cinco me bloquea del todo: si no contestas, sigo por el orden que propongo en la §1.
Van con recomendación para que puedas resolverlas confirmando.

---

## 1. Prioridad: ¿E3 o E5? — **recomiendo E3**

Los dos están libres de bloqueo técnico. La diferencia está en lo que desbloquea cada uno:

- **E3 (cable Dashboard→n8n)** desbloquea **los dos gates del §6 que hoy no puedo cubrir**:
  `claim ↔ reserva` y `release A ↔ take B`. Mientras no exista, la acreditación de #156 por mi lado
  queda incompleta por construcción, no por falta de tiempo.
- **E5 (read models)** no desbloquea gates, pero es donde está el **riesgo de negocio**: si la
  adquisición no se calcula por `root` con el resultado del leaf confirmado, **los números se inflan
  hasta 3×**. Eso es un número que alguien mirará y creerá.

Recomiendo **E3 primero** por los gates, y E5 inmediatamente después. Si tu prioridad es que ningún
número mienta antes que la completitud de la acreditación, dilo y las invierto.

## 2. Los gates que dependen de piezas ajenas — ¿basta el stub corrupto?

«Vista malformada» solo la tengo cubierta **parcialmente**: fila con `schema_version` no soportado y
fila cuyo `session_id` no es el pedido. No puedo probar una vista real corrupta porque la vista no
existe.

Tu §Evidencia contempla exactamente esta vía: *«stub consumidor deliberadamente corrupto»*.
**Recomiendo** construir ese stub —una tabla efímera con el nombre y las columnas de
`conversation_control_v1`, poblada con filas que violan la cardinalidad y los enums— y acreditar contra
ella en el mismo PostgreSQL efímero de E2. Sería acreditación real de mi lado sin tocar nada de n8n ni
prejuzgar su DDL.

¿Lo tomo como suficiente para el gate, o esperas a la vista real de n8n?

## 3. **No sé qué tiene hoy la tabla de claims**, y la migración la escribí a ciegas

La de fencing del 28 jul se aplicó a mano y nunca se versionó, así que escribí la de E2 **aditiva e
idempotente** precisamente para no depender de saberlo: deja el mismo estado final se parta de donde se
parta, y la acredito partiendo de una tabla deliberadamente deficiente.

Pero eso me protege de romper, **no** de que falte algo que no imaginé. Con el catálogo real delante
podría afirmar qué hace la migración en cada entorno en vez de suponerlo:

```sql
SELECT c.relname AS tabla, a.attname AS columna, format_type(a.atttypid, a.atttypmod) AS tipo
FROM pg_attribute a JOIN pg_class c ON c.oid = a.attrelid
WHERE c.relname = 'dashboard_conversation_claims' AND a.attnum > 0 AND NOT a.attisdropped
ORDER BY a.attnum;

SELECT conname, pg_get_constraintdef(oid) FROM pg_constraint
WHERE conrelid = 'public.dashboard_conversation_claims'::regclass;

SELECT indexname, indexdef FROM pg_indexes
WHERE tablename = 'dashboard_conversation_claims';
```

Van por `pg_catalog` y no por `information_schema` a propósito: con un rol readonly, `information_schema`
filtra por privilegios y «no existe» se ve igual que «existe sin grants» — ya nos costó una hipótesis
equivocada.

**Yo no las ejecuto** (cero accesos vivos). ¿Las pides tú, que tienes lectura autorizada de STG, o se lo
pedimos a Alberto?

## 4. `uq_claims_active_lead`: ¿se conserva o se retira?

Dice el contrato: *«`uq_claims_active_lead`, si se conserva, es política de producto/UI, no autoridad
conversacional»*. No sé si existe hoy —ver §3— y **mi migración no lo crea ni lo borra**, deliberadamente:
tocarlo sin saber si está sería decidir por accidente.

**Recomiendo conservarlo** si existe: impide que un agente tenga dos conversaciones tomadas del mismo
lead, que es una regla de producto razonable, y no interfiere con la autoridad por sesión. Pero si lo
que quieres es que **nada** sugiera que el lead es autoridad, retirarlo es más limpio y entonces habría
que decirlo explícitamente en la migración.

## 5. E5 y las métricas que ya existen — el cabo con más consecuencias

E5 pide calcular la adquisición **por `root`, con el resultado del leaf confirmado**. Pero el Dashboard
**ya tiene** métricas de adquisición vivas hoy (`lib/metrics.js`, `components/FunnelV2.js`), que cuentan
leads sin saber nada de cadenas de recotización porque hasta ahora no existían.

Lo que necesito acotar: **¿E5 es solo superficie nueva, o corrige también las métricas existentes?**

- Si es **solo superficie nueva**: el funnel actual seguirá contando cada lead continuado como
  adquisición, así que el día que Discounts se active **los números del dashboard se inflarán** y nadie
  lo habrá decidido.
- Si **corrige las existentes**: es un cambio de métrica sobre superficie que el negocio mira a diario,
  y por la regla de esta casa eso no se toca sin decisión explícita — además de que hay preguntas
  abiertas con Hylant sobre la metodología de conversión que llevan meses sin respuesta.

**Recomiendo** construir E5 como superficie nueva y **declarar el desfase**, sin tocar el funnel actual,
porque cambiar una métrica que Hylant mira sin su visto bueno es peor que declarar que va a desfasarse.
Pero la consecuencia —números inflados el día del rollout— hay que decidirla, no heredarla.
