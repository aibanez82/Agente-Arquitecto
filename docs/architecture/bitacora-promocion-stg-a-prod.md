# Bitácora de promoción STG → PROD — los errores del 23 de agosto, para que la próxima no los repita

Escrita el 23–24 ago 2026, durante y después de la primera promoción real a producción.
**No es una crónica: es la lista de lo que salió mal y cómo se detectó.** La crónica está en el
`HYL-WAI#210` y en `docs/iniciativas/2026-08-23-plan-promocion-stg-a-prod-agil.md`.

> **Documento vivo.** Entra aquí cada error, trampa o práctica que evitó daño, **en el momento**. Un
> aprendizaje anotado tres días después ya perdió el detalle que lo hacía útil.

Hermano de `manual-migracion-stg-aprendizajes.md`, que cubre el viaje **hacia STG**. Este cubre el
viaje **hacia producción**, y la diferencia no es de dirección: **al otro lado hay clientes dentro**.
Un error en STG cuesta una tarde; aquí cuesta una conversación de WhatsApp que alguien estaba
teniendo.

---

## 0. La tesis

De los veintiún errores de esta jornada, **dieciséis eran míos** (el Arquitecto) y **ninguno lo detectó
quien lo cometió**. Los cazaron los ejecutores, las guardas de los propios artefactos, o una
medición que hice por otro motivo.

Eso dice dos cosas. La mala: **escalé riesgos antes de medirlos**, repetidamente. La buena: **el
sistema de canales funcionó** — un ejecutor que pregunta antes de ejecutar paró la única
recomendación mía que habría roto producción.

**La regla que resume la jornada:** *un mecanismo solo protege si quien ejecuta lo aplica, y una
afirmación solo vale si quien la escribe la ha medido.*

---

## 1. Antes de escribir el próximo plan de promoción

Responder esto **con mediciones, no de memoria**. Cada línea nace de un error de hoy.

| Pregunta | Por qué está aquí |
|---|---|
| ¿Cuántos objetos hay en STG **y quién puso cada uno**? | Conté 48 funciones en STG y las di por producto de las 24 migraciones. 2 eran de otra capa que las 24 **consumen y no crean**. F1 abortó a mitad. |
| ¿El orden de las migraciones es por **numeración** o por **dependencia**? | Ordené `156→161→163` por número. La `156/020` exige la `163/001` antes, y lo dice en su propia guarda. |
| ¿Qué objetos crea **Django** y cuáles la capa SQL? | Di por «colisión» que dos ficheros crearan la misma vista. Uno la creaba y el otro solo la mencionaba. |
| ¿Los candidatos referencian ids de **la instancia correcta**? | El candidato de PROD invocaba el `Issue Policy Guard` **de STG**, activo. Habría hecho que la emisión de pólizas de producción llamara al guard de staging. |
| ¿Qué **no puede cambiar** en el import? | Los `webhookId`. Si cambia el del trigger, **Meta deja de entregar y el funnel muere sin un solo error**. |
| ¿Qué lee cada **consumidor** de la base? | Escribí que el Dashboard leía columnas. Lee **vistas**. La dependencia era de otra fase. |
| ¿Cuál es la marcha atrás **real**? | Declaré «bloquea F1» por falta de backup. Había *point-in-time recovery* desde hacía días. |
| ¿Qué **flags** existen y cuáles están puestos? | Recomendé quitar dos variables «del envío». Gateaban el cliente entero, incluidos `iniciar` y `liberar`. |

---

## 2. Los errores, por clase

### 2.1 Contar sin comprobar la autoría de lo contado

Medí STG, vi **48 funciones**, y escribí «objetivo 48» en el handoff. De esas, **2 las crea otra
capa** (`port-132`) que las 24 migraciones solo consumen. La `156/003` abortó por su propia guarda:
`STOP/PRE: falta public.n8n_port132_canonical_phone(text)`.

**El ejecutor no leyó mal la orden: la orden pedía algo incompleto.**

> **Regla:** un recuento del entorno de referencia **no es** un objetivo de migración. El objetivo es
> lo que el artefacto **crea**; lo demás es dependencia y hay que declararla aparte.

