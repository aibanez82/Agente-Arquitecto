# Mejoras Conversación → Arquitecto: textos para #586 («Cancelar» del seguimiento) y #543 (ramas pendientes)

**Responde a:** `Agente-MejorasConversacion:handoffs/2026-10-10-noche-586-543-propuestas.md` · **10 oct 2026**
**Solo propuestas. Nada se modifica.**
**Fuentes:**
- `n8n_chat_histories` de PROD: todos los errores 41 del histórico (15 filas, 9 sesiones).
- `qualitas_polizaemitida` × `conciliacion_pagos`, para saber de quién es la póliza que bloquea cada número de serie.
- Issues #586, #543 y #566.

**Comprobado en todos los textos:**
- Tuteo y estilo de Carla.
- Sin adjetivos con género.
- Sin enlaces.
- Sin plazos ni descuentos.
- Ninguno dispara los cinco detectores de hito.

---

## 1 · #586: «Cancelar» al seguimiento «¿Avanzamos?»

**Caso real:** `waq_4383` (Honda CR-V 2019, 9-oct).
- El cliente había pedido la Limitada en mensual (14765) y el bot le dijo que no había esa opción (14766).
- 14798: seguimiento «¿Cómo te pareció tu cotización del *CR-V* por *$16,722.58 MXN*? ¿Avanzamos?».
- 14817: «Cancelar».

**Texto de hoy** (14818 `Mark_Session_Closed` → 14820):
> Para tu caso, te recomendamos contactar directamente con un agente especializado que podrá atenderte mejor: https://api.whatsapp.com/send?phone=525537511678&text=Quiero%20continuar%20con%20mi%20cotizacion%204383

**Referencia buena:** «Cancelar» a la oferta de descuento, `waq_4386` 14858:
> De acuerdo, dejamos tu cotización tal como está. Si cambias de idea, aquí sigo.

### Propuesta A (recomendada): el mismo texto que el del descuento
> De acuerdo, dejamos tu cotización tal como está. Si cambias de idea, aquí sigo.

**Por qué:**
- Es el mismo botón, y el cliente debe recibir la misma respuesta venga del mensaje que venga.
- Ya está en PROD, salió por el carril determinista y no insiste.
- «Dejamos tu cotización tal como está» también encaja con el seguimiento: no se le ha ofrecido nada nuevo, así que no se cambia nada.

### Propuesta B (alternativa): una sola pregunta de objeción, con salida explícita
> Entendido. ¿Es por el precio o te quedó alguna duda de la cobertura? Si prefieres dejarlo aquí, no pasa nada: tu cotización queda guardada.

**Por qué podría tener sentido:**
- Es la lógica del bloque firmado «RECHAZO BLANDO RECIÉN ENTREGADA LA COTIZACIÓN» (22-sep), aplicada al botón: «No gracias» → una pregunta de objeción.
- En PROD esa pregunta ha abierto el carril de descuento con clientes que dijeron que no. `waq_4379`: «Por el precio» → descuento → el cliente siguió preguntando.
- En `waq_4383` el «Cancelar» llega justo después de un «no tengo mensual para Limitada», y es probable que fuera precio.

**Por qué no la recomiendo como primera opción:** el handoff pide «sin insistir», y un botón «Cancelar» es un no más claro que un «No gracias» escrito. Si Alberto prefiere B, que salga **una vez por conversación**, igual que el gancho de pausa (D2).

### Lo que acompaña al texto (grafo, no copy)
1. **Sin `Mark_Session_Closed` decidido por el modelo.** El «Cancelar» detiene la cadena de seguimientos (no más «DESCUENTO ADICIONAL» ni «No te escribo más»), pero la sesión sigue abierta: si el cliente vuelve a escribir, se le atiende con su cotización.
2. **Sin enlace del agente especializado.** «Cancelar» no es una petición de hablar con una persona.

---

## 2 · #543: ramas pendientes

### Qué hay detrás de los 9 casos de error 41 en PROD
Lo medí cruzando el número de serie con `qualitas_polizaemitida`:

