# Informe — `#82`: los dos detectores de hito, arreglados hasta `stg` (Dashboard, 17 ago)

Ejecutado el handoff `handoffs/2026-08-17-fix-82-detectores-hito.md` (`origin/main` de
`Dashboard_seguroautoqualitas` = `984241e`). Autoriza Alberto, alcance solo hasta `stg`. **No he
promocionado a `main` ni he tocado producción.**

## Qué queda hecho

| objeto | valor |
|---|---|
| repo | `aibanez82/Dashboard_seguroautoqualitas` |
| rama de trabajo | `fix/82-detectores-hito`, sacada de `origin/stg` (`101be74`) en **worktree**, no `checkout` |
| commit del fix | `621ca22` |
| merge `--no-ff` | `cd58ed7` |
| **`origin/stg`** | **`cd58ed7`** (antes `101be74`) |
| `origin/main` | `984241e`, **intacto** |

El clon de Alberto queda `behind 2` en `stg` hasta `git fetch && git merge --ff-only origin/stg`.

Cambio aplicado, en `apps/operacion/pages/api/db-leads.js`:

- `confirmo_cobertura`: `LIKE '%ha seleccionado%'` + `'%Cobertura%'` → `ILIKE '%continuamos con%'` +
  `ILIKE '%cobertura%'`.
- `dio_domicilio`: `LIKE '%Su domicilio%'` → `LIKE '%*Domicilio:*%'`.

**Confirmo lo que avisaba el handoff: las dos subconsultas tenían los mismos `LIKE`.** Están
corregidas ambas —`n8n_chat_histories` (líneas 88-98) y `n8n_chat_histories_archive` (110-120)—, así
que la vista no queda inconsistente según de dónde venga la sesión. `dio_vin` y `poliza_emitida_wa`
no se han tocado.

## Gate

Suite completa **225/225 en verde** con el cambio aplicado.

Un aviso sobre esa cifra, porque el número engaña si no se mira: corriendo la suite tal cual salen
**209 tests y 1 fallo**, y ese "1 fallo" es un fichero entero que **no carga** —
`continuation.test.js` exige un clon del repo productor y aborta al no encontrarlo. Aislado contra la
base sin mi cambio, falla igual: es del entorno, no del parche. Con
`HYL_WAI_REPO=/Users/AIP/claude-projects/HYL-WAI` carga y la cuenta real pasa de 209 a **225**. Es
decir, **16 tests no se estaban ejecutando y el resumen los daba por un solo fallo**.

## Lo que NO puedo afirmar: que STG ya sirva el fix

Mergear a `stg` no despliega STG, así que fui a la fuente viva a comprobarlo — y **no he podido**:
la API de Vercel responde `403 forbidden / invalidToken` con la credencial de
`~/Library/Application Support/com.vercel.cli/auth.json`, que ayer mismo funcionaba. **El token está
caducado o revocado.**

Así que lo verificable termina en `origin/stg = cd58ed7`. **Que el deployment de STG haya recogido
el fix está sin comprobar**, y no lo doy por bueno. Para cerrarlo hace falta renovar la sesión del
CLI de Vercel (`vercel login`), que es de Alberto.

## Lo que este parche no arregla — y una propuesta

El parche corrige el síntoma y **deja el mecanismo intacto**: la próxima vez que cambie el copy, los
`LIKE` volverán a quedarse atrás en silencio. Y ahora el copy se edita desde Wagtail (`HYL-WAI#161`),
o sea que puede cambiar **sin pasar por ningún repo** — nadie va a ver un diff.

**Propongo un chequeo que valide que cada frase de hito sigue existiendo en el workflow vivo de n8n**
(API, el mismo `BtOaZm7WlZT-24V7hqCnF`) y falle cuando una deje de aparecer. Detectaría la rotura el
día que ocurre en vez de meses después. Puedo implementarlo; la decisión es de Alberto.

## Un tercer detector que nadie ha verificado

Al tocar el fichero aparece un hito más que **no** está en el handoff ni, que yo sepa, en el issue:

```sql
BOOL_OR((message->>'type') = 'ai'
  AND (message->>'content') LIKE '%tengo%'
  AND (message->>'content') LIKE '%Nombre:%') AS dio_datos_personales
```

No lo he tocado —el handoff decía no tocar otros detectores— pero **su estado es desconocido**, y
tiene la misma forma que el que acabamos de arreglar: busca `'%Nombre:%'` cuando el bloque real del
resumen que sí hemos confirmado es `*Domicilio:*`, con asteriscos. Si el resumen usa `*Nombre:*`, el
`LIKE` casaría igualmente por ser subcadena; lo que no está comprobado es que la frase con `tengo`
siga existiendo. **Verificarlo contra el workflow vivo cuesta una consulta** y evita arreglar dos de
tres hitos y dejar el tercero roto.

— Dashboard, 17 ago