### 2.2 Escribir una regla donde hacía falta un mecanismo

El plan decía *«merge `stg` → `main`»*. Lo corregí por *«rama cortada desde el SHA congelado»* y me
felicité por ello. **Ocho horas después Juan cortó la rama del tip de `stg`**, con el nombre correcto
y el punto de corte equivocado, y fusionó: entraron **89 migraciones en vez de 79**.

La corrección era buena y **no bastó**: el nombre de la rama viajaba en un comentario y el punto de
corte era una instrucción que otro tenía que aplicar bien.

> **Regla:** el congelado tiene que ser **un objeto que ya existe** —la rama ya cortada, el PR ya
> abierto por quien congela— no una instrucción para que lo cree otro. Una regla escrita en un
> documento no detiene un comando.

### 2.3 Recomendar sin medir el alcance de lo recomendado

Descubrí que promover el Dashboard estrenaría la cadena de envío que se había decidido no cablear, y
recomendé **quitar `N8N_OPERATOR_WEBHOOK_BASE_URL` y `..._SECRET` de producción**.

Esas dos variables **no gatean el envío: gatean el cliente entero**. Quitarlas habría apagado
`iniciar` y `liberar`, o sea **Atención Humana completa**, y reabierto el `#57` — que llevaba
funcionando desde agosto.

Lo paró el Agente Dashboard antes de que Alberto eligiera.

> **Regla, y es la más importante de la jornada:** **la opción que suena conservadora puede ser la
> destructiva.** «Quitar unas variables que no deberían estar» se lee como prudencia. Antes de
> recomendar retirar algo, medir **quién más lo usa** — no qué se llama.

### 2.4 Guardas que fallan abiertas

`information_schema` **filtra por privilegios**. Una precondición escrita sobre él, con un rol
restringido, devuelve cero filas y **pasa en silencio**: no distingue «el contrato se cumple» de «no
puedo verlo».

Lo delata que el mismo fichero, doce líneas antes, usa `pg_attribute` + `::regclass`, que no filtran.

> **Regla:** para catálogo, `pg_catalog` y `to_regclass`. Y que la guarda exija **en positivo** lo
> esperado: si solo comprueba que *nada incumple*, cualquier consulta vacía la pasa.

### 2.4 bis Un test de paridad no ve lo que los dos lados tienen mal igual

El builder produce los candidatos de STG y de PROD desde un solo grafo, con una tabla de
configuración por entorno, y un test acredita que **solo** difieren en lo que la tabla declara. Suena
hermético. **No lo es**, y falló tres veces el mismo día:

| Lo que no tenía fila | Consecuencia si se importa |
|---|---|
| id del `Issue Policy Guard` | la emisión de pólizas de PROD llamaría al guard de **staging** |
| `errorWorkflow` | el bot estrena 229 nodos **sin red de error** |
| URL base de Django | **7 nodos** del candidato de PROD apuntando a `hyl-wai-stg` |

El tercero es el peligroso, y explica por qué esta clase importa: el guard era un id **inexistente en
PROD**, así que habría fallado a la vista. **`hyl-wai-stg` existe, responde y tiene datos.** Un bot de
producción leyendo de ahí **no da error: da respuestas equivocadas** — el precio de una cotización de
pruebas a un cliente real, y ofertas de descuento escritas en la base de staging. **El smoke puede no
cazarlo**: el bot responde y el mensaje llega.

Lo dijo el Agente n8n en una frase que vale más que el hallazgo: *«el test del espejo no podía verlo:
los dos candidatos lo comparten»*.

> **Regla:** un test de paridad acredita **diferencias declaradas**, no corrección. Lo que no tiene
> fila en la tabla es **invisible** para la comparación, y por tanto es exactamente donde se esconden
> los errores.
>
> **Corolario operativo:** verificar por **ausencia de lo ajeno**, no por presencia de lo corregido.
> «Arreglé los 7 nodos» no prueba que no hubiera un octavo; «cero nodos del artefacto de PROD
> mencionan un host que no sea producción» sí. Y hacerlo **en espejo**: cero hosts de producción en
> el artefacto de STG, porque el cruce en esa dirección es peor.
>
> Y antes de regenerar: **inventariar qué más difiere entre entornos y no tiene columna**. Las tres
> aparecieron de una en una, tropezando.

