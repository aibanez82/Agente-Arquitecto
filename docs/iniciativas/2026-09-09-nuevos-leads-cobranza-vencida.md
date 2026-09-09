# Nuevos Leads — Cobranza Vencida · diseño v1

> Arquitecto-IA-Qualitas · 9 sep 2026 · **Encargo de Alberto**, decisiones suyas marcadas como tales.
> Estado: **diseño para validar.** No hay nada implementado.

> **El nombre importa y lo eligió Alberto.** Esto **no es rescatar una póliza**: la póliza cancelada
> no se recupera ni se rehabilita. Es **captación de leads nuevos** — gente que ya demostró que
> compra seguro de auto y que ahora está sin cobertura. La cobranza vencida es **el origen del
> lead**, no el objeto del trabajo. Quien lo lea como «recuperar cartera» diseñará mal.

## 1. Qué es

Hylant nos envía **mensualmente** una Excel con pólizas que su contact center **Metepec** emitió y que se han **cancelado por falta de pago**. La cobranza vencida **no se rehabilita** — decisión de Alberto: *«no rehabilitar, esto es muy complejo»*—: se le **vende una póliza nueva**, que es negocio nuestro y entra como lead propio.

El flujo: importar la Excel desde el Dashboard → ver los recibos vencidos → seleccionar → enviar un aviso por WhatsApp → **el cliente entra como lead en el bot de cotización que ya existe**, igual que si viniera de la landing.

## 2. La Excel, medida (agosto 2026)

**644 filas, 18 columnas, una hoja.** No es una estimación: está medido sobre el fichero real.

| Dato | Estado |
|---|---|
| **`NUMERO SERIE` (VIN)** | **628 de 644 con 17 caracteres**, 625 únicos |
| `TELEFONO` | **612** de 10 dígitos · 2 vacíos o `0` · 30 con formato raro |
| `CORREO` | 565 válidos · 79 sin correo |
| `PRIMA TOTAL` | 627 negativas (cancelación) · **17 positivas** |
| Personas con varias pólizas | 11 |
| **Código postal** | **NO existe columna** |
| Marca / modelo / versión | **NO existen columnas** |

**Agentes:** `88200` (370), `88199` (180), `88201` (66), **`27614` (25 — el nuestro)**, `27613` (3).
**Coberturas:** AMPLIA 534 · LIMITADA 96 · RC 14. **Forma de pago:** `C` en las 644.

### Lo que estos números deciden

- **El VIN resuelve el vehículo.** Da marca y año de forma determinista, sin preguntar nada. Es el dato que hacía falta.
- **El CP hay que preguntarlo.** No viene, y es obligatorio para cotizar. **Decisión de Alberto: se pregunta en la conversación.**
- **619 de 644 pólizas son de otros agentes.** Aunque existiera un servicio de consulta en Quálitas —y **no está documentado**: el único método documentado es `obtenerNuevaEmision`— nuestras credenciales van con el agente `27614` y no cubrirían pólizas ajenas. **Por eso el CP no se puede traer de Quálitas.**
- **Las 17 filas con prima positiva se apartan.** No son cancelaciones; podrían ser rehabilitaciones. Escribirle «su póliza está cancelada» a quien la rehabilitó es quedar mal con un dato que teníamos.
- **Las 25 pólizas de nuestro agente merecen mirarse aparte**: conviene comprobar si alguna se canceló por el defecto del `#329`.

## 3. El canal

**Decisión de Alberto: número nuevo, misma cuenta de Meta.** Descartado Twilio.

### Por qué importa la cuenta

Meta entrega los webhooks **por cuenta, no por número**. Así que los mensajes al número nuevo **sí llegan al bot actual** — y hoy **se descartan en silencio**, porque `Phone Number ID Guard` compara contra una constante:

```
metadata.phone_number_id == "1028815256982638"
```

Un cliente que responda al aviso no recibiría **nada**. Ese es el defecto que hay que corregir antes de enviar el primer mensaje.

### El cambio, que son dos nodos

1. **`Phone Number ID Guard`** acepta los dos números en vez de uno.
2. **`WA Config`** deja de escribir el número a mano y lo toma del mensaje entrante.

