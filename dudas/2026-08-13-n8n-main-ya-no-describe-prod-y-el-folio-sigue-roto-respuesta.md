# Respuesta — sí a re-exportar, y el folio ya tiene issue (`#78`)

**Arquitecto · 13 ago 2026.** Las dos preguntas son mías y las contesto las dos. Bien planteadas: la 1 es
efectivamente una declaración y no un `sync`, y hacías bien en no tomarla tú.

---

## 1 · Sí, re-exporta los dos baselines. **Autorizado.**

La declaración que hay detrás es «el estado vivo de hoy **es** el estado limpio de PROD», y esa la puedo firmar
porque **acredité los 15 nodos uno a uno hoy**, no porque me fíe del recuento:

| Nodos | Procedencia | Dónde lo acredité |
|---|---|---|
| `Listar Cotizaciones` · `Cambiar Cotizacion` · `Limpiar Turno De Cambio` · `Prepare Resolution Context` | Multicotización | promoción + arreglo de la credencial de STG, verificado por API |
| `Human Takeover Guard` · `Save Human-Gated Message` · `Resolve Session` · `RAG IA Agent` · los tres `Send *` | Atención Humana | tu promoción de las 14:59 |
| `Format Disambiguation Message` | `#76` | cerrado con conversación real |
| `Session Resolution` · `Merge Session Data` · `AI Agent` | `#77`, ventana C | cerrado con conversación real, verificado contra la base |

Ninguno es un cambio a mano de nadie. Tu argumento es el correcto y es el que decide: **un detector que ladra por
15 nodos legítimos deja de servir para avisar del 16º**, que sería el ilegítimo. Un baseline desfasado no es
prudencia, es un punto ciego con aspecto de rigor.

Va a `main`, que es la rama de baselines de referencia — tu clon está parado en `docs/fase4-preparacion`, así que
no choca con la regla de no tocar la rama en la que estás.

**Con dos condiciones:**

1. **En el mismo commit**, `Atencion Humana` (`B5ihE5xHg8bjeesl`) entra en `TARGETS` con su baseline. Tienes razón
   en que el hueco es tuyo, y también en decirlo aquí en vez de dejarlo pasar: un workflow vivo sin vigilancia es
   peor que uno vigilado con drift. Ahí queda saldado.
2. **Deja constancia en el commit de que el baseline nuevo se apoya en acreditaciones del 13 ago**, con los
   issues (`#76`, `#77`) nombrados. Si dentro de tres meses alguien se pregunta por qué el baseline saltó 6 nodos
   en un día, la respuesta tiene que estar en el propio historial y no en esta conversación.

### Sobre `WhatsApp Insurance Quotation Bot copy`

Me lo has reportado dos veces y sigue sin dueño; el fallo de que siga ahí es mío, no tuyo. **Decisión: añádelo
también a `TARGETS` con su baseline**, aunque esté inactivo. Vigilar es barato y ese workflow es exactamente el
tipo de cosa que alguien edita «porque es una copia» y acaba activando.

Lo que **no** hagas es borrarlo: eso es acción viva sobre PROD y la decide Alberto. Lo llevo a la ventana de
higiene de la Fase 5, donde ya están los dos `DROP INDEX`, y ahí se decide si se borra o se queda vigilado.

## 2 · El folio: **issue propio, y ya está abierto**

`qualitas-issues#78` — «Si alguna vez se revive la desambiguación: copy y parser van juntos (folio y ordinal)».
Lo abrí al cerrar `#77`, antes de leer tu duda, así que no tienes que hacer nada.

Recoge lo tuyo: que hoy es inocuo, que el parseo de ordinal se fue **a propósito** con la rama (y que era mejor
así, porque un «2» dicho a cualquier otra cosa cambiaba de cotización sin avisar), y las tres cosas que hay que
recordar si alguien revive el router — copy y parser juntos, consumir el folio si se acepta, y **no** promover el
cuerpo del `Format Disambiguation Message` de STG, que es el del bug de `#76`.

Tu instinto era el correcto: una nota dentro de un issue cerrado no la lee nadie. Un cabo que solo hace daño
dentro de seis meses necesita un sitio propio donde esperar.
