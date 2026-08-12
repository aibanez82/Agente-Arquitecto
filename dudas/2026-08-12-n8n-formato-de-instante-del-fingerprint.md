# Duda — `#156` E6: «UTC ISO-8601» no basta para un fingerprint que compara Django

**12 ago 2026 · Agente n8n · no bloqueante: E6 va entregado con un formato declarado.**

Handoff `2026-08-11-hyl-wai-156-discounts-conversation-control-n8n.md`, entregable E6.
Contrato `conversation-control-v1.md`, SHA-256 `bccbf44a…807471`.

## El problema

El fingerprint normativo es SHA-256 del JSON JCS de una lista cuyos elementos son:

```json
{"canonical_message_id":"uuid","logical_created_at":"UTC ISO-8601","content_sha256":"64hex"}
```

JCS fija el orden de claves, el escapado y la forma de los números. **No fija cómo se serializa un
instante**, porque para JCS eso ya es una cadena. Y «UTC ISO-8601» admite al menos estas formas,
todas legítimas, para el mismo momento:

```
2026-08-01T11:00:00Z
2026-08-01T11:00:00+00:00
2026-08-01T11:00:00.000Z
2026-08-01T11:00:00.000000Z
```

Cuatro cadenas distintas ⇒ **cuatro hashes distintos**. Y el fingerprint no es información interna:
Django lo compara con el suyo antes de aceptar `activated`, y si no cuadra persiste `uncertain` y
devuelve `409`. Un desacuerdo de formato no se vería como un bug de formato, se vería como
«la herencia nunca completa».

## Qué he implementado

**Siempre 6 dígitos de fracción y sufijo `Z`:** `2026-08-01T11:00:00.000000Z`.

En SQL: `to_char(ts AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"')`. En JS, la misma forma,
y hay un test que contrasta las dos implementaciones.

Los seis dígitos son obligatorios **aunque sobren ceros** a propósito. La alternativa —omitir la
fracción cuando es cero, que es lo que hace `isoformat()` de Python— haría que el mismo historial
produjera dos fingerprints distintos según la hora exacta a la que llegó un mensaje. Un fallo que
aparece sólo cuando un timestamp cae en un segundo redondo es de los que tardan semanas en
diagnosticarse.

Elegí 6 y no 3 porque `timestamptz` de PostgreSQL guarda microsegundos: truncar a milisegundos
perdería información real del lado que **produce** el dato.

## Qué te pido

Que se acuerde **explícitamente con Juan**, porque es interoperabilidad y no una decisión de un
solo lado. Concretamente: que el lado Django serialice `logical_created_at` con esos mismos 6
dígitos y `Z`, y no con `isoformat()` a secas.

Si prefieres otra forma, la cambio: es una línea en cada implementación y sus tests. Lo que no se
puede es dejarlo sin fijar — «UTC ISO-8601» leído por dos equipos distintos son dos formatos
distintos, y el síntoma sería un 409 permanente sin causa aparente.

## De paso, para tu inventario

Al cerrar E5 apareció que **`reserve()` necesita un `session_id` exacto**, así que los **10 puntos
de envío que E1 encontró sin sesión acreditable no pueden pasar por el fence tal como están**. No es
que falte migrarlos: es que no tienen el dato. La cobertura real del fence es **8 de 18** hasta que
Juan apruebe o rechace esas excepciones nominales, que están nombradas una a una en
`docs/156/inventario-conectores-whatsapp.md`.
