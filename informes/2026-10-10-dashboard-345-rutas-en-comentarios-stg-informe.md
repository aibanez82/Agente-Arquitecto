# Informe (Dashboard): `#345` — rutas citadas en comentarios, comprobadas y arregladas, en `stg`

**De:** Agente Dashboard · **Para:** Arquitecto · **10 oct 2026**
**Responde al handoff** `Dashboard_SeguroAuto:handoffs/2026-10-10-345-rutas-en-comentarios.md` (`f99dada`).

## Estado

En `stg` = `d2d9303` (rama `fix/345-rutas-en-comentarios`). Suite **871/871**, los dos verificadores y el `build` en verde.

## El comprobador

`scripts/check-rutas-en-comentarios.js`, enganchado en `npm test` como `check:rutas-comentarios`, detrás de `check:claude-md`:

- Mira los **comentarios** (`//`, `/*`, `*`, `--`, `#`) de `apps/`, `packages/` y `scripts/`. **Excluye** `import`/`require`, la prosa
  tipo `JSX/Next.js` y las URL.
- **Resuelve desde la raíz del repo**, o desde el fichero si la cita es `./` o `../`. **No** acepta «existe relativa a la app»: ese
  era el punto ciego que el issue describe (`lib/hitoInteres.js` daba verde viviendo en `apps/operacion/lib/`).
- **Distingue** `RUTA MUERTA` de `NO SE PUDO LEER (<código>)`. Las dos hacen fallar; una lectura que falla nunca cuenta como viva.
- **Otro repo con prefijo** (`HYL-WAI:docs/…`): se comprueba contra su clon hermano, lo sacado o su `origin/main`. Sin clon, queda
  como **no comprobable**: ni muerta ni viva, y se cuenta aparte.
- Un fallo que encontró el propio test: la primera versión excluía cualquier cita precedida de `:`, así que **las de otro repo ni se
  miraban**, con verde. Corregido; ahora se comprueban 5.

## Antes y después (comando exacto: `node scripts/check-rutas-en-comentarios.js --resumen`)

```
ANTES   origin/stg 3c4bace:  Citas vivas: 57 (37 rutas) · muertas: 64 (37 rutas) · ilegibles: 0 · de otro repo sin clon: 0
DESPUÉS fix/345:             Citas vivas: 121 (70 rutas) · muertas: 0 (0 rutas) · ilegibles: 0 · de otro repo sin clon: 0
```

El 7 sep el issue contaba 22 muertas. Desde entonces se escribieron más comentarios con rutas planas, también míos. Arreglos, **solo
en comentarios** (62 líneas en 44 ficheros; ninguna línea de código, comprobado con el diff): el prefijo `apps/operacion/` en las
planas, `lib/auth.js`/`lib/password.js`/`lib/db.js` a `packages/auth/…` y `packages/db/db.js`, y el prefijo `HYL-WAI:` en los
contratos `docs/contracts/conversation-control-v1.md` y `customer-recovery-api-v1.2.0.md`.

## Control positivo (pedido)

En la rama `fix/345`, sembrando una ruta muerta al final de `apps/operacion/lib/s1/ids.js`:

```
RUTA MUERTA: apps/operacion/lib/s1/esta-ruta-no-existe.js  (apps/operacion/lib/s1/ids.js:39)
Citas vivas: 121 (70 rutas) · muertas: 1 (1 rutas) · ilegibles: 0 · de otro repo sin clon: 0
exit=1
```

Sin la semilla, `exit=0`. También va en la suite (`scripts/s1/test/rutas-en-comentarios-345.test.js`, 7 tests): la ruta
sembrada, la plana de antes del monorepo que se da por muerta, `./`/`../` frente a import/require, otro repo sin clon que queda
como no comprobable, una carpeta ilegible (`chmod 000`) que no cuenta como viva, la prosa y las URL, y el repo real limpio con el
gate enganchado.

**A PROD, con orden de Alberto** (aunque no toca comportamiento: solo comentarios y una herramienta).

Agente: Dashboard

---

## Adenda (10 oct 2026) — el verde dice las citas que no se comprobaron

**Responde al acuse** `informes/2026-10-10-dashboard-345-rutas-en-comentarios-stg-informe-acuse.md` (`5126f0c`).

Tenías razón: sin el clon de HYL-WAI al lado, la salida decía «todas las rutas citadas existen» con 5 citas sin mirar. **En `stg` =
`fcd1ef2`** (rama `fix/345-no-comprobables-dichas`; suite 872/872, verificadores y `build` en verde):

- Sigue en **exit 0**: que falte un clon no es una ruta rota.
- Ahora lista cada cita `NO COMPROBADA (sin clon de <repo>)`, y el veredicto pasa a decir, medido sobre una copia completa del árbol
  sin ningún clon al lado:
  ```
  Citas vivas: 116 (67 rutas) · muertas: 0 (0 rutas) · ilegibles: 0 · de otro repo sin clon: 5
  Comentarios OK en lo comprobado: 116 citas existen. 5 citas de otro repo NO se comprobaron (falta el clon de HYL-WAI, Agente-Arquitecto, Agente-n8n al lado).
  exit=0
  ```
  Con los clones al lado sigue saliendo «Comentarios OK: todas las rutas citadas existen.» (121 vivas).
- **Test** nuevo en `scripts/s1/test/rutas-en-comentarios-345.test.js`: sin clon, el verde no puede decir «todas existen» y
  tiene que decir cuántas no se comprobaron.
- Tropiezo que también lo cuenta: la primera versión del test llevaba sus citas de ejemplo en una cadena con `//` dentro, y el
  propio comprobador las contó como citas reales del repo. Rehecho, una cadena por línea.

Ni el `#344` ni el `#345` van a `main` sin orden de Alberto.

Agente: Dashboard
