# Mejoras Conversación → Arquitecto: #596, los tres textos de urgencia de Montserrat

**Responde a:** `Agente-MejorasConversacion:handoffs/2026-10-14-596-textos-de-montserrat.md` · **14 oct 2026**
**Solo propuestas. Nada se modifica.**
**Fuentes:**
- `n8n_chat_histories` de PROD, del 21-sep al 14-oct.
- `qualitas_whatsappmessage`, el registro de envíos de Django.
- `qualitas_polizaemitida` × `qualitas_cotizacion`.
- Lo firmado en `docs/estado/2026-10-09-firmas-de-alberto.md`.

---

## 0 · Lo primero: «únicamente hoy» no es verdad en los datos

No encuentro ningún mecanismo que haga caducar el precio o el descuento al final del día:
- No hay ninguna columna de caducidad o validez en las tablas que puedo leer.
- **Las pólizas se emiten días después al mismo precio de la cotización:**

| Cotización | Cotizada | Emitida | Después de | Precio cotizado → emitido |
|---|---|---|---|---|
| 4349 | 7-oct | 8-oct | 22 h | $8,706.77 → $8,706.77 |
| 3662 | 23-sep | 24-sep | 25 h | $12,635.22 → $12,635.22 |
| 2572 | 6-jul | 8-jul | 49 h | $10,671.66 → $10,671.66 |
| **3602** | 21-sep | 29-sep | **189 h (8 días)** | $10,523.03 → $10,523.03 |
| **3723** (con **descuento**) | 29-sep | 1-oct | **33 h** | Emitida con el precio con descuento |

- El precio aguanta al menos 8 días, y el descuento al menos 33 h.
- Decirle al cliente «válido únicamente hoy» es **una urgencia que el sistema no cumple**. Si vuelve mañana y ve el mismo precio, lo nota. Además, prometer una caducidad que no existe puede considerarse publicidad engañosa ante Profeco. Que lo valore Alberto.
- **Esto también toca a lo ya firmado y a lo que ya está en PROD:**
  - la firma del `#567` («la oferta vence *hoy*… se aplica siempre»);
  - el segundo recordatorio de hoy («DESCUENTO ADICIONAL para HOY!!»);
  - el `summary_pending/2` («solo está disponible hoy»).

**Decisión que pido a Alberto, antes que los textos:**
- **(V) Hacerlo verdad:** el precio o el descuento caducan a las 23:59 del día de la cotización, y al día siguiente se recotiza. Es grafo y Django, no copy. Con eso, «únicamente hoy» vale tal cual.
- **(H) Urgencia honesta, sin mecanismo:** «es el precio de hoy» y «no te puedo asegurar que se mantenga». Las dos frases son ciertas: la cotización avisa de que la tarifa puede cambiar, y no lo garantizamos.

Abajo doy cada texto en las dos versiones. Mientras no exista (V), **recomiendo (H)**.

---

## 1 · Tercer recordatorio a clientes dormidos

**Montserrat:** «¡Aún está a tiempo de aprovechar tu precio promocional! Es válido únicamente hoy. ¿te ayudo a finalizar tu compra?»

### (a) Texto de hoy y quién lo manda
Es el tercer mensaje de la cadena de seguimiento:
1. «¿Cómo te pareció tu cotización del *[VEHÍCULO]* por *$[PRECIO] MXN*? ¿Avanzamos?» (+8 min)
2. «Me acaban de aprobar un DESCUENTO ADICIONAL para HOY!! ¿Avanzamos y te envío la nueva cotización?» (+16 min)
3. «**No te escribo más. Si quieres retomarla más adelante, contéstame por aquí cuando gustes. Tengo tu cotización guardada...**» (+28 min)

**Casos reales:**
- `waq_4387` 14897 (9-oct): el cliente contesta al minuto, «Si por favor quiero seguir los contacto ya que salga de trabajar».
- `waq_4378` 14757: «Aceptar» 18 min después, y abre el descuento (14776).

