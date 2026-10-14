# E2E STG antes del día de PROD: K, V, R y E en verde. C (#586) **arreglado y en verde 3/3 sobre `ae699fe9`** (adenda 2), tras fallar en `327de5ea`

> De: Agente QA & Testing · Para: Arquitecto-IA-Insurmind · 14 oct 2026
> Responde a: `Agente_QATest_Qualitas:handoffs/2026-10-14-e2e-stg-paquete-prod.md`.
> **Versiones:** bot **`327de5ea`** y guard **`c31a3c54`**, medidas al principio y al final de las 13 corridas, sin cambios.
> Runner: `Agente_QATest_Qualitas:runners/prod14_stg.js` (`cffa92c`).
> Protocolo:
> - sesiones `QA-SUITE-PROD-*`, sin dígitos;
> - un clon propio de la 2683 por corrida (cotizaciones 5542–5554);
> - sin tocar sesiones de Alberto;
> - residuo cero en las 13 corridas, borrado por ID.

## Lo primero: `#586`, el segundo «Cancelar» cierra la sesión — **3 de 3**

| | C1 · C2 · C3 (como pide el handoff) | CX (variante: otro seguimiento entre los dos «Cancelar») |
|---|---|---|
| 1.er «Cancelar» | **B**, literal: «Entendido. ¿Es por el precio o te quedó alguna duda de la cobertura? Si prefieres dejarlo aquí, no pasa nada: tu cotización queda guardada.» (95068 · 95072 · 95075) → **PASS** | B (95079) → PASS |
| 2.º «Cancelar» | **Ni A ni ningún texto.** El modelo llama a **`Mark Session Closed`** y redacta «…contactar directamente con un agente especializado…: https://api.whatsapp.com/send?phone=525537511678…». Después `Authority Lost?` → `Terminal 240` → **`Terminal Sink`**: **no sale nada**, y la sesión queda **`closed`** (95069 · 95073 · 95076) → **FAIL** | **A**, literal: «De acuerdo, dejamos tu cotización tal como está. Si cambias de idea, aquí sigo.» (95080) → PASS |

**Por qué (en el código, `Merge Session Data` → `cancelarFijo`):** el carril fijo solo actúa si el último mensaje del bot es
el seguimiento de Django (`prev_ai_source === 'django_checkpoint_followup_v06'`). Con un envío real, tras mandar B el último
mensaje del bot pasa a ser esa B (`source: cancelar_fijo_586`). El segundo «Cancelar» ya no entra en el carril y cae al
modelo, que **interpreta «Cancelar» como baja: cierra la sesión y deriva**. La A solo sale si entre los dos «Cancelar» llega
otro seguimiento (CX).

**Cómo lo medí, para que lo puedas rehacer.** Con fence, el envío de B no escribe nada. Tras el 1.er «Cancelar» sembré lo
que habría escrito un envío real (las mismas columnas y el mismo `source` que el grafo):
- la fila `human` con `client_message_342`;
- la fila `ai` de B con `source: cancelar_fijo_586` y `motivo: cancelar586_B`;
- `captured_data.cancelar586 = {b: true}`.

Si solo hubiera sembrado el contador, el seguimiento seguiría siendo el último mensaje y saldría la A, que sería un PASS
falso. El 2.º «Cancelar» no lo toqué.

**Para el viaje a PROD:** con el paquete actual, un cliente que escribe «Cancelar» dos veces seguidas tras un seguimiento se
queda **con la sesión cerrada y sin respuesta**. No es lo que firmó Alberto («ni enlace ni cierre de sesión»). Opciones,
para que decidas tú:
1. que `cancelarFijo` reconozca también `prev_ai_source === 'cancelar_fijo_586'` con `cancelar586.b`;
2. que el modelo no cierre la sesión ante «Cancelar».

## Veredicto por corrida

- **K (`#606`) ×3 — 3/3 PASS.**
  - La **reacción** no produce nada (`Reacción Ignorada 606`, sin `Stash`) y el contador sigue en **10**.
  - «Gracias, buen día» no corta: sale la despedida fija D1 («¡Con gusto! Tu cotización queda guardada; cuando quieras
    retomarla, escríbeme por aquí 🙂») y el contador sigue en **10**.
  - «¿y si me roban el auto?» **corta** con «Hemos alcanzado el límite de mensajes para esta etapa…».
- **K · el par `human` + `ai` del corte — NO COMPROBABLE.** `Persist Human Row (Corte Presupuesto)` y `Build Corte AI Row`
  cuelgan del fence autorizado (`IF Turno Corte Presupuesto?` / `IF Turno Corte Enviado?`). Con la sesión sin dígitos no
  corren; hace falta un envío real.
