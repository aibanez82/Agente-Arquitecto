# Informe — `hitoInteres.js`: la sonda ya distingue ausente de sin-permiso

**Handoff:** `Dashboard_SeguroAuto:handoffs/2026-09-06-hitointeres-la-sonda-pregunta-si-existe-y-quiere-saber-si-puede-leer.md` (`d1600a6`)
**Ejecutor:** Agente Dashboard · 6 sep 2026 · **`stg` = `3ef9f39`**, entrado por merge desde `fix/hitointeres-sonda-de-privilegios`. `main` no se toca.

## Criterios, uno a uno

**1 · Suite en verde, con el recuento dicho antes de medirlo.** Dije **309** (305 + las cuatro
pruebas que pedías) y salieron **310**: escribí una quinta, la de la forma del SQL. Lo digo así
porque el criterio era decir la cifra antes, y la acerté en el método pero no en el número.

**2 · Tres pruebas, una por estado.** `{existe:true, legible:false}` → `sin-permiso` ·
`{existe:false}` → `tabla-ausente` · `{existe:true, legible:true}` → camino normal, 1 lead.

**3 · Prueba de que no lanza.** Con `query` rechazando un `42501`, `leerHitoDeclarado` devuelve
objeto con `motivo:'error'` y no propaga. La garantía que ya había, conservada.

**4 · Ejercitado contra STG de verdad.** Conectado como `u81gb6n2j32hnm` —propietario; en STG no
existe `dashboard_rw`, tal como avisaste—:

```
la sonda            -> {"existe":true,"legible":true}
leerHitoDeclarado   -> disponible: true · motivo LITERAL: "ok" · 11 leads con hito
tabla inventada     -> {"existe":false,"legible":false}   y NO lanza excepción
```

El control con la tabla inventada es el que acredita lo que de verdad estaba en duda: **la forma con
el `oid` no revienta**, que es justo lo que sí hace `has_table_privilege` con el nombre como texto.

**El estado `sin-permiso` NO se puede reproducir en STG**, y no lo he forzado. Queda declarado como
pediste.

**5 · La guarda de privilegios: NO la he pasado.** Necesita el `DATABASE_URL` de PROD y **el
clasificador de permisos de mi sesión me bloquea ese acceso** — es el mismo bloqueo del `#296`, no
un permiso que falte en la base. No hace falta para esta entrega, porque no propongo promoción:
`main` no se toca aquí. Cuando la promoción llegue, o me autorizan el acceso o la guarda la pasa
quien pueda.

## Detalles de ejecución

- La quinta prueba verifica que el `oid` va **sin comillas** en `has_table_privilege`: si alguien lo
  devuelve a texto, la función lanza y perdemos el estado `tabla-ausente`. Es el error concreto
  contra el que nos avisaste, y ahora hay algo que lo impide.
- **El doble de pruebas del módulo devolvía solo `existe`.** Le he añadido `legible`, por defecto
  `true`: sin eso, todos los casos viejos habrían caído en `sin-permiso` por omisión y habría
  cambiado la premisa de pruebas que no tocaba tocar. Se ve poco y era lo más fácil de romper.
- **El `catch` se queda genérico**, como mandaba tu §4. No he atado este módulo a `motivoDelFallo`,
  que solo vive en la rama del `#296`.
- **Cabecera corregida**: decía que en PROD el motivo sería siempre `tabla-ausente`, y allí la tabla
  existe y lo que falta es el permiso.

## Lo que sigue bloqueado, y no por esto

`qualitas_leadfunnelevent` sigue sin `GRANT` en PROD (`#284`). Promover esto a producción antes de
que Juan lo ejecute **no arregla nada**: solo cambiaría el rótulo del hueco de `error` a
`sin-permiso` — que es una mejora de diagnóstico real, pero no de servicio.

— Agente Dashboard
