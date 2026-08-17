# Higiene de `CLAUDE.md` — procedimiento recurrente

> No es una limpieza puntual: es la rutina que evita volver a limpiar bajo presión.
> Techo vigente: **30 KB** (Alberto, 16 ago 2026). Medición al crear este doc: **23.375 bytes**.

## Por qué existe

El fichero crece **legítimamente**: cada agente nuevo, cada convención aprendida, cada regla de BD
descubierta. El techo ya subió tres veces (15 KB el 29 jun → 23 KB el 14 jul → 30 KB el 16 ago) y
seguirá subiendo, porque perseguir un número desactualizado no es disciplina.

Lo que **no** puede repetirse es lo del 16 ago: llegar al 99,9% del techo y, para meter dos
convenciones nuevas, comprimir cuatro existentes **elegidas por cuál se recortaba más rápido**. Eso
no es higiene, es amputación bajo presión de espacio, y decide el reloj en vez del criterio.

## 1. El test de imprescindibilidad

Un bloque **se queda** si responde SÍ a alguna de las cuatro. Si no responde a ninguna, **sale con
puntero** — nunca se borra.

1. **¿Cambia una decisión que puedo tomar en un turno cualquiera?** (regla operativa)
2. **¿Su ausencia produce un error SILENCIOSO?** — el que devuelve un resultado plausible y falso.
   Sin la tabla de JOINs escribo `c.lead_id` en vez de `l.cotizacion_id`: hay filas, hay cifra, y la
   cifra miente. Esta pregunta es la más importante del test.
3. **¿Es una prohibición?** Lo que NO hago pesa más que lo que hago: no ejecuto, no abro issues en
   HYL-WAI sin OK, no toco Meta, no ordeno por el canal en vivo.
4. **¿Es un puntero de UNA línea al doc canónico?** El puntero se queda siempre; el contenido no.

## 2. Qué sale siempre, y a dónde

El destino no se improvisa en cada higiene — está fijado por categoría:

| material | destino |
|---|---|
| Estado de un bug | `qualitas-issues` (o `aguayo-co/HYL-WAI` si el fix es de Juan) |
| Estado de una iniciativa | su doc en `docs/iniciativas/` |
| Ítem resuelto | `docs/architecture/pendientes-resueltos-historial.md` |
| Narrativa / origen de una convención | `docs/architecture/convenciones-origen.md` |
| Descripción de arquitectura, catálogo de sistemas | `docs/architecture/overview.md`, `data-flow.md` |
| Cronología de un incidente | `docs/bugs/bug-NN-*.md` |
| Protocolo de un ejecutor | `docs/protocolos/<agente>.md` |

**Un estado duplicado no es red de seguridad: es una segunda versión que se desincroniza y miente.**

**Y antes de mover a un destino, hay que auditar el destino.** Un doc de destino obsoleto convierte
la higiene en una degradación: el contenido bueno sale de donde se lee cada turno y aterriza junto a
contenido que miente, prestándole credibilidad. Comprobar siempre tres cosas del destino: **qué
describe** (¿el ecosistema o un solo sistema?), **cuándo se tocó por última vez** (`git log -1`), y
si **contradice** algo de lo que sale. Si falla cualquiera, el destino se arregla primero y la fase
espera. Ocurrió en la primera pasada, el 16 ago: `overview.md` y `data-flow.md` databan del 28 jun,
describían solo el Dashboard y enseñaban un JOIN roto sobre `n8n_chat_histories` — la fase ámbar se
paró y ambos quedaron marcados como obsoletos.

## 3. Qué no sale nunca

Las cuatro del test, y en concreto: esquema de BD y JOINs · regla de estado real de un lead ·
workaround del Bug #7 · el cuerpo de las convenciones · las prohibiciones de rol.

Sobre las convenciones, explícito porque es la tentación obvia —son el 28% del fichero—: **una regla
que no veo cada turno es una regla que no aplico.** Sacarlas a un doc con índice ahorraría 5 KB y
rompería exactamente aquello para lo que existen. De ellas solo sale la justificación **ya
duplicada** en `convenciones-origen.md`.

## 4. Cuándo se hace — disparadores, no calendario

- **Al pasar del 80% del techo** (24 KB de 30). Es el aviso, no el límite.
- **Al cerrar una etapa con Juan** (S1, S2…): ahí muere estado de golpe y la higiene es casi gratis.
- **A la tercera convención nueva** desde la última higiene: si entran reglas, hay que hacer sitio
  con criterio antes de necesitarlo.
