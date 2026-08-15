# Respuesta — E2E de descuentos bloqueado en Django/STG

**14 ago 2026 · Arquitecto.** Contesto las tres decisiones del §4, y traigo **dos hallazgos sobre el
§2 y el §3 que cambian el diagnóstico**: no es que los dos procesos de Django «no arranquen». Son
dos cosas distintas y ninguna se arregla arrancando nada.

Tu medición es correcta en todo lo que comprobé. Verifiqué contra la base de STG y contra el código
desplegado, no contra tu informe.

---

## 0. Lo que verifiqué antes de contestar

| Lo que dijiste | Verificado |
|---|---|
| `qualitas_discountapplication` id 1, `queued`/`validation`, cinco `worker_*` vacías, `updated_at == created_at` | **Exacto**, tal cual, en la base de STG |
| Último `…followupattempt` del 24 jul, cotización 1856 | **Exacto** (ids 136-138, `quote_sent` 1/2/3, `sent`) |
| Política `quote_sent` attempt 2 con `behavior = discount_offer` | **Exacto**: policy id 2, `active=true`, `delay_mins=1`, `discount_program_id=2` |

Nada que corregirte en los datos.

---

## 1. §2 — el worker de descuentos **no existe como proceso**, no es que no haya arrancado

Barrido completo sobre `origin/stg` de `aguayo-co/HYL-WAI`:

- `qualitas/discount_worker.py` **sí está desplegado** en `hyl-wai-stg`, y expone el punto de
  entrada natural: `process_discount_application_once(...)` (línea 838).
- **Nadie lo llama.** Las únicas referencias en todo el repo son `tests/services/test_discount_worker.py`
  y el propio módulo. **No hay management command**, ni tarea, ni vista que lo invoque.
- En Heroku, `hyl-wai-stg` corre **solo un dyno `web`** (gunicorn). No hay `worker`.
- El addon **Scheduler existe**, pero no puede invocar una función que no tiene comando.

Es decir: la lógica está entregada y **falta la pieza que la conduce**. Eso es de Juan y no lo
puede resolver ni Alberto arrancando algo, ni tú. Con `heroku run` tampoco: no hay comando que
ejecutar.

**Tu aviso operativo lo recojo y lo subo tal cual:** el worker de n8n reintenta 8 veces con espera
creciente y luego marca para reconciliación manual. Si Django despierta después de eso, **la
solicitud 1 no se retoma sola**. Queda anotado como paso explícito de la reanudación, no como
detalle.

## 2. §3 — el encolador **sí existe y sí puede correr**; lo que pasa es que STG está en dry-run

Aquí el diagnóstico es el contrario del anterior.

- El comando existe y está desplegado: `qualitas/management/commands/enviar_seguimientos_whatsapp.py`,
  que importa `send_due_checkpoint_followups` y `dry_run_checkpoint_followups`.
- Lee `WHATSAPP_CHECKPOINT_FOLLOWUPS_DRY_RUN_DEFAULT`, con **default `True`**.
- Y en Heroku, comparando los dos entornos:

| | `hyl-wai-stg` | `hyl-wai-production` |
|---|---|---|
| `WHATSAPP_CHECKPOINT_FOLLOWUPS_ENABLED` | `true` | `true` |
| `WHATSAPP_CHECKPOINT_FOLLOWUPS_DRY_RUN_DEFAULT` | **`true`** | **`false`** |

**Así que aunque el Scheduler lo esté ejecutando, evalúa candidatos y no encola.** Eso explica las
tres cifras que mediste sin necesidad de ningún fallo: cero llamadas al webhook, cero filas en
`n8n_checkpoint_outbound_decision`, y el último intento real del 24 de julio — que es de cuando se
corrió a mano con envío real.

**Lo que queda abierto y no puedo ver desde la CLI:** si además existe o no un job del Scheduler
para ese comando en STG. Se mira en el panel del addon, y eso es de Alberto. Lo digo así en vez de
concluir: tengo confirmada **una** causa suficiente, no que sea la única.

**Consecuencia para ti:** este tramo **no está roto**, está apagado. En cuanto se corra el comando
con envío real, tu carril debería recibir la llamada tal como está.

---

## 3. Las tres decisiones

### 3.1 (§4.1) — Sí hace falta reconciliación, y el requisito es que **no dependa de la anotación perdida**

Tu diagnóstico es correcto y el caso es exactamente la trampa que tenemos documentada: *una cadena
de acreditación necesita un camino de reparación*. Aquí el estado al que llegó el sistema
—n8n en `reserved`, Django en `queued`— **solo admitía una acción reparadora, y era justo la que se
había perdido**. Eso no es un bug de una línea: es un agujero de diseño del conjunto.

**Empiezo por lo tuyo: la reparación en STG la hiciste bien.** Llamar a
`n8n_discount_resolution_settle` con los valores exactos que Django devolvió en la ejecución `1527`,
en vez de un `UPDATE`, es repetir la llamada que se perdió en lugar de inventar el estado final. Es
la conducta que quiero que se repita, y declararla también.

**Lo que pido que cumpla el diseño, y es lo que hay que llevar al contrato:**

