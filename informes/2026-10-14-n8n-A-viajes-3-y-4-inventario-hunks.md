# Informe · Agente n8n · A · inventario de hunks de los viajes 3 y 4 a PROD (antes del import)

**Orden:** `Agente-n8n:handoffs/2026-10-14-A-orden-prod-dia-de-viajes.md`: «Para los viajes 3 y 4: inventario de hunks antes del import, con cada hunk, de qué causa es y quién lo ejercitó».

**Cómo se ha medido:**
- **Base:** PROD **`d3a660c2`**, tras el viaje 1; el viaje 2 (`#606`) no toca ningún prompt y se aplica en la cadena para que la base sea la real.
- **Candidato:** el **mismo script de cambio** de STG (`resumen/cambio_resumen.py`, `nopromete/cambio_nopromete.py`) aplicado **sobre el PROD vivo**. No se copia el `systemMessage` de STG, que lleva la llamada, la retención y el `#586`.
- **Hunks:** el diff por líneas (`difflib`) del texto antes y después. Esto es todo lo que cambia en `systemMessage` y `text`.

## Viaje 3 · resumen con la pregunta al principio (firma `resumen-orden-pregunta` → A)

**Nodos:** `Rebuild Summary From Record` + `AI Agent` (solo el `systemMessage`). **`Rebuild Recovery Summary` no existe en PROD** (el `#551` no viajó), así que no viaja.

| hunk | líneas PROD | qué | causa | quién lo ejercitó |
|---|---|---|---|---|
| 1 | 763-768 → 763-764 | fuera la «línea de apertura cálida… ¡[Variante]! Ya tenemos todo 🎉»; la plantilla abre con «[Nombre], ¿todo correcto? Con tu sí, emito tu póliza.» | resumen (A) | arnés del resumen en STG: control 2/2 con la pregunta al final → 3/3 + 1/1 en el vivo `ec6f86d1`; E2E del QA sobre `327de5ea` |
| 2 | 785-787 → 781 | la plantilla acaba en el C.P. (sale la pregunta final) | resumen (A) | ídem |
| 3 | 791 → 785-786 | «CIERRE DEL MENSAJE DE RESUMEN… gancho de urgencia… ¡Confírmame…!» → «NADA ANTES NI DESPUÉS…» | resumen (A); de paso quita el «antes de que cambie», que es urgencia del `#596` | ídem; offline 4/4 de `rehacerResumen` |

**Texto exacto de cada hunk:**
    --- AI Agent.systemMessage · hunk 1 · replace · líneas PROD 763-768 → 763-764
    - Antes del bloque de datos, agrega una línea de apertura cálida — sujeta a la misma regla
    - VARIACIÓN EN TRANSICIONES (no repitas la palabra de apertura de tu mensaje anterior): "¡[Variante]!
    - Ya tenemos todo 🎉"
    - 
    - MENSAJE ÚNICO - RESUMEN COMPLETO:
    - "¡[Variante]! Ya tenemos todo 🎉
    + MENSAJE ÚNICO - RESUMEN COMPLETO (el sistema lo monta en este orden, con los datos del registro):
    + "[Nombre], ¿todo correcto? Con tu sí, emito tu póliza.
    --- AI Agent.systemMessage · hunk 2 · replace · líneas PROD 785-787 → 781-781
    - [Colonia], [Ciudad], C.P. [CODIGO_POSTAL]
    - 
    - [Nombre], ¿todo correcto? Con tu sí, emito tu póliza."
    + [Colonia], [Ciudad], C.P. [CODIGO_POSTAL]"
    --- AI Agent.systemMessage · hunk 3 · replace · líneas PROD 791-791 → 785-786
    - CIERRE DEL MENSAJE DE RESUMEN: si agregas algo después del bloque de domicilio, NUNCA termines con una pregunta binaria seca tipo "¿Confirmás SÍ o NO?" (ni variantes similares, ni en voseo). Usa en su lugar un cierre cálido con gancho de urgencia/escasez, variando la redacción entre sesiones (misma regla de VARIACIÓN EN TRANSICIONES) — ej. "¡Confírmame para asegurar esta tarifa antes de que cambie! 😊"
    + NADA ANTES NI DESPUÉS: no añadas apertura antes de la pregunta ni ningún cierre después del bloque de domicilio. La pregunta va
    + arriba (WhatsApp corta los mensajes largos con «Leer más») y el sistema monta el resumen en ese orden.
    

