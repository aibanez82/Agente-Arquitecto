# Bug #2 — Prefijo 57 (Colombia) en session_id en lugar de 52 (México)

**Sistema:** Django · **Estado:** 🟡 Medio (bajado de 🟠 Alto el 11 jul — ver reevaluación abajo)

## Reevaluación (11 jul) — bajado a Medio

La única evidencia "confirmada en vivo" del bug es la sesión `573107696237` — que **es el segundo número de prueba de Juan** (así lo identifica la nota del Bug #15: "Afecta también a un segundo número de prueba (Juan, `573107696237`, prefijo `57` = coincide con Bug #2)"). Es un teléfono colombiano real (+57), no un número mexicano al que Django le puso el prefijo equivocado por accidente. La lógica (`NumeroPruebaWhatsapp.objects.filter(...).exists() → 57 si True, 52 si False`) probablemente funciona como bandera interna de "esto es tráfico de prueba", no como un error de detección de país.

**Lo que sigue sin confirmarse (por eso no se cierra del todo):**
1. Nunca se verificó si un número mexicano real (no de Juan, no de QA) cayó alguna vez en `57` por un falso positivo del `.filter(...).exists()`. La hipótesis de que esto explica el patrón general `qid=null/phase=fallback` sigue sin confirmar.
2. Sigue sin resolverse si la tabla `qualitas_numeropruebawhatsapp` existe de verdad en producción (ver hallazgo pendiente más abajo). Si no existe, el `.filter(...).exists()` siempre daría `False` → siempre asignaría `52` → el bug no podría estar afectando a clientes reales aunque quisiera.

**Pendiente para cerrarlo con certeza:** pedir a Juan que confirme en Heroku si la migración 0024 corrió (`heroku run python manage.py showmigrations qualitas --app hyl-wai-production`).

## Fila de la tabla original

| 2 | Prefijo `57` (Colombia) en `session_id` en lugar de `52` (México) | Django | 🟠 Alto — **confirmado ACTIVO en vivo 7 jul:** sesión real `573107696237` cayendo en `qid=null / phase=fallback` en `n8n_chat_histories` (mensajes más recientes de toda la tabla al momento de revisar). **Hipótesis nueva:** esto probablemente explica el patrón `qid=null/phase=fallback` en general — si Django crea el `session_id` con el prefijo equivocado, el inbound real de Meta (con el prefijo correcto del cliente) nunca hace match contra la sesión/cotización guardada. Pendiente confirmar revisando `qualitas_cotizacion.telefono` de esa cotización vs. el prefijo real usado. Código fuente del bug: `qualitas/models.py`, lógica `NumeroPruebaWhatsapp.objects.filter(...).exists() → 57 si True, 52 si False` (ver también la nota sin resolver sobre si esa tabla existe en prod, `docs/2026-07-07-respuesta-agente-n8n-rate-limit-data-no-es-migracion.md`). |

## Corrección de arquitectura (9 jul) — de dónde nace el bug

Este bloque vivía en CLAUDE.md, sección "Arquitectura completa del sistema", como la corrección del 9 jul sobre el webhook de lead creado (que no existe). Se mueve aquí completo porque es donde nace el Bug #2 (el prefijo 57 vs 52).

> **✅ CORRECCIÓN (9 jul 2026, leído directo del código de `aguayo-co/HYL-WAI` rama `main`,
> commit `586b318` — reemplaza el punto 1 de abajo, que era incorrecto):** Django **NO** dispara
> ningún webhook a n8n al crear el lead. Confirmado con la lista de workflows de PROD vía API
> (solo 3 existen: bot principal, Payment Confirmation, Retomar Conversación — ninguno recibe un
> "lead creado"). Lo que realmente pasa (`qualitas/models.py`, dentro del `serve()` de la landing
> page, tras crear `Cotizacion`+`Lead`): (a) Django genera el PDF de cotización, lo sube a S3; (b)
> Django manda el **primer mensaje de WhatsApp DIRECTO vía Meta Graph API** (plantilla con imagen +
> link al PDF + botón quick-reply), usando sus propias credenciales `WHATSAPP_ACCESS_TOKEN`/
> `WHATSAPP_PHONE_NUMBER_ID` — sin pasar por n8n; (c) si el envío fue exitoso, Django hace un
> **`INSERT INTO whatsapp_sessions` directo por SQL crudo** (`phone_number`, `quotation_id`,
> `conversation_phase='greeting'`, `session_id`) — **este es el punto exacto donde nace el prefijo
> 57 vs 52 del Bug #2** (`NumeroPruebaWhatsapp.objects.filter(...).exists() → 57 si True, 52 si
> False`, justo antes del INSERT). Cuando el cliente responde más tarde, `Check Session Exists` de
> n8n ya encuentra la fila (creada por Django) y carga el `quotation_id` correcto — n8n nunca
> extrae el `quotation_id` del texto del mensaje. **Implicación para el Bug #11** (sesión pegada a
> la 1ª cotización al recotizar): el fix del UPSERT de `quotation_id` va en **Django**
> (`qualitas/models.py`, este mismo `INSERT`, cambiarlo a `INSERT ... ON CONFLICT (session_id) DO
> UPDATE ...`), **no en un workflow de n8n** — el "workflow del webhook de lead creado" que se
> mencionaba en el Bug #11 no existe; era una inferencia nunca verificada. Esto es tarea de Juan,
> no del Agente n8n.
>
> **⚠️ Hallazgo sin confirmar, pendiente de Juan:** la tabla `qualitas_numeropruebawhatsapp`
> (modelo `NumeroPruebaWhatsapp`, migración `0024`, ya presente en el commit desplegado en PROD
> desde el 5 jun según Heroku) **no existe** en la BD accesible vía `DATABASE_URL` del Dashboard
> (`information_schema.tables` sin resultados, confirmado 9 jul). Pero las `whatsapp_sessions` más
> recientes (creadas hace minutos al momento de revisar) sí tienen `quotation_id` correcto — el
> código que depende de esa tabla parece estar funcionando de todas formas, lo cual no cuadra si
> la tabla de verdad no existe. Dos hipótesis sin descartar: (a) la migración 0024 nunca corrió en
> PROD y este bloque de código lleva tiempo fallando silenciosamente sin afectar el envío del
> mensaje inicial (el INSERT a `whatsapp_sessions` sí ocurre según los datos — inconsistente con
> (a) salvo que haya otro camino de creación que no hemos encontrado); (b) el `DATABASE_URL` que
> usa el Dashboard (y por tanto el Arquitecto) no apunta exactamente a la misma base que usa
> `hyl-wai-production` hoy. **Pedir a Juan que confirme directo en Heroku
> (`heroku run python manage.py showmigrations qualitas --app hyl-wai-production`) si la 0024 está
> aplicada.**
