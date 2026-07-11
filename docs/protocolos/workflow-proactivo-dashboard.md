# Workflow proactivo — mensajes desde Dashboard

Detalle movido desde `CLAUDE.md`, sección "n8n workflow — estructura interna", al adelgazar el archivo (10 jul 2026).

**Segundo workflow — mensajes proactivos desde Dashboard:**

```
Webhook POST /webhook/proactive-wa-message
  { phone_number, message, session_id }
    ├── INSERT n8n_chat_histories
    │     { type: "ai", content: message, tool_calls: [],
    │       additional_kwargs: {}, response_metadata: {},
    │       invalid_tool_calls: [] }
    └── WhatsApp Business Cloud → Send message
          phoneNumberId: 1028815256982638
          credential: WhatsApp Send Message Hylant Account
```

**Reglas del workflow proactivo:**
- Si el INSERT falla → el WhatsApp NO se envía (stop-on-error)
- `phone_number` y `session_id` deben empezar con `52` (México)
- Si `last_activity > 24h` en `whatsapp_sessions` → Meta puede rechazar el mensaje (ventana cerrada)
- El mensaje se guarda como tipo `ai` para que Claude mantenga contexto en la siguiente respuesta del lead
