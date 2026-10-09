# Informe — PROD viaje 5 (`#496` + `#565`): aplicado

**De:** Agente n8n · **Para:** Arquitecto · **9 oct 2026, 00:26 UTC**
**Responde a:** `Agente-n8n:handoffs/2026-10-08-orden-prod-viaje-5-limitada-y-24h.md` (41cc667c). Confirmación de Alberto en mi sesión («Go»).

**Bot PROD `458024c6` → `9c813fc3-2246-484b-9999-0ad9503bca80`.** El `Issue Policy Guard` sigue en `9aa96337` (comprobado tras el PUT).

- **Respaldo:** `backups/prod-viaje5/PROD-BtOaZm7WlZT-24V7hqCnF-458024c6-pre-20261009T002552Z.json`.
- **Espejo:** `main` y `stg`.
- **Script:** `scripts/prod-viaje5/promote-viaje5-prod.py`, rama `chore/prod-viaje5`.

## Método

- **`#565`:** el bloque viejo y el nuevo salen del diff del `systemMessage` en el commit de STG `39569d41`, que es un solo hunk. Se sustituyen sobre el `systemMessage` **de PROD**, exigiendo que el bloque viejo, con una línea de contexto a cada lado, aparezca **1 vez**. El de STG no se copia.
- **`#496`:** se exige que el `queryReplacement` de PROD sea igual al de STG antes de `e97b8dff`. Pasa al de después, que es igual al STG vivo: el array de 6, en el mismo orden.

## Diff, verificado en el vivo

- **Hojas cambiadas:** solo `AI Agent/options/systemMessage` y `Persist Limitada Observation/options/queryReplacement`.
- **`systemMessage` de AI Agent: exactamente 1 hunk** (líneas 825-827 → 825):
  ```
  -[LINK_PAGO]
  -
  -El link expira en 24 horas."
  +[LINK_PAGO]"
  ```
- **Lo que no viaja:** el `#257` ni el bloque del email; los recuentos de `hayAtencionHumana`, `numeroAtencionHumana` y `email` son iguales antes y después. El `systemMessage` de RAG queda intacto.
- **«expira en 24»: 0 en los nodos del bot** (y 0 en `activeVersion`).
  - Nota sobre tu «hoy aparece 1»: en los nodos era 1, efectivamente. La API devolvía 2 en total porque `activeVersion` lleva una copia de la versión activa. Medí sobre los nodos.
- **Nodos y aristas:** sin cambios; el resto de nodos, byte-idénticos; workflow activo.

## Pendiente

- **El primer mensaje de emisión real** sin la frase.
- **La primera observación de la Limitada** guardada entera.
- **Sigue en el `systemMessage`:** «Para activar tu cobertura, realiza tu pago en las próximas 24 horas:», que tu orden no incluía.

Agente: Agente-n8n
