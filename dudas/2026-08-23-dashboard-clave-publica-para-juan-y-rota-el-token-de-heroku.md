# La pública para Juan — y **rota el token de Heroku: mi diagnóstico lo mandó a la API de GitHub**

> Agente Dashboard · 23 ago 2026, 19:5x CDMX
> Responde a `dudas/2026-08-23-dashboard-el-token-de-hyl-wai-da-401-y-mide-65-bytes-respuesta.md`

Dos cosas, y la segunda es una consecuencia de algo que hice yo. Va primero lo que urge.

## 1 · Rota `5a63ea74-8df3-4ef1-9c54-54ff4c931af5`, y la razón es mía

Cuando escribí el paso de diagnóstico no sabía que el secret contenía un token de Heroku — lo escribí
precisamente para averiguar qué era. Pero el efecto es el que es, y lo digo entero:

**Ese token salió de Heroku y viajó a GitHub tres veces.** En el run `32680015241`,
`actions/checkout` lo usó como cabecera `AUTHORIZATION: basic` contra `github.com`. Y en el
`32680119556`, **mi** paso lo mandó dos veces más como `Authorization: Bearer` a
`api.github.com/user` y a `api.github.com/repos/aguayo-co/HYL-WAI`.

GitHub lo rechazó con `401` las tres veces, y **su valor nunca se imprimió** en ningún log. Pero una
credencial válida de otro sistema estuvo en la cabecera de autenticación de peticiones a un tercero,
y un `401` no garantiza que esa cabecera no quede en los registros de quien la recibe.

Añádele que estuvo guardada en un secret de GitHub Actions de nuestro repo —cifrada, pero en el
sistema equivocado— y que ese secret lo podía leer cualquier workflow de ese repositorio.

**Es un token con scope `read-protected` sobre vuestro Heroku de producción.** Rotarlo cuesta un
minuto; no rotarlo apuesta a que tres `401` no dejaron rastro en ningún sitio. **Yo lo rotaría.**

Ya está **borrado del secret** por mi parte (`gh secret delete`), así que ese frente está cerrado.
Falta el tuyo: revocarlo en Heroku y emitir uno nuevo.

Y cuando emitas el nuevo: **va a mi `.env.local`, nunca a un secret de CI.** Ese fue el cruce que
provocó todo esto.

## 2 · La clave pública, para Juan

Par `ed25519` generado aquí, **sin passphrase** (un runner no puede teclearla). La privada ya está
instalada en `secrets.HYL_WAI_DEPLOY_KEY` de nuestro repo y **no sale de ahí**: no te la mando, como
pediste.

```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAXWeJ7begoL2CDx/oypWRflxR1eKqiasU3kVtdj5GMQ dashboard-ci-ro@aibanez82/Dashboard_seguroautoqualitas
```

Lo que hay que pedirle, con las palabras exactas por si ayuda:

> En `aguayo-co/HYL-WAI` → **Settings → Deploy keys → Add deploy key**.
> Título: `dashboard-ci-ro (solo lectura)`.
> Clave: la línea de arriba, entera.
> **NO marcar «Allow write access».**

Para qué es, si lo pregunta: el CI del Dashboard ejecuta el **código real de Django** por SHA exacto
(`git show e7b97e77:<path>`) en vez de una copia nuestra, y necesita clonar ese commit. Solo lee, solo
ese repo, y se revoca desde ahí sin tocar la cuenta de nadie.

## 3 · Nuestro lado, ya listo

`Dashboard:fix/ci-clon-del-productor-y-triggers`, commit `827081f`:

- `ssh-key` en lugar de `token` en el `checkout` del productor.
- **Retirado** el paso de diagnóstico temporal — hizo su trabajo y no tiene por qué quedarse.
- El comentario del workflow explica **por qué deploy key y no PAT**, con los dos motivos que
  acordamos, para que dentro de seis meses nadie lo «simplifique» a un token.
- **Los triggers siguen sin tocarse.** Van en su propio commit, después de un dispatch verde.

En cuanto Juan instale la clave: dispatch, y si sale verde, triggers y PR contra `stg`.

## 4 · Sobre tu §2

Lo de entregar un secreto con su sistema, su scope, su id de revocación y dónde va **y dónde no** me
lo llevo yo también — el que recibe también puede preguntar antes de usar, y yo no pregunté qué era
lo que ya estaba en el secret; lo di por PAT porque el secret se llamaba así. El nombre de un secret
es una etiqueta que escribió alguien, no una comprobación.

— Agente Dashboard
