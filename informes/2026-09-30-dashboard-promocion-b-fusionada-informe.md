# Informe — promoción B fusionada en `main` por orden de Alberto

**De:** Agente Dashboard · **Para:** Arquitecto-IA-Quálitas · **30 sep 2026**
**Orden:** Alberto, en sesión, literal: *«Fusiona el PR #16»*. La dejo por escrito aquí porque una orden en
sesión no la ve ningún otro agente.

## Lo que se ha hecho

| | |
|---|---|
| PR | **#16** (variante B), fusionado con commit de merge |
| `main` | `db9fdf7` → **`f552f47`**, padres `db9fdf7` + `1425508` |
| Deploy de producción | `dpl_DbMcL5vUarRarteXupN8BsEok3e8` **READY** en 47 s; el dominio `dashboard-seguroautoqualitas.vercel.app` apunta a él |

**Lo que entró es exactamente el candidato probado.** Antes de fusionar comprobé que el PR seguía en `1425508`,
`MERGEABLE`/`CLEAN`, y que `main` seguía en `db9fdf7`, sin commits nuevos desde que construí el candidato. Ese
candidato (`db9fdf7` + `1425508`) pasó **678/678 y el `build`**.

## Comprobado en PROD sin sesión

| Petición | Respuesta | Qué acredita |
|---|---|---|
| `GET /` | 307 al login | la aplicación está viva |
| `POST /api/sistema/liberar-inactivas` | **307 al login** | **el `#495` no está en PROD**: no existe la exención del middleware ni el endpoint (en STG, donde sí está, da 401) |
| `GET /api/alertas/salud-bot` | 307 al login | exige sesión: **la línea del `#505` no la puedo ver yo** |

## ⚠️ GitHub marca el PR #14 como fusionado, y no lo está

La cabecera del #14 (`stg` = `8a15a55`) quedó dentro de `main` a través de la rama B, que había fusionado `stg`
para llevar el `#505`. GitHub lo marca como *merged*. **Pero el código del `#495` no está en `main`**: mandan los
reverts de B. Lo he dejado aclarado en un comentario del propio PR #14, que es donde alguien lo leería.

**Y lo que ya habíamos declarado queda en vigor:** fusionar `stg` en `main` no traerá el `#495`; reactivarlo exige
revertir los reverts. `stg` sigue ejecutando el `#495` y `main` no.

## Lo que queda por comprobar con sesión (Alberto)

En PROD, pestaña **Chats**:

1. **La línea del `#505`**: debería decir **«Envíos del bot sin confirmar: 4 colgadas en s1.reply.»**, lo que tu
   SQL devolvió ayer. Con esto, **la condición del `#499` está en PROD**, pendiente solo de esa lectura con los ojos.
2. **Filtro «Tomadas»**: tienen que salir las tomas activas que mediste (9, o las que queden), y entre ellas los
   leads **2208 y 2125** con la pastilla **«Póliza emitida»**. Hasta hoy estaban ocultos.
3. **El visor, leads con foto y texto**: el texto del cliente junto a la foto ya no se borra (`#487`).

— Agente Dashboard

---

## Actualización — Alberto lo ha visto en PROD

Alberto, en sesión, tras mirar PROD: *«la línea dice 4 colgadas en s1.reply»*. Es lo que devolvió tu SQL el 29 sep.
**La alerta del `#505` queda acreditada en PROD con los ojos, y con ella la condición del `#499`.**

Siguen sin mirar con sesión: el filtro «Tomadas» (2208 y 2125 con «Póliza emitida») y el texto junto a la foto.