## Viaje 4 · no prometer contacto (firma `no-prometer-contacto`)

**Nodos:** `Merge Session Data` (la copia literal nueva de `respuesta-fija-limite30.js`, con el aviso firmado y el texto «cuando elige esperar», más `output.vuelveDesde`), `AI Agent` (`text` y `systemMessage`) y `RAG IA Agent` (`systemMessage`). **No viajan la llamada, la retención ni el `#586`.**

| hunk | campo · líneas PROD | qué | causa | quién lo ejercitó |
|---|---|---|---|---|
| 1 | `AI Agent.systemMessage` 120-122 → 120-126 | el aviso `fuera` del límite de 30 con el texto firmado nuevo (`[vuelve_desde]`) y el texto «Perfecto. Te guardo tu cotización…» cuando el cliente elige esperar | no-prometer-contacto | arnés en STG: AVISO y ESPERA 3/3 + 1/1 en el vivo `0adf0e0e` (el carril del grafo); ESPERA-2 (el modelo) control 0/2 → 3/3 |
| 2 | `AI Agent.systemMessage` +265-269 (REGLAS GENERALES, regla 8, nueva) | «NUNCA prometas un contacto que nadie va a hacer…» | no-prometer-contacto | ESPERA-2 3/3; `waq_4420` reproducida, 0 promesas (el control tampoco prometía: no discrimina, lo dije en su informe) |
| 3 | `RAG IA Agent.systemMessage` +181-184 (regla 14, nueva) | la misma regla general | no-prometer-contacto | **no ejercitado por el RAG** de forma separada: en los arneses, los turnos de espera los contestó el AI |
| 4 | `AI Agent.text` (el `[CTX:]`) | `+ \| vuelve_desde=` cuando `limite30=fuera` | no-prometer-contacto | ESPERA-2: el modelo usó la fecha (3/3) |

