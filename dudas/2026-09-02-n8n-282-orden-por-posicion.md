# Duda `#282` (segunda) — la opción A resultó INERTE: en v1 el abanico se ordena por POSICIÓN de lienzo, no por el array de `connections`

**De:** Agente n8n · **Para:** Arquitecto · 2 sep 2026
**Estado:** opción A aplicada tal cual la dictaste (STG `90d7f718`, tabla del §3 **5/5**, espejo sincronizado) — y la E2E midió que **no cambia el orden de ejecución**. Paro otra vez antes de tocar más el vivo.

## 1 · Lo medido

Inyecté el clic firmado (arnés del `#239b`, forma calcada de la exec 27282: `type='button'`,
`button.text='Ver la cotización'`, payload canónico real de la cotización 2316). **Exec 27918**:

- El `workflowData` de la propia ejecución lleva el abanico **ya permutado**:
  `[Extract Quote Click, Discount Reply Intake]`.
- Y aun así la entrega corrió primero, entera: `Discount Reply Intake` startTime `…291313` →
  (264 nodos) → `Insert Quote Delivery History` `…294038` → **después** `Extract Quote Click`
  `…294064` → `Persist Click Human Row` `…294083`.
- Resultado en tabla: `ai` **6221** < `human` **6222**. El criterio 2 sigue cayendo, con tu opción A
  puesta y verificada en forma.

## 2 · La causa, en la fuente de n8n (no es un misterio: es una regla)

`packages/core/src/execution-engine/workflow-execute.ts`, **n8n@2.28.7**, en el bloque
`executionOrder === 'v1'`:

```ts
// Always execute the node that is more to the top-left first
nodesToAdd.sort((a, b) => { ... a.position[1] ... a.position[0] ... });
```

Con `v1` (el nuestro, medido en `settings`), los destinos de un abanico se ordenan por **posición de
los nodos cabecera en el lienzo**: y menor (más arriba) primero; a igual y, x menor. **El orden del
array de `connections` no participa.** Y las cabeceras están así:

| cabecera de rama | position |
|---|---|
| `Discount Reply Intake` | `[4384, 620]` ← gana por y |
| `Extract Quote Click` | `[-4212, 1440]` |

Ni tú ni yo lo teníamos: tu handoff razonó con el array y mi opción A también. Lo he dejado escrito
como **gotcha 38** en `docs/gotchas-n8n.md` (defecto concreto que lo atrapó: este).

## 3 · El arreglo que sí cumple el objetivo de tu opción A

**Mover la cabecera del carril del clic por encima de la de entrega**: `Extract Quote Click` a
`y < 620` (propongo `[-4212, 560]`, y arrastrar `Persist`/`Restore` a la misma banda para que el
lienzo cuente la verdad; solo la cabecera decide, el resto es legibilidad). Es un cambio de
**coordenadas** — que en v1 es un cambio **semántico**, exactamente lo que el gotcha 38 avisa — y por
eso no lo aplico sin tu OK, aunque el objetivo («el carril del clic corre entero ANTES de la
entrega») ya lo dictaste. La verificación que propongo para el PASS: además de forma, **orden medido
en ejecución real** (`startTime` de `Persist` < `startTime` de `Discount Reply Intake`), que es la
prueba que a la opción A le faltó pedir.

## 4 · Lo que la E2E ya dejó medido (y bueno)

- **La fila `human` se inserta bien en el vivo**: id 6222, `content` = «Ver la cotización» (el título
  real que envió Meta), sesión `waq_2316` (la de la cotización, resuelta por `payload_v1`),
  `created_at` = epoch de Meta (15:51:30, insert real a las 15:51:34). Criterios 3 y 4: **PASS**.
- **Criterio 5: PASS medido.** Reinyecté el MISMO webhook (mismo wamid, exec 27923):
  `duplicado_wamid`, sigue habiendo **una** fila, y de propina la re-entrega tampoco se repite
  (`IF Already Sent?` corta: su ledger va por wamid inbound).
- **Criterio 6 sano:** `interes_confirmado` de 2316 se quedó en **1** tras dos Notify — Django
  dedupe. El `#135` intacto.
- Efecto lateral del arnés que Alberto verá: el clic nuevo (wamid nuevo) **re-entregó el PDF** de la
  2316 a su WhatsApp de prueba. Comportamiento preexistente del carril de entrega (ledger por wamid;
  Meta no permite repetir botón, así que en la vida real no pasa), no lo introduje yo.

## 5 · Tu medición del §5: **ORDER BY id, confirmado en la implementación**

`@langchain/community@1.1.27` — la versión exacta que fija el catálogo pnpm de n8n@2.28.7
(`pnpm-workspace.yaml`) — `dist/stores/message/postgres.js:85` (tarball de npm, código que corre):

```js
const query = `SELECT message FROM ${this.tableName} WHERE session_id = $1 ORDER BY id`;
```

`MemoryPostgresChat` usa esa clase tal cual y encima `BufferWindowMemory` con k=60. Tu razonamiento
del §2 queda apoyado en medición: **la memoria lee por `id`**, y por tanto la opción A sigue siendo
la correcta — solo que su palanca real son las coordenadas, no el array.

## 6 · Qué pido

OK (o alternativa) al movimiento de coordenadas del §3. Con él: re-E2E completa con orden medido,
criterio 7 (mensaje normal detrás del clic, respuesta pegada), y después el clic real de Alberto
sobre cotización nueva, que sigue siendo tuyo y de nadie más.

— Agente n8n
