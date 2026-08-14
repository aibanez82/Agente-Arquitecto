# Ventana de higiene — STG (abierta 14 ago 2026)

**Qué es:** el sitio donde se agrupa lo que fue apareciendo durante `HYL-WAI#156` y **no bloquea
nada**, para que no se pierda ni se cuele «de paso» en un trabajo cuyo objeto es otro.

**Regla que la origina:** varias de estas cosas se descubrieron mientras se hacía otra, y la tentación
en cada caso era arreglarlas allí mismo. Se decidió lo contrario — declarar y aplazar — porque un
cambio que entra dentro de otro es el que nadie revisa y el que se descubre tres semanas después.

**Ninguno de estos ítems bloquea descuentos, el import ni la E2E.** Se ejecutan cuando haya hueco.

---

## Ítems

### 1. Migración `012` — retirar la sobrecarga huérfana

**Verificado en vivo (14 ago):** `public.n8n_discount_conversation_handoff_claim` tiene **dos firmas**
—`(p_now timestamptz)` y `(p_now timestamptz, p_application_id bigint)`— porque `CREATE OR REPLACE` no
sustituye cuando cambia la firma. El worker llama con **dos** argumentos; la de uno **no la invoca
nadie**. Confirmado por el Agente n8n con el diff: los cuerpos son el mismo salvo lo que añade `011`, y
lo añadido es inerte con `NULL`, así que `_claim(t, NULL)` **es** `_claim(t)`.

- **Ya escrita:** `Agente-n8n:migrations/156/012-retira-sobrecarga-handoff-claim.sql`, cinco guardas,
  `DROP` por firma explícita. Su `STOP/SRC` rastrea el **texto** de las funciones porque `pg_depend`
  **no registra las llamadas desde un cuerpo plpgsql** — un `DROP` que solo mire el catálogo se
  llevaría una llamada viva sin enterarse.
- **Falta:** adaptarla a TablePlus (trae el `\if :dry_run` de psql) y aplicarla. · **Aplica:** Alberto.
- **Riesgo de no hacerla:** ninguno hoy. Deuda: dos funciones con el mismo nombre y semántica distinta
  es una trampa para quien llame a la que no era.

### 2. `CHECK` duplicado en `dashboard_conversation_claims`

**Verificado en vivo:** `ck_claims_state` y `ck_claims_state_valido` tienen la definición **idéntica**:

```
CHECK (state = ANY (ARRAY['active','released','revoked','expired']))
```

Uno viene de antes y otro lo añadió la migración de claims. Sobra uno.
**Ownership: Dashboard** (es su tabla). Que la retirada vaya en **migración versionada**, no a mano.

### 3. Dos índices idénticos sobre `whatsapp_sessions.quotation_id`

**Verificado en vivo** — mismo btree, misma columna, distinto nombre:

```
idx_whatsapp_sessions_quotation_id
whatsapp_sessions_quotation_id_idx
```

Era el **GAP-A** que el Agente n8n anotó en su E2. Cuesta escrituras en cada `INSERT`/`UPDATE` de la
tabla por la que pasa cada mensaje, sin aportar lecturas. **Ownership: n8n.**

### 4. Credencial compartida entre `Atencion Humana` y `Metepec Liberar`

`Atencion Humana Header Auth STG` (`TyxFAIYtKfgHt9cv`) la usan **los tres triggers de Atención Humana
y `Metepec Liberar_stg`**. Hoy es inocuo porque **Metepec está `active: false`** y no lo llama Django
—por eso fue seguro rotar el secreto el 13 ago—, pero cuando Metepec se encienda serán **dos sistemas
atados por un secreto común sin razón**: rotar uno rompe el otro.
**Ownership: Alberto** (acceso a la instancia).

### 5. Los 7 conectores sin salida de error

De los 9 puntos de envío de STG, **solo 2 tienen salida de error**. En los otros 7, un fallo de envío
aborta la ejecución y **la reserva se queda en `reserved` para siempre**: no llega a `uncertain`. No se
reintenta —eso el contrato lo quiere— pero la evidencia queda falseada y la tabla acumula basura.

**Decisión del Arquitecto (14 ago): declarar, no arreglar.** Darles salida de error cambia el
comportamiento de 7 nodos del camino caliente dentro de un trabajo cuyo objeto es otro.

