# Agente MTP — automatizar entrega de leads a METEPEC (plataforma digital)

> Añadido: 20 julio 2026. Continúa [leads-metepec-seguimiento-comisiones](2026-07-20-leads-metepec-seguimiento-comisiones.md).
> **Corrección 22 jul:** renovación sale por completo de este alcance — Alberto decidió que
> ningún caso de renovación va a METEPEC (si es póliza Hylant se resuelve directo emitiendo;
> si no es Hylant, no es un lead convertible, no vale la pena mandarlo). Detalle:
> [casuística de renovación](2026-07-22-casuistica-renovacion.md). Todo lo de renovación en este
> documento (diseño de correo, alcance, plantilla) queda obsoleto — se conserva solo como
> referencia histórica de lo que se descartó y por qué.

## Qué es esto

No es un 6º repo/agente de Claude Code. Es una rama nueva del workflow n8n del bot de
WhatsApp (mismo patrón que "Payment Confirmation"), diseñada por el Arquitecto e
implementada por el **Agente n8n** existente. No requiere LLM en el loop de envío —
lógica determinística: armar payload → INSERT en `leads_metepec` → mandar correo.

## Motivación

Hoy el bot maneja ~70-80% de los leads de forma autónoma por WhatsApp. El resto son
casos que el bot no puede cerrar y hoy se resuelven mandando un correo manual (Alberto
lo redacta a mano) al contact center de Highland (METEPEC), que cotiza/emite por
teléfono.

Dos categorías identificadas en el bot actual (auditado 20 jul):
- **Plataforma digital (Uber/Didi/taxi/flotilla):** YA detectado — regla de
  "ESCALAMIENTO INMEDIATO" en el system prompt de Sonnet, pero hoy responde con un
  link fijo a `wa.me/525634352430` (handoff humano por WhatsApp, no METEPEC).
- **Renovación:** NO detectado como escalamiento — el Intent Router (Haiku) lo
  clasifica hoy como `kb_query` (pregunta informativa respondida con la KB/RAG), sin
  ningún gancho que dispare acción. Hace falta agregar `renovacion` como intent propio.

## Diseño acordado con Alberto (20 jul)

1. **Intent Router (Haiku):** agregar `"renovacion"` como valor propio de intent
   (hoy cae en `kb_query`).
2. **Nuevo branch en el workflow principal**, disparado cuando intent = `renovacion`
   **o** la regla de escalamiento de Sonnet detecta vehículo comercial — reemplaza el
   envío del link fijo `wa.me/525634352430`:
   - Nodo Function arma el payload del lead (nombre, teléfono, email, vehículo, VIN,
     CP, monto cotizado, `motivo_entrega`: `'plataforma_digital'` | `'renovacion'`)
   - Nodo Postgres → `INSERT INTO leads_metepec` (tabla ya existe, sin cambios de
     esquema — ver [leads-metepec-seguimiento-comisiones](2026-07-20-leads-metepec-seguimiento-comisiones.md))
   - Nodo Send Email desde `insurmindmetepec@gmail.com` → METEPEC, con los datos +
     clave de agente
   - Responde al cliente confirmando que un asesor especializado lo va a contactar
     (nuevo texto, reemplaza el mensaje de escalamiento actual)

## Datos confirmados

- **Remitente:** `insurmindmetepec@gmail.com`
- **Clave de agente (fija):** `27614`
- **Destino en STG:** `acer3500@gmail.com` — decidido (20 jul) que el correo real de METEPEC
  no se comparte/usa en STG, solo en PROD cuando se despliegue ahí.
- **Credencial Gmail:** ✅ conectada (20 jul) — en n8n **STG** (`n8n-xlqk.srv1810257.hstgr.cloud`),
  credencial tipo **Gmail OAuth2 API** (nombre "Gmail account"), estado "Account connected".

### Cambio de plan: SMTP → Gmail OAuth2 API (20 jul)

El plan original (credencial SMTP + App Password, puerto 465/587) falló en n8n STG con
"Connection closed unexpectedly" en ambas combinaciones estándar (465+SSL, 587+STARTTLS) —
consistente con que Hostinger bloquea los puertos SMTP salientes en ese VPS. Alberto no tiene
acceso SSH al VPS para confirmarlo directamente, así que se descartó seguir depurando SMTP a
ciegas y se pivotó a la **Gmail API vía OAuth2** (HTTPS/443, no depende de puertos SMTP):

