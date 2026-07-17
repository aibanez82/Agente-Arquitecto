# Handoff para Juan — exponer `pdf_cotizacion_url` en `api/cotizacion/detalle/`

**Fecha:** 17 jul 2026
**De:** Arquitecto-IA-Qualitas (vía Alberto)
**Para:** Juan
**Estado:** diagnóstico completo, fix de una línea, listo para implementar.
**Prioridad:** media — no bloquea nada activo hoy, pero deja sin efecto un parche de conversación (M31) que ya está desplegado en n8n esperando este dato.

## Por qué

Mejoras Conversación detectó (conversación real, lead 1397 / cotización 2849, sesión `529832103468`) que cuando un cliente dice "no veo la cotización", el bot lo manda a revisar su correo y, si insiste, lo deriva a un agente humano — aunque el sistema ya tiene el PDF de esa cotización específica guardado en S3.

El fix de conversación (parche M31) ya está desplegado en el `systemMessage` del `AI Agent` de n8n (STG y PROD, verificado idéntico): la instrucción le dice al bot que reenvíe `pdf_cotizacion_url` directamente en el chat en vez de mandar al cliente a su correo. Pero ese dato nunca le llega al bot — de ahí este handoff.

## Causa raíz

El bot carga el contexto de la cotización con la tool `get_quotation_data`, que llama:

```
POST https://seguroautoqualitas.com/api/cotizacion/detalle/
Body: { "cotizacion_id": "<id>" }
```

Esa vista es `api_obtener_detalle_cotizacion` en `qualitas/views.py:685`. El diccionario `data` que arma como respuesta (líneas 731-762) incluye `id`, `email`, `telefono`, `marca_id`, `modelo`, `paquete`, `forma_pago`, `precio_total`, `opciones_cotizacion`, etc. — **pero no incluye `pdf_cotizacion_url` en ningún punto.**

El campo sí existe y sí se llena correctamente:
- Modelo: `qualitas/models.py:51` → `pdf_cotizacion_url = models.URLField(max_length=1000, blank=True, null=True)`
- Se puebla en el flujo de generación/subida del PDF a S3: `models.py:797-802`

Es decir: el dato está bien en la base de datos — simplemente esta vista puntual nunca lo serializa en la respuesta.

## Fix

Agregar una línea al diccionario `data` de `api_obtener_detalle_cotizacion` (`qualitas/views.py`, junto a los demás campos, alrededor de la línea 761):

```python
"pdf_cotizacion_url": cot.pdf_cotizacion_url,
```

Nada más. No requiere cambios en n8n (el prompt ya está listo) ni en el flujo de generación del PDF (ya funciona — es el mismo que usa el envío inicial de WhatsApp).

## Verificación después de aplicar

1. Confirmar por API que el endpoint ya devuelve el campo:
   ```
   curl -X POST https://seguroautoqualitas.com/api/cotizacion/detalle/ \
     -H "Content-Type: application/json" \
     -d '{"cotizacion_id": "2849"}'
   ```
   y verificar que la respuesta incluya `"pdf_cotizacion_url": "https://hyl-wai-www.s3.us-east-1.amazonaws.com/pdf_cotizacion/Cotizacion_2849_SI_2025.pdf"` (o el link real vigente para esa cotización).
2. Repetir por WhatsApp la conversación de origen: decir "no veo mi cotización" y confirmar que el bot responda reenviando el link real, sin mencionar el correo ni derivar a un agente.

## Nota

Este es el único pendiente real del parche M31 (Mejoras Conversación) — el resto del paquete que revisaron (M27-M34) ya estaba desplegado en el prompt de n8n, así que este es el único cambio de código pendiente de todo ese lote.
