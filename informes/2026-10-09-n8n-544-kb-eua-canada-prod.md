# Informe — `#544` en PROD: KB de cobertura en EUA y Canadá (113 reescrito, 43 retirado, 114 con la excepción)

**De:** Agente n8n · **Para:** Arquitecto · **9 oct 2026, 12:13 UTC**
**Responde a:** `Agente-n8n:handoffs/2026-10-09-orden-prod-544-kb-eua-canada.md` (64fda6d4). Autorización permanente; validado por Alberto en STG (exec 83209).

**Dónde:** BD de PROD, `kb_chunks`. Migraciones `migrations/544/001` y `002` de la rama `fix/544-kb-eua-canada` (`3c99edb3`): **los mismos ficheros que en STG**, aplicados juntos en **una sola transacción**. Ni grafo ni prompt.

## Procedimiento

1. **Respaldo** de las filas 43, 113 y 114 (todas las columnas, embedding incluido): `backups/544/PROD-kb_chunks-43-113-114-pre-20261009T121248Z.json`. Las reversiones versionadas (`001-revert.sql`, `002-revert.sql`) también valen para PROD, porque las filas eran idénticas.
2. **Antes del cambio:** 120 filas; md5 de `kb_chunks_rag.content` **iguales a las guardas**: 43 `4fb44898…`, 113 `dbfaee77…` y 114 `051a271e…`.
3. **Aplicado:** `DO` (guarda) · `UPDATE 1` (113) · `DELETE 1` (43) · `DO` (guarda) · `UPDATE 1` (114).

## Comprobaciones (PROD)

| comprobación | resultado |
|---|---|
| filas | **119** |
| id 43 | **ausente** |
| id 113: md5 del texto y coseno del embedding frente a STG | **iguales · 1,000000** |
| id 114: md5 del texto y coseno del embedding frente a STG | **iguales · 1,000000** |

**Recuperación en PROD** (top 3 por coseno sobre `kb_chunks_rag`):

| pregunta | top 3 | «solo México» sin la excepción |
|---|---|---|
| ¿mi póliza cubre en Estados Unidos? | 113, 114, 15 | ninguno |
| ¿me cubre si choco en Texas? | 114, 113, 65 | ninguno |
| ¿la responsabilidad civil aplica en Canadá? | 113, 41, 114 | ninguno |
| si me voy de viaje a Houston, ¿estoy asegurado? | 114, 113, 4 | ninguno |
| ¿mi seguro sirve en Vancouver? | 113, 114, 52 | ninguno |

**PASS:** el 113 está en el top 3 de las cinco preguntas, el 43 no aparece y no hay ningún «solo México» sin la excepción.

**Pendiente:** la primera pregunta real de PROD sobre el tema, que mides tú para cerrar el `#544`.

Agente: Agente-n8n
