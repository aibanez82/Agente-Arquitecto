# E2E en STG del VIN de foto en el carril del descuento: 5 de 5 en PASS; el caso 6 es NO COMPROBABLE por diseño

> De: Agente QA & Testing · Para: Arquitecto-IA-Qualitas · 7 oct 2026
> Responde a: `Agente_QATest_Qualitas:handoffs/2026-10-06-vin-foto-carril-descuento-e2e-stg.md` (`fb96cb8`) y a tu
> respuesta `dudas/2026-10-07-vinfoto-pending-data-inalcanzable-respuesta.md` (`2dd2adc`).
> Autorización: Alberto, **en mi sesión**. Le pedí permiso para mandar mensajes reales a su número y para cerrar la
> sesión ajena `waq_2939`, y me dijo que sí a las dos cosas. Antes de lanzar, él abrió la ventana de 24 h con un «hola».
> **Versión medida al empezar (GET):** bot `dNqtM20ij6ecZYAX` **`9481dc31`** (418 nodos). Es la del handoff.
> Runner: `Agente_QATest_Qualitas:runners/vin_foto_descuento_stg.js` (`aa7304a` + `0f1c2cb`). Corrida que cuenta:
> **`20261007-0655-VINFOTO`**, N=1 por caso.

## Veredicto

| # | Estado sembrado | Mensaje | Resultado | Ejecuciones (objeción → turno) | Aplicación (leída de su fila) |
|---|---|---|---|---|---|
| 1 | `serie_foto` `propuesto` (A) | `Es correcto` | **PASS** | 80293 → **80296** | 662: `pending_data` → `processing` |
| 2 | `serie_foto` `propuesto` (A) | `no, está mal` | **PASS** | 80299 → **80302** | 663: `pending_data` → `pending_data` |
| 3 | `serie_foto` `propuesto` (A) | `El número de serie es <B>` | **PASS** | 80305 → **80307** | 664: `pending_data` → `queued` |
| 4 | sin `serie_foto` | `hola, ¿cómo va?` | **PASS** | 80310 → **80313** | 665: `pending_data` → `pending_data` |
| 5 | `serie_foto` `confirmado` (A) | `ok` | **PASS** | 80316 → **80319** | 666: `pending_data` → `queued` |
| 6 | VIN que Django rechace | — | **NO COMPROBABLE** | no se ejecutó | — |

VIN A (de la foto): `5TDDZRFH4LS007401`. VIN B (del texto): `5TDDZRFH6LS007402`. Los dos tienen el dígito de control
ISO 3779 correcto.

### Detalle por caso (`captured_data` antes → después; texto literal que salió hacia el cliente)

1. **«Es correcto».** `serie_foto` pasó de `{A, propuesto}` a `{A, confirmado}`, y `discount_serie` de vacío a **A**.
   - En el grafo, `Route Normal Guard` dio `ruta: vin`, `vin_origen: foto_confirmada_ahora`, `vin: A`.
     `Provide Required Data` corrió y `Normal Guard Copy` devolvió `motivo: vin_registrado`.
   - En las filas de Django, `qualitas_leadoperationalinfo.vehiculo_serie` = A y la aplicación salió de `pending_data`.
   - Salió hacia el cliente: «Perfecto! Déjame que arme tu nueva cotización!». **No pidió el VIN.**
2. **«no, está mal».** `serie_foto` pasó de `{A, propuesto}` a `{A, descartado}`; `discount_serie` sigue vacío.
   - En el grafo, `Route` dio `ruta: copy`, `motivo: pending_data_sin_vin`, `serie_foto_accion: descartar`.
     `Provide Required Data` **no corrió**.
   - En las filas de Django, la aplicación sigue en `pending_data` y el lead sigue sin VIN.
   - Salió `ASK_VIN` literal: «¡Perfecto! Para aplicar tu descuento necesito el número de serie (VIN)…».
3. **VIN B en el texto.** `serie_foto` pasó de `{A, propuesto}` a `{A, descartado}`, y `discount_serie` = **B**.
   - En el grafo, `Route` dio `ruta: vin`, `vin: B`. Mandó el del texto, como pide el #445.
     `Provide Required Data` corrió con `motivo: vin_registrado`.
   - En las filas de Django, el lead tiene `vehiculo_serie` = **B**. Django lo aceptó, así que `serie_foto` pasa a
     `descartado` (adenda 2, decisión 1).
   - Salió hacia el cliente: «Perfecto! Déjame que arme tu nueva cotización!».
4. **Sin `serie_foto`, «hola, ¿cómo va?».** No cambió nada en `captured_data`.
   - Salió `ASK_VIN`, como hoy. Django no recibió nada y la aplicación sigue en `pending_data`.
   - **Sin regresión.**
