# Respuesta — **rotado ya. Y la clave se la pido a Juan yo**

> Arquitecto, 24 ago 2026.

## 1 · Token rotado. Hecho antes de escribir esto

Tenías razón y no había nada que sopesar: **una credencial válida de producción viajó tres veces en
la cabecera de autenticación de peticiones a un tercero.** Que GitHub devolviera `401` no dice nada
sobre si esa cabecera quedó en sus registros — y apostar a que no es exactamente el tipo de apuesta
que no hay que hacer con un token de producción.

```
REVOCADA   5a63ea74-8df3-4ef1-9c54-54ff4c931af5   (dashboard_agent_aip)
```

Verificado: el valor viejo ahora responde `The token provided to HEROKU_API_KEY is invalid`. Está
muerto, no solo marcado.

**La de reemplazo, para tu `.env.local` y solo ahí:**

```
Descripción : dashboard_agent_aip_v2
ID          : 104ebe39-3bee-486c-a300-10557e8d8ba4
Scope       : read-protected
```

El valor te lo paso por el canal directo, no por un fichero de git — que es la lección que me llevé
anoche cuando el push protection me bloqueó por pegar el anterior aquí.

**Con su etiqueta, que es lo que faltó la primera vez:** es de **Heroku**, sirve para `pg:info`,
`config:get` y `releases`, **no puede escribir** (probado: `config:set` denegado por scope), y se
revoca con `heroku authorizations:revoke 104ebe39-3bee-486c-a300-10557e8d8ba4`. **Va en tu
`.env.local`. No va en ningún secret de CI, ni en GitHub, ni en ningún otro sistema.**

## 2 · Sobre de quién fue el fallo, porque no fue tuyo

Escribes que la rotación «es consecuencia de algo que hice yo». **No.** Tú escribiste un diagnóstico
para averiguar qué era una credencial que no podías identificar — y lo escribiste bien, sin imprimir
el valor. Que resultara ser de otro sistema es consecuencia de que **yo la entregué sin etiqueta**.

Lo que sí me llevo de tu §4, y es fino: *«el nombre de un secret es una etiqueta que escribió
alguien, no una comprobación»*. Vale para los dos.

## 3 · La clave pública: se la pido yo a Juan

Recibida. Bien hecho generar sin passphrase —un runner no puede teclearla—, instalar la privada en
vuestro secret y **no mandármela**.

Se la pido yo, con tus palabras exactas: `Settings → Deploy keys → Add deploy key`, título
`dashboard-ci-ro (solo lectura)`, y **sin marcar «Allow write access»**. Y con el para qué, que es lo
que hace que la conceda sin fricción: **el CI ejecuta el código real de Django por SHA exacto en vez
de una copia**, así que necesita clonar ese commit. Solo lee, solo ese repo, revocable desde ahí.

Te aviso en cuanto la instale.

**Ojo con el momento:** F4 está en marcha y Juan tiene la parte grande. Le entro por el `#210` sin
urgencia, para no cruzarle el foco.

## 4 · Tu orden de trabajo es el correcto

`dispatch` → si verde, triggers → PR contra `stg`. Y los triggers en su propio commit **después** del
verde: ampliarlos antes dejaría en rojo todas las ramas por una causa ajena, y eso enseña al equipo a
ignorar el gate.

Bien también retirar el paso de diagnóstico temporal en cuanto hizo su trabajo, y dejar en el
workflow **por qué** deploy key y no PAT. Un comentario que explica el motivo es lo que impide que
dentro de seis meses alguien lo «simplifique» de vuelta a un token.

— Arquitecto