### 2.4 ter El recurso de instancia que no estaba en mi lista — y el `403` que se imprimió como «0»

**La quinta de la clase 2.4 bis, y la que llegó a producción.** El bot de 229 nodos entró a las
02:24 y **murió en 0,6 s con el primer mensaje real**:

```
Could not find the data table: 'bIxZXnNOotosIa5q'
```

Una **Data Table de n8n** —`quote_document_deliveries`, el candado de idempotencia del envío del
documento— usada por cuatro nodos, existente en STG e inexistente en PROD. Es **recurso de
instancia**, como las credenciales, pero sin fila en la tabla de configuración.

**El fallo del inventario fue mío.** Al aprobar F4 pedí inventariar «credenciales, `phoneNumberId`,
tokens, ids de workflow, hosts». El ejecutor buscó **exactamente eso**. Enumerar categorías conocidas
es un método que solo encuentra lo que ya sospechas.

> **Regla:** la pregunta no es *qué categorías conozco*, sino **¿qué recursos viven en la INSTANCIA y
> no en el grafo?** Todos comparten firma: un **id opaco embebido en el JSON** que el espejo no
> distingue de un dato cualquiera. Y la verificación no es una lista: es un **censo con dos números
> que deben coincidir** — el ejecutor lo formuló mejor que yo: *91 nodos con referencia a recurso de
> instancia, 9 recursos distintos, 8 con fila*. «8 de 9» es falsable; «he revisado y no veo nada» no.

**Y encima medí mal el estado de partida.** Escribí en el handoff «en PROD hay 0 data tables». No lo
medí: `d.get('data', [])` sobre un `{"message":"Forbidden"}` —**HTTP 403**— devuelve lista vacía, y
mi script imprimió «0». **Es la misma trampa del §2.4, en una API en vez de en un catálogo, el mismo
día en que la escribí como convención.** Por eso la convención se reformuló: no va de
`information_schema`, va de **cualquier lectura que pueda fallar en silencio**.

**Lo que funcionó, y es lo que hay que copiar:**

- **La marcha atrás preautorizada.** El handoff decía «con el bot vivo, revierte primero y pregunta
  después». El ejecutor revirtió **sin consultar** a los 3 min 25 s, y era lo correcto: el bot moría
  con *cualquier* mensaje entrante, no solo con el del smoke.
- **La red de error, puesta media hora antes, capturó este mismo fallo.** Sin ella la ejecución
  habría muerto sin rastro.
- **Una sola ejecución afectada** en 50 minutos de ventana rota, y era la del propio smoke. Cero
  clientes reales — porque la landing seguía cerrada, que era el motivo de tenerla cerrada.
- **El smoke hizo exactamente su trabajo:** encontrar el fallo antes que un cliente. Un smoke que
  falla en el paso 1 no es un smoke fallido.

Matiz que el ejecutor corrigió y vale: **el trigger y el `webhookId` sí entregaron.** Lo que murió
fue el procesamiento aguas abajo. La superficie que más miedo daba funcionó.

### 2.4 quater «Leí la guarda» no es «tracé la ruta» — el modo `shadow` sí escribe

La noche del 23, tras la promoción, Juan encendió `QUALITAS_POLICY_RECEIPT_SYNC_MODE=shadow` en
producción. Fui a ver qué significaba, encontré esto en dos ficheros —

```
qualitas/first_receipt_confirmation.py:66              if mode != "apply":
qualitas/management/commands/process_first_receipt_fulfilment.py:86   if mode != "apply":
```

— y le dije a Alberto que **`shadow` observa y no escribe estado autoritativo**.

**Era falso.** Horas después, con el mismo modo encendido unos minutos, el ledger pasó de **0 a 36
filas** con datos reales del proveedor (`provider_receipt_id 2152784936`, `provider_status
"rechazado"`, fechas de vencimiento verdaderas), más 27 `PolicyInstallment`, 5 `PolicyPaymentSummary`
y 5 snapshots.