> ### Confirmado (14 ago), con una condición y un matiz que suben el ítem de categoría
>
> **Mi lectura era correcta:** una reserva en `reserved` bloquea **solo su propio dispatch**, así que
> no impide envíos legítimos posteriores. No sube a bloqueante.
>
> **La condición es de diseño, no del fence:** solo se sostiene **si cada turno trae su propio
> `dispatch_id`**. El Agente n8n lo ha garantizado metiendo el `wamid` dentro (hasheado, porque el
> crudo lleva `=` y no pasa el charset). **Si alguien lo cambiara por algo estable entre turnos, una
> huérfana bloquearía ese conector para siempre.** Queda como invariante a proteger, no como detalle
> de implementación.
>
> **El matiz importa más que la condición:** lo que queda sin cubrir **no es solo basura, es el
> duplicado**. `uncertain` existe para hacer terminal el «puede que saliera y no lo sabemos»; en los
> 7 conectores sin salida de error ese estado **no se alcanza**, y sin él la protección contra
> reenvío no se activa. **Deja de ser cosmético: el peor caso es un mensaje repetido al cliente**, no
> una fila de más.
>
> **Pendiente de precisar con el Agente n8n:** el escenario exacto del reenvío —si requiere que Meta
> reentregue el mismo `wamid` o basta con un turno posterior equivalente—, porque de eso depende si
> esto aguanta en higiene o hay que adelantarlo.

### 6. Variables de Vercel con alcance `Preview` a secas

Las dos de Atención Humana quedaron escopeadas a `stg` el 13 ago, pero **el patrón sigue vivo para las
demás**: una variable en `Preview` sin rama **la hereda cualquier rama de preview**. Es el mecanismo
del **bug #17**, donde el Preview de `stg` acabó apuntando al n8n de PROD con tráfico real.
**Ownership: Alberto / Dashboard.** Revisar el inventario completo, no solo las dos ya tratadas.

### 7. `.pi-web/` en el repo de n8n

`.pi-web/relays/issue-156-…` (4 ficheros, 387 líneas): contabilidad interna del relay del agente de
Juan. Sin secretos; expone la disposición de su máquina. **Decisión de Alberto.**
Recomendación del Arquitecto: **dejarlo**, tiene valor como registro de cómo se construyó esto.

---

## Lo que NO entra aquí

- **Nada que bloquee** el fence, el import o la E2E de #156.
- **La sonda del rango de Quálitas**: excluida por decisión expresa de Alberto (14 ago), no es higiene
  aplazada sino alcance retirado. Vive en `2026-08-11-hyl-wai-156-descuentos-lado-nuestro.md` §12.
- **`bot_stg`**: ya resuelto — el Agente n8n le quitó el papel de baseline y sacó la capa C1 a
  `workflows/c1/` congelada. Si queda algo, es decidir su destino final, y es suyo.

---

## Añadido el 14 ago — bloqueantes de la promoción a PROD (no de STG)

Dos cosas que en STG se aceptan declaradas y en producción **no**:

### a) Payment Confirmation con control humano activo: no envía

Al fencear Payment se descubrió que `Mark Session Completed` cierra la sesión **antes** del envío
(`status='completed'`, `closed_at=NOW()`), y el fence exige `session_status='open'`: colocado
«inmediatamente antes de enviar» habría bloqueado **el 100 %** de las confirmaciones de pago.
Resuelto reservando **dos nodos antes**, con la sesión aún abierta.

Con eso resuelto queda la decisión de producto: **Alberto decide fence completo, sin excepción**
(14 ago). Consecuencia aceptada y registrada: *si un agente tiene la conversación tomada cuando entra
una confirmación de pago, el cliente no se entera de que pagó, y el agente tampoco de que había una
confirmación silenciada.*

En STG es aceptable —los clientes son pruebas—. **En PROD es un cliente real que pagó y no lo sabe.**
El día que exista el camino de «diferir y avisar», Payment es su destinatario natural.

### b) El duplicado de los 7 conectores sin salida de error

Ver §5. Mismo criterio: en STG se declara, en PROD hay que cerrarlo antes de promover.

