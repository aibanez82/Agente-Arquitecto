# El alcance de una cotización: coberturas, deducible y vigencia

> **Qué es esto:** cómo se leen los campos de `QUOTE-SCOPE-CONTEXT v1.0.0` (`HYL-WAI#194`) y las dos
> cosas que el contrato **deliberadamente no dice** y hay que resolver antes de enseñárselas a un
> cliente. Creado el 2 sep 2026.

---

## 1 · Qué entrega el contrato

Django expone, **de forma aditiva**, dos bloques nuevos por cada opción de `opciones_cotizacion[]` en
`POST /api/cotizacion/detalle/`. Fuente: el XML ya persistido de cada hoja
(`qualitas_cotizacionrespuestaxml`), **no** una llamada nueva a Quálitas.

| Campo | Contenido |
|---|---|
| `vigencia.fecha_inicio` · `vigencia.fecha_termino` | `YYYY-MM-DD` o `null` |
| `coberturas_detalle[].no_cobertura` | Código numérico (catálogo `coberturas.csv`) |
| `coberturas_detalle[].cobertura` | Nombre; `null` si el código no está en catálogo |
| `coberturas_detalle[].suma_asegurada` | Decimal canónico como string, o `null` |
| `coberturas_detalle[].tipo_suma` | Código; `null` si inválido |
| `coberturas_detalle[].tipo_suma_descripcion` | Solo para `0`/`1`/`3`; **`null` en todo lo demás** |
| `coberturas_detalle[].deducible` | Decimal canónico como string, o `null` |

**Con `optimizeResponse=true` y `dataField=data`, n8n ve `opciones_cotizacion` en el top-level, NO bajo
`data.*`.**

**`"0"` no es `null`:** un cero real (deducible 0 en RC) es un valor, no una ausencia. XML ausente,
inválido o con error de proveedor conserva la opción legacy pero entrega fechas `null` y
`coberturas_detalle: []`.

## 2 · El deducible es un PORCENTAJE (Alberto, 2 sep 2026)

**El contrato declara `deducible` neutral a propósito** —el XML de Quálitas no dice la unidad, e
inferirla en el productor sería inventar—. La unidad la resuelve el consumidor, y es esta:

> **El deducible viene en porcentaje.**

Dos fuentes independientes que concuerdan:

- **Alberto, 2 sep 2026**, que es accountable del producto.
- **Medición propia en PROD el 2 sep 2026** (`qualitas_cotizacionrespuestaxml`, 440 bloques
  `<Coberturas>` de las 40 filas más recientes de `xml_amplia_anual` y otras 40 de
  `xml_limitada_anual`/`xml_amplia_mensual`): Daños Materiales `0005` y Robo Total `00010` **sobre una
  suma asegurada de 356.400**. Cinco y diez pesos sobre un coche de 356.400 no son un deducible.

Valores observados, estables en las 80 cotizaciones:

| `no_cobertura` | Cobertura | `deducible` | Lectura |
|---|---|---|---|
| 1 | Daños Materiales | `0005` | 5 % |
| 3 | Robo Total | `00010` | 10 % |
| 4 | Responsabilidad Civil | `0000` | sin deducible |
| 5 | Gastos Médicos | `0` | sin deducible |
| 7 | Gastos Legales | `0` | sin deducible |
| 14 | Asistencia Vial | `0` | sin deducible |

*(La hoja `limitada` no trae la cobertura 1 — es la diferencia con `amplia`.)*

**Por qué importa decirlo así:** «tu deducible es 5» no responde nada, y «5 pesos» es falso. La
respuesta útil para el cliente es **el importe**: `suma_asegurada × deducible / 100`. Con los números
de arriba, 5 % sobre 356.400 son **17.820 pesos**.

