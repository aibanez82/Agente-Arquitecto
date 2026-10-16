# Informe — SESIÓN A · (j) `#353`: revisión fresca del paquete `n8n_payment_events`, rol privado y merge a `stg`

**De:** Agente n8n · A · **Para:** Arquitecto · **16 oct 2026**
**Orden:** `Agente-n8n:handoffs/2026-10-14-A-firmas-orden-prod-591-y-cola.md`, fila j.
**Último comentario de Juan en el `#353`** (`oilycoyote`, 10 oct): «revisión fresca, merge a `stg` de Agente-n8n y definición privada de roles. Condición de retorno: paquete integrado y checkpoint separado para cualquier DDL live».
**Ningún entorno vivo tocado:** ni DDL ni grants en STG ni en PROD.

**Una precisión sobre el handoff:** el paquete `088981f6` no lo entregó Juan. Lo entregué yo, el Agente n8n, el 16 sep, por el handoff `70429eca`. Lo que hizo Juan el 10 oct fue auditar a quién le tocaba y asignármelo con esas tres tareas.

## 1 · Revisión fresca (16 oct)

| Comprobación | Resultado |
|---|---|
| Suite efímera (`test-efimero.sh`, PostgreSQL local sin red), sobre `088981f6` tal cual | **16/16** |
| `check-drift` del paquete contra **STG** (solo lectura de catálogos) | **`conforme`**: 4 columnas, PK única, sin índices extra |
| `check-drift` contra **PROD** (solo lectura) | **`divergente`**: «la tabla `public.n8n_payment_events` no existe». Es lo esperado: el DDL nunca se autorizó |
| Uso real en STG: Payment Confirmation `Ob5JYHYbc23SLp0A`, `4594e0a8` | el **único** punto de escritura sigue en `' Mark Session Completed'` (con espacio delante en el nombre del nodo): `INSERT INTO n8n_payment_events … ON CONFLICT`, y el propio SQL prohíbe los `SELECT` hermanos. Coincide con el mínimo del paquete, `INSERT` + `SELECT (event_id)` |
| Uso en PROD: Payment `6f1968da` (espejo de `main`) | **no usa la tabla.** El Payment S1 no está promovido |

## 2 · La definición privada de roles

**Cómo la he leído.** Ninguna de tus órdenes lo concreta. Lo interpreto así: el nombre del rol de n8n en PROD, la IP y el host del servidor **no deben vivir en el repo**. El paquete los llevaba escritos en `README.md`, en `grants.sql` y como valor por defecto en `payment_events_pkg.py`.

**Commit `e5ea29d1`, encima de `088981f6`** (sin reescribir lo que ya estaba revisado por SHA):
- **Rol sin valor por defecto.** Sale de `--role` o de la variable **`PAYMENT_EVENTS_N8N_ROLE`**.
- **Sin rol, `check-grants` responde `no_comprobable`** (exit 2): nunca da un «conforme» sin haber leído. Es un control nuevo en la suite, que ahora da **17/17**.
- **Docs genéricas.** `grants.sql` y `README.md` remiten al `.env` del entorno; ya no nombran el rol, la IP ni el host.
- **La definición en sí** está en el `.env` de PROD de esta máquina (gitignored), con el valor medido el 15 sep.

**Lo que no se puede borrar:**
- el nombre sigue en la **historia** de la rama (`088981f6`), y no la reescribo;
- también está en mi comentario del `#353` del 16 sep.

**Si «privada» quería decir otra cosa, dímelo y lo cambio.** Por ejemplo, un **rol dedicado** de n8n que no sea el *owner*. Eso sí sería un DDL vivo y necesitaría su propio checkpoint.

## 3 · Merge

- **`feature/353-paquete-n8n-payment-events`** (`088981f6` + `e5ea29d1`) → **`stg`** de `aibanez82/Agente-n8n`, con merge `--no-ff` **`7fc8c580`**.
- Son 5 ficheros, todos en `scripts/353/paquete-n8n-payment-events/`, +340 líneas; nada más.
- La rama ya estaba verde y su relato va en el mensaje del merge.

## Lo que sigue (no lo hago yo)

- **Cualquier DDL o grant en un entorno vivo** va con **checkpoint aparte**, como pide Juan: crear la tabla en PROD, y cualquier rol dedicado.
- El paquete está listo para eso:
  - `bootstrap.sql` es idempotente;
  - `check-drift` y `check-grants` se pueden pasar antes y después;
  - en PROD, `check-grants` es afirmativo-comprobable, pero la denegación no se puede comprobar (el rol es *owner*).

Agente: Agente n8n · A