**Quién lo manda:** Django no lo registra en `qualitas_whatsappmessage` (en la sesión `waq_4387` solo consta `saludos_inicial_sin_pdf_con_boton`). Los tres mensajes viven en `n8n_chat_histories`. **Corrección del Arquitecto (14-oct): son los checkpoints de Django (`django_checkpoint_followup_v06`), no n8n**; la escritura en `n8n_chat_histories` no indica que los mande n8n. Según `Agente-n8n:scripts/load-checkpoint-followup-copy-stg.py`, el texto se configura en `qualitas_leadfollowuppolicy`, en el checkpoint `quote_sent`, intento 3. No tengo permiso de lectura de esa tabla en PROD. **Confírmalo en el grafo.**

**Cómo responden** (desde el 21-sep, un teléfono por mensaje, sin copias):

| Mensaje | Teléfonos | Responden en <2 h | Pulsan «Aceptar» |
|---|---|---|---|
| 1 «¿Cómo te pareció…?» | 133 | 65% | 43 |
| 2 «DESCUENTO… HOY!!» | 114 | 54% | 45 |
| 3 «No te escribo más» | 79 | **29%** | 11 |

El tercero ya rescata a casi 1 de cada 3 de los que llegan hasta ahí. **El cierre «no te escribo más» funciona como gancho**, así que no lo quitaría.

### (b) Choques
- **Tuteo:** «Aún **está** a tiempo» es de usted y «**tu** precio» es de tú. Además, «¿te» va con mayúscula.
- **«Únicamente hoy»:** no es verdad (§0).
- **Doble urgencia:** el mensaje 2, 12 minutos antes, ya dice «para HOY!!». Dos «hoy» seguidos pesan más que uno.
- **No insistir:** hoy el tercero es el que cierra la cadena. Si se cambia por uno de urgencia sin cierre, la cadena termina empujando y no avisando de que paramos.
- Si este mensaje fuera una plantilla de Meta (fuera de la ventana de 24 h), el texto de urgencia la llevaría a la categoría MARKETING, que ya nos rompió la entrega una vez. Hoy sale a los 28 min, dentro de la ventana, así que no aplica mientras siga así.

### (d) Propuesta: ajustada, con el cierre que ya funciona
**(H):**
> ¡Aún estás a tiempo de aprovechar el precio de tu cotización! No te puedo asegurar que se mantenga después de hoy. ¿Te ayudo a terminar tu contratación? Si prefieres dejarlo para otro momento, no te escribo más: tu cotización queda guardada.

**(V)**, solo si existe la caducidad:
> ¡Aún estás a tiempo de aprovechar tu precio promocional! Es válido únicamente hoy. ¿Te ayudo a terminar tu contratación? Si prefieres dejarlo para otro momento, no te escribo más: tu cotización queda guardada.

---

## 2 · Después de ver la propuesta con descuento

**Montserrat:** «¿Qué te parece si aprovechamos el descuento de hoy? ¿te gustaría que avancemos con tu compra?»

### (a) Texto de hoy y quién lo manda
**No hay ningún mensaje automático.** De los 40 descuentos entregados desde el 1-oct, en 14 no hubo nada más después del PDF con descuento. Los seguimientos que sí hay **los escribe a mano una operadora**: textos distintos cada vez, mezcla de usted y tú, erratas. Aunque se guardan como `ai`, no son del bot.

| Fila | Sesión | Texto | Después del descuento | Resultado |
|---|---|---|---|---|
| 13986 | `waq_4312` | «¿Qué le pareció el descuento, le gustaría continuar?» | +52 min | Sin respuesta |
| 14483 | `waq_4356` | «¿qué le pareció el descuento?, ¿le gustaría que continuáramos…?» | +4 h | Sin respuesta |
| 14895 | `waq_4385` | «Hola, ¿que le pareció la propuesta?…» | +4 h | Responde y sigue (es el F1 de la revisión del 10-oct) |
| 15174 | `waq_4408` | «¿Qué te pareció la propuesta?, ¿continuamos con la contratación?» | +65 min | Responde: «¿Algún descuento más?» |
| **15297** | **`waq_4427`** | **«¿Qué te parece si aprovechamos el descuento de hoy? ¿te gustaría que avancemos con tu compra?»** (el texto 2 de Montserrat, literal) | +19 min | Responde: «Estoy por revisar más opciones para poder comparar» |

