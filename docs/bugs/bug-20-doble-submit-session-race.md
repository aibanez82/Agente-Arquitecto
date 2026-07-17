# Bug #20 (detalle adicional) — carrera entre doble-submit del landing y el reset de sesión de WhatsApp

**Sistema:** Django · **Estado:** 🟠 Abierto — comentado en `qualitas-issues#20` (16 jul), no es un issue nuevo, es el mecanismo técnico preciso detrás del síntoma ya trackeado ahí.

## Origen

Alberto reportó una conversación real donde el bot le respondió a un cliente con datos de cotización
válidos: *"Solo puedo ayudarte con la contratación de tu póliza de auto si tengo tu información de
cotización... contacta a un agente especializado"* — cuando el cliente sí tenía una cotización activa
segundos antes. Se investigó en Django (no solo n8n) para encontrar la causa raíz real.

## Caso real

Teléfono `5543510353` / email `naganomena@yahoo.com.mx`, Hyundai Ioniq 2022. Dos cotizaciones creadas
en 6 segundos:

- `qualitas_cotizacion` **2882** — `fecha_creacion` 2026-07-16 22:30:54.081 UTC.
- `qualitas_cotizacion` **2883** — `fecha_creacion` 2026-07-16 22:31:00.511 UTC.

Mismo teléfono, mismo email, mismo vehículo — doble envío del formulario de landing (mismo patrón que
`qualitas-issues#20`).

## Mecanismo exacto (leído del código real de `stg`/`main`, no asumido)

En `qualitas/models.py`, método `serve()` del form de landing (línea ~610 en adelante):

```python
cot_obj = Cotizacion.objects.create(...)                    # línea ~610
QualitasUtils.archivar_historial_chats(data['telefono'])    # línea 633 — INCONDICIONAL, para TODA cotización nueva
Lead.objects.create(cotizacion=cot_obj)
...
resultados_ws = service.cotizar_paquetes_multiples(...)     # llamada SOAP a Quálitas — lenta
...
# más abajo (línea ~849): genera PDF, sube a S3, manda el WhatsApp inicial,
# y SOLO SI el envío fue exitoso, inserta la sesión nueva:
cursor.execute("""
    INSERT INTO whatsapp_sessions
    (phone_number, quotation_id, conversation_phase, last_activity, created_at, updated_at, session_id)
    VALUES (%s, %s, %s, %s, %s, %s, %s)
""", [...])
```

`archivar_historial_chats` (`qualitas/utils.py:97`) archiva (`INSERT INTO whatsapp_sessions_archive
SELECT * FROM whatsapp_sessions WHERE phone_number LIKE %s`) y **borra**
(`DELETE FROM whatsapp_sessions WHERE phone_number LIKE %s`) cualquier sesión existente para ese
teléfono — sin distinguir si es una recotización legítima minutos/horas después (el caso que resolvió
el Bug #11) o un duplicado del mismo submit a milisegundos de distancia.

**La ventana de riesgo:** entre el `archivar_historial_chats()` y el `INSERT` final de la sesión nueva
hay una llamada SOAP a Quálitas + generación de PDF + subida a S3 — trabajo que puede tomar varios
segundos. Si dos cotizaciones del mismo teléfono se crean casi al mismo tiempo (doble-submit real):

1. La cotización A (2882) pasa su propio `archivar_historial_chats` (no encuentra nada que archivar,
   es la primera), y más tarde inserta su sesión con éxito.
2. La cotización B (2883), corriendo en paralelo, llega a `archivar_historial_chats` **después** de
   que A ya insertó su sesión — la archiva y borra (confirmado: hay una fila en
   `whatsapp_sessions_archive` para la cotización 2882, `created_at` 22:31:00.308 — prácticamente el
   mismo instante que la creación de 2883).
3. B sigue su propio flujo lento (SOAP + PDF + S3) antes de insertar SU sesión (para 2883).
4. **Durante todo ese tramo, la tabla `whatsapp_sessions` no tiene ninguna fila para ese teléfono** —
   aunque el cliente ya recibió el WhatsApp inicial de A (o de B, según cuál mensaje se muestre) y
   puede responder en cualquier momento de esa ventana.
5. Si el cliente responde durante esa ventana, `Resolve Session` (n8n, modo `phone_open_sessions`)
   encuentra `match_count = 0` → `Session Resolution` cae a la rama de "no hay cotización activa" →
   el bot manda el mensaje de deflect al agente humano, aunque el cliente sí tiene cotización.

**No hay `ON CONFLICT`/upsert en el INSERT.** El doc de resolución del Bug #11
(`docs/bugs/bug-11-recotizar-session.md`) describe un fallback `ON CONFLICT (session_id) DO UPDATE`
que se supone se agregó como parte de ese fix — **verificado que NO existe en el código real hoy**
(`grep -n "ON CONFLICT" qualitas/*.py` → sin resultados). O el doc de #11 quedó desactualizado
respecto a lo que Juan realmente desplegó, o hubo una regresión después. Vale la pena que Juan lo
confirme — si existiera el `ON CONFLICT`, el `INSERT` de la sesión B fallaría más silenciosamente en
vez de crear una fila nueva, pero no cambiaría la ventana de "cero filas" descrita arriba.

## Por qué es el mismo bug que `qualitas-issues#20`, no uno nuevo

El síntoma que reportó Alberto es una consecuencia directa del doble-submit de #20 combinado con el
fix de #11 (que asume que cualquier cotización nueva del mismo teléfono es una recotización
legítima y por tanto debe resetear la sesión). El fix real de #20 (idempotencia/debounce en el
submit del landing) resolvería esto de raíz — sin dos cotizaciones casi simultáneas, no hay carrera
que gane el `archivar_historial_chats` de una contra el `INSERT` de la otra.

## Impacto

Cada vez que el doble-submit de #20 ocurre (~9-11% de teléfonos según la medición de QA del 11 jul),
hay una probabilidad real de que el cliente reciba el mensaje de deflect a un agente humano en vez de
poder continuar su cotización con el bot — no solo "un lead duplicado en el dashboard", sino una mala
experiencia de cliente real en el momento más caliente del funnel (justo después de recibir la
cotización).

## Candidatos de fix (no decidido, para discutir con Juan)

1. **El de fondo:** idempotencia/debounce en el submit del landing (lo que ya pide #20) — elimina la
   causa raíz de tener dos cotizaciones casi simultáneas.
2. **Mitigación en el mecanismo de #11:** que `archivar_historial_chats` + el `INSERT` final vivan en
   la misma transacción atómica (`transaction.atomic()`), y/o que el archivado solo dispare si ya
   pasó un umbral de tiempo desde la última sesión activa del mismo teléfono (para no interferir con
   un doble-submit a milisegundos, dejando el reset solo para recotizaciones genuinas minutos/horas
   después).
3. Confirmar con Juan si el `ON CONFLICT (session_id) DO UPDATE` que describe el doc de #11 sigue
   existiendo o si el doc está desactualizado.
