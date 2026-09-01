# Iniciativa · Desacople BBDD

> **Objetivo:** que **nadie salvo Django hable con la base de datos de Django**. Ni n8n ni el Dashboard.
> Toda operación de datos, por API.
>
> **Estado:** abierta · **1 sep 2026** · Arquitecto-IA-Quálitas
> **Tracker:** `aguayo-co/HYL-WAI` · nomenclatura `DSC_N8N_NNN` y `DSC_DSH_NNN`

---

## 1 · Por qué, en una frase

Hoy tres sistemas escriben en la misma base de datos. Un cambio de esquema en cualquiera **rompe a los
otros en silencio y en caliente**, sin que ningún test lo vea. Ya ha pasado, y este mismo documento
recoge los casos.

## 2 · El tamaño real, medido

| Frente | Acoplamiento | Medido |
|---|---|---|
| **n8n** | **78 nodos SQL** solo en el bot de PROD (70 `postgres` + 8 `postgresTool`), más los otros workflows | 1 sep 2026, API de n8n |
| **Dashboard** | **27 consultas** en 13 ficheros, 4 tablas propias y 4 vistas | 1 sep 2026, código en `stg` |

### Y el dato incómodo: la deuda crece más rápido de lo que la retiramos

El inventario del `#238`, del **28 ago**, contó **56 nodos SQL** en el bot. Hoy, **1 sep**, son **78**.
**Veintidós más en cuatro días** — porque cada carril nuevo que entregamos (claim/settle, guardas,
terminales) se construye con nodos SQL, que es el patrón que ya tenemos a mano.

**Consecuencia práctica, y es la regla más importante de esta iniciativa:** mientras esté abierta,
**todo carril nuevo se hace contra API si la hay, y si no la hay se pide**. Si seguimos añadiendo SQL
al ritmo de esta semana, la iniciativa no termina nunca.

## 3 · Los tres tipos de daño, con casos reales

**a) Se rompe sin desplegar nada.** `conversation_control_v1` sin `GRANT`: «Tomar conversación» caída
en PROD, sana en STG. Nadie tocó el Dashboard. `HYL-WAI#284`.

**b) Los entornos divergen sin que nadie lo note.** `dashboard_control_commands` **existe en STG y no
en PROD**. Son tablas nuestras creadas a mano, sin migración que las gobierne. Ver `#122`.

**c) La misma verdad se interpreta en tres sitios.** Los hitos de conversación: Django los deriva, n8n
los espeja en un nodo, el Dashboard los busca con `LIKE` sobre el copy del bot. Tres lectores de un
texto que ninguno controla — y ya produjo un indicador que llevaba meses diciendo «no» siempre
(`qualitas-issues#82`).

## 4 · Frente Dashboard — `DSC_DSH_NNN`

**Inventario:** `Dashboard_SeguroAuto:docs/arquitectura/inventario-acceso-directo-postgres-2026-09-01.md`

Dos cosas que ya están bien y no hay que tocar: **el Dashboard no escribe en ninguna tabla de Django**,
y **hay dos precedentes de desacople funcionando** — `discount-reconciliation`, que no tiene ni una
consulta, y las tres vistas `dashboard_*_v1`, que hicieron de contrato cuando Django alteró
`discountsettings`.

| Código | Función de negocio | Qué retira | Prioridad |
|---|---|---|---|
| `DSC_DSH_000` | Mapa y reglas comunes | — | — |
| `DSC_DSH_001` | Bandeja del contact center | `inbox.js` · **única consulta periódica, 30 s** | Alta |
| `DSC_DSH_002` | Tarjetas de captación y embudo | `db-leads.js` · ~42 columnas · 8 tablas | Alta |
| `DSC_DSH_003` | Detalle de conversación | `conversation.js` · **13 consultas** | Alta |
| `DSC_DSH_004` | Control de conversación (tomar/liberar) | `conversation_control_v1` | Alta |
| `DSC_DSH_005` | Resolución de sesión destino del operador | contrato S1-DUAL | Media |
| `DSC_DSH_006` | Conciliación de pagos | `conciliacion.js` — **lee PROD aunque estés en `stg`** | Media |
| `DSC_DSH_007` | Continuación S1 y descuentos | las tres vistas `dashboard_*_v1` | Baja |
| `DSC_DSH_008` | **Hitos de conversación como dato** | los `LIKE` de los tres sistemas | Alta — quita más deuda que ninguno |
| `DSC_DSH_009` | **Mudar a Django las tres tablas de dominio** | `claims`, `control_commands`, `message_audit` | Alta — ordena todo lo demás |

### La decisión de propiedad, que ordena el frente entero

De las cuatro tablas `dashboard_*`, **tres no son nuestras aunque las escribamos nosotros**:

