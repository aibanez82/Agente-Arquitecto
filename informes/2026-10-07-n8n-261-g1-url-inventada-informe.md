# Informe #261 G1 — ninguna URL inventada llega al cliente (STG)

**De:** Agente n8n · **Para:** Arquitecto · **7 oct 2026**
**Responde a:** `Agente-n8n:handoffs/2026-10-07-261-ninguna-url-inventada-sale.md`, con tu respuesta a mi duda (tres fuentes, la 1
limitada a la sesión). **Estado:** aplicado en STG y aceptado. La liga de pago en vivo es **NO COMPROBABLE**: Django STG devuelve 503.
**PROD no está tocado.**

## versionId y diff

**Bot STG:** `faa1da51` → **`affd10b4`**. Respaldo: `backups/261g1/bot-stg-faa1da51-20261008T002809Z.json`.

**Cadena:** `Figure Fidelity Guard` → **`URL Sources`** → **`URL Fidelity Guard`** → `Email Fidelity Guard`. El envío y `Sync Memory`
siguen leyendo la salida de `Email Fidelity Guard`, que ya es el texto final.

- **`URL Sources`** (Postgres, `onError` continúa, `alwaysOutputData`). Extrae por regex en SQL **solo** los campos `url`,
  `link_pago` y `payment_url` de las filas `tool` **de esta sesión**, con techo de 20 000 caracteres por fila, 200 filas y URLs de
  hasta 500 caracteres. Esas son las claves medidas en PROD: 79, 13 y 3. Añade el `pdf_cotizacion_url` de la cotización de la
  sesión. **Nunca serializa salidas enteras** (#261a).
- **`URL Fidelity Guard`** (Code, molde #341/#473), solo para respuestas **del agente**: las deterministas, con `reason`, no se
  tocan.
  - **Lista fija:** `api.whatsapp.com`, `wa.me` y `seguroautoqualitas.com` **sin ruta**.
  - **Si quita una URL:** el mensaje pasa a la frase U4, «Ese dato no lo tengo aquí a la mano, y no quiero darte uno que no sea
    exacto.», más la **última pregunta** del mensaje si no llevaba URL. U2 tiene huecos que el grafo no puede rellenar.
  - **Registro:** cada recorte queda en `urlFidelity261` (`url_retirada`, URLs quitadas, sesión) y en `console.log('FIDELIDAD_261_url')`.
  - **Fail-open de verdad:** si `URL Sources` falla, no recorta nada.
- **Diff contra el respaldo:**
  - hojas: solo las de los 2 nodos nuevos;
  - connections: solo `Figure` → `Sources` → `Guard` → `Email`;
  - los dos `systemMessage` intactos; el workflow activo.
- **Código:** rama `fix/261-g1-ninguna-url-inventada`, `scripts/261g1/`.

**Dos defectos atrapados antes del import:**
1. Mi primera regex usaba `{1,500}`. **Postgres no admite repeticiones por encima de 255** («invalid repetition count»): el nodo
   habría fallado siempre y la guarda, fail-open, no habría hecho nada sin avisar. Ahora el techo va en el `FILTER (length <= 500)`.
   La consulta exacta del nodo está probada contra la BD de STG.
2. Si `URL Sources` fallaba, la guarda veía la lista de fuentes vacía y recortaba **todas** las URLs. Ahora, ante un fallo de las
   fuentes, no toca nada.

## Aceptación

| # | Resultado | Evidencia |
|---|---|---|
| 1 | **PASS** (arnés) | El texto real de exec `23897` (fila STG 5886, `Cotizacion_2302_AI_2020.pdf`): `url_retirada` → U4 + «¿Continuamos con la contratación?». En STG, la cotización 2302 tiene `pdf_cotizacion_url` NULL y la URL da 403. Las fuentes de `waq_2302` traen el PDF de la **2301**, no el de la 2302. |
| 2 | **PASS** (arnés) | `payment_url` de `Ensure Payment Link` en las fuentes → intacta. |
| 3 | **PASS** (arnés y regresión) | Con tu decisión (fuente 1 = la sesión), una liga de **otro turno de la misma sesión** pasa. **Control positivo:** una URL real de tool de **otra sesión** de PROD, evaluada con las fuentes de la sesión equivocada → **quitada**. También se quita el dominio con ruta inventada (`seguroautoqualitas.com/promo-secreta`). |
| regresión | **PASS 59/59** | Todos los mensajes del modelo con URL de PROD en 30 días (59), con sus fuentes calculadas con **la misma regex** del nodo y el código real de la guarda: **59 intactos, 0 recortes**. |
| 4 | **PDF PASS / liga NO COMPROBABLE** | Teléfono de Alberto. **81033** (`waq_2678`, cotización con PDF): «¿Me mandas el PDF…?» → `Get Quotation Data` → «Aquí tienes de nuevo tu cotización: https://…/Cotizacion_2678_HI_2024.pdf», **intacta** (`pdf_propio` en las fuentes). **81031** (`waq_2300`, liga): Django STG devolvió 503 y el bot dio el texto de error, sin URL. **81029** (`waq_2345`, cotización sin PDF): el modelo no mandó URL. |
| 5 | **PASS** | Diff: arriba. |

**Sesiones:** `waq_2345`, `waq_2300` y `waq_2678`, fijadas como `active` solo durante su caso; las tres **cerradas**.

**Anotado:** las fuentes incluyen URLs `nel.heroku.com/reports?…`, que vienen de las **cabeceras HTTP** guardadas en las salidas de
algunas tools (el campo `url` del `report-to` de Heroku). Son inocuas como fuente permitida: el modelo no tiene motivo para
mandarlas. Pero muestran que esas salidas se guardan con cabeceras; quizá merezca un issue aparte.

— Agente n8n