- **Nunca «cuando reviente».** Si la higiene se dispara por falta de espacio, ya llega tarde.

## 5. La métrica correcta: densidad de regla, no bytes

Los KB no dicen nada por sí solos. **30 KB que son todo regla está bien; 20 KB con 8 de catálogo,
no.** En cada higiene se mide qué porcentaje del fichero pasa el test de §1, y **esa** es la cifra
que se persigue. Un fichero que crece con densidad estable está sano aunque engorde.

Reparto medido el 16 ago 2026 (22.979 B, antes de subir el techo), como línea base:

| bytes | % | sección | veredicto |
|---|---|---|---|
| 6.576 | 28,6 | Convenciones (19 reglas) | 🔒 no sale |
| 2.212 | 9,6 | Staging y gobernanza | 🟡 ~800 B de estado |
| 2.074 | 9,0 | Arquitectura completa | 🟡 prosa sí, regla anti-error no |
| 1.803 | 7,8 | Mapa de sistemas | 🟡 catálogo |
| 1.523 | 6,6 | Bugs — fuente única | 🔒 casi todo regla |
| 1.393 | 6,1 | Pendientes de infraestructura | 🟢 sale entero, con punteros |
| 1.233 | 5,4 | n8n workflow interna | 🟡 prosa |
| 936 + 612 | 6,8 | Esquema BD · estado real del lead | 🔒 **error silencioso** |

## 6. El gate — lo que la hace de cero riesgo

1. **Lista de anclas** antes de tocar nada: una frase-ancla por hecho o regla que no puede
   desaparecer.
2. **`scripts/verifica-claude-md.sh`**: cada ancla, o está en `CLAUDE.md`, o está en su destino **y**
   `CLAUDE.md` tiene el puntero. Ancla huérfana = fallo, no se mergea. Es el método con el que se
   auditó el 16 ago el adelgazamiento del `CLAUDE.md` del Dashboard (10.211 → 8.201 B, diez reglas
   duras verificadas una a una).
3. **Una PR por categoría**, nunca una sola. Un diff de 6 KB no se revisa, se aprueba a ojo.
4. **Lo aprueba Alberto.** Es el fichero que gobierna cómo trabajo: no se toca por iniciativa propia
   ni por mensajería entre sesiones.
5. **Después, riesgo residual observable:** la primera sesión que trabaje con el fichero nuevo anota
   qué echó de menos y dónde tuvo que ir a buscarlo. Lo que se busque dos veces, vuelve.

## 7. Registro de higienes

Una fila por pasada. Sin registro no hay tendencia, y sin tendencia no se ve si algo vuelve a entrar
por la puerta de atrás.

| fecha | antes → después | densidad | qué salió y a dónde |
|---|---|---|---|
| 16 ago 2026 · fase verde | 23.471 → 22.965 | 35 anclas, 0 huérfanas | `Pendientes de infraestructura` reescrita solo con lo vivo: `HYL-WAI#70` llevaba cerrado desde el **2 jul** y `#114` desde el **24 jul**, ambos listados como pendientes. Promoción STG→PROD (cerrada) y plantilla Meta (duplicada) fuera. Dos ítems se quedan por pasar el test: son prohibición y regla de ruteo, no estado. Estado de iniciativas compactado |
| 16 ago 2026 · fase ámbar | — | — | **PARADA antes de empezar**: los destinos (`overview.md`, `data-flow.md`) estaban obsoletos desde el 28 jun y contradecían el esquema. Marcados como obsoletos; la fase espera a que exista un destino sano del ecosistema |
| 16 ago 2026 | 22.983 → 22.979 | — | Compactada la justificación ya duplicada de 4 convenciones para meter 2 reglas nuevas. **Bajo presión de techo — el caso que este protocolo existe para no repetir.** |

## 8. Primera pasada, propuesta

Con el techo en 30 KB ya no hay urgencia, así que se hace bien: 🟢 verde (estado que caduca, ~2 KB)
→ 🟡 ámbar (prosa a `docs/architecture/`, ~1,5 KB) → convenciones (justificación duplicada, ~400 B).
Una PR por fase, en ese orden, cada una con su gate. Objetivo: ~19 KB sobre techo de 30, es decir
**una docena de convenciones de margen** sin volver a tocar ninguna existente.
