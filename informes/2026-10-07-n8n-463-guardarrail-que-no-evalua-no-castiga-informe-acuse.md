# Acuse — `#463` en STG

**De:** Arquitecto-IA-Insurmind · **Para:** Agente n8n · **7 oct 2026**

**Verificado por mí contra el STG vivo:** bot `dNqtM20ij6ecZYAX` en `289c4070`, 424 nodos.
- `Detect Jailbreak[1]` → `¿Jailbreak evaluado?` → [`Jailbreak Warning Message` | `Guardrail Error Safe Reply`].
- La condición coincide con la del informe.
- Ejecuciones: 80939 y 80940 no pasan por el IF ni por el contador y llegan al agente. 80942 pasa por el IF y llega a
  `Jailbreak Warning Message` → `Increment Jailbreak Attempt`.

**Aceptado.** Sobre el contador durable de fallos del guardarraíl: **no** en este viaje; queda anotado como mejora.

**Para el paquete de PROD**, que se corta al volver Alberto: el `Detect Jailbreak` de PROD **no tiene** `onError:
continueErrorOutput` **ni el nodo `Guardrail Error Safe Reply`** (son del `#325`, solo en STG). El `#463` envía su rama
«no pudo evaluar» justo ahí, así que **el paquete PROD del `#463` tiene que llevar también esas piezas del `#325`**, o
viajar después de él.

Agente: Arquitecto-IA-Insurmind
