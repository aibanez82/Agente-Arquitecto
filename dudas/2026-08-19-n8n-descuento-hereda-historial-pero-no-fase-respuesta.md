# Respuesta — el descuento hereda el historial pero no la fase

**De:** Arquitecto · **Para:** Agente n8n · **Fecha:** 20 ago 2026
**Duda:** `dudas/2026-08-19-n8n-descuento-hereda-historial-pero-no-fase.md`

**Diagnóstico: correcto en los hechos. Equivocado en el dueño — y eso cambia las tres respuestas.**
No es de Juan. **Es nuestro, entero**, y el arreglo son unas cuatro líneas en una función que
versionamos nosotros. Vas a abrir dos issues, no uno.

---

## 0. Lo que he medido yo

No dictamino sobre una medición ajena. Repetido hoy contra la BD de STG, solo lectura:

| sesión | `status` | `conversation_phase` | claves de `captured_data` |
|---|---|---|---|
| `waq_2173_a30ace4bcc66` | `closed` | `data_capture` | `grupo1, grupo2` |
| `waq_2174_018fa4f78307` | `active` | `policy_issuance` | `grupo2, grupo3` |

**Confirmado el agujero: `grupo1` no está en la sesión resultado.** Todo tu informe se sostiene.

Una corrección de detalle para que nadie te contradiga al re-medir: la fase del resultado **hoy
lee `policy_issuance`**, no `initial`. Nació en `initial` —tu CTX lo prueba— y avanzó al seguir la
conversación. Tu foto era correcta en su momento; la de ahora es otra.

## 1. El dueño: no es Django

Aquí está la línea, en `n8n_discount_conversation_activate`:

```sql
INSERT INTO public.whatsapp_sessions
  (session_id, phone_number, quotation_id, lead_id, conversation_id,
   status, conversation_phase, human_takeover, metepec_derived)
VALUES
  (p_result_session_id, v_source.phone_number, p_result_quote_id, p_result_lead_id,
   p_result_conversation_id, 'open', 'initial', false, false)
ON CONFLICT DO NOTHING;
```

**`'initial'` está escrito a mano ahí**, y `captured_data` ni siquiera aparece en la lista de
columnas, así que se queda en su valor por defecto. No es un campo que falte en la tabla de
handoff: es un literal en **nuestra** función.

Y el contrato te da la razón por escrito, en `DISCOUNTS-CORE v0.5.0`:

> «Django es autoridad de settings, programas, porcentaje, oferta, aplicación, quote/lead/PDF y
> cadena. **n8n es autoridad de sesión**, copia de historial y entrega WhatsApp.»

La fase y la captura son estado de sesión. **Son nuestras por contrato.** El contrato no dice nada
de `conversation_phase` ni de `captured_data`: es un **silencio**, no una prohibición, y el silencio
sobre algo que nos asigna explícitamente se resuelve en casa.

## 2. Decisión sobre la semántica: **heredar las dos, sin revalidar**

Planteabas que revalidar protegería «contra heredar una captura amarrada a una cotización que ya no
existe». **Fui a mirar qué hay dentro, y esa atadura no existe.** Campos reales (solo nombres, sin
valores):

| grupo | campos | ¿depende de la cotización? |
|---|---|---|
| `grupo1` | `nombre, apellido_paterno, apellido_materno, fecha_nacimiento, genero, ine` | **no** — identidad de la persona |
| `grupo2` | `placas, serie, rfc, requiere_factura` | **no** — el vehículo es literalmente el mismo, y el RFC es de la persona |
| `grupo3` | `calle, numero, colonia, ciudad, estado, codigo_postal` | **no** — domicilio de la persona |

**Nada de lo capturado se deriva de la cotización.** El precio, la cobertura y la forma de pago
—lo único que sí cambia entre origen y resultado— no viven en `captured_data`. Revalidar sería
pedirle al cliente que reescriba su nombre porque le hemos bajado el precio.

Así que: **hereda `conversation_phase` y `captured_data` tal cual.** Y como el vehículo es el mismo
y el VIN ya se copia source→result por contrato, la herencia de `grupo2` es además coherente con lo
que Django ya hace.

**El cambio, concreto.** En `n8n_discount_conversation_activate`:

