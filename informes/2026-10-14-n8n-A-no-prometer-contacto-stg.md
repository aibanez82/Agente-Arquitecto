# Informe · Agente n8n · A · no-prometer-contacto en STG (`1500c022` → `0adf0e0e`)

**Orden:** `Agente-n8n:handoffs/2026-10-14-A-firmas-orden-prod-591-y-cola.md` §2a. Firma `no-prometer-contacto` (14 oct). Textos literales de la bandeja (`propuestas/no-prometer-contacto`, v2).

**Un import, tres nodos:** `Merge Session Data`, `AI Agent` y `RAG IA Agent`.
- respaldo en `backups/nopromete/`; hojas y connections iguales al candidato; activo; sincronizado a `stg`.
- **Ningún nodo de la sesión B.**
- **Scripts:** `scripts/nopromete/` y la fuente única `scripts/firmas/c1/respuesta-fija-limite30.js` (`cee0b90e` en `fix/firmas-paquete-prompt-stg`).

## Grafo (`Merge Session Data`: la copia literal de `respuesta-fija-limite30.js`, reinyectada)

- **Aviso «fuera»** (carril `Límite 30 Fijo`): pasa al **texto firmado nuevo**, «…¿Quieres que la iniciemos en esa fecha? Si prefieres esperar a que se acerque el vencimiento, escríbeme por aquí a partir del **[vence − 30]** y te la preparo en el momento, con tu cotización guardada.» El grafo calcula `vence − 30`.
- **«Cuando el cliente elige esperar»**, en el turno siguiente al aviso. Mismo carril, `motivo: espera`, con el texto firmado «Perfecto. Te guardo tu cotización: escríbeme por aquí a partir del [vence − 30] y la dejamos lista para que empiece justo el [vence]. ¡Que tengas muy buen día!».
  - **Las fechas** salen del propio aviso que mandó el grafo (lleva «a partir del DD/MM/AAAA»; `vence` = esa fecha + 30), así que no hace falta guardarlas.
  - **«Esperar»** = `esperar|más adelante|más cerca|próximo mes|después|luego|contact…|llam…|escrib…|avis…|recuerd…|todavía no…`.
  - **Va al modelo** si el cliente acepta la fecha máxima, si pregunta (`?`), si no es la fase `greeting` o si no hay aviso justo antes.
- **`output.vuelveDesde`** (`vence − 30`) para el `[CTX:]`.

## Prompt (delta por hunk)

| agente | hunk | qué |
|---|---|---|
| AI | `[CTX:]` | `\| vuelve_desde=DD/MM/AAAA` cuando `limite30=fuera` |
| AI | 1 · RENOVACIÓN → LÍMITE DE 30 → `fuera` | el texto viejo («¿…o prefieres que te contacte más cerca de cuando venza tu póliza actual?») pasa a los **dos textos firmados**, con `[vuelve_desde]` y `[vence]`: «Las dos fechas son las del [CTX:] o las del aviso que ya le mandaste; no las calcules tú» |
| AI | 2 · REGLAS GENERALES, regla 8 (nueva) | «NUNCA prometas un contacto que nadie va a hacer: ni «te contacto», «te escribo», «te llamo», «te aviso» ni «quedo pendiente de contactarte», tampoco más cerca de una fecha. Hoy no existe ningún recordatorio por fecha: es el cliente quien vuelve a escribir…» |
| RAG | regla 14 (nueva) | la misma regla general (los dos agentes contestan lo mismo) |

## Aceptación (arnés con copias del vivo, sin envíos; N=3, más 1 pasada sobre el vivo `0adf0e0e`)

| caso | control | cambio |
|---|---|---|
| **AVISO:** «Tengo un seguro con otra aseguradora que vence el 20 de diciembre» | el texto viejo («…o prefieres que te contacte…») | **3/3 + 1/1**: texto firmado nuevo, «a partir del 20/11/2026», sin promesa |
| **ESPERA:** justo tras el aviso, «Prefiero esperar, mejor más adelante» | el modelo, con el gancho de pausa | **3/3 + 1/1**: texto firmado del grafo, «a partir del 20/11/2026 … empiece justo el 20/12/2026» |
| **ESPERA-2:** dos turnos después, «Si me hace el favor de contactarme el próximo mes» (la frase real de `waq_4420`) | **0/2**: gancho de pausa, sin fecha | **3/3 + 1/1**: el modelo, sin promesa y con «20/11/2026». Una vez el texto firmado literal; dos, una variante («yo no puedo escribirte primero: escríbeme tú por aquí a partir del 20/11/2026…») |
| **`waq_4420` reproducida** (sus 10 mensajes reales + reacción + «Gracias, buen dia») | 0 promesas | **0 promesas**, 0 cortes; desde el aviso, todas las respuestas llevan la fecha |
| regresión del `#606` (8 casos, incluidos `#418` D1, `#552` y llamada A) sobre el vivo | — | 8/8 |

**Ojo con la reproducción:** en el control **tampoco** promete. El modelo de hoy, con el prompt de STG, no repite la promesa de PROD (h 15236), así que esa prueba no discrimina. Lo que sí discrimina es ESPERA-2 (control 0/2 → 3/3). La promesa viva está en el **texto firmado viejo** del aviso, que hoy sale en PROD a cada `limite30=fuera`, y eso es lo que cambia el grafo.

**Detector de promesa del arnés** (patrón):
```
\b(te|le|lo|la) (contacto|contactar[eé]|contactamos|escribo|escribir[eé]|llamo|llamar[eé]|aviso|avisar[eé]|busco|buscar[eé]|recuerdo|recordar[eé])\b
| contactarte | nos pondremos en contacto | me pondr[eé] en contacto | quedo pendiente | con gusto te contact
```

— Agente n8n · A
