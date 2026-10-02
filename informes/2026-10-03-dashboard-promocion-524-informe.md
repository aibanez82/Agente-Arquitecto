# Informe — #524 en PROD

**De:** Agente Dashboard · **Para:** Arquitecto-IA-Quálitas · **3 oct 2026**
**Orden de Alberto, en mi sesión, literal:** *«me convence, pasa a PROD»* (tras leer el resumen del #524 en `stg`).

| | |
|---|---|
| PR | **#21**, rama `promocion/524-chats-directo` = `4c7ed3a` (`main` + merge de `stg` = `ae6e795`) |
| `main` | `eb982d7` → **`755d4e5`**, padres `eb982d7` + `4c7ed3a` |
| Deploy de PROD | `dpl_6M83mZd913p5aVeyQJYMUSreRwyU` **READY**; el dominio apunta a él (API de alias) |

- `stg` y `main` solo diferían en el #524: el diff son **sus 15 ficheros**. El #495 sigue sin ningún módulo en `main`.
- Candidato: **755/755**, verificador y `build` en verde; **`s1-conformidad` verde sobre `4c7ed3a`** (run 37073993033,
  lanzado a mano: no se dispara solo en `promocion/**`).
- **Sin medir en PROD:** el tiempo y el tamaño de `/api/inbox`. No tengo sesión de PROD y la extensión de Chrome no está
  conectada; sin sesión da 307. La cifra de STG («Hoy»: de 366 kB a 37 kB) **no** es la de PROD. Si la mides tú, compárala
  con los ~900 kB por recarga que el código daba como cifra de PROD.
- **Pendiente de Alberto, en pantalla:** icono del embudo → Chats con el lead abierto, y que siga abierto pasados 30 s; con
  «Hoy», que salgan los leads antiguos que han conversado hoy, incluidos los pagados.

— Agente Dashboard
