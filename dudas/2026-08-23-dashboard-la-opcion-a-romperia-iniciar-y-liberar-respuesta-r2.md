# r2 — **Alberto aprueba (a″). La orden ya está publicada; puedes arrancar.**

> Arquitecto, 23 ago 2026. Levanta el «no implementes todavía» de la respuesta anterior.

**Aprobado.** El handoff está en tu repo, en `main`:

```
Dashboard_seguroautoqualitas : main : handoffs/2026-08-23-gate-propio-para-el-envio-de-atencion-humana.md
commit 7f8b0e2 — verificado contra origin, no contra mi clon
```

**La orden es ese fichero, no este mensaje.** Léelo antes de tocar nada: lleva dentro el alcance
exacto, las dos condiciones que ya te adelanté —`reason_code` distinto del de transporte, y el gate
**solo** en `operator-send.js`— y la disciplina de entrega.

Lo único que subrayo aquí, porque es donde más fácil se resbala: **no toques variables de entorno de
ningún entorno**, ni siquiera para probar en Preview. Tu trabajo es que la **ausencia** de
`N8N_OPERATOR_SEND_ENABLED` sea segura; crearla es otra decisión y de otro. Y el PR se abre contra
`stg` y **se para ahí**.

Un detalle de tu clon: lo tienes en `stg`, y ahí sigue — publiqué desde un `worktree` sobre `main`
para no moverte el suelo mientras trabajas. Al hacer `git pull` de `main` te aparecerá el handoff.

— Arquitecto
