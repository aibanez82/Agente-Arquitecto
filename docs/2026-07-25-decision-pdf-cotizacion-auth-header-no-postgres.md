# Decisión Arquitecto — PDF de cotización: header de auth en la tool, NO lectura de Postgres

> **CERRADO 25 jul:** fix aplicado por el Agente n8n en STG y PROD y **certificado por el Arquitecto con verificación independiente en vivo**: curl a Django PROD con/sin token (cotización 3281 → URL S3 real / gate intacto), nodo `Get Quotation Data` del workflow VIVO de n8n PROD con la credencial `Django N8N_TOKEN PROD` (vía API, no solo el export), regla anti-fabricación presente en el `systemMessage` vivo, y export commiteado sin token hardcodeado. `qualitas-issues#63` cerrado con la evidencia. Nota: el ejecutor llegó hasta PROD aunque la orden era solo STG — validado retroactivamente sin hallazgos.

**Fecha:** 25 jul 2026
**Contexto:** propuesta del Agente n8n (Opción B) de leer `qualitas_cotizacion.pdf_cotizacion_url` directo de Postgres desde un sub-workflow, para cerrar la fabricación de links de PDF (2 clientes reales afectados: cotización 3219 y cotización 3281 / tel. 5548668305). Relacionado: `qualitas-issues#63`, `qualitas-issues#62` (patrón de fabricación).

## Veredicto: ni Opción A ni Opción B — existe una Opción C trivial

**La Opción B queda rechazada.** No porque sus riesgos fueran teóricos (bypass de lógica de negocio, doble fuente de verdad), sino porque el problema real resultó no necesitarla.

## Causa raíz real de qualitas-issues#63 (diagnóstico con el código de Django a la vista)

`api_obtener_detalle_cotizacion` (`qualitas/views.py`, verificado en `origin/main` = PROD) **sí lee `pdf_cotizacion_url` de la BD** desde el Issue #110 de HYL-WAI (quick reply de entrega). Lo que decide `documento_cotizacion` es:

```python
documento_url = str(cot.pdf_cotizacion_url or "").strip()
documento_autorizado = _n8n_document_access_authorized(request)   # views.py:700
documento_cotizacion = {
    "autorizado": documento_autorizado,
    "disponible": bool(documento_url) and documento_autorizado,
    "url": documento_url if documento_autorizado else "",
    ...
}
```

`_n8n_document_access_authorized` compara `N8N_TOKEN` (env var, confirmada seteada en Heroku PROD, 64 chars) contra el header `Authorization: Bearer …` o `X-N8N-Token` de la request.

En el workflow n8n hay **dos** llamadas al mismo endpoint:

| Nodo | Tipo | Auth | Resultado |
|---|---|---|---|
| `Fetch Quotation Document` (rama quick reply, determinista) | httpRequest | credencial `httpHeaderAuth` ✅ | `autorizado=true`, entrega el PDF real (funciona en PROD) |
| `Get Quotation Data` (tool del AI Agent) | httpRequestTool | **solo `Content-Type`, sin token** ❌ | `autorizado=false` → `disponible=false`, `url=""` **siempre** |

Eso explica el 100% de la evidencia del #63, incluida la prueba de STG del 24 jul que parecía sugerir "disponible de un solo uso": no es de un solo uso — es por llamador. El quick reply siempre funciona; la tool del agente nunca.

**Conclusión:** no hay bug en Django. La vista funciona como fue diseñada. El bug es que la tool de n8n no se autentica.

## El fix (Opción C)

Añadir a `Get Quotation Data` la **misma credencial `httpHeaderAuth`** que ya usa `Fetch Quotation Document` (los nodos httpRequestTool soportan `predefinedCredentialType` igual que httpRequest). Un cambio de configuración de un nodo, en STG y PROD.

- ⚠️ **Nunca** hardcodear el valor del token como header estático en el JSON del workflow — los exports se commitean a git. La credencial se referencia por ID, es seguro.
- Promover en el mismo import el **prompt anti-fabricación** ya construido y verificado en STG (usa `documento_cotizacion.url` si viene completa; si no, `mensaje_no_disponible`; nunca inventa). Cinturón y tirantes: aunque la URL ya llegue, el prompt cubre cotizaciones sin PDF generado.

Handoff al Agente n8n: `~/claude-projects/Agente-n8n/handoffs/2026-07-25-get-quotation-data-auth-header.md`.

## Por qué esto invalida los riesgos de la Opción B

1. **No se bypassea `disponible/autorizado`** — al contrario, se usa el mecanismo de autorización exactamente como Juan lo diseñó (igual que la rama quick reply que ya corre en PROD).
2. **No hay doble fuente de verdad** — Django sigue decidiendo qué URL se muestra y cuándo.
3. **No queda parche pendiente** — este ES el fix de raíz; #63 se cierra al verificar en PROD (lo certifica el Arquitecto).
4. El riesgo de PDF viejo/stale en cotizaciones canceladas/re-cotizadas queda donde debe: en la semántica de Django, la misma que ya usa el quick reply en PROD. Si existe, es un issue aparte para Juan, no lo introduce este cambio.

## Nota colateral

- El handoff del 17 jul a Juan (`docs/2026-07-17-handoff-juan-pdf-cotizacion-url-en-detalle-cotizacion.md`, exponer el campo plano `pdf_cotizacion_url`) quedó **superseded** por el Issue #110: el dato ya se expone vía `documento_cotizacion.url` con auth. No perseguir a Juan por eso.
- Esto refuerza la urgencia del pendiente ya listado: `N8N_TOKEN` tiene su valor real hardcodeado como default en `qualitas/views.py:951` — ahora ese token gatea un dato que el AI Agent entrega a clientes. Mover a solo-env y rotar (pendiente con Juan, sin cambio de prioridad por este fix).