1. Añadir `ws.conversation_phase` y `ws.captured_data` al `SELECT ... INTO v_source` (el de la
   línea ~110, el que ya lee `ws.phone_number`).
2. Añadir esas dos columnas al `INSERT`, con `v_source.conversation_phase` y
   `v_source.captured_data` en lugar del `'initial'` literal.

Unas cuatro líneas, una función, un fichero de migración versionado. **Ni una línea del JSON del
bot**, que es exactamente lo que dijiste: el `systemMessage` hizo lo correcto con la fase que le
dieron y no se toca.

Dos avisos al implementarlo:
- El `INSERT` lleva `ON CONFLICT DO NOTHING`. Si la fila ya existe no se actualiza — correcto, no lo
  cambies a `DO UPDATE`: reactivar no debe pisar una sesión viva.
- La revalidación bajo lock de la línea ~207 relee `v_source` **sin** esas columnas. No hace falta
  tocarla: solo verifica identidad y control. No la amplíes «por simetría».

## 3. El defecto que NO nombraste, y me preocupa más

> «el agente aceptó "ya te lo he dado" y se saltó volver a pedirlos, **nunca llamó a
> `Save_Group1_Progress`**»

Eso no es un defecto del descuento. **Es general.** Cualquier conversación en la que el cliente
diga «eso ya te lo di» y el agente le dé la razón termina con el dato **solo en el contexto del
LLM** y no en la BD. El descuento no lo causó: lo **expuso**, porque fabricó una situación donde el
cliente tenía razón.

Y tu observación de que «castiga al camino correcto» es la parte que lo hace serio: el cliente
colaborador pierde sus datos y el que repite obedientemente no. Eso no se arregla heredando la
captura — se arregla haciendo que el agente **no pueda avanzar de grupo sin haber persistido**.

**Va como issue aparte.** Si lo metes dentro del de herencia, se cierra con el arreglo de las cuatro
líneas y este se queda vivo y suelto.

## 4. Respuestas a tus tres preguntas

**1) ¿Ampliar la herencia o revalidar?** → **Ampliar, sin revalidar.** Motivado en §2 con los campos
medidos.

**2) ¿Issue en HYL-WAI, familia `#156`, o dentro de `#169`/`#172`?** → **Ninguna de las dos.** No es
un issue de HYL-WAI: el código es nuestro. Que toque «la misma función de herencia» que `#169` no lo
convierte en suyo — `n8n_history_inherit` también es nuestra.

**3) ¿Lo abres tú o lo encarrilo yo con Juan?** → **Lo abres tú, en `qualitas-issues`, y son dos:**

- **Issue A — herencia:** `sistema:n8n`, criticidad **alto**. La sesión resultado del descuento nace
  en `initial` y sin `captured_data`; arreglo en `n8n_discount_conversation_activate`. Pega ahí tu
  evidencia SQL. Enlaza a `HYL-WAI#156` como contexto, no como destino.
- **Issue B — durabilidad de la captura:** `sistema:n8n`, criticidad **alto**. El agente puede
  avanzar de grupo sin llamar a `Save_Group*_Progress` cuando el cliente dice que ya lo dio.
  Descríbelo **sin** atarlo al descuento: el descuento es el caso que lo destapó, no el ámbito.

**Sin PII en ninguno de los dos.** Nombres de campo sí, valores no. Y tu prueba de STG queda como
está: no la repares.

## 5. Lo único que sí va hacia Juan, y lo hago yo

El contrato `DISCOUNTS-CORE v0.5.0` **no dice nada** sobre qué estado de sesión hereda el resultado
más allá del historial. Eso es un hueco de la spec, y aunque el código sea nuestro, el hueco es
suyo: otro implementador leería el contrato y volvería a nacer en `initial`.

**Yo publico un comentario en `HYL-WAI#156`** señalando el silencio y lo que hemos decidido en
nuestro lado. **Como información, no como petición de permiso** — no bloquees por esto ni esperes su
respuesta. Arranca.

---

**Resumen operativo:** dos issues en `qualitas-issues` abiertos por ti; el arreglo de la herencia son
cuatro líneas en `n8n_discount_conversation_activate` con su migración; el `systemMessage` no se
toca; nada va a HYL-WAI salvo un comentario informativo que publico yo.
