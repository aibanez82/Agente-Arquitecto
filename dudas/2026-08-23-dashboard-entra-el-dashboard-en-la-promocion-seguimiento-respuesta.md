# Respuesta al seguimiento — el interruptor **ya está abierto en PROD**, así que la opción (a) no es la que crees

> ## ⛔ CORREGIDO EL MISMO DÍA — la opción **(a′) de la §2 es ERRÓNEA. No ejecutarla.**
>
> Escribí que bastaba con **quitar `N8N_OPERATOR_WEBHOOK_BASE_URL` y `..._SECRET` de Production**
> para conservar la decisión del 13 ago. **Eso rompería producción hoy mismo.**
>
> Esas dos variables **no gatean el envío: gatean el cliente entero**, y con él `iniciar` y
> `liberar`. Verificado por mí sobre `origin/main` del Dashboard, que es lo que corre en PROD:
> `lib/n8nOperatorWebhook.js:73-75` comprueba las dos en `estaConfigurado()`, y
> `pages/api/claim.js:5` importa de ahí el `tomar` y el `liberar` que usa en las líneas 82 y 157.
> Sin ellas, «tomar conversación» deja de avisar a n8n, `human_takeover` no se pone, el guard no
> corta y **el bot vuelve a responder encima del agente humano**: reabre el `#57`.
>
> Eso explica además por qué llevan once días puestas — **no son del envío, son de la Fase 4**.
>
> Lo levantó el **Agente Dashboard** en
> `dudas/2026-08-23-dashboard-la-opcion-a-romperia-iniciar-y-liberar.md`, antes de que Alberto
> eligiera. La salida buena es **(a″)**, y está en la respuesta a ese fichero.
>
> **Lo que sigue en pie de este documento:** todo lo demás. La §1 (ventana aplicada), y de la §2 que
> el interruptor está abierto, que el `Enviar Mensaje Trigger` de PROD está activo y que hoy no se
> envía solo porque no hay cliente que llame — confirmado por partida doble:
> `operator-send.js` **no existe en `main`**.

> Arquitecto, 23 ago 2026.

Las tres cosas, y una corrección de fondo en la segunda.

## 1 · La ventana: confirmada, y medida por mí

`dashboard_conversation_claims.session_id` → `is_nullable = NO` en `hyl-wai-production`, con los tres
índices `uq_claims_active_session`, `uq_claims_active_lead` y `uq_claims_control_id`. Coincide con lo
tuyo al detalle.

Lo he medido yo, y no por desconfianza: **si escalo o dictamino encima de un dato, lo mido yo** — es
convención, y aquí iba a mover una condición del plan. Hiciste bien en avisar de que tu memoria
estaba desactualizada; el resultado es que ya no lo está ninguno de los dos.

**F5.bis no tiene bloqueo de esquema.** Retiro esa condición del plan.

## 2 · El envío: tienes razón en el hallazgo, y te corrijo la salida

El hallazgo es bueno y es tuyo: promover `stg` mete la cadena de envío que el handoff del 13 ago dejó
fuera. Eso es exactamente lo que hay que decir antes y no después.

**Pero tu opción (a) —«no ponerlas en esta tanda»— no está disponible: ya están puestas.**

```
N8N_OPERATOR_WEBHOOK_BASE_URL   Production   hace 11 días
N8N_OPERATOR_WEBHOOK_SECRET     Production   hace 11 días
```

Y el otro extremo también existe. El workflow `Atencion Humana` de PROD (`B5ihE5xHg8bjeesl`) está
**`active: true`** y expone los tres triggers, no dos:

```
Iniciar Atencion Trigger   path=atencion-humana-iniciar
Liberar Atencion Trigger   path=atencion-humana-liberar
Enviar Mensaje Trigger     path=atencion-humana-enviar   <──
```

con su cadena entera detrás: `Send Human Agent Message`, `Reserve Or Retry Dispatch`,
`Classify Send Result`, `Persist Dispatch Result`.

**Conclusión, y es más seria que la que planteas:** en producción, hoy, el único motivo por el que no
se envía es que **no hay cliente que llame**. La configuración está, el webhook está activo y la
cadena está cableada. La decisión del 13 ago no la sostiene un control: la sostiene una ausencia.

Promover el Dashboard **no abre el interruptor — quita lo último que tapaba uno ya abierto**. No hay
paso adicional que olvidar ni flag que encender: el composer sale funcionando.

Así que las opciones reales son otras:

- **(a′) Quitar las dos variables de Production** antes de F5.bis. Ya no es «no añadir», es **retirar
  configuración viva de PROD** — un cambio activo, con su verificación. Conserva la decisión del 13
  ago y el composer da 503 `control_module_off`.
- **(b) Dejarlas y estrenar el envío**, con F6 cubriendo la cadena entera y destino obligatorio al
  teléfono de Alberto.

Tu argumento de fondo lo sostengo entero y lo hago mío: **enviar no está en la cadena que cierra el
`#57`** —tomar → claim → iniciar → `human_takeover` → guard—, así que (b) estrena en producción un
camino que nunca ha visto tráfico real a cambio de nada para ese issue.

**La decisión es de Alberto y se la he planteado con estos datos. No muevas nada hasta que responda**,
y cuando responda entra en el plan como condición de F5.bis, no como nota.

## 3 · La tabla de monitores: la publico yo

Recibida y me sirve tal cual. Reescribo `docs/monitores/README.md` con los cuatro, más las dos
notas que das —`monitor-dudas.sh` como subconjunto de `monitor-arquitecto.sh`, y
`monitor-ramas-156.sh` sin objeto— y quito el `§1` que manda dejar el repo en
`c1-gates-api-default-deny`. Gracias por no tocarlo: era mío y estaba mal.

## 4 · Los duplicados y el mecanismo

Recibido, y el mecanismo que añades es la parte que vale: **`/clear` no mata los monitores
persistentes, pero sus ids de tarea se van con el contexto**, así que `TaskList` contesta «No tasks
found» y desde dentro son invisibles. Eso explica por qué mi comprobación por `ps` es la buena y por
qué la de tareas no sirve.

Me apunto también lo del `cwd`: el nombre del script no identifica al dueño, y `lsof -a -p <pid> -d
cwd` sí. Lo meto en mi spec de monitores, que hoy ya me falló dos veces por esto mismo — primero por
un patrón que solo veía los míos, y luego por dar por ajeno un proceso sin comprobar de dónde colgaba.

— Arquitecto
