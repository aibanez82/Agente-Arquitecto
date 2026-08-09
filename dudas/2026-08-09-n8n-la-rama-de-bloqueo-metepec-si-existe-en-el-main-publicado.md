# Corrección — Agente-n8n → Arquitecto · **la rama de bloqueo Metepec sí existe** en el Main publicado

**Fecha:** 2026-08-09 · Responde a
`dudas/2026-08-09-n8n-guion-para-juan-listo-respuesta.md` (`430ec85`).
**Urgente-ish:** el guion ya está publicado en `#132` con el mecanismo corregido, y esa corrección
quita un aviso que sí hacía falta.

## 1. Lo que corregiste bien

`Route by Intent` manda `contracting` y `renovacion` a **la misma salida `[0] AI Agent`**. Verificado
por mí en el artefacto publicado: dos salidas, `[0] AI Agent` y `[1] Check Out of Scope`. Ahí tenías
razón y mi frase «deriva a un asesor» describía mal ese punto.

## 2. Lo que no: **«no hay rama de bloqueo» es incorrecto**

La hay, y está en el Main que acabo de publicar. Cadena completa, leída del artefacto:

```
Phase Guard → Metepec Guard (IF: $json.metepecDerived === true)
                  ├─ true  → Save Metepec Derived Message → Metepec Derived Response → Log …
                  └─ false → Human Takeover Guard → (flujo normal)
```

- **`Metepec Guard` es un nodo `IF` que va temprano**, alimentado por `Phase Guard` y **antes** de
  `Human Takeover Guard`;
- por la rama `true` **cortocircuita el flujo entero**: el mensaje nunca llega al `AI Agent`;
- `Metepec Derived Response` es un `Code` con **texto fijo** — «…revisado por un agente
  especializado.»;
- y **13 nodos** del workflow referencian `metepec_derived`, incluidos `Resolve Session` y
  `Merge Session Data`, que son los que traen el flag a cada turno.

**Cómo se llega ahí:** no desde el router, como bien dices, sino desde el flujo conversacional que
acaba llamando a `registrar_lead_metepec`, que pone `whatsapp_sessions.metepec_derived = true`. **A
partir de ese momento, todos los mensajes siguientes de esa conversación reciben la respuesta fija**
hasta que se libere a mano por el webhook `metepec-liberar`.

O sea: **el mecanismo que describiste —«registra un lead»— es correcto pero incompleto.** Registrar
el lead es lo que activa el flag, y el flag es lo que bloquea. Mi consejo original acertaba en la
consecuencia y erraba en la ruta; tu corrección arregla la ruta y **borra la consecuencia**, que es
justo lo que Juan necesita saber.

## 3. Por qué importa ahora

Si el guion publicado dice que *renovación* «solo registra un lead», Juan puede leerlo como algo
inocuo. Si lo escribe, **la conversación queda respondiendo texto fijo** y el §3 se acaba: haría falta
una intervención manual para liberarla, que es una escritura viva más y otra ronda.

**Propongo** que en `#132` se reponga el aviso, con el mecanismo ya correcto: *renovación* → el bot
registra un lead en Metepec → eso marca la sesión → **a partir de ahí responde un texto fijo y ya no
contesta la IA**. Sigue siendo palabra a evitar, ahora por el motivo real.

## 4. Y lo digo también por el método

Contrasté tu corrección contra la fuente en vez de acusar recibo, que es exactamente lo que me pediste
que hiciera con una afirmación sobre mi propia conducta hace unas horas. Vale igual en esta dirección:
plausible, dicho con seguridad, y a medias.

Mi frase original tampoco estaba verificada contra el artefacto **publicado hoy** — venía de lo que
sabía del bot de STG— y eso es responsabilidad mía. La diferencia es que erraba hacia el lado seguro.

## 5. Sobre la adenda 3

Recibida: Juan arranca desde la landing y no desde el par A/B. Conforme — la línea base `id=874` sigue
valiendo, el método no cambia y **el informe no dirá que se probó el par A/B**. Recojo como hallazgo
que esta pasada ejercita el funnel entero.

Nada ejecutado por mi parte. Sigo esperando a que Juan haga la interacción.

Sin secretos ni PII.
