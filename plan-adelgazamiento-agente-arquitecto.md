# Plan de adelgazamiento — Agente-Arquitecto

**Fecha:** 10 julio 2026
**Objetivo:** reducir `CLAUDE.md` de ~90 KB (~55-60k tokens) a ~12-15 KB sin perder ni una línea de información.
**Principio rector:** mover, no borrar. Todo el detalle se conserva en git, en archivos que el agente lee solo cuando los necesita.

---

## 1. Diagnóstico

| Hallazgo | Impacto |
|---|---|
| `CLAUDE.md` = 89.901 bytes, 634 líneas | Se carga completo en el contexto en **cada turno** del agente. El modelo procesa ~60k tokens antes de leer tu pregunta → es la causa directa de la lentitud. También diluye la atención (peores respuestas) y acerca cada sesión al límite de contexto. |
| El peso no está en la doc de arquitectura, sino en la **bitácora de bugs** | Las filas #10, #12, #14, #15 y #17 de la tabla de bugs son narrativas de 2-8 KB cada una, con toda la cronología de cada investigación. El bug #15 solo ocupa ~8 KB. Además hay ~15 KB de secciones "Detalle Bug #X" después de la tabla. |
| ~40% del contenido es historia de bugs **ya resueltos** (#6, #8, #10, #12, #15, #16) | Historia valiosa como registro, pero muerta como contexto operativo diario. |
| `docs/` y los JSON de workflows NO se cargan automáticamente | No hay imports `@` en CLAUDE.md. Están bien donde están — no tocar. |
| `.claude/settings.json` | Normal, no afecta velocidad. |
| Nota menor de higiene | `.env.local` y `.DS_Store` viajan dentro del zip. `.env.local` está gitignored en el repo real, pero ojo al compartir zips: contiene secretos (tokens n8n/staging). |

**Regla de oro que se rompió:** CLAUDE.md debe contener lo que el agente necesita saber en *cada* conversación. Todo lo que se necesita solo *a veces* debe vivir en `docs/` y referenciarse por ruta.

---

## 2. Estructura destino

```
Agente-Arquitecto/
├── CLAUDE.md                     ← adelgazado (~12-15 KB)
└── docs/
    ├── bugs/
    │   ├── INDEX.md              ← tabla completa actual (movida tal cual, como registro)
    │   ├── bug-01-historiales-vacios.md
    │   ├── bug-02-prefijo-57.md
    │   ├── ...                   ← un archivo por bug, contenido movido VERBATIM
    │   └── bug-17-webhook-proactivo-stg.md
    ├── protocolos/
    │   ├── agente-mejoras-conversacion.md
    │   ├── agente-n8n.md
    │   └── handoffs.md
    └── (resto de docs/ sin cambios)
```

---

## 3. Disposición sección por sección

### SE QUEDAN en CLAUDE.md (recortadas donde se indica)

| Sección | Acción |
|---|---|
| Identidad y rol | Queda íntegra (~0.5 KB, es el corazón del agente). |
| Contexto del negocio | Queda íntegra. |
| Arquitectura completa del sistema | Queda el diagrama y las reglas, PERO: la corrección del 9 jul (bloque de ~35 líneas sobre el webhook que no existe) se **condensa a 4-5 líneas** con el hecho final ("Django NO dispara webhook al crear lead; envía el 1er WhatsApp directo vía Meta API y hace INSERT a whatsapp_sessions — ahí nace el Bug #2; el único webhook real es el de pago") + puntero a `docs/bugs/bug-02-prefijo-57.md` para la cronología. El hallazgo pendiente de la tabla `numeropruebawhatsapp` se mueve al archivo del bug #2. |
| Wagtail + Django | Queda íntegra (corta y estable). |
| Mapa de sistemas | Queda íntegra. Recortar la celda del Agente Mejoras Conv. a una frase + puntero al protocolo. |
| Esquema de BD + JOINs correctos | Queda íntegra — es de lo más valioso por token que tiene el archivo. |
| n8n workflow — estructura interna | Queda, recortando el detalle del workflow proactivo (el bloque JSON de ejemplo) a `docs/protocolos/` o al doc de arquitectura. Conservar la lista de nodos Postgres y la regla de exportar tras cada cambio. |
| Regla de estado real de un lead (hitos LIKE) | Queda íntegra — el agente la usa constantemente y el riesgo "si cambia el copy, los LIKE mueren" debe estar siempre visible. |
| Workaround Bug #7 en Dashboard | Queda (8 líneas, operativo y activo). |
| Arquitectura de agentes (3 niveles) + regla de oro | Queda íntegra. |
| Flujo de trabajo Claude Code (repos clonados) | Queda íntegra. |
| Variables de entorno clave | Queda íntegra. |
| Convenciones | Queda, PERO la convención de timezone (línea 630, ~2.5 KB con DDL y query de auditoría) se recorta a 3 líneas (regla: timestamptz UTC interno, presentación en America/Mexico_City, nunca naive) + puntero a un nuevo `docs/architecture/timezone.md` con el hallazgo completo, la DDL y la query. |

### SE MUEVEN a docs/ (verbatim, sin resumir al mover)

| Contenido actual | Destino |
|---|---|
| Tabla completa de bugs (filas narrativas) | `docs/bugs/INDEX.md` + un archivo por bug (`docs/bugs/bug-NN-slug.md`). Cada archivo conserva TODO: cronología, evidencia, commits, decisiones. |
| Secciones "Detalle Bug #6/#8/#9/#10/#11" (líneas 257-384, ~15 KB) | Al archivo del bug correspondiente. El bug #10 (el más largo: historia del fix fallido, harness, causa multi-factor, plan de capas, staging) queda entero en `docs/bugs/bug-10-vin-issue-policy.md`. |
| Kommo CRM — integración en curso | `docs/iniciativas/kommo-crm.md` (es una iniciativa, no contexto diario). Dejar 1 línea en Pendientes. |
| Agente Mejoras Conversación — protocolo (~2.5 KB) | `docs/protocolos/agente-mejoras-conversacion.md`. En CLAUDE.md queda la tubería Mejoras→Arquitecto→n8n en 3 líneas (la regla de oro) + puntero. |
| Agente n8n — protocolo + flujo v1 | `docs/protocolos/agente-n8n.md` + puntero. |
| Entorno staging (mapa prod→staging, gotchas de import, convención handoffs) | Ya existe `docs/iniciativas/entorno-pruebas-staging.md` — consolidar ahí. En CLAUDE.md quedan 3 líneas: que existe, la URL de la instancia STG, y el principio rector ("staging nunca apunta a prod"). La convención de handoffs (importante y transversal) puede quedarse en Convenciones: son 2 líneas. |
| Pendientes de infraestructura — las 2 filas gigantes (created_at de n8n_chat_histories ~2.5 KB; estatus de pago Quálitas ~1 KB) | La fila queda en 1 línea + puntero: el detalle del created_at va a `docs/bugs/` o a un doc propio (`docs/architecture/n8n-chat-histories-created-at.md`); ya tiene además el issue #87 como fuente canónica. |

### Nueva tabla de bugs en CLAUDE.md (formato obligatorio)

Una línea por bug, sin excepciones:

```markdown
## Bugs — índice

Detalle completo, evidencia y cronología: docs/bugs/ (un archivo por bug).

| # | Bug | Sistema | Estado | Detalle |
|---|---|---|---|---|
| 1 | Historiales vacíos ~76% (mayoría = leads que nunca respondieron) | n8n | 🟡 Activo | docs/bugs/bug-01-... |
| 2 | Prefijo 57 en session_id (nace en Django, qualitas/models.py) | Django | 🟠 Activo | docs/bugs/bug-02-... |
| ... |
| 10 | VIN↔ciudad en Issue_Policy | n8n | ✅ Resuelto 10 jul | docs/bugs/bug-10-... |
| 14 | Deflect "fuera de alcance" mata conversaciones con qid válido | n8n | 🔴 Crítico | docs/bugs/bug-14-... |
| 15 | Meta entrega mensajes de STG también a PROD | Meta | ✅ Resuelto 10 jul | docs/bugs/bug-15-... |
| 17 | Botón proactivo del Dashboard STG dispara WhatsApp por PROD | Dashboard | 🟠 Falta paso 3 (Vercel env) | docs/bugs/bug-17-... |
```

Para bugs activos se permite 1 línea extra de "próximo paso" — nada más.

---

## 4. Cómo aplicarlo de forma segura (pasos)

1. **Rama nueva:** `git checkout -b adelgazar-claude-md`. Nada se aplica directo en `main`.
2. **Crear `docs/bugs/`** y mover el contenido bug por bug, **copiando verbatim** (cortar-pegar, no reescribir). Orden sugerido: primero los resueltos (#6, #8, #10, #12, #15, #16 — son el 70% del peso), luego los activos.
3. **Crear `docs/protocolos/`** y mover los dos protocolos de agentes + el detalle del workflow proactivo.
4. **Reescribir CLAUDE.md** según la sección 3. Añadir al inicio la regla anti-reengorde (sección 5).
5. **Verificación de no-pérdida (clave del "seguro"):** antes de commitear, comprobar que cada bloque movido existe en su destino. Método simple: para cada bug, `grep` de 2-3 frases distintivas (p. ej. `"Gómez Palacio"`, `"wamid"`, `"1259868760534397"`) en `docs/bugs/` — deben aparecer. Y `wc -c` total: bytes(CLAUDE.md nuevo) + bytes(docs nuevos) ≥ bytes(CLAUDE.md viejo).
6. **Verificar tamaño final:** `wc -c CLAUDE.md` → objetivo ≤ 15.000 bytes.
7. Commit + push, probar el agente 1-2 días en la rama, merge a `main`.
8. **Rollback trivial:** si algo falla, `git checkout main -- CLAUDE.md`. Nada se pierde nunca porque todo está en git.

---

## 5. Regla anti-reengorde (añadir al CLAUDE.md nuevo)

El archivo volverá a engordar si no se cambia el hábito que lo engordó. Añadir al final de Convenciones:

> **Disciplina de CLAUDE.md:** este archivo se carga completo en cada turno — tamaño máximo **15 KB**. Aquí solo viven hechos estables y reglas operativas. Cronologías, evidencia, hallazgos e investigaciones de bugs van SIEMPRE a `docs/bugs/bug-NN-*.md` (crear el archivo si no existe); en la tabla de bugs solo se actualiza la línea de estado. Al cerrar un bug: estado → ✅ con fecha, y todo lo demás al archivo de detalle. Verificar `wc -c CLAUDE.md` tras cada edición.

Esto es lo que el agente leerá cada día, así que él mismo mantendrá la disciplina.

---

## 6. Resultado esperado

| Métrica | Antes | Después |
|---|---|---|
| Tamaño CLAUDE.md | ~90 KB | ~12-15 KB (−85%) |
| Tokens fijos por turno | ~55-60k | ~8-10k |
| Latencia por respuesta | Alta (proporcional al contexto) | Notablemente menor, sobre todo el primer token |
| Información perdida | — | **Cero** (todo movido a git) |
| Coste por sesión | — | ~6x menos tokens de entrada fijos |

Beneficio secundario: mejores respuestas. Con 60k tokens de bitácora, el modelo tiende a mezclar estados viejos de bugs (p. ej. tratar el #10 como activo cuando ya está resuelto). Con el índice de 1 línea + lectura bajo demanda del archivo del bug, trabaja siempre sobre el estado vigente.
