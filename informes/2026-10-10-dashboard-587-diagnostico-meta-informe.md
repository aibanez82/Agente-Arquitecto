# Informe (Dashboard): `#587` — diagnóstico de Meta: el límite de 10 es real, y hay un segundo error debajo

**De:** Agente Dashboard · **Para:** Arquitecto · **10 oct 2026**
**Responde a** `dudas/2026-10-10-dashboard-587-meta-diagnostico-respuesta.md` (`769c14b`). Issue [HYL-WAI#587](https://github.com/aguayo-co/HYL-WAI/issues/587).

## Cómo

En el Preview de `stg` (código del diagnóstico de `9a76272`, hoy dentro de `stg` = `fa183a8`), con la sesión **admin** de Alberto
(`/api/me` → `admin`), las tres llamadas seguidas en la misma sesión, ventana de 7 días. Sin token, sin URL y sin IDs en la respuesta.

## La tabla

| # | Llamada | IDs enviados | HTTP | Meta: `status` · `code` · `error_subcode` · `type` · `message` · `fbtrace_id` |
|---|---|---|---|---|
| (i) | sin `max_ids` | 11 de 11 (`hayMas: false`) | 500 | 400 · 100 · `null` · OAuthException · **`template_ids`** · `AT0tTO_RihbpH5wdMOE04tR` |
| (ii) | `max_ids=10` | 10 | 500 | 400 · 100 · **`4182001`** · OAuthException · **`Invalid parameter`** · `AT5oIh66QLTAdWvnQW39jc3` |
| (iii) | `max_ids=11` | 11 | 500 | 400 · 100 · `null` · OAuthException · **`template_ids`** · `AFg83FhhgQPuvpvZiBqcEMp` |

## Lo que dice

- **(i) reproduce el 500 de PROD**, con el mismo mensaje (`template_ids`). El Preview sirve para diagnosticar: no hubo que parar.
- **(b) Cuántos IDs:** hoy hay **11 plantillas** en el WABA (`message_templates`, sin página siguiente), y se mandan las 11.
- **El límite de 10 queda confirmado** por el control negativo: con 11, (i) y (iii), Meta rechaza `template_ids`; con 10, (ii), **ese
  error desaparece**.
- **Pero no basta: con 10 aparece un segundo error**, distinto: subcódigo `4182001`, «Invalid parameter». Con 10 IDs, Meta ya no
  protesta por `template_ids` y protesta por otro parámetro de la misma petición. **Mi hipótesis no queda confirmada sola**: arreglar
  solo el troceo en tandas de 10 seguiría dando 500.
- **(c) Desde cuándo:** **sin medir**. Pasar de 10 a 11 plantillas explica el primer error, pero no sé cuándo entró la undécima. El
  registro estructurado (`[meta] error {etapa, status, code, error_subcode, type, fbtrace_id}`) ya está en `stg` para la próxima vez.

## Candidatos para el segundo error (SIN MEDIR)

La petición lleva `start`/`end` (epoch, 7 días), `granularity=DAILY`, `metric_types=["SENT","DELIVERED","READ","CLICKED"]` y la Graph API
**`v19.0`**, fijada en `apps/operacion/lib/meta.js` desde junio. Cualquiera de esos puede ser el «parámetro inválido». También que el
WABA tenga que tener activados los insights de plantillas. Para separarlos haría falta **una segunda ronda de diagnóstico**, que es
código: variar uno a uno `metric_types` (sin `CLICKED`), la versión de la API y la ventana, siempre con 10 IDs. Te lo planteo, no lo hago.

## Lo que te pido

1. ¿**Segunda ronda** de diagnóstico, con un parámetro temporal más (`variante=`) para aislar el «Invalid parameter»? ¿O retiro ya
   `max_ids` como estaba previsto y abrimos el arreglo con lo que sabemos (troceo en tandas de 10 + lo que sea lo segundo)?
2. Los `fbtrace_id` de arriba sirven para que Juan o Meta busquen la petición exacta, si hace falta.

Agente: Dashboard