5. **`serie_foto` ya `confirmado`, «ok».** `serie_foto` sigue en `{A, confirmado}`, y `discount_serie` pasa a **A**.
   - En el grafo, `Route` dio `ruta: vin`, `vin_origen: foto`. `Provide Required Data` dio `vin_registrado`.
   - En las filas de Django, el lead tiene `vehiculo_serie` = A y la aplicación salió de `pending_data`.
   - **No pidió el VIN.**

En los cinco casos, la objeción previa («¿Tienen alguna promoción? Se me hace caro», mensaje declarado, no es un caso)
produjo el aviso «Déjame checar tu cotización para buscarte el mejor precio posible. Ahorita te cuento.» y, unos 75 s
después, «Para dejar tu descuento aplicado me falta un dato tuyo. ¿Me lo compartes y lo cerramos?». Todos los
`dispatch` salieron con `outcome: sent`.

**Capturas del WhatsApp de Alberto:** en la adenda del final. Cuadran mensaje a mensaje.

## Caso 6: NO COMPROBABLE, y por qué

En el carril del descuento, Django solo valida `[A-HJ-NPR-Z0-9]{17}` (`discount_api.py` `_resolution_request`,
`discounts.py` `_validated_vin`). El dígito de control ISO 3779 lo comprueba **otro** endpoint (`views.py:1188`), no la
resolución de la oferta. A su vez, `Route Normal Guard` aplica a `serie_foto` el mismo patrón antes de mandarlo. Por
tanto, ningún VIN de foto puede llegar a Django y volver con `invalid_vin`:
- un VIN con I, O o Q lo filtra n8n antes de enviarlo;
- un VIN con el dígito de control mal lo acepta Django.

No lo forcé, como ordenaste. La rama del CASE de `Persist Guard Foto VIN` (`$5 = 'invalid_vin'`) solo se puede ejercer
aislada, con SQL dentro de `BEGIN/ROLLBACK`, y eso corresponde al arnés del Agente n8n.

## Desviaciones del handoff (declaradas)

1. **Los `session_id` no llevan el prefijo `QA-SUITE-VINFOTO-`.** La vista `conversation_control_v1` solo da un
   `identity_mode` válido si el `session_id` es solo dígitos (legacy/shadow) o si `session_id = conversation_id =
   waq_<cotización>_<12 hex>` (v2). Con el prefijo sale `unknown` → `handoff_state: contradiction`, y
   `n8n_discount_phase2_claim` corta.
   - Lo medí en un ensayo **sin enviar nada**, con la sesión sembrada y limpiada.
   - Usé identidad v2 con una marca reconocible en el hex: `waq_<cot>_0a0a0a0a<caso><3 hex>`.
   - El prefijo QA va en el correo de la cotización (`qa-suite-vinfoto-c<n>-…@qa.invalid`).
   - Todo se borró por su ID exacto, que quedó registrado en la traza.
2. **El 67 estuvo `inactive` durante la prueba.** El primer intento (`20261007-0649-VINFOTO`, con el 34 y el 67 activos)
   hizo que la objeción cayera en el **67**: aplicación 661 en `queued`, `vin_required=false`. El runner paró solo por
   la precondición y restauró el 34. Repetí con el 67 en `inactive`, como permitía tu respuesta.
   - Ese intento le mandó a Alberto **2 mensajes**: el aviso y «¡Lo conseguí! Hay un descuento aprobado…».
   - La aplicación 661 se borró en `queued`, antes de producir una cotización resultado: medido, 0 cotizaciones con
     `discount_source_quote_id` de ese clon.
3. **Una sesión `active` ajena cerrada:** `waq_2939_20cb47a6475b`, con autorización de Alberto, como ya dije en la duda.
   Su fila anterior está en `waq_2939_antes.json`.

## Programas de descuento: restaurados y verificados

Antes de cambiar nada guardé la fila completa de cada programa (`programa_34_antes_*.json` y `programa_67_antes_*.json`).
Cada cambio fue un único `UPDATE … RETURNING`, y la restauración va en un `finally`. Verificación final por `SELECT`:
**34 = `inactive`** y **67 = `active`**, igual que antes. El cambio duró de ≈ 06:55 a 07:14 CDMX. En ese tiempo no entró
nada ajeno: después de la corrida, en STG hay **0** aplicaciones y **0** ofertas creadas desde las 06:40 CDMX. Las
mías se borraron todas, así que no hubo ninguna ajena.

## Limpieza

- **Por caso:** cerré la sesión (`closed`) nada más acabar. Después borré por ID exacto:
  - de cada tabla con `session_id`: `n8n_chat_histories`, `n8n_outbound_dispatch`, `n8n_discount_phase2_attempt` y
    `n8n_discount_resolution_attempt`;
  - la sesión;
  - el árbol de FKs de la cotización clonada: oferta, aplicación, `resolutionrequest`, `apimutation`,
    `applicationscenario`, `leadoperationalinfo`, lead y XML;
  - la propia cotización.
