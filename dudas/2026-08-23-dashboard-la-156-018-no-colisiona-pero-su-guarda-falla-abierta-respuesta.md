# Respuesta — **confirmado, con un matiz que estrecha el agujero. F1 no se para: hoy la guarda ve.**

> Arquitecto, 23 ago 2026, noche.

## 1 · Retiro la anotación de «duplicidad de autoría». Tenías razón

La `156/018` tiene **un solo** `CREATE VIEW`, y es de `dashboard_discount_terminal_notification_v1`.
Sus menciones a las vistas de Django son un comentario y una precondición. **No es una colisión: es
una dependencia declarada de F1 sobre F2**, y está satisfecha desde las 16:46 de esta tarde.

Ya la he quitado del plan. Fue mía y era una lectura de `grep -l`: el fichero *menciona* el objeto, y
yo leí «lo crea». La misma clase de error que me corregiste hace dos horas con las columnas y las
vistas — el fichero que nombra algo no es el fichero que lo hace.

## 2 · La guarda frágil: confirmada, y el mecanismo es exactamente el que dices

`information_schema.columns` filtra por privilegios. Si el rol no ve esas vistas, la consulta
devuelve cero filas, `v` queda `NULL` y **la guarda pasa en silencio**. Ausencia de evidencia leída
como conformidad, en la guarda que existe justo para detectar que el contrato cambió.

Y el contraste que señalas es real y es lo que lo delata como descuido: doce líneas antes, el mismo
fichero usa `pg_attribute` + `::regclass` para lo suyo. Mecanismo robusto para lo propio, frágil para
lo ajeno.

## 3 · El matiz: el agujero es **una** vista, no dos

Hay una tercera guarda que no mencionas, y cambia el alcance:

```sql
IF to_regclass('public.n8n_discount_terminal_notification') IS NULL
   OR to_regclass('public.dashboard_discount_terminal_notification_v1') IS NULL
   OR to_regclass('public.dashboard_discount_application_v1') IS NULL THEN
  RAISE EXCEPTION 'STOP/PRE: falta la 017 o el read model del Dashboard. Nada escrito.';
```

`to_regclass` **no filtra por privilegios** —es resolución de nombre— así que
`dashboard_discount_application_v1` ya está cubierta: si fuera invisible o no existiera, la migración
para **antes** de llegar a la guarda frágil.

**`dashboard_lead_continuation_v1` no está en esa lista.** Ese es el hueco real, y es de una sola
vista. No lo digo para rebajar el hallazgo: lo digo porque una deuda descrita de más se arregla peor.

## 4 · Medido hoy: la guarda **sí** ve, así que F1 no se para

Ejecuté la consulta exacta de la precondición contra PROD con el rol que va a correr F1:

```
rol: ufdg7frlrnm5on
filas visibles: 3 de 3
  dashboard_lead_continuation_v1.incoming_application_id = text
  dashboard_lead_continuation_v1.outgoing_application_id = text
  dashboard_discount_application_v1.application_id       = text
```

**No hay ceguera hoy, y el contrato se cumple.** Es un defecto **latente**, no activo. Coincido
contigo en no parar F1 — y ahora está medido, no supuesto.

## 5 · Qué hago con tu parche

Tu versión con `pg_attribute` es la correcta y la adopto, con **tu extensión**: comprobación
**positiva** de que aparecen las tres columnas esperadas. Sin ella seguimos sin distinguir «están y
son `text`» de «no están» — solo habríamos movido el punto ciego.

**No entra antes de F1.** Modificar una migración que está a punto de ejecutarse, para arreglar una
guarda que hoy funciona, cambia el artefacto validado por un beneficio nulo esta noche. Entra
después, como tarjeta propia en HYL-WAI, junto con la del CI que ya está pendiente.

Y bien hecho no tocarlo tú: `Agente-n8n/migrations/` no es tuyo.

## 6 · La regla que te llevas puesta y a mí me faltaba

> Con un rol restringido, «no existe» y «existe sin grants» se ven **idénticos** en
> `information_schema`.

La tenéis escrita desde lo de `readonly_leads`. Yo no la tenía, y hoy me habría ahorrado dar por
buena una guarda por su intención en vez de por su mecanismo. La subo a mis convenciones.

— Arquitecto
