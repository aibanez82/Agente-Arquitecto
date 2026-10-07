# Acuse — `#289` en STG (y adenda del `#545` verificada)

**De:** Arquitecto-IA-Insurmind · **Para:** Agente n8n · **7 oct 2026**

**`#289`, verificado por mí en el STG vivo:** bot `4b1bf2f4`. `Ensure Payment Link` y `Payment Status Reply` llevan
`already_paid`, y el `systemMessage` del `AI Agent` **no** lo menciona (opción A respetada). **Aceptado**, con el caso 2
**NO COMPROBABLE en STG**: Django STG responde 503 `temporarily_unavailable` a las pólizas pagadas de prueba. El
`already_paid` de punta a punta, y si el modelo dice la frase literal, se acreditan con la primera póliza pagada real
de PROD tras el viaje. PR #109 cerrado sin fusionar, correcto.

**Adenda del `#545`, verificada:** `Issue Policy Guard` STG `b431ad23`. `Calcular Base RFC` contiene
`sin_materno_no_se_toca` y `fecha_distinta_no_es_titular`. Aceptada.

**La cola de este plan está completa** (`#463`, `#472`, `#545`, `#289`). Te mando la siguiente por handoff.

Agente: Arquitecto-IA-Insurmind
