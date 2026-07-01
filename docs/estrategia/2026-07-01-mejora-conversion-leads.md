# Plan de mejora de conversión de leads

> Autor: Arquitecto-IA-Qualitas · Fecha: 1 julio 2026
> Destinatario: Alberto Ibáñez / Juan Aguayo (aguayo-co)
> Objetivo: aumentar el % de leads de Google Ads que terminan en póliza pagada,
> con foco inicial en recuperar leads que reciben mensaje de WhatsApp y no responden.

---

## Resumen ejecutivo

La idea de partida es correcta: **perseguir a los leads que reciben el primer mensaje de
WhatsApp y no contestan**. Pero "no contesta" no es un solo grupo, y antes de montar un motor
de reintentos hay que descartar que una parte de esos silencios sean en realidad **mensajes que
nunca se entregaron** por un bug conocido de formato de teléfono.

La recomendación es **medir la fuga real por fase antes de construir nada**, y arrancar en
paralelo el trámite de aprobación de plantillas de WhatsApp con Meta, que es el paso con más
latencia externa.

---

## 1. "No contesta" son tres grupos distintos

No todos los leads silenciosos necesitan lo mismo. Se distinguen leyendo los hitos reales de la
conversación en `n8n_chat_histories`:

| Grupo | Cómo se detecta | Temperatura | Qué necesita |
|---|---|---|---|
| **1. Nunca respondió** | AI envió saludo, `human_msg_count = 0` | Frío | Verificar entrega + revisar copy del primer mensaje |
| **2. Respondió y se calló a mitad** | `has_responded = true` pero atascado en `confirmo_cobertura` / `dio_datos_personales` / `dio_vin` / `dio_domicilio` | Caliente | Nudge con **el dato exacto que falta** ("solo me falta tu número de serie") |
| **3. Llegó a póliza, no pagó** | `poliza_emitida_wa = true` sin `estatus_pago = 'PAGADO'` | Muy caliente | Reenviar link de pago |

Los grupos 2 y 3 son leads calientes ya trabajados: recuperarlos es el retorno más alto por
mensaje enviado. El grupo 1 puede ser el más numeroso, pero es el más frío y el más contaminado
por el problema de entrega descrito abajo.

---

## 2. Dos bugs conocidos pueden estar frenando la conversión *antes* del follow-up

### Bug #2 — prefijo de país incorrecto (responsabilidad Django)

Algunos leads se registran con `session_id` / teléfono con prefijo **`57` (Colombia)** en lugar
de **`52` (México)**. Con el número mal formado, **Meta no entrega el mensaje**. Esos leads no
son "fríos": son mensajes que nunca llegaron. Perseguirlos con más mensajes al número incorrecto
no sirve de nada.

> **Acción para Juan:** cuantificar cuántos leads tienen prefijo de país incorrecto y corregir
> la normalización del teléfono en Django antes del webhook a n8n. Si el porcentaje es alto, este
> es el arreglo de conversión con mejor retorno de todos — y no requiere ningún motor de
> reintentos.

### Bug #1 — 89% de sesiones sin historial (responsabilidad n8n)

n8n no está guardando el historial de conversación en `n8n_chat_histories` en el 89% de los
casos. Esto nos deja **parcialmente ciegos**: sin historial no se puede saber con fiabilidad en
qué fase se cayó cada lead. Un perseguidor "inteligente" (que sabe qué dato falta) depende de
tener este dato; un perseguidor "tonto" (mismo mensaje a todos) funciona sin él, pero convierte
mucho menos.

---

## 3. La restricción que define toda la arquitectura: la ventana de 24 h de Meta

WhatsApp Business no permite enviar texto libre a un usuario fuera de una ventana de 24 h desde su
última actividad:

- `last_activity < 24 h` → se puede enviar **texto libre** (el bot de Claude improvisa la respuesta).
- `last_activity > 24 h` → Meta **rechaza** el texto libre. Solo se pueden enviar **plantillas
  HSM pre-aprobadas** por Meta.

Como perseguir a un lead casi siempre ocurre >24 h después, el motor de reintentos **depende de
tener plantillas aprobadas**. Sin ellas, el follow-up falla justo cuando más se necesita. El
trámite de aprobación con Meta tiene latencia (horas o días), por eso conviene arrancarlo cuanto
antes.

Se necesitan al menos 3 plantillas:
1. Nudge genérico de reactivación.
2. "Solo falta un dato" (parametrizable con el dato pendiente).
3. Reenvío de link de pago.

---

## 4. Motor de reintentos propuesto (Agente Conversión)

Cadencia sugerida, con escalada a humano en lugar de spam infinito:

```
Mensaje inicial enviado
   │
   ├─ +1 h   → si sigue en silencio y DENTRO de ventana 24 h → recordatorio texto libre
   │
   ├─ +24 h  → plantilla HSM (según grupo: nudge / falta-dato / pago)
   │
   ├─ +72 h  → segunda plantilla HSM
   │
   └─ sin respuesta → escalar a humano vía botón "Pasar a Kommo" en el Dashboard
                       (o marcar el lead como perdido)
```

Reutiliza el workflow `Retomar Conversacion.json` ya existente como base (verificar si soporta
plantillas HSM o solo texto libre) y el botón "Pasar a Kommo" para el traspaso a atención humana.

---

## 5. Plan de acción por orden de prioridad

| # | Acción | Responsable | Bloquea a |
|---|---|---|---|
| 1 | **Medir la fuga por fase** con los hitos de `n8n_chat_histories` (Agente Mejoras Conversación) — cuántos leads en cada grupo | Alberto / Agente Mejoras | Diseño del motor |
| 2 | **Cuantificar Bug #2** (prefijo de país) — % de leads con teléfono mal formado | Juan (Django) | Nada — arreglo directo |
| 3 | **Diseñar y enviar a aprobación las 3 plantillas HSM** con Meta | Alberto | Motor de reintentos |
| 4 | **Corregir Bug #1** (historial vacío) para segmentación fiable | n8n | Perseguidor "inteligente" |
| 5 | **Construir el Agente Conversión** con la cadencia de arriba | Ejecutor Nivel 3 | — |

---

## Recomendación final

El instinto de perseguir a los no-respondedores es acertado, pero **el orden importa**:

1. Medir la fuga real por fase (paso 1) para saber dónde está el agujero grande.
2. Descartar el Bug #2 (paso 2) — si buena parte de los "no contestan" son mensajes que nunca se
   entregaron, arreglar la normalización del teléfono convierte más que cualquier campaña de
   reintentos, y es más barato.
3. Recién entonces construir el motor de reintentos, con las plantillas de Meta ya aprobadas.

Perseguir leads sobre datos ciegos (Bug #1) y con números mal formados (Bug #2) desperdicia
presupuesto de mensajes de Meta y da métricas engañosas. Primero visibilidad y entrega, luego
automatización.