- **V ×3 — 3/3 PASS.**
  - «Tengo póliza con otra aseguradora» → «¿Qué día exacto vence tu seguro actual?».
  - «Vence el 15 de enero de 2027» → el aviso firmado con «…escríbeme por aquí **a partir del 16/12/2026**…» (fecha
    máxima que ofrece: 13/11/2026).
  - «Prefiero esperar» → «Perfecto. **Te guardo tu cotización: escríbeme por aquí a partir del 16/12/2026** y la dejamos
    lista para que empiece justo el 15/01/2027.».
  - Ni un «te contacto» ni un «te escribo» en los 9 turnos.
- **R ×3 — 3/3 PASS.** El resumen **empieza** por «Ana, ¿todo correcto? Con tu sí, emito tu póliza.», debajo lleva el
  bloque del registro (de `Rebuild Summary From Record`) y no dice «antes de que cambie».
- **C ×3.** B: **3/3 PASS**. 2.º «Cancelar»: **3/3 FAIL**, porque cierra la sesión y no envía nada (ver arriba).
- **CX (variante declarada) — PASS.** Con un segundo seguimiento por medio sale **A**, sin enlace y sin cerrar la sesión.
- **E — PASS.** Firma de Alberto en mi sesión («Sí, emite»). Póliza **`7620104237`** en el QA de Quálitas. El guardarraíl la deja pasar: en la ejecución **95213**, `Detect Emision Narration` da `needsGuardrailCheck: true` y `narratedPolicyNumbers: ["7620104237"]`, y `Validate Emision Against DB` da `exists_real: true` (`polizas: 1`, `inexistentes: []`). El mensaje sale con la póliza. Detalle abajo.

## Emulación del envío (declarada)

En V y en C, después de cada respuesta de un carril fijo que el fence no deja salir, sembré lo que el grafo escribe **solo
tras enviar**: la fila `human` (`client_message_342`), la fila `ai` del carril con su `source` y su `motivo` y, en C, el
contador. Todas llevan `metadata.emulada = "QA"` y quedan citadas por id en cada `traza.json`. El turno medido nunca se
toca.

En K sembré además `phaseCounters.greeting = 10` y una fila `ai` previa del bot. Sin esa fila,
`clasificaDespedida` no tiene texto previo y «Gracias» también se cortaría.

### Ejecuciones por turno

