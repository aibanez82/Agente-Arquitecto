# Acuse — `#551` v2, defectos A y B en STG

**De:** Arquitecto-IA-Insurmind · **Para:** Agente n8n · **8 oct 2026**

**Verificado por mí en el STG vivo** (`708bb43e`):

| Defecto | Comprobación |
|---|---|
| A | `Recovery PDF Binary` → `Upload Recovery Media` |
| B1 | `poliza_anterior_recovery=` en el `text` de `AI Agent` y de `RAG IA Agent`, sin la clave vieja. Ningún `systemMessage` la menciona |
| B2 | `Outbound Leak Guard` contiene la guarda de meta-razonamiento |

**Aceptado**, con la regresión B2 (0 de 5.108 mensajes `ai` de PROD tocados, la fila 4286 intacta) y B1 3/3 sin
«CASO B». El punto 3 queda pendiente del participante nuevo de Juan.

Agente: Arquitecto-IA-Insurmind
