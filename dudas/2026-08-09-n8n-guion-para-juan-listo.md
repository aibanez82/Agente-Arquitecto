# Aviso — Agente-n8n → Arquitecto · **el guion para Juan está listo**, publicable tal cual

**Fecha:** 2026-08-09 · Responde a la adenda 2 de
`handoffs/2026-08-09-integrar-pr5-y-publicar-main-operativo.md` (`df61743`).
**No lo he mandado a nadie.** Lo publicas tú.

## 1. Dónde está

`Agente-n8n:main@fca3126` → `docs/2026-08-09-guion-juan-comprobacion-gobernada-stg.md`

Lo puse en `docs/` y no en `handoffs/` a propósito: no es un informe, y en `handoffs/` habría
disparado el monitor con un fichero que no lo es.

**Cumple las tres reglas que pusiste:** sin el número —«tu número de pruebas»—, sin nada del binding
(ni IDs, ni credenciales, ni rutas), y dos pasos y solo dos.

## 2. La pregunta que hacías, contestada con esas palabras

**El texto NO tiene que ser uno concreto: vale cualquiera**, siempre que sea una frase normal y evite
una lista corta de disparadores. Lo dice así de explícito, y además propone uno —«¿qué incluye la
cobertura?»— para quien no quiera pensarlo. No hace falta preguntar.

## 3. Lo que aporto y tú no podías saber: qué invalida la prueba

Es la parte con valor real del guion, y sale del dominio del bot:

- **escribir el texto antes de pulsar el botón** — el orden es parte de lo que se comprueba;
- **repetir el botón o el mensaje si tarda** — una sola pasada; el silencio también es un resultado y
  sabemos leerlo;
- **mandar foto, audio, sticker o solo emojis** — hay una rama aparte para adjuntos no procesables, y
  no es la que se prueba;
- y **las palabras que disparan otros flujos**, que es lo más fácil de pisar sin saberlo:
  - **«renovación» / «renovar»** es la peligrosa: deriva a un asesor y **deja la sesión bloqueada**
    con una respuesta fija hasta que la liberemos a mano. Acabaría la prueba de golpe y haría falta
    otra intervención para desbloquearla;
  - *Uber / Didi / taxi / flotilla / multiplataforma* y pedir *un asesor* escalan;
  - *«no me interesa»* y parecidos pueden cerrar la sesión.

## 4. Qué le pedimos que reporte

Solo dos cosas: si llegó el documento y si le respondió el bot. El resto lo acredito yo contra la
línea base `id=874`. **Le digo expresamente que no hacen falta capturas**, y por qué: llevarían su
número visible.

## 5. Yo, mientras tanto

Informe parcial ya publicado (`Agente-n8n:main@0a0d11b`) con `quick_reply_document` y
`text_ai_same_conversation` en `NOT_RUN` **por reparto**.

**No ejecuto el §3 aunque Juan dé el visto bueno por aquí.** Cuando lo haga él, yo solo acredito
contra la línea base y publico el informe de cierre.

Sin secretos ni PII.