**Lo que sí es cierto, y es la formulación correcta:**

> `shadow` **ingiere y proyecta** — escribe sus propias tablas. Lo que **no** hace es **aplicar
> efectos** sobre el dominio de negocio. Verificado: `qualitas_polizaemitida.estatus_pago` intacto
> (52 `PENDIENTE`, 6 `PAGADO`) y `conciliacion_pagos` sin tocar (320 filas), que era la frontera que
> el `#210` declaró fuera de alcance.

Así que **no hubo daño** — pero mi afirmación no describía el sistema, y con ella dije a Alberto que
el ledger «viajaba inerte» cuando ya no lo estaba del todo.

**El error de método, que es el que se repite:** encontré **una** guarda y extrapolé su alcance a
**todo** el subsistema. Un `if mode != "apply"` acredita que *ese* camino está protegido; no dice
nada de los demás. Y el nombre del modo —«sombra»— empujaba hacia la conclusión cómoda.

> **Regla:** leer una guarda dice qué protege **esa** guarda. Para afirmar qué hace un modo completo
> hay que **trazar la ruta o medir el efecto**. Y cuando se puede medir barato —contar filas antes y
> después— **se mide**: la lectura del código es una hipótesis, el recuento es el dato.

Corolario para los planes: **«llega inerte» y «no escribe nada» son afirmaciones distintas.** Un
módulo puede llegar sin efectos de negocio y aun así empezar a poblar sus tablas desde el primer
minuto — y eso cambia qué significa «volver atrás».

### 2.4 quinquies La coincidencia que era una tautología

**24 ago, cierre del hilo de la data table.** El Agente n8n leyó por fin las filas de
`quote_document_deliveries` en PROD con una clave que sí tenía alcance, y encontró **uso real del 22
al 25 de julio**: entregas de documento con `wamid` de Meta, cotizaciones reales, hasta un `+57`.
Su informe de F4.bis decía que la tabla «apareció en la ventana de Alberto». **Preexistía un mes.**

Y traía dos preguntas razonables: *¿qué escribió esas filas?* y *¿quién creó la tabla?* Las dos
apuntaban fuera —un workflow borrado, otra mano—, porque la premisa de partida era que **el bot no
tenía nodos `dataTable`**. Medido sobre `Agente-n8n`, todas las refs, ruta `workflows/`, cadena
`Check Delivery Idempotency`:

| | |
|---|---|
| 21 jul, `0a8229ce` | `deploy(prod): entrega de cotizacion por quick reply` — primer export con los cuatro nodos |
| 26 jul | 112 nodos, los cuatro presentes |
| 27-29 jul | 113 nodos, los cuatro presentes |
| tabla `CKUcyIg4N6YqsjAl` | `createdAt 2026-07-22T03:15:09Z` — la misma tarde del deploy |

**Los escribió el propio bot.** No había nada que buscar.

Lo que hay que aprender no es el 403 —eso ya está en `2.4 ter`—, sino lo que vino después. Cuando
comparamos el esquema del mecanismo nuevo contra el de la tabla viva, **coincidía exacto**, y lo
leímos como una señal fuerte: dos diseños convergiendo. Era lo contrario. **Era la misma tabla que
nuestro propio mecanismo había creado un mes antes**, así que la coincidencia no aportaba
información: no podía haber salido de otra forma. Una comparación cuyo resultado está garantizado de
antemano se siente como una verificación y no lo es — es la misma familia que `2.4 bis`, el test de
paridad que no ve lo que los dos lados comparten.

Y la afirmación que abrió el agujero no fue «no existe»: fue **«el bot de 119 no tenía nodos
`dataTable`»** — una ausencia enunciada sin decir **contra qué instantánea** del bot se miró. El
número «119» venía de la tabla de `CLAUDE.md`; los exports de julio marcan 112 y 113. Se comparó
contra un recuento de otro sitio y se concluyó sobre un grafo que nadie abrió.

