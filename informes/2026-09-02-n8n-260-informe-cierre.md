# Informe `#260` — la sesión en curso va primero. Aceptación **5/5**, con la reproducción del caso real de PROD resuelta

**De:** Agente n8n · **Para:** Arquitecto · 2 sep 2026 · Handoff `b0473bd`, reglas §4 cumplidas.

## 1 · Estado del vivo

Bot STG **`f9931e17`**, 316 nodos. `(status = 'active') DESC` al frente del único `ORDER BY` de
`Resolve Session`, con el comentario-centinela dentro del SQL. **Diff de UN nodo y, dentro, UNA
clave** (`query`) — verificado con parada §4 armada (y tu falsa alarma del segundo «LIMIT 5» era mi
comentario, bien cazada). Respaldo a mano con restauración **probada en dry-run ANTES del import**
(`scripts/260/restaurar-260-stg.py` — vuelta en un comando). Espejo sincronizado.

## 2 · Mediciones previas (verificadas por los dos)

Alcance NOMINAL: el `ORDER BY` ordena los tres modos. Alcance EFECTIVO: solo `phone_open_sessions`
(`payload_v1/v2` usan filas únicamente bajo `matchCount === 1`). `candidates` alimenta solo los dos
nodos de desambiguación: sin `active` el término nuevo es constante-falso (lista idéntica), con
`active` la resolución la toma y la lista ni sale — **tu bloqueante 4 se cumple por construcción**.

## 3 · Aceptación

| # | Caso | Medido | PASS |
|---|---|---|---|
| 1+2 | Cambio por folio a la 2322 con **~20 opens estampadas** por el turno del cambio, pregunta en el turno siguiente | **TODOS los turnos posteriores resolvieron a la recién activada, sin lista** (execs 28428/28434/28436/28438, cot=2322, desambiguación=False) — la reproducción exacta de lo que mató la prueba de Alberto, resuelta | ✅ |
| 3 | Teléfono de UNA sesión (regresión) | **Medida a nivel SQL, no conversacional** (declarado): `ORDER BY` viejo vs nuevo sobre los 5 teléfonos de una sesión de STG — **5/5 filas idénticas** | ✅ |
| 4 | **BLOQUEANTE** — sin resolución posible | Con **cero actives** (flip autorizado, conteo 0 verificado): **la lista SIGUE saliendo** (exec 28432). La desambiguación no se apagó | ✅ |
| 5 | Conversación normal completa | En la 2300 restaurada: «Jacinto, tu cotización para el VOLKSWAGEN VENTO 2020… **$8,583.97 MXN**» + cierre natural (execs 28442/28444), sin lista, sin anomalías | ✅ |

**Intervenciones, todas con tu SÍ y conteos:** flip del caso 4 (2322→open, 0 actives medido) y par de
restauración (2322→open + 2300→active). **Estado final = estado encontrado** (2300 `active`, 2322
`open`). El cierre por flujo real que preferías lo tapó el muro (abajo); la restauración fue SQL con
tu segunda firma.

## 4 · La nota que pediste: los limitadores nos están dejando sin banco de pruebas

Dos limitadores —ninguno defecto, los dos haciendo su trabajo— me taparon mediciones HOY, con cifras:

- **KB Budget Guard** (sesión 2316): `kbTurns` **15/15**, límite duro POR SESIÓN, sin ventana ni reset.
- **Message Budget Guard** (sesión 2322): `phaseCounters.greeting` al tope (**hard: 10**; los caps por
  fase: greeting 10, data_capture 25, summary 8, issuance 5, payment 10) — dispara ANTES del agente,
  así que bloquea hasta el flujo de cambio de cotización.

Las sesiones de prueba del teléfono de Alberto en STG se están agotando por acumulación (contadores
de vida sin reset). **El argumento para pedir sesión limpia queda escrito**: sin una vía de
renovar/crear sesiones de prueba, cada batería futura pagará en flips e intervenciones lo que hoy
pagamos aquí.

## 5 · Qué queda

- **PROD del `#260`: contigo y con la orden de Alberto** — no lo lanzo yo (tu §4). Con él, la prueba
  pendiente del `#299` en PROD sale sola detrás (mismo guion, ahora sí llegará a la puerta).
- La causa de fondo (el turno del cambio estampa `updated_at` a todas las open) queda **sin tocar a
  propósito** y dicha: si algún día se quita el término `active` del orden, el defecto vuelve entero.
- **El E2E de Juan asomó en STG** (clic en la 2325, exec 28430, por el carril del `#282` limpio). No
  toqué ni tocaré nada de su teléfono; mis flips fueron solo 2300/2322.

— Agente n8n
