# Noche 10→11 oct (STG, bot `5adf0e57`): petición de llamada, regresión de hitos con Sonnet 5.5 y `#591` v2 (la E, pendiente de firma)

> De: Agente QA & Testing · Para: Arquitecto-IA-Insurmind
> Responde a: `Agente_QATest_Qualitas:handoffs/2026-10-10-noche-llamada-591v2-regresion.md` (`a2934f4`).
> **Versión:** bot `dNqtM20ij6ecZYAX` **`5adf0e57`** (536 nodos), igual al principio y al final de las 9 corridas.
> Runner: `Agente_QATest_Qualitas:runners/noche_llamada_591_stg.js` (`664df8b`; variante LS y criterio del escalado en `1803d48`).
> Protocolo:
> - sesiones `QA-SUITE-NOCHE-*`, sin dígitos;
> - un clon propio de la 2683 por sesión (cotizaciones 3011–3019);
> - **sin `waq_2981`**;
> - residuo **cero**: medido después de cada corrida, todo borrado por ID.

## Resumen

| Corrida | Resultado |
|---|---|
| **R** (hitos, ×3) | **3/3**. Las tres frases de detector aparecen literales en las tres |
| **L** (llamada, ×3) | El turno 1 da **B sin descuento** en 3/3, sin enlace y sin ofrecer devolver la llamada. El turno 2 **no es C**: ver abajo, es el código. El escalado y «contratar por aquí» van bien |
| **LS** (llamada con el contador sembrado, ×3) | Turno 2: responde el **modelo** (no C) en 3/3. Turno 3: **no repite** en 3/3 |
| **E** (`#591` v2 con emisión) | **Pendiente.** Mi capa pide la confirmación de Alberto en mi sesión para emitir, y se la estoy pidiendo. Si no está, queda escrito aquí y no se emite |

## Corrida R — regresión de hitos con Sonnet 5.5 (sin emitir)

Hice tres conversaciones hasta el resumen (`R1`, `R2` y `R3`) y conté las frases literales en el texto reservado
(`Stash Main Reply Payload`):

| Frase de detector | N |
|---|---|
| «Continuamos con» + «cobertura» | **3/3** (88546, 88561, 88575) |
| «Número de serie:» o «Placas» | **3/3** (en los resúmenes 88554, 88568 y 88583) |
| «\*Domicilio:\*» | **3/3** (mismos resúmenes) |

`dio_datos_personales` no se cuenta, como pediste (lo lleva el `#590`).

## Corrida L — petición de llamada (sin emitir)

**Orden de los turnos (declarado):**
1. «¿Me pueden llamar?»
2. «Prefiero que me marquen, no me gusta escribir»
3. La misma petición otra vez: repito el turno 1
4. «Quiero contratar por aquí»
5. «Quiero hablar con un agente», **al final**, porque deja la sesión derivada y lo que viniera detrás no mediría
   «la conversación sigue con normalidad».

| Turno | L1 · L2 · L3 | Lo que salió |
|---|---|---|
| 1 «¿Me pueden llamar?» | 88514 · 88525 · 88536 | **B sin descuento** por el carril `Llamada Fija Copy` (`clase: peticion`, `variante: B_SIN_DESCUENTO`). El texto firmado lleva el precio vigente de **$10,858.25**. **Sin enlace** y sin ofrecer devolver la llamada. **PASS** en las 3 |
| 2 «Prefiero que me marquen…» | 88515 · 88526 · 88537 | **B otra vez**, idéntica. **No es C** |
| 3 la misma otra vez | 88517 · 88527 · 88538 | **B otra vez** |
| 4 «Quiero contratar por aquí» | 88518 · 88529 · 88539 | Sigue el flujo normal: «Continuamos con \*Cobertura Amplia…\* … ¿Me das tu nombre completo?». **PASS** |
| 5 «Quiero hablar con un agente» | 88520 · 88531 · 88542 | **Escala como hoy:** «…contactar directamente con un agente especializado…: https://api.whatsapp.com/send?phone=525537511678&text=…». Sin texto de llamada. **PASS** |

### Por qué se repite B en L: el arnés, no el bot

`Persist Contador Llamada`, que marca `captured_data.llamada.b = true`, es una **rama lateral de
`Settle Llamada Fija Sent`**. Solo corre cuando el texto **sale de verdad**; el propio nodo dice «solo cuando el texto
SALIÓ». En mis sesiones sin dígitos el fence deniega el envío (`Llamada Fija Fence Denied`), así que el contador no se
escribe nunca (medido: `llamada = {}` después de cada turno) y `decideLlamada` vuelve a elegir B. Con un envío real no
pasaría. Por eso lo medí también con la variante **LS**.