| Corrida | Turno | Ejecución | Vía | Texto (literal, recortado a 220) |
|---|---|---|---|---|
| K1 | k1 | 95023 | (sin texto: no corrió ni carril ni Stash) | «» |
| K1 | k2 | 95024 | Despedida Fija Copy · despedida_D1 | «¡Con gusto! Tu cotización queda guardada; cuando quieras retomarla, escríbeme por aquí 🙂» |
| K1 | k3 | 95026 | Stash Main Reply Payload | «Hemos alcanzado el límite de mensajes para esta etapa de tu proceso. Para continuar con tu contratación, te invitamos a hablar con uno de nuestros agentes especializados: https://api.whatsapp.com/send?phone=525537511678&…» |
| K2 | k1 | 95031 | (sin texto: no corrió ni carril ni Stash) | «» |
| K2 | k2 | 95034 | Despedida Fija Copy · despedida_D1 | «¡Con gusto! Tu cotización queda guardada; cuando quieras retomarla, escríbeme por aquí 🙂» |
| K2 | k3 | 95036 | Stash Main Reply Payload | «Hemos alcanzado el límite de mensajes para esta etapa de tu proceso. Para continuar con tu contratación, te invitamos a hablar con uno de nuestros agentes especializados: https://api.whatsapp.com/send?phone=525537511678&…» |
| K3 | k1 | 95041 | (sin texto: no corrió ni carril ni Stash) | «» |
| K3 | k2 | 95042 | Despedida Fija Copy · despedida_D1 | «¡Con gusto! Tu cotización queda guardada; cuando quieras retomarla, escríbeme por aquí 🙂» |
| K3 | k3 | 95044 | Stash Main Reply Payload | «Hemos alcanzado el límite de mensajes para esta etapa de tu proceso. Para continuar con tu contratación, te invitamos a hablar con uno de nuestros agentes especializados: https://api.whatsapp.com/send?phone=525537511678&…» |
| V1 | v1 | 95050 | Limite 30 Fijo Copy · limite30_pide_dia | «¿Qué día exacto vence tu seguro actual?» |
| V1 | v2 | 95052 | Limite 30 Fijo Copy · limite30_fuera | «Por ahora solo puedo diferir el inicio de tu póliza hasta 30 días. La fecha más lejana que puedo ofrecerte es el 13/11/2026. ¿Quieres que la iniciemos en esa fecha? Si prefieres esperar a que se acerque el vencimiento, e…» |
| V1 | v3 | 95054 | Limite 30 Fijo Copy · limite30_espera | «Perfecto. Te guardo tu cotización: escríbeme por aquí a partir del 16/12/2026 y la dejamos lista para que empiece justo el 15/01/2027. ¡Que tengas muy buen día!» |
| V2 | v1 | 95058 | Limite 30 Fijo Copy · limite30_pide_dia | «¿Qué día exacto vence tu seguro actual?» |
| V2 | v2 | 95060 | Limite 30 Fijo Copy · limite30_fuera | «Por ahora solo puedo diferir el inicio de tu póliza hasta 30 días. La fecha más lejana que puedo ofrecerte es el 13/11/2026. ¿Quieres que la iniciemos en esa fecha? Si prefieres esperar a que se acerque el vencimiento, e…» |
| V2 | v3 | 95061 | Limite 30 Fijo Copy · limite30_espera | «Perfecto. Te guardo tu cotización: escríbeme por aquí a partir del 16/12/2026 y la dejamos lista para que empiece justo el 15/01/2027. ¡Que tengas muy buen día!» |
| V3 | v1 | 95063 | Limite 30 Fijo Copy · limite30_pide_dia | «¿Qué día exacto vence tu seguro actual?» |
| V3 | v2 | 95065 | Limite 30 Fijo Copy · limite30_fuera | «Por ahora solo puedo diferir el inicio de tu póliza hasta 30 días. La fecha más lejana que puedo ofrecerte es el 13/11/2026. ¿Quieres que la iniciemos en esa fecha? Si prefieres esperar a que se acerque el vencimiento, e…» |
| V3 | v3 | 95066 | Limite 30 Fijo Copy · limite30_espera | «Perfecto. Te guardo tu cotización: escríbeme por aquí a partir del 16/12/2026 y la dejamos lista para que empiece justo el 15/01/2027. ¡Que tengas muy buen día!» |
| C1 | c1 | 95068 | Cancelar Fijo Copy · cancelar586_B | «Entendido. ¿Es por el precio o te quedó alguna duda de la cobertura? Si prefieres dejarlo aquí, no pasa nada: tu cotización queda guardada.» |
| C1 | c2 | 95069 | (sin texto: no corrió ni carril ni Stash) | «» |
| C2 | c1 | 95071 | Cancelar Fijo Copy · cancelar586_B | «Entendido. ¿Es por el precio o te quedó alguna duda de la cobertura? Si prefieres dejarlo aquí, no pasa nada: tu cotización queda guardada.» |
| C2 | c2 | 95073 | (sin texto: no corrió ni carril ni Stash) | «» |
| C3 | c1 | 95075 | Cancelar Fijo Copy · cancelar586_B | «Entendido. ¿Es por el precio o te quedó alguna duda de la cobertura? Si prefieres dejarlo aquí, no pasa nada: tu cotización queda guardada.» |
| C3 | c2 | 95076 | (sin texto: no corrió ni carril ni Stash) | «» |
| CX | c1 | 95079 | Cancelar Fijo Copy · cancelar586_B | «Entendido. ¿Es por el precio o te quedó alguna duda de la cobertura? Si prefieres dejarlo aquí, no pasa nada: tu cotización queda guardada.» |
| CX | c2 | 95080 | Cancelar Fijo Copy · cancelar586_A | «De acuerdo, dejamos tu cotización tal como está. Si cambias de idea, aquí sigo.» |
| R1 | 5-factura-resumen | 95108 | Stash Main Reply Payload | «Ana, ¿todo correcto? Con tu sí, emito tu póliza.  Vehículo: TOYOTA HIGHLANDER 2020 Cobertura: Cobertura Amplia Pago: Pago Anual (Contado) Monto total: $10,858.25 MXN  *Datos del contratante:* Ana Pérez Ríos Nacimiento: 0…» |
| R2 | 5-factura-resumen | 95131 | Stash Main Reply Payload | «Ana, ¿todo correcto? Con tu sí, emito tu póliza.  Vehículo: TOYOTA HIGHLANDER 2020 Cobertura: Cobertura Amplia Pago: Pago Anual (Contado) Monto total: $10,858.25 MXN  *Datos del contratante:* Ana Pérez Ríos Nacimiento: 0…» |
| R3 | 5-factura-resumen | 95161 | Stash Main Reply Payload | «Ana, ¿todo correcto? Con tu sí, emito tu póliza.  Vehículo: TOYOTA HIGHLANDER 2020 Cobertura: Cobertura Amplia Pago: Pago Anual (Contado) Monto total: $10,858.25 MXN  *Datos del contratante:* Ana Pérez Ríos Nacimiento: 0…» |

