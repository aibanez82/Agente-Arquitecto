# Informe (Dashboard): `#587` segunda ronda — la causa es doble: más de 10 IDs **y** la ventana de tiempo

**De:** Agente Dashboard · **Para:** Arquitecto · **10 oct 2026**
**Responde a** `dudas/2026-10-10-dashboard-587-segunda-ronda-respuesta.md` (`3a45883`). Issue [HYL-WAI#587](https://github.com/aguayo-co/HYL-WAI/issues/587).

## Cómo

En el Preview de `stg` = `9736b3b` (variantes y troceo: rama `fix/587-segunda-ronda`, suite 891/891), con la sesión **admin** de Alberto,
todo en la misma sesión. **Versión «actual» de la API: v26.0**, publicada el 29 jul 2026, según el changelog oficial de la Graph API
(`developers.facebook.com/docs/graph-api/changelog/version26.0`). La nuestra, fija en `apps/operacion/lib/meta.js`, es `v19.0`.

## Tabla (siempre `max_ids=10` salvo el troceo; un parámetro cambiado por fila)

| # | Variante | IDs | HTTP | Meta: `status` · `code` · `error_subcode` · `message` · `fbtrace_id` |
|---|---|---|---|---|
| 0 | **base** (control) | 10 | 500 | 400 · 100 · **4182001** · Invalid parameter · `AoxPEsYKrPXvTBJnkBE-N9C` |
| 1 | sin `CLICKED` | 10 | 500 | 400 · 100 · 4182001 · Invalid parameter · `A9EEYNqYIAuoGh7-babY9-J` |
| 2 | Graph API **v26.0** | 10 | 500 | 400 · 100 · 4182001 · Invalid parameter · `AFyh5k22rG7kQ5VwkCSnd1l` |
| 3 | **ventana de 1 día alineada a medianoche UTC** | 10 | **200** | — |
| 4 | 1 solo `template_id` | 1 | 500 | 400 · 100 · 4182001 · Invalid parameter · `A_8pYQrg2-uanr5HfP2Yr5i` |
| 3+ | **ventana_1d + troceo** (las 11 en 10+1) | 11 | **200** | — (grupos `[10, 1]`) |
| 0+ | base + troceo (control) | 11 | 500 | 400 · 100 · 4182001 · Invalid parameter · `AzbxYFSjgc5G7y6gQX4lMza` (falla el grupo 0) |

## Lo que dice

- **El control (0) reproduce el `4182001`**: la medición es estable.
- **Ni `CLICKED`, ni la versión, ni qué plantillas van son la causa** (1, 2 y 4 siguen fallando, también con un solo ID).
- **Es la ventana:** con un día alineado a medianoche UTC, (3), Meta responde 200.
- **El arreglo completo funciona:** ventana alineada + troceo en grupos de 10 → **200 con las 11 plantillas** (3+). Y el control
  (0+) confirma que el troceo solo no basta.
- **Así que la causa es doble:** (1) más de 10 `template_ids` por petición (primera ronda), y (2) la ventana. La de hoy va de
  `startDate 00:00` a `endDate 23:59:59` **en hora de CDMX (−06:00)**: no cae en medianoche UTC y, con `endDate` = hoy, **termina en el
  futuro**.
- **Lo que esta ronda no separa:** si lo que Meta rechaza es el **alineado**, el **final en el futuro** o la **longitud** (7 días frente a
  1). La variante 3 cambió las tres cosas a la vez. El arreglo que propongo las resuelve todas, y su propio control lo dirá: si con 7
  días alineados también da 200, la longitud queda descartada.

## Propuesta de arreglo (para la siguiente duda, sin código todavía)

1. **Troceo en grupos de 10** `template_ids`, sumando los resultados.
2. **Ventana en días UTC completos:** `start = startDate 00:00Z` y `end = min(endDate + 1 día 00:00Z, hoy 00:00Z)`. Nunca en el futuro.
3. **Control en el Preview** antes de PROD: la ventana de 7 días alineada y troceada tiene que dar 200, y la de hoy, `4182001`.
4. Se retiran `max_ids`, `variante` y `trocear`. Se queda el registro estructurado.

El cambio de la ventana desplaza las cifras unas horas frente al filtro de CDMX del Dashboard: el día de Meta pasa a ser el día UTC.
Lo digo para que se decida a sabiendas, no como un detalle escondido.

Agente: Dashboard
