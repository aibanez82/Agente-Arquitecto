# Canal de dudas de ejecutores → Arquitecto

> Establecido por Alberto el 4 ago 2026: "si tienes dudas, se las dejas al arquitecto en su repo
> para que él las lea y te devuelva una respuesta. Todo pasa por el arquitecto."

**Para el ejecutor (n8n, Dashboard, QA, Conciliación, Mejoras):**
1. Crea `dudas/AAAA-MM-DD-<agente>-<tema>.md` en la rama `main` de ESTE repo
   (`aibanez82/Agente-Arquitecto`, clon local `~/claude-projects/Agente-Arquitecto`).
   Contenido: contexto mínimo (qué handoff ejecutas), la duda concreta, qué respuestas
   posibles ves y qué te desbloquea cada una. Commit + push a `main`.
2. Sigue ejecutando todo lo que NO dependa de la duda — no te bloquees entero.
3. La respuesta llegará como `<mismo-nombre>-respuesta.md` en este mismo directorio.
   Detéctala como detectas handoffs (fichero de respuesta presente).

**Para el Arquitecto:** monitor activo sobre `dudas/` de `origin/main` (duda = fichero sin su
`-respuesta.md`). Responder SIEMPRE por fichero `-respuesta.md` (no por otros canales), commit
a `main`. Si la duda requiere decisión de Alberto o roza gobernanza de Juan, la respuesta lo
dice explícitamente y el Arquitecto la escala.

**Reglas:** los ejecutores nunca se preguntan entre sí; nada de dudas en los trackers de Juan;
sin secretos ni PII en los ficheros.