| Sesión / fila | Fecha | De quién es la póliza que bloquea | Rama |
|---|---|---|---|
| `…1628` 5082–5089 | jul | **Nuestra**: 7620098398, por la landing el 8-jul y **pagada**. El cliente cree que el pago se rechazó | **a2** |
| `waq_4321` 14184–14187 | 6-oct | **Nuestra**: 7620103892, emitida el día antes, **pago pendiente** | **a1** |
| `…8700` 8788–8793 | 23-jul | **Nuestra, de 12 s antes**: 7620099427 se emitió a las 20:24:32 y el segundo intento de emisión dio el 41 a las 20:24:44 | Doble emisión, no es rama de copy (ver G3) |
| `waq_3744` 13875–13880 | 3-oct | Quálitas, **vencida** el 23-sep, y el 41 sigue 10 días después | **b2** |
| `waq_3639` 12070–12073 | 22-sep | Quálitas, **no es nuestra**; el cliente confirma que el número de serie es correcto | **c2** (otro agente, o póliza vigente) |
| `…1583` 6017–6022 y `…0836` 6363–6364 | jul | Quálitas, no es nuestra | c2 |
| `…6018` 9846–9852 | 27-jul | Nadie: el número de serie estaba **mal capturado** (`…2609LT0…` frente a `…2669L19…` en la foto). Corregido, se emitió | R0, rama «revisemos el número de serie» (ya firmada) |
| `…2775` 5371–5374 | 11-jul | Quálitas, no es nuestra | c2 |

**Lecturas que cambian el diseño:**
- **Dos de nueve son pólizas nuestras.** a1/a2 no son raras, y hoy, sin el #566, el bot no puede saberlo.
- **Uno de nueve era el número de serie mal capturado.** La pregunta de R0 («revisemos el número de serie») resuelve casos reales.
- **En dos casos los seguimientos siguieron empujando a emitir con la emisión bloqueada** (`waq_3639` 12074–12076, `waq_3744` 13881–13883: «¿Seguimos con la emisión de tu póliza?», «Tu precio preferencial… solo está disponible hoy»). Ver G2.

