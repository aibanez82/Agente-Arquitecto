# Propuesta — guardrail determinístico de la Limitada (para tu revisión; NADA construido)

> Agente n8n · 24 ago 2026. Responde a tu encargo tras el hallazgo del smoke (fila 10760: a
> «quiero emitir», el bot listó Amplia y Limitada con precios). Reincidencia post-9.bis → por tu
> cautela del `#206`, el arreglo es guardrail en la salida, no tercera redacción. **Defecto
> concreto que habría atrapado (criterio de admisión del `#179`): la 10760, medida en PROD.**

## Dónde

**Un solo punto de estrangulamiento: el carril del main reply**, entre el post-proceso del
`AI Agent` y `Stash Main Reply Payload` — el mismo patrón que `Format KB Response` (#197). Nodo
`Limitada Guardrail` (code, determinístico, sin LLM). Premisa que te pido verificar en el dictamen:
el texto libre del agente solo sale al cliente por ese carril (los demás conectores llevan textos
fijos); si hay otro camino con prosa del agente, el guardrail necesita replicarse ahí.

## Condición (determinística, dos partes)

Dispara si: **(a)** la respuesta contiene `/\blimitada\b/i` **y (b)** el mensaje entrante del turno
NO contiene `/(limitad|cobertura|opcion|paquete|plan)/i`. La parte (b) implementa el «solo si te lo
preguntan» con una ventana honesta: preguntar por opciones/coberturas ES preguntar. Alternativa más
estricta si Alberto la prefiere: solo `/limitad/i` — a tu criterio; es un literal en el nodo.

## Qué pasa si dispara — en dos fases, para no romper prosa a ciegas

**Fase 1 — OBSERVAR (lo que propongo desplegar primero):** no muta nada; anota el disparo (log de
ejecución + aviso Telegram con el fragmento) y deja pasar. Dos objetivos: medir frecuencia real y
falsos positivos ANTES de darle poder de edición, y estrenarlo sin riesgo. Salida de fase: N días
o M disparos revisados, lo que dictes.

**Fase 2 — ACTUAR:** la mención estructurada (el bloque `**Limitada:**` con sus viñetas, el caso
de la 10760) se **elimina determinísticamente** — es un recorte de bloque, no una reescritura. Si
la mención es prosa inline (no recortable sin riesgo de mutilar), **fail-open con alarma**: se
envía tal cual + Telegram — para una regla de negocio, un mensaje mutilado al cliente es peor que
una mención indebida con aviso. (Si tú o Alberto preferís fail-closed ahí, es un flag del nodo.)

## Ruta de despliegue y pruebas

Grafo compartido → builder (los DOS candidatos lo ganan) → tests en la suite s1: el positivo (la
10760 literal como fixture → dispara), el negativo («¿qué es la cobertura limitada?» → no
dispara), y el recorte estructurado (bloque fuera, resto byte-idéntico). Import a STG con firma
— puede viajar en el MISMO import que el rename+guard pendiente, matando el drift conocido y el
guardrail en un solo movimiento firmado. PROD, en la promoción que ordenes.

## Qué NO es

No toca prompts (cautela #197: apilar prompt sobre prompt es lo que ya falló dos veces). No toca
PROD hasta su promoción. No decide política de negocio: los literales de la condición son
exactamente donde tú y Alberto dictáis.
