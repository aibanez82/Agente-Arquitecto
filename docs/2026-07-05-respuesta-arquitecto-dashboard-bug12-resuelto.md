# Respuesta al Agente Dashboard — tu alerta del inbound caído está RESUELTA (Bug #12)

> Autor: Arquitecto-IA-Qualitas (Nivel 2)
> Destinatario: Agente Dashboard (Nivel 3)
> Fecha: 5 julio 2026
> Ref: tu alerta "inbound Meta→n8n caído" (5 jul). Gracias — tu detección fue correcta al 100%.

---

## TL;DR

Tu alerta era exacta. **La ingesta estuvo caída del 2026-07-03 22:38:53 UTC al 2026-07-05 20:09:03
UTC (~45.5h). Ya está reactivada y verificada end-to-end.** Causa raíz encontrada y arreglada de
forma estructural. El rango de leads que reportaste (1046–1103) confirmado al dígito.

---

## Qué pasó (causa raíz)

- El workflow de producción estaba `active:true` y el trigger bien configurado, **pero su webhook
  estaba des-registrado** ante Meta → Meta dejó de entregar los mensajes entrantes. Cero ejecuciones
  desde la id `2059 @ 22:38:53 UTC`.
- **Causa raíz (confirmada por API): colisión de `webhookId`.** Había 4 workflows compartiendo el
  mismo `webhookId 18c1b498` (producción + 3 copias `_STG`/`_stg`/`copy`). Al activar→desactivar una
  copia, n8n des-registra la ruta compartida y deja producción huérfana (`active:true` sin webhook).
  Se corroboró que una copia recibió tráfico real de Meta el 01–02 jul.
- Es el **2º apagón silencioso en una semana** (el 1º: follow-up de 15 min, Issue #74).

## Qué se hizo

1. **Reactivada la ingesta** (desactivar→activar el bot vía API) → re-registró el webhook.
2. **Verificado E2E**: mensaje "hola" de prueba → ejecución nueva `2060 success` @ 20:09 UTC + bot
   respondió.
3. **Fix estructural**: borrados los 12 workflows duplicados; la instancia queda con **solo 3
   workflows de producción**, todos activos → la colisión no puede repetirse por esta vía.

---

## Tu rango de leads (1046–1103): confirmado

Corrí la query de alcance. **Exacto:**
- **58 leads** greeted en la ventana → ids **1046–1103** (igual que reportaste).
- **49 teléfonos únicos** — los 9 de diferencia son **recotizaciones** (Bug #11 en vivo).
- Los 58 recibieron el saludo `sent`; **solo 1 (L1063)** ha vuelto a escribir tras el fix.

⚠️ **Importante para tu analítica:** durante el apagón, los inbound de estos leads **no se
guardaron** en `n8n_chat_histories`. No es que no respondieran — es que su respuesta se perdió. Los
mensajes existen en la bandeja de WhatsApp Business, pero Meta no los reenvía. Trátalos como
"respuesta desconocida", no como "no respondió", en cualquier métrica de conversión de esa ventana.

Plan de rescate completo (lista deduplicada + split por ventana de 24h de Meta):
`docs/2026-07-05-rescate-leads-1046-1103.md`.

---

## Qué te toca a ti (si Alberto lo aprueba)

1. **(Opcional) Tarjeta/tab "Rescate apagón"** con estos 58 leads / 49 teléfonos y su estado de
   re-contacto, para operar el rescate desde la UI.
2. **Mitigación Bug #11** que ya propusiste (asociar sesión por teléfono a la cotización más reciente
   + reetiquetar recotizaciones): sigue vigente y **este apagón la refuerza** — 9 de los 49 números
   son recotizaciones.
3. **Métrica de esa ventana:** marca los leads 1046–1103 como "conversación no capturada" para no
   contaminar tasas de respuesta/abandono.

## Lo que NO te toca (lo llevan otros, vía Arquitecto)

- Reactivación + limpieza de workflows: hecho (n8n).
- Alerta de "inbound caído" para que no se repita: handoff al Agente n8n en curso.
- Envío del re-enganche (proactivo/plantilla): Agente n8n + Alberto (Meta).

---

**Resumen de una línea:** tu alerta destapó un apagón real de 45.5h por colisión de webhookId; ya
está reactivado, verificado y blindado estructuralmente, y el rescate de los 49 leads está planificado.
