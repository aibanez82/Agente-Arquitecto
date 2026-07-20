# Handoff Arquitecto → Agente n8n — Agente MTP: enganche a METEPEC (caso Plataforma Digital)

> Autor: Arquitecto-IA-Qualitas · 20 jul 2026
> Ejecutor: **Agente n8n**.
> Gobernanza: reportas al Arquitecto **a través de Alberto**. No hablas con otros agentes.
> Copia canónica: `Agente-Arquitecto:docs/iniciativas/2026-07-20-agente-mtp-correo-metepec.md` (diseño completo) y `docs/iniciativas/2026-07-20-leads-metepec-seguimiento-comisiones.md` (tabla) — deja también copia de este handoff en `Agente-n8n/handoffs/`.
> **Rama/entorno destino: STG únicamente** (`n8n-xlqk.srv1810257.hstgr.cloud`). NO tocar PROD todavía.

## Objetivo

Automatizar el enganche de leads de "plataforma digital" (Uber/Didi/taxi/flotilla) que hoy el
bot escala a un WhatsApp humano fijo, perdiendo la oportunidad de que InsureMind reciba comisión
por participar en la venta. En vez de escalar con el link fijo, el bot debe: pedir el VIN (si no
lo tiene), registrar el lead en la tabla `leads_metepec`, mandar el correo a METEPEC vía Gmail, y
confirmar al cliente.

Contexto de negocio completo: `docs/iniciativas/2026-07-20-agente-mtp-correo-metepec.md`.

## Dónde vive el bug/comportamiento actual (confirmado leyendo el JSON)

El bloque "ESCALAMIENTO INMEDIATO A AGENTE HUMANO" existe **duplicado en dos nodos** —
mismo patrón de doble-mención que el Bug #6 (regex de placas), hay que tocar los dos:

1. **Nodo `AI Agent`** (`@n8n/n8n-nodes-langchain.agent`, `parameters.systemMessage`) — el
   agente principal de contratación.
2. **Nodo `RAG IA Agent`** (`@n8n/n8n-nodes-langchain.agent`, `parameters.systemMessage`) —
   el agente de KB/preguntas.

En ambos, dentro de la lista "Situaciones que activan escalamiento inmediato", aparece
textualmente:
```
- Vehículo de uso comercial: Uber, Didi, taxi, flotilla, transporte de pasajeros
```
Y ambos, al detectar cualquier situación de la lista (incluida esta), responden ÚNICAMENTE con
el mensaje fijo:
```
"Para su caso, le recomendamos contactar directamente con un agente especializado que podrá
atenderle mejor: https://api.whatsapp.com/send?phone=525634352430&text=Quiero%20continuar%20con%20mi%20cotizacion%20{QUOTATION_ID}"
```
sin pedir el VIN — dato que no está garantizado en ese punto de la conversación (nombre,
teléfono y email SÍ están garantizados desde el landing/lead vía `get_quotation_data`, pero el
VIN normalmente se captura después, en el Grupo 2 de `DATA_CAPTURE`).

## Cambio propuesto

**Separar el trigger "Vehículo de uso comercial" del resto de la lista de escalamiento** (los
demás casos — quiere hablar con humano, cancelar, "caso especial", se niega a dar datos, menor
de edad, auto importado — **no cambian**, siguen escalando igual que hoy con el mensaje fijo).

Para "Vehículo de uso comercial" específicamente, nuevo flujo en ambos nodos (`AI Agent` y
`RAG IA Agent`):

1. Al detectar el caso, si el VIN/número de serie NO está todavía en el contexto de la
   conversación, responder ÚNICAMENTE (usar EXACTAMENTE este texto):
   ```
   En ese caso necesitaría por favor que me des tu VIN y así ofrecerte una cotización especial.
   ```
   y finalizar el turno (no seguir con el resto del flujo normal).
2. Cuando el usuario responda con el VIN, llamar la tool nueva **`registrar_lead_metepec`**
   (ver abajo) con:
   - `nombre`, `telefono`, `email` — de `get_quotation_data` (mismo origen que usa
     `issue_policy` hoy, nunca mostrados al usuario)
   - `vehiculo_descripcion` — de `get_quotation_data` (marca/modelo/año, mismo dato que se
     muestra en el resumen: "Vehículo: [MARCA MODELO AÑO]")
   - `vin` — lo que acaba de dar el usuario
   - `cotizacion_id` — el `qid=` del prefijo `[CTX:...]`
   - `motivo_entrega` — literal `"plataforma_digital"`
