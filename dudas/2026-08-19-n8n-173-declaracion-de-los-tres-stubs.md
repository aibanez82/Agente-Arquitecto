# Declaración de stubs — `#173`: reponer la cobertura del camino conversacional

**Arquitecto, 19 ago 2026.** Declarado con el criterio de `@1.1.0 §4.bis`: **quien escribe el test no
declara lo que el test acredita.** Verificado contra el artefacto y los fixtures del repo, no inventado.

## 1. `Fetch Discount Catalog`

`httpRequest` GET a `/api/v1/discounts/ai-use-cases`. El stub devuelve **200** con la forma que ya
usa `scripts/156/test/discount-phase2-v1.test.js`:

```json
{ "use_cases": [ {
    "code": "PRICE_OBJECTION",
    "name": "…",
    "description": "…",
    "positive_examples": ["…"],
    "negative_examples": ["…"]
} ] }
```

**Un solo caso publicado, `PRICE_OBJECTION`.** El catálogo es cerrado por diseño y el stub no debe
ampliarlo: si devuelve códigos que no existen en producción, la prueba acredita un clasificador que
nadie va a ejecutar.

**Y declaro un segundo caso obligatorio:** la suite debe incluir **catálogo vacío o error 5xx**. Un
stub que siempre responde bien no acredita qué pasa cuando Django no contesta — y ese camino existe.

## 2. `Discount Intent Classifier`

Para un texto **sin** intención de descuento, el veredicto es:

```json
{ "code": "no_match" }
```

Es lo que el propio prompt del nodo exige: *«`{"code":"PRICE_OBJECTION"}` si coincide claramente con
ese código publicado, o `{"code":"no_match"}` en cualquier duda»*. **El stub no debe devolver texto
libre ni un objeto abierto**: si acepta cualquier forma, la prueba deja de acreditar que el nodo es
cerrado, que es justo su propiedad de seguridad.

## 3. `Settle Discount Classification`

`postgres`, llama a `n8n_discount_phase2_classify($1, $2)`, cuya salida real es
`TABLE(turn_key text, etapa text, intent text, consultar_disponibilidad boolean, continuar_normal
boolean, rechazo text)`.

Para el camino conversacional normal el stub devuelve **una fila** con:

| campo | valor |
|---|---|
| `turn_key` | el mismo que emitió `Discount Phase 2 Claim` |
| `intent` | `no_match` |
| `consultar_disponibilidad` | `false` |
| **`continuar_normal`** | **`true`** |
| `rechazo` | `null` |

`continuar_normal = true` es lo que evalúa `IF Continue Normal Conversation?` —
`{{ $json.continuar_normal === true }}` — y lo que devuelve el turno a `Restore After Discount
Phase 2` → `Intent Router` → `AI Agent`.

**Caso obligatorio adicional:** al menos una prueba con **`continuar_normal = false`**, que acredite
que el turno NO se devuelve a la conversación normal cuando la clasificación no lo autoriza. Sin
ella, el stub solo prueba que la puerta se abre, nunca que se cierra.

## Y el hallazgo de fondo, que no hay que perder

> **El módulo de descuentos está en la ruta de TODOS los mensajes de texto**, no solo de los que
> piden descuento.

Eso lo dice el issue y es lo más importante que hay aquí. Explica por qué `#169`, `#170` y `#172` se
cruzan tanto: no son tres bugs vecinos, son tres síntomas de que **el camino principal del bot pasa
por una capa que se diseñó para un caso lateral**.

Con la cobertura repuesta, esa prueba deja de ser solo un test: pasa a ser el **canario del camino
principal**. Si mañana alguien vuelve a poner algo delante del `Intent Router`, esa prueba lo dirá
en vez de dejar la ruta muda otra vez.

Merece un issue propio en el Project para decidir si esa es la arquitectura que queremos — pero eso
es decisión de Alberto, no condición para reponer la prueba.

— Arquitecto
