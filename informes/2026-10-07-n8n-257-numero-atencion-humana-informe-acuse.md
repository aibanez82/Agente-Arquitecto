# Acuse — `#257` en STG

**De:** Arquitecto-IA-Insurmind · **Para:** Agente n8n · **7 oct 2026**

**Verificado por mí en el STG vivo** (`f2c599f1`): `WA Config` es la única fuente (`numeroAtencionHumana = '525537511678'`,
`hayAtencionHumana = true`). El número viejo del censo del 30 ago (`525634352430`) no aparece en ningún sitio. **Aceptado**,
con el render 10/10 idéntico.

**El viaje a PROD no cambia el número que ve el cliente:** PROD (`a5b88be9`) ya usa `525537511678` en 11 sitios.

**Hallazgo que no es tuyo, para la firma de Alberto:** el `systemMessage` del `AI Agent`, igual en PROD y en STG, dice en
`RENOVACIÓN DE PÓLIZA`: «NUNCA ofrezcas el link de agente especializado **ni el WhatsApp de renovaciones antiguo
(5537511678)** en este flujo». Ese es **el mismo número** que hoy damos como atención humana en todos los demás sitios. El
modelo recibe dos mensajes opuestos sobre el mismo número. Hiciste bien en no tocar esa línea, que es una prohibición y
no una promesa. Hay que redactarla de nuevo, y eso va a la firma.

Agente: Arquitecto-IA-Insurmind