| Tabla | Qué guarda | Dueño correcto |
|---|---|---|
| `dashboard_conversation_claims` | Qué agente tomó qué conversación, con `control_id` y `epoch` | **Django** |
| `dashboard_control_commands` | Las **órdenes al bot**, con hash de idempotencia y resultado | **Django** |
| `dashboard_message_audit` | **Lo que un operador humano escribió al cliente** | **Django** |
| `dashboard_users` | Cuentas y **hashes de contraseña** de nuestros agentes | **Dashboard** |

Las tres primeras **ya participan en el contrato de control de Django desde fuera**, sin migración y
sin contrato. Que un humano tome una conversación es un hecho que el bot tiene que respetar, no estado
de una pantalla. Y el mensaje de un operador es un mensaje que el cliente recibió, como el del bot.

`dashboard_users` es la excepción legítima: autenticación de nuestra aplicación, no dominio de seguros.

## 5 · Frente n8n — `DSC_N8N_NNN`

**Raíz:** `HYL-WAI#238`, con el inventario del 28 ago por workflow, funciones y escrituras inline.

Pendiente de trocear en `DSC_N8N_NNN` por familia de función —claim/settle de salientes, memoria de
conversación, sesiones, descuentos, recordatorios—, no por nodo. **Un issue por nodo sería inmanejable
y no describiría ninguna decisión.**

## 6 · Reglas comunes a los dos frentes

1. **Una API por función de negocio, no por tabla.** Si acabamos con `/api/leads` y `/api/polizas`,
   habremos movido el acoplamiento de SQL a HTTP sin ganar nada.
2. **Cada issue dice qué consulta retira**, con fichero y línea. Una API que se añade dejando viva la
   consulta que venía a sustituir no ha desacoplado nada.
3. **Verificación en PROD, no solo en STG.** Los dos entornos tienen **modelos de privilegios
   distintos** —STG no tiene ACLs y el Dashboard conecta como propietario; PROD usa un rol con
   grants—, así que **una API probada solo en STG no ejercita permisos**. Es literalmente lo que
   produjo el `#284`.
4. **Ningún objeto de base de datos fuera de una migración.** Quien es dueño de la tabla es dueño de
   su migración.
5. **Decir siempre si una respuesta incluye el archivo** (`*_archive`). Mirar solo la tabla viva da
   resultados incompletos, y ya costó una discrepancia.

## 6 bis · Cómo se migra sin romper nada (Alberto, 1 sep 2026)

**Decidido: interruptor por función y ramas cortas. Nada de rama larga de iniciativa.**

El motivo de descartar la rama larga es el `#273` de hoy: un paquete preparado aparte, sobre una base
que se separó del sistema vivo mientras se trabajaba, **arrastraba 30 nodos que nadie había pedido** y
no se vio hasta compararlo contra el grafo real. Una rama de semanas sufriría lo mismo y peor, porque
los dos sistemas se mueven a diario. Y en n8n una rama no aísla nada: **los workflows no viven en git**,
git guarda espejos. Lo que aísla es la instancia de STG.

**El interruptor tiene tres estados por función**, no dos:

| Estado | Qué hace | Para qué |
|---|---|---|
| `sql` | Lee como hoy | Estado inicial y vuelta atrás |
| `dual` | **Lee las dos fuentes, sirve la de SQL y registra las diferencias** | Detectar divergencias con tráfico real **antes** de depender de la API |
| `api` | Sirve la API | Estado final |

`dual` es la pieza que hace segura la migración: se puede tener una función comparando durante días sin
que ningún usuario dependa de la API. Es el mismo patrón que la casa ya usa —el `dual` del
conversation-id y el modo `DARK` del cutover del `#135`—, así que no inventamos nada.

**Reglas del interruptor:**

- **Uno por función**, no uno global. La bandeja puede estar en `api` mientras el resto sigue en `sql`.
- **Por defecto `sql`.** Un despliegue nunca cambia de fuente por sí solo.
- **La vuelta atrás no despliega**: se cambia la variable y ya.
- **Ninguna función pasa a `api` sin haber estado en `dual`** con tráfico real y sin diferencias.

**Ramas:** una corta por issue (`feature/dsc-dsh-001`), a `stg` en cuanto pase, y desaparece.

## 7 · Cómo se mide el avance

No por issues cerrados, sino por **acoplamiento retirado**:

| Métrica | Línea base (1 sep 2026) | Hoy |
|---|---:|---:|
| Nodos SQL en el bot de PROD | 78 | 78 |
| Consultas directas del Dashboard | 27 | 27 |
| Tablas nuestras en la BD de Django | 4 | 4 |

**Se actualiza al cerrar cada issue.** Si una cifra sube, la iniciativa está perdiendo.