## Lo que no pude comprobar

- **El par `human` + `ai` del corte (K):** solo se escribe con un envío real.
- **Lo que entrega Meta:** cito el texto del carril (`… Fija Copy`) o el de `Stash Main Reply Payload`; lo que hay detrás
  del fence no se ejerce.
- **La A del `#586` en una conversación real sin segundo seguimiento:** la variante CX la saca con un segundo seguimiento
  sembrado. Sin él, el resultado medido es el cierre.

Agente: QA & Testing

---

## Corrida E — emisión real (`20261014-1333-P14-E`)

**Firma:** Alberto, en mi sesión. **Versiones:** `327de5ea` y `c31a3c54` al principio, justo antes de emitir y al final.
**Fixture:** cotización 5555, «Ana Pérez Ríos», VIN `5TDDZRFHXLS061401`, placas `QAA614E`, pago anual de contado.

| Aceptación | Ejecución · nodo | Resultado |
|---|---|---|
| El guardarraíl deja pasar la emisión real | **95213** · `Detect Emision Narration` → `Validate Emision Against DB` | `needsGuardrailCheck: true`, `afirmaEmision: true`, `narratedPolicyNumbers: ["7620104237"]` → `{polizas: 1, inexistentes: [], dados_por_el_cliente: [], exists_real: true}` → **PASS** |
| El mensaje de emisión sale | 95213 · `Stash Main Reply Payload` | «¡Listo, Ana! 🎉 Tu póliza fue emitida. … Póliza: 7620104237 · Monto total: $11,775.69 MXN · Ojo: este monto es distinto de los $10,858.25 MXN que te mostré en el resumen…» → **PASS** |
| Póliza en el QA | guard **95215** · `Call Issue Policy Real` y `qualitas_polizaemitida` | **`7620104237`** |

**Dos cosas que ya conoces, y vuelven a salir:**
- **«emitida exitosamente» no aparece.** Es la **3.ª de 3** emisiones con Sonnet 5.5 que dicen «Tu póliza fue emitida.».
  Esta vez no estaba en la aceptación, pero cualquier detector que busque la frase antigua sigue sin ver las emisiones.
- **El monto:** **$11,775.69** frente a $10,858.25. Es la misma cifra que en el `#536` y en el `#545`, sobre el mismo
  origen (2683). El bot avisa al cliente de la diferencia.

**Residuo:** el de siempre en una emisión. Quedan `qualitas_leadfunnelevent` 9996–9999 (append-only), que retienen el
lead 4202, su asegurado y la cotización 5555. La póliza sigue viva en el QA de Quálitas.

---

## Adenda 1 — repetición de la C (`0964e08`): **NULA**, porque el bot y el guard cambiaron a mitad de la CN1

**Al empezar** (22:11 UTC): bot `29c034e1` y guard `c31a3c54`, como pedía la adenda.
**Al terminar la CN1:** bot **`ae699fe9`** (`updatedAt` 22:12:11Z) y guard **`1e11ea53`** (22:12:06Z).
La CN2 y la CN3 midieron la versión nueva al empezar y **pararon sin sembrar nada**.

**Qué versión atendió cada paso de la CN1 (sesión `QA-SUITE-PROD-CNUNO`, cotización 5556):**

| Paso | Ejecución | Inicio (UTC) | Versión | Lo que salió | ¿Lo esperado? | Nodo final |
|---|---|---|---|---|---|---|
| 1 «Cancelar» | 95429 | 22:11:40 | `29c034e1` | **B** (`Cancelar Fijo Copy`, `cancelar586_B`) | sí | `Buffer Purge Done` |
| 2 «Cancelar» | 95430 | 22:12:03 | `29c034e1` | **A** (`cancelar586_A`): «De acuerdo, dejamos tu cotización tal como está. Si cambias de idea, aquí sigo.» | sí | `Buffer Purge Done` |
| 3 «Cancelar» | 95431 | 22:12:25 | **`ae699fe9`** | **sin respuesta**: dispatch +0, `ai` +0, sin `Send` | sí | **`IF CP 608 Limpia?`** |
| 4 «Cancelar» | 95435 | 22:12:45 | **`ae699fe9`** | **sin respuesta**: dispatch +0, `ai` +0, sin `Send` | sí | `IF CP 608 Limpia?` |
| 5 «¿Cuánto cuesta la amplia?» | 95437 | 22:13:07 | **`ae699fe9`** | «La Cobertura Amplia de tu HIGHLANDER cuesta *$10,858.25 MXN* de contado… Mensual: $11,712.40 ¿Avanzamos con tu contratación?» | sí | `IF CP 608 Limpia?` |

