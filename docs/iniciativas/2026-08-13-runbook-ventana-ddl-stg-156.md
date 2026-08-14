# Runbook — Ventana de DDL en STG · `HYL-WAI#156`

**Fecha:** 13 ago 2026 · **Autor:** Arquitecto · **Para:** Alberto (aplica) · **Entorno:** `hyl-wai-stg`
**Paso 4** del plan de `docs/iniciativas/2026-08-11-hyl-wai-156-descuentos-lado-nuestro.md` §10.

**Qué hace esta ventana:** publica en STG los **12 objetos DDL** de #156 — 11 migraciones de n8n y 1
del Dashboard, **6.185 líneas de SQL**. Nada de esto activa nada: son tablas, vistas y funciones que
quedan ahí esperando a que los workflows se importen (paso 5). **Ningún workflow se toca en esta
ventana.**

**Qué desbloquea:** el `503 dependency_unavailable` de «Tomar conversación» en STG, que hoy falla
porque le faltan `public.conversation_control_v1` y `public.dashboard_control_commands`.

---

## 0. Quién aplica y quién acredita

| | Quién | Con qué |
|---|---|---|
| **Aplica** | Alberto | TablePlus contra `hyl-wai-stg` |
| **Acredita** | Arquitecto | lectura de `pg_catalog` tras cada bloque |

Los ejecutores **no** aplican: sus handoffs les prohíben expresamente tocar una BD viva, y no tienen
credenciales de STG. Esto no cambia en esta ventana.

**La cuenta:** la del `DATABASE_URL` de `hyl-wai-stg` — usuario `u81gb6n2j32hnm`. Verificado el 13 ago:
es **owner** de `whatsapp_sessions`, `whatsapp_sessions_archive`, `dashboard_conversation_claims` y
`n8n_chat_histories`, las cuatro con `relacl = null`.

### Sobre los GRANTs: no hacen falta, y esto cierra el pendiente 5 *para STG*

Las migraciones de n8n **no llevan `GRANT` a propósito**, y el Agente n8n lo declaró: el contrato pide
tres roles (n8n DML, Dashboard claims, Django `SELECT`-only) y **hoy es mono-rol**, así que escribirlos
produciría sentencias contra roles inexistentes.

**Verificado en vivo, y corrige lo que dice la entrega del Dashboard:** `readonly_leads` **no existe en
STG** (0 coincidencias en `pg_roles`). Su aviso —«la vista necesita su GRANT a `readonly_leads`»— es
correcto **para PROD** y no aplica aquí. En STG todo pertenece a la misma cuenta, y el Dashboard lee
con esa misma cuenta: es la única explicación de que hoy pueda leer `dashboard_conversation_claims`
(`relacl = null` ⇒ solo el owner).

> **No se ejecuta ningún `GRANT` en esta ventana.** El día que existan los roles, la sentencia que
> hará falta está escrita como texto en `Agente-n8n:docs/156/entrega-n8n.md` §2. **En PROD esto será
> distinto** y hay que re-verificarlo allí: `readonly_leads` sí existe y el pendiente 8 sigue abierto.

---

## 1. Precondiciones — las tres bloquean, y una es de seguridad

### 1.1 ⛔ Escopear las variables de Vercel ANTES de aplicar

`N8N_OPERATOR_WEBHOOK_BASE_URL` y `N8N_OPERATOR_WEBHOOK_SECRET` viven con alcance **`Preview` a secas**,
**sin override para la rama `stg`**. Es el patrón del **bug #17** con `N8N_PROACTIVE_WEBHOOK_URL`, donde
el Preview de `stg` acabó apuntando al n8n de **PROD**.

Hoy no ha hecho daño **solo porque el 503 corta antes de llegar a la red**. Esta ventana **quita ese
503**. Si se aplica sin escopear, la primera «Tomar conversación» en STG puede llamar al **workflow de
producción**.

> **Orden no negociable: escopear → ventana.** No al revés, y no «lo miro después».

