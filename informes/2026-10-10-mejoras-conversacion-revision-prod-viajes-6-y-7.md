# Mejoras Conversación → Arquitecto: revisión de PROD tras los viajes 6 y 7

**Responde a:** `Agente-MejorasConversacion:handoffs/2026-10-10-revision-prod-tras-viajes-6-y-7.md` · **10 oct 2026**
**Fuente:** `n8n_chat_histories` de PROD, filas con `created_at` ≥ 9-oct 12:00 CDMX (18:00 UTC), leídas el 10-oct a las 13:11 CDMX. Nada se modifica.

## 0 · Lo primero: el viaje 7 todavía no tiene tráfico real
- **Viaje 6** (`26dfbb82`): import entre las 12:43 y las 12:48 CDMX del 9-oct (informes `5e8aea3b` y `0cbb9334`).
- **Viaje 7** (`1b869a0f`): import hacia las 12:35 CDMX del 10-oct (`4f3f2410`).
- **La última fila real es la 14912, del 9-oct a las 17:33 CDMX.** Desde entonces no ha escrito ningún cliente. Las cotizaciones 4389–4393 (9-oct, 19:00 CDMX) son pruebas con teléfono `…0000` y no tienen chat.
- Por eso **ningún marcador del viaje 7 tiene primer caso real todavía** (despedidas, imagen que no es tarjeta, «Están bien», pasarela, número del `#257`, «Inicio de vigencia»). Más abajo dejo los casos de la ventana anterior al viaje 7, que sirven de comparación.
- Hay 15 sesiones con actividad en la ventana. Tres son anteriores al viaje 6 o lo cruzan (`waq_4375`, `4376`, `4377`).

**Ojo al contar filas por hora:** al aplicar un descuento, el historial de la cotización vieja **se copia** a la sesión nueva con `created_at` nuevo. Se reconoce porque llevan los mismos `toolu_…`:
- `waq_4379` 14822–14833 es una copia de `waq_4375`.
- `waq_4384` 14777–14783 es una copia de `waq_4378`.
- `waq_4385` 14803–14816 es una copia de `waq_4380`.

Si se cuenta por fecha, parece que el bot mandó tres recordatorios en un minuto (`waq_4384`, 18:40 UTC), y no es así. Lo aviso por si el Dashboard cuenta mensajes así. En este informe solo cuento las filas originales.

## 1 · Primer caso real de cada cambio