> **ACREDITADO (Alberto, 2 sep 2026): la base es la suma asegurada del vehículo** — valor comercial o
> valor convenido según la póliza—, que es exactamente el campo `suma_asegurada` de esa cobertura.
>
> **El cálculo queda cerrado:** `deducible en pesos = suma_asegurada × porcentaje / 100`.
> Con datos reales: 31.500 × 5% = **1.575** en Daños Materiales; × 10% = **3.150** en Robo Total.
>
> **Y esto NO depende de resolver el `tipo_suma = 2`**: ese código solo impide *nombrar* el tipo de
> valor; la cifra es la misma se llame como se llame. La pregunta del `2` sigue abierta con Juan,
> pero **no bloquea decir el importe**.
>
> **Aviso de la documentación oficial:** en **Responsabilidad Civil el deducible puede venir en DÍAS,
> no en porcentaje** («ya sea en porcentaje o en días, para el caso de RC»). Hoy nuestras cotizaciones
> traen RC con deducible `0`, así que no aplica — pero si algún día no lo es, leerlo como porcentaje
> sería un error de la familia del «25%».
>
> **Y no es una constante del producto: es un parámetro comercial.** La doc dice que está limitado
> del lado de SISE y que mover­lo «deberá contar con autorización». Por eso el 5% y el 10% **no van
> escritos en ningún prompt**, por muy constantes que los hayamos medido en 1.322 cotizaciones.

## 3 · `tipo_suma` vale `2` y el catálogo no lo tiene

**En el 100% de lo medido** (440/440 bloques) `TipoSuma` es `2`. El catálogo autoritativo
`HYL-WAI:docs/qualitas-documentacion-webservices/catalogs/tipo_suma.csv` solo define:

```
0 = Valor convenido · 1 = Valor factura · 3 = Valor comercial
```

El contrato hace lo correcto ante un código desconocido —conserva `tipo_suma`, pone
`tipo_suma_descripcion: null`— así que **ese campo llegará vacío en todas las cotizaciones reales**.
El contrato no falla; el catálogo no cubre el único valor que producción usa.

**Qué significa el `2` no está acreditado.** La sospecha razonable es «valor comercial ajustado» —es
lo que el bot ya le dice al cliente junto a «valor factura»— pero **es una sospecha, no un hecho**.
Preguntado a Juan en el `#194`.

**Consecuencia operativa:** el consumidor puede decir **cuánto** cubre cada cobertura, pero **no puede
nombrar el tipo de valor** hasta que el `2` esté resuelto.

## 4 · El hueco que esto cierra, medido

En el histórico de PROD (`n8n_chat_histories`, medido 2 sep 2026): **93 preguntas de clientes** sobre
coberturas, deducible, suma asegurada o vigencia, en **73 de 361 sesiones con mensaje humano** — una de
cada cinco conversaciones.

El muro, literal:

> **Cliente:** «¿cuál es el deducible de la amplia?»
> **Bot:** «No conozco esta respuesta, pero si lo deseas, puedes ponerte en contacto por WhatsApp con
> un agente especializado…»

Una derivación a persona **en el momento exacto de la intención de compra**.

**Lo que ya funciona hoy y no hay que tocar:** «¿qué suma asegurada tiene el coche?» se responde bien
(«$422.000 valor factura y $249.000 valor comercial ajustado»). El valor del vehículo ya está; **lo que
falta es el detalle por cobertura**.

## 5 · Estado

**No hay slice consumidor autorizado.** `HYL-WAI#194` entrega el productor y un handoff
**informativo**; el trabajo de n8n necesita su propia autorización y su propio tracker.

Cuando llegue, tres exigencias que salen de aquí: leer los paths **top-level** reales; **no inferir**
sobre `null`/`[]`/códigos desconocidos; y **no decir un deducible sin unidad**.


---

# Anexo — Qué preguntan los clientes, qué contestamos hoy, y el plan

> Medido en `n8n_chat_histories` de PROD el **2 sep 2026**. Encargo de Alberto.

## A · El caso que cambia la prioridad

> **Cliente:** «Y por ese rubro yo pago el 5% de deducible?»
> **Bot:** «El deducible en **Daños Materiales es del 25%**, no 5%.»

**El cliente tenía razón y el bot le corrigió con un número falso.** Verificado contra el XML de **su
propia cotización** (`cotizacion_id` 2980): Daños Materiales al **5%** sobre suma asegurada
**216.900** → deducible real **10.845 pesos**; el bot le dijo **54.225**.

Dos turnos después se contradijo: *«Si dice 5% en tu cotización, ese es el deducible que tendrías»*.

**Origen:** el `25%` es correcto **para Robo Parcial**. Sin el dato de esa cotización, el modelo buscó
en la base de conocimiento y trajo el porcentaje más cercano.

**Esto no es un hueco de cobertura informativa. Es el bot inventando un producto peor que el que
vendemos, en el momento de decidir la compra.**

## B · El volumen

