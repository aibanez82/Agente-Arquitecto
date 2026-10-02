# Informe — promoción de #502, #513 y #514 fusionada en `main`

**De:** Agente Dashboard · **Para:** Arquitecto-IA-Quálitas · **2 oct 2026**
**Responde a:** `handoffs/2026-10-01-promocion-502-513-514.md` (`0f064b2`)
**Orden de Alberto, en mi sesión, literal:** *«sí, fusiona el PR #19»*.

| | |
|---|---|
| PR | **#19**, rama `promocion/502-513-514` fijada en `eb085fd`, fusionado con commit de merge |
| `main` | `0f064b2` → **`169e776`**, padres `0f064b2` + **`eb085fd`** |
| Deploy de PROD | `dpl_43WfCgFXXLejQjChop3AB6Wwim5N` **READY**; `dashboard-seguroautoqualitas.vercel.app` apunta a él (API de alias) |

**Aceptación:**
1. `main` no se había movido de `0f064b2`. El diff de la fusión tiene **exactamente los 11 ficheros** de tu lista. El diff de
   árbol `main..stg` enseña más, pero es el #495 que `main` dejó fuera a propósito: la fusión no lo trae.
2. Candidato real (`main` + `eb085fd`): **737/737, 0 saltados**, verificador y `build` en verde. **`s1-conformidad` en verde
   en el PR** (run 36844394647), la primera promoción con el #514.
3. **El #495 sigue fuera:** ninguno de sus módulos está en `main`.
4. Deploy READY y dominio apuntando a él.
5. **`/api/db-leads` en PROD: NO lo he podido comprobar con sesión.** No tengo credencial de PROD, y sin sesión da 307 al
   login, que solo prueba que el deploy contesta. El 200 queda para Alberto en su navegador, o para ti, junto con la
   cifra del hito (~158).

## Lo que no viaja

`stg` = `fea442d` lleva además el arreglo del parpadeo de «Cargando bandeja…» (rama `fix/bandeja-sin-parpadeo` =
`b24d9ca`), pedido por Alberto el 2 oct. **No está en `main`**: necesita su propia promoción.

— Agente Dashboard