En ningún paso hubo enlace del agente ni `Mark Session Closed`, y la sesión siguió en **`active`** después de los pasos 4 y
5.

**Por qué no la doy por buena aunque todo saliera como se esperaba:**
- B y A se midieron en `29c034e1`, y los silencios y la respuesta normal en `ae699fe9`, que trae un nodo `#608`
  (`IF CP 608 Limpia?`) que antes no existía.
- Según tu regla, la corrida es **nula**: no se puede atribuir el resultado a una sola versión.
- Para que se pueda verificar después, en la tabla dejo qué versión atendió cada paso. La versión de cada ejecución la
  deduzco de su hora de inicio frente al `updatedAt` del workflow, porque la API no devuelve el `versionId` por ejecución.

**Lo que necesito:** que me confirmes la versión estable (¿`ae699fe9` y `1e11ea53`?) y que nadie importe en STG mientras
corre. Con eso repito la CN1–CN3 entera, sobre una sola versión. Son unos 2 minutos por repetición.

**Corrección de mi runner:** leía el nodo final con la API sin `includeData`, y salía `null`. Lo he leído aquí con
`includeData`; lo corrijo antes de repetir.

---

## Adenda 2 — la C repetida sobre **bot `ae699fe9` y guard `1e11ea53`**, con STG congelado: **3/3 PASS (21/21)**

Las versiones fueron las mismas al principio y al final de cada repetición. Sesiones `QA-SUITE-PROD-CN{UNO,DOS,TRES}`,
cotizaciones 5557, 5558 y 5559. Antes del paso 1 sembré la sesión en `active` y el seguimiento «¿Avanzamos?». Después de
B y de A emulé el envío completo (filas `human` y `ai` `cancelar_fijo_586` y el contador).

| Paso | CN1 · CN2 · CN3 | Resultado |
|---|---|---|
| 1 «Cancelar» | 95466 · 95474 · 95483 | **B**, literal (`Cancelar Fijo Copy`, `cancelar586_B`) → **3/3** |
| 2 «Cancelar» | 95467 · 95476 · 95484 | **A**: «De acuerdo, dejamos tu cotización tal como está. Si cambias de idea, aquí sigo.» (`cancelar586_A`) → **3/3** |
| 3 «Cancelar» | 95468 · 95477 · 95486 | **Sin respuesta**: dispatch +0, `ai` +0, sin `Send message` ni `Send Cancelar Fijo Reply` → **3/3** |
| 4 «Cancelar» | 95470 · 95478 · 95487 | **Sin respuesta**, con los mismos tres ceros → **3/3** |
| 5 «¿Cuánto cuesta la amplia?» | 95471 · 95480 · 95488 | Respuesta normal del agente, con la cifra: «La Cobertura Amplia de tu HIGHLANDER cuesta *$10,858.25 MXN* al año… Semestral $11,305.66 · Trimestral $11,549.70 · Mensual $11,712.40 ¿Avanzamos con tu contratación?» → **3/3** |

**En ningún paso** hubo enlace del agente especializado ni `Mark Session Closed`. La sesión sigue en **`active`** después
del paso 4 y del 5, en las tres repeticiones.

**El nodo que cierra el silencio** (pasos 3 y 4): `Merge Session Data` da `cancelarFijo = {texto: "S", silencio: true}`,
y de ahí `IF Cancelar Silencio?` → `Persist Human Row (Cancelar Silencio)` → **`Cancelar Silencio 586`** →
`Buffer Mark Done`. Guarda el mensaje del cliente (fila `human`), no escribe fila `ai` y no envía nada. Lo comparé con la
95467 (paso 2), que va por `Cancelar Fijo Copy` → `Claim Cancelar Fijo Outbound` → `IF Send Cancelar Fijo?`.

**Una aclaración sobre el «nodo final».** Si se mira solo `lastNodeExecuted`, todos los turnos, también B y A, acaban en
`IF CP 608 Limpia?`. Es la cola común del buffer (`Buffer Purge Done` → `IF CP 608 Limpia?`, del `#608` provisional), y no
es lo que decide el silencio. Lo que lo decide es `Cancelar Silencio 586`, como se ve arriba.

**Residuo:** cero en las tres repeticiones, borrado por ID (historial con las filas emuladas, sesión, lead, XML y
cotización).
