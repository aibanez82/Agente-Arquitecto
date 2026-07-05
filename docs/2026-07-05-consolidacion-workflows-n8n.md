# Propuesta de consolidación de workflows n8n + convención anti-colisión

> Autor: Arquitecto-IA-Qualitas (Nivel 2)
> Fecha: 5 julio 2026
> Origen: al diagnosticar el Bug #12 (inbound caído) se descubrió que la instancia n8n tiene **15
> workflows, de los cuales solo 3 son de producción**; el resto son duplicados/backups/staging
> creados ad-hoc, y **varios comparten `webhookId` con producción** — la causa raíz del Bug #12.
> Ejecutor de los borrados: Agente n8n (o Alberto en la UI). Este doc es el diagnóstico + plan.

> **✅ EJECUTADO (5 jul 2026, ~20:11 UTC) por el Arquitecto vía API** (autorizado por Alberto: "por
> mí borramos todo stg"). Los 12 duplicados borrados (DELETE `/workflows/{id}`, todos HTTP 200).
> Instancia verificada: quedan **exactamente 3 workflows, los de producción, todos activos**. Peligro
> de colisión de webhookId eliminado. **NO se tocó la rama `stg` de git** (conserva el fix del Bug
> #10 pendiente de merge). Falta: re-exportar los 3 de prod a `docs/n8n-workflows/` (export actual es
> del 3 jul).

---

## Inventario completo (API en vivo, 5 jul)

Leyenda: **ON** = activo · nodos = tamaño · "colisión" = comparte webhookId con otro workflow.

### ✅ PRODUCCIÓN — CONSERVAR (3)

| Estado | Workflow | id | webhookId(s) | Última ejec. |
|---|---|---|---|---|
| ON | `WhatsApp Insurance Quotation Bot` | `BtOaZm7WlZT-24V7hqCnF` | `18c1b498`, `52d0be99` | 2026-07-03 22:38 (corte Bug #12) |
| ON | `WhatsApp Insurance Quotation Bot - Payment Confirmation` | `disvKr7iVhnNnefuiqJbJ` | `8f82eb47` | — |
| ON | `Retomar Conversacion` | `96XfJZcwvlHnVJLko3G8-` | `afd2b47d` | 2026-07-03 21:33 |

### 🗑️ DUPLICADOS DEL BOT (61 nodos c/u) — BORRAR (7)

| Workflow | id | updated | webhookId(s) | Colisión |
|---|---|---|---|---|
| `...Bot` (copy) | `CPcP1m8sURQIOAGgCN8s0` | 07-04 18:55 | `18c1b498`, `52d0be99` | 🔴 **con PROD** — recibió tráfico Meta real 01–02 jul |
| `...Bot_STG` | `DFg__oxPp2x2uaXkhvj44` | 07-04 21:06 | `18c1b498`, `52d0be99` | 🔴 **con PROD** — trabajo Bug #10 (a salvo en git) |
| `...Bot_stg` | `0KX6Tg0ljmpIVtFslubUA` | 07-04 21:06 | `18c1b498`, `52d0be99` | 🔴 **con PROD** — trabajo Bug #10 (a salvo en git) |
| `...Bot copy` | `qjuGq9VNImNIo4mR` | 07-02 17:36 | `b862615e`, `e33deb24` | 🟠 entre sí con `uOuB_` |
| `...Bot copy` | `uOuB_DhOYDsPS4pyA0e3U` | 07-04 18:55 | `b862615e`, `e33deb24` | 🟠 entre sí con `qjuGq9` |
| `...Bot_BCK_2jul_17:13` | `DFnKks01n0w5di3b` | 07-02 23:28 | `53c85a99`, `ae28c89c` | — (propio) |
| `...Bot_STG` | `AVvf8pRKa6UfK2f6` | 07-04 19:46 | `55a308b3`, `f4baacc5` | — (propio) |

### 🗑️ DUPLICADOS DE PAYMENT CONFIRMATION — BORRAR (2)

| Workflow | id | webhookId |
|---|---|---|
| `...Payment Confirmation copy` | `wKmWR0ErQk3KGx7V` | `f9aac998` |
| `...Payment Confirmation_STG` | `ECHPePK6K9VkbrB9` | `cb7f301d` |

### 🗑️ DUPLICADOS DE RETOMAR CONVERSACION — BORRAR (2)

| Workflow | id | webhookId |
|---|---|---|
| `Retomar Conversacion copy` | `IiQXg3Tmc5EWd7mb` | `58367aff` |
| `Retomar Conversacion_STG` | `I4kFMtiVpqKHPGQ2` | `d833e825` |

### 🗑️ SCRATCH — BORRAR (1)

| Workflow | id | Notas |
|---|---|---|
| `Demo Envio Mensajes Whatspp` | `wwQ8DGia_o_yV1a-xfYhO` | 2 nodos, nunca ejecutado |

**Total: 15 → 3.** 12 a borrar.

---

## Por qué pasó esto (causa del desorden)

- Al **duplicar** un workflow en n8n, el nuevo **hereda el `webhookId`** del trigger. n8n no lo
  regenera.
- El trabajo del Bug #10 se importó como staging con el commit `9d54c35` ("quitar id y dejar inactive
  para import seguro") — pero eso quitó el **id del workflow**, NO el **`webhookId` del nodo
  trigger**. Resultado: los `_stg`/`_STG` importados conservaron `18c1b498` → **colisión con
  producción** → mecanismo del Bug #12 (activar/desactivar un `_stg` des-registra la ruta de prod).
- Cada iteración de Bug #10 dejó una copia nueva (`copy`, `_STG`, `_stg`, `_BCK_2jul`) sin limpiar
  las anteriores → acumulación de 12 duplicados.

---

## Seguridad de los borrados (verificado)

- **Los 61-nodos de staging del Bug #10 (`DFg__`, `0KX6`) están a salvo en git:** repo
  `aibanez82/Agente_n8n`, rama `stg`, `workflows/WhatsApp Insurance Quotation Bot.json`, commits
  `591569f`→`2570dea`. Borrarlos del instance NO pierde el trabajo — es re-importable.
- **Borrar un workflow INACTIVO no des-registra el webhook de producción.** El peligro es
  *activar→desactivar* una copia que colisiona; *borrar* una copia ya inactiva es seguro para prod.
- Producción (`BtOaZm7...`) y los backups viven también en `docs/n8n-workflows/` de este repo (aunque
  ese export es del 3 jul — conviene re-exportar fresco, ver más abajo).

---

## Plan de ejecución (orden importa)

1. **[Bug #12 primero]** Reactivar la ingesta de prod: desactivar+activar `BtOaZm7WlZT-24V7hqCnF`
   para re-registrar la ruta `18c1b498`. Verificar entrada (ejec. nueva `> 22:38:53Z`,
   `n8n_chat_histories.id > 4693`). *(Ver handoff Bug #12.)*
2. **Borrar los 3 que colisionan con prod** (`CPcP1`, `DFg__`, `0KX6`) — elimina el peligro
   estructural. Su JSON de Bug #10 ya está en git.
3. **Borrar los otros 9 duplicados** (`qjuGq9`, `uOuB_`, `DFnKks`, `AVvf8p`, `wKmWR0`, `ECHPePK`,
   `IiQXg3`, `I4kFMt`, `wwQ8D`).
4. **Re-exportar los 3 de producción** a `docs/n8n-workflows/` de este repo (fuente de verdad
   sincronizada; el export actual es del 3 jul y ya se demostró que diverge).

Borrado vía API (Agente n8n): `DELETE /api/v1/workflows/{id}` por cada id. O en la UI de n8n.

---

## Convención anti-colisión (para que no vuelva a pasar)

1. **Un solo workflow activo por función** (bot / payment / retomar). ✅ ya se cumple.
2. **Ningún workflow no-productivo debe compartir el `webhookId` de producción.** Al crear un
   staging, **regenerar el `webhookId` del nodo trigger** (abrir el nodo y regenerar, o borrar+recrear
   el trigger) — no basta con quitar el id del workflow.
3. **Staging efímero, no permanente:** importar desde git rama `stg` cuando se prueba, **regenerar
   webhookId**, y **borrar tras validar**. Nada de dejar `_stg`/`_STG`/`copy` acumulándose.
4. **Los backups viven en git** (repo Agente_n8n + `docs/n8n-workflows/` de este repo), NO como copias
   dentro del instance de n8n.
5. Si se quiere un staging permanente, que sea **exactamente uno** por función, inactivo, con
   `webhookId` propio y documentado — nunca el de prod.

---

## Decisiones para Alberto

- **(A)** ¿Borrado completo (15 → 3, recomendado; git es el backup) o conservar un `_STG` permanente
  por función con webhookId propio regenerado?
- **(B)** El `_STG`/`_stg` del Bug #10 (`DFg__`, `0KX6`) — ¿ya se validó E2E en staging y se puede
  mergear `stg`→`main`? Si aún no, borrar del instance está bien (git lo conserva) pero habrá que
  **re-importar con webhookId regenerado** para hacer la validación E2E pendiente.
