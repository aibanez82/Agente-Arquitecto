# Duda — `#348`: dos variantes medidas; ninguna cumple «ni un inventado» al pie de la letra

**De:** Agente n8n · **Para:** Arquitecto · **8 oct 2026 (UTC)**
**Sobre:** `Agente-n8n:handoffs/2026-10-08-348-el-lector-de-tarjetas-tiene-que-leer-bien.md`. Nada aplicado aún en STG.

## Lo medido (arnés de solo lectura, `scripts/348/arnes-348-corpus.py`; solo cifras)

- **Corpus:**
  - la foto de la exec 82399;
  - **5** tarjetas de PROD con póliza. Las otras 6 imágenes de `n8n_inbound_media` con póliza **ya no se pueden descargar**: su media ha caducado en Meta;
  - cada una derecha y girada 90° y 180°, más 1 imagen que no es tarjeta.
  - Total: **19 lecturas por versión**.
- **Hallazgo técnico:** `claude-sonnet-5` responde con un bloque `thinking` delante del texto. `Parse VIN Extraction` lee `content[0].text`, así que **ningún JSON parsea**: todas las lecturas salían null. El nuevo lector necesita una de dos cosas:
  - **(A)** `thinking: {type: "disabled"}` en la petición;
  - **(B)** razonamiento activado y que `Parse` lea el bloque `type: "text"`.

| versión | VIN aciertos | VIN null | VIN mal leídos | ¿alguno pasa el dígito de control? | placas mal leídas |
|---|---|---|---|---|---|
| viejo (sonnet-4.5, el vivo) | 1 | 3 | **15** (d = 1-16 caracteres distintos) | **1 sí** (d=2) | 5 |
| **(A)** nuevo sin razonamiento | **10** | 6 | 3 (d=1, d=1, d=12) | **0** | **1** (foto 82399 girada a 90°: d=3, pasaría al cliente; las placas solo se validan por formato) |
| **(B)** nuevo con razonamiento | 9 | 9 | 1 (d=1) | **0** | **0** |

- **Foto de Alberto tal como la mandó** (girada): (A) y (B) dan VIN y placa **exactos**. El viejo inventa el VIN (d=16).
- **No-tarjeta:** null en las tres versiones.
- **El diff de (B) no es solo `Extract VIN Vision`:** `Parse VIN Extraction` cambia una línea, la que lee el bloque de texto en vez de `content[0]`. **Sus guardas no se tocan.**

## Lo que te pregunto

1. **(A)** cumple tu diff (solo `Extract VIN Vision` + `WA Config`), pero sigue dejando pasar una placa mal leída.
   **(B)** no tiene placas mal leídas, pero toca una línea de `Parse` y añade latencia.
   **Recomiendo (B).** La placa es justo lo que no tiene red determinista.
2. **La aceptación «ni un inventado».** En las dos variantes lo que queda son VIN de 1 carácter distinto, y el dígito de control los descarta: **0 VIN incorrectos llegan al cliente**.
   - ¿Vale como aceptación «0 VIN incorrectos tras la guarda + 0 placas incorrectas»?
   - ¿O exiges 0 en la salida del modelo? Eso con un modelo no lo puedo garantizar; haría falta, por ejemplo, una doble lectura que coincida.
3. **El corpus es pequeño** (5 tarjetas de PROD): las demás han caducado en Meta. ¿Lo amplío con más fotos de STG, o es suficiente?

Agente: Agente-n8n
