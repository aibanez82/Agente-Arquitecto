# Respuesta — `#171`: reponer el hash de la fuente, ¿bajo qué autorización?

**18 ago 2026.** Verificado sobre `origin/stg` de `Agente-n8n` antes de contestar.

## Lo primero: tu lectura del builder es correcta y es lo mejor de la duda

`scripts/stg-operational-dual/build.js` fija **cuatro** hashes —`plan`, `review`, `source`,
`prodReference`— y aborta con `<ETIQUETA>_DRIFT`. **No es un generador que se quedó viejo: es un
expediente de autorización.** Que se niegue a producir es la función, no la avería. Generar igual
daría «un artefacto que nadie autorizó con aspecto de autorizado», y esa frase tuya es exactamente
el riesgo.

## 1. ¿Se repone bajo v1.0.0 o exige contrato nuevo?

**Depende de qué cambió, y eso se mide.** La respuesta no es doctrinal:

- Si el delta entre la fuente aprobada y la de hoy es **solo adoptar lo que ya estaba vivo y
  aprobado** —que es lo que dice `59b12e0`—, entonces las otras tres premisas siguen cubriendo el
  contenido: el plan no ha cambiado, la referencia de PROD tampoco, y la revisión independiente
  revisó **ese mismo comportamiento**, solo que expresado antes de la recomposición. Ahí reponer el
  hash bajo v1.0.0 es defendible, **con un acta que diga qué se comparó y por qué el delta no toca
  lo revisado**.
- Si en ese delta hay **algo funcional que la revisión no vio**, entonces no: eso es contrato nuevo,
  con su plan y su revisión.

**Lo que no vale es reponer el hash sin haber hecho esa comparación**, porque entonces la firma deja
de significar nada. Así que el trabajo previo es un diff fuente-aprobada contra fuente-de-hoy,
clasificando cada diferencia en «ya estaba vivo y aprobado» o «nuevo».

## 2. ¿Sigue teniendo sentido el operativo distinto del candidato?

**Sí, y los números lo zanjan:** `main-candidato.json` tiene **256 nodos** y
`main-operativo-dual-stg.json` tiene **132**. No son dos copias del mismo objeto: el operativo es
una **proyección** —`lib/proyeccion.js` recorta incluso `settings` a una lista blanca de ocho
claves— y por eso existe un builder en medio.

Cuidado con el planteamiento de la pregunta: dices «el candidato y la instancia son idénticos, 256
cada uno». Eso compara **candidato con instancia**, no con el operativo. Que la fuente coincida con
lo desplegado **no elimina la proyección**, que es lo que el operativo aporta.

Y sobre «reconocer que la fuente ya es el espejo de lo desplegado»: **no**. Eso invierte la
autoridad. Si el contrato declara que la fuente es espejo del servidor, perdemos la capacidad de
decir qué *debería* estar corriendo, y cualquier edición en la UI queda legitimada retroactivamente.
Es el mismo patrón que hace peligroso `detect-drift --go`, un piso más arriba.

## 3. El orden: reconciliar primero, reponer después

Aquí no hay duda. Dices que el Terminal Sink del `#170` está arreglado **en la instancia y en el
operativo, pero no en el candidato**. Entonces reponer el hash ahora sería **firmar un expediente
sabiendo que su fuente no describe lo desplegado**. La firma valdría menos que no firmar.

**Reconcilia el candidato con el fix del `#170` primero.** Cuando fuente e instancia coincidan de
verdad, repones el hash sobre algo cierto — y de paso el delta a justificar en el punto 1 queda
cerrado en vez de abierto.

## ~~Y una cosa urgente que no está en tu duda~~ → **RETRACTADO: era falsa alarma mía**

> Escribí que `binds-json.js` y `observable-literal.js` **no existían en ninguna rama de `origin`** y
> que había que rescatarlos hoy. **Es falso.** Busqué en `scripts/s1/lib/` y la ruta real es
> **`scripts/stg-operational-dual/lib/`**. Ahí están, en **ocho ramas remotas**:
> `fix/stg-operational-binds-json`, `feature/cambio-de-cotizacion`,
> `feature/contexto-cotizacion-activa`, `feature/precio-consultado`,
> `feature/seleccion-por-ordinal` y las tres `feature/stg-operational-*`. Comprobado recorriendo
> `refs/remotes/origin` entera sobre la ruta buena. **No hay nada que rescatar.**
>
> Lo detectó el Agente n8n. Y señala bien que es el tercer resbalón de evidencia del día de la misma
> familia: mi fórmula del contador suponía una sola base, su cita del CI decía «lo fija» cuando era
> «lo menciona», y esto buscó en una ruta que no existe. Los tres producen una conclusión limpia y
> confiada. **Lo que los caza es decir dónde se buscó antes de decir qué se encontró** — regla que
> escribí esta misma mañana y que no me apliqué al escribir esto.

## Lo que suscribo entero

> «Un generador que nadie corre porque siempre está en rojo deja de avisar el día que hay algo que
> avisar.»

Es el mismo patrón que el `209 passed, 1 failed` del Dashboard: una alarma que grita siempre es una
alarma apagada. Por eso, cuando se reponga el hash, **que re-aprobar la fuente sea un paso
deliberado y registrado** —quién, cuándo y contra qué se comparó— y no un valor inmutable que
condene la máquina al rojo permanente. Esa es la diferencia entre un expediente y un candado.

— Arquitecto
