# Checkpoint de materialización del par sintético A/B — preparado, **no ejecutado**

Responde a `DJANGO_S1_FIXTURE_MATERIALIZATION_CHECKPOINT` (`HYL-WAI#132`, `c.5227149911`).
**Nada se ha ejecutado contra STG.** Cero DML, cero DDL, cero deploy, cero `config:set`.

Script: `scripts/s1-fixtures/materializar-par-ab.py` (este repo, rama `main`).

## 1. Qué crea, exactamente

| Objeto | Cantidad |
|---|---|
| `qualitas_cotizacion` | **2** |
| `qualitas_lead` | **2** |
| detalle de cotización (`xml_cache`) | **2** |
| `whatsapp_sessions` abiertas | **2** |

Las dos comparten **el mismo recipient sintético** y tienen cotización, lead y `conversation_id`
**distintos**, que es la condición que faltaba y que bloqueó la Orden 1.

Nada más se crea, y **nada preexistente se toca**: el script solo hace `INSERT`. Cero `UPDATE`,
cero `DELETE`, cero DDL.

## 2. Cómo se ejecuta — sin desplegar nada

Corre contra el código Django **ya desplegado**, así que no exige merge ni deploy:

```bash
heroku run --app hyl-wai-stg -- python manage.py shell < scripts/s1-fixtures/materializar-par-ab.py
```

Por defecto es **dry-run**: evalúa guards, construye todo, comprueba postcondiciones y **revierte la
transacción a propósito**. Solo con `S1_FIXTURE_APPLY=1` hace commit.

## 3. Guards — fail-closed, antes de abrir la transacción

1. **`AMBIENTE_PRUEBAS` tiene que estar activo.** No es una convención: está a `1` en STG y **no
   está definida en producción**, donde el default del código es `"0"` → `False`. Verificado en
   ambos. Es un discriminador intrínseco, y por sí solo ya impide que este script corra en PROD.
2. **Django tiene que seguir en `shadow`** — se lee el modo real, no se asume.
3. **`S1_FIXTURE_RUN_ID`** obligatorio y con el patrón contractual `^s1-\d{8}T\d{6}Z-[0-9a-f]{8}$`.
4. **`S1_FIXTURE_RECIPIENT`** obligatorio, con forma E.164 de móvil mexicano.
5. **Idempotencia dura**: si el run-id ya dejó cualquier huella, deniega. No se repite ni se
   completa una corrida a medias.

Si un guard no se puede evaluar, **deniega**. Nunca se asume que se cumple.

## 4. El recipient no se inventa, y esto no es un detalle

El script **no genera el teléfono**: lo exige por variable de entorno y solo valida su forma.

Un número inventado puede ser el de una persona real, y mandarle un WhatsApp de prueba sería un
envío no solicitado a un tercero. Es exactamente lo que el contrato protege con
`synthetic_attestation`, cuyo propio código dice que *«el builder no infiere si un teléfono es de
alguien»*. Quien puede atestiguar que un número es sintético **y** está en la allowlist del sender
es el owner, no el script.

**Esto es lo único que falta para poder ejecutar**: un recipient sintético atestiguado y
allowlisted, suministrado por canal privado.

## 5. Atomicidad y postcondiciones

Todo ocurre dentro de un único `transaction.atomic()`. Dentro, y antes del commit, se comprueba
releyendo de la base —no asumiendo lo que se acaba de escribir—:

- exactamente 2 / 2 / 2 / 2 objetos;
- cotización, lead y conversación **distintas** entre A y B;
- las dos sesiones existen, las dos están `open`, y **comparten un único `phone_number`**;
- cada lead está emparejado con su cotización, la cotización lleva el recipient y tiene detalle.

Cualquier diferencia lanza y **aborta el conjunto antes del commit**. El rollback no es un
procedimiento aparte: es la ausencia de commit.

## 6. Sobre el detalle de cotización — decisión declarada

La fila `xml_cache` se crea con los seis XML a **NULL**, deliberadamente.

El endpoint de detalle recorre los seis escenarios y **solo parsea los que tienen contenido**, así
que con NULL responde `200` con `opciones_cotizacion` vacío. Meter un XML inventado obligaría al
parser real de Quálitas a digerir algo falso, y un fallo ahí rompería el endpoint para el par A/B:
más superficie de riesgo y ningún beneficio para Gate A, que no llama a Django.

**Queda declarado por si liderazgo quiere lo contrario:** si el flujo S1 exigiera opciones no
vacías, hace falta una segunda decisión sobre qué XML sintético es aceptable. No se ha asumido.

## 7. Control offline — positivo y negativo

Ejecutado, sin tocar STG:

- **el script compila** (`py_compile`);
- **guard del run-id**: acepta el formato canónico y **rechaza** mayúsculas hex, fecha malformada,
  vacío y texto libre — 5/5;
- **guard del recipient**: acepta E.164 correcto y **rechaza** dígito de más, prefijo no mexicano,
  carácter no numérico y vacío — 5/5;
- **el dry-run es el control negativo estructural**: recorre el camino completo de escritura y
  revierte, de modo que se ejercita todo salvo el commit.

**Un fallo real que este control encontró antes de ejecutar nada:** la primera versión creaba el
lead con `estado="nuevo"`, que **no existe** en `ESTADOS_LEAD`. Django **no valida choices** en
`create()` —no hay CHECK en la base—, así que habría entrado en silencio y dejado dos leads con un
estado inexistente. Corregido a `COTIZACION_INICIADA`, que es el default del modelo.

## 8. Lo que el script NO hace

Sin llamadas externas —no instancia servicios de Quálitas ni de Meta—, sin envíos, sin DDL, sin
deletes, sin tocar filas preexistentes, sin `config:set`, sin deploy, sin migraciones, sin mover
Django de `shadow` y sin rozar PROD.

**`poblar_pruebas_dummy` se consultó como referencia y no se reutiliza**, por tres motivos
concretos: deriva el teléfono del índice de iteración —así que nunca produce dos cotizaciones con
el mismo recipient, que es justo lo que necesitamos—, emite `CREATE TABLE IF NOT EXISTS`, y
**borra filas** (`_delete_n8n_rows_for_scenario`) antes de insertar.

## 9. Salidas

- **Pública**: una línea `S1_FIXTURE_RESULT` con estado y conteos. Sin IDs, sin teléfono, sin
  run-id, sin filas.
- **Privada**: con `S1_FIXTURE_PRIVATE_OUT`, un JSON `0600` creado con `O_EXCL` —falla si ya
  existe, en vez de sobrescribir— con los valores que necesita el binding de la Orden 2.
