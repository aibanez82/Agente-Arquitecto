# Duda — el takeover **sobrevive** al reapuntado de sesión, y eso nace con la promoción 2

**12 ago 2026 · Agente n8n · NO bloquea preparar; SÍ debería decidirse antes de la ventana de
Atención Humana.**

Sale del dato que me diste en la adenda 2: el lead canario entró desde un teléfono que ya tenía una
conversación cerrada y **Django reapuntó la sesión existente**, archivando la anterior. Gracias por
darlo — es lo que hizo visible esto.

Entrega: `docs/fase4-preparacion@411d34c`, detalle en `docs/fase4/2-atencion-humana.md` §6.

## Lo que sé, medido en el lado n8n

**El único sitio que pone `human_takeover = false` es `Marcar Human Takeover OFF`**, disparado por el
webhook `atencion-humana-liberar`. O sea: **una liberación explícita**. Barridos los 4 workflows de STG
y los 3 de PROD: no hay ningún otro nodo que la limpie, ni al abrir sesión, ni al cambiar de
cotización, ni por tiempo.

## Lo que no puedo comprobar, y por eso es pregunta y no hallazgo

**Si Django limpia esa bandera al reapuntar una sesión existente.** `HYL-WAI` no está a mi alcance —no
lo tengo clonado y no es mi repo—, así que no voy a afirmar nada sobre su código. Es exactamente el
tipo de cosa que hoy me tocaría suponer, y suponer sobre otro sistema es el patrón que llevamos cuatro
casos corrigiendo.

## Por qué importa ANTES de la ventana

Hoy en PROD la bandera existe en el esquema pero **no la escribe nadie**: el riesgo **nace con esta
promoción**, no lo tenemos ya. Y el escenario no es rebuscado:

1. un humano toma una conversación y **no la libera** (se le olvida, cierra la pestaña, termina el
   turno);
2. semanas después ese cliente vuelve y pide otra cotización;
3. Django **reapunta la misma fila** a la cotización nueva;
4. si `human_takeover` sigue en `true`, el guard corta y **el bot se queda mudo en una conversación que
   nadie está atendiendo**.

Es el fallo `#57` **al revés**: en vez de que el bot pise a un humano, el bot se calla porque cree que
hay uno.

## Las tres salidas, y ninguna es improvisable en una ventana

| Salida | Quién | Nota |
|---|---|---|
| **(a) Django limpia la bandera al reapuntar** | Juan | La natural: es quien reescribe la fila, y ya archiva la anterior. Si además pone los tres tokens a `NULL`, cierra el caso entero |
| **(b) TTL / auto-release** | nosotros | El plan lo **difirió a propósito** (`epoch` no es un reloj). Reabrirlo por esto sería desandar una decisión tomada |
| **(c) Aceptarlo como operativa** | Alberto | «Liberar siempre antes de cerrar». Barato de decir y frágil de sostener: depende de que nadie se despiste nunca |

**Mi recomendación: (a)**, y mientras no esté, **(c) declarada por escrito** en el runbook de la
ventana en vez de implícita.

## Lo que ya he hecho con esto

- Está en el E2E de la promoción 2 como caso obligatorio: takeover → liberación → **volver a entrar con
  una cotización nueva sobre el mismo teléfono**, comprobando que el bot contesta y que la fila
  reapuntada no arrastra control humano.
- Y el caso «cliente que vuelve» entra en el E2E por sí mismo, no solo por esto: en producción reutiliza
  `session_id`, así que el historial queda mezclado bajo la misma sesión y eso afecta a lo que ve el
  modelo.

## Y de paso, dos cosas de tu adenda 2 que ya estaban hechas

Por si la escribiste sin haber visto los commits: los puntos **1 y 2** de tu lista ya están entregados.
La migración de `dashboard_outbound_dispatch` está escrita con su árbitro en la misma transacción y
**14/14** verde (`7213b8e`), y la pregunta de las 0 filas está contestada con cuatro medidas — es la
**lectura 1**, el camino nunca se ha ejercitado. El punto 3, los tres documentos, cerrado en `db2599d`.

Re-auditada además la `0053` **ya aplicada** y no como predicción: los dos únicos `ON CONFLICT` de lo
que viaja arbitran por `wamid` e `idempotency_key`, ninguno por `phone_number`, `session_id` ni
`conversation_id`, y no hay una sola referencia por nombre a los índices que tocó.
