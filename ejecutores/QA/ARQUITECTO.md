# ARQUITECTO.md — Contexto del Arquitecto para el Agente QA

> Este archivo explica al Agente QA quién es el Arquitecto, cómo se comunican,
> y qué contexto del sistema necesita para hacer su trabajo correctamente.
> Actualizado: 27 junio 2026.

---

## Quién es el Arquitecto

El **Arquitecto-IA-Qualitas** es el agente de Nivel 2 del ecosistema Insurmind.

- **Repo:** `aibanez82/Agente-Arquitecto`
- **Fuente de verdad:** `CLAUDE.md` en ese repo
- Tiene visión transversal de todos los sistemas: Django, n8n, BBDD, Dashboard, GA4, Meta/WhatsApp
- **Diagnostica y planifica. No ejecuta.**
- Cuando detecta un bug cross-sistema, entrega un plan exacto de qué tocar y en qué archivo

---

## Tu rol como Agente QA (Nivel 3)

Eres un agente **ejecutor**. Recibes planes validados del Arquitecto a través de Alberto.

**Tu trabajo:**
- Correr tests end-to-end del funnel completo
- Simular conversaciones de WhatsApp con leads de prueba
- Verificar que los leads de prueba aparecen en el tab "Test" del dashboard (no en el principal)
- Verificar que las conversaciones se guardan correctamente en `n8n_chat_histories`
- Reportar anomalías hacia arriba (a Alberto → Arquitecto), no intentar diagnosticarlas tú solo

**Regla crítica:** Nunca coordines directamente con otros agentes ejecutores (Conversión, etc.). Todo pasa por el Arquitecto, a través de Alberto.

---

## Protocolo de comunicación

```
Tú detectas algo anómalo en un test
          ↓
Lo reportas a Alberto con evidencia (query SQL, log, captura)
          ↓
Alberto lo lleva al Arquitecto
          ↓
El Arquitecto diagnostica la causa raíz y entrega un plan
          ↓
Alberto te trae el plan
          ↓
Tú ejecutas y reportas el resultado
```

---

## El sistema que testeas

### Funnel completo
```
Google Ads → Landing → Django (Heroku) → n8n WhatsApp agent
→ cliente → póliza emitida → pago confirmado
```

### Stack
| Componente | Tecnología | URL / repo |
|---|---|---|
| Backend | Django + Heroku | `aguayo-co/HYL-WAI` |
| Dashboard | Next.js + Vercel | `aibanez82/Dashboard_seguroautoqualitas` |
| WhatsApp bot | n8n (Heroku) | Exportado como JSON |
| Base de datos | Heroku Postgres | Compartida Django + n8n |

### Tablas clave en Postgres
| Tabla | Qué contiene |
|---|---|
| `qualitas_lead` | Estado del lead (`estado`), canal, fechas |
| `qualitas_cotizacion` | Datos del auto, email, teléfono, CP, precio |
| `whatsapp_sessions` | `conversation_phase` — **tiene bug activo, no confiar** |
| `qualitas_polizaemitida` | Número de póliza, `estatus_pago`, precio |
| `n8n_chat_histories` | Hitos reales de conversación WA — **fuente fiable** |
| `NumeroPruebaWhatsapp` | Teléfonos de prueba de Juan Aguayo |

### JOINs correctos
```sql
-- qualitas_cotizacion → qualitas_lead
JOIN qualitas_cotizacion c ON l.cotizacion_id = c.id   -- NO c.lead_id

-- whatsapp_sessions → qualitas_cotizacion
JOIN whatsapp_sessions ws ON ws.quotation_id = c.id

-- Columnas: canal_atencion (no canal), codigo_postal (no cp)
```

---

## Bugs conocidos que afectan tus tests

### Bug 1 — n8n_chat_histories casi siempre vacío (crítico)
Solo el 10.5% de sesiones con `whatsapp_session` tienen registros en `n8n_chat_histories`.
El 89% restante no tiene historial. Cuando un test de historial falle, este bug es la causa probable.

**Query de verificación:**
```sql
SELECT
  ws.session_id,
  EXISTS (
    SELECT 1 FROM n8n_chat_histories WHERE session_id = ws.session_id
  ) AS tiene_historial
FROM whatsapp_sessions ws
JOIN qualitas_cotizacion c ON ws.quotation_id = c.id
JOIN qualitas_lead l ON l.cotizacion_id = c.id
WHERE l.fecha_creacion >= NOW() - INTERVAL '7 days';
```

### Bug 2 — Prefijo 57 en session_id (afecta leads de prueba de Juan)
El `session_id` en `whatsapp_sessions` a veces tiene prefijo `57` (Colombia) en lugar de `52` (México).
Afecta solo los leads de prueba cuyo teléfono está en `NumeroPruebaWhatsapp`.

```
Esperado: 523107696237   (prefijo México)
Real:     573107696237   (prefijo Colombia)
```

### Bug 3 — TEST_EMAILS no filtrados en n8n
Los leads de prueba reciben mensajes WhatsApp reales. Para tests, verifica que el email
esté en la lista de `TEST_EMAILS` de `lib/constants.js` del Dashboard.

Emails de prueba activos:
```
rarefe@hotmail.com, acer3500@gmail.com, juan.aguayo@aguayo.co,
jandersongomezfranco@gmail.com, hector.silvar@yahoo.com.mx,
juaguayo@yahoo.com, juaguayo@gmail.com, marketinghylant@e-broking.com,
alberto@insurmind.ai, oilycoyote@hotmail.com
```

### Bug 4 — conversation_phase stuck en greeting
`whatsapp_sessions.conversation_phase` no se actualiza correctamente en Django.
**Nunca uses `conversation_phase = 'greeting'` como indicador de que no hubo conversación.**
Verifica siempre en `n8n_chat_histories`.

### Bug 5 — 4 leads reales sin whatsapp_session
IDs 837, 834, 810, 802 — nunca recibieron mensaje de WhatsApp aunque tienen teléfono válido.
Si encuentras leads similares en tests, repórtalo al Arquitecto.

---

## Leads de prueba (para tus tests)

Usa siempre los emails de la lista `TEST_EMAILS` para leads de prueba.
El teléfono de Juan Aguayo está en `NumeroPruebaWhatsapp` — los leads con ese número
tienen el bug del prefijo `57` (Colombia).

**Verificar en dashboard:** Los leads de prueba deben aparecer únicamente en el tab "Test"
del dashboard (`https://dashboard-seguroautoqualitas.vercel.app`), nunca en el tab principal.

---

## Contexto de seguridad

- El webhook de n8n tiene un token hardcodeado en `views.py` de Django como valor por defecto — pendiente rotar en variables de entorno de Heroku
- Nunca compartir tokens, keys o credenciales en el chat
- Las variables de entorno viven en Heroku (Django) y Vercel (Dashboard)
