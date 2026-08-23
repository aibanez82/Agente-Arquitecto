# Monitores del ecosistema — quién vigila qué, y desde dónde

> **Reescrito el 23 ago 2026.** La versión anterior era del 4 de agosto, describía **un** monitor y
> mandaba dejar el Dashboard en la rama `c1-gates-api-default-deny`, que hace semanas que no es la de
> trabajo. Lo levantó el propio Agente Dashboard, que además pasó la tabla vigente de los suyos y
> **no tocó este fichero porque es mío** — que es exactamente lo correcto.

Hay **dos familias** de monitores y no se parecen en nada, aunque el nombre sea el mismo:

- Los del **Arquitecto** son procesos de la herramienta `Monitor`, uno por canal, con sus scripts
  versionados en `scripts/monitores/`. Spec completa y procedimiento de rearme:
  **`docs/protocolos/monitores-arquitecto.md`** — es ahí donde hay que mirar, no aquí.
- Los de los **ejecutores** viven en sus propios repos y los arma su propia sesión. Este documento
  los inventaría para que, cuando uno emita, se sepa de quién es y a quién reclamarle.

---

## Los cinco del Arquitecto — uno por canal

| | Canal que vigila | Script |
|---|---|---|
| `m2` | lo que **escribe** Juan: comentarios e issues nuevos en HYL-WAI (repo entero) | `scripts/monitores/m2-gobernanza.sh` |
| `m3` | lo que se **empuja**: todas las refs de los 6 repos, con alerta de force-push | `scripts/monitores/m3-refs.sh` |
| `m4` | lo que se **pregunta**: `dudas/` sin `-respuesta` | `scripts/monitores/m4-dudas.sh` |
| `m5` | lo que se **entrega**: `informes/` nuevos | `scripts/monitores/m5-informes.sh` |
| `m6` | lo que Juan **despliega**: releases de `hyl-wai-stg` y `hyl-wai-production` | `scripts/monitores/m6-releases-stg.sh` |

**Un monitor por canal, no por asunto.** El detalle de por qué, y las trampas de cada uno, en la spec.

## Los cuatro del Dashboard

Scripts en `Dashboard_seguroautoqualitas:scripts/`, armados por su sesión.

| Fichero | Qué vigila | Cadencia |
|---|---|---|
| `monitor-handoffs.sh` | `handoffs/` en `Dashboard:origin/main` | 60 s |
| `monitor-arquitecto.sh` | en **este** repo: `dudas/*dashboard*respuesta`, `informes/*dashboard*acuse` y `handoffs/` | 90 s |
| `monitor-stg.sh` | la punta de `origin/stg` en Dashboard, HYL-WAI y Agente-n8n | 120 s |
| `monitor-issue.sh` | comentarios de un issue; `ISSUE` **obligatorio, sin default**. Hoy armado en `#210` | 180 s |

Dos avisos suyos que conviene no perder:

- **`monitor-dudas.sh` es subconjunto de `monitor-arquitecto.sh`** — armar los dos duplica avisos.
- **`monitor-ramas-156.sh` quedó sin objeto** al cerrarse el `#156`.

## Los del Agente n8n

Corre los suyos desde su repo (`monitor-handoffs.sh`, `monitor-dudas.sh`), invocados como
`git show origin/main:scripts/<script>.sh | bash`. **Se llaman igual que los del Dashboard**, así que
por nombre no se distinguen: ver la regla de abajo.

---

## Cómo saber de quién es un monitor — y por qué el nombre no basta

Esto costó dos errores el mismo día, así que va como regla:

**1 · El patrón de búsqueda tiene que cubrir a todos, no solo a los tuyos.** Buscar
`monitores/m[0-9]` dio `ps` limpio con **siete** monitores ajenos corriendo, y de ahí salió un
«no hay monitores vivos» que era falso.

```bash
ps -eo pid,ppid,lstart,command | grep -v grep \
  | grep -E "monitores/m[0-9]|scripts/monitor-|heroku releases"
```

**2 · El nombre del script NO identifica al dueño.** `monitor-handoffs.sh` existe en el Dashboard y
en Agente-n8n. Quien lo distingue es el **directorio de trabajo del proceso**:

```bash
lsof -a -p <pid> -d cwd -Fn | sed -n 's/^n//p'
```

El `ppid` sirve para agrupar por sesión; el `cwd`, para atribuir el repo. Con solo el nombre se
llega a conclusiones equivocadas en los dos sentidos: matar lo ajeno, o dar por ajeno lo propio.

**3 · `TaskList` no ve los monitores tras un `/clear`.** El aviso importante, y lo aportó el Agente
Dashboard: **`/clear` no mata los monitores persistentes** —siguen bajo el mismo proceso— pero **sus
ids de tarea se van con el contexto**. Desde dentro de la sesión son invisibles y `TaskList` responde
«No tasks found». Por eso la comprobación buena es la de `ps`, y por eso los duplicados se acumulan:
la sesión nueva no recuerda haberlos armado y los arma otra vez.

## Cómo añadir un monitor nuevo

Antes de añadirlo, el test que ahorra procesos: **¿es un canal nuevo, o es un asunto que cabe en un
monitor existente?** Casi siempre es lo segundo, y entonces lo que falta es una entrada en una lista,
no un proceso. Si de verdad es un canal nuevo: script versionado en el repo de quien lo arma, fila en
la tabla de arriba, y sección propia en la spec — **un monitor sin sección en su spec es
indistinguible de un residuo**.
