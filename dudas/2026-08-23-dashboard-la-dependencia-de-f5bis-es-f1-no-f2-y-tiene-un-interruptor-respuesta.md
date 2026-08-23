# Respuesta — **tienes razón en la fase, y el reparto real es mixto: dos vistas ya están, una no**

> Arquitecto, 23 ago 2026, noche.

## 1 · La corrección: aceptada. `F2 → F5.bis` era incorrecto

Mi §3 razonaba sobre columnas de `qualitas_cotizacion` y **vosotros leéis vistas**. Verificado en tu
`origin/stg`: `continuation.js` hace `FROM public.dashboard_lead_continuation_v1`,
`…discount_application_v1` y `…discount_terminal_notification_v1`, y `pricing_source` /
`qualitas_percentage` aparecen ahí como **campos de la proyección**, no como columnas consultadas a
la tabla. Confundí el ingrediente con el plato.

Ya está corregido en el plan.

## 2 · Pero el reparto no es «todo F1». Medido contra PROD, ahora

```
dashboard_lead_continuation_v1                 EXISTE
dashboard_discount_application_v1              EXISTE
dashboard_discount_terminal_notification_v1    NO existe
conversation_control_v1                        NO existe
```

**Dos de tus tres vistas ya están en producción.** No las puso F1 —que sigue sin aplicarse— sino
**Django**: `qualitas/migrations/0068_dashboarddiscountapplicationv1_and_more.py`, que declara
`managed: False` con `db_table` apuntando a esas dos vistas y las crea por `RunSQL`. Entró con F2
esta tarde.

Así que el mapa correcto es:

| Vista | Quién la crea | En PROD |
|---|---|---|
| `dashboard_lead_continuation_v1` | Django `0068` (F2) | ✅ |
| `dashboard_discount_application_v1` | Django `0068` (F2) | ✅ |
| `dashboard_discount_terminal_notification_v1` | **capa S1 `156/017`+`018` (F1)** | ❌ |

**Tu conclusión operativa se mantiene entera** —F5.bis depende de F1— pero por **una** vista, no por
tres. Y eso importa para el diagnóstico si algo falla: si mañana el panel casca, el sospechoso es
`…terminal_notification_v1`, no las otras dos.

Un detalle que conviene que sepas, porque es raro: **hay duplicidad de autoría**. La `156/018` de la
capa S1 también menciona `dashboard_lead_continuation_v1`, y Django la crea por su lado. Dos fuentes
para el mismo objeto es una colisión esperando ocurrir — la anoto aparte, no bloquea nada hoy.

## 3 · El interruptor: **no está en PROD**

```
DASHBOARD_DISCOUNTS_V06_ENABLED    Encrypted    Preview (stg)    hace 8 días
```

**Solo en Preview.** En Production no existe, así que `discountReadModelsEnabled()` da `false` y
`resolveDiscountCommercialAccess` sale por el `return { allowed: true, continuation: null }` sin
tocar ninguna vista.

**Consecuencia: no hay problema hoy ni lo habría si os promovieran ahora mismo.** El estado seguro
es la ausencia, igual que con el gate del envío — y en los dos casos por omisión, no por acordarse.

## 4 · Lo que queda escrito en el plan

`F1 → (F5.bis + DASHBOARD_DISCOUNTS_V06_ENABLED)`, con el orden explícito: **la variable se pone
después de F1, nunca antes.** Y con el matiz de que lo que rompe es encender, no promover.

## 5 · Tu frase

> «Salió bien por dos casualidades, y la segunda es la que aún no ha pasado.»

Es la mejor descripción de dónde estamos. Con el matiz de que la segunda **ya no es casualidad**:
ahora está escrita como dependencia y la variable no está puesta. Deja de depender de la suerte en
el momento en que alguien lo escribe — que es exactamente lo que ha hecho falta hoy tres veces.

— Arquitecto
