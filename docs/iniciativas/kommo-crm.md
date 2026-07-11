## Kommo CRM — integración en curso

Kommo es el CRM de escalada humana del ecosistema. Ya está parcialmente integrado: cuando el bot decide derivar, envía un mensaje WA al lead con un link a Kommo.

**Plan activo:** Base ($15/user/mes). Incluye API v4 completa.

**Feature en diseño — botón "Pasar a Kommo" en el Dashboard:**

Caso de uso: Alberto ve en el dashboard un lead caliente que no está respondiendo al bot y quiere intervenir manualmente como humano.

Flujo propuesto:
```
Modal del lead en Dashboard
    ↓ click "Pasar a Kommo"
    ↓
Next.js → Kommo API v4 POST /leads/complex
    ↓
Crea contacto + lead en Kommo con:
  - Nombre (si el bot ya lo capturó)
  - Teléfono
  - Vehículo + precio cotizado
  - Nota con link a conversación WA
    ↓
Alberto atiende el lead directamente desde Kommo
```

**Pendiente para implementar:**
- Subdominio Kommo de Alberto
- API token Kommo (Ajustes → Integraciones → API → Token largo)
- Nombre del pipeline y etapa destino en Kommo
- Agregar `KOMMO_API_TOKEN` y `KOMMO_SUBDOMAIN` a Vercel

**Repo donde se implementa:** `aibanez82/Dashboard_seguroautoqualitas`
**Archivo clave:** nuevo endpoint `pages/api/kommo-lead.js` + botón en modal del dashboard
