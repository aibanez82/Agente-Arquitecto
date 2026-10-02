# Informe — el arreglo del parpadeo de la bandeja, en `main`

**De:** Agente Dashboard · **Para:** Arquitecto-IA-Quálitas · **3 oct 2026**
**Responde a:** `handoffs/2026-10-03-promocion-bandeja-sin-parpadeo.md` (`321b031`)
**Orden de Alberto, en mi sesión:** *«git pull y lanza handoffs/2026-10-03-promocion-bandeja-sin-parpadeo.md (orden de Alberto)»*.

| | |
|---|---|
| PR | **#20**, rama `promocion/bandeja-sin-parpadeo` = `2c563e0` (`main` + merge de **`b24d9ca`**, no de `stg`) |
| `main` | `321b031` → **`6d72f4a`**, padres `321b031` + `2c563e0` |
| Deploy de PROD | `dpl_FqjAFbqxWx5RSdMoLK9vBBecZRVw` **READY**; `dashboard-seguroautoqualitas.vercel.app` apunta a él (API de alias) |

## La condición de parada, mirada

`main` no estaba en `169e776` sino en **`321b031`**. Lo único posterior es **tu propio handoff** (`handoffs/`, sin código), que
no podía citarse a sí mismo. Como el código era el de `169e776` y `b24d9ca` seguía siendo la cabeza de
`fix/bandeja-sin-parpadeo`, seguí adelante.

## Aceptación

1. Diff del PR: **exactamente los 4 ficheros**, +56/−5.
2. Candidato: **743/743, 0 saltados**; verificador y `build` en verde.
3. **`s1-conformidad` en verde sobre el SHA del PR** (`2c563e0`, run 37066934224). **Ojo:** el workflow solo se dispara con
   push a `feature/`, `fix/`, `chore/`, `ci/`, `stg` y `main`, no a `promocion/`. En el #19 salía porque `eb085fd` ya había
   pasado por `stg`; aquí lo lancé a mano (`workflow_dispatch`). El check-run está en el commit, aunque `gh pr checks` no
   lo lista. Si quieres que las promociones lo disparen solas, hay que añadir `promocion/**` a los disparadores: va con
   su handoff.
4. **El #495 sigue fuera** de `main`.
5. **Sin comprobar en pantalla:** que la lista no se tape tras los refrescos y tras tomar/liberar. Lo tiene que mirar
   Alberto con sesión.

— Agente Dashboard
