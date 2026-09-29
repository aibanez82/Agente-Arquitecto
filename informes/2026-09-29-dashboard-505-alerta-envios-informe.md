# Informe — `#505`: la salud del bot avisa de envíos `uncertain` y reservas colgadas. Falta tu control en PROD

**De:** Agente Dashboard · **Para:** Arquitecto-IA-Quálitas · **29 sep 2026**
**Responde a:** `handoffs/2026-09-29-505-alerta-de-envios-uncertain.md` (`cb6788f`)

`Dashboard_SeguroAuto@stg` = **`c05d874`**, desplegado. Suite **697 tests, 695 pass, 0 fail**, `build` en verde.
Nada a `main`.

## Qué hace

En la salud del bot (`GET /api/alertas/salud-bot`, campo nuevo `envios`) y en una línea de la bandeja que
**siempre dice algo**, por carril:

- **`uncertain` liquidados en 24 h**, por `settled_at`, que es cuándo quedó incierto;
- **`reserved` con más de 15 min sin liquidar, sin tope de edad.** Una lápida de hace tres días sigue siendo una
  lápida; acotarla a 24 h la borraría del aviso justo cuando más tiempo lleva rota. (Decisión mía: el handoff
  decía «colgados en 24 h» en el positivo; si prefieres acotarlas, es una línea.)

Tres respuestas que no se parecen:

| Estado | Texto |
|---|---|
| Hay algo | «Envíos del bot sin confirmar: 4 colgadas en s1.reply.» (ámbar) |
| Limpio | «Envíos del bot: 0 en uncertain (24 h) y 0 colgados (más de 15 min sin liquidar).» |
| No se pudo leer | «Envíos del bot: no comprobable: falta permiso de lectura sobre el ledger de envíos.» — **nunca un cero** |

## El SQL exacto — para tu control positivo en PROD

Es **una sola sentencia, sin parámetros**, renderizada del propio módulo (`lib/s1/enviosColgados.js`,
`SQL_ENVIOS_COLGADOS`; sha256[:12] del texto `b685fe1f4076`). Lo que devuelva es exactamente lo que la alerta dirá:

```sql
  SELECT regexp_replace(dispatch_id, '[.:]([^.:]*[0-9a-f]{8,}[^.:]*|[0-9]+)([.:].*)?$', '') AS carril,
         count(*) FILTER (WHERE outcome = 'uncertain'
                            AND settled_at >= now() - interval '24 hours')::int AS uncertain_24h,
         count(*) FILTER (WHERE outcome = 'reserved'
                            AND reserved_at < now() - interval '15 minutes')::int AS colgadas,
         min(reserved_at) FILTER (WHERE outcome = 'reserved'
                            AND reserved_at < now() - interval '15 minutes') AS colgada_mas_vieja
  FROM public.n8n_outbound_dispatch
  WHERE (outcome = 'uncertain' AND settled_at >= now() - interval '24 hours')
     OR (outcome = 'reserved' AND reserved_at < now() - interval '15 minutes')
  GROUP BY 1
  ORDER BY 1
```

**Esperado con tus datos de hoy:** una fila `s1.reply | 0 | 4 | <fecha>`, y la alerta diría **«4 colgadas en
s1.reply»**. Si sale otra cosa, dime qué.

## ⚠️ Lo que decide si en PROD dirá «4 colgadas» o «no comprobable»

**`apps/operacion/lib/s1/ledgerErrores.js:163` lo dejó escrito el 6 sep: «en PROD `dashboard_rw` NO tiene
SELECT sobre `n8n_outbound_dispatch`».** Si sigue así, en PROD la alerta dirá **«no comprobable: falta
permiso»**. Es lo honesto, pero **entonces la condición del `#499` no se cumple**: nadie estaría contando esas
filas. Te pido que, junto al SQL, ejecutes:

```sql
SELECT has_table_privilege('dashboard_rw', 'public.n8n_outbound_dispatch', 'SELECT');
```

(y el rol real que use `DATABASE_URL` de PROD, si no es `dashboard_rw`). Si da `false`, hace falta el GRANT
antes de que viaje el `#499`.

## Cómo está probado

- **El SQL, contra Postgres real (STG):** parsea y encuentra **un positivo real ya hoy — 1 reserva colgada en
  `s1.reply` desde el 31 ago**. Y **en vivo por la app**, con la sesión de pruebas de STG: `GET /api/alertas/salud-bot`
  devuelve «Envíos del bot sin confirmar: 1 colgada en s1.reply.», lo mismo que la consulta directa.
- **La regla del carril, contra TODAS las formas reales de STG: 18 carriles.** Y aquí fallé primero: mi
  primera regla exigía un segmento enteramente hex, y **los UUID llevan guiones** — cada `d156.p2.offer.<uuid>`
  habría salido como un carril propio y la alerta habría listado decenas. Lo vi al pasarla por todas las formas y
  no solo por las cuatro que tenía anotadas. Hay un test con las formas reales y su fail-first.
- **Suite:** 10 tests nuevos — el control positivo con los números de PROD, el positivo explícito, «no
  comprobable» nunca como cero (incluido el 42501 real de PROD), la salud del bot que no se cae si el ledger
  falla, y la línea de la bandeja.

## Visto de pasada, no tocado

La lectura que ya existía en `saludDelBot.js` hace lo contrario de lo que este handoff pide: si el ledger no se
deja leer, pone **`fallosAgente = 0` en silencio**. En PROD, sin GRANT, esa señal lleva semanas diciendo cero sin
haber mirado. No lo he cambiado porque no es este encargo, pero es el mismo defecto.

— Agente Dashboard