> ### ✅ HECHO — 13 ago, 20:42 (verificado por el Arquitecto)
>
> Las dos con alcance **`Preview (stg)`** (`BASE_URL` ~20:30, `SECRET` ~20:35), y el alias de STG
> sirve **`dpl_GL6iUZ8PANpWzvT8sCs6ju5rrKKr`, creado 20:42:25** — **posterior a ambas**, así que el
> build las tomó. `Ready`.
>
> **La sintaxis del bug #17 ya no vale:** la CLI 54.16 pasó la rama a **posicional**
> (`vercel env add <name> preview <rama>`); `--git-branch` da *unknown option*.
>
> **Secreto rotado, no descubierto.** n8n no muestra el valor de una credencial guardada (ni UI ni
> API), así que se fijó uno nuevo en `Atencion Humana Header Auth STG` (`TyxFAIYtKfgHt9cv`) y el mismo
> en Vercel. Seguro porque el otro workflow que comparte esa credencial —`Metepec Liberar_stg`— está
> **`active: false`** y no lo llama Django (0 coincidencias en `stg` de HYL-WAI), y el Dashboard hoy
> corta con 503 antes de la red.
>
> **Lo que NO queda acreditado, y es deliberado:** los valores se guardaron como *sensitive*, así que
> ni `vercel env pull` los devuelve (`[SENSITIVE]`). Los dos modos de fallo siguen vivos hasta la
> primera llamada real: que `BASE_URL` **no lleve `/webhook`** (el cliente lo añade; con él iría a
> `/webhook/webhook/…`) y que el secreto coincida con la credencial. **Síntoma de cada uno: 404 el
> primero, 401/403 el segundo.**
>
> Higiene anotada para otra ventana: `Atencion Humana` y `Metepec Liberar` comparten credencial sin
> motivo — hoy da igual porque Metepec está apagado.

### 1.2 Punto de retorno

**`hyl-wai-stg` no tiene ni un backup** (`heroku pg:backups` → *No backups*). Antes de abrir:

```
heroku pg:backups:capture -a hyl-wai-stg
```

No es paranoia de más: son 12 migraciones y las de n8n crean funciones con `CREATE OR REPLACE`, que no
se deshacen solas.

### 1.3 La vista `002` se genera, no se escribe

`002` sale de una plantilla que `scripts/156/build-view.js` rellena con **los gates que la instancia
STG ejecuta hoy**. Antes de aplicarla, que el Agente n8n corra:

```
node scripts/156/build-view.js --check
```

Si falla, el fichero commiteado no describe la instancia viva y **hay que regenerarlo antes**, no
aplicarlo. Hoy no debería fallar —los workflows no se han importado y el vivo no ha cambiado—, pero es
la comprobación que convierte «debería» en «es».

---

## 2. Orden de aplicación, y el porqué del primero

**El Dashboard va PRIMERO.** No es preferencia: `002-conversation-control-v1.sql` **lee
`dashboard_conversation_claims` en cuatro sitios** (líneas 140, 150, 159, 171), y `001` declara
expresamente que **no toca esa tabla** porque su DDL es del Dashboard. Publicar la vista antes de que
claims tenga su forma final la dejaría apoyada en la tabla vieja — sin el `UNIQUE(session_id, epoch)`
del que depende su resolución de `authority_epoch` por backward scan.

| # | Fichero | Líneas | Qué publica |
|---|---|---|---|
| **A** | `Dashboard_SeguroAuto/migrations/2026-08-11-claims-epoch-anti-aba.sql` | 434 | `dashboard_control_commands` + los 5 gaps de claims (`bigint`, `conversation_id` 80, `CHECK(epoch>0)`, `UNIQUE(session_id,epoch)`) |
| **B** | `Agente-n8n/migrations/156/001-readiness-conversation-control-v1.sql` | 548 | readiness físico de `whatsapp_sessions` y del **archive** (cierra GAP-B: el archive tenía los tokens sin las banderas) |
| **C** | `…/002-conversation-control-v1.sql` | 407 | **`public.conversation_control_v1`** ← la que quita el 503 |
| **D** | `…/003-outbound-fence.sql` | 426 | `n8n_outbound_dispatch` + `n8n_outbound_reserve` |
| **E** | `…/004-history-inheritance.sql` | 412 | herencia de historial, funciones JCS y fingerprint |
| **F** | `…/005-evidence-views.sql` | 500 | vistas de evidencia + `n8n_discount_conversation_activate` |
| **G** | `…/006-checkpoint-outbound.sql` | 446 | **`n8n_checkpoint_outbound_claim`** ← sin esto, el `retomar-candidato` falla en el nodo SQL |
| **H** | `…/007-discount-resolution.sql` | 533 | resolución de la oferta |
| **I** | `…/008-discount-phase2.sql` | 549 | catálogo → oferta fase 2 |
| **J** | `…/009-discount-application-poller.sql` | 691 | polling de aplicación + `n8n_discount_application_handoff_v1` |
| **K** | `…/010-discount-conversation-handoff.sql` | 478 | cutover y activación |
| **L** | `…/011-discount-delivery.sql` | 761 | entrega del PDF |

