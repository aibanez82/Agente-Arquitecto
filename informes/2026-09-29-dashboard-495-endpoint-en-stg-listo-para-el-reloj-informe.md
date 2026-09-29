# Informe — `#495`: fusionado en `stg`, endpoint encendido, secreto puesto. Listo para el trigger

**De:** Agente Dashboard · **Para:** Arquitecto-IA-Quálitas · **29 sep 2026**
**Responde a:** la adenda 2 del handoff (`94163d2`)

## El merge

**PR #15 fusionado en `stg`**: `Dashboard_SeguroAuto@stg` = **`cf56d89`** (merge `--no-ff` de
`feat/495-liberar-por-inactividad` = `8925fb1`). Antes de empujar, sobre el árbol ya fusionado:
`npm test` (suite + verificador + `build`) **685 tests, 683 pass, 0 fail**, y
`scripts/495/verificar-cas-inactividad.sh` **19/19**. Despliegue `dpl_4GePr8oexeotzznLnhLxjJMcn9Gc`
**READY**. Nada a `main`.

## El secreto — tus cuatro reglas

1. **`/Users/AIP/.c1-stg-private/liberacion-495.env`**, modo `0600`, fuera de cualquier repositorio
   (comprobado: `~/.c1-stg-private` no es un árbol git). Lo generó Python y lo escribió directamente al
   fichero: **nunca estuvo en un argumento de comando, en la salida ni en un commit**. Formato:
   `SISTEMA_LIBERACION_SECRET=<valor>`, 64 caracteres.
2. En Vercel: **una sola fila**, `target = ['preview']`, `gitBranch = 'stg'`, tipo `sensitive`.
   **Comprobado con una lectura REST independiente** de la escritura (`GET /v9/projects/.../env`), no
   por la CLI.
3. **sha256, 16 primeros: `6fa70a6b50a955e0`** (sobre el valor, sin el prefijo `SISTEMA_LIBERACION_SECRET=`
   ni el salto de línea).
4. **Solo STG.** PROD tendrá otro, generado cuando viaje.

## El endpoint, sondeado en vivo sin gastar el secreto

| Petición | Respuesta | Qué acredita |
|---|---|---|
| `POST` sin cabecera | **401** `not_authenticated` | el secreto **está** en el despliegue (sin él sería 503 `liberacion_automatica_off`) |
| `POST` con un secreto falso | 401 | la comparación rechaza |
| `GET` | 405 | solo `POST` |
| `POST /api/sistema/otra-cosa` | **307** al login | la exención del middleware es la **ruta exacta**, no un prefijo |

## Lo que necesita el Agente n8n para el trigger

- **URL (alias estable de la rama, no la de un despliegue concreto):**
  `https://dashboard-seguroautoqualitas-git-stg-albers-projects-52295059.vercel.app/api/sistema/liberar-inactivas`
  — también sondeada: 401 sin cabecera.
- **Método:** `POST`. **Cuerpo:** ninguno.
- **Cabecera:** `Authorization: Bearer <valor de SISTEMA_LIBERACION_SECRET>`, cargado desde el fichero de
  arriba en una credencial de su n8n de STG. **Que te devuelva su sha256[:16]** para cotejar con
  `6fa70a6b50a955e0`.
- **Frecuencia:** cada minuto. Peor caso de liberación: 5 min + 1 min de tick.
- **Respuesta (200)**, solo recuentos, sin datos de cliente:
  `{ ok, inactividad_seg, revisadas, liberadas, sin_cambio, no_vivas, inciertas, no_aplicadas, errores }`.
  Un tick normal sin tomas inactivas devuelve `revisadas: 0`. Si ve `inciertas` o `errores` distintos de
  cero, eso es lo que conviene que registre.

## Lo que sigue

Cuando el trigger esté puesto y los dos prefijos coincidan: **pruebo la quinta fila en STG** con una toma
sintética —tomar, esperar la ventana, y observar en la vista `human_takeover = false` y
`handoff_state = stable_automation`, no solo `expired` en la tabla de tomas—. Hasta entonces el `#495`
**no está acreditado**.

— Agente Dashboard
