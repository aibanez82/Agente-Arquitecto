# Duda — dos perillas sobre «cambiar de cotización», para que decidas

**Alberto pide expresamente que decidas tú las dos.** Yo le he dejado el diagnóstico con los datos en
la mano; la decisión toca `systemMessage` y/o artefacto acreditado, así que es tuya (y puede que de
Juan la segunda).

## 0. Lo que Alberto quiere, y lo que NO quiere

Textual, porque el matiz es todo:

> «Si un lead le pide que quiere ver otra cotización, el agente debe ser capaz de listar las que tiene
> activas para que el lead la escoja y continuar por ella.»
>
> «Lo que NO quiero que pase: que yo cotice en la web un Toyota 2024 y la primera respuesta del bot
> sea *tienes 5 cotizaciones activas, ¿por cuál quieres continuar?*. Eso no. **Solo si el lead pide ver
> otra cotización.**»

O sea: **bajo petición sí, de oficio no.**

## 1. Lo que ya existe, y por eso esto es barato

- **Listar**: `Format Disambiguation Message` ya construye el mensaje bueno, con marca, submarca,
  modelo, cobertura, forma de pago, importe y fecha:
  `1. #1987 Toyota Corolla · Amplia · Anual · $11,814.82 · 09/08 22:31`
- **Seleccionar**: el folio ya funciona (`disambiguation_folio_selection`), y **consume** el número
  para que no llegue al agente como si fuera conversación.
- **Cambiar de sesión**: es la **afinidad**, y está probada — es exactamente lo que hizo el fixture
  `S1-F2` (ejecución `891`): seleccionar B la puso `active` y bajó la anterior a `open`, sin tocar A.

**Restricción técnica que condiciona el diseño:** `Send message` y `Send Disambiguation Message` son
`operation: send` de **texto plano**. **El bot no puede mandar botones interactivos** — los `qc:v2:`
vienen de fuera (Django/plantillas de Meta). Así que en conversación la selección es **por folio
escrito**, no por quick reply.

## 2. Perilla 1 — dos herramientas para el agente (lo que Alberto pide)

`listar_cotizaciones()` y `cambiar_a_cotizacion(folio)`. Flujo:

1. el lead pide «quiero ver mi cotización del Focus» / «la anterior»;
2. el agente llama a `listar_cotizaciones` → como la lista trae marca/submarca/modelo, «Focus» es
   resoluble; si hay una sola coincidencia cambia directo, si hay varias enseña la lista y pide folio;
3. `cambiar_a_cotizacion` aplica **afinidad** — el mecanismo ya probado, sin tocar la resolución.

**Detalle de comportamiento que hay que decidir cómo se redacta:** la sesión del turno se resuelve
**antes** de que corra el agente, así que el cambio surte efecto **a partir del mensaje siguiente**.
En la práctica: «Perfecto, seguimos con la #1987 (Ford Focus)» y desde ahí la conversación va por esa.

**Lo que necesita:** una tool nueva en el artefacto (contenido acreditado) y una instrucción en el
`systemMessage` que hoy **no existe**: `otra cotiz|cambiar de cotiz` → **0 coincidencias**, frente a 42
menciones de «cotización» en general.

**Esta perilla NO toca el primer contacto**: la herramienta solo se invoca cuando el agente entiende
que el lead lo pidió.

## 3. Perilla 2 — la desambiguación automática (lo que Alberto teme, y ya puede pasar)

Hoy se dispara sola cuando: el lead escribe **sin identidad**, tiene **≥2 sesiones abiertas** y
**ninguna `active`**. En ese caso el bot responde con la lista **sin que nadie se la haya pedido** —
justo lo que Alberto describe como inaceptable.

**Matiz importante, y es lo que evita la alarma:** por el camino normal **no ocurre**. Si cotiza en la
web, la entrada a WhatsApp lleva la identidad incrustada (`qc:v2:`) → `payload_v2` → resuelve directo
y no lista nada. Verificado en la ejecución `877` (quick reply real de Juan) y en el fixture `S1-F2`.

El escenario incómodo exige que el lead escriba a pelo al WhatsApp **y** que ninguna de sus
cotizaciones esté `active`. Es el respaldo, no el camino.

**Lo que hay que decidir:** si se deja como está —es un respaldo razonable— o se estrecha para que esa
lista no aparezca nunca sin petición (por ejemplo, condicionándola a que el mensaje sugiera retomar
algo, y si no, arrancar la conversación normal).

**Mi recomendación, y la digo sabiendo que decides tú:** dejarla. Cuando no hay identidad ni sesión
activa, preguntar es mejor que adivinar — y la alternativa es elegir una por recencia, que es
precisamente lo que produjo la conversación de Juan de esta tarde. Pero es tu llamada.

## 4. Un dato que aparece de paso, por si pesa en la decisión

Con **5 cotizaciones abiertas** (el caso real de Juan, ejecución `884`), la regla vigente —«si hay
exactamente una `active`, gana»— eligió una **en silencio** y el lead no tuvo forma de cambiar. No es
un fallo: es la regla escrita. Pero conviene tenerlo delante al decidir la perilla 2, porque las dos
alternativas —preguntar o elegir por recencia— tienen coste, y hoy pagamos el segundo sin decirlo.

## 5. Lo que yo NO hago

No toco el `systemMessage` ni añado tools por mi cuenta. Con tu decisión, ejecuto lo que salga.

— Agente n8n
