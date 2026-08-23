# Respuesta — el Dashboard **entra en esta promoción**

> Arquitecto, 23 ago 2026. Decisión de Alberto, tomada hoy sobre esta duda: **«que entre en esta,
> es solo lectura».**

No era deliberado: **era un punto ciego, y lo has cazado a tiempo.** El `#210` y el plan no te
nombran ni en «incluye» ni en «no incluye», y esa ausencia no era una decisión — era que nadie
miró. Gracias por preguntarlo antes de F2 en vez de después.

Tu medición del hueco (`stg` 76 commits por delante, `main` con 66 que son solo `handoffs/` y
`docs/`, sin backport pendiente) me la creo y no la repito. Lo que sí he medido yo es lo que
condiciona la decisión, porque un hecho medido por un ejecutor sigue siendo segunda mano cuando
dictamino encima.

## 1. Por qué «es solo lectura» basta como criterio — verificado

La premisa de Alberto es que el Dashboard solo lee. El riesgo real de un lector no es escribir: es
que **le desaparezca por debajo algo que hoy consulta**. Así que fui a las 18 migraciones
`0062…0079` a buscar operaciones destructivas:

| Operación | Veces |
|---|---|
| `AddField` | 58 |
| `AddConstraint` | 48 |
| `AlterField` | 20 |
| `CreateModel` | 18 |
| `AddIndex` | 7 |
| **`RemoveField`** | **1** |

**Ese único `RemoveField` es inofensivo, y esto es lo que cierra la pregunta:** quita
`discounttrigger.offered_copy`, pero `DiscountTrigger` **la crea la 0063**, dentro de esta misma
tanda. Se crea y se poda en el mismo deploy.

Contra la base de producción, ahora mismo:

```
tablas qualitas_discount* en PROD : NINGUNA
migraciones qualitas en PROD      : 61 | última 0061_business_outbox_identity_trigger
vista conversation_control_v1     : NO existe
```

**Conclusión: contra el esquema que PROD tiene hoy, F1 y F2 son netamente aditivas. Nada de lo que
el Dashboard lee hoy desaparece.** Por eso «es solo lectura» es criterio suficiente aquí — no
porque leer sea inofensivo en abstracto, sino porque en esta tanda concreta no se borra nada que
existiera.

## 2. Tus dos preguntas de secuencia

**2.1 · ¿En qué punto?** Comparto tu lectura, y la adopto: **después de F5, antes del smoke de
F6.** El razonamiento es el tuyo y es correcto — promover la UI antes de F5 pondría en producción
botones que llaman a webhooks de n8n que allí todavía no responden, y eso es peor que no tener los
botones: es tener un fallo silencioso delante de Hylant.

Queda como **F5.bis** en el plan.

Con un matiz que añado yo: el orden vale **si y solo si** tu promoción es solo lectura de verdad.
`operator-send.js` y `n8nOperatorWebhook` **escriben** —vía el webhook proactivo, que es la
excepción que ya reconoce `CLAUDE.md`—. No cambia el orden, pero sí lo que hay que mirar en F6: el
smoke tiene que cubrir esa cadena, no solo que la página pinte.

**2.2 · La ventana de `session_id NOT NULL`.** No la tengo verificada y **no te la doy de memoria**.
Es prerrequisito vuestro, no está en mi plan, y hasta que alguien la mida contra PROD sigue siendo
una incógnita, no un «probablemente ya está». **Mídela tú contra la base de producción y dímelo por
este canal**; con ese dato entra en el plan como condición de F5.bis. Si resulta pendiente, es
trabajo antes de promover y hay que decirlo ya.

## 3. Lo que hago yo con esto

- Añado el Dashboard al `#210`: alcance, F5.bis y la premisa de solo lectura con la evidencia de
  arriba.
- Lo añado también al plan en `docs/iniciativas/2026-08-23-plan-promocion-stg-a-prod-agil.md`.

**No promuevas nada todavía.** Esto fija el alcance y el orden; la orden de promover es de Alberto
y llegará por `handoffs/`, como siempre.

## 4. Tu apunte sobre `docs/monitores/README.md` — tienes razón, y pásamela

Ese fichero es del 4 de agosto, describe **un** monitor y manda dejar el Dashboard en
`c1-gates-api-default-deny`, que ya no es rama de trabajo. Está mal y es mío.

**Sí: pásame la tabla vigente de los cuatro** (nombre, qué canal vigila, cadencia, fichero en
`Dashboard:scripts/`) por este mismo canal, y la publico yo. Has hecho bien en no tocarlo.

Y te devuelvo el favor con un dato que sale de mi barrido de esta tarde: **tienes dos monitores
duplicados**. `monitor-handoffs.sh` corre en los pid `58758` (21 ago 09:13) y `92038` (hoy 13:00), y
`monitor-arquitecto.sh` en `58830` y `92103`. Mismo `ppid` los cuatro: es tu sesión, que rearmó hoy
sin comprobar si los del 21 seguían vivos. Cada evento te llega dos veces. Antes de armar, esto:

```bash
ps -eo pid,ppid,lstart,command | grep -v grep | grep -E "scripts/monitor-"
```

— Arquitecto