**Verificado contra ejecuciones reales**: cada mensaje trae `metadata.phone_number_id`, y `WA Config` ya lo tiene delante — hoy lo ignora. Como **los seis nodos de envío leen de `WA Config`**, el bot pasaría a contestar **desde el número por el que le hablaron**, sin tocarlos.

Con eso se cumple el encargo de Alberto: **no hay flujo nuevo en n8n**. El agente IA que responde dudas de póliza es el mismo.

### Riesgo declarado

El aislamiento es **parcial**. La calificación de calidad es por número, así que quemar el nuevo no tumba el principal — pero **las sanciones graves por spam son de cuenta**, y la cuenta es la misma. 644 mensajes al mes a gente que no los espera es exactamente el perfil que Meta penaliza.

**Por eso el registro de «no contactar» (`#356`) deja de ser higiene y pasa a ser protección del canal que da de comer.**

## 4. El descuento

**Decisión de Alberto: 40 % de salida, y no ofrecer más.**

No hay que crear nada: **`POR_VIN_40`** ya existe, está `active` desde el 27 ago, da 40 % y **exige VIN** — que es justo lo que la Excel trae.

**Un ajuste pendiente:** hoy está marcado `available_for_phase_2_intent = true` y `available_for_phase_1_checkpoint = false`, o sea disponible cuando el cliente objeta precio, no de salida. Para ofrecerlo desde el primer mensaje hay que habilitarlo en fase 1 o que el flujo marque el lead. **Es configuración, no código.**

## 5. Qué hay que construir

### Django (HYL-WAI — es de Juan)

Tres tablas, separando el lote importado del estado del contacto, para que la Excel de un mes no pise el historial del anterior:

- **`lead_cobranza_import`** — un lote por Excel: periodo, fichero, quién y cuándo, filas leídas, filas descartadas y por qué.
- **`lead_cobranza_row`** — una fila por póliza: los 18 campos originales **sin transformar**, más los derivados (teléfono canonicalizado, VIN validado, marca y año deducidos) y el motivo de exclusión si lo hay.
- **`lead_cobranza_contacto`** — un registro por intento de contacto: a quién, cuándo, con qué plantilla, resultado del envío y respuesta.

Más una **API de lectura** para el Dashboard y un **endpoint de envío** que el botón dispare.

### Dashboard

Sección **solo `admin`** —la lista blanca de roles ya existe y `agente` no la vería—, con: subida de la Excel, vista de filas con su estado, selección individual o total, y botón de envío.

### n8n

**Los dos nodos del §3.** Nada más.

## 5.bis. La Excel nos devuelve nuestros propios fallos y nuestras propias pruebas

**Esto no lo vi al escribir la v1 y lo cambia todo en la lista de exclusiones.** La Excel trae **25 pólizas de nuestro agente `27614`**, así que **nuestras cancelaciones vuelven a nosotros dentro del fichero de Hylant**.

Medido en PROD hoy: de **61 pólizas emitidas por nosotros, 36 siguen `PENDIENTE`** — nunca se pagaron. Todas ellas son candidatas a aparecer en la Excel del mes siguiente cuando Quálitas las cancele. Y entre esas 36 hay dos clases que **no pueden recibir el mensaje**:

**1 · Gente a la que prometimos no molestar.** La póliza `7620101920` es la de **Armando Lobo**: pidió su liga de pago dos veces, el sistema le falló las dos (`#329`), canceló, y le respondimos por escrito *«no tiene que hacer nada más»*. **Venderle una póliza nueva no es menos incómodo que ofrecerle rescatar la vieja: es escribirle igual, después de prometerle que no lo haríamos.** El reencuadre de la iniciativa no suaviza esto en absoluto.

**2 · Nuestras propias pruebas.** De las 36 pendientes, **14 son internas — el 39 %** (lista completa y medida en la sección siguiente). **Si la campaña sale a ciegas, nos escribimos a nosotros mismos, a Juan y a los probadores de Hylant.**

### Decisiones de Alberto sobre esto (9 sep)

**1 · Armando Lobo recibe el mensaje.** Palabras suyas: *«es un daño colateral. Por un lead no pasa nada. Es más costoso armar una lógica para estos casos.»* **Queda decidido y así se implementa.**

Dejo constancia de una precisión que le di y que no cambia la decisión: **esa lógica hay que construirla igual**, porque el propio flujo genera bajas —quien responda «no, gracias» no puede recibir el mes siguiente— y honrar además las bajas anteriores es **la misma tabla**, no una nueva. El `#356` sigue en pie por esa razón, no por este caso.

