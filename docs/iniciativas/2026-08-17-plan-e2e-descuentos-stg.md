# E2E de Descuentos en STG — plan y **acta de la primera ejecución**

> **Ejecutado el 17 ago 2026, 22:33–23:25 UTC.** Alberto conduce (landing, WhatsApp real, UI de n8n);
> el Arquitecto verifica por SQL y API. Nada de esto tocó PROD.
>
> El plan original preveía dos rutas según si Quálitas aceptaba el porcentaje. **La realidad fue otra
> y mejor**: entró por una vía que no habíamos contemplado, el descuento se aplicó, y el flujo murió
> más adelante por un motivo que nadie había visto. Este documento queda como **acta + guía para la
> próxima**, que es lo único que sirve cuando la predicción falla.

---

## 1. Lo que aprendimos, por orden de importancia

### 1.1 · El disparador real es la INTENCIÓN, no el checkpoint de seguimiento

Preparamos toda la prueba para provocar el checkpoint `quote_sent` + `attempt=2`, que es el trigger
configurado. **No hizo falta.** El cliente escribió *«es muy cara»* y el bot lo enrutó por
`Discount Reply Intake` → creó la aplicación directamente. `phase_2_intent_enabled = true`.

**Para la próxima:** si quieres provocar un descuento, **basta con quejarse del precio**. El camino
del seguimiento es más lento, exige que el Scheduler dispare y encima está condicionado (§1.2).

### 1.2 · Pulsar el botón NO cuenta como mensaje humano

El template inicial (`saludos_inicial_sin_pdf_con_boton`) trae un botón «ver cotización». Al
pulsarlo, Django envía el documento y queda registrado como `ai · quote_document_sent`, pero **no se
crea ninguna entrada `human`** en `n8n_chat_histories`, y `whatsapp_sessions.last_activity` **no se
actualiza**.

Consecuencia, verificada en `qualitas/whatsapp_checkpoint_followups.py:387`:

```python
if not chat_activity.last_human_message_at:   # -> "missing_recent_human_message"
```

**Un cliente que solo pulsa el botón y no escribe nunca entra en el circuito de seguimientos**, y por
tanto nunca recibirá una oferta por esa vía. Es de la familia de `qualitas-issues#41`, pero un paso
antes y más silencioso: el cliente *sí* interactuó.

### 1.3 · Quálitas acepta el 30 % — la premisa del rango 0/20 está muerta

Confirmado con datos: programa `POR_PRECIO_ALTO_PARA_IA_30`, aplicación `100`, cotización resultado
`2114` creada. **El sondeo del 31 jul ya no vale** (Alberto: el webservice cambió). No usarlo.

### 1.4 · **El bloqueante: la cotización con descuento no tiene PDF**

La aplicación terminó en `uncertain` / `document_binary_invalid`. El documento que recibe el worker:

```
qualitas_discountquotedocument · discount-quote-2114.pdf · 1167 bytes · PDF 1.4, 1 página
   "Cotizacion con descuento aplicacion #100"
   "Programa: POR_PRECIO_ALTO_PARA_IA_30"
   "Descuento Qualitas: 30%"
```

Un **placeholder de tres líneas**. Y la causa está aguas arriba: `qualitas_cotizacion.2114` tiene
**`pdf_cotizacion_url` vacío**, mientras la original `2113` sí tiene su PDF en S3.

`document_binary_invalid` **no es un bug del guard: es el guard funcionando.** Lo que falta es
generar el PDF real de la cotización con descuento — y eso es Django.

**Reproducible:** la aplicación `67` está igual, con placeholder de 1169 bytes y el mismo motivo.
**Mientras no se arregle, el E2E de `#161` no es ejecutable**: ni segunda descarga exacta, ni
delivery, ni «cero llamada nueva a Quálitas» pueden verificarse, porque el flujo muere antes.

### 1.5 · Defecto del candidato `#161`, encontrado y corregido

`Discount Conversation Handoff Claim` reventaba con *«Query Parameters must be a string…»*. Su
`queryReplacement` era **una sola expresión** con `|| null`: por la vía que `#161` añadió no llega
aplicación, colapsa a `null`, y el nodo Postgres exige string o array.

