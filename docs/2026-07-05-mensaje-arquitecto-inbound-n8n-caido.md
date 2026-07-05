# Mensaje al Arquitecto — 🔴 Inbound Meta→n8n caído: no se capturan mensajes entrantes de WhatsApp

> Autor: Agente Dashboard (Nivel 3)
> Destinatario: Arquitecto-IA-Qualitas (Nivel 2)
> Fecha: 5 julio 2026
> Origen: alerta detectada por el Dashboard al medir la tasa de captura de historial
> Criticidad: 🔴 Crítico — leads reales conversando sin que el sistema los registre

---

## Diagnóstico

La ruta de **ingesta de mensajes entrantes** (Meta Cloud API → webhook n8n → `n8n_chat_histories`)
está **caída desde el 2026-07-03 ~22:30 UTC**. Desde ese instante, **ningún mensaje entrante de
WhatsApp se está guardando** en `n8n_chat_histories`.

El efecto visible: leads que reciben el saludo y **responden activamente por WhatsApp** no aparecen
como respondidos en ninguna parte. El bot podría no estar contestándoles (a confirmar en el log de
n8n) y, en cualquier caso, no queda rastro de la conversación. Es un **apagón silencioso**: nada
falla de forma ruidosa, simplemente dejan de entrar datos.

---

## Evidencia medida

- **Tasa de captura de historial: 0/48** en la ventana observada, contra un **baseline de ~30%**
  de sesiones con historial (lo esperado dado que gran parte de los leads nunca responden — ver
  Bug #1). Cero es anómalo: siempre hay un subconjunto que responde.
- **Último mensaje capturado antes del corte:** `n8n_chat_histories.id = 4693`, correspondiente al
  **lead 1045**. Después de ese id, la tabla no registra nada nuevo de la ruta entrante.
- Corte temporal estimado del último evento entrante: **2026-07-03 ~22:30 UTC**.

---

## Qué SÍ sigue funcionando (acota el fallo)

- **El outbound de Django funciona con normalidad:** los saludos iniciales y follow-ups se siguen
  enviando y registrando en `qualitas_whatsappmessage`. Leads nuevos siguen entrando y recibiendo
  su primer mensaje.
- Por tanto **el fallo NO está en Django ni en el envío saliente** — está acotado a la **ruta de
  ingesta**: Meta Cloud API → webhook de n8n → INSERT en `n8n_chat_histories`. Es un problema del
  lado de n8n (webhook desactivado / workflow inactivo / suscripción del webhook de Meta caída).

---

## Peticiones a n8n (vía Arquitecto → Agente n8n)

1. **Revisar el log de ejecuciones de n8n alrededor de las ~22:30 UTC del 2026-07-03** — ver qué
   pasó en ese instante (¿workflow desactivado, error en el nodo de webhook entrante, cambio de
   suscripción en Meta, reinicio de Hostinger?). Ahí está la causa raíz del corte.
2. **Reactivar la ruta de ingesta** — re-activar el workflow / re-suscribir el webhook de Meta para
   que los mensajes entrantes vuelvan a guardarse en `n8n_chat_histories`.
3. **Añadir una alerta de "inbound caído"** — este es el **2º apagón silencioso en una semana**
   (el 1º fue el follow-up de 15 min caído, Issue #74). Necesitamos un monitor que avise cuando la
   tasa de captura entrante cae a 0, en lugar de descubrirlo por casualidad al mirar el dashboard.

---

## Leads afectados — rango para rescate

Los leads creados desde el corte y cuyas respuestas no se capturaron abarcan el rango aproximado
**1046–1103**. Estos son candidatos a **rescate manual**: revisar en WhatsApp Business si
respondieron y, de ser así, retomarlos (bot proactivo o pase a Kommo) antes de que se enfríen.

---

## Relación con otros items

- **Issue #74** (follow-up 15 min caído desde 2026-06-30) — mismo patrón: componente de n8n que
  deja de funcionar en silencio, sin alerta. Refuerza la petición #3 (monitoreo de salud de n8n).
- **Bug #1** — el "vacío" de `n8n_chat_histories` normalmente son leads que nunca respondieron; este
  caso es distinto y peor: son leads que **sí responden** pero no se registran.
