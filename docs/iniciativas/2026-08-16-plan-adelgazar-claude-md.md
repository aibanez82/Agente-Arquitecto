# Plan — adelgazar `CLAUDE.md` con cero riesgo

> Estado: **propuesto**, pendiente de OK de Alberto. Nada ejecutado.
> Medición base: 16 ago 2026, `CLAUDE.md` = **22.979 bytes**, techo declarado **23 KB**.

## 1. El problema no es el tamaño, es el margen

Quedan **21 bytes**. El síntoma apareció hoy: para meter dos convenciones nuevas (640 B) hubo que
compactar cuatro existentes, y **se eligieron por cuál se podía recortar rápido, no por criterio**.
Eso ya es riesgo tomado bajo presión de espacio. Un fichero al 99,9% de su techo convierte cada
aprendizaje futuro en una amputación improvisada.

Objetivo: **~17 KB**, y bajar el techo declarado a **20 KB** para que el margen recuperado no se
rellene solo.

## 2. Qué significa «cero riesgo» aquí

No es «no borrar nada». Es esto, y se puede verificar:

1. **Ninguna regla o hecho que cambie una decisión desaparece del contexto de trabajo.**
2. **Lo que se mueve queda alcanzable en un salto conocido** — puntero explícito en `CLAUDE.md`.
3. **Nada se mueve sin comprobar que el destino ya lo contiene.**

Corolario incómodo pero central: **un fichero más pequeño que induce a inventar no es cero riesgo,
es riesgo diferido.** Si quito la tabla de JOINs, la próxima sesión escribirá `c.lead_id` en vez de
`l.cotizacion_id`, la consulta devolverá filas y la cifra será falsa sin que salte nada.

## 3. Reparto actual, medido

| bytes | % | sección |
|---|---|---|
| 6.576 | 28,6 | **Convenciones** (19 reglas) |
| 2.212 | 9,6 | Staging y gobernanza con Juan |
| 2.074 | 9,0 | Arquitectura completa del sistema |
| 1.803 | 7,8 | Mapa de sistemas |
| 1.523 | 6,6 | Bugs — fuente única |
| 1.393 | 6,1 | Pendientes de infraestructura |
| 1.233 | 5,4 | n8n workflow — estructura interna |
| 1.214 | 5,3 | Identidad y rol |
| 956 | 4,2 | Flujo de trabajo y arquitectura de agentes |
| 939 | 4,1 | Contexto del negocio |
| 936 | 4,1 | **Esquema de BD** |
| 612 | 2,7 | **Regla de estado real de un lead** |
| 442 · 371 · 243 | 4,6 | Protocolos ejecutores · Env vars · cabecera |

## 4. Clasificación por riesgo — el corazón del plan

### 🟢 VERDE — mover ya (~2 KB). Estado que caduca

`Pendientes de infraestructura` (1.393 B, 8 filas) y el estado embebido en `Staging y gobernanza`
(~800 B de los 2.212).

Riesgo cero **porque el destino ya existe y el estado es verificable en vivo**: `qualitas-issues`,
los docs de iniciativa, `pendientes-resueltos-historial.md`. De hecho el propio `CLAUDE.md` ya ordena
que el estado viva fuera — esta sección lleva meses incumpliendo su propia disciplina. Un estado
duplicado no es una red de seguridad: es una segunda versión que se desincroniza y miente.

Queda en `CLAUDE.md`: una línea por ítem **vivo y bloqueante** con su puntero. Los `🟡`/`💡` sin
decisión se van enteros.

### 🟡 ÁMBAR — mover con puntero, separando prosa de regla (~1,5 KB)

`Arquitectura completa` (2.074) + `n8n workflow interna` (1.233) + parte de `Mapa de sistemas`
(1.803). Aquí hay dos cosas mezcladas y solo una puede salir:

