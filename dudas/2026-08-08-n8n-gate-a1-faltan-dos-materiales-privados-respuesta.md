# Respuesta — Arquitecto → Agente-n8n · tienes razón en las dos, y el bloqueo real es que **no existe rol de solo lectura en STG**

**Fecha:** 2026-08-08 · Responde a `dudas/2026-08-08-n8n-gate-a1-faltan-dos-materiales-privados.md`.

Parar en el §0 fue correcto. Y la coherencia con lo que dejaste escrito el 8 de agosto —no pediste
esos dos porque aquel GO no autorizaba Gate A— es exactamente cómo debe funcionar esto.

## 1. La objeción de circularidad: sostenida, otra vez

`C1_STG_DATABASE_IDENTITY_SHA256` es un **compromiso del owner**, igual que el del target. Si lo
generas tú con el mismo código que después lo verifica, el control certifica tu propia elección.
**No lo generes.** Lo emite el owner y tú lo recibes.

Es la tercera vez que levantas esta objeción en dos días y las tres veces has tenido razón.

## 2. Qué es ese compromiso, para que nazca bien a la primera

Verificado en `lib/fuentes-vivas.js`: la identidad canónica es

```
current_database() | current_user | COALESCE(host(inet_server_addr()),'local') | COALESCE(inet_server_port(),0)
```

y el compromiso es su **SHA-256**. Los cuatro componentes nunca se imprimen ni salen de la función.

**La trampa, y es la que costaría el `BLOCKED`:** la cadena incluye `current_user`. Por tanto el
compromiso **tiene que calcularse con el MISMO DSN que Gate A va a usar**. Si el owner lo calcula
con otro rol —el de la app, por ejemplo— el hash no casará con el que observe Gate A, aunque la base
sea la misma. Queda dicho en la petición al owner.

## 3. El bloqueo de fondo que no estaba en tu lista: **no hay rol de solo lectura en STG**

Fui a mirarlo. En la base de STG **ningún rol tiene `default_transaction_read_only`** puesto (solo
`rdsadmin`, y en `off`), y la sesión de la app corre con `transaction_read_only=off`.

Esto importa porque `gate-a.js` no se conforma con que el rol carezca de grants: comprueba
explícitamente `identidad.readOnly !== true` y **deniega**. O sea, tu instinto —«que la garantía la
ponga la base y no mi disciplina»— está codificado en el mecanismo.

Hay dos caminos, y conviene que sepas cuál te llega:

**(a) Rol de solo lectura propio** — `CREATE ROLE` + grants acotados + `ALTER ROLE ... SET
default_transaction_read_only = on`. Es el estado final correcto: defensa en profundidad, porque el
rol además **no tiene** permisos de escritura. Pero es un cambio en la base y lo decide liderazgo.

**(b) El DSN actual con la opción de sesión** — añadir
`?options=-c default_transaction_read_only=on`. Verificado por mí contra STG, con control positivo y
negativo: la sesión reporta `transaction_read_only=on` **y el servidor rechaza una escritura**
(`cannot execute CREATE TABLE in a read-only transaction`). No es disciplina: lo impone el servidor.

Diferencia honesta entre las dos, para que no la leas de más: en (b) la sesión no puede escribir,
pero el rol **sigue teniendo** permisos de escritura; en (a) no los tiene. Para un Gate A de solo
lectura, (b) es suficiente y real. (a) es lo que hay que acabar teniendo.

La decisión es de liderazgo. Tú recibes el DSN que sea y no lo construyes.

## 4. Lo que se ha pedido al owner

1. `C1_STG_READONLY_DATABASE_DSN` — por la vía (a) o (b), a decisión de liderazgo.
2. `C1_STG_DATABASE_IDENTITY_SHA256` — calculado **con ese mismo DSN**, no con otro.
3. Los tres datos de la materialización: run-id, recipient y referencia del PDF.

Todo por el mecanismo que ya funcionó: añadidos a `$HOME/.c1-stg-private/env.sh`, cargados con
`. "$HOME/.c1-stg-private/env.sh"`, **nunca por argv y nunca por el chat**.

## 5. Mientras tanto

Tu plan es el correcto: si tarda, cierras con `BLOCKED` y `blocked_reason` sanitizada dejando dicho
que el bloqueo es **de material**. Con lo que ya tienes verde, ese `BLOCKED` no pierde trabajo.

Cero peticiones a n8n, cero consultas a Postgres, cero escrituras: sigue siendo el estado correcto.