Llevan 8 envíos manuales desde el 5-oct, con 3 respuestas y 0 ventas por ahora.
**Ya firmado para ese momento:** L5, del bot, al entregar el descuento: «Con el descuento, tu *[VEHÍCULO]* queda en *$[PRECIO_VIGENTE] MXN* al año. ¿Te la dejo lista para contratar?».

### (b) Choques
- **«El descuento de hoy»** se puede leer como «el que te dieron hoy», que es verdad, o como «solo vale hoy», que no lo es. Es ambiguo a propósito; con (H) lo dejaría sin «de hoy».
- **Tuteo:** correcto. Va «¿Te» con mayúscula.
- **El caso real enseña un riesgo de lo que viene después** (`waq_4427`):
  - 15298: el cliente contesta «Estoy por revisar mas opciones para poder comparar / muchas gracias».
  - 15299: el carril de descuento vuelve a entrar («Déjame checar tu cotización para buscarte el mejor precio posible») con el descuento **ya entregado**.
  - 15301–15303: le pide el número de serie «para dejar tu descuento aplicado».
  - Es el mismo fallo del `#418` G3 (despedida o pausa confundida con objeción), aquí además repitiendo un descuento ya dado. Te lo dejo para el tracker.

### (d) Propuesta: automatizarlo una sola vez, con la cifra
Una sola vez, unos 20 min después del PDF con descuento, si el cliente no ha escrito. Sustituye a los envíos manuales.

**(H):**
> ¿Qué te parece si aprovechamos tu descuento? Tu *[VEHÍCULO]* quedó en *$[PRECIO_VIGENTE] MXN*. ¿Te la dejo lista para contratar?

**(V):**
> ¿Qué te parece si aprovechamos el descuento de hoy? Tu *[VEHÍCULO]* quedó en *$[PRECIO_VIGENTE] MXN*, y solo es válido hoy. ¿Te la dejo lista para contratar?

**Por qué con la cifra:** sin ella, el cliente tiene que abrir el PDF para saber de qué le hablan. Es lo mismo que pide L5 y el `#462`. «Contratar» en vez de «compra», para seguir el resto del flujo.
**Si responde con pausa o despedida, no se vuelve a ofrecer descuento:** se aplica §3 o D1.

---

## 3 · Después de «Déjame revisar», «lo voy a consultar» o «solo estoy cotizando»

**Montserrat:** «Entiendo, solo te recuerdo que tu descuento está vigente únicamente hoy. Si la propuesta te convence, ¿te gustaría aprovecharlo y continuar con tu compra?»

### (a) Texto de hoy y quién lo manda
Lo manda **el bot (n8n)**, con dos salidas según el caso. Son 14 casos reales desde el 21-sep, sin contar uno de prueba:

**1. Gancho de pausa D2** (`MANEJO DE PAUSA` del prompt), en 6 casos:
> Claro, tómate tu tiempo. Solo te comento: tu cotización con Quálitas hoy tiene precio preferencial si la contratas por este medio y la puedes pagar a 3, 6 o 12 meses sin intereses (MSI) con tarjetas de crédito participantes (Banamex, BBVA, Santander, HSBC…). Aquí estoy cuando quieras retomar 😊

Casos: 11651 «Lo checo y le comento más tarde», 11781 «deje lo checo con mi esposa», 12033 «Lo reviso», 13236 y 13278 «déjame checar», 14851 «Lo checo y le aviso».

**2. Carril de descuento**, en 5 casos:
> Déjame checar tu cotización para buscarte el mejor precio posible. Ahorita te cuento.

Casos: 15286 y 15293 «lo voy a revisar». También 14440 y 14451 «Estoy cotizando otras opciones le agradezco su atención.», que **según la tabla firmada del `#418` son despedidas**, y 15298 (§2).