| | |
|---|---|
| Mensajes que tocan coberturas/deducible/suma/vigencia | **126** |
| De ellos, preguntas reales (excluye elegir paquete) | **106** |
| Sesiones afectadas | **84 de 361** — una de cada cuatro |
| Respuestas que son un muro | **11** |
| De esos muros, resueltos por el dato del `#194` | **4** |

Reparto de las preguntas reales: **16** «qué coberturas trae» · **8** deducible · **3** suma asegurada
· **3** comparar opciones · **2** vigencia · **74** mencionan cobertura sin preguntar por su alcance.

## C · El hallazgo que simplifica el plan

**El deducible es CONSTANTE en toda la historia de producción.** Medido sobre **7.932 bloques
`<Coberturas>` de 1.322 cotizaciones** (todas las que tienen `xml_amplia_anual` en PROD), **sin una
sola excepción**:

| Cobertura | Deducible |
|---|---|
| Daños Materiales | **5 %** |
| Robo Total | **10 %** |
| Resp. Civil · Gastos Médicos · Gastos Legales · Asistencia Vial | **0** |

**Consecuencia: el porcentaje se puede decir bien HOY**, sin esperar a nadie. Lo que sí exige el
`#194` es el **importe en pesos**, porque la suma asegurada cambia con cada vehículo.

> **Aviso:** constante **hasta hoy** no es constante **por contrato**. Es la configuración del paquete
> Quálitas del negocio 8545; si el negocio cambia de paquete, cambia. Por eso la fase 1 es un parche y
> la fase 2 lee el dato de cada cotización.

## D · Plan de desarrollo en n8n

### Fase 1 — Parar la mentira. **Hoy, sin depender de Juan**

Corregir la base de conocimiento para que el `25%` no pueda volver a aplicarse a Daños Materiales:
el 25% es **de Robo Parcial**, y el de Daños Materiales es 5% y el de Robo Total 10%.

**Coste:** un cambio de copy en la base de conocimiento. **Cero riesgo de arquitectura.**
**Qué compra:** que el bot deje de dar una cifra cinco veces peor que la real.

### Fase 2 — Que el bot mire la cotización antes que el manual

Requiere que **Juan despliegue el productor del `#194`**, hoy en `feature/issue-194-quote-scope-context`
y **en ningún entorno**.

1. **No hay endpoint nuevo ni nodo nuevo.** `Get Quotation Data` ya llama a
   `POST /api/cotizacion/detalle/`; con el `#194` desplegado, **la misma llamada devuelve los campos
   nuevos**. Lo que hay que tocar es la **descripción de la herramienta**, para que el modelo sepa que
   existen y qué significan.
2. **Regla de prioridad en el prompt:** ante una pregunta sobre el alcance de **esta** póliza
   —deducible, suma asegurada, qué cubre, vigencia—, **la fuente es la cotización; la base de
   conocimiento no**. Hoy es al revés de hecho, y de ahí salió el 25%.
3. **Antes de promover, llamar al endpoint en el entorno de destino.** `401` tipado en JSON = vivo;
   `500` con HTML = la ruta no existe. Es la lección de §2.18 del manual y nos costó una reversión.

### Fase 3 — Carril determinista para las tres preguntas de siempre

Las tres más repetidas **tienen una sola respuesta correcta**, y acabamos de ver al modelo contradecir
a un cliente que acertaba. **Una pregunta con una sola respuesta correcta no se le pregunta a un
modelo** — es el patrón del `#254` y del `#275f`.

Colgar del `Intent Router`, que ya tiene destinos deterministas:

| Pregunta | Respuesta |
|---|---|
| ¿Cuál es el deducible? | Por cobertura, en **pesos** y con el % al lado |
| ¿Qué coberturas trae? | La lista real de **esa** cotización, con su suma asegurada |
| ¿Las opciones traen las mismas coberturas? | Comparación entre las opciones cotizadas |

**Guarda:** solo dispara si la cotización trae `coberturas_detalle` no vacío. Sin dato, el turno sigue
al modelo — igual que en el `#275f`.

**Y el importe en pesos exige acreditar la base del porcentaje** (§2). Hasta entonces, el carril dice
el porcentaje, que ya es correcto.

### Lo que NO entra

- **Nombrar el tipo de valor** («valor factura», «valor comercial»): `tipo_suma` llega como `2` y no
  está en catálogo. Pendiente de Juan.
- **Coberturas opcionales no cotizadas** (llantas, auto sustituto, deducible cero): no vienen en el
  XML de la cotización. Eso es venta, no dato.
