# Informe — `#296`: el fallo que el cliente ve deja de ser invisible, y además avisa

**Handoff:** `Dashboard_SeguroAuto:handoffs/2026-09-03-296-el-fallo-que-el-cliente-ve-y-nosotros-no.md` · Issue `HYL-WAI#296`
**Ejecutor:** Agente Dashboard · 2 sep 2026

**Entrega:** PR `aibanez82/Dashboard_seguroautoqualitas#13` → `stg`, **abierto y sin mergear**.
Va por PR porque añade el campo `ledger` a la respuesta de `/api/conversation`, que es contrato.
Suite **328/328** (23 pruebas nuevas). **No toco el 400**: es el `#297` y va por n8n.

## Tu criterio

> *«Que hubieras podido enterarte del caso del 2 de septiembre sin la captura de Alberto.»*

Probado de punta a punta contra un servidor de pruebas con la forma real de la respuesta. Sale solo:

```
FALLO INVISIBLE — agente · 2026-09-02 14:37:16 CDMX · lead 963 · cotizacion 2316 · waq_2316_76c8e149a2fc · s1.agenterr.a40c3165
FALLO INVISIBLE — agente · 2026-09-02 14:38:04 CDMX · lead 963 · cotizacion 2316 · waq_2316_76c8e149a2fc · s1.agenterr.811bf208
```

Las dos horas de la captura, y con **a quién** — tu condición 1.

## Las dos mitades

**Que se vea:** la incidencia aparece en el timeline del modal, en su sitio cronológico, como franja
y no como burbuja (no es un mensaje de nadie, es un hecho sobre el envío). Con **etiqueta nuestra**:
no se reproduce la copy de n8n, porque copiarla la vuelve contrato de hecho — el mismo acoplamiento
del que huimos con los detectores por `LIKE`.

**Que avise:** `scripts/monitor-fallos-invisibles.sh` sondea `/api/alertas/fallos-invisibles`. **No
habla con Postgres a propósito**: el acceso directo queda en **un único origen**
(`lib/s1/ledgerErrores.js`), el mismo que alimenta el timeline. Un monitor con su propia conexión
sería un segundo punto de acoplamiento y otra credencial repartida — tu §5.

## Un cero por no haber podido mirar no es un cero

Tu propia moraleja, implementada en tres sitios: `leido`/`motivo` viajan en las dos respuestas; el
endpoint da **503** y no 200-con-lista-vacía si no puede leer; y el monitor **canta** cuando el
ledger no se deja leer, en vez de quedarse mudo.

## Tres formas de fallo, no una

`agente` (prefijo `s1.agenterr.`), `entrega` (`outcome` en `failed`/`uncertain`) y `sin_liquidar`
(reservado y nunca liquidado, con **5 min de gracia** para no confundir un envío en vuelo con un
fallo). Es el mismo defecto de invisibilidad en la misma tabla.

## Lo medido, que corrige el issue

| | issue | medido contra el ledger |
|---|---|---|
| 2 sep | 2 | **5** — 14:37, 14:38, 14:48, 14:49, 14:50 CDMX |
| total STG | 5 | **8** |

Los tres que faltaban son **posteriores a tu medición**: seguía pasando mientras escribías. Y los
cinco son del **mismo lead 963 / cotización 2316** — un cliente que lo intentó cinco veces.

## Riesgo conocido, y deuda

- **`s1.agenterr.` es una convención de nombre, no un campo. Si n8n la cambia, dejamos de ver esa
  clase EN SILENCIO — el fallo que acabamos de hacer visible se volvería invisible otra vez.** La
  mitigación (`por_clase`) lo delata pero no avisa sola; la solución es tipificarlo en el ledger.
- **+2 consultas directas** sobre la línea base de 27 → **29**. `DSC_` pedido y aceptado por ti.
- **Sin verificar en PROD.** Ver abajo.

## Lo que no pude hacer, y por qué no es un `GRANT`

Intenté comprobar en PROD si `n8n_outbound_dispatch` existe y si nuestro rol tiene `SELECT`. **Me lo
bloqueó el clasificador de permisos de mi propia sesión**, no la base de datos: nunca llegué a
conectar, así que **no hay evidencia de que falte ningún `GRANT`** y esto **no** es de la familia del
`#284` mientras no se mida. Lo he escalado a Alberto, que es quien puede autorizarlo. **No te pido
que lo corras tú**: sería saltarme por otra sesión una decisión de permisos de la mía.

**No promover a PROD sin esa verificación.**

— Agente Dashboard
