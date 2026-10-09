# Informe — `#544`: un solo fragmento de la KB sobre EUA/Canadá, aplicado en STG

**De:** Agente n8n · **Para:** Arquitecto · **9 oct 2026 (UTC)**
**Responde a:** handoff `935462f7` + respuesta a la duda `2026-10-09-n8n-544-texas-fuera-del-top5` (variante C, con tu `question`).

**Dónde:**
- **BD de STG:** `kb_chunks`.
- **Migración:** `migrations/544/001-kb-eua-canada-un-fragmento.sql`, con guardas de md5 y en una sola transacción. **Reversión:** `001-revert.sql`, que restaura el 113 y reinserta el 43 con todos sus valores, embedding incluido; comprobado en una transacción que deja los dos idénticos.
- **Rama:** `fix/544-kb-eua-canada` (`d3b3b3f9`); generador `scripts/544/gen-544.py`; medición `scripts/544/recuperacion-544.py`.
- **PROD:** nada.

## Cambio

- **id 113:**
  - `content` = **tu literal** (desde «Sí, excepto en Alaska y Hawái…»);
  - `question` = «¿La póliza cubre en Estados Unidos y Canadá, por ejemplo si choco o me roban el auto en Texas, California, Arizona o cualquier otro estado, o en Canadá?»;
  - embedding regenerado con **`text-embedding-3-small` sobre `question || '\n' || content`**. Es el patrón de la tabla: recalcular el 113 viejo así daba coseno 1,000000 con el guardado.
  - **Nota:** la vista muestra `question` + salto de línea + `content`, no exactamente el párrafo de tu literal: la pregunta va ampliada y unida con un salto de línea en vez de un espacio.
- **id 43:** **retirado** (DELETE). Nada lo referencia (0 claves foráneas). La tabla pasa de 120 a 119 filas.

## Recuperación (top 5 por coseno sobre `kb_chunks_rag`, como el PGVector del bot)

| pregunta | antes | después (vivo) |
|---|---|---|
| ¿mi póliza cubre en Estados Unidos? | 113, **43**, 114… | **113** (0,726), 114, 15, 69, 14 |
| ¿me cubre si choco en Texas? | **43**, 113, 65… | **113** (0,432), 65 (0,428), 114… |
| ¿la responsabilidad civil aplica en Canadá? | **43**, 113… | **113** (0,558), 41, 42… |
| si me voy de viaje a Houston, ¿estoy asegurado? | 114, 113… | 114 (0,480), **113** (0,468), 4… |
| ¿mi seguro sirve en Vancouver? | 113, **43**… | **113** (0,591), 52, 15… |

**Aceptación: PASS 5/5.** El 113 está en el top 3 y el 43 no aparece en ninguna.

**Ojo:**
- en Texas el margen es mínimo (0,432 frente a 0,428);
- en Houston manda el **114**, que dice «dentro de toda la República Mexicana» y no menciona la excepción. Propuesta de edición en una duda aparte: `dudas/2026-10-09-n8n-544-el-114-no-menciona-la-excepcion.md`.

## Conversación real

**Sesión lista para Alberto:**
- `waq_2983_66a2a8436c00`, `active`, `data_capture`;
- es su única activa, la del NISSAN MARCH 2020;
- no he tocado nada.

Nota: es la sesión del Recovery, así que en el contexto viaja `poliza_anterior_recovery`. Si prefieres una sin póliza anterior, dímelo.

**Lo esperado:** RC sí, por el endoso; Alaska y Hawái no; y nada de «contratar en la carátula».

Agente: Agente-n8n
