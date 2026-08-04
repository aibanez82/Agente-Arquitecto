# Monitores de sesión (re-lanzables tras reinicio)

> Los monitores del ecosistema son **loops locales de sesión** de Claude Code: viven en el
> terminal donde se lanzaron y **NO sobreviven** a cerrar la ventana ni a reiniciar la Mac.
> Este doc es la fuente única para volver a levantarlos con una sola frase.

## Cómo re-activarlos

**Frase disparadora (dísela a Claude en una sesión nueva):**
**«Retoma donde estábamos: barrido de arranque y arma los monitores».**

Al oírla, Claude:
1. Lee este doc.
2. **Barrido de arranque:** hace `git fetch` y revisa AHORA MISMO si hay algún handoff sin
   responder (según el criterio de detección de cada §), y si lo hay lo ejecuta ya — sin esperar
   al primer latido del loop.
3. **Arma los monitores:** para cada monitor de la tabla cuyo repo coincida con el working
   directory actual (o los que pida la frase), lanza su `/loop` con el prompt EXACTO de la sección
   correspondiente.
4. Confirma qué encontró en el barrido, cuáles monitores quedaron armados y en qué rama dejó cada
   repo.

> Cada monitor se arranca **desde su propio repo**: `cd ~/claude-projects/<repo> && claude`, y
> luego la frase. Un solo terminal solo puede sostener el/los loop(s) de esa sesión.

## Inventario de monitores

| Monitor | Repo (working dir) | Rama a preservar al terminar cada ciclo | Sección |
|---|---|---|---|
| Handoffs del Arquitecto → Dashboard | `~/claude-projects/Dashboard_SeguroAuto` | `c1-gates-api-default-deny` (o la que esté activa al arrancar) | §1 |

---

## §1 · Monitor de handoffs Arquitecto → Dashboard

Prompt EXACTO para `/loop` (pegar tal cual como argumento del skill `loop`):

```
Cada ciclo: en /Users/AIP/claude-projects/Dashboard_SeguroAuto ejecuta `git fetch origin` y revisa si hay un handoff nuevo en `handoffs/` sobre `origin/main` (commits nuevos con mensaje "handoff:" o similar) sin su informe de respuesta correspondiente (detección por fichero sin informe, no por rango de commits -- idempotente a pulls, igual que hace Agente-n8n). OJO: desde la ronda 2 de S1, los informes del Dashboard van a `Agente-Arquitecto:informes/` (su main está bajo auditoría de Juan), NO a Dashboard/main -- para saber si un handoff ya está respondido, busca su informe en el canal que ese handoff indique (handoffs/ del Dashboard O Agente-Arquitecto:informes/). Si encuentras un handoff nuevo del Arquitecto sin responder: ejecútalo directamente sin preguntar al usuario (haz `git checkout main && git pull`, sigue las instrucciones del handoff -- respeta escrupulosamente cualquier límite duro que declare: tocar solo cierta rama, no tocar stg/main, cero accesos vivos a BD -incluso read-only- durante gobernanza S1/Contract-First #132, claim.js intacto, fencing preservado, etc.-, y entrega el informe donde el handoff diga -handoffs/ del Dashboard o Agente-Arquitecto:informes/-). Si tienes dudas sobre el alcance o algo ambiguo, NO se lo preguntes al usuario -- déjaselo por escrito al Arquitecto en `/Users/AIP/claude-projects/Agente-Arquitecto/dudas/` para que él lo lea y responda por el mismo canal. Al terminar cada ejecución, vuelve a dejar el repo en la rama en la que estaba antes de empezar (`c1-gates-api-default-deny`), sin cambios sin commitear. Si no hay handoff nuevo, no hagas nada y espera al siguiente ciclo.
```

Notas:
- Es un `/loop` **autopaceado** (sin intervalo): Claude se auto-programa un latido cada ~25 min.
- Estado vigente al crear este doc (4 ago 2026): entregada la ronda 2 de S1 v1.1, candidato
  `7996c8e`, pendiente de reverificación del Arquitecto. El primer ciclo tras un reinicio hace
  `git fetch` y recoge cualquier handoff llegado mientras la Mac estuvo apagada.

## Cómo añadir un monitor nuevo

Añade una fila a la tabla y una sección `§N` con su prompt exacto de `/loop`. Si quieres que la
frase «activa los monitores» lo arranque automáticamente, este doc ya basta — Claude lo lee entero.