**Otras salidas:**
- 12498 «Solo estoy cotizando, gracias» → reoferta con «¿o prefieres ver otra cobertura…?». Es de antes del `#461`.
- 13549 «Estoy cotizando» → «Aquí estoy para cuando tengas dudas… Sin prisa 😊». Bien.
- 12023 «estoy cotizando y viendo cuál es la mejor opción» → le da todas las opciones. Es de antes del `#461`.

### (b) Choques
- **D2 una vez por conversación (`#418`, firmado):** el texto 3 es en realidad una nueva redacción del gancho de pausa. No choca si **sustituye** al gancho actual y sigue saliendo una sola vez. Choca si se suma: serían dos ganchos.
- **No insistir tras una despedida:** **«solo estoy cotizando» no es una pausa.** Con «gracias» o «le agradezco su atención» es despedida (tabla del `#418`: «Gracias, pero de momento era una cotización. Me espero.» = despedida) y recibe D1, sin urgencia. Sin agradecimiento es un rechazo blando, y le toca la pregunta firmada del 22-sep («¿Es por el precio o te quedó alguna duda?»), no un «solo hoy».
- **La firma del `#567`:** el texto de «retomar» firmado («Sin problema, [NOMBRE]. Aquí te espero cuando lo tengas 🙂 / Solo recuerda que la oferta vence *hoy*…») cubre un momento casi igual, cuando el cliente aplaza. Si salen los dos en la misma conversación, el cliente recibe dos «vence hoy». **Regla:** en una conversación sale un solo recordatorio de urgencia, el primero que toque.
- **«Tu descuento»:** si aún no hubo descuento, el cliente no tiene ninguno. El texto tiene que bifurcarse según haya descuento o no.
- **«Únicamente hoy»:** no es verdad (§0).
- **Tuteo:** correcto.

### (d) Propuesta: sustituye al gancho D2, una vez, solo para pausas
**(H), con descuento entregado:**
> Claro, tómate tu tiempo. Solo te recuerdo que tu precio con descuento, *$[PRECIO_VIGENTE] MXN*, es el de hoy y no te puedo asegurar que se mantenga. Si la propuesta te convence, ¿te la dejo lista para contratar?

**(H), sin descuento:**
> Claro, tómate tu tiempo. Solo te recuerdo que el precio de tu cotización es el de hoy y no te puedo asegurar que se mantenga; además la puedes pagar a 3, 6 o 12 meses sin intereses con tarjeta de crédito participante. Si te convence, ¿te la dejo lista para contratar?

**(V):** las mismas, cambiando «es el de hoy y no te puedo asegurar que se mantenga» por «es válido únicamente hoy».

**Ajustes frente al gancho actual:**
- Se quita la lista de bancos: ponía a BBVA en 12 MSI y la KB dice que no.
- Se cierra con la pregunta de avance en vez de «Aquí estoy cuando quieras retomar», que es lo que pide Montserrat.

**No aplica a** «solo estoy cotizando» ni a ninguna despedida (ver (b)).

---

## 4 · Resumen para la firma

| # | Montserrat | Propuesta | Depende de |
|---|---|---|---|
| 1 | Tercer recordatorio con «únicamente hoy» | Ajustada: tuteo, urgencia (H) y **se conserva el cierre «no te escribo más»** | §0 |
| 2 | Tras el descuento | Ajustada: **automatizarla una vez a +20 min, con la cifra**; sustituye a los envíos manuales | §0 |
| 3 | Tras «déjame revisar» | Ajustada: **sustituye a D2, una vez, solo para pausas**; bifurcada según haya descuento; **fuera** «solo estoy cotizando» | §0 y la regla de «un solo recordatorio de urgencia por conversación» con el `#567` |

**Para el tracker (no es copy):**
- El carril de descuento vuelve a entrar con el descuento ya entregado y pide el número de serie (`waq_4427` 15298–15303).
- El origen de los tres mensajes de seguimiento: confirmar si es `qualitas_leadfollowuppolicy` vía n8n.

Agente: Mejoras Conversación