> **`K` y `L` en ese orden, obligatorio:** las dos definen
> `n8n_discount_conversation_handoff_claim` con `CREATE OR REPLACE`. La versión buena es la de `L`.
> Aplicarlas al revés deja en la base la definición vieja **sin que nada falle**.

Rutas absolutas (los ficheros ya están en `stg` de cada clon; abrirlos en TablePlus y ejecutar tal
cual, **sin editar nada**):

```
/Users/AIP/claude-projects/Dashboard_SeguroAuto/migrations/2026-08-11-claims-epoch-anti-aba.sql
/Users/AIP/claude-projects/Agente-n8n/migrations/156/0NN-*.sql
```

> Los dos clones están en `main`. Para ver estos ficheros: `git checkout stg` en cada uno — o
> abrirlos desde `stg` sin mover el clon. **Cuidado con el working copy compartido**: si alguna
> sesión de agente está trabajando en ese clon, mover HEAD le cambia el suelo (nos pasó el 12 ago).

---

## 3. Ejecución

Van **de una en una**, en el orden A→L, y **se comprueba entre cada una**. Ninguna necesita que la
anterior haya «asentado»: si una aborta, se para la ventana y se llama al Arquitecto — no se salta al
siguiente fichero.

**Las guardas son suyas, no mías.** `001` trae 29 `RAISE EXCEPTION`, `005` trae 22, `006` cinco. Están
escritas para abortar nombrando el problema en vez de dejar la base a medias. **Un error que nombra
una tabla o una columna es la migración trabajando, no un fallo del procedimiento** — cópialo tal cual
y páralo ahí.

Todas son idempotentes (`IF NOT EXISTS` / `CREATE OR REPLACE`): **volver a ejecutar una que ya pasó no
rompe nada**. Si dudas de si una llegó a aplicarse, repetirla es más seguro que adivinar.

### Comprobación después de cada bloque

```sql
SELECT c.relkind, c.relname
FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND (c.relname LIKE 'n8n\_%' OR c.relname LIKE 'discount\_%'
       OR c.relname IN ('conversation_control_v1','dashboard_control_commands'))
  AND c.relkind IN ('r','v')
ORDER BY c.relkind, c.relname;
```

### Comprobación final de la ventana

```sql
SELECT
  to_regclass('public.conversation_control_v1')      AS vista_control,
  to_regclass('public.dashboard_control_commands')   AS ledger_dashboard,
  to_regclass('public.n8n_outbound_dispatch')        AS fence,
  to_regproc('public.n8n_checkpoint_outbound_claim') AS claim_checkpoint,
  (SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = 'public' AND p.proname LIKE 'n8n\_%')  AS funciones_n8n;
```

**Ninguna de las cinco puede salir `NULL`.** Si alguna sale `NULL`, esa migración no se aplicó.

---

## 4. Qué esperar justo después, para que no parezca un fallo

Repetir el POST de «Tomar conversación» en STG. **El resultado esperado es `202`, no `201`**, y es
correcto:

- el `503` desaparece — la vista y el ledger ya existen;
- pero los workflows **aún no están importados** (paso 5), así que el n8n vivo sigue contestando los
  cuerpos de Fase 4, y `claim.js` de #156 los clasifica `control_outcome_unknown` → `uncertain` → `202`
  («quedó pendiente de confirmación»).

**El `201` con `id` de claim llega tras el import**, no tras esta ventana. Quien vea el `202` y lo
tome por avería, hará rollback de una ventana que salió bien.

## 5. Lo que esta ventana NO hace

Importar ni activar workflows · tocar PROD · ejecutar `GRANT`s · crear roles · resolver el pendiente 5
(la brecha de roles queda **declarada**, y en STG es inocua por mono-rol) · corregir el
`phone_number_id` incrustado del worker, que va antes del import y es trabajo del Agente n8n.

## 6. Si algo sale mal

1. **Para.** No sigas con el siguiente fichero.
2. Copia el mensaje de error **entero** — las guardas nombran el objeto exacto.
3. Llama al Arquitecto: leo el catálogo y digo dónde se quedó.
4. `heroku pg:backups:restore` solo como último recurso y con el Arquitecto delante: restaurar tira
   también los datos de STG posteriores a la captura.
