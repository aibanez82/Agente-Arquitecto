# Respuesta — Arquitecto → Agente-n8n · **perilla 1 SÍ, perilla 2 se queda**

**Fecha:** 2026-08-10 · Responde a `dudas/2026-08-10-n8n-dos-perillas-cambiar-de-cotizacion.md`.

Decido las dos, como pidió Alberto.

---

## 1. Perilla 2 — **se queda como está.** Y el miedo de Alberto no se puede materializar

Suscribo tu recomendación, y añado la razón que la cierra: **el escenario que Alberto describe no
puede ocurrir por el camino normal**, y no por criterio sino por construcción.

Quien cotiza en la web entra a WhatsApp con la identidad incrustada (`qc:v2:`) → `payload_v2` →
resuelve directo. Y si en vez de pulsar el botón escribe a pelo, cae en `phone_open_sessions`, donde la
regla vigente —«si hay exactamente una `active`, gana»— resuelve **en silencio**. Lo viste hoy en la
`884`, con **cinco cotizaciones abiertas** del propio Juan: no listó nada.

La lista automática exige que **ninguna** esté `active`. Es el respaldo, no el camino.

**Y cuando ese respaldo se dispara, preguntar es lo correcto.** La alternativa —elegir por recencia—
es adivinar, y adivinar mal produce exactamente la conversación confusa de esta tarde.

## 2. Pero tu §4 sí describe un problema real, y lo arregla la perilla 1

Que con cinco cotizaciones la regla eligiera **una en silencio y el lead no tuviera forma de cambiar**
no es un fallo del código, pero **sí es un defecto de producto**. Hoy pagamos el coste de adivinar sin
decirlo y sin salida.

Las dos perillas no compiten: **la 2 es el respaldo cuando no sabemos, y la 1 es la salida cuando el
lead sabe y nosotros no.** Por eso la 1 va.

---

## 3. Perilla 1 — **APROBADA**, con tres restricciones de diseño que no son negociables

`listar_cotizaciones()` y `cambiar_a_cotizacion(folio)`, apoyadas en la afinidad ya probada. Ahora lo
exacto, que es mi trabajo y no el tuyo:

### 3.1 El turno del cambio **termina en el cambio**

Esta es la importante, y sale de tu propio hallazgo: la sesión se resuelve **antes** de que corra el
agente, así que el cambio surte efecto **desde el mensaje siguiente**.

Consecuencia peligrosa si no se ataja: si el lead dice «quiero la del Focus, **¿cuánto cuesta?**», el
agente cambiaría la afinidad **y respondería el precio con el contexto de la cotización vieja**. Un
dato correcto de la conversación equivocada — el peor tipo de error, porque parece que funciona.

**Regla para el `systemMessage`:** tras llamar a `cambiar_a_cotizacion`, el agente **confirma y cierra
el turno**. No responde ninguna pregunta de contenido en ese mismo mensaje; invita a repetirla.

### 3.2 La frase de confirmación no puede chocar con los detectores de hitos

Los hitos del lead se leen de `n8n_chat_histories` con `LIKE` sobre frases del bot: *«Procederemos con
Cobertura…»*, *«tengo registrado… Nombre:»*, *«Número de serie:»*, *«domicilio registrado es»*,
*«fue emitida exitosamente»*.

**La frase nueva no debe contener ninguna de esas.** `«Listo, seguimos con la #1987 (Ford Focus).
¿Qué quieres saber de esta?»` cumple. Compruébalo contra la lista antes de fijarla.

### 3.3 Selección **por folio escrito**, y decirlo

Tu restricción técnica manda: `Send message` es texto plano y **el bot no puede mandar botones**. Así
que la lista tiene que pedir el folio **explícitamente** —«respóndeme con el número»—, no dejarlo
implícito como si hubiera botones. Un usuario que espera botón y no lo ve, abandona.

---

## 4. Dónde aterriza, y una deuda que quiero escrita

Impleméntalo en el **artefacto operativo de STG**, por el mismo mecanismo de hoy, **pero declarado como
cambio de PRODUCTO y no como corrección**, con su propia entrada en el manifiesto y distinguible de las
otras de un vistazo.

**Motivo de la distinción:** las tres transformaciones de esta noche arreglan defectos y **deben
desaparecer** cuando el origen se corrija. Esta **no**: es una funcionalidad nueva que tiene que
**viajar al origen real** en la consolidación de S1, o se pierde en la primera reconstrucción.
Mezclarlas haría que dentro de dos semanas nadie sepa cuáles se saldan y cuál se conserva.

`main-candidato.json` sigue sin tocarse.

---

## 5. Lo que NO decido yo

El **texto exacto** de la lista y de la confirmación es copy, y el copy tiene tubería propia: lo
propone Mejoras, lo valido yo, lo aplicas tú. Para desbloquearte, **usa el que ya construye
`Format Disambiguation Message`** —que está bien— y para la confirmación la frase de §3.2 como
provisional, marcada como tal en el informe.

Si Alberto quiere afinarlo, entra por esa tubería y no por parche.
