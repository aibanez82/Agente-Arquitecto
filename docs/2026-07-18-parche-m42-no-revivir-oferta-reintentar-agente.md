# Parche M42 — no revivir la oferta de reintentar/derivar en turnos no relacionados tras un fallo de API

> Origen: Alberto, probando el fix del Intent Router en STG (18 jul). Diagnosticado directo por
> el Arquitecto (no pasó por Agente Mejoras Conversación).
> Nodo objetivo: `AI Agent`.

## Qué pasa hoy

Cotización 1754, sesión `525551074144`: un intento de emisión falló antes (Quálitas QA caído),
mostrando el mensaje de respaldo con `[api_error:issue_policy]`. Turnos después, Alberto mandó un
dato suelto sin relación ("5551074144", su teléfono). El bot respondió:

> "Alberto, ya tengo tu teléfono desde tu cotización. Para continuar con la emisión de tu póliza
> del Toyota Corolla 2026, ¿quieres que reintente procesar tu solicitud o prefieres contactar
> directamente con un agente especializado en este enlace? [link]"

Esto **no es ninguno de los dos textos exactos** que el `systemMessage` prescribe (ni el mensaje
de respaldo de `[api_error:issue_policy]`, ni el mensaje de escalamiento de ESCALAMIENTO
INMEDIATO) — el modelo improvisó, mezclando el dato nuevo con una oferta de reintentar/derivar
que nadie pidió en ese turno, apoyándose en su memoria del fallo anterior.

## Por qué importa

El `systemMessage` ya exige texto EXACTO para ambos mensajes ("usa EXACTAMENTE este texto") —
esto es una violación de esa regla. En un cliente real: tiene un fallo de emisión una vez, sigue
chateando normal (da un dato, hace una pregunta), y el bot le sigue metiendo la oferta de
reintentar/hablar con un agente sin que la pida — sensación de bot atorado/insistente.

## Regla a agregar (AI Agent)

```
EDGE CASE — No revivir la oferta de reintentar/derivar tras un fallo de API en turnos
posteriores no relacionados:
Los mensajes de respaldo por fallo de API (issue_policy, get_quotation_data, etc.) y el mensaje
de escalamiento a agente especializado se muestran EXACTAMENTE como están definidos, SOLO en el
turno donde ocurre el fallo real. En turnos posteriores, si el usuario manda un mensaje que NO es
una respuesta directa a esa oferta (ej. comparte un dato, hace una pregunta, comenta algo),
responde normalmente a ESE mensaje sin volver a mencionar "reintentar" ni el enlace de agente
especializado — aunque el fallo siga sin resolverse. Solo vuelve a ofrecer esas opciones si el
usuario pregunta explícitamente por el estado de su emisión/póliza o pide ayuda de forma directa.
```

## Verificación de no-conflicto

- No contradice las reglas existentes de `[api_error:X]` — sigue exigiendo el texto exacto en el
  turno del fallo real, solo acota que no se repita fuera de ese turno.
- No contradice ESCALAMIENTO INMEDIATO — sigue funcionando igual cuando el usuario pide
  explícitamente hablar con un humano.

## Caso de prueba de referencia

Provocar un fallo de `issue_policy` (o simular con Quálitas caído), luego mandar un mensaje no
relacionado (un dato suelto o una pregunta de KB) y confirmar que el bot responde a ese mensaje
sin repetir la oferta de reintentar/agente especializado.

## Verificación antes de aplicar

**Aplicar primero en STG**, verificar contra el `systemMessage` vivo antes de pegar.
