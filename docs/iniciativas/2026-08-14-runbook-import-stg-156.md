# Runbook — Import de los workflows de `#156` en la instancia n8n STG

**Fecha:** 14 ago 2026 · **Autor:** Arquitecto · **Aplica:** Alberto (único con acceso a la instancia)
**Autorización:** GO de Juan en `#156` (14 ago): *«GO para importar en STG, con el gate de cobertura
9/9 en STG»*. Sin condiciones añadidas.

**Paso 5** del plan. **Esto NO enciende Descuentos** — el módulo sigue apagado por base de datos y por
`WHATSAPP_CHECKPOINT_FOLLOWUPS_ENABLED=false`. Encenderlo es el paso siguiente y va aparte.

---

## 0. Antes de tocar nada

**El punto de retorno ya existe y está en git:** `Agente-n8n:workflows/vivo-stg-2026-08-14/`, exportado
de la instancia esta mañana y verificado. **Si algo sale mal, se reimportan esos cuatro ficheros y la
instancia vuelve a como está ahora.** No hace falta capturar nada nuevo.

> **Lo que hace este paso delicado:** tres de los cuatro **sustituyen** workflows vivos porque
> comparten `id`. No es «añadir»: es reemplazar el bot principal de STG, Retomar y Payment.

## 1. Qué se importa, y en qué orden

| # | Fichero (`Agente-n8n@stg`) | `id` | Efecto | Nodos |
|---|---|---|---|---|
| 1 | `workflows/s1/payment-candidato.json` | `Ob5JYHYbc23SLp0A` | **sustituye** Payment | 9 → 19 |
| 2 | `workflows/s1/retomar-candidato.json` | `nYRaRzU83qDLuEWI` | **sustituye** Retomar | 12 → 31 |
| 3 | `workflows/s1/main-candidato.json` | `dNqtM20ij6ecZYAX` | **sustituye** el bot principal | 132 → 249 |
| 4 | `workflows/s1/discount-application-worker-candidato.json` | `issue156-…-v1` | **crea** uno nuevo | 59 |

**El orden importa por riesgo, no por dependencia:** los tres primeros son independientes entre sí, y
el bot principal va **el último de los que sustituyen** porque es el que más tráfico mueve — si algo
falla en Payment o Retomar, te enteras antes de tocar el camino principal.

**Los cuatro entran con `active: false`**, que es como están en el repo. **Verifícalo en la pantalla de
import antes de confirmar**: si alguno apareciera activo, párate.

## 2. Los `webhookId`, que es la trampa conocida

Los tres que sustituyen conservan su `id` de workflow, pero **n8n genera `webhookId` nuevos al crear
nodos webhook**. Ya nos pasó en la ventana de Atención Humana: *crear → anotar → cablear → activar*.

Después de importar, **comprueba que las URLs de los webhooks siguen siendo las mismas**:

- Retomar: `…/webhook/proactive-wa-message`
- Payment: el que use Django para `enviar_webhook_whatsapp`
- Atención Humana **no se toca** en este import

**Si alguna URL cambió, hay que recablear al consumidor** —Django para Payment, Dashboard para
Retomar— **antes de activar**. Una URL que cambia en silencio es un webhook que deja de llegar.

## 3. Verificación después de cada import

En la instancia:
- el workflow aparece con el **número de nodos esperado** (19 / 31 / 249 / 59);
- sigue **inactivo**;
- en el bot principal, que **`Cambiar Cotizacion` y `Listar Cotizaciones` estén ahí** y colgando del
  `AI Agent` y del `RAG IA Agent` — es lo que casi se pierde y lo que quiero ver con tus ojos, no solo
  en el JSON.

Yo acredito por mi lado lo que se pueda leer desde la base y desde el repo.

## 4. Activación — **decisión separada, no parte de este runbook**

Importar deja los cuatro inertes. Activarlos es otro momento y otro criterio, y **el worker es el que
hay que mirar con más cuidado**: trae `Discount Poll Schedule`, un `scheduleTrigger` **de 1 minuto**
que consulta Django, escribe en Postgres y **sube y envía PDFs por WhatsApp**. Con el módulo apagado no
hará nada, pero que su activación sea una decisión y no un efecto lateral del import.

Orden sugerido cuando toque: los tres que sustituyen primero (recuperan el servicio que ya daban), el
worker en último lugar.

## 5. Si algo sale mal

1. **Para.** No sigas con el siguiente fichero.
2. **Rollback:** reimporta el fichero correspondiente de `workflows/vivo-stg-2026-08-14/`. Vuelve
   exactamente al estado de esta mañana.
3. Dime qué workflow, qué nodo y qué decía el error — con eso leo el candidato y el vivo y te digo
   dónde está la diferencia.

## 6. Lo que este paso NO hace

Encender Descuentos (`module_enabled`, las dos fases y el `DiscountTrigger` siguen apagados) · activar
ningún workflow · tocar `WHATSAPP_CHECKPOINT_FOLLOWUPS_ENABLED` · tocar PROD · tocar Atención Humana.