| Marcador | Primer caso real | Veredicto |
|---|---|---|
| **L1** (#461) | **14868**, `waq_4379`, 9-oct 15:02 CDMX: «¡Hola! Soy Carla, de Quálitas 😊 Ya tengo tu cotización para tu *NISSAN KICKS 2017*: Cobertura Amplia, pago anual de *$7,880.90 MXN*. ¿Te la dejo lista para contratar?» | **Literal. PASS.** Antes, en 14840 (13:26 CDMX, tras responder qué cubre), cerró con «¿Te gustaría continuar con tu contratación?»: no es L1, pero tampoco invita a cambiar ni menciona la Limitada |
| **c1** (renovación, póliza de otra aseguradora, #543) | **14906 → 14908**, `waq_4385`, 17:29–17:30 CDMX: primero «¿esa póliza que vence es con nosotros (Quálitas) o con otra aseguradora?», luego «¿Qué día exacto vence tu seguro actual? Así te preparo la nueva póliza para que inicie justo ese día.» | **Paráfrasis, no literal.** El sentido es correcto. Fricción en §3-F1 |
| **D2** (gancho de pausa) | 14852, `waq_4379`: «Claro, tómate tu tiempo… 3, 6 o 12 MSI con… BBVA…» | Sale una vez, bien. **Pone a BBVA en 12 MSI**: la KB (fragmento 33) dice que no. Lo arregla el texto D de la petición de llamada solo cuando se pregunta por dividir el pago; el gancho conserva el error |
| K1, K4 (#340) | Sin casos. Ningún cliente corrigió un dato que el bot diera | — |
| R0 (#543) | Sin casos. No hubo error 41 | — |
| U1 (#261) | Sin casos. Nadie pidió el PDF mientras se generaba | — |
| L4 (#461) | Sin casos. No se llegó a ningún resumen después del viaje 6 | — |
| Límite de 30 (`limite30_fijo`) | Sin casos. En `waq_4385` el inicio quedó a 19 días (28/10/2026), dentro del límite. **Pero `captured_data` sigue vacío (`{}`)**: la fecha acordada solo vive en el chat. Ver §3-F1 | No ejercitado |
| Cliente sin materno | Sin casos. Nadie pasó de grupo 1 después del viaje 6 | — |
| D1–D5 (#418, viaje 7) | Sin casos después del viaje 7. **Comparación anterior** (prompt sin el bloque fijo): 14794 y 14796 (`waq_4381`), 14886 (`waq_4379`), 14901 y 14903 (`waq_4387`). Las cuatro despiden sin volver a ofrecer | Pendiente |
| «Están bien» (#472) | Sin casos después del viaje 7. **Comparación:** 14684 → 14686 (`waq_4377`, 9-oct 11:51 CDMX), el falso rechazo que ya está comentado en el #472 | Pendiente |
| Imagen que no es tarjeta (#581) | Sin casos después del viaje 7. **Comparación:** 14724 (`waq_4377`): una captura del error de pago entró como `[FOTO_VIN]` | Pendiente |
| Pasarela caída | Sin casos después del viaje 7. **Comparación:** 14729 (`waq_4377`): «No puedo obtener la liga de pago en este momento. Inténtalo de nuevo más tarde.» | Pendiente |
| Número de atención humana (#257) | Sin casos después del viaje 7. Después del viaje 6 sigue saliendo el `5537511678` (14820, 14876, 14878, 14882), que es lo esperado hasta el viaje 7 | Pendiente |
| «Inicio de vigencia» en el resumen | Sin casos (no hubo resúmenes) | Pendiente |

## 2 · Regresiones
**No veo ninguna.** No encontré nada que antes funcionara y después del viaje 6 deje de funcionar. Con tan poco tráfico (13 sesiones reales, un solo cliente que llegó a datos), esto no prueba que no las haya.

## 3 · Fricciones nuevas (después del viaje 6)

**F1 · `waq_4385`: pasa a datos sin haber elegido cobertura, y la fecha de inicio no se guarda.**
- El cliente preguntó por la «cobertura básica» y si «para esta» había MSI (copia de 14804 y 14808). Después aceptó el descuento.
- En 14905 escribe: «pensé que mi póliza anterior había vencido el día de ayer 08 pero es 28. Entonces sería hasta por el 29 que estaría contratando».
- El bot le vuelve a preguntar el día (14908), luego el día con mes y año (14910), y en 14912 pide el nombre. **Son tres turnos para un dato que ya venía en el primer mensaje.**
- **Además:**
  - `qualitas_cotizacion` 4385 tiene `paquete` y `forma_pago` en NULL y no hubo `Save_Quotation_Selection`. Se pasó a `data_capture` sin el enunciado A1, y el cliente se inclinaba por la Limitada.
  - `captured_data` está vacío, así que el 28/10 solo está en el chat.
  - No veo en el esquema al que tengo acceso ninguna columna `fecha_inicio`. ¿Dónde se escribe? Puede que solo al emitir.
- **Te lo dejo a ti para el tracker:** ¿pasar a datos sin cobertura elegida es un defecto, o el grafo lo recoge en el resumen?
- **Texto sugerido** (cuando el cliente da él mismo la fecha de vencimiento):
  > Perfecto: tu póliza actual vence el 28/10/2026, así que te preparo la nueva para que empiece ese mismo día y no te quedes sin cobertura. ¿Seguimos con la Limitada o con la Amplia?

  La pregunta de cobertura solo va si no hay `paquete` guardado. Si el cliente da dos fechas («vence el 28… hasta el 29»), se toma la de vencimiento y se confirma una sola vez.

**F2 · `waq_4383`: «Cancelar» cierra la sesión y manda el enlace del agente especializado.**
- 14817 «Cancelar», probablemente el botón del recordatorio de 14798. Le siguen `Mark_Session_Closed` y, en 14820, «Para tu caso, te recomendamos contactar directamente con un agente especializado…».
- El cliente había pedido Limitada en mensual (14765). «Cancelar» es un no al recordatorio, no una petición de un humano.
- En `waq_4386`, 14858 contesta con un texto determinista («De acuerdo, dejamos tu cotización tal como está. Si cambias de idea, aquí sigo.») sin ninguna fila `human` delante, 13 s después del recordatorio. **Dos salidas distintas para lo que parece el mismo botón.** ¿Tienen botones distintos los dos recordatorios?
- Es la única fila «Cancelar» de todo el histórico, así que no puedo llamarlo regresión.
- **Texto sugerido para «Cancelar» del primer recordatorio:** el de 14858, tal cual. Sin el enlace del agente.

**F3 · `waq_4379`: petición de llamada.** Entregado aparte (`informes/2026-10-10-mejoras-conversacion-peticion-de-llamada.md`, firmado). Antes había escrito desde otro teléfono (sesión sin cotización, filas 14861–14866). El bot le pidió escribir desde el celular de la cotización, que era lo correcto con lo que había.

**F4 · `waq_4384` 14791 (12:46 CDMX, justo en el límite del viaje 6).** Ante «Pago mensual no maneja», responde «Sí manejamos pago mensual… ¿Quieres que revise ese monto en tu cotización?». **Pregunta en vez de dar la cifra**, y el cliente no volvió. Texto sugerido:
> Sí: en mensual quedaría en un primer pago de $[PRIMER_PAGO] y 11 de $[SUBSECUENTE] ($[TOTAL] en total). Si lo quieres en partes sin costo extra, la anual de $[ANUAL] te sale a 6 MSI de $[ANUAL/6] con tarjeta de crédito participante. ¿Cuál te acomoda?

Es la misma lógica que el texto D firmado. Las cifras salen de `opciones_cotizacion`.

**F5 · `waq_4387` 14898–14903: «quiero seguir… ya que salga de trabajar».** El bot espera sin agendar nada y sin decir qué tener a mano. Es el caso del `#567` (franjas firmadas el 9-oct, no están en los viajes 6 y 7). Mientras llega, texto sugerido:
> Va. Para que sea rapidísimo, ten a la mano tu tarjeta de circulación (placas y número de serie); lo demás me lo dices tú. ¿A qué hora sales? Te escribo a esa hora.

La última pregunta solo si el `#567` ya está desplegado. Sin él, se corta en «…me lo dices tú».

**F6 · Recordatorios en «usted» del 9-oct a las 17:18 y 17:20 CDMX** (14895 `waq_4385`, 14896 `waq_4384`): «¿Le gastaría que continuáramos…», con erratas distintas en cada uno. **Parecen escritos a mano por una operadora, no por el bot** (Alberto confirmó lo mismo para 14773 en `waq_4377`). No es del bot, así que no propongo nada.

## 4 · Observación, no es nueva
La cadencia de tres mensajes («¿Cómo te pareció…?», «DESCUENTO ADICIONAL», «No te escribo más») se completa en 20–24 min (`waq_4376`, `4382`, `4386`, `4387`, `4388`). Dos clientes contestaron **después** del «No te escribo más»: 14775 a los 18 min y 14898 al minuto. Ya pasaba antes del viaje 6. Lo dejo anotado por si se revisa la cadencia.

Agente: Mejoras Conversación
