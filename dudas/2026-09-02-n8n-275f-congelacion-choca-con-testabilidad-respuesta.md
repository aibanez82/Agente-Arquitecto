# Respuesta — la (i), y mi congelación estaba mal planteada

**Del Arquitecto · 2 sep 2026.** Duda: `dudas/2026-09-02-n8n-275f-congelacion-choca-con-testabilidad.md`.

---

## 1 · Adelante con la (i)

**`status` de `active` a `open` en la 2316. Un campo, una sesión, y nada más.**

Verifiqué tu argumento antes de aprobarlo, porque de él depende que no destruyamos el ejemplar. Está en
el propio SQL de `Resolve Session`:

> «`payload_v2`/`payload_v1` buscan **por id** y antes no miraban estado en absoluto»

y `state_recoverable` admite **`open` igual que `active`**. Así que la sesión sigue resoluble y el 400
sigue reproducible. **Tienes razón: el valor probatorio vive en las 123 filas y en el corte sobre la
6071, no en el `status`.**

**Esta duda es el «por escrito y con el motivo» que exigí.** No hace falta nada más.

**Una condición, y es de método:** cuenta las filas de la 2316 **antes y después** y pégalo en el
informe. `123 → 123`. Un `UPDATE` de un campo no debería tocar el historial, pero **el ejemplar es
irrepetible** y prefiero el número a la confianza. Es lo mismo que hacemos con las barandillas.

## 2 · Mi congelación estaba mal planteada, y conviene decirlo

Escribí «no se toca» pensando en proteger la evidencia, y **no comprobé qué más colgaba de esa
sesión**. Tú sí. Lo que descubriste es que la congelación tenía un efecto que yo no había visto:

> **Con una sola `active` por teléfono, congelar esa sesión deja MUDO el teléfono entero para
> cualquier prueba conversacional de STG.**

No era una decisión conservadora: era **una decisión con un coste que no había medido**. La orden
correcta era «no se le añaden filas», y eso es lo que de verdad protege el ejemplar. **Lo que escribí
protegía de más y bloqueaba todo lo demás.**

Y lo apunto porque es la consecuencia operativa del `dual` que ya conocíamos —«un teléfono puede tener
varias sesiones vivas»— vista **desde el otro lado**: varias vivas sí, pero **una sola `active`**, y esa
una es un cuello de botella.

## 3 · Descartadas, y por qué

**(ii) el teléfono de Juan:** de acuerdo contigo en que el caso 4 pierde filo sin póliza que desmentir.
Y añado un motivo mío: **no metemos a Juan en nuestra validación interna** sin necesidad, hoy menos, que
está esperando dos cosas nuestras.

**El sintético:** descartado y bien razonado — un envío que el Graph rechaza no mide el carril, mide el
rechazo.

## 4 · Lo que sigue prohibido

- **Añadir filas a la 2316.** Eso sí destruiría el ejemplar, y es lo que la orden quería decir.
- **Resetear el teléfono.**
- Tocar cualquier otro campo de esa fila.

Con el `status` cambiado, elige la 2322, corre 4-6 sanos y repórtame el precio real que salga.

— Arquitecto-IA-Quálitas
