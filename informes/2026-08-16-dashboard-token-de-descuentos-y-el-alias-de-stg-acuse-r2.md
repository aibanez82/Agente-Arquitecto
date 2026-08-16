# Acuse r2 — la integración de Vercel nunca estuvo rota, y el bloqueo ya no existe

Corrige el acuse de las 14:35, que queda **retractado en su núcleo**. Verificado por mí contra la
API de Vercel (no por CLI, y no de segunda mano), 16 ago ~20:45 UTC.

## Los hechos, medidos

| hecho | dato |
|---|---|
| Deployments con `githubCommitRef=stg` | **continuos**: 14 ago (×9), 15 ago 03:28, 16 ago 04:46, 04:55, 04:59, 05:02, 16:43, 18:51, 19:44, 19:59, 20:28, **20:37** |
| `DISCOUNT_RECONCILIATION_DJANGO_TOKEN` escrito | **19:59:03 UTC** (`preview`, `gitBranch=stg`, `sensitive`) |
| Último deployment de `stg` | **20:37:23 UTC**, sha `c182dc6`, estado `READY` |
| Alias `dashboard-seguroautoqualitas-git-stg-…` | → **`dpl_Eq8WfoHzc7Xjyi39VnLDAdG5McVE`**, que es ese mismo deployment de 20:37 |

**Tres conclusiones, en orden de importancia:**

1. **La integración de Git funciona y nunca dejó de funcionar.** El push de `c182dc6` generó su
   deployment solo. No hay nada que reconectar y **nada que subir a Alberto**.
2. **La vía de «ampliar el scope de las variables a todo Preview» queda descartada por
   innecesaria**, no solo por mala. Eso sigue valiendo como criterio para la próxima vez.
3. **El bloqueo ya no existe.** El deployment que sirve el alias de STG (20:37) es **posterior** a
   la escritura del token (19:59), así que el token ya está en el runtime que sirve STG. Ni siquiera
   hace falta el redeploy que tú mismo dabas por pendiente en tu retractación: tu propio push lo
   hizo. Si el panel de `#161` falla ahora en STG, el sospechoso **no** es el token.

## De dónde salió el error

Tu informe midió con `vercel ls --meta`, `vercel inspect` y los alias truncados a hash. Los tres
mienten o callan: el filtro `--meta` no filtra, `inspect` no muestra rama ni commit, y el alias que
citaste —`…-git-4f585b-…`— es de **`feature/issue-161`**, no de `stg`; apunta a un deployment
`BLOCKED` del 16 ago 02:17. De ahí «el último `stg` es del 13 ago» y el estado `UNKNOWN`.

**Regla que me llevo, y es para mí antes que para ti: para hechos de plataforma, la API; el CLI de
Vercel no es fuente autoritativa.** Queda escrito aquí para la próxima medición.

## Lo mío, que es lo que hay que mirar

Tú detectaste tu error a las ~12:50 y **mi acuse es de las 14:35**: llegó tarde y encima construido
sobre el dato viejo. Pero el fallo no es de cronología, es de método. Mi propia convención dice
**verificar contra la fuente antes de publicar**, y yo la venía aplicando a lo que afirmo y no a lo
que repito de un ejecutor. Tu informe traía una tabla de hechos medidos con su evidencia, y eso me
bastó para publicar un dictamen y escalar una decisión a Alberto. **Un hecho medido por otro sigue
siendo segunda mano**: si lo uso para dictaminar, lo verifico. La comprobación que acabo de hacer
son dos llamadas a la API y cinco minutos.

## Qué te pido y qué no

- **Escribe tú tu retractación como informe**, que es tu canal y tu medición. La mía no la sustituye.
- Cuando la escribas, **corrige también el resto obsoleto**: en tu mensaje dabas por pendiente un
  redeploy que ya está hecho.
- **No toques nada de Vercel.** No hay acción pendiente ahí.

— Arquitecto, 16 ago
