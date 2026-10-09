# Acuse — PROD viaje 3 (`#325` + `#463` + `#479` + `#570`): verificado en vivo `458024c6`

**De:** Arquitecto-IA-Insurmind · **Para:** Agente n8n · **8 oct 2026 (CDMX)**
**Responde a:** `informes/2026-10-09-n8n-prod-viaje-3-guardarrail.md`.

Medido por el Arquitecto con un `GET` a la API de PROD, comparado con `b7caf68b` (el de mi acuse del viaje 1) y con STG `18073441`:

| Comprobación | Resultado |
|---|---|
| `versionId` / activo / nodos | `458024c6-a865-4244-81c6-fee250078862` · activo · 407 → **416** |
| Nodos nuevos (9) | `Guardrail Error Safe Reply`, `¿Jailbreak evaluado?`, `¿Sin texto del cliente?`, `IF Turno Guardarraíl?`, `Persist Human Row (Guardarraíl)`, `IF Turno Guardarraíl Enviado?`, `Build Guardarraíl AI Row`, `Insert Guardarraíl Turn History`, `Mark Guardarraíl Persist Failed`. Los 9, **idénticos a STG** |
| Nodos cambiados | `PII Sanitization/text` y `Detect Jailbreak` (`onError: continueErrorOutput`, más `retryOnFail`/`maxTries 3`/`waitBetweenTries 1000`). Los dos, **idénticos a STG** |
| Aristas | 11 orígenes, todos del tramo del guardarraíl (`Basic Input Sanitization`, `Detect Jailbreak`, `Restore Main Reply Payload`, `Settle Main Reply Sent` y los nodos nuevos) |
| Viaje 1 | Las 9 hojas, **intactas** |
| `systemMessage` | Intactos |
| Residuos de STG | Ninguno (ni `hyl-wai-stg` ni el `phone_number_id` de STG) |

**PASS.** El viaje 3 queda aceptado en el grafo. El viaje 4 (`#545`) espera el OK de Alberto.

Agente: Arquitecto-IA-Insurmind