**Texto exacto de cada hunk:**
    --- AI Agent.systemMessage · hunk 1 · replace · líneas PROD 120-122 → 120-126
    -   ¿Quieres que la iniciemos en esa fecha, o prefieres que te contacte más cerca de cuando
    -   venza tu póliza actual?" Si el cliente acepta la fecha máxima, úsala como fecha_inicio y
    -   continúa el flujo normal del caso correspondiente.
    +   ¿Quieres que la iniciemos en esa fecha? Si prefieres esperar a que se acerque el vencimiento,
    +   escríbeme por aquí a partir del [vuelve_desde] y te la preparo en el momento, con tu cotización
    +   guardada." Si el cliente acepta la fecha máxima, úsala como fecha_inicio y continúa el flujo
    +   normal del caso correspondiente. Si el cliente prefiere esperar, responde: "Perfecto. Te guardo tu
    +   cotización: escríbeme por aquí a partir del [vuelve_desde] y la dejamos lista para que empiece
    +   justo el [vence]. ¡Que tengas muy buen día!" Las dos fechas son las del [CTX:] o las del aviso que ya
    +   le mandaste; no las calcules tú.
    --- AI Agent.systemMessage · hunk 2 · insert · líneas PROD 261-260 → 265-269
    + 
    + 8. NUNCA prometas un contacto que nadie va a hacer: ni «te contacto», «te escribo», «te llamo», «te aviso» ni
    + «quedo pendiente de contactarte», tampoco más cerca de una fecha. Hoy no existe ningún recordatorio por fecha:
    + es el cliente quien vuelve a escribir. Dile desde cuándo puede hacerlo (vuelve_desde del [CTX:] o la fecha del
    + aviso que ya le mandaste) y que su cotización queda guardada.
    --- RAG IA Agent.systemMessage · hunk 1 · insert · líneas PROD 181-180 → 181-184
    + 14. NUNCA prometas un contacto que nadie va a hacer: ni «te contacto», «te escribo», «te llamo», «te aviso» ni
    +     «quedo pendiente de contactarte». Hoy no existe ningún recordatorio por fecha: es el cliente quien vuelve a
    +     escribir; su cotización queda guardada.
    + 
    --- AI Agent.text · hunk 1 · replace · líneas PROD 1-1 → 1-1
    - =={{ '[CTX: qid=' + $json.quotationId + ' | vehiculo=' + ($json.vehiculo || 'desconocido') + ' | phase=' + $json.conversationPhase + ' | checkpoint=' + ($json.checkpoint || 'ninguno') + ' | pendiente=' + ($json.pendiente || 'ninguno') + ' | session=' + $json.sessionId + ' | phone=' + $json.phoneNumber + ' | fecha_actual=' + $now.toFormat('yyyy-MM-dd') + ($json.discountSerie ? ' | serie=' + $json.discountSerie : '') + ($json.rfcBase ? ' | rfc_base=' + $json.rfcBase : '') + ($json.aseguradoraCtx ? ' | aseguradora=' + $json.aseguradoraCtx : '') + ($json.venceCtx ? ' | vence=' + $json.venceCtx.vence + ' | dias=' + $json.venceCtx.dias + ' | limite30=' + $json.venceCtx.limite30 + ' | fecha_max=' + $json.venceCtx.fecha_max : '') + ($json.fechaInicio ? ' | fecha_inicio=' + $json.fechaInicio : '') + ((($json.sessionData || {}).policyData || {}).numero_poliza ? ' | poliza=emitida' : '') + ($json.discountUnavailable ? ' | descuento=no_disponible' : '') + ']\n=== USER INPUT STARTS BELOW ===\n' + $json.chatInput + '\n=== USER INPUT ENDS ABOVE ===' }}
    + =={{ '[CTX: qid=' + $json.quotationId + ' | vehiculo=' + ($json.vehiculo || 'desconocido') + ' | phase=' + $json.conversationPhase + ' | checkpoint=' + ($json.checkpoint || 'ninguno') + ' | pendiente=' + ($json.pendiente || 'ninguno') + ' | session=' + $json.sessionId + ' | phone=' + $json.phoneNumber + ' | fecha_actual=' + $now.toFormat('yyyy-MM-dd') + ($json.discountSerie ? ' | serie=' + $json.discountSerie : '') + ($json.rfcBase ? ' | rfc_base=' + $json.rfcBase : '') + ($json.aseguradoraCtx ? ' | aseguradora=' + $json.aseguradoraCtx : '') + ($json.venceCtx ? ' | vence=' + $json.venceCtx.vence + ' | dias=' + $json.venceCtx.dias + ' | limite30=' + $json.venceCtx.limite30 + ' | fecha_max=' + $json.venceCtx.fecha_max : '') + ($json.vuelveDesde ? ' | vuelve_desde=' + $json.vuelveDesde : '') + ($json.fechaInicio ? ' | fecha_inicio=' + $json.fechaInicio : '') + ((($json.sessionData || {}).policyData || {}).numero_poliza ? ' | poliza=emitida' : '') + ($json.discountUnavailable ? ' | descuento=no_disponible' : '') + ']\n=== USER INPUT STARTS BELOW ===\n' + $json.chatInput + '\n=== USER INPUT ENDS ABOVE ===' }}

**Ningún otro hunk:** el diff por líneas de los tres campos no da nada más.

— Agente n8n · A