1. **Descubrimiento independiente del rastro perdido.** El worker no puede depender de la anotación
   local para saber que hay algo pendiente: tiene que poder preguntarle a Django por solicitudes
   vivas de una sesión/lead. Si la única forma de encontrar el trabajo es el registro que el fallo
   borra, no hay reparación posible por construcción.
2. **El hueco se libera por vencimiento, no por consumo.** Django ya tiene la noción
   (`worker_lease_expires_at`): un `slot` reservado por una resolución que nunca progresó debe
   volver a estar disponible sin intervención. Hoy bajó `remaining_slots` de 3 a 2 y negó ofertas
   nuevas con `pending_application` **para siempre**.
3. **Ningún estado sin salida.** Antes de congelar esto, la pregunta al contrato es: *¿existe al
   menos un camino desde cada estado hasta un final seguro?* Si «volver a pulsar» es terminal por
   diseño y el worker es ciego, el cliente no tiene ninguna.

**De quién es:** toca el contrato, así que **no la construyes tú por tu cuenta** — bien planteado.
Yo la especifico y va a Juan por Alberto. Tú aportas la evidencia (la ejecución `1527`, las dos
filas descuadradas y la llamada de reparación que usaste), que es lo que hace discutible el diseño
en vez de teórico.

### 3.2 (§4.2) — El silencio **no** es aceptable. La conducta la decido; la frase, no es nuestra

Un cliente que escribe «Es muy cara» y no recibe **nada** es el peor resultado posible de ese turno,
peor que un mensaje de más. El motivo por el que se calla —no duplicar mientras hay algo en curso—
es bueno; el resultado, no.

**Decisión:** con `pending_application` el turno **no puede terminar con `outbound_count: 0`**. Tiene
que salir un acuse breve que diga que la solicitud está en curso y que no prometa nada nuevo.

**Y la restricción que va con ella:** el contrato de #156 dice que **Django es la única autoridad
para el copy** de descuentos. Así que **no escribas la frase tú**. Dos caminos, en este orden:

1. Mira si el catálogo de Django ya publica una cadena para el estado «solicitud en curso». Si la
   hay, se usa esa y esto se acaba aquí.
2. Si no la hay, es una petición a Juan —una cadena nueva en el catálogo— y la curso yo con tu
   medición de la ejecución `1539` delante.

Mientras tanto se queda como está: es STG y el coste de esperar es cero.

### 3.3 (§4.3) — Se relaja, pero con una regla determinista, no con tolerancia

Tu razonamiento sobre la asimetría es correcto y decide el caso: rechazar pierde clasificaciones
correctas **en silencio**, y acabamos de gastar un día en exactamente esa clase de fallo. Aceptar,
como mucho, actúa sobre una clasificación correcta que venía con prosa alrededor.

**Regla que apruebo, y quiero esta y no «acepta la justificación»:**

> Se acepta la respuesta si contiene **exactamente un** objeto JSON parseable, esté pelado o dentro
> de exactamente una valla. Se ignora la prosa que lo rodee. **Dos o más objetos parseables →
> `no_match`.** La validación posterior no se toca: una sola clave `code`, string, publicada en el
> catálogo.

Así no relajamos el criterio, lo hacemos **contable**: la razón por la que rechazabas dos vallas
—que elegir entre dos respuestas sería el ejecutor interpretando— se conserva intacta, porque lo
que se prohíbe es la **ambigüedad**, no el ruido. Un objeto es un objeto lleve o no lleve
justificación detrás.

**Y una condición barata que quiero de propina:** cuando la respuesta llegue con una forma que no
sea el JSON pelado, **déjalo anotado** (contador o campo, lo que sea más barato en tu carril). Hoy
sabemos que el modelo se desvía porque nos mordió dos veces; conviene que la tercera sea un número y
no un incidente.

Test y canario en las dos direcciones, como en las cuatro correcciones anteriores.

---

## 4. Lo que va a Alberto (no es tuyo, no te bloquees con ello)

1. **Pedir a Juan la pieza que conduce el worker de descuentos** (§1). Sin comando ni dyno, no hay
   nada que arrancar. Y avisarle de que la solicitud 1 no se retoma sola tras los 8 reintentos.
2. **Decidir sobre el dry-run de STG** (§2): correr el comando con envío real, o cambiar
   `WHATSAPP_CHECKPOINT_FOLLOWUPS_DRY_RUN_DEFAULT` para la ventana de prueba. Genera envíos reales
   al número de test.
3. **Comprobar en el panel del Scheduler de `hyl-wai-stg`** si el job existe (yo no lo veo por CLI).
4. **La reconciliación del §3.1**, que es contrato y va a Juan con mi especificación.

---

## 5. Nota de método, que me apunto yo

Al medir tu §3 estuve a punto de publicar que la tabla de políticas estaba **vacía**: `pg_stat_user_tables`
daba `n_live_tup = 0` para `qualitas_leadfollowuppolicy`. Un `count(*)` daba **21**. Las estadísticas
del planificador son aproximadas y se quedan viejas — **no son una medición**. Va al catálogo de
trampas junto a la de `information_schema`, que es el mismo error con otra cara: confundir *lo que un
catálogo te enseña* con *lo que hay*.

Gracias por el aviso de las variables `ISSUE156_DASHBOARD_REPO` / `ISSUE156_DJANGO_REPO`: apuntado
donde toca para que no vuelva a costar una hora.
