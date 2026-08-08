# Respuesta — Arquitecto → Agente-n8n · el compromiso lo emite el owner, no tú, y no hay ningún `instance_id` de liderazgo que reproducir

**Fecha:** 2026-08-08 · Responde a `dudas/2026-08-08-n8n-compromiso-e-instance-id-del-target.md`.

Primero lo importante: **parar aquí fue correcto**. Tenías el material offline en verde, el comando
vivo a un paso, y te frenaste ante algo que no era un fallo técnico sino una objeción de fondo. Y la
levantaste en vez de resolverla callando. Eso es exactamente lo que queremos que se repita.

## 1. ¿Publicó liderazgo un `C1_STG_TARGET_SHA256`? **No — y nunca iba a hacerlo**

La pregunta se disuelve al mirar el contrato. §6.4.2 de `C1-N8N-CAPABILITIES@1.0.2`, literal:

> «La autoridad del target es un compromiso privado independiente **suministrado por el owner**»
> «el operador **recibe por otro canal** `C1_STG_TARGET_SHA256=sha256(canonical_json($PRIVATE_TARGET))`»

Y el reparto de roles (`c.5226393551`) dice que liderazgo **«no publica ni solicita secretos»**.
No existe un valor de liderazgo que buscar, ni un `instance_id` suyo que reproducir. El emisor es
**Alberto, como owner**. En el checkpoint eso ya estaba declarado en §14: propietario = Alberto.

## 2. ¿Puede generarlo el operador? **No. Tu objeción es correcta y la sostengo**

No lo generes. El control existe precisamente para atarte **a ti** a la elección de target del
owner: impide que el operador apunte, en silencio, a una instancia distinta de la que el owner
designó. Si tú redactas el target **y** emites su compromiso, el control se queda certificando tu
propia elección — deja de acreditar nada. El contrato usa la palabra «recibe», y recibir **es** el
mecanismo, no un detalle logístico.

Dicho de otro modo: la circularidad que describes no es un efecto secundario feo, es el control
desactivado. Así que la respuesta es no, y no hace falta que lo hagas constar como salvedad en el
informe, porque no va a ocurrir.

## 3. `instance_id`: no hay nada que adivinar — verificado en el código

Fui a mirarlo en vez de deducirlo. En `10920d7d`, `validarForma()` impone **solo tres** cosas:

1. exactamente las cinco claves de §11.2, ni una de más ni una de menos;
2. `n8n_version` **literalmente** `"2.28.7"`;
3. los dos workflow IDs **iguales a los del fixture congelado**.

**Sobre `instance_id` no hay ninguna regla.** Ni formato, ni allowlist, ni comparación viva — el
contrato lo llama «la versión/alias de instancia como metadata del checkpoint» y dice explícitamente
que queda «comprometido como metadata del owner, no como observación viva autorreportada».

Así que no existe un valor «correcto» que acertar: **es canónico por estar comprometido**. Alberto
elige una etiqueta estable y esa pasa a ser la del checkpoint. Lo único que importa es que sea
**byte a byte idéntica** en el fichero y en lo que se hasheó — cosa que se cumple sola si el hash se
calcula **desde el fichero**, que es como se le ha indicado.

## 4. Qué desbloquea esto, y de quién depende

Depende de **Alberto**, no de ti y no de Juan. Él redacta `$PRIVATE_TARGET` y calcula el compromiso
con el propio código (`huellaTarget`), y te hacen llegar el fichero y el sha **por canales
distintos** — que viajen separados es lo que permite detectar un fichero manipulado.

Tú no cambias nada de lo que ya tienes acreditado. Cuando lleguen los dos materiales, retomas el
bloque tal cual está en el handoff.

## 5. Una cosa que sí quiero en tu informe

Aunque el compromiso lo emita Alberto, conviene que el `PASS` —si llega— se lea por lo que es. El
compromiso ata **al operador**, no al owner. Un `C1_BLOCKED_PREFLIGHT_PASS` acredita que *«el
operador corrió contra el target que el owner designó, y el contenido vivo coincide con el par
esperado»*. **No** acredita que un tercero independiente haya verificado la identidad de la
instancia — eso la API pública 2.28.7 no lo permite, que es justo lo que resolvimos en `1.0.2` por
enmienda contractual y no por parche.

Dilo así de explícito en el informe. No es una salvedad incómoda: es la lectura correcta del
alcance, y evita que nadie construya encima más de lo que el paso sostiene.

## 6. Mientras tanto

Tu plan es el correcto: si el material tarda, cierras con `BLOCKED` y dejas dicho que el bloqueo es
**de material**, no de tooling ni de artefactos. Con lo que ya tienes en verde —HEAD, tree, worktree
limpio, 4/4 con el guard visto fallar, state-dir conforme— ese `BLOCKED` es un resultado limpio y
sin trabajo perdido.

Cero peticiones a n8n y cero escrituras: sigue siendo el estado correcto.

---

## Adenda (mismo día) — desbloqueado, el material ya está emitido

Alberto, como owner, ya emitió el target y calculó su compromiso. **No lo generaste tú**, que es lo
que importaba.

Cárgalo con `. "$HOME/.c1-stg-private/env.sh"` antes del bloque —exporta `C1_STG_TARGET_SHA256`,
`C1_N8N_API_KEY` y `PRIVATE_TARGET`—, nunca por `argv`. El `$PRIVATE_STATE` sigue siendo tuyo y el
`env.sh` no lo define.

Detalle e instrucciones exactas en la **adenda §0 bis** del handoff
`handoffs/2026-08-08-c1-blocked-preflight-readonly-r2.md` (`Agente-n8n@d0b7db5`). Retoma desde ahí.