Los tres valores posibles hacen tres cosas distintas — **esto es lo que hay que recordar**:

| valor | efecto | resultado |
|---|---|---|
| `\|\| null` | el campo entero es `null` | *«Query Parameters must be a string…»* |
| `\|\| ''` | `stringToArray('')` deja la lista vacía | *«there is no parameter $1»* |
| **`\|\| 'null'`** | manda el texto `"null"` | lo caza `NULLIF(NULLIF($1,''),'null')` ✅ |

Corregido en `Agente-n8n:stg` (`316a9f9`) e importado a la instancia. Rompe el hash acreditado
`5d542e2b…`, con OK de Juan.

---

## 2. Cosas operativas que cuestan media hora si no las sabes

- **Las ejecuciones del worker NO se guardan.** Sus `settings` traen `saveDataSuccessExecution:none`,
  `saveDataErrorExecution:none`, `saveManualExecutions:false`. En la API **no vas a ver nada** aunque
  se ejecute. El error solo se ve **en la pantalla de quien pulsa** «Execute workflow»: pídeselo.
  Y no concluyas «no se ejecuta» por no encontrar registros — ese error lo cometí dos veces.
- **El worker se ejecuta a mano desde la UI.** La API pública de n8n no expone ejecución manual, y
  activar/desactivar por API no basta.
- **Django y n8n comparten la misma base en STG** (`dei0jssp8kr5kv`, PG 17.9), distinta de la de PROD
  (`d779dc6ojpjvn5`). Se consulta con `STG_DATABASE_URL` de `Agente-n8n/.env.local`.
- **Nombres de columna que no son los obvios:** `qualitas_cotizacion` usa `nombre_marca`/`submarca`/
  `modelo` (el año) y `pdf_cotizacion_url`; `whatsapp_sessions` usa `status`, no `session_status`;
  `DiscountProgram.offered_copy` (no `DiscountTrigger`, pese a lo que dice `#161`).

## 3. Estados por los que pasa una aplicación (observado)

```
queued → awaiting_conversation / history_inheritance   (slot reserved, result_quote_id creado)
       → [claim del worker] → uncertain / document_binary_invalid
```

En la cola: `n8n_discount_application_poll`, con `poll_key` del tipo
`d156.app.<id>.g0.poll.<n>` — el `<n>` es lo que la constraint de `#161` amplió a `[1-9]`.

## 4. Guion para la próxima ejecución

1. **Baseline**: máximos de `qualitas_lead`, `qualitas_cotizacion`, `qualitas_polizaemitida` y estado
   de `n8n_discount_application_poll`. Sin esto no se distingue lo que crea la prueba.
2. Cotizar en la landing con teléfono real.
3. Pulsar «ver cotización» → llega el documento.
4. **Escribir una queja de precio** («es muy cara»). Esa es la vía rápida.
5. Verificar la aplicación creada y su `result_quote_id`.
6. **Comprobar que la cotización resultado tiene `pdf_cotizacion_url`** ← si está vacío, para: el
   flujo va a morir en el paso siguiente.
7. Ejecutar el worker desde la UI, **dos veces**, pidiendo el error de pantalla si lo hay.
8. Verificar handoff, segunda descarga y delivery.

## 5. Lo que NO se hace

- Nada en PROD. No se reconcilian las aplicaciones `1`, `34`, `67` ni `100` — vetadas por Juan y
  además son evidencia. No se completa ningún pago.

## 6. Rollback disponible

`~/Desktop/161-backup/`: `worker-VIVO-antes-*.json` (204 KB), `funciones-previas.sql` (4
definiciones), `163-definicion-previa.sql` y `163-rollback-una-funcion.sql`.

## 7. Evidencia de esta ejecución

| qué | valor |
|---|---|
| lead / cotización origen | `760` / `2113` (TOYOTA SIENNA 2024) |
| aplicación / cotización resultado | `100` / `2114` |
| sesión WhatsApp | `waq_2113_32c10d18808b` (`active`) |
| estado final | `uncertain` · `document_binary_invalid` |
| reportado a Juan | `HYL-WAI#161`, comentario del 17 ago |