**2 · Las pólizas internas se marcan y NO se envían.** El Dashboard debe resaltarlas.

### El registro de internos — declarado por Alberto (9 sep)

**No se deduce, se declara.** Alberto entregó la lista completa; yo la crucé con PROD para sacar los teléfonos, que es lo que de verdad atrapa las variantes.

| Correo | Teléfonos vistos | Cotiz. | Pólizas | **Pendientes** |
|---|---|---|---|---|
| `juan.aguayo@aguayo.co` | 3107696237, 5149843762, 5555550101 | 42 | 3 | **3** |
| `test@test.com` | 5551074144 | 42 | 3 | **3** |
| `acer3500@gmail.com` | 5551074143/44/848/896 | 10 | 3 | **3** |
| `alescamillar@gmail.com` | 5525592446 | 9 | 2 | **2** |
| `rarefe@hotmail.com` | 5518859302 | 30 | 1 | **1** |
| `alberto@insurmind.ai` | 5554022064 | 1 | 1 | **1** |
| `qa+prod-20260727@example.com` | 0000000000 | 1 | 1 | **1** |
| `oilycoyote@hotmail.com` | 3107696237 | 5 | 0 | 0 |
| `juaguayo@yahoo.com` | 3107696237 | 3 | 0 | 0 |
| `marketinghylant@e-broking.com` | 5577150462 | 3 | 0 | 0 |
| `juaguayo@gmail.com` | 3107696237 | 1 | 0 | 0 |
| `acer3500@gmail.co` | 5551074144 | 1 | 0 | 0 |
| `jandersongomezfranco@gmail.com` | 3336424341 | 1 | 0 | 0 |
| `hector.silvar@yahoo.com.mx` | 7771082776 | 1 | 0 | 0 |

**Catorce de las 36 pólizas pendientes son internas — el 39 %.** *(En una versión anterior de este documento dije «ocho». Era mi cuenta antes de tener la lista de Alberto; el número bueno es 14.)*

### Por qué el registro necesita teléfono y no solo correo

Dos identificadores lo demuestran:

- **`3107696237`** aparece con **cuatro correos distintos** (`juan.aguayo@aguayo.co`, `oilycoyote@hotmail.com`, `juaguayo@yahoo.com`, `juaguayo@gmail.com`).
- **`5551074144`** con tres (`test@test.com`, `acer3500@gmail.com` y `acer3500@gmail.co`, este último con el dominio mal escrito).

La Excel trae correo **y** teléfono, y no hay garantía de que el par coincida con el que tenemos. **Cruzar por los dos, y excluir si casa cualquiera de ellos.**

Y `acer3500@gmail.co` —un `.com` sin la `m`— es el aviso de que **la coincidencia debe ser exacta y la lista debe poder crecer**: nadie va a acertar todas las variantes de entrada.

## 6. Lo que hay que decidir antes de implementar

1. **El registro de «no contactar» (`#356`)** — Alberto decidió que no bloquea el arranque (ver §5.bis), pero **el flujo lo necesita para sus propias bajas**: quien conteste «no, gracias» no puede recibir el mes siguiente. Sigue siendo trabajo obligatorio, con otra justificación.
2. **Las 17 filas de prima positiva** — preguntar a Hylant antes de escribirles.
3. **La plantilla de Meta** — hay que darla de alta y aprobarla. Meta es de Juan.
4. **Pedirle a Hylant el CP en la Excel del mes que viene.** Es gratis preguntar y convertiría el flujo en cero preguntas.
5. **Qué le decimos a quien pregunte por su póliza vieja.** Es de Metepec: no vemos sus recibos ni podemos decirle cuánto debía. Hay que decidir si derivamos o contamos lo que trae la Excel.

## 7. Lo que este diseño NO resuelve

**La emisión necesita más que el CP.** Con VIN y CP se **cotiza**; para **emitir** hacen falta nombre completo, RFC, fecha de nacimiento y domicilio. La Excel trae el nombre; el resto lo pide el bot en su conversación de emisión, que ya existe.

Así que el ahorro real es: **el vehículo y el descuento**, que es la parte difícil. No es «cero preguntas».

Agente: Arquitecto-IA-Qualitas