**Regla, y es la que ya teníamos aplicada a un caso nuevo:** toda afirmación de ausencia lleva su
ámbito, **y la instantánea cuenta como ámbito**. «El bot no tiene X» exige decir qué bot, de qué
fecha, leído de dónde. Sin eso no lo puede refutar nadie, y por eso sobrevivió un mes.

**Dato operativo que salió de paso, y que conviene no olvidar:** el historial de ejecuciones de n8n
en PROD **solo conserva del 23 al 24 de agosto**. Julio no se puede reconstruir por ahí. Para
auditar cualquier cosa anterior, la fuente es el git de los exports y los metadatos del recurso,
nunca las ejecuciones.

### 2.5 Dar por evidencia un metadato que no puede distinguir

Escribí «el PR lo fusionó Alberto» leyendo `mergedBy`. **Todos los agentes operan con su cuenta**, así
que ese campo no distingue quién apretó de quién ordenó.

> **Regla:** en un repo donde varios agentes comparten identidad, **git acredita el qué y el cuándo,
> nunca el quién**. Si el quién importa, se pregunta.

### 2.6 Leer «menciona» como «crea»

Un `grep -l` devuelve el fichero que **nombra** un objeto, no el que lo **hace**. Con eso declaré una
«duplicidad de autoría» que no existía y una dependencia entre fases que era de otra fase.

> **Regla:** para saber quién crea algo, buscar la sentencia (`CREATE`, `DROP`), no el nombre.

### 2.7 Marcar como bloqueante lo no medido

«**Bloquea F1**», en negrita, sobre el issue de otro, sin haber mirado si había *point-in-time
recovery*. Lo había, desde hacía cuatro días. **Juan tenía razón y yo le había contradicho en su
propio tablero.**

Trampa asociada: la app tenía **dos addons Postgres**, y el que **no** usa dice `Rollback:
Unsupported`. Mirar el equivocado «confirma» lo contrario de lo que pasa.

> **Regla:** si va a llevar la palabra «bloquea», se mide antes. Si no da tiempo, se llama
> **hipótesis**.

### 2.8 Monitores que se callan

Tres fallos distintos, el mismo día, en el mismo monitor:

1. **Ceguera silenciosa.** Al perder la credencial hacía `continue`: seguía vivo sin emitir nada,
   para siempre. Desde fuera, «no hay releases» y «no estoy mirando» **se ven igual**.
2. **No heredaba nada.** Recuperé la sesión y siguió ciego, porque el `export` no llega a un proceso
   que ya arrancó.
3. **El patrón de detección solo veía los míos.** Dije «no hay monitores vivos» con **siete**
   corriendo, porque los ajenos se llaman distinto.

> **Reglas:** la pérdida de acceso **es un evento**, no un no-evento. Un monitor que necesita
> credencial **la busca él**. Y el nombre del script no identifica al dueño: eso lo hace el `cwd`
> (`lsof -a -p <pid> -d cwd`).

### 2.9 Probar la denegación contra el sitio equivocado

Para comprobar que un token nuevo **no** podía escribir, lancé un `config:set` **contra producción**.
Lo denegó el scope. Si me hubiera equivocado de scope, habría metido una variable basura en PROD y
**reiniciado la app con clientes dentro**.

> **Regla:** una prueba de denegación se hace donde el fallo no cuesta nada. **STG existe para eso.**

### 2.9 bis Entregar un secreto sin etiqueta, y estar a punto de escribirlo en git

Dos errores encadenados, la misma noche, con la misma credencial.

**El primero: la entregué sin decir para qué era.** Había **dos** necesidades de credencial abiertas
a la vez —un token de Heroku para que el Dashboard midiera por su cuenta, y un PAT de GitHub para el
arreglo del CI— y pasé la de Heroku diciendo poco más que «aquí tienes». Alberto tenía dos huecos y
una sola credencial en la mano: acabó en `secrets.HYL_WAI_READ_TOKEN`, donde daba **401**.

Lo diagnosticó el Agente Dashboard sin ver el valor: **65 bytes**, que no es la forma de ningún PAT
—40 el clásico, ~93 el fine-grained—, y `401` en `/user`, que descarta permisos y dice «no reconozco
esta credencial». Era `HRKU-…`, un token de Heroku. **Un `401` en `/user` es de sistema equivocado;
un `404` en el repo habría sido de permisos.**

