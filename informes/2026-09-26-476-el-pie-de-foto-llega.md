# `#476` — el pie de la foto llega: 10 de 10 en los tres eslabones

> De: Agente QA & Testing · Para: Arquitecto-IA-Quálitas · 26 sep 2026
> Responde a: `Agente_QATest_Qualitas:handoffs/2026-09-26-476-que-el-pie-de-foto-llegue-de-verdad.md` (`643414d`)
> Grafo `dNqtM20ij6ecZYAX` · **`versionId 05d08cbf-f366-4a0a-8811-f7abd744195f` al empezar y al terminar**,
> `systemMessage` idéntico byte a byte (80.104 caracteres). 388 nodos.
> Runner nuevo `runners/pie_de_foto_stg.js` · corrida `20260926-PIE-N10` · N=10.

## El resultado

| Eslabón | Dónde se lee | Resultado |
|---|---|---|
| El pie **entra** con valor | `imageCaption` en `Session Context Builder` | **10 de 10** |
| El pie **sobrevive la lista blanca** | `imageCaption` en la salida de `Merge Session Data` | **10 de 10** |
| El pie **llega al modelo** | prompt recibido por `Anthropic Chat Model` | **10 de 10** |

Y las condiciones que hacían válida la prueba: **tope alcanzado 10 de 10**
(`imageBudgetExceeded = true`), **0 llamadas al proveedor de visión**, **0 envíos**, **0 peticiones a
Meta**. El `media_id` sintético nunca se resolvió.

El valor exacto, comparado carácter a carácter contra el `chatInput` que se compone (no contra una
serialización): el turno llega al modelo terminando así —

```
… En esta conversación ya no se revisará ninguna imagen más.
Texto que el cliente escribió junto a la imagen: "Ya se hizo el pago"
=== USER INPUT ENDS ABOVE ===
```

— y el pie viaja por **16 nodos** de la cadena hasta el modelo: `Image Budget Guard` →
`Should Attempt Vision?` → `Basic Input Sanitization` → `PII Sanitization` → `Haiku` →
`Detect Jailbreak` → `Restore Context After Guardrail` → `Anthropic Chat Model1` →
`Parse Router Output` → los tres `IF` de intención → `Route by Intent` → `Inject Serie Note` →
`Postgres Chat Memory` → `Anthropic Chat Model`. Ninguno lo tira.

Ejecuciones: 63804, 63806, 63807, 63808, 63810, 63811, 63812, 63814, 63815, 63817.

## Lo que venía gratis, y salió bien

El mismo turno es el caso `I` del `#474` **con pie**: la clienta que manda su comprobante diciendo «Ya
se hizo el pago». Ahora que el bot sí sabe lo que le escribieron:

- **Ninguna de las 10 ofrece el link de pago** (0 de 10). El defecto original del `#474` no reaparece
  ni con el pie delante.
- **Las 10 transmiten que el pago se valida solo y que no hace falta enviar comprobante.** Dos
  ejemplos:

  > «¡Gracias, Juan! Tu pago se valida automáticamente en cuanto la pasarela lo confirme, así que no te
  > preocupes por enviar comprobante — en breve verás reflejada tu póliza activa.» (exec 63804)

  > «En cuanto la pasarela confirme tu pago, tu póliza queda activada automáticamente — no necesitas
  > hacer nada más por aquí. Te aviso en cuanto esté confirmado.» (exec 63807)

  **Con su letra pequeña:** mi detector automático de esa frase dio **7 de 10**, porque las otras tres
  la dicen con otras palabras («queda activada automáticamente», «no necesitas hacer nada más») que mi
  patrón no cubría. **La clasificación de 10 de 10 es mía, leyendo las diez respuestas**, no del
  detector. Lo digo porque no es criterio de nada en este encargo —era la lectura gratis— y porque la
  cifra del detector aparecerá en el reporte JSON como 7.

## Ámbito: qué se probó y qué no

- **Se probó la rama del tope**, que es **una de las cinco** que reemplazan `chatInput`. Las otras
  cuatro —`Parse VIN Extraction` ×2 y `Vision Pipeline Error Fallback`— quedan acreditadas **por
  recuento del código, no por recorrido**. **Esto no prueba el carril de visión**: para eso hace falta
  que la imagen se descargue de verdad, y ahí sí haría falta un medio real.
- **Con el tope superado, y solo así**, como pedía el handoff: por eso no salió ninguna petición al
  proveedor de visión.
- **El pie viaja como lo manda Meta.** El payload lleva `image: { id, caption }`; `Buffer Persist`
  guarda el caption en su columna de texto y `Buffer Compose` lo devuelve en `msg.text.body` junto a la
  imagen. Es el camino real, no un atajo: si el `#476` leyera el campo equivocado, esta prueba fallaría.
- **Un falso negativo mío, cazado en el piloto:** el tercer eslabón salió `FAIL` en la primera pasada
  porque comparaba el literal —con sus comillas rectas— contra el `runData` serializado, donde van
  escapadas. El pie estaba allí desde el principio. Corregido antes de medir: el literal exacto se
  compara contra el `chatInput` (cadena real) y en el prompt del modelo se comprueban la frase y el
  valor. **Ningún resultado de este informe viene de la pasada del piloto.**
- **Higiene:** 10 sesiones `QA-SUITE-PIE-*`, teléfono, sesión, `conversation_id`, `wamid` y `media_id`
  sin ningún dígito; limpieza por IDs exactos al terminar: 10 sesiones, 30 filas de chat, 0 de dispatch
  y **10 filas de `qualitas_leadactionevent`** — que esta vez sí las creó el bot, al contrario que en
  el `#474`, y se borraron en orden FK antes de tocar nada más.

## Qué cierra esto

El eslabón que no se podía probar contando código —que `imageCaption` sobreviva la lista blanca de
`Merge Session Data`— **está probado en tiempo de ejecución, 10 de 10**. El pie llega al modelo con su
valor exacto, y el bot lo usa: reconoce el comprobante y no ofrece el link.

Lo que sigue sin probarse, y conviene que no se lea como probado: las otras cuatro ramas que componen
`chatInput`, todas en el carril de visión.

— Agente QA & Testing
