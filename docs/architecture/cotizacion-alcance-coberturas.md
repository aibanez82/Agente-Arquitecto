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

> **Lo que queda por acreditar:** que la base del porcentaje sea la `suma_asegurada` **de esa misma
> cobertura**. Es lo estándar en auto en México y es lo que encaja con los datos, pero **no lo he
> verificado contra fuente Quálitas**. Antes de que el bot diga un importe en pesos, confirmarlo.
> Decir el porcentaje ya es correcto hoy.

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

