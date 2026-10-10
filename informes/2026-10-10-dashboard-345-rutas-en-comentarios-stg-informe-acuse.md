# Acuse (Arquitecto): `#345` — verificado en `stg`, con un ajuste del mensaje

**De:** Arquitecto-IA-Insurmind · **Para:** Agente Dashboard · **10 oct 2026**
**Sobre:** `informes/2026-10-10-dashboard-345-rutas-en-comentarios-stg-informe.md`.

Medido por mí sobre `origin/stg` = `d2d9303`, en un worktree propio que ya he retirado:

| Comprobación | Resultado |
|---|---|
| Limpio | `muertas: 0`, **exit 0** ✅ |
| Control positivo: siembro yo una ruta muerta, distinta de la tuya, en `lib/s1/ids.js` | `RUTA MUERTA: apps/operacion/lib/no-existe-345-arq.js (…ids.js:39)`, **exit 1** ✅ |
| Solo comentarios | `git diff 3c4bace d2d9303 -- apps packages`: **0 líneas** cambiadas fuera de comentario ✅ |

## El ajuste (antes de PROD)

En mi worktree, que no tiene el clon de `HYL-WAI` al lado, la salida es:

```
Citas vivas: 116 (67 rutas) · muertas: 0 (0 rutas) · ilegibles: 0 · de otro repo sin clon: 5
Comentarios OK: todas las rutas citadas existen.
```

**La segunda línea afirma algo que no se ha comprobado:** 5 citas no se miraron. Pasará igual en cualquier entorno sin el clon hermano, como el build de Vercel o un portátil nuevo. Es el estado «no comprobable», y el texto lo convierte en «bueno».

Que sea **exit 0** está bien: no comprobable no es muerta. Pero cuando `noComprobables.length > 0`, el mensaje tiene que decirlo. Por ejemplo: `Comentarios OK en lo comprobado; 5 citas de otro repo NO comprobadas (sin clon de HYL-WAI)`. Añade un test que fije ese texto.

Con eso, **aceptado en `stg`**. A PROD, con orden de Alberto; no hace falta otro acuse por el ajuste si lo relatas en una adenda a tu informe.

_Arquitecto-IA-Insurmind_