Firmados el 9-oct y sin cambios: R0, a1, a2, b1 y c1. Abajo van **a0** (puente hasta el #566), **b2** y **c2**.

---

### a0 · Error 41, el cliente dice que la póliza es nuestra, y el #566 aún no existe

**Caso real:** `waq_4321`. 14186: «Si ya cuenta con una poliza activa». El cliente solo quería pagar (14117: «me puede ayudar para pagar este numwro de poliza»). Una persona lo resolvió a mano 45 minutos después (14199 y 14212).
**Texto de hoy** (14187, caso B, ya quitado en el viaje 6):
> Gracias por el dato. En este momento solo emitimos pólizas nuevas, no renovaciones de pólizas Quálitas existentes. Lamento no poder ayudarte en esta ocasión.

**Propuesto:**
> ¡Entonces ya eres cliente! No hace falta contratar otra. Le paso tu caso a una persona de nuestro equipo para que revise tu póliza y te ayude con lo que necesites, aquí mismo por WhatsApp. ¿Es por el pago o por otra cosa?

**Por qué:**
- Da la razón y para el flujo de emitir.
- La pregunta final le ahorra a la persona del equipo una vuelta.
- Es lo que ya pasó a mano en `waq_4321`, pero sin los 45 minutos de silencio.

**Necesita del grafo:** aviso a una persona (o `human_takeover`). Si no hay a quién avisar, no se usa a0 y se espera al #566.
Cuando el #566 exista, a1/a2 sustituyen a a0.

**Caso a2 de referencia:** `…1628` 5086, «Hice el tramite en linea antes de hacerlo contigo, pero me rechazo el pago». La póliza 7620098398 consta pagada en la conciliación. Con el #566 se le diría a2 («Tu *[VEHÍCULO]* ya está asegurado con nosotros: póliza [NÚMERO], vigente hasta el [FECHA]…»), que es justo lo que necesitaba oír.

---

### b2 · La póliza anterior venció y aun así Quálitas devuelve el error 41

**Caso real:** `waq_3744` (Suzuki Vitara).
- 13877: «Pues el anterior si pero ya venció el 23 de septiembre».
- 13879: «Entonces donde puedo hacer la renovación».

**Texto de hoy:** el caso B (13878) y el enlace al `5537511678` (13880). Después del viaje 6 ya no hay caso B; con la póliza vencida se usa b1 y se reintenta, **y si vuelve el 41 no hay texto**: el modelo improvisa.

**Propuesto (H, con persona):**
> Quálitas todavía tiene registrada tu póliza anterior con este número de serie, aunque ya venció, y por eso no me deja emitir la nueva desde aquí. Tus datos y tu precio quedan guardados. Le paso tu caso a una persona de nuestro equipo para que lo revise con Quálitas y te escriba por aquí mismo.

**Alternativa (S, sin persona):** si el grafo no puede avisar a nadie:
> Quálitas todavía tiene registrada tu póliza anterior con este número de serie, aunque ya venció, y por eso no me deja emitir la nueva por ahora. Tus datos quedan guardados para que no tengas que repetirlos.

**Por qué:**
- H da una salida real sin prometer plazo («te escriba», no «en X horas»).
- S es honesta pero deja al cliente sin camino. Es lo que pasó con el Vitara, que preguntó «¿dónde puedo hacerla?» y no tuvo respuesta válida.
- **Recomiendo H.** «Tu precio queda guardado» solo si el grafo lo garantiza; si no, se quita.

**Sigue pendiente la prueba con Quálitas** (¿cuándo libera el número de serie?, ¿hay que cancelar la anterior?). Si la prueba da un plazo cierto, se añade una frase: «Quálitas suele liberarlo en [N] días; te escribo ese día para emitirla.»

---

### c2 · Póliza vigente de Quálitas que no es nuestra (otro agente)

**Caso real:** `waq_3639` (KIA Forte 2020, 22-sep).
- 12071: el bot pregunta si el número de serie es correcto.
- 12072: «Correcto».
- Ni la póliza ni el número de serie están en nuestra base: es una póliza Quálitas de otro canal.

**Texto de hoy** (12073):
> Entiendo. Si el VIN es correcto pero Quálitas ya tiene una póliza activa con ese número de serie, no podría emitir una nueva sobre el mismo vehículo desde aquí. Te recomiendo contactar directamente con un agente especializado que podrá revisar tu caso: [enlace]

**Propuesto (antes de saber nada, la pregunta que decide la rama):**
> Ese número de serie ya tiene una póliza de Quálitas registrada, y no es una de las nuestras. ¿Ya tienes un seguro vigente para este auto con otro agente? Si es así, dime qué día vence y te preparo la nueva para que empiece justo ese día.

- Si contesta con la fecha → **c1** firmado y se intenta emitir con inicio diferido.
- Si Quálitas vuelve a rechazar con inicio diferido → **c2**:

**c2 (H, con persona):**
> Quálitas no me deja emitir una segunda póliza para este auto mientras la actual siga vigente, aunque la nueva empiece después. Tus datos quedan guardados. Le paso tu caso a una persona de nuestro equipo para que lo revise con Quálitas y te escriba por aquí mismo.

**c2 (S, sin persona):**
> Quálitas no me deja emitir una segunda póliza para este auto mientras la actual siga vigente. Tus datos quedan guardados; escríbeme cuando tu póliza actual venza y lo intentamos de nuevo.

**Por qué:**
- La primera pregunta cambia «¿el VIN es correcto?», que es la duda equivocada cuando el cliente ya lo confirmó, por la que de verdad decide la rama.
- «No es una de las nuestras» solo se dice si el grafo lo comprobó (#566). Sin él, se quita esa frase.
- **En S quito el «cuando se acerque el vencimiento» del borrador del 7-oct.** El Vitara demuestra que el 41 puede seguir después del vencimiento, así que «acércate antes» no sirve. «Cuando venza» es lo más honesto que se puede decir sin la prueba.
- **Recomiendo H** por la misma razón que en b2.

---

## 3 · Reglas del grafo (no son copy)
- **G1.** a0, b2-H y c2-H solo se usan si existe a quién avisar (notificación a una persona o `human_takeover`). Si no, la variante S.
- **G2.** **Con una emisión bloqueada por el error 41, se detiene la cadena de seguimientos.** Hoy siguen saliendo «¿Seguimos con la emisión de tu póliza?» y «Tu precio preferencial… solo está disponible hoy» (`waq_3639` 12074–12076, `waq_3744` 13881–13883) a un cliente al que no le podemos emitir.
- **G3.** **Doble emisión** (`…8700`): la póliza 7620099427 se emitió, el segundo intento dio el 41 a los 12 s, y el bot mostró el error antes de dar la póliza. Es de julio y puede que el Issue Policy Guard ya lo cubra. Si no, un 41 sobre un número de serie con póliza nuestra emitida en esta misma sesión no es un error: es la póliza que ya se emitió.

Agente: Mejoras Conversación
