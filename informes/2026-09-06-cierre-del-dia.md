# Cierre del día — 6 de septiembre de 2026

> Arquitecto-IA-Qualitas. **Punto de retomada.**

## Lo que quedó en PROD

**Dos promociones, las dos con PASS medido por las dos partes.**

| | |
|---|---|
| Bot n8n | `9f2e8ba3-8b9f-492f-8469-5be4f9172b1a` · **319 nodos** |
| Mañana | paquete de 13 issues de STG (`#279 #323 #332 #334 #339 #340 #341` y familia) → 317 nodos |
| Tarde | escritor de copy de descuentos + literal único → 319 |
| `kb_chunks` | los seis chunks de accesorias: **los dos entornos byte a byte** |

**Lo que cambia para el cliente:** ante «¿tienes alguna promoción?» ya no recibe dos acuses del mismo hecho. Recibe el aviso y después **lo que ha cambiado**, con la frase comercial que fijó Alberto: «…Logré un descuento especial si contratas hoy conmigo». **Promesa comercial nueva en el carril Direct**, con su decisión expresa.

**La escritura del segundo import la lanzó Alberto en persona** desde la sesión del ejecutor: el clasificador de permisos frenó el `PUT` y el ejecutor **no pidió que lo hiciera el Arquitecto**. Correcto: habría sido lavar el permiso.

## Lo que se aprendió, y vale más que los arreglos

**1 · «El nodo se ejecutó» no es «el nodo actuó».** Diagnostiqué el emisor del mensaje malo leyendo la lista de nodos de una ejecución, y el `claim` de ese carril devolvía `[]`. Encargué un arreglo a un carril que no dispara. El emisor real se acredita por el `wamid`, que es lo que ata el nodo con la fila del ledger.

**2 · Un encargo mal acotado propaga su punto ciego al ejecutor.** Escribí «un literal, dos lectores» y eran **tres** — el tercero firmaba el `request_hash`. El ejecutor heredó mi «dos» y declaró el cierre sin volver a medir. Por eso toda declaración de inexistencia va con **ámbito, método y `versionId`**, y el criterio de aceptación la pide explícitamente.

**3 · Poner el escritor en un consumidor en vez de en la fuente garantiza que otro se escape.** Dos nodos clamaban de la misma función y solo uno pasaba por nuestra pluma. La solución no fue un nodo compartido —el fan-out de n8n habría duplicado el envío— sino **una fuente en el repo inyectada en dos nodos**, con `jsCode == fuente` verificado por consumidor. La propuso el ejecutor.

**4 · No recomendar sobre un campo sin leer para qué se usa.** Propuse vaciar el `copy` del `request_hash`; al leer `n8n_outbound_reserve` resultó que sostiene el `uncertain_no_retry`, que impide reenviar un mensaje que quizá ya llegó. Retirado antes de que costara nada.

**5 · Una herramienta puede tener el punto ciego justo donde dices que cubre.** La guarda de privilegios enumeraba el catálogo y preguntaba «¿lo usa el código?»; así, **un objeto que el código consulta y no existe nunca aparecía**. Ahora pregunta en las dos direcciones.

## Lo abierto, y de quién es

| Qué | De quién |
|---|---|
| **`#284`** — «Tomar conversación» roto en PROD por **dos** causas: seis `GRANT` ausentes **y** `dashboard_control_commands` sin crear (migración del 11 ago nunca aplicada). Retiene cuatro entregas del Dashboard | **Juan** |
| **`#343`** — un claim humano de 4 s mata una aplicación de descuento y la deja en `uncertain`, secuestrando la conversación | **Juan** |
| **`#342`** — el carril de descuentos no pasa por la memoria: el mensaje del cliente no se persiste. Causa diagnosticada | nuestro |
| **`#288`** — cerrado en la práctica por el escritor de copy; el nodo del Poller queda puesto en un carril que no dispara | nuestro |
| Promoción a PROD de la sonda de `hitoInteres`, el hito del ledger y el `#296` | **bloqueadas por el `#284`** |

## Decisiones de Alberto, tomadas hoy

- **Frase comercial del `#339`**: la de Django, «Logré un descuento especial si contratas hoy conmigo».
- **Opción A con fuente única en build-time**; **D descartada** por no tener defecto medido que la justifique (criterio `#179`).
- **Cadencia de seguimientos**: no se toca. Tres avisos en ocho minutos, misma config en PROD. Preferencia comercial, no defecto.
- **Barrido de `uncertain` en PROD**: no se hace. Advertido que una fila viva secuestra una conversación en curso, no solo el pasado.

## Limitación conocida, no deuda

El `request_hash` del carril Direct firma la frase de Django, no la enviada — la huella se calcula al reservar y el texto se decide al enviar. **No se arregla**: vaciar ese campo debilita el `uncertain_no_retry`, y hacerlo firmar lo enviado es la iniciativa D. Documentado en `docs/architecture/outbound-dispatch-request-hash.md`, con el disparador que la reabriría: ver un `uncertain_no_retry` bloqueando un mensaje legítimo.

Agente: Arquitecto-IA-Qualitas
