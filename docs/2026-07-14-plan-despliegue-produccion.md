# Plan de despliegue a producción — 14 jul 2026

## ✅ Resultado — verificado en vivo (14 jul, tarde)

**Track B se portó a PROD** — workflow `BtOaZm7WlZT-24V7hqCnF` actualizado 14:47 UTC (08:47 CDMX),
70 nodos, activo. **Sin que quedara registro aquí de que el gate (6ª prueba, issue #38) se cerró
antes de portar** — desviación del plan, dejarla explícita para no repetirla.

Verificación en vivo del Arquitecto: ejecuciones del workflow desde el port en adelante, todas
`status=success`. 4 leads creados el 14 jul (IDs 1302-1305, canales LANDING/WHATSAPP) — los 4 con
email en `TEST_EMAILS` del Dashboard (Juan probando, QA, `rarefe@hotmail.com`), por eso el
Dashboard mostraba "0 leads + 4 test" y generó una alarma falsa de "no llegan leads". **Alberto
confirmó el mismo día que sí llega todo bien a PROD.**

**Track A (Django shadow) NO se desplegó** — `hyl-wai-production` sigue en el release de marzo,
sin release nuevo el 14 jul. Sigue pendiente, en paralelo, sin bloquear nada.


> Origen: Juan pide subir "todo lo de hoy" a producción. Su recomendación (sección F de su
> reporte) habla de desplegar Django en `shadow` con monitoreo 24-72h y no pasar a `dual` hasta
> confirmar el workflow de n8n actualizado en staging.
> **Esto en realidad son 2 despliegues independientes, con riesgo muy distinto — hay que
> separarlos, no tratarlos como un solo "subir todo".**

## Los 2 tracks

### Track A — Django: conversation_id a PROD, en `shadow`

Esto es lo que Juan describe. Bajo riesgo real: `shadow` no cambia ningún comportamiento visible
(confirmado en el código — `CONVERSATION_ID_SESSION_MODES = {"dual", "enforced"}`, `shadow` no
está en esa lista). Django empieza a guardar `conversation_id` internamente, nada más.

**Pasos:**
1. Juan mergea `stg` → `main` en `HYL-WAI`, despliega `hyl-wai-production`.
2. Juan corre la migración `0033_whatsapp_conversation_id_phase2` contra la BD de PROD (misma
   migración aditiva/defensiva que ya corrió limpio en STG).
3. Config var en `hyl-wai-production`: `WHATSAPP_CONVERSATION_ID_MODE=shadow`. **No tocar
   `WHATSAPP_TEMPLATE_QUOTE_INITIAL_HAS_BUTTON`** — sigue en `false` en PROD, eso es una decisión
   aparte (activar botones) que nadie ha pedido todavía.
4. **No pasar a `dual` en PROD** — de acuerdo con Juan. Y hay una razón técnica adicional que él
   no menciona: el payload v2 real (`dual`) **nunca se probó de punta a punta hoy** — todas las
   pruebas de conversation_id en STG fueron con Django en `shadow` (payload v1). La ruta `dual` de
   n8n (`Resolve Session` resolviendo por `conversation_id`) está verificada por partes, pero no
   con un click real de botón v2 real. No pasar a `dual` en ningún ambiente todavía, ver Track B.

**Riesgo:** bajo, reversible con un cambio de config var.

### Track B — n8n: portar el workflow completo de STG a PROD

Esto es lo grande y lo que de verdad concentra el riesgo. El workflow de PROD (`BtOaZm7WlZT-24V7hqCnF`)
no se ha tocado en todo el día — todo vive solo en `dNqtM20ij6ecZYAX` (STG). Portar "todo lo de
hoy" significa: conversation_id (3 bugs), M19 + 6 adendas, M1 completo + 8 nodos extra, M20, M21,
persistencia incremental (4 tools nuevas), fix de `.item`→`.first()`, fix de `Restore Context
After Phase Update`, fix de edad máxima. Es el diff más grande que se ha portado a PROD de una
sola vez.

**A diferencia del Track A, esto SÍ cambia comportamiento real para clientes reales de
inmediato**, sin importar el flag de Django — M19/M1/M20/M21/persistencia no dependen de
`shadow`/`dual`, se activan solos en cuanto el workflow esté activo en PROD.

## Gate obligatorio antes de portar — no negociable

**No portar todavía. Falta cerrar 1 cosa:** la 6ª prueba (issue #38 — reconocer respuestas cortas
tipo homoclave) está commiteada pero **sin confirmar contra una ejecución real todavía**. Es la
única pieza de hoy sin verificación de punta a punta. En cuanto Alberto la corra y yo la verifique,
este gate queda cerrado.

## Riesgos conocidos que SÍ se aceptan portar (no son bloqueantes, pero deben quedar explícitos)

- **`policy_data` sigue roto** (confirmado, sin fix definitivo). No es crítico — Django tiene su
  propio registro real de la póliza vía `api_emitir_externo`, y `conversation_phase =
  'payment_pending'` ya cubre la necesidad de negocio. Se acepta portar con esto conocido, no
  oculto.
- **`captured_data` depende de que el LLM llame la tool correctamente** — no es 100% determinístico.
  Aceptable para lo que se usa hoy (nada de lógica de negocio dura corre sobre esto todavía).
- **Issue #37 solo tiene la mitad de n8n resuelta** (edad máxima). La mitad de Django
  (`api_emitir_externo` sin conectar a la validación existente) sigue pendiente — no bloquea este
  despliegue, es una mejora aparte.

## Pasos técnicos del Track B (para Agente n8n, una vez cerrado el gate)

1. **Congelar STG** — nadie sigue probando/cambiando el workflow mientras se prepara el port, para
   portar un estado conocido y quieto.
2. **Diff estructural completo STG vs PROD**, nodo por nodo — no asumir que "aplicar el JSON de
   STG tal cual" es seguro. En particular:
   - **Credenciales**: STG usa `Postgres STG`, `Anthropic STG`, `WhatsApp Test` — el port a PROD
     tiene que recablear a las credenciales de PROD (`Postgres account`, `Anthropic Hylant
     Account`, `WhatsApp Send Message Hylant Account`). Si esto se pasa por alto, PROD queda
     escribiendo en la BD de STG o mandando WhatsApps de prueba a números reales — el mismo tipo
     de bug que ya causó los issues #15/#16/#17 hace unos días, en la dirección inversa.
   - Cualquier URL/host hardcodeado (`hyl-wai-stg` en vez de `seguroautoqualitas.com`, phoneNumberId
     de test) tiene que quedar apuntando a PROD.
   - `webhookId` de los 3 triggers: confirmar que el import NO pisa los IDs de producción actuales
     (mismo gotcha del Bug #12).
3. **Snapshot fresco de PROD ya tomado** (`901347b`, este repo) — es el punto de rollback si algo
   sale mal.
4. **Deploy a PROD, inactivo primero.** Releer desde la API tras el `PUT` (no confiar en que se
   guardó tal cual se mandó) — verificar node count, credenciales, webhookId, exactamente igual
   que se ha hecho todo el día en STG.
5. **Activar, y monitorear activamente** (no pasivamente) durante una ventana definida — ver
   sección de monitoreo abajo. Empezar en horario de bajo tráfico si es posible.
6. **Reportar y verificar en vivo** (yo) antes de considerarlo cerrado — mismo proceso de todo el
   día, sin atajos por ser PROD.

## Qué monitorear (retomando la lista de Juan, ampliada)

- `WhatsApp initial failed` — envíos de plantilla inicial que fallan.
- `payload_version` — confirmar que sigue en v1 (Django en `shadow`, nunca debería verse v2 en
  PROD todavía).
- Sesiones `waq_*` — no deberían aparecer en PROD mientras el flag siga en `shadow`. Si aparece
  una, algo está mal configurado.
- Errores en `whatsapp_sessions` (constraint, tipo de dato — el mismo patrón del bug de
  `Resolve Session`, aunque ya se corrigió, vale la pena vigilar el primer día).
- Errores de OPL / link de pago.
- Webhook de pago cuando haya pagos reales — primera vez que corre con toda la cadena de hoy
  encima (incluida la reescritura de `Mark Session Completed`).
- **Agregado:** ejecuciones fallidas en general (`status=error` vía API) — no solo los puntos
  específicos de arriba. Revisar cada pocas horas el primer día.
- **Agregado:** que `Save Policy Data` siga fallando como se espera (no debería sorprender a
  nadie que `policy_data` quede vacío) — pero si empieza a fallar de una forma *distinta* a la ya
  diagnosticada, es señal de algo nuevo.

## Secuencia recomendada

1. **Hoy/mañana:** correr y verificar la 6ª prueba (gate del Track B).
2. **En paralelo, sin depender de lo anterior:** Track A (Django `shadow` a PROD) — Juan puede
   avanzar esto ya, es de bajo riesgo y no espera al Track B.
3. **Una vez cerrado el gate:** Track B — diff, snapshot (ya hecho), deploy inactivo, verificar,
   activar, monitorear.
4. **`dual` en cualquier ambiente:** no entra en este plan. Es una decisión aparte, posterior,
   que requiere primero un click real de botón v2 probado de punta a punta en STG.

## Dueños

| Track | Quién ejecuta | Quién verifica |
|---|---|---|
| A (Django shadow) | Juan | Arquitecto (en vivo, como el resto de STG) |
| B (n8n workflow) | Agente n8n | Arquitecto (en vivo) |
| Gate (6ª prueba) | Alberto (dispara la prueba real) | Arquitecto |