### Corrida LS — el mismo guion con el contador sembrado tras el turno 1

Después del turno 1 escribí en la sesión **lo mismo que escribiría `Persist Contador Llamada`** si el envío hubiera
salido: `llamada = {"b": true}`, citado en la traza. El resto del guion es idéntico.

| Turno | Ejecución | Texto (reservado) |
|---|---|---|
| LS1 · l2 | 88592 | «Entiendo, no hace falta que escribas mucho. Por aquí te lo dejo lo más ligero posible: te pido los datos de uno en uno y, cuando lleguemos a las placas y el número de serie, puedes mandarme una foto de tu tarjeta de circulación para no teclearlos. ¿Empezamos con tu nombre completo?» |
| LS1 · l3 | 88593 | «Por este medio no puedo programar una llamada, pero sí puedo hacer que sea muy corto. Te pido un dato a la vez y basta con respuestas breves. Las placas y el número de serie los puedes mandar con una foto de tu tarjeta de circulación. ¿Me das tu nombre completo para empezar?» |
| LS2 · l2 | 88603 | «Por aquí no puedo organizar una llamada, pero te lo pongo fácil. Te pido los datos uno a uno, y las placas y el número de serie los puedes mandar con una foto de tu tarjeta de circulación. ¿Empezamos con tu nombre completo?» |
| LS2 · l3 | 88604 | «No tengo forma de programar llamadas desde este chat, y prefiero decírtelo claro. Aquí te lo hago lo más corto posible. Son pocos datos, y con una foto de tu tarjeta de circulación me ahorras escribir las placas y la serie. Tu cotización de Cobertura Amplia está en *$10,858.25 MXN* al año. ¿Te la dejo lista para contratar?» |
| LS3 · l2 | 88614 | «Entiendo. Por este medio no puedo hacer llamadas, pero lo hago lo más ligero posible. Te pido los datos de uno en uno y solo me respondes lo justo. Tu *TOYOTA HIGHLANDER 2020* quedaría con Cobertura Amplia, pago anual de *$10,858.25 MXN*. ¿Empezamos?» |
| LS3 · l3 | 88615 | «Por aquí no tengo manera de programar llamadas, y no quiero prometerte algo que no puedo cumplir. Lo que sí puedo hacer es que escribas lo mínimo. Te pido un dato a la vez, y para las placas y el número de serie basta una foto de tu tarjeta de circulación. ¿Arrancamos con tu nombre completo?» |

- **Turno 2: no es C en ninguna.** Responde el modelo, que no ofrece llamar, dice que por ese medio no puede programar
  una llamada y facilita el canal (datos de uno en uno, foto de la tarjeta). **Es lo que dicta el código**, no una
  deriva del modelo:
  - `clasificaLlamada` lee «Prefiero que me marquen» como **`peticion`** («prefiero … que me marquen» está en la regex
    de petición);
  - `decideLlamada` solo da **C** ante una **`queja`** («no me quieres responder», «nadie me contesta», «no me haces
    caso»…);
  - tras B, una `peticion` devuelve `null`, y entonces responde el modelo.

  O el criterio del handoff (C) o la regex del código no es lo que se quería. **FAIL contra el texto del handoff**, y
  te lo dejo a ti para decidir cuál de los dos cambia.
- **Turno 3: no repite** en ninguna de las tres. Cada texto es distinto del turno 1 y del turno 2. **PASS.**
- **D:** no apareció en ningún turno.
- Los turnos 4 y 5, igual que en L: **PASS**.

### Corrección de mi instrumento (declarada)

Mi primer criterio del turno 5 daba por escalado el turno si corría `Human Takeover Guard`. Ese nodo corre en todos los
turnos, así que no prueba nada. Lo cambié por lo que de verdad es el escalado de hoy: el enlace del agente especializado,
o `human_takeover` en la sesión. Con ese criterio reevalué los 6 turnos 5 (L y LS): los 6 llevan el enlace, así que el
veredicto no cambia, pero ahora se apoya en el dato correcto.

## Lo que no pude comprobar

- **Lo que entrega Meta.** Cito el texto de `Llamada Fija Copy` o el de `Stash Main Reply Payload`. Lo que hay detrás del
  fence no se ejerce: `Outbound Leak Guard`, las guardas de cifras y el envío.
- **El contador de llamada escrito por el propio grafo.** En LS lo sembré yo con el mismo contenido. Que
  `Persist Contador Llamada` lo escriba tras un envío real solo se mide con un teléfono real.

Agente: QA & Testing
