# Protocolo — inbox de captura rápida `QUALITAS:`

> Añadido: 20 julio 2026. **Destino cambiado el 19 agosto 2026: el inbox es ahora
> `aguayo-co/HYL-WAI`.** `aibanez82/qualitas-issues` quedó congelado — no se abre nada nuevo ahí,
> pero **se sigue barriendo mientras le queden issues abiertos**, y sus números no se han movido.
> Historia del cambio: `docs/architecture/convenciones-origen.md`.

## Función

Además de ser el tracker de bugs técnicos del ecosistema (ver CLAUDE.md, sección
"Bugs — fuente única"), el tracker es el **inbox de captura rápida** de Alberto. Cuando está fuera
de casa, dicta o escribe ideas/bugs vía Claude (app iOS o web) usando el prefijo `QUALITAS:`.
Claude estructura cada captura como un Issue.

⚠️ **El destino de esa captura lo fija el flujo de Alberto en la app de Claude, no este repo.** Si
ese flujo sigue apuntando a `aibanez82/qualitas-issues`, las capturas nuevas seguirán cayendo en el
repo congelado por mucho que aquí diga otra cosa — **hay que cambiarlo en la app**. Hasta
confirmarlo, barrer los dos.

## Responsabilidad del Arquitecto

1. **Al iniciar cada sesión de trabajo** (o cuando Alberto lo pida explícitamente,
   ej. "revisa QUALITAS"), consultar issues abiertos:
   ```
   gh issue list --repo aguayo-co/HYL-WAI --state open
   gh issue list --repo aibanez82/qualitas-issues --state open   # hasta que se vacíe
   ```
2. Cada issue trae: tipo (bug/feature/idea), repo afectado dentro del ecosistema
   (Dashboard_seguroautoqualitas, HYL-WAI, Agente_QATest_Qualitas, etc.), contexto,
   prioridad tentativa.
3. **Triangular** — decidir uno de:
   - Reasignar a un ejecutor existente (Nivel 3).
   - Trabajo directo del Arquitecto (diagnóstico/plan).
   - Requiere más contexto de Alberto antes de proceder.
4. Una vez triangulado y asignado (o resuelto), **cerrar el issue donde esté** —en HYL-WAI si
   nació ahí, en `qualitas-issues` si es de los que quedaron— con comentario indicando
   destino/resolución. Ejemplos:
   - "Reasignado a Dashboard_seguroautoqualitas como issue #47"
   - "Resuelto directamente, ver commit xyz"
5. **Nunca ejecutar el trabajo directamente si el issue pertenece a otro repo** — solo
   coordinar y reasignar. Se respeta la regla de oro: todo pasa por el Arquitecto,
   los ejecutores nunca se hablan entre sí lateralmente.

## Cómo mostrar la bandeja cuando Alberto la pide (añadido 20 jul 2026)

Cuando Alberto pide ver lo capturado — cualquier frase equivalente: "dame las ideas de Alberto",
"los pendientes que te hablé", "qué registré en la app", "revisa la bandeja" — **NO listar el
backlog completo**.

**Filtro base:** label `triage`. **Origen opcional** según cómo lo pida:
- "en la app" / "que te hablé" / "que te conté" → añade label `src:app`
- "por voz" / "nota de voz" → añade label `src:voz`
- "en iOS" / "en el iPhone" → añade label `src:ios`
- Si no especifica canal, mostrar todos los `triage`.

Comando:
```
gh issue list --repo aguayo-co/HYL-WAI --label triage[,src:app] --state open
gh issue list --repo aibanez82/qualitas-issues --label triage[,src:app] --state open   # resto
```
Las labels `triage`, `src:*`, `sistema:*`, `criticidad:*` y `reportado-por:*` se replicaron en
HYL-WAI el 19 ago: el filtro funciona igual en los dos.

Para cada uno, una línea: `[#n] resumen · tipo (idea/feature/bug) · repo destino · prioridad`.
Al final preguntar cuáles trackear y cuáles descartar. Al procesar uno, quitarle `triage` (el
label de canal se queda como registro de origen — no se borra).

## Relación con la función de tracker

No reemplaza la función de tracker de bugs técnicos ya documentada en CLAUDE.md —
la complementa. Un issue capturado vía `QUALITAS:` puede terminar siendo, tras
triangulación, un bug técnico que se queda en el mismo tracker con su ciclo normal
(abrir → agente ejecutor → Arquitecto certifica → cierra).

## Extensión (27 jul 2026) — barrido de issues entrantes de Juan en HYL-WAI

Juan también nos abre trabajo directamente en su repo (`aguayo-co/HYL-WAI`), asignando
el issue a `aibanez82` (caso real que motivó esto: #126, estados de entrega de Meta,
abierto y asignado el 27 jul — nos enteramos porque Juan lo mencionó, no por el tracker).

**En el mismo momento del barrido de inbox** (inicio de sesión o "revisa QUALITAS"),
ejecutar también:

```
gh issue list --repo aguayo-co/HYL-WAI --assignee aibanez82 --state open
gh search issues --repo aguayo-co/HYL-WAI --mentions aibanez82 --state open
```

- El primero trae lo formalmente asignado a Alberto; el segundo, issues donde Juan
  nos menciona sin asignar.
- Para cada issue nuevo (no registrado aún en `docs/iniciativas/` ni en CLAUDE.md):
  leerlo completo, diagnosticar, responder en el issue si procede, y registrar la
  iniciativa en git — mismo tratamiento que una captura del inbox.
- Los issues ya conocidos solo se revisan si tienen comentarios nuevos de Juan
  (`gh issue view <n> --comments` cuando la fecha de actualización sea posterior al
  último registro nuestro).

Esto NO sustituye la regla de "Verificar PROD cuando Juan ejecuta": Juan puede cerrar
o avanzar cosas sin comentar — el barrido detecta lo que abre, no lo que despliega.

---

## ⛔ DEROGADO el 18 ago 2026 (Alberto) · CERRADO del todo el 23 ago

**Nada se abre ya en `aibanez82/qualitas-issues`.** Con ello cae este protocolo de inbox de captura
rápida (`QUALITAS:`) y el ruteo entre dos trackers: ahora hay uno solo.

**Dónde está el destino, con la precisión del 19 ago:** los issues **viven en el repo
`aguayo-co/HYL-WAI`**, y el **Project `orgs/aguayo-co/projects/2`** («HYL-WAI Kanban») es la cola de
prioridad y estado sobre ellos. La primera redacción de esta derogación decía «el tracker único pasa
a ser el project», y no es exacto: el repo es donde nacen, el tablero es donde se ordenan. Todo
issue se **asigna a alguien** — sin responsable no es un issue, es una nota.

**Cerrado del todo el 23 ago 2026:** los 35 issues que quedaban abiertos aquí al derogarlo —incluidos
`#81` (conversación tras `uncertain`), `#82` (detectores de hito) y `#83` (cola de reconciliación)—
se fueron cerrando donde estaban, y ese día se midió el repo en **0 abiertos**
(`gh issue list --repo aibanez82/qualitas-issues --state open` → `[]`). **Sale del barrido de
sesión**, que hasta entonces tenía que mirar los dos. Las referencias `qualitas-issues#NN` de los
documentos **siguen siendo válidas** y no se renumeran: GitHub no transfiere issues entre owners
distintos, así que nada se movió de sitio.

Este documento queda como histórico.
