# Informe — F5.bis cerrada: el Dashboard está en producción

> Agente Dashboard · 23 ago 2026, 22:2x CDMX
> Ejecuta `Dashboard:handoffs/2026-08-24-f5bis-promocion-del-dashboard-a-produccion.md`, con el GO de
> `4161180` y confirmado por Alberto en la conversación antes de tocar `main`.

## La lectura autenticada, primero, porque es lo que cierra la fase

```
POST /api/auth                       -> 200   cookie dashboard_session obtenida
GET  /api/db-leads   (autenticado)   -> 200   ok=true · 1321 leads
                                             resumen: totalLeads, contestan, online,
                                                      polizasEmitidas, pagoPendiente
```

**Las lecturas funcionan contra producción con sesión real.** No es un deploy verde ni un `307` que
parece vida: es el dato del funnel devuelto por la app promovida.

## Estado

| | |
|---|---|
| `main` | `4161180` → **`22baa55`** |
| Deployment | `FyFqUNE9GMcRovtktw5CqbvVxnkQ` · **success** (leído de la API) |
| Punto de retorno | `6qCdbXorFgyacu7Z1z62vCrB4CLL`, anotado **antes** |
| Gates antes de commitear el merge | **229/229** + verificador de rutas OK |
| Llega a producción | 27 ficheros, +3410 líneas |

## Las otras cuatro comprobaciones

| # | Qué | Resultado |
|---|---|---|
| 1 | Login | `200` + cookie |
| 2 | **Aceptación** | `db-leads` `200`, 1321 leads |
| 3 | Envío apagado | `POST /api/operator-send` → **`503 control_send_disabled`** |
| 4 | Atención Humana viva | `POST /api/claim` → `400 session_id_required` |

**Sobre el 3:** es el código que queríamos y no el otro. `control_send_disabled` dice «apagado por
decisión»; `control_module_off` habría dicho «sin transporte». El envío llegó apagado **por
omisión**, sin que nadie tuviera que acordarse de apagar nada. Y el `404` de antes de promover, que
medí en la línea base, convierte esto en prueba: pasó de **no existir** a **existir y estar apagado**.

**Sobre el 4, que es más informativo de lo que parece:** si el transporte faltara, `claim` habría
devuelto `503 control_module_off` — lo acredita el test «módulo OFF por defecto» de la suite verde,
que comprueba exactamente eso. Que devuelva un error de **validación** significa que pasó la guarda
de transporte: **`iniciar` y `liberar` tienen con qué llamar a n8n.** Ambas peticiones usaron cuerpo
vacío a propósito: mueren en la validación, sin tocar BD ni webhook.

## Lo que NO está acreditado, y dejo dicho

**La cadena completa de extremo a extremo no se ha probado**: tomar → claim → `iniciar` →
`human_takeover` → el guard cortando. Eso exige tomar una **conversación real de un cliente** en
producción, y Alberto lo prohibió expresamente cuando se lo planteé: *«no toques conversaciones
reales, solo verifica que responden»*.

Lo que sí está acreditado es cada eslabón por separado: la ruta desplegada y respondiendo, el
transporte configurado, y —por tu medida de F4— el bot de 229 nodos con sus 26 referencias a
`human_takeover` y las 6 del `Phone Number ID Guard`, que verifiqué por mi lado contando en el export.

Si quieres cerrar ese hueco sin tocar a un cliente, hace falta **una sesión de WhatsApp de prueba en
PROD**, que hoy no existe. Es decisión de Alberto y de Juan, no mía.

## Un tropiezo que tu medición no anticipaba

Escribiste «código divergente: NINGUNO», y es cierto **para código**. Pero el merge dio **dos
conflictos** en docs:

- **`CLAUDE.md`** — `main` conservaba la sección de Git **anterior al gitflow** (la del
  `git push origin main` directo) y citaba `docs/convenciones/respaldos-en-rama-propia.md`, una ruta
  **muerta** que habría hecho fallar el gate. Resuelto a favor de `stg`, quirúrgicamente sobre el
  hunk para no descartar lo ya fusionado. El resultado queda en 9660 bytes, idéntico al de `stg`.
- **`docs/convenciones-de-rama.md`** — añadido por los dos lados. Comprobé que la versión de `stg`
  contiene la de `main` **literalmente** (la convención del worktree) más 4.600 bytes: superconjunto
  estricto, no se perdió nada.

No lo cuento como reproche sino porque el mismo patrón se repetirá en la promoción siguiente: **«sin
código divergente» no es «sin conflictos»**, y en un repo donde `handoffs/` va directo a `main` y
`CLAUDE.md` se mantiene en `stg`, los docs divergen por construcción.

## Y una corrección al handoff, encontrada al ejecutarlo

El paso 3 pedía «lectura autenticada **del funnel**». **`/api/funnel-v2` no existe en ninguna rama** —
el funnel se calcula en el front a partir de `db-leads`; esa ruta venía de antes del monorepo. Usé
`/api/db-leads`, que existe en las dos y por eso permite comparar antes y después.

Lo digo porque si hubiera ido a ciegas habría obtenido un `404` tras promover y no habría sabido
distinguir «el endpoint no existe» de «la promoción rompió las lecturas» — que es exactamente la
confusión que esta fase estaba diseñada para evitar.

## Límites respetados

- **Ninguna variable de entorno creada**, en ningún target.
- Nada de n8n, nada de base de datos, nada en STG.
- La landing sigue cerrada.
- Cero escrituras sobre conversaciones reales.

— Agente Dashboard
