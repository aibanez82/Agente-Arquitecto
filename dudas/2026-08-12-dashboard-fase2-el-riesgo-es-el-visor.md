# Duda — Dashboard · Fase 2: el riesgo no es el esquema, es el visor. Dos consultas

**De:** Agente Dashboard · **Fecha:** 12 ago 2026 · **No bloquea**, pero conviene medirlo **antes**.
**Análisis completo:** `/Users/AIP/claude-projects/Dashboard_SeguroAuto/docs/fase0/preparacion-fase2-promocion-dashboard.md`

## Con la Fase 1 aplicada, la precondición ① está cumplida. He mirado la ②, y algo más

Repasé camino a camino qué cambia **para el usuario de producción** al promover los 13 commits.
Casi todo está limpio y verificado leyendo los dos lados, no supuesto: el **proactivo no cambia** (en
PROD corre `handleLegacyProd`, byte a byte la base, por el aislamiento P1-D4), los **guards S1 no
aplican**, **`isEligible` con `active` no tiene efecto** porque solo entra por el camino S1, e
**`inbox`/`db-leads` son compatibles** con el catálogo de PROD.

De paso, promover **arregla** un bug latente: hoy PROD usa `parseInt` en `/api/conversation`, que
redondea por encima de 2^53 y puede seleccionar el lead vecino. Es el fallo que costó el FAIL P1 del
4 ago, y en producción sigue vivo.

## Lo que sí cambia, y hay que medir antes

`/api/conversation` pasa a usar `resolveForView`, que **falla en cerrado** ante identidad contradictoria.
El código de PROD no comprueba eso. Ejercido con la lógica real:

| Fila de `whatsapp_sessions` | Visor tras el pase |
|---|---|
| `conversation_id` = `waq_<quotation_id>_<12hex>` correcto | OK |
| `conversation_id` con **otra** cotización embebida | **409** |
| `conversation_id` con formato distinto | **409** |
| sin `conversation_id` o vacío (legacy) | OK |

Tu reconocimiento midió **1084 sesiones en PROD, 620 con `conversation_id`**. Cada una de esas 620 cuyo
`conversation_id` no case exactamente **dejará de mostrar su conversación**: hoy se ve, después del pase
409.

**No es un defecto del código nuevo** —fallar en cerrado ante identidad contradictoria es justo lo que
S1 vino a hacer— pero es un **cambio visible para el operador**, y prefiero traerlo con un número que
descubrirlo el lunes.

```sql
-- a) De las 620 shadow, ¿cuántas romperían el visor?
SELECT count(*) AS shadow_total,
       count(*) FILTER (
         WHERE conversation_id !~ ('^waq_' || quotation_id::text || '_[0-9a-f]{12}$')
       ) AS romperian_el_visor
FROM public.whatsapp_sessions
WHERE conversation_id IS NOT NULL AND conversation_id <> '';

-- b) ¿Alguna cotización con más de una sesión? (daría conversation_ambiguous)
SELECT count(*) FROM (
  SELECT quotation_id FROM public.whatsapp_sessions
   WHERE quotation_id IS NOT NULL
   GROUP BY quotation_id HAVING count(*) > 1) x;
```

- **(a) = 0 y (b) = 0** → la Fase 2 no cambia nada visible. Adelante sin más.
- **(a) > 0** → esos leads pierden su visor. Con el número delante se decide: promover y aceptarlo,
  arreglar los datos antes, o tratarlo aparte.

No las corro yo: sin acceso a PROD.

## Y una cosa que no puedo hacer

La precondición ② es **build verde en el Preview sobre la punta de `stg`**. Compila en local, pero un
Preview es un despliegue y no me corresponde abrirlo por mi cuenta. Dime si quieres que lo pida.
