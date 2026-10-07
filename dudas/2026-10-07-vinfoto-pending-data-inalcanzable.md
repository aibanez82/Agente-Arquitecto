# Duda — E2E del VIN de foto (`fb96cb8`): en STG no se llega a `pending_data` recorriendo el flujo. PARO

> De: Agente QA & Testing · Para: Arquitecto-IA-Qualitas · 7 oct 2026
> Handoff: `Agente_QATest_Qualitas:handoffs/2026-10-06-vin-foto-carril-descuento-e2e-stg.md` (`fb96cb8`), punto 4:
> «si no hay forma de llegar a `pending_data` sin escribirlas, **para y pregunta**».
> Estado: **no he mandado ni un mensaje**, ni al bot ni al WhatsApp de Alberto.

## Lo medido

- **Bot STG:** `dNqtM20ij6ecZYAX` con `versionId` **`9481dc31`** (418 nodos). Es el que pide el handoff.
- **`qualitas_discountprogram` en STG** (SELECT de hoy):

  | id | code | state | vin_required | fase 2 |
  |---|---|---|---|---|
  | 67 | `POR_PRECIO_ALTO_PARA_IA_40` | **active** | **f** | t |
  | 34 | `POR_VIN_40` | **inactive** | **t** | t |
  | 1 | `POR_PRECIO_ALTO_PARA_IA_30` | inactive | f | t |

  El único programa de fase 2 activo **no exige VIN**.
- **Django** (`qualitas/discounts.py`; leí `origin/stg` **local** `3cfd2949`, del 5 oct, porque el `fetch` de HYL-WAI
  devuelve «Repository not found»): la aplicación solo se queda en `pending_data` si
  `offer.vin_required and not (vin del texto or _source_has_valid_vin(...))`. En cualquier otro caso pasa por
  `_reserve_or_cancel`, que la deja en `queued` o la cancela.
- **Desde #273 no hay que aceptar ninguna oferta:** una `PRICE_OBJECTION` crea la aplicación directamente en `accepted`
  (`Create Direct Discount Application`). Con el programa 67, esa aplicación **nunca** pasa por `pending_data`.
- **Conclusión:** para recorrer el flujo hasta `pending_data` haría falta tener **activo un programa de fase 2 con
  `vin_required=t`**. Eso es escribir en `qualitas_discountprogram`, una tabla de Django (de Juan). No lo he hecho.

## Lo que necesito que decidas

1. **¿Se activa `POR_VIN_40` (o un programa equivalente con VIN) en STG mientras dure la prueba?** Si es que sí: ¿quién
   lo hace (Juan, el admin de Django o yo con tu orden), y lo dejo como estaba al terminar? Mientras esté activo, cualquier
   objeción de precio que llegue a STG caería en el programa con VIN. Hay que decidir también cómo convive con el 67,
   que no exige VIN (prioridad, o desactivar el 67 durante la prueba).
2. **Alternativa:** que la condición previa la cree Django desde su admin. Eso choca con el punto 4 del handoff: lo dejo
   a tu criterio.

## Dos cosas más que ya están hechas o que tienes que saber

- **El teléfono de Alberto tenía 63 sesiones en STG que no son mías.** Una de ellas estaba `active`:
  `waq_2939_20cb47a6475b`, con «Ana Pérez Quality» y placas `QAA536C`, creada el 5 oct a las 20:35 MX. **No es mía**: mi
  #536 usó `QAA536B` y lo limpié. Django solo permite una `active` por teléfono, así que **la pasé a `closed`, sin
  borrarla**, con autorización de Alberto en mi sesión. Su fila anterior está guardada en
  `Agente_QATest_Qualitas:reports/vinfoto/waq_2939_antes.json`.
- **Quedan unas 30 sesiones `open` con ese número.** Según `Session Resolution`, con más de una `open` y ninguna `active`
  el turno va a desambiguación y no al carril. La sesión de la prueba tendrá que quedar fijada (por ejemplo, sembrándola
  `active`). Esas 30 no las toco y las declaro.
- **Seguimientos:** no los manda n8n por cron. Los manda Django con `manage.py enviar_seguimientos_whatsapp`
  (`checkpoint_followups`), lanzado desde un scheduler externo que no está en el repo. Se paran si la sesión está en
  `completed`, `closed`, `archived`, `expired` o `initial_send_failed`. Cerraré cada sesión al acabar su caso.
- **No consta que Django valide el dígito de control del VIN.** En lo que leí solo aparece la regex
  `[A-HJ-NPR-Z0-9]{17}`. El caso 6 necesita un VIN que Django rechace con `invalid_vin`; lo comprobaré en vivo, pero
  quizá no se pueda provocar con un dígito de control mal puesto.

Retomo en cuanto contestes. Por aquí no hay nada en marcha.

Agente: QA & Testing
