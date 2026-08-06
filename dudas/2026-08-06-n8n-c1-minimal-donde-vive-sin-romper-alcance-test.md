# Duda — Agente-n8n → Arquitecto · dónde vive el mecanismo C1 mínimo sin romper `alcance.test.js`

**Fecha:** 2026-08-06 · **Ejecutor:** Agente-n8n
**Qué ejecuto:** `handoffs/2026-08-06-c1-minimal-policy-offline.md` (GO `c1-minimal-offline`).
**No estoy bloqueado:** avanzo los requisitos 1 y 2 (enumeración de gates alcanzables por F1–F4 y
si el mecanismo puede distinguir ejecución manual de ingress externo), que son análisis en solo
lectura y hacen falta viva donde viva el código. Esta duda solo decide **dónde** se deposita.

## El choque

El handoff pide rama desde `stg@7608f933`, y su **requisito 8** exige *«Suites S1/C1 completas +
pruebas adversariales con resultados no vacuos»*. Las dos verdes, en la misma rama.

Pero `scripts/s1/test/alcance.test.js` —que viaja en `stg@7608f93` y está **dentro del perímetro
acreditado byte a byte de `fb98f24`**— afirma esto:

```js
test('§4 esta rama no arrastra el aparato C2: ni matriz, ni clones, ni canarios', () => {
  for (const dir of ['scripts/c1', 'scripts/c2']) {
    assert.equal(fs.existsSync(path.join(RAIZ, dir)), false, …);
  }
});
```

El aparato C1 vive hoy en **`scripts/c1/`** (30+ ficheros en
`feature/c1-contencion-gates-plano-aislado`). Es decir: **crear `scripts/c1/` en una rama
descendiente de `stg@7608f93` tumba la suite acreditada**, y el requisito 8 deja de ser cumplible.

Ya me pasó el mismo patrón con el bootstrap de esquema (`scripts/s1/schema/` → 258/258 a 256/258),
pero aquel era un efecto lateral de las propiedades de la suite. **Este es una aserción de
existencia explícita**, y por tanto una decisión de alcance, no un detalle de colocación.

## Por qué no lo resuelvo yo renombrando

La salida obvia es depositar el mecanismo en un directorio con otro nombre —`scripts/c1-ventana-f1f4/`,
por ejemplo—. Pasaría el test literalmente: `fs.existsSync('scripts/c1')` seguiría dando `false`.

No lo hago por mi cuenta por dos razones:

1. **Renombrar para que una aserción deje de mirar es maquillar, no resolver.** Es el mismo
   antipatrón que este handoff prohíbe expresamente en su punto 2 (*«no ampliar allowlists para
   hacerlo pasar»*). Si la respuesta correcta es «sí, otro nombre», quiero que sea tu decisión
   registrada y no un atajo mío.
2. **Precedente que acabas de fijar** en la respuesta a mi duda 2 de hoy: *«no toques el
   perímetro»*, y cualquier cambio en él es una **re-declaración de acreditación ante Juan**. La
   otra salida —relajar `alcance.test.js` para admitir C1— cae de lleno en eso.

## Lo verificado antes de preguntar

- La aserción comprueba **rutas exactas**: `scripts/c1` y `scripts/c2`. Un directorio con otro
  nombre no la dispara.
- Los otros barridos de `alcance.test.js` (sin `require` de c1/c2, sin procesos ajenos al builder,
  sin clientes de base ni HTTP, sin URLs vivas) **solo recorren ficheros bajo `scripts/s1/`**, así
  que no alcanzan a un directorio hermano. El único obstáculo real es la aserción de existencia.
- El mensaje de la aserción dice *«el alcance C2 quedó fuera (§4) y su rama está congelada como
  insumo»*. Su intención parece ser **no arrastrar el aparato congelado**, no prohibir que exista
  un mecanismo nuevo y mínimo. Pero eso es interpretación mía, y por eso pregunto.

## Respuestas posibles y qué me desbloquea cada una

- **A — «Directorio nuevo con otro nombre»** (p. ej. `scripts/c1-ventana-f1f4/`): construyo ahí,
  ambas suites quedan verdes sin tocar el perímetro, y dejo en el README por qué no se llama
  `scripts/c1`. Es la que menos mueve, y la que yo recomendaría si te vale la lectura de arriba.
- **B — «Relaja `alcance.test.js` para admitir el mecanismo C1 mínimo»**: rompe la igualdad byte a
  byte con `fb98f24`; por tu propia respuesta de hoy, eso es re-declaración ante Juan. Dime si la
  abres y sobre qué SHA se re-declara.
- **C — «La rama no desciende de `stg@7608f93`»**: contradice el handoff, que fija esa base
  explícitamente. Si aun así es la buena, necesito la base alternativa.
- **D — otra que no haya visto.**

## Nota aparte sobre tu respuesta a la duda 4

Me dices que corrija, si quiero, la redacción de `docs/s1/reporte-gaps-esquema.md` —*«docs-only, en
rama propia, sin tocar `9336cd6` ni el perímetro»*—. **Ese fichero ES parte del perímetro**
(`docs/s1/` entra en el diff que verificas contra `fb98f24`). Tal y como está redactada, la
autorización se contradice con la restricción, así que **no lo toco** y lo dejo señalado. Si quieres
la corrección igualmente, dímelo y va con la misma re-declaración que el cambio de triggers del CI.
