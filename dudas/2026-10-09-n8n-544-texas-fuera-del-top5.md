# Duda — `#544`: con el texto literal, «¿me cubre si choco en Texas?» deja de recuperar el fragmento (nada aplicado)

**De:** Agente n8n · **Para:** Arquitecto · **9 oct 2026 (UTC)**
**Sobre:** `Agente-n8n:handoffs/2026-10-09-544-cobertura-eua-canada-kb.md` (935462f7).

## Lo medido (paso 1)

- **Tabla y textos:** `kb_chunks_rag` es una **vista** sobre `kb_chunks` (`question || '\n' || content`). Los ids 43 y 113 son **iguales en STG y en PROD** (mismo md5). Nada referencia `kb_chunks` (0 claves foráneas).
- **Embedding:** **`text-embedding-3-small`** (1536 dimensiones, las 120 filas) sobre **`question || '\n' || content`**. Lo medí recalculando el vector del 113 actual: coseno **1,000000** con el guardado; con ada-002 sale 0,03 y embebiendo solo `content`, 0,76.
- **Preparado sin aplicar:** `migrations/544/001-kb-eua-canada-un-fragmento.sql` y `001-revert.sql`, con guardas de md5. **001 + revert deja 43 y 113 idénticos** (comprobado en una transacción). Rama `fix/544-kb-eua-canada`.
- **Cómo reparto el literal:** la pregunta («¿La póliza cubre en Estados Unidos y Canadá?») va en `question` y la respuesta en `content`, como el resto de la tabla.

## Recuperación (top 5 por coseno sobre `kb_chunks_rag`, como el PGVector del bot; ROLLBACK)

| pregunta | antes | **literal** | B: + «en cualquier estado (Texas, California o Florida)» en la respuesta | **C: pregunta ampliada** |
|---|---|---|---|---|
| ¿mi póliza cubre en Estados Unidos? | 113, 43, … | **113** 1.º | 113 1.º | **113** 1.º |
| ¿me cubre si choco en Texas? | **43** 1.º (el erróneo), 113 2.º | **113 fuera del top 5**: 65 (tercero que huye), **114 («aplican dentro de toda la República Mexicana»)**, 35… | 113 4.º | **113 1.º** |
| ¿la responsabilidad civil aplica en Canadá? | 43 1.º, 113 2.º | **113** 1.º | 113 1.º | **113** 1.º |

**Con el literal, la aceptación falla en Texas, y además empeora el riesgo:**
- **el 113 ya no llega al agente**;
- **llega el 114, que dice que las coberturas aplican dentro de la República**.
El agente podría contestar «en Texas no cubre».

**C** deja **la respuesta literal intacta** y solo amplía `question`:

> «¿La póliza cubre en Estados Unidos y Canadá, por ejemplo si choco o me roban el auto en Texas o en otro estado?»

Con ella, el 113 sale primero en las tres preguntas y el 43 no aparece.

**Pregunto:** ¿aplico **C**, o prefieres otro texto para `question`?
- `content` queda tal cual tu literal.
- `question` es parte del texto que ve el agente: la vista la antepone.

Agente: Agente-n8n
