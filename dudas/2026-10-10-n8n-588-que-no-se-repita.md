# Duda n8n · #588 paso 2: que una edición de la KB no vuelva a dejar el vector viejo

**Contexto:** `informes/2026-10-10-n8n-588-kb-vectores-stg.md`. 17 fragmentos de PROD se editaron el 4-6 sep sin regenerar el vector.
Propuesta, **sin código**.

## Opciones
1. **Marca de qué texto se embebió:**
   - una columna `embedding_md5` (el md5 de `question || '\n' || content` en el momento de embeber), que escriben el script de
     regeneración y la carga;
   - una comprobación **solo SQL** (`md5(question || E'\n' || content) <> embedding_md5`) detecta cualquier desfase **sin llamar a la API**.
   - **Coste:** una migración de esquema en `kb_chunks`, que es tabla de Django (pedido a Juan), y rellenar la columna una vez.
   - **Ventaja:** exacta, gratis de ejecutar y sin el ruido del lote.
2. **Disparador en la BD:** al actualizar `question` o `content`, poner `embedding = NULL` (o la marca de desfase). La vista
   `kb_chunks_rag` deja de servir ese fragmento hasta que se regenere.
   - **Coste:** esquema de Django, igual que la 1.
   - **Riesgo:** un fragmento editado desaparece de la búsqueda hasta que alguien lo regenere. Necesita la 1 o la 3 para no quedarse
     así en silencio.
3. **Comprobador periódico con la API:** un workflow programado en n8n que hace esta auditoría (una llamada suelta por fila: 119 al día,
   del orden de céntimos) y avisa por Telegram si algo baja de 0,999.
   - **Coste:** un workflow y credenciales por entorno.
   - **Contras:** la API tiene ruido en lote (medir suelto) y avisa con retraso.
4. **Regla de proceso:** toda escritura en `kb_chunks` pasa por el script que regenera el vector (`gen-*.py`). Coste cero, pero no se
   puede hacer cumplir: es justo lo que falló el 4-6 sep.

## Recomendación
- **La 1 más un aviso diario barato.** La columna `embedding_md5` y una consulta SQL diaria (sin API) en un workflow programado de n8n que
  avise si hay filas desfasadas.
- La 2 solo si se quiere que un texto editado no pueda servirse con el vector viejo ni un minuto, con su aviso para que no desaparezca
  en silencio.
- Mientras no exista la columna, la 3 (la auditoría de `scripts/588/auditoria.py`) programada una vez por semana.

## Preguntas
1. ¿Pido a Juan la columna `embedding_md5` (opción 1) o prefieres empezar por el comprobador con la API (3), que no toca Django?
2. ¿Quién edita hoy `kb_chunks` en PROD (el Dashboard, Django admin, a mano)? El punto de escritura decide dónde se engancha la
   regeneración.

Agente: Agente-n8n
