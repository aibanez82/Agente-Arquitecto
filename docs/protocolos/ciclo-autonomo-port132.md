# Ciclo autónomo de iteración — port #132 (Arquitecto ↔ Agente n8n ↔ Juan)

> Montado 29 jul 2026 a petición de Alberto: que las iteraciones técnicas
> (ejecutor entrega → Arquitecto revisa → Juan audita → vuelta) corran sin intervención
> humana, dejando a Alberto solo las decisiones que son suyas.

## Las tres patas

1. **Arquitecto (esta sesión):** un Monitor persistente vigila (a) commits nuevos en
   `Agente-n8n:feature/issue-132-port-dual-safe` y (b) comentarios nuevos de `oilycoyote`
   en HYL-WAI#132 (poll cada 60 s). Al despertar:
   - **Commit del ejecutor** → reproducir suites en worktree propio + pasada adversarial
     (3 lentes, `estandar-adversarial-desarrollo.md`). Verde → notificar a Juan en #132
     pidiendo re-auditoría. Hallazgos → handoff `6.8.N+1` en `Agente-n8n:handoffs/` +
     commit/push (el loop del ejecutor lo recoge solo).
   - **Comentario de Juan** → triangular. Hallazgos técnicos → handoff nuevo al ejecutor.
     Aprobación/sign-off → actualizar guion/docs y avisar a Alberto. Decisión de negocio →
     PARAR y avisar a Alberto (ver límites).
2. **Agente n8n (sesión de Alberto, arranque manual una vez):** un `/loop` que hace
   `git pull` y ejecuta el handoff más reciente sin reporte correspondiente; al terminar,
   commit+push (eso despierta al Arquitecto). Comando exacto: ver abajo.
3. **Juan:** ya itera por #132 de forma natural — no necesita nada nuevo.

## Comando para la sesión del Agente n8n (pegar UNA vez)

```
/loop Haz git pull en feature/issue-132-port-dual-safe. Si hay en handoffs/ un handoff de
fase 6.8.x del Arquitecto SIN reporte docs/ correspondiente, ejecútalo completo (protocolo
fail-first, 3x ambos flavors) y al terminar haz commit+push del código y el reporte. Si no
hay handoff pendiente, no hagas nada. No toques STG/PROD ni notifiques a Juan — eso es del
Arquitecto.
```

## Límites — lo que el ciclo NUNCA hace solo (queda para Alberto)

- Decisiones GO/NO-GO de ventanas de deploy, y cualquier deploy/import real a STG o PROD.
- Merges a `main`/`stg` de cualquier repo, rotación de secretos, cambios de env vars.
- Compromisos de fechas o de alcance con Juan más allá de la iteración técnica en curso.
- Si Juan pide algo fuera del carril técnico (o algo huele a decisión de negocio), el
  Arquitecto responde "lo llevo a Alberto", avisa por PushNotification y se detiene ahí.
- Ante ambigüedad sobre si algo es "técnico" o "decisión": es decisión → Alberto.

## Cordura anti-bucle

- Máximo 2 iteraciones autónomas Arquitecto↔ejecutor por paquete sin intervención de
  Alberto; a la tercera, PushNotification y parar (señal de que el enfoque está mal, no
  de que falten parches).
- El Monitor es de esta sesión — si la sesión muere, el ciclo muere con ella (rearmar al
  reabrir; este doc es la referencia).
