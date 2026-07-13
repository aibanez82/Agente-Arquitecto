# Iniciativa — Persistencia incremental de datos capturados en n8n (13 jul 2026)

> Estado: 🔵 Recién scoped, sin handoff enviado todavía. Origen: conversación con Alberto sobre política de seguimiento proactivo.
> Guardado en git (no en memoria local) para persistir entre las 3 laptops de Alberto.

## Origen

Al diseñar la política de seguimiento proactivo (`docs/estrategia/...` — pendiente, ver nota al final), surgió un escenario ("ya tenemos el 70% de tus datos") que requiere saber cuánto lleva capturado un lead a media conversación. Al investigarlo se confirmó que **hoy ese dato no existe en ningún lado consultable**, ni siquiera para Django leyendo la BD directamente.

## Problema confirmado (no es hipótesis — verificado en vivo, dos formas distintas)

**1. Una conversación real completa en STG (cotización 1691, hasta póliza emitida `7620098629`) tiene los 3 campos JSONB vacíos:**
```
conversation_phase: "payment_pending"   ← esto sí avanzó
quotation_data:     {}
captured_data:       {}
policy_data:         {}
```

**2. Búsqueda exhaustiva en el workflow `WhatsApp Insurance Quotation Bot` (PROD, verificado, aplica igual en STG): ningún nodo escribe `captured_data`, `quotation_data` ni `policy_data`.** Los únicos `UPDATE` sobre `whatsapp_sessions` en todo el workflow son `Update Activity`, `Update Phase in DB`, `Update Out of Scope in DB`, `Increment KB Counter` — ninguno toca esas 3 columnas.

**3. Del lado Django, confirmado en `qualitas/utils.py` (`_crear_o_actualizar_whatsapp_session_activa`):** las 3 columnas se **inicializan/resetean explícitamente a `{}`** al crear o recotizar una sesión (`WHATSAPP_SESSION_STATE_RESET_VALUES`), y nunca se vuelven a tocar desde Django tampoco.

**Conclusión: las 3 columnas existen en el schema desde hace tiempo, pero están completamente muertas para escritura — en ambos sistemas.** Todo lo que el bot "sabe" que capturó vive únicamente en el contexto conversacional del LLM (reconstruible solo leyendo `n8n_chat_histories` semánticamente), nunca como dato estructurado.

## Por qué importa (más allá del seguimiento proactivo)

- Desbloquea el "Nivel 3" de la política de seguimiento proactivo (ver conversación del 13 jul con Alberto): con `captured_data` poblado, Django puede calcular "% completado" contando campos no vacíos — sin necesitar entender la conversación.
- Dashboard/QA ganan visibilidad real de en qué parte del flujo está un lead sin tener que leer el chat completo.
- Reduce el riesgo de re-preguntar datos ya dados si la sesión se retoma (recotización, error de sesión, etc.) — hoy esa reconstrucción depende 100% de que el LLM la re-derive del historial de chat en cada turno.

## Diseño propuesto (a validar con Agente n8n antes de convertir en handoff)

### Checkpoints de escritura — 4 puntos naturales, ya existen en el flujo actual

Los primeros 3 coinciden exactamente con las transiciones entre grupos que M19 ya introdujo (cierre de Grupo 1→2, 2→3, 3→factura) — son el lugar natural para agregar un `UPDATE ... SET captured_data = captured_data || $1::jsonb` justo ahí, mismo patrón que ya usa `Update Phase in DB` para `rate_limit_data` (merge con `||`, no reemplazo).

| Checkpoint | Qué se escribe | Columna |
|---|---|---|
| Cierre Grupo 1 (nombre, fecha nacimiento, género) | `{nombre, apellido_paterno, apellido_materno, fecha_nacimiento, genero, ine}` | `captured_data` |
| Cierre Grupo 2 (placas, serie, factura) | `{placas, serie, requiere_factura, rfc}` (rfc solo si aplica) | `captured_data` |
| Cierre Grupo 3 (domicilio validado) | `{calle, numero_ext, numero_int, colonia, ciudad, estado, codigo_postal}` | `captured_data` |
| Después de `issue_policy` exitoso | `{numero_poliza, monto_total, fecha_emision, fecha_vencimiento_link, link_pago}` | `policy_data` |

`quotation_data` queda fuera de este alcance por ahora — ya se llena implícitamente vía `get_quotation_data` en cada turno (no persiste, pero tampoco parece haber un consumidor que lo necesite persistido, a diferencia de `captured_data`). Revisar si hace falta cuando se diseñe el handoff real.

### Shape sugerido de `captured_data` (acumulativo, merge con `||` en cada checkpoint)

```json
{
  "grupo1": {"nombre": "...", "apellido_paterno": "...", "fecha_nacimiento": "...", "genero": "..."},
  "grupo2": {"placas": "...", "serie": "...", "requiere_factura": true},
  "grupo3": {"colonia": "...", "ciudad": "...", "estado": "..."}
}
```
Anidado por grupo (no plano) para que "¿qué porcentaje lleva?" sea tan simple como contar claves de primer nivel presentes (`grupo1`/`grupo2`/`grupo3`) sobre 3 — sin necesitar saber los nombres de campo internos de cada uno.

## Riesgos / cosas a decidir antes del handoff

- **PII duplicada:** estos datos ya existen en `qualitas_cotizacion`/`qualitas_polizaemitida` del lado Django una vez la póliza se emite — persistirlos también en `whatsapp_sessions.captured_data` no es una exposición nueva (misma BD, mismo nivel de acceso), pero sí duplica el dato. Aceptable dado que el propósito es justamente tenerlo disponible *antes* de la emisión, que es cuando Django todavía no lo tiene.
- **No es solo "agregar un UPDATE"**: hay que decidir qué pasa si el usuario corrige un dato ya capturado más adelante (M19 permite retroceder a un grupo si el usuario pide corrección) — el merge con `||` sobrescribe by design, así que un `UPDATE` posterior al mismo grupo debería funcionar bien, pero falta confirmarlo con un caso de prueba real.
- Coordinar el orden: esto puede aplicarse independiente de la iniciativa `conversation_id` (no se solapan en los mismos nodos), pero ambas tocan el mismo workflow — mejor no mandarlas en paralelo al mismo tiempo para no pisarse.

## Estado y próximo paso

🔵 13 jul: scoped, sin handoff enviado. Cuando Alberto confirme el diseño (o lo ajuste), se traduce a un handoff concreto para Agente n8n como los anteriores — verificando primero contra el `systemMessage`/estructura viva de STG, no contra este documento de diseño.

## Relacionado

Política de seguimiento proactivo (conversación con Alberto, 13 jul — pendiente de documento formal): el Nivel 3 de esa política ("ya tenemos el 70% de tus datos") queda bloqueado hasta que esta iniciativa se implemente.
