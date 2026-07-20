# Protocolo — `qualitas-issues` como inbox de captura rápida

> Añadido: 20 julio 2026.

## Función

Además de ser el tracker de bugs técnicos del ecosistema (ver CLAUDE.md, sección
"Bugs — fuente única"), `aibanez82/qualitas-issues` es el **inbox de captura rápida**
de Alberto. Cuando está fuera de casa, dicta o escribe ideas/bugs vía Claude (app
iOS o web) usando el prefijo `QUALITAS:`. Claude estructura cada captura como un
Issue en ese repo.

## Responsabilidad del Arquitecto

1. **Al iniciar cada sesión de trabajo** (o cuando Alberto lo pida explícitamente,
   ej. "revisa QUALITAS"), consultar issues abiertos:
   ```
   gh issue list --repo aibanez82/qualitas-issues --state open
   ```
2. Cada issue trae: tipo (bug/feature/idea), repo afectado dentro del ecosistema
   (Dashboard_seguroautoqualitas, HYL-WAI, Agente_QATest_Qualitas, etc.), contexto,
   prioridad tentativa.
3. **Triangular** — decidir uno de:
   - Reasignar a un ejecutor existente (Nivel 3).
   - Trabajo directo del Arquitecto (diagnóstico/plan).
   - Requiere más contexto de Alberto antes de proceder.
4. Una vez triangulado y asignado (o resuelto), **cerrar el issue en qualitas-issues**
   con comentario indicando destino/resolución. Ejemplos:
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
gh issue list --repo aibanez82/qualitas-issues --label triage[,src:app] --state open
```

Para cada uno, una línea: `[#n] resumen · tipo (idea/feature/bug) · repo destino · prioridad`.
Al final preguntar cuáles trackear y cuáles descartar. Al procesar uno, quitarle `triage` (el
label de canal se queda como registro de origen — no se borra).

## Relación con la función existente de `qualitas-issues`

No reemplaza la función de tracker de bugs técnicos ya documentada en CLAUDE.md —
la complementa. Un issue capturado vía `QUALITAS:` puede terminar siendo, tras
triangulación, un bug técnico que se queda en este mismo repo con su ciclo normal
(abrir → agente ejecutor → Arquitecto certifica → cierra).
