# Plan de mejora de conversión de leads

> Autor: Arquitecto-IA-Qualitas · Fecha: 1 julio 2026 (v2 — validado con datos de producción)
> Destinatario: Alberto Ibáñez / Juan Aguayo (aguayo-co)
> Objetivo: aumentar el % de leads de Google Ads que terminan en póliza pagada.

> **Nota de versión:** la v1 de este documento afirmaba que el Bug #1 "estrangulaba" el motor
> de follow-up y que había que construir un "Agente Conversión" nuevo en n8n. **Ambas cosas eran
> falsas.** Al conseguir acceso a Heroku y consultar la BD de producción se comprobó que el motor
> de follow-up **ya existe, está activo y funciona** (envíos verificados con acuse de Meta). Este
> documento sustituye a esa versión con la foto real.

---

## Resumen ejecutivo

La idea de partida —perseguir a los leads que no responden al primer WhatsApp— **ya está
implementada y corriendo en producción** del lado de Django. No hay que construirla. Lo que sí
mueve la aguja de la conversión es otra cosa:

1. **El primer contacto:** el ~76% de los leads no responde *ni una vez* al mensaje inicial.
   Ahí está la fuga grande, y es un problema de copy/oferta, no de tecnología.
2. **La cadencia de follow-up:** hoy hay **un solo** recordatorio (a los ~15 min). Hay margen para
   toques adicionales (24h, 72h) respetando la ventana de Meta.
3. **La visibilidad:** el Dashboard no muestra los mensajes que Django envía, así que hoy es
   imposible auditar qué se le mandó a un lead sin entrar a la base de datos.

---

## Lo que YA existe y funciona (verificado en producción)

Django tiene un motor de follow-up de WhatsApp activo, disparado por un **management command vía
Heroku Scheduler**. Config vars relevantes (`hyl-wai-production`):

| Config var | Valor | Significado |
|---|---|---|
| `WHATSAPP_FOLLOWUPS_ENABLED` | `1` | Follow-up activo |
| `WHATSAPP_QUOTE_FIRST_FOLLOWUP_DELAY_MINUTES` | `12` | Primer recordatorio ~12-15 min tras el saludo |
| `WHATSAPP_FOLLOWUP_MAX_CANDIDATE_AGE_MINUTES` | `1440` | Solo persigue leads de ≤24h → **respeta la ventana de Meta** |

Plantillas HSM aprobadas por Meta en uso: `cotizacion_inicial_con_imagen`, `cotizacion_pdf_inicial`,
`cotizacion_followup_15m`.

**Evidencia de que funciona** (lead 952, cotización 2404, 30 jun 2026):

```
14:53:56  cotizacion_inicial_con_imagen  → sent  (wamid ...52C9)
15:10:56  cotizacion_followup_15m        → sent  (wamid ...97CA, Meta: "accepted")
```

Log de eventos (`qualitas_leadactionevent`):

```
14:53:56  whatsapp_initial_sent         source=django
15:10:54  whatsapp_followup_15m_queued  source=management_command
15:10:56  whatsapp_followup_15m_sent    source=management_command
```

El follow-up se envía correctamente a **no-respondedores**: de 59 follow-ups, **51 fueron a leads
que nunca respondieron** (comportamiento correcto).

---

## El funnel real (datos de producción, 1 jul 2026)

```
246 cotizaciones generadas
 → ~120 recibieron WhatsApp inicial     (whatsapp_initial_sent = 120)
 → 59 recibieron follow-up a los ~15m   (verificado con acuse de Meta)
 → ~48 leads respondieron de verdad     (~40% de reply sobre los contactados)
 → muy pocos llegaron a póliza pagada
```

Señales de calidad:
- **Solo 1 mensaje falló** de ~180 (error de parámetros de plantilla de Meta `#132018`). No es sistémico.
- **93% de las sesiones (`whatsapp_sessions`) están atascadas en `conversation_phase='greeting'`**
  (189 de 203) → confirma el **Bug #5**: ese campo es inservible como medida de avance.

---

## Reinterpretación del Bug #1 (importante)

El CLAUDE.md describe el Bug #1 como "n8n no guarda historial (89% de sesiones vacías)". Los datos
matizan esto:

- El número real hoy es **~76%** (154 de 203 sesiones sin historial), no 89%.
- **El historial existe casi solo cuando el humano responde** (48 de 49 sesiones con historial
  tienen mensaje humano). El contacto inicial lo manda **Django** (plantillas), no n8n; n8n solo
  entra cuando el cliente contesta.
- Por tanto, "76% de sesiones vacías" es en gran parte **"76% de leads que nunca respondieron"**
  — un problema de **conversión en el primer contacto**, no una pérdida masiva de datos.

**Consecuencia:** el Bug #1 sigue importando para la **analítica** (el Agente Mejoras Conversación
está ciego sobre esos leads y no puede analizar su copy), pero **NO frena el motor de follow-up**,
que decide a quién perseguir con su propia lógica del lado Django, no leyendo `n8n_chat_histories`.

---

## Las palancas reales de conversión (por prioridad)

| # | Palanca | Por qué | Dónde |
|---|---|---|---|
| 1 | **Copy/oferta del primer contacto** | El 76% no responde ni una vez. Es la fuga mayor. | Plantilla `cotizacion_inicial_con_imagen` (Meta) + lógica Django |
| 2 | **Más toques de follow-up** | Hoy solo hay uno (15 min). Añadir 24h y 72h con plantilla HSM puede recuperar leads que el toque único no alcanza. | Django (nuevas plantillas + scheduler) |
| 3 | **Visibilidad en el Dashboard** | Hoy no se ve qué se envió a un lead → imposible auditar/optimizar sin tocar la BD. | Repo `Dashboard_seguroautoqualitas` (ver spec aparte) |
| 4 | **Corregir Bug #1** | Desbloquea el análisis de copy del Agente Mejoras sobre el 76% ciego. Es analítica, no follow-up. | n8n |
| 5 | **Revisar sobre-envío** | 8 de 59 follow-ups fueron a leads que sí habían respondido. Verificar si se enviaron *después* de su respuesta (mala UX). | Django |

---

## Recomendación

El motor de "perseguir no-respondedores" ya existe y está verificado — **no construir nada nuevo
en n8n**. El foco debe ir al **primer contacto** (palanca 1), que es donde se pierde el 76% de los
leads, y a la **cadencia de follow-up** (palanca 2). En paralelo, cerrar el **gap de visibilidad
del Dashboard** (palanca 3) para poder medir y optimizar lo que ya se envía.

## Pregunta abierta para Juan

- ¿Cómo decide exactamente el management command a quién enviar el follow-up (qué define
  "candidato" y "ya respondió")? Confirmarlo cierra la última incógnita del modelo.
- ¿Está prevista una cadencia de más de un toque, o el `cotizacion_followup_15m` es el único?

> Nota no relacionada con conversión: existe un incidente activo de **emisión de pólizas** — el
> endpoint `/api/emitir-externo/` devuelve HTTP 400 de forma recurrente (1 jul 2026) con un
> mensaje genérico y sin loguear la causa. Se documenta y se traslada a Juan en un Issue aparte.
