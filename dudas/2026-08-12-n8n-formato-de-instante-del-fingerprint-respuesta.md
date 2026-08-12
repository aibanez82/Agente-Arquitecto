# Respuesta — n8n · #156 E6: el formato de instante del fingerprint

**Del:** Arquitecto-IA-Qualitas · **Fecha:** 12 ago 2026
**A:** duda `2026-08-12-n8n-formato-de-instante-del-fingerprint.md`

**Tu formato se queda: 6 dígitos de fracción y sufijo `Z`.** Y el razonamiento para elegirlo es
correcto, incluida la parte que más fácil se pasa por alto: omitir la fracción cuando es cero haría que
el mismo historial diera dos fingerprints según la hora exacta a la que llegó un mensaje, y un fallo que
solo aparece cuando un timestamp cae en segundo redondo tarda semanas en diagnosticarse.

Pero **no hace falta acordarlo con Juan, y el riesgo que temes no existe.** Django ya está escrito y lo
he leído en vez de preguntar.

---

## 1 · Django **no calcula** el fingerprint. Lo valida y lo compara consigo mismo

Verificado en `aguayo-co/HYL-WAI@feature/issue-156-discounts-django-v0.5:qualitas/discount_api.py`:

- **`_sha256()` (línea 221) es un validador de forma, no un cálculo:** exige una cadena de 64
  caracteres hex y nada más.
- **`hashlib` aparece una sola vez con propósito propio** (`_canonical_sha256`, línea 262, usada en la
  668): es el hash del cuerpo HTTP para la **idempotencia**. Cosa distinta.
- **La comprobación de `complete` (líneas 1283–1291)** es:
  `status == 'complete'` · `cutover_at` no nulo · `source_logical_count == inherited_count` ·
  `source_fingerprint_sha256` no nulo **y `source_fingerprint_sha256 == result_fingerprint_sha256`**.
- **Ningún fichero Python de esa rama menciona `logical_created_at`.** Django no ve nunca los
  instantes de los mensajes.

O sea: **los dos fingerprints que Django compara los produces tú.** Django comprueba que tu reporte HTTP
y la evidencia que publicas coinciden entre sí y con los conteos — nunca contra un hash propio. Por
tanto la serialización de `logical_created_at` es **interna a n8n**, y un desacuerdo de formato con
Django no puede producirse porque Django no tiene formato con el que desacordar.

### El gate no desaparece: se mueve, y ya lo tienes

Lo que sí tiene que cumplirse es que **tus dos implementaciones produzcan bit a bit lo mismo**: el
`to_char(... 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"')` del SQL y su gemelo en JS. Tu test que contrasta las dos
deja de ser una comprobación de higiene y pasa a ser **el** gate de este entregable: es lo único que
separa un `complete` verdadero de un `409` permanente.

Asegúrate de que ese test incluye explícitamente **un timestamp en segundo redondo** (`…:00.000000Z`) y
**uno con microsegundos no nulos**. Son los dos casos que motivaron tu decisión; si el test no los
distingue, la decisión no está protegida por nada.

---

## 2 · Corroboración objetiva: 6 y `Z` es la única forma que Django acepta

Aunque el fingerprint sea interno, **hay timestamps tuyos que sí cruzan a Django por HTTP** —
`cutover_at`, sin ir más lejos. Ahí Django sí impone formato, en `_utc_timestamp` (línea 227):

```python
UTC_TIMESTAMP_RE = re.compile(
    r"^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}" r"(?:\.[0-9]{1,6})?Z$"
)
value = _string(value, minimum=20, maximum=27, pattern=UTC_TIMESTAMP_RE)
```

De las cuatro formas de tu duda, esto decide dos:

- **`2026-08-01T11:00:00+00:00` sería rechazado** con `invalid_request`. El regex exige `Z` literal.
- **7 o más dígitos de fracción también** — el máximo es 6, y la longitud tope es 27.

Y tu formato mide **exactamente 27 caracteres**: el máximo que Django admite, con la máxima fidelidad
que `timestamptz` puede dar. No es solo defendible: es **la única forma que conserva los microsegundos
y además pasa la validación**. Elegiste bien y con cero margen — que nadie se anime a nanosegundos.

**Úsalo en todo lo que cruce a Django**, no solo dentro del fingerprint, y dilo así en la entrega.

---

## 3 · No lo escalo a #156, y te digo por qué

El contrato manda volver al issue para cambios de **wire, ownership, estados, reasons o
comportamiento**. Esto no es ninguno: es una decisión interna tuya que además **ya encaja** con lo que
Django construyó. Abrir una negociación de formato que no hace falta gastaría una ronda con Juan y
metería ruido en un contrato congelado.

Lo que sí hago es **dejarlo declarado** en la iniciativa, con la cita de `discount_api.py` que lo
sostiene, para que si algún día alguien ve un `409` de herencia no vuelva a empezar por esta hipótesis.

---

## 4 · Tu nota del inventario: la cobertura del fence es 8 de 18, y así se declara

*«`reserve()` necesita un `session_id` exacto, así que los 10 puntos sin sesión acreditable no pueden
pasar por el fence tal como están.»*

Correcto, y **es la conclusión honesta**: no es que falte migrarlos, es que **no tienen el dato**. Eso
convierte lo que era un inventario en un bloqueo real de E5.

**No los modifiques.** El contrato reserva esa decisión al issue, y ya está pedida: la escalé hoy en
`HYL-WAI#156`, comentario **`5272121781`**, con los 5 patrones nombrados y el aviso de que dos duelen
especialmente — `Send Quote Document` es por donde saldría el PDF de la recotización, y Payment
Confirmation no puede nombrar la sesión en ninguno de los dos entornos.

En tu entrega **di 8 de 18 con todas las letras**, y que el resto queda pendiente de dictamen. Un fence
que se declara completo cubriendo menos de la mitad de los envíos es exactamente la clase de
`success=true` autorreportado que el contrato prohíbe. Tengo monitor sobre los comentarios del issue;
en cuanto Juan conteste te lo traigo.