- **Sale la prosa descriptiva** → `docs/architecture/overview.md` y `data-flow.md`: el diagrama del
  funnel, la lista de nodos de n8n, las columnas de la tabla de sistemas que son puro dato de
  catálogo.
- **Se queda toda regla anti-error**, y son pocas líneas de alto valor: Django **NO** dispara webhook
  al crear el lead · el **único** webhook real es el de pago · Django y n8n comparten BD · `lib/db.js`
  siempre.

### 🔴 ROJO — no se toca (2.100 B)

`Esquema de BD` + JOINs (936) · `Regla de estado real de un lead` (612) · workaround Bug #7 · los
`% ` de identidad y rol que fijan qué NO hago (no ejecuto).

Son los que evitan **el error caro y silencioso**: los que fallan devolviendo un resultado
plausible. Ahorrar 900 bytes aquí es el peor negocio del fichero.

### ⬛ CONVENCIONES — no se mueve ninguna (6.576 B)

**Una regla que no veo cada turno es una regla que no aplico.** Sacarlas a un doc con índice en
`CLAUDE.md` ahorraría 5 KB y rompería exactamente aquello para lo que existen. Lo único que sale es
la **justificación que ya esté duplicada** en `convenciones-origen.md`, y queda poco: las tres más
largas son manual STG (951), tres canales (802) y gitflow (713) — entre 300 y 500 B recuperables en
total, y solo tras comprobar el duplicado.

## 5. El gate — lo que convierte «cero riesgo» en procedimiento

Sin esto el plan es una intención. Con esto es verificable:

1. **Lista de anclas**, antes de tocar nada: una frase-ancla por hecho o regla que no puede
   desaparecer (JOINs correctos, `c.codigo_postal`, `l.canal_atencion`, workaround Bug #7, «Django
   NO dispara webhook», «no ejecuto», las 19 convenciones…).
2. **`scripts/verifica-claude-md.sh`**: por cada ancla, o está en `CLAUDE.md`, o está en su doc
   destino **y** `CLAUDE.md` tiene el puntero. Cualquier ancla huérfana = fallo, no se mergea.
   Es el mismo método con el que se auditó hoy el adelgazamiento del `CLAUDE.md` del Dashboard
   (10.211 → 8.201 B, diez reglas duras verificadas una a una).
3. **Una PR por categoría, nunca una sola PR gigante.** Verde → Ámbar → Convenciones. Cada una
   revisable y reversible por separado; una PR de 6 KB de diff no se revisa, se aprueba a ojo.
4. **Lo aprueba Alberto.** Es el fichero que gobierna cómo trabajo: no se cambia por iniciativa
   propia ni por mensajería entre sesiones.
5. **Después, riesgo residual observable:** la primera sesión que trabaje con el fichero nuevo anota
   qué echó de menos y dónde tuvo que ir a buscarlo. Si algo se buscó dos veces, vuelve a
   `CLAUDE.md`. Eso convierte el riesgo invisible en una lista corta.

## 6. Resultado esperado

| fase | recorte | acumulado |
|---|---|---|
| Verde — estado que caduca | ~2.000 B | 21,0 KB |
| Ámbar — prosa a `docs/architecture/` | ~1.500 B | 19,5 KB |
| Convenciones — justificación duplicada | ~400 B | 19,1 KB |

Eso deja ~19 KB con techo nuevo de 20 KB: margen para **una docena de convenciones nuevas** sin
volver a canibalizar ninguna. Si hiciera falta más, la siguiente palanca honesta **no** es cortar
más contenido: es partir `CLAUDE.md` por rol (lo que uso en cada turno vs. lo que uso al arrancar) —
decisión distinta, y con su propio riesgo.

## 7. Lo que este plan NO hace

- No toca convenciones como cuerpo de reglas.
- No mueve nada de lo 🔴 rojo.
- No borra: todo lo que sale queda en un doc del repo con puntero desde `CLAUDE.md`.
- No se ejecuta sin OK de Alberto, y no en una sola pasada.
