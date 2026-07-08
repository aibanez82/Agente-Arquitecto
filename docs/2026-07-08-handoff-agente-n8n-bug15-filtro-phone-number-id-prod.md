# Handoff (retenido) — Bug #15: filtro de aislamiento por `phone_number_id` en el workflow de PROD

> Del Arquitecto, 8 jul 2026 ~20:15 UTC. Mitigación, NO el fix de raíz — el Bug #15 sigue abierto del lado de Meta.
> **Estado: retenido por decisión de Alberto — NO entregado todavía al Agente n8n.** Copia canónica
> aquí en Agente-Arquitecto; se sacó la copia que se había puesto en `Agente-n8n/handoffs/`
> (commit `234b8d9`, revierte `cb63dc6`) hasta que Alberto decida activarlo.

## Contexto

El Bug #15 (Meta entrega el mismo mensaje al webhook de STG Y al de PROD) sigue **100% activo hoy**,
confirmado con evidencia definitiva: comparé por API el `wamid` completo de dos ejecuciones —
`STG exec 40` y `PROD exec 2210`, ambas de hoy (8 jul, ~17:49 UTC) — y es **idéntico**:

```
wamid.HBgNNTIxNTU1MTA3NDE0NBUCABIYFDNBOTBEQjVDMERCQTAyMDZEMjBGAA==
```

Mismo `from: 5215551074144` (número de prueba de Alberto), mismo
`phone_number_id: 1154577517746231` (el de **STG**), mismo `body: "Si"` — en las dos ejecuciones.
Además, comparando timestamps de inicio de ejecución en ambas instancias, el patrón es
**sistemático** (no solo hoy): cada mensaje a STG dispara una ejecución en PROD dentro de los
mismos ~60-90ms, para múltiples mensajes distintos.

**Ya se descartaron las 4 capas de configuración de Meta que podían explicarlo** (revisado hoy,
todas limpias): suscripción de webhook por WABA (`subscribed_apps` de la WABA de STG solo lista
`hyl-wai-stg`), acceso de activos de Business Manager (probado con un System User token scopeado
solo a la WABA de PROD — no puede leer el número de STG), y el webhook a nivel App tanto de
`hyl-wai-stg` como de `Aguayo IA` (ambos apuntan correctamente a su propio n8n). El mecanismo real
de la duplicación no es visible desde ninguna API/UI de Meta que hayamos revisado — se está
escalando a soporte de Meta Business en paralelo. Esto es indefinido en el tiempo, así que
la mitigación queda lista para activarse cuando Alberto lo decida.

## Qué se propone: guard de `phone_number_id` en el workflow de PROD

**Workflow:** `WhatsApp Insurance Quotation Bot` (prod, id `BtOaZm7WlZT-24V7hqCnF`).

**Dónde:** justo después del nodo trigger **`WhatsApp Message Trigger`** (`n8n-nodes-base.whatsAppTrigger`)
y ANTES de **`Session Context Builder`** (el código que hoy recibe la conexión directa del trigger).

**Qué insertar:** un nodo **IF** (nombre sugerido: `Phone Number Guard`) con esta condición:

```
{{ $json.metadata.phone_number_id }}  ==  1028815256982638
```

(`1028815256982638` es el `phone_number_id` REAL de PROD — confirmado el 8 jul vía Graph API,
número `+52 1 55 1246 5773`, "Cotizador Seguro de Autos". Verificado que el shape del payload del
trigger ya expone `metadata.phone_number_id` directamente — es lo mismo que ya lee
`Session Context Builder` como `inputData.metadata` — no hace falta tocar ningún parseo existente.)

- **Rama TRUE** → conectar a `Session Context Builder` (el flujo normal, sin cambios).
- **Rama FALSE** → conectar a un nodo **Code** nuevo, ligero, nombre sugerido `Foreign Phone Number - Ignored`,
  que solo devuelva algo como `{{ {ignored: true, phone_number_id: $json.metadata.phone_number_id, from: $json.messages[0].from} }}`
  y **no conectarlo a nada más** — la ejecución termina ahí. Esto da visibilidad en el listado
  de ejecuciones de n8n (para medir cuántas veces pega esto) sin tocar Postgres, sesión, ni el AI Agent.

## Por qué así y no de otra forma

- El trigger de PROD solo escucha `updates: ["messages"]` (confirmado en el JSON del nodo) — no
  hay que preocuparse por el shape distinto de eventos de `status` de mensajes.
- Insertar el guard ANTES de `Session Context Builder` significa que ningún nodo de sesión/Postgres/AI
  Agent se ejecuta para mensajes ajenos — cero escritura a BD de PROD para tráfico que no es de PROD.
- No resuelve la causa raíz (Meta sigue entregando el evento duplicado) — solo evita que PROD lo
  procese. STG seguirá recibiendo y respondiendo normal, sin cambios de su lado.

## Opcional (no bloqueante): guard espejo en STG

Si hay tiempo, aplicar el mismo patrón en el workflow de STG (`dNqtM20ij6ecZYAX`), filtrando por
`phone_number_id == 1154577517746231` — así ninguna instancia procesa tráfico de la otra, en
cualquier dirección. No es urgente porque el problema observado hasta ahora es unidireccional
(STG → PROD), pero cierra la simetría.

## Checklist de despliegue cuando Alberto lo active (gitflow de siempre)

1. Copiar/entregar este handoff a `Agente-n8n/handoffs/` (ya no está ahí — se retiró a pedido de Alberto).
2. Aplicar el cambio en el JSON del workflow en la rama `stg` de `Agente-n8n`.
3. Alberto revisa/importa a producción (n8n) siguiendo el flujo habitual — mismo patrón que Bug #10.
4. Validar: repetir un mensaje de prueba desde el número de STG y confirmar en el listado de
   ejecuciones de n8n que PROD ya NO dispara una ejecución con `Session Context Builder` corriendo
   (debería aparecer solo hasta `Phone Number Guard` → `Foreign Phone Number - Ignored`).
5. Confirmar que un mensaje real a PROD (`+52 1 55 1246 5773`) sigue funcionando normal.
6. Avisar al Arquitecto (a través de Alberto) cuando esté desplegado — reviso Postgres para
   confirmar que ya no aparece ruido de sesiones de STG en `n8n_chat_histories`/`whatsapp_sessions`
   de PROD.
