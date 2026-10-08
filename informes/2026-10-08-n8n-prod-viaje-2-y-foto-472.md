# Informe — PROD viaje 2 (`#552` + `#289`) aplicado, y la foto del `#472` en STG

**De:** Agente n8n · **Para:** Arquitecto · **8 oct 2026 (UTC)**
**Responde a:** `Agente-n8n:handoffs/2026-10-08-orden-prod-viaje-2-liga-y-pagos.md` (7eaf4aea).

## Viaje 2: aplicado. Bot PROD `a5b88be9` → **`fe9c5213-e408-420a-81e9-257013df54b1`**

GO de Alberto en mi sesión («Go»), 22:49 UTC.

- **Método.** Los dos módulos verificados en STG, aplicados sobre el **PROD vivo**:
  - `carril_552.py` (57496055), cuyos 13 nodos se calcan de los nodos de PROD, así que llevan credenciales y URL de PROD;
  - `cambio_289.py` (45965488).
  Script: `scripts/prod-viaje2/promote-viaje2-prod.py` (rama `chore/prod-viaje2`, d68ae3ad).
- **Precondiciones medidas antes del PUT:**
  - PROD en `a5b88be9`;
  - las 20 dependencias presentes;
  - el #552 y el #289 ausentes;
  - las anclas del `#207` (`Parse Router Output`) y las del `#289`, únicas.
- **Equivalencia con STG:** las hojas que cambian en PROD son las mismas y con el mismo valor que cambiaron en STG en `aefaa4d2` (#552) y `4f28162d` (#289).
- **Diff en el vivo después del PUT:**
  - hojas cambiadas en nodos existentes: solo `Parse Router Output/jsCode`, `Ensure Payment Link/toolDescription` y `Payment Status Reply/jsCode`;
  - nodos: 393 → 406 (+13); el resto, byte-idénticos;
  - connections: solo `Parse Router Output` y el carril;
  - los dos `systemMessage` intactos;
  - cero residuos de STG;
  - workflow activo.
- **Respaldo:** `backups/prod-viaje2/PROD-BtOaZm7WlZT-24V7hqCnF-a5b88be9-pre-20261008T224931Z.json`.
- **Espejo:** `main` `233f9e57` y `stg`.
- **Pendiente:** el primer caso real de cada uno en PROD.

## Foto del `#472` (STG, exec 82399): **no ejercita la regla de confirmación**

- **Sesión preparada:** `waq_2198_…`, la única `active` del teléfono de Alberto. Las 19 filas previas están guardadas. **Aún no la he restaurado.**
- **La foto:** una tarjeta de circulación real, **girada 90°**. A simple vista se leen bien el NIV y la placa.
- **Lo que leyó el modelo de visión, con confianza «alta» en los dos:**
  - un VIN **inventado**, que difiere del impreso en 14 de 17 posiciones;
  - la placa, con un carácter mal leído (un `2` como `Z`).
- **Lo que hizo el grafo:**
  - `Parse VIN Extraction` descartó el VIN por la validación determinista del #469/#477. La red funcionó.
  - El bot pidió confirmar la placa mal leída y volvió a pedir el VIN.
- **Conclusión:** la regla del `#472` no se ejercitó, porque no hubo un VIN válido que confirmar.
- **El defecto real** es la lectura de una tarjeta girada. Es el mismo patrón por el que preguntó Alberto: «¿por qué le pedimos el VIN si mandó la tarjeta?».
- **Propuesta (no aplicada):**
  - reintentar la visión con la imagen girada (90°/270°) cuando el VIN no pase la validación;
  - o avisar al modelo de que la tarjeta puede venir girada.
  Esta foto serviría de caso fail-first.

¿Sesión: (a) foto derecha para ejercitar el #472, o (b) restaurar?

Nota: en mi mensaje directo de antes se coló la placa leída. No va en este fichero.

Agente: Agente-n8n
