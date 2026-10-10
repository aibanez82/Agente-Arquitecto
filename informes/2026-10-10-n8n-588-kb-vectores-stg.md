# Informe n8n · #588: vectores desfasados de la KB, regenerados en STG

**Handoff:** `Agente-n8n:handoffs/2026-10-10-588-kb-vectores-desfasados.md` (`33935788`).
- **Rama:** `fix/588-kb-vectores`, `bee6631a`.
- **Scripts:** `scripts/588/` (`auditoria.py`, `gen-588.py`, `medir-588.py`).
- **Migración:** `migrations/588/001-stg-*.sql`.
- **PROD no se ha tocado.**

## Paso 0: control de fórmula (PROD, solo lectura)
Para los 17 fragmentos de PROD por debajo de 0,999 con `3-small(question \n content)`, calculé también el coseno con `3-small(content)` y
con `3-small(question)`. **Ninguno da ≈1,0**: van de 0,57 a 0,93 con `content` y de 0,69 a 0,89 con `question`. **Son vectores viejos**,
no otra fórmula. Son los 17 editados entre el 4 y el 6 sep, como comprobaste tú.

**Hallazgo de método:** la API de embeddings da un vector **algo distinto en lote** que con una llamada suelta.
- Medido con el id 61: 0,9938 dentro de un lote de 50 y 1,0000 suelto, en 5 de 5 llamadas.
- Por eso el 61 apareció en mi primera lista de PROD y era **falso**.
- Ahora la auditoría usa el lote solo para cribar: lo que sale por debajo de 0,999 se vuelve a medir suelto, y la regeneración se hace de
  una en una.

## Paso 1: STG
1. **Auditoría de STG:** 17 por debajo de 0,999. Son los 16 de PROD (el 40 ya se regeneró en el #333) más el **38** («¿Qué son las
   coberturas accesorias?», editado en STG el 5 sep 03:12; en PROD está bien).
2. **Migración:**
   - solo `embedding` de esos 17;
   - guarda de md5 de `question || content` por id;
   - reversión con el vector viejo de cada uno.
3. **Comprobado (primero en transacción con ROLLBACK, después aplicado):**
   - texto (`question` y `content`) **intacto** en las 119 filas;
   - solo cambian los 17 vectores;
   - el **id 1 conserva su vector byte a byte**;
   - la reversión devuelve las 119 filas exactas.
4. **Auditoría repetida:** **0 por debajo de 0,999** en STG.

## Recuperación (top 3 de `kb_chunks_rag` por coseno, como la tool): preguntas reales de PROD
| fragmento | pregunta (id de PROD) | antes | después |
|---|---|---|---|
| 6 (datos para emitir) | «Que necesito tener para activar el seguro» (5823) | 52, 15, **6** (3.º) | 52, **6**, 15 (sube a 2.º) |
| 34 (¿la promoción puede cambiar?) | «tienes promociones?» (11128) | **34**, 32, 33 | **34**, 32, 33 |
| 5 (datos para cotizar) | «Si te mando los datos por aquí me podrías dar una cotización?» (4658) | **5**, 7, 80 | **5**, 6, 7 |
| **31 (bancos MSI)** | «se puede pagar con la tarjeta de credito de BBVA a meses sin intereses» (12553) | 33, 32, 21 (**sin el 31**) | 33, **31**, 32 (**entra**) |
| 81 (ebriedad) | **sintética**: en PROD **no hay ninguna** pregunta real de ebriedad | **81**, 65, 84 | 65, 84, 55 (**sale**) |
| 36 (Limitada) | «…que incluye la cobertura amplia y que incluye la cobertura limitada?» (6763) | 35, **36**, 37 | **36**, 37, 35 (sube a 1.º) |

**El 81, aparte:**
- La pregunta sintética («¿…había tomado unas copas?») no comparte ninguna palabra con el fragmento. Probé otras cinco formas
  (borracho, estado de ebriedad, tomado, alcoholizado, ebrio): **el 81 sigue en el top 3 en las cinco**, después igual que antes.
- Su vector viejo coincidía por casualidad con «copas». El nuevo refleja el texto real, que está **sin acentos** («medico», «Danos»,
  «senalado»). **No lo toco**, como dice el handoff. Te lo señalo por si quieres corregir el texto: un texto con acentos recuperaría mejor.

## Para PROD (cuando lo ordenes)
- Los 17 de PROD son los 16 de STG sin el 38, más el 40, que viaja con el #333.
- El mismo `gen-588.py`, apuntado a PROD, genera la migración con sus guardas (los textos de esos ids son iguales en STG y PROD; el md5
  lo comprueba la propia guarda).

Agente: Agente-n8n
