# Handoff Arquitecto → Agente n8n — URGENTE: confirmar si hoy hubo cruce prod/staging

> Autor: Arquitecto-IA-Qualitas · 7 jul 2026
> Ejecutor: **Agente n8n**.
> Prioridad: **máxima — antes que el Bug #14.** Alberto lo pidió explícitamente como bloqueante.
> Copia canónica: `Agente-Arquitecto:docs/2026-07-07-handoff-agente-n8n-URGENTE-verificar-cruce-prod-stg.md` — deja también copia en `Agente-n8n/handoffs/`. Alberto: confirma que se lo pasaste completo, no solo la ruta.

## Objetivo

Durante la validación E2E del Bug #10 de hoy, encontré (vía `n8n_chat_histories` de **producción**, consultado directo con SQL) una sesión — `session_id 525551074144`, el número de prueba de Alberto — con `qid=null | phase=fallback` que contiene texto que coincide EXACTAMENTE con las pruebas de hoy: el VIN `1HGCM82633A004352` que le indiqué a Alberto, "Juan Perez Garcia", "29 oct 1982". Mezclado con mensajes que Alberto no reconoce haber escrito ("good", "Hola", "Mismos", "pascual", "Claro").

**Confirmado por separado:** la cotización real "Honda Accord 2026" de la prueba de hoy (la que SÍ funcionó, con el resumen completo) **NO existe en `qualitas_cotizacion` de producción** — esa parte del flujo quedó aislada correctamente en staging.

**Sin confirmar:** si además, en algún momento de la prueba de hoy, los mensajes de Alberto (o parte de ellos) llegaron también al webhook de **producción** — ya sea porque escribió al número equivocado, o porque hay algún cruce real de infraestructura. Un mensaje en `n8n_chat_histories` no indica a qué número de WhatsApp Business llegó — no se puede resolver esto con SQL.

## Tarea (única, urgente)

Consulta el histórico de **ejecuciones** de AMBAS instancias de n8n vía API, acotado a la ventana de tiempo de la prueba de hoy (~15:14–15:20 hora CDMX, 7 jul):

1. **Producción** (`n8n.srv1325340.hstgr.cloud`): `GET /api/v1/executions` filtrando por el workflow del bot principal, en esa ventana de tiempo. ¿Hay ejecuciones asociadas al teléfono `525551074144`? Si las hay, ¿qué webhook/trigger las disparó?
2. **Staging** (`n8n-xlqk.srv1810257.hstgr.cloud`): mismo query, mismo teléfono, misma ventana. Debería mostrar las ejecuciones de la prueba real (VIN inválido x2, VIN válido, resumen, el loop de "Solo puedo ayudarte...").
3. **Comparar:** si AMBAS instancias muestran ejecuciones para `525551074144` en la misma ventana, eso confirma que los mensajes de Alberto llegaron a los dos webhooks (a un mismo tiempo o en momentos distintos) — hay que determinar si fue porque escribió a dos chats distintos en su WhatsApp, o si hay un cruce real de infraestructura (esto último sería mucho más grave: revisar si el número de prueba de Meta quedó, por error, compartiendo webhook o configuración con el de producción — mismo patrón de riesgo que el Bug #12).

## Qué NO hacer

No toques nada de producción. No borres ni modifiques la sesión `525551074144` de prod todavía — puede ser evidencia útil. Si confirmas cruce real de infraestructura (no solo confusión de número), repórtalo con máxima urgencia antes de continuar con cualquier otra tarea de staging — sería un hallazgo más grave que el Bug #14.

## Reporte esperado

Para cada instancia: ejecuciones encontradas (o su ausencia) para `525551074144` en la ventana de tiempo, con ids de ejecución. Conclusión: ¿cruce de infraestructura real, o simplemente Alberto escribió a dos números/chats distintos?
