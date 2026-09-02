# Duda `#275f` (segunda) — la congelación de la 2316 y «repite en sesión sana» chocan: la activa gana SIEMPRE la resolución

**De:** Agente n8n · **Para:** Arquitecto · 2 sep 2026
Tu orden: repetir 4-6 en sesión sana, sin tocar la 2316. **Medido: las dos cosas a la vez no se
pueden** — y antes de improvisar, te traigo la colisión con opciones.

## 1 · Lo medido

`Session Resolution` (código vivo del bot, rama `phone_open_sessions` — texto normal):

```js
const active = usable.filter((m) => m.status === 'active');
if (active.length === 1) { sessionRow = active[0]; ... }   // la activa gana SIEMPRE
else if (active.length === 0 && open.length === 1) { ... } // solo sin activa cae a la open única
```

La ÚNICA sesión `active` del teléfono de prueba es **la 2316 congelada**. No decide la recencia ni
el `updated_at`: decide el status. **Consecuencia: mientras la 2316 esté `active` y clavada, TODOS
los textos del teléfono de prueba caen en ella** — no solo mi batería: cualquier E2E conversacional
de STG desde el teléfono de Alberto está muerto. La congelación, tal cual, apaga la testabilidad.

## 2 · Opciones, con su coste medido

**(i) — la que recomiendo: cambiar UN campo de la 2316, `status` `active` → `open`, con este escrito
como el «por escrito y con el motivo» que tu §2 exige.** El valor probatorio de la 2316 no vive en el
status: vive en sus **123 filas y en el corte en la 6071** — y eso queda intacto (nada escribe en su
historial; el 400 sigue reproducible para verificar el `#297` resolviéndola por `payload_v1`/`v2` o
reactivándola ese día). Con la 2316 en `open`, el teléfono queda con varias `open` → la resolución
cae a la **desambiguación del dual** («¿cuál cotización?») — que es flujo REAL de cliente —, elijo la
2322, la afinidad la vuelve `active`, y corro 4-6 sanos ahí (la 2322 tiene cotización → el caso 6
pregunta SU precio de verdad).

**(ii) El teléfono de Juan** (waq_2323, `active`, historial corto y sano, cotización 2323): 3
WhatsApps reales a Juan con aviso previo tuyo. Coste: el caso 4 pierde filo — la 2323 no tiene póliza
que desmentir — y molestamos a un tercero.

**(iii) Teléfono sintético por el arnés: descartado** — el `Send message` contra un número
inexistente falla en el Graph API y contamina la medición con otro fallo.

## 3 · Qué NO haría en ningún caso

Añadir filas a la 2316 (mueve el borde: destruye la evidencia) o resetear el teléfono de prueba
(`reset-test-phone-stg.py` la borraría entera).

Con tu (i), (ii) u otra, ejecuto y te reporto los 4-6 con literales.

— Agente n8n
