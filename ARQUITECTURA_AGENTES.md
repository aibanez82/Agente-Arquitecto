# Arquitectura de Agentes — Ecosistema IA Quálitas/Insurmind

> Decisión estratégica de arquitectura multi-agente.
> Definido: 27 junio 2026.

---

## Principio rector

**Diagnóstico arriba, ejecución abajo.** Un cerebro razona con visión completa del ecosistema; los ejecutores actúan sobre planes ya validados.

---

## Los 3 niveles

### Nivel 1 — Lectura (read-only)
Agentes que SOLO leen y entienden. No modifican nada.

- **Agente de Código** — Django + n8n + BBDD + Dashboard. Los bugs cruzan constantemente entre estos cuatro sistemas, por eso se unifican en un solo agente.
- **Agente de APIs externas** — GA4 + Meta/WhatsApp. Observa comportamiento de APIs que no se controlan: formatos, límites, latencias, ventanas de datos.

### Nivel 2 — Arquitecto (orquestador)
El cerebro. **NO ejecuta.** Recibe la petición, decide qué fuentes consultar, integra las respuestas y entrega un diagnóstico coherente con el plan de qué tocar y dónde.

### Nivel 3 — Ejecutores (write)
Agentes que actúan sobre los sistemas. Reciben planes validados del Arquitecto a través de Alberto.

- **Agente QA** — tests automáticos end-to-end (`aibanez82/Agente_QATest_Qualitas`)
- **Agente Conversión** — análisis de conversaciones y reintentos *(futuro)*

---

## Regla de oro de comunicación

**Los ejecutores NO se hablan entre sí. Solo comunican hacia arriba, con el Arquitecto, a través de Alberto.**

Si una tarea necesita coordinación entre QA y Conversión, sube al Arquitecto — nunca se coordinan lateralmente. Esto evita el fallo más común de los sistemas multi-agente: dos agentes con permiso de escritura tomando decisiones contradictorias sin supervisión.

---

## Orden de construcción (incremental)

Cada capa valida a la anterior antes de agregar la siguiente.

1. ✅ **Arquitecto + repo Dashboard** — base del diagnóstico cruzado
2. ✅ **Agente QA** — primer ejecutor activo
3. ⏳ **Django HYL-WAI conectado al Arquitecto** — cuando PAT esté disponible
4. ⏳ **Agente de APIs externas** — cuando GA4 y Meta justifiquen un agente dedicado
5. ⏳ **Agente Conversión** — cuando el flujo esté estable y haya que escalar reintentos

---

## Protocolo de comunicación Arquitecto → Ejecutor

El flujo siempre pasa por Alberto:

```
Ejecutor detecta anomalía
       ↓
Alberto la lleva al Arquitecto
       ↓
Arquitecto diagnostica causa raíz
       ↓
Arquitecto entrega plan concreto a Alberto
       ↓
Alberto lo lleva al Ejecutor correspondiente
       ↓
Ejecutor actúa y reporta resultado
```

---

## Mapa de repos

| Repo | Agente | Rol |
|---|---|---|
| `aibanez82/Agente-Arquitecto` | Arquitecto | Documentación transversal, fuente de verdad del ecosistema |
| `aibanez82/Dashboard_seguroautoqualitas` | Dashboard Qualitas | Código Next.js del dashboard únicamente |
| `aguayo-co/HYL-WAI` | (lectura) | Backend Django — fuente de lógica de negocio |
| `aibanez82/Agente_QATest_Qualitas` | Agente QA | Tests end-to-end |
