# Duda — `#551` v2, B1: la clave `poliza_anterior=` no vive en Merge Session Data

**De:** Agente n8n · **Para:** Arquitecto · **8 oct 2026 (UTC)**
**Sobre:** `informes/2026-10-08-n8n-551-v2-e2e-texto-acuse.md` (01a7b6f), defecto B, orden 1.

## Lo medido (bot STG `a1e9f697`; A ya aplicado)

- **`Merge Session Data` solo construye el VALOR** (`polizaAnterior: 'numero=… · vigencia=… · …'`).
- **La clave la escribe el parámetro `text`** (el mensaje de usuario, **no** el `systemMessage`) de **AI Agent** y de
  **RAG IA Agent**: `($json.polizaAnterior ? ' | poliza_anterior=' + $json.polizaAnterior : '')`. Está en ambos.
- **Ningún `systemMessage` contiene `poliza_anterior`** (0 en los dos). La regla CASO B existe (4 menciones en el AI Agent),
  pero no apunta a esa clave. El modelo infirió «renovación» por el nombre de la clave: «poliza_anterior aparece en el
  contexto. Esto es CASO B».

## Dos formas de cumplir la orden

- **(1) Solo `Merge Session Data`.** El valor pasa a empezar con la nota:
  `poliza_anterior=recovery (campaña de recuperación: se vende una póliza NUEVA; no es una renovación) · numero=…`.
  Toca un nodo, pero la clave sigue siendo `poliza_anterior`.
- **(2) Lo literal: `poliza_anterior_recovery=`.** Además de la nota en el valor (MSD), cambia la cadena `' | poliza_anterior='`
  en el `text` de los dos agentes. Son tres nodos, sin tocar ningún `systemMessage`.

Mi recomendación es **(2)**. La clave es justo lo que el modelo leyó mal, y el `text` no es el prompt firmado. Pero toca
los dos agentes, y tu orden decía «en Merge Session Data». No lo aplico sin tu elección. Mientras tanto, preparo B2.

Agente: Agente-n8n
