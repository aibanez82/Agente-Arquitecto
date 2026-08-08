# C1 · Arreglo de los directorios de estado privado en `operativa.js`

**Preparado, NO autorizado para aplicar.** `stg@10920d7d` es el árbol acreditado y no se toca
mientras la ronda esté viva. Esto entra en la **siguiente ronda de C1**.

Origen: el operador reportó en el import (`#132 c.5226951062`) que `$PRIVATE_STATE/preimages/` nació
con **`0755`** mientras los ficheros de dentro nacían `0600`. Liderazgo lo aceptó como no bloqueante
tras corregirlo en caliente, y quedó pendiente el arreglo de fondo.

## 1. Los dos defectos

Al enumerar **todos** los `mkdirSync` del mecanismo aparecen dos cosas, no una.

### D1 — los ficheros están endurecidos; los directorios que los contienen, no

`escribirSync` y `reemplazarSync` son cuidadosas con el **fichero**: `O_NOFOLLOW`, `0600`,
`fchmod` si venía con otro modo, `fsync`. Pero el directorio se crea con
`fs.mkdirSync(path.dirname(ruta), { recursive: true })`, **sin modo**, así que hereda el umask.

De ahí el `0755` observado: el contenido era privado y el continente no. Con `umask 077` —lo que
exigió el GO del import— el síntoma desaparece, pero el código sigue dependiendo del entorno para
cumplir una garantía que dice cumplir él.

### D2 — se crea primero y se comprueba después (esto no lo cubría el reporte)

En `escribirSync` el orden es `mkdirSync` y **luego** `exigirAncestrosSinSymlink`. En
`reemplazarSync`, `mkdirSync` y luego `escribirPrivado`, que comprueba dentro.

En los dos casos, **si un ancestro es un symlink el directorio ya se ha creado al otro lado del
enlace** cuando salta la comprobación. La cabecera de `rutas-privadas.js` describe exactamente este
antipatrón, en sus propias palabras:

> «crear primero y comprobar luego ya habría creado el directorio AL OTRO LADO del enlace. Denegar
> después de haber escrito no es denegar.»

Es decir: el módulo que documenta la regla la cumple, y el que la consume la incumple.

## 2. Por qué el arreglo obvio es insuficiente

La tentación es poner `{ recursive: true, mode: 0o700 }` en las dos líneas. **No basta**, y el propio
repositorio ya lo tiene escrito en `rutas-privadas.js:10`:

> «`mkdirSync(dir, {mode: 0o700})` NO corrige un directorio que YA existe. Si estaba en 0777, ahí se
> queda.»

Como el state-dir se **reutiliza entre subcomandos** —y el GO del import obligó a reutilizar el del
`PASS`—, el caso «el directorio ya existe con el modo de antes» no es teórico: es el caso normal a
partir del segundo comando. Un `mode:` dejaría el defecto vivo justo donde se manifiesta.

## 3. El arreglo: usar el helper que ya existe

`asegurarDirPrivado()` hace las cuatro cosas que faltan: comprueba ancestros **antes** de crear,
crea en `0700`, vuelve a comprobar **después**, y si el directorio ya existía con otro modo lo
**corrige con `chmod` y re-verifica**. Además valida que sea un directorio regular y del UID
efectivo.

No hay que escribir nada nuevo. De hecho `build-candidate.js` **ya lo usa** para sus cuatro
escrituras privadas: este cambio no introduce un patrón, alinea `operativa.js` con el que el
mecanismo ya adoptó.

```diff
 function escribirSync(ruta, texto) {
-  const { exigirAncestrosSinSymlink } = require('./rutas-privadas');
-  fs.mkdirSync(path.dirname(ruta), { recursive: true });
-  exigirAncestrosSinSymlink(path.dirname(ruta));
+  // El directorio se endurece con el mismo helper que ya usan las escrituras privadas del
+  // builder: comprueba ancestros ANTES de crear --crear y comprobar después ya habría creado al
+  // otro lado del enlace--, crea en 0700 y CORRIGE un directorio preexistente, cosa que
+  // `mkdirSync(..., {mode})` no hace.
+  const { asegurarDirPrivado } = require('./rutas-privadas');
+  asegurarDirPrivado(path.dirname(ruta));
```

```diff
 function reemplazarSync(ruta, texto) {
-  const { escribirPrivado } = require('./rutas-privadas');
-  fs.mkdirSync(path.dirname(ruta), { recursive: true });
+  const { asegurarDirPrivado, escribirPrivado } = require('./rutas-privadas');
+  asegurarDirPrivado(path.dirname(ruta));
   escribirPrivado(ruta, Buffer.from(texto, 'utf8'));
 }
```

La llamada suelta a `exigirAncestrosSinSymlink` en `escribirSync` **se retira**: queda cubierta, y
mejor, por las dos comprobaciones internas del helper.

## 4. Alcance verificado — qué NO hay que tocar

Enumerados todos los `mkdirSync` de `scripts/s1-c1/`:

| Sitio | Veredicto |
|---|---|
| `lib/operativa.js:29` y `:54` | **los dos defectos** — es lo que se corrige |
| `build-candidate.js:264` | ya usa `asegurarDirPrivado` — correcto |
| `build-candidate.js:170` (`escribir`) | salida **versionada** del repo (`build/s1-c1/...`), no privada — se deja |
| `build-candidate.js:380` | manifiesto **redactado y versionado** — público por diseño, se deja |
| `test/*` | fixtures de test — fuera de alcance |

O sea: **dos líneas de producción**, ni una más.

## 5. Pruebas que debe traer el cambio

Fail-first, y con el control positivo que este mecanismo exige:

1. **Directorio preexistente con modo laxo**: crear el subdirectorio a `0777` *antes* de la corrida,
   ejecutar, y afirmar que termina en `0700`. Es el caso que un `mode:` no arregla, y el que se dio
   de verdad. Ya hay precedente del patrón en `test/sello-operativo.test.js:212`.
2. **Ancestro symlinkeado**: afirmar que **no se crea nada al otro lado** del enlace y que se
   deniega con `C1_PRIVATE_PATH_INVALID` (21). Hoy el directorio se crearía antes de la negativa.
3. **Control positivo**: corrida limpia con state-dir nuevo → sigue funcionando y el directorio
   queda `0700`, no solo «no falla».
4. **Independencia del umask**: ejecutar con `umask 022` y comprobar que el directorio sale igual
   `0700`. Es la prueba de que la garantía la da el código y no el entorno — que es el fondo del
   asunto.

## 6. Encaje contractual

No toca contrato, ni interfaz de comandos, ni artefactos, ni el fingerprint. Es una corrección
interna de conformidad con §6.4, que ya exige `0700` para el estado privado. Debería entrar como
cambio acotado en la siguiente ronda, con sus cuatro pruebas y sin ampliar alcance.
