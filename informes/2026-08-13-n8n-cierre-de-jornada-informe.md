# Cierre de jornada — Agente n8n · lo entregado y lo que queda

**13 ago 2026 · Agente n8n.** Resumen pedido por Alberto. No hay tarea dentro: es estado.

---

## 1. Lo que está en producción y funcionando

| | Qué | Cerrado por |
|---|---|---|
| **Esquema** | 7 columnas de control + `phone_number` a 32 + `wamid` con su índice único parcial, en `whatsapp_sessions`, su archive y `n8n_chat_histories` | ventana aplicada por Alberto, acreditada por ti |
| **Retomar Conversación** | promoción 1 | **comportamiento**: proactivo real recibido en el teléfono, fila `10673` |
| **Multicotización** | promoción 2 — las cuatro piezas | pendiente de tu acreditación y de la conversación real |
| **Atención Humana** | promoción 3 — workflow `B5ihE5xHg8bjeesl` **inactivo** + bot parcheado | pendiente de UI, activación y Dashboard |

**El bot pasó de 113 a 119 nodos en dos ventanas**, sin perder ni uno y con los 7 `webhookId` intactos en
las dos. `Phone Number ID Guard` sigue en su sitio y `registrar_lead_metepec` nunca cruzó.

Estado vivo de la instancia, ahora mismo:

```
B5ihE5xHg8bjeesl   active=False  Atencion Humana          ← creado inactivo a proposito
96XfJZcwvlHnVJLko3G8-  active=True   Retomar Conversacion
BtOaZm7WlZT-24V7hqCnF  active=True   WhatsApp Insurance Quotation Bot   (119 nodos)
disvKr7iVhnNnefuiqJbJ  active=True   ...Payment Confirmation
ZFjVEFPvibRgK5FG   active=False  WhatsApp Insurance Quotation Bot copy  ← el huerfano que reporte
```

## 2. Lo entregado, por artefacto

**Migraciones** (`fix/fase0-sessions-paridad-prod@c5f0464`)
- `001` paridad de sesiones — **aplicada**. 42/42 gates, incluida la acreditación del rollback
  ejecutándolo de verdad, y el gate de `ctid` que demuestra que no hay reescritura de tabla.
- `002` `dashboard_outbound_dispatch` — 14/14, **escrita y no aplicada**, dos ficheros por modo.

**Guiones de promoción** (`docs/fase4-preparacion@4f0d8f0`) — tres, todos con la misma disciplina: cuerpo
construido desde el workflow vivo, retrato con fallo en cerrado por `versionId`, dos banderas para
escribir, y verificación posterior. El de Multicotización además **mide la paridad contra la base en el
momento** y aborta si no es 0 en las dos direcciones.

**Análisis** — la clasificación de los 39 nodos (que reprodujo tu medición del 10 ago: 56 − 17 de
credencial = 39), la medición del subconjunto mínimo de S1, y la respuesta de las 0 filas con cuatro
medidas independientes.

**#156** (`feature/issue-156-conversation-control-n8n@383f6c2`) — fixture corregido con la medición en
vivo, en commit propio. **La rama no se ha tocado desde entonces** y no la toco: sigue esperando dictamen.

`stg` y `main` **intactos** en todo el día.

## 3. Lo que queda — mío

1. **El `DROP INDEX`** del duplicado sobre `whatsapp_sessions.quotation_id`. Es lo último del viaje y no
   tiene prisa. **No lo he empezado.**
2. **El export de `main`**: ya no describe a PROD en el bot ni en Retomar, así que `detect-drift.py` dará
   drift en esos dos destinos, correctamente. No lo he tocado porque el handoff de la Fase 4 prohíbe
   empujar a `main` — hace falta tu OK o declararlo como drift esperado.

Y una cosa que **no** he empezado y no empezaré sin que lo pidas: el plan B de `#159`, detectar por mi
lado que el `quotation_id` cambió respecto al claim.

## 4. Lo que queda — de otros

| Qué | De quién |
|---|---|
| Comprobar en la UI que los tres webhooks muestran la credencial, y **activar** | Alberto |
| Dashboard apuntando a `iniciar` y `liberar` | Agente Dashboard |
| La conversación real que cierra Multicotización | Alberto |
| Aplicar la `002` | Alberto, cuando decidas |
| `HYL-WAI#159` — que Django limpie `human_takeover` al reapuntar | Juan |
| Acreditar las promociones 2 y 3 | tú |

## 5. Dos cabos que prefiero dejar dichos

**La `002` sigue sin aplicar y el workflow ya vive en producción** con tres nodos que referencian
`dashboard_outbound_dispatch`. Mientras `enviar` no se cablee no se ejecutan — es lo acordado — pero la
trampa queda armada y el síntoma no apuntaría a hoy.

**El `id` de la credencial va declarado a mano** en el guion, porque la API no expone `GET /credentials`.
Es lo único de la promoción 3 que no se puede verificar por máquina, y por eso la comprobación por
interfaz **antes** de activar no es una formalidad.

## 6. Y el balance de errores, que hoy es parte del trabajo

Cinco míos, todos encontrados y corregidos dentro de la jornada:

1. **Un guard más ancho que su criterio** gritó «REVERTIR» sobre una promoción correcta (`WA Config STG`
   en un comentario). Arreglado buscando nodo o referencia, no texto.
2. **Deduje la cabecera de la credencial** de la hermana de Retomar (`Authorization`) cuando la propia
   estaba escrita en tu reporte de Fase 6.5 (`X-Operator-Auth`). La etiqueté como inferencia, que es lo
   que salvó el día.
3. **Dije que no tenía acceso a la base de PROD** sin abrir el fichero, y te hice medir algo que podía
   medir yo.
4. **Comparé el criterio nuevo contra medio criterio viejo** y la fórmula sobrecontaba 23 filas.
5. **Mis tres guiones mutaban el «antes»** que usan para verificar, por copiar referencias en vez de
   valores. Lo destapó un `113 -> 117` que salía `117 -> 117`.

Los cinco son la misma forma, que es la que tú nombraste mejor que yo: **el fallo no está en el
razonamiento, está en contra qué se compara.** Y en los cinco lo que funcionó no fue no equivocarse: fue
medir antes de actuar y decirlo antes de que lo encontrara otro.

Añado el que me llevo como regla propia: **antes de escribir «no puedo», mirar.**
