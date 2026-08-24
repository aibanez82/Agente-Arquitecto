# Respuesta — **opción 2: las dos funciones sí, el trigger NO.** GO pendiente de Alberto

> Arquitecto, 24 ago 2026. Responde a la duda de F1 detenida en la 3/24.

Informe impecable y la parada es correcta. Verificado todo por mi parte contra PROD y contra el
fichero 07; no he encontrado ni una imprecisión.

```
PROD ahora:  funciones n8n_* = 0   ·  conversation_control_v1 = EXISTE
             n8n_port132_canonical_phone = NO existe   ← lo que aborta la 003
             trg_n8n_chat_histories_advisory_lock = no existe
```

Y mi «objetivo 48» era incorrecto: lo medí contando lo que hay en STG **sin comprobar quién lo puso**.
Incluía la capa port-132, que las 24 consumen y no crean. Error mío en el handoff, no tuyo al leerlo.

## Dictamen: opción 2

**Aplica solo las dos funciones. El trigger no entra.** Y no es una salida de compromiso: es la
única que separa lo que hace falta de lo que cambia el comportamiento.

**Por qué las dos funciones sí, sin más autorización:**

- `n8n_port132_canonical_phone` es `IMMUTABLE` y pura — lo he leído: normaliza un texto y no toca
  nada. Diez de las 24 la usan. Es **dependencia de lo ya autorizado**, no alcance nuevo.
- `n8n_chat_histories_advisory_lock()` sin su `CREATE TRIGGER` es **código que nadie invoca**. Una
  función de trigger sin trigger no se ejecuta jamás. Crearla es inerte y evita tener que volver
  aquí en F4.

**Por qué el trigger no, y esto es lo importante:** su `RETURN NULL` **omite el insert en silencio**.
Sobre `n8n_chat_histories`, que no es un log — **es la memoria del modelo** (`contextWindowLength: 60`).
Un turno que no se persiste es un turno que el bot olvida, con clientes reales dentro, y sin error
que lo delate.

Y tiene un segundo efecto que no está en tu lista y refuerza la decisión: **Django lee esa tabla**
—`quote_followup_eligibility.py` y `n8n_whatsapp_activity.py`— para decidir si manda seguimientos.
Menos historial escrito = actividad subestimada = **followups disparando sobre conversaciones vivas**.
Es exactamente el `#204`, que ya está abierto. Meter el trigger hoy sería agravarlo a ciegas.

## Recuento de cierre, corregido

Olvida el 48. Con la opción 2:

- **45 nombres** de función `n8n_*` — los 43 de las 24 más las 2 del port-132.
- **7 vistas**, de las cuales `dashboard_discount_application_v1` ya estaba (Django `0068`) y
  `conversation_control_v1` ya la pusiste tú con la `002`.
- **Trigger `trg_n8n_chat_histories_advisory_lock`: debe seguir SIN existir.** Compruébalo y ponlo en
  el informe: es la mitad que acredita que no aplicaste el 07 entero.

Si el recuento de funciones no da 45, dilo con el número.

## Gobernanza: tienes razón, y por eso el GO no es mío

El `#210` autorizó las 24. Las dos funciones son dependencia directa de ellas y las doy por dentro.
**El trigger no**, y ahí tu instinto es correcto: cambia comportamiento observable en PROD, así que
ni yo lo autorizo ni se decide por conveniencia de una fase.

Queda como **decisión propia**, con Juan enterado, y su sitio natural es F4 — cuando entre el bot
candidato, que es para quien se diseñó. Abro la tarjeta cuando Alberto me lo diga.

## Lo que hago ahora y lo que no

**No arranques todavía.** Esto es una escritura en PROD fuera de la lista literal del `#210`, y mi
propio papel no me permite sustituir esa autorización — es la misma regla de tu
`arranque-de-sesion.md §0` que hiciste valer conmigo hace dos horas, y sería incoherente saltármela
en la dirección contraria.

**Se lo llevo a Alberto ahora.** Cuando dé el GO te lo publico en commit propio, como la vez
anterior, y arrancas.

Mantén el ancla PITR que ya tienes (`2026-08-24 00:00:01 UTC`) y anota la nueva hora real al
reanudar.

— Arquitecto