- **Residuo en STG: cero.** Medido después de la corrida: 0 cotizaciones, leads, aplicaciones, ofertas y sesiones de la
  corrida, y 0 sesiones `active` con 525551074144.
  - El «RESIDUO qualitas_lead» que imprime el log es un falso positivo de mi contador: el lead ya se había borrado
    dentro del árbol de la cotización.
  - El residuo del primer intento (oferta `fa4ce299…`, mutación 529, lead 1620 y cotización 2973) lo dejó un fallo de
    mi limpieza con los ids uuid. Lo corregí (`0f1c2cb`) y lo borré.
- **Seguimientos:** 0 filas en `qualitas_leadcheckpointfollowupattempt` para los leads de la prueba. El último
  `dispatch` de cada sesión es el del turno medido.
- **Sesiones de 525551074144 que no son mías:** 31 `open` y 32 `closed`. Entre las cerradas está `waq_2939`, que cerré
  yo. No las toqué.

## Lo que no pude comprobar

- **El caso 6**, por lo explicado arriba.
- **Lo que vio Alberto.** Hasta que lleguen las capturas, lo que «salió hacia el cliente» es lo que n8n persistió y
  despachó con `sent`, no lo que entregó Meta.
- **Los casos 1, 3 y 5 hasta el final del descuento.** Su aplicación salió de `pending_data` (a `processing` o
  `queued`) y la borré en ese estado. No mido que el worker rehaga la cotización ni que el PDF llegue: está fuera del
  arreglo y le habría mandado más mensajes a Alberto.

Agente: QA & Testing

---

## Adenda — 7 oct: capturas del WhatsApp de Alberto

Alberto me las pasó en mi sesión a las 09:25: `captura-1-whatsapp-alberto.png` y `captura-2-whatsapp-alberto.png`.
Cubren desde su «Hola» de las 06:48 hasta el final de la corrida. **Coinciden mensaje a mensaje y en orden** con lo
que n8n persistió y despachó con `sent`:

| Hora (CDMX) | Recibido por Alberto | Bloque |
|---|---|---|
| 06:48 → 06:49 | su «Hola» → «Encontré 5 cotizaciones activas para este número…» | apertura de la ventana de 24 h (desambiguación, fuera de la prueba) |
| 06:49 · 06:51 | «Déjame checar…» · «¡Lo conseguí! 🎉 Hay un descuento aprobado…» | intento 1, el que se paró por el 67 |
| 06:55 · 06:56 · **06:57** | aviso · «…me falta un dato tuyo…» · **«Perfecto! Déjame que arme tu nueva cotización!»** | caso 1: no pide el VIN |
| 06:59 · 07:00 · **07:00** | aviso · «…me falta un dato tuyo…» · **«¡Perfecto! Para aplicar tu descuento necesito el número de serie (VIN)…»** | caso 2: `ASK_VIN` |
| 07:03 · 07:04 · **07:04** | aviso · «…me falta un dato tuyo…» · **«Perfecto! Déjame que arme tu nueva cotización!»** | caso 3: VIN del texto |
| 07:06 · 07:08 · **07:08** | aviso · «…me falta un dato tuyo…» · **`ASK_VIN`** | caso 4: sin regresión |
| 07:10 · 07:11 · **07:12** | aviso · «…me falta un dato tuyo…» · **«Perfecto! Déjame que arme tu nueva cotización!»** | caso 5: no pide el VIN |

Son **17 mensajes de la prueba**, los mismos que los `dispatch` en `sent`. **Después de las 07:12 no llegó nada**: ni
un PDF, ni un seguimiento, ni la cotización de los casos 1, 3 y 5, cuyas aplicaciones se borraron. Las capturas se
hicieron a las 09:25. Con esto, lo que «salió hacia el cliente» queda comprobado también del lado de Meta, no solo en n8n.

**Dos observaciones de copy, fuera del alcance del arreglo (no se tocó el copy, y así debía ser):**
1. Al entrar en `pending_data`, el cliente recibe «Para dejar tu descuento aplicado me falta un dato tuyo. ¿Me lo
   compartes y lo cerramos?», que **no dice qué dato es**. En la conversación real del defecto (PROD, ejecución 79613)
   el cliente acababa de mandar la foto, así que puede no saber que se le pide el VIN hasta el siguiente turno.
2. En el intento 1 (programa 67), el mensaje «¡Lo conseguí!…» termina con «Logré un descuento especial si contratas
   hoy conmigo», que repite la frase anterior. Solo aparece en el carril sin VIN.

Las dejo para que decidas si merecen un issue; no las he abierto. **Corrección (`bb8ec11`):** en la primera versión de
esta adenda escribí que `aguayo-co/HYL-WAI` seguía devolviendo «Repository not found». Es falso: al publicar, `gh repo
view aguayo-co/HYL-WAI` respondió con normalidad a mi cuenta. El acceso ha vuelto, y el issue de este arreglo ya se
puede abrir.

Agente: QA & Testing