- Proyecto de Google Cloud creado: `SMTP Metepec` (el nombre quedó del plan original, no se
  renombró — no afecta funcionalidad).
- Gmail API habilitada, OAuth consent screen tipo External / modo Testing, con
  `insurmindmetepec@gmail.com` como test user.
- Cliente OAuth (Web application) con Redirect URI
  `https://n8n-xlqk.srv1810257.hstgr.cloud/rest/oauth2-credential/callback`.
- El **nodo a usar en el workflow es "Gmail"** (nativo de n8n), no "Send Email"/SMTP.
- La App Password generada en Google ya no se necesita para este camino.

## Plantilla del correo (basada en ejemplo real de Juan Aguayo, 16 jul 2026 — enviado manual,
## caso plataforma; sin los datos del cliente de ese ejemplo, solo la estructura)

- **Destino real (solo PROD, nunca en STG):** `metepecaten@qualitas.com.mx`
- **CC real (solo PROD, nunca en STG):** `laura.escamilla@hylant.com`,
  `Rafael.Rebollar@hylant.com`
- **En STG:** único destinatario `acer3500@gmail.com`, sin CC (evitar mandar pruebas a
  personas reales).
- **Subject — patrón fijo confirmado (20 jul), mismo para ambos casos:**
  `{clave_agente} Cotización {Plataforma Digital | Renovación}`
  - Plataforma digital: `27614 Cotización Plataforma Digital`
  - Renovación: `27614 Cotización Renovación`
- **Cuerpo (caso plataforma digital):**
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
  (cuerpo de renovación: mismo formato, primera línea pendiente de redactar — ver
  "Alcance" abajo).

## Alcance — decidido 20 jul: Plataforma Digital primero

Se construye el diseño completo (cuerpo de correo + rama de n8n) para **Plataforma Digital**
primero, porque el trigger de detección ya existe (regla de escalamiento en el system prompt
de Sonnet para Uber/Didi/taxi/flotilla — no requiere tocar el Intent Router). Renovación queda
documentado como siguiente paso, pendiente de: agregar el intent `renovacion` al clasificador
Haiku (hoy cae en `kb_query`) y redactar su cuerpo/asunto de correo.

## Flujo conversacional completo (caso Plataforma Digital) — decidido 20 jul

Hallazgo clave: la regla de escalamiento actual (Sonnet) corta la conversación de inmediato al
detectar Uber/Didi/taxi/flotilla, **antes** de que el bot pida el VIN — ese dato normalmente se
captura más adelante en el flujo normal (milestone `dio_vin`), no en el landing. Nombre,
teléfono y email SÍ están garantizados desde el landing/lead — solo falta el VIN.

Diseño: no es una rama de n8n desconectada de la conversación — es una **tool nueva del agente
Sonnet** (mismo patrón que la tool de búsqueda en la KB ya existente):

1. Bot detecta vehículo comercial (regla ya existente en el system prompt).
2. Si el VIN no está capturado todavía en la conversación, responde:
   `"En ese caso necesitaría por favor que me des tu VIN y así ofrecerte una cotización
   especial."`
3. Cuando el cliente da el VIN, Sonnet llama la tool nueva **`registrar_lead_metepec`**
   (parámetros: nombre, teléfono, email, vehículo, VIN, `motivo_entrega='plataforma_digital'`).
   Esta tool, internamente (sub-workflow n8n):
   - INSERT en `leads_metepec`
   - Envía el correo a METEPEC (nodo Gmail, credencial OAuth2 ya conectada) con asunto
     `27614 Cotización Plataforma Digital` y el cuerpo de la plantilla de arriba
4. Tras confirmar éxito la tool, Sonnet responde con el mensaje final de confirmación al
   cliente (pendiente de redactar — ver abajo).

**Mensaje final de confirmación al cliente** (post-envío, reemplaza el link fijo
`wa.me/525634352430`) — confirmado 20 jul:
`"Perfecto, ya tengo tus datos registrados. Uno de nuestros asesores especializados te va a
contactar directamente para darte seguimiento a tu cotización."`

## Diseño Plataforma Digital — completo (20 jul), listo para handoff a Agente n8n

Falta únicamente:
- Repetir el mismo setup de credencial OAuth2 en n8n **PROD** cuando se pase de STG a
  producción (cliente OAuth propio con la Redirect URI de PROD — no reutilizar el de STG).