**El segundo: al responderle, pegué el token entero** en el fichero para demostrar el prefijo. **El
push protection de GitHub bloqueó el push** identificándolo como `Heroku Platform API OAuth2 Token`.
Tenía razón: para acreditar de qué sistema es, bastan el prefijo y la longitud — exactamente el
criterio que el ejecutor había aplicado al diagnosticar sin imprimir el valor. **Iba a hacer en un
fichero de git lo que él evitó hacer en un log de CI.**

> **Reglas:** una credencial se entrega con su **sistema**, su **scope**, su **id de revocación** y
> **dónde va** — y, si hay más de una en vuelo, con dónde **no** va. Nunca se escribe entera en un
> documento: prefijo y longitud identifican sin exponer.
>
> **Y la de diagnóstico, que vale para cualquier credencial:** longitud y código HTTP bastan casi
> siempre. Si `/user` da `401`, no es permisos — es que la credencial no es de ese sistema.

### 2.10 Errores de los ejecutores, y por qué importan poco

Los hubo, y los tres fueron **de diagnóstico, no de ejecución**: un `grep` que falló por mayúsculas,
una memoria desactualizada sobre una ventana ya aplicada, y atribuir a sus propias migraciones una
vista que solo consumen.

**Ninguno llegó a producción**, y por el mismo motivo en los tres casos: **pararon y preguntaron
antes de ejecutar**. Un error de diagnóstico que se publica como duda es material de trabajo; el
mismo error ejecutado en silencio es un incidente.

---

## 3. Lo que funcionó, y hay que repetir

**El ejecutor que para.** Dos veces en F1 —una vista inesperada, una guarda que abortó— y las dos
veces el motivo era real. La segunda evitó que el hueco de la capa `port-132` se descubriera en F4,
con el bot ya importado.

**La orden de arranque en commit propio.** El handoff decía «Ordenado por Alberto» en su encabezado,
escrito al redactarlo. El Agente n8n **se negó a arrancar**: su regla exige la línea en un commit
separado y observable. Tenía razón — y esa regla nació de un hallazgo mío de agosto. **El gate
disparó sobre su propio autor.**

**Verificar por `versionId`, no por número de nodos.** Dos grafos distintos pueden coincidir en
recuento. Los cinco exports de PROD se acreditaron como el mismo objeto que la instancia.

**Cerrar contando, no leyendo el informe.** F1 se dio por buena tras contar yo mismo 45 funciones, 7
vistas y **el trigger ausente** — esa última es la mitad que distingue «aplicó la opción acordada» de
«aplicó el fichero entero».

**El estado seguro por omisión.** Tres veces salió el mismo patrón y las tres se resolvió igual:
sustrato primero, capacidad después, y **el interruptor ausente** en producción. Nadie tiene que
acordarse de apagar; hay que acordarse de encender.

---

## 4. Deudas que deja esta promoción

- **`s1-conformidad` del Dashboard lleva 11 días en rojo** y nadie lo sabía: sus triggers no cubren
  las ramas donde se trabaja. Un gate que no se dispara donde se trabaja no protege.
- **La guarda de `information_schema`** de la `156/018` sigue fallando abierta (§2.4).
- **STG conserva una sobrecarga** que su propia `156/012` viene a borrar. PROD quedó más limpio que
  STG; conviene saber **por qué** antes de limpiarlo.
- **`#204` y `#205`** — con descuentos ya en producción, el followup legacy puede pisar
  conversaciones reales. No bloquean el despliegue; **bloquean reabrir la landing**.

---

## 5. Para la próxima, en cinco líneas

1. **Mide antes de escribir el plan**, no durante la ejecución. La tabla del §1 es el guion.
2. **Congela con un objeto**, no con una instrucción.
3. **Nada se llama «bloqueante» sin medición** delante.
4. **Antes de retirar algo, mide quién lo usa.** La opción conservadora puede ser la destructiva.
5. **Cierra contando**, y cuenta también lo que **no** debe existir.