3. Si la tool retorna éxito, responder ÚNICAMENTE (usar EXACTAMENTE este texto):
   ```
   Perfecto, ya tengo tus datos registrados. Uno de nuestros asesores especializados te va a
   contactar directamente para darte seguimiento a tu cotización.
   ```
4. **Fallback de seguridad:** si la tool falla (error de Postgres o de Gmail), NO perder el
   lead — usar el mensaje de escalamiento fijo actual (`wa.me/525634352430...`) como respaldo,
   igual que el resto de errores de API en este workflow (`[api_error:...]`).

## Tool nueva: `registrar_lead_metepec`

Mismo patrón que las tools ya existentes en este workflow (`Search Colony by Postal Code` es
`postgresTool`; `Issue Policy`/`Get Quotation Data` son `httpRequestTool`) — vos decidís la
implementación exacta (sub-workflow con "Execute Workflow Tool", o un `toolCode` que encadene
Postgres + Gmail vía HTTP). Debe hacer, en este orden:

1. **INSERT en `leads_metepec`** (tabla ya existe en Postgres STG, sin cambios de esquema —
   script en `Agente-Arquitecto:scripts/2026-07-20-crear-tabla-leads-metepec.sql`):
   columnas relevantes: `cotizacion_id`, `nombre`, `telefono`, `email`,
   `vehiculo_descripcion`, `vin`, `motivo_entrega='plataforma_digital'`,
   `fecha_entrega_metepec` (default `now()`, no hace falta pasarlo).
2. **Enviar correo vía nodo Gmail** (credencial OAuth2 ya conectada en n8n STG, nombre
   `"Gmail account"`, cuenta `insurmindmetepec@gmail.com`):
   - **Destinatario en STG (fijo por ahora): `acer3500@gmail.com`** — NO usar el correo real
     de METEPEC ni agregar CC reales todavía, esto es solo prueba en STG.
   - **Asunto:** `27614 Cotización Plataforma Digital`
   - **Cuerpo:**
     ```
     Este prospecto está interesado en una póliza para uso plataformas (Indriver, Uber o Didi).
     Por favor, contactar

     Nombre del cliente: {nombre}
     Teléfono de contacto: {telefono}
     Correo electrónico: {email}
     Vehículo: {vehiculo_descripcion}
     Número de Serie (VIN): {vin}
     Nuestra clave de agente es 27614
     ```
3. Retornar éxito/error a la tool para que el agente sepa qué mensaje dar al usuario (paso 3/4
   arriba).

## Tareas

1. Confirmar que la credencial `"Gmail account"` (Gmail OAuth2 API) ya está conectada en esta
   instancia de n8n STG antes de empezar (Alberto la conectó el 20 jul).
2. Construir la tool `registrar_lead_metepec` (INSERT + Gmail).
3. Editar `AI Agent` y `RAG IA Agent`: separar el trigger de vehículo comercial del resto de la
   lista de escalamiento, con el flujo de 4 pasos de arriba.
4. Probar en STG con un caso simulado (pin data o Execute workflow): mensaje mencionando "Uber"
   → debe pedir VIN → responder con un VIN de prueba → debe insertar en `leads_metepec` y
   mandar el correo a `acer3500@gmail.com` → debe responder con el mensaje de confirmación.
5. Confirmar que el resto de triggers de escalamiento (humano, cancelar, menor de edad, etc.)
   siguen funcionando exactamente igual que antes (no debe haber regresión ahí).
6. Reportar el commit + resultado de la prueba en STG.

## Fuera de alcance

- Caso "renovación" — queda pendiente, requiere agregar el intent `renovacion` al Intent
  Router (Haiku), hoy clasifica como `kb_query`. No tocar en este handoff.
- Desplegar a PROD — requiere: (a) credencial OAuth2 propia en n8n PROD (cliente OAuth de
  Google Cloud con la Redirect URI de PROD, no reutilizar el de STG), (b) cambiar destinatario
  a `metepecaten@qualitas.com.mx` con CC `laura.escamilla@hylant.com` y
  `Rafael.Rebollar@hylant.com`. Se hace en un handoff aparte cuando STG esté validado.
- Agente Conciliación (búsqueda por VIN en el portal de Quálitas para saber si METEPEC cerró la
  venta) — trabajo separado, no de Agente n8n.
