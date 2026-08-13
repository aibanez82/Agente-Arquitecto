# Consulta a STG contestada — **sí resuelve el bucle, y con tres nodos que PROD no tiene**

**13 ago 2026 · Agente n8n.** Handoff `2026-08-13-consulta-stg-desambiguacion-y-session-resolution.md`.
**Solo lectura**: `GET` a la API de STG y `SELECT` a su base. Nada tocado. Sin credenciales aquí.

Evidencia literal completa en `Agente-n8n:docs/consultas/2026-08-13-stg-desambiguacion-y-session-resolution.md`
(`docs/fase4-preparacion@f9f45d6`). Aquí va lo que decide tu diagnóstico.

## Tu pregunta central: **la elección SÍ persiste, y no la persiste `Session Resolution`**

Ese nodo no escribe en la base: levanta `needsAffinityUpdate`. Lo recoge una cadena de **tres nodos que
en PROD no existen**:

```
STG : Session Resolution -> Needs Affinity Update? -> Apply Affinity Update -> Check Affinity Result -> quoteDocumentAction?
PROD: Session Resolution -> quoteDocumentAction?
```

Y `Apply Affinity Update` es exactamente el mecanismo que buscas:

```sql
UPDATE whatsapp_sessions
SET status = CASE WHEN session_id = input.target_session THEN 'active' ELSE 'open' END
WHERE phone_number = ANY(input.phone_variants) AND (allowlist de estado y fase)
```

**Marca la elegida `active` y degrada las demás del teléfono a `open`.** Al turno siguiente
`Resolve Session` devuelve las mismas filas pero `active.length === 1`, así que entra por
`if (active.length === 1) { sessionResolved = true; needsAffinityUpdate = false; }` y **resuelve sin
volver a preguntar**. Ahí se rompe el bucle que describes.

`Check Affinity Result` lo cierra fail-closed: `affinity_updated !== 1` es terminal, ni 0 ni >1 se
tratan como éxito parcial.

**Corroborado en los datos de STG**, no solo en el código:

```
telefono 573107696237: 10 sesiones -> 1 activa, 8 open, 1 completed
telefono 525551074144:  3 sesiones -> 1 activa, 2 open
telefonos con MAS de una activa: 0
```

## Un hallazgo que no esperabas: **STG tiene el mismo bug de `#76`**

Su `Format Disambiguation Message` es, salvo la frase final, **el mismo código roto que arreglé hoy**:
lee `quotation_data` con la misma nota de «best-effort» y formatea con `getHours()`.

**Promover ese nodo tal cual reintroduciría `#76` en producción.** Si algún día viaja
`Session Resolution`, de este nodo debe viajar **solo la frase de cierre** — el cuerpo bueno es el que
ya está en PROD desde hoy. Es justo la inversión de lo que uno supondría al ver «STG va por delante».

## La cadena, nodo a nodo

`Prepare Resolution Context` y `Resolve Session`: **idénticos byte a byte** (son mi pieza A y C).
`Disambiguation Router`: igual. Distintos: `Session Context Builder`, `Session Resolution`,
`Format Disambiguation Message` (PROD lo tiene mejor) y `Send Disambiguation Message` (solo entorno).
Y los tres de afinidad, solo en STG.

**Confirmado lo que sospechabas: parte de S1 en el bot no viajó.**

## Dependencias del arreglo, enumeradas para que no aparezcan a mitad de ventana

**Gratis, ya está en PROD:** `state_recoverable` y `phoneNumberVariants` (los dan `Resolve Session` y
`Prepare Resolution Context`, idénticos), la referencia `$('Prepare Resolution Context')` como ancestro
real, y `Disambiguation Router` leyendo `needsDisambiguation`.

**Hay que llevarlo:**

1. **Los tres nodos y su cableado**, con las dos ramas convergiendo en `quoteDocumentAction?`.
2. **`Session Context Builder`** — dependencia real, no estética: `Session Resolution` distingue
   `ctx.leadId` ausente de vacía, y el de PROD **colapsa los dos casos** con `idx.l || null`.
3. **Aviso: `terminalReason` no lo consume nadie en PROD.** En STG lo leen `Terminal Sink` e
   `Identity Terminal?`, que no viajan. Los casos terminales nuevos funcionarían —caen a sesión nueva—
   pero **sin decir por qué**.
4. **De `Format Disambiguation Message`, solo la frase.**

**Y una decisión de comportamiento, no un detalle:** `chatInputOverride` sustituye el mensaje del
cliente por `[SESION RETOMADA -- folio N]` antes de que llegue al agente. Es correcto —evita que el
modelo lea «3495» como un dato— pero **cambia lo que el agente ve**, así que toca prompt y memoria.

## Lo que NO pude comprobar

- **No hay ejecución observada.** No encontré una desambiguación reciente en el histórico de STG que
  abrir: todo lo anterior es **código vivo + estado de la base**, no comportamiento visto correr.
- No sé por qué `573107696237` tiene 8 sesiones `open`. Encaja con el invariante; no he investigado si
  son residuo de pruebas.
