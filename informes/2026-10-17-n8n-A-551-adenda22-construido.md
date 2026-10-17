# n8n · A → Arquitecto: `#551`, adenda 22 construida en la rama. Sin importar

**Fecha:** 17-oct-2026 · **Orden:** `Agente-n8n:handoffs/2026-10-16-A-551-recovery-a-prod.md`, adenda 22 (`23c4e410`).

**Dónde está.** En `Agente-n8n`, rama `feature/551-ver-promo-por-texto`, en `origin` y sin fusionar. Es el commit **`17aebb03`**, encima de `7de52cd8`, el de la adenda 20.
- No lo he juntado con `7de52cd8` en un solo commit: ese SHA ya está en tu adenda y en mi informe, y no reescribo historia revisada por SHA.
- Los dos commits van en el mismo viaje.
- **Nada importado, ni en STG ni en PROD. 0 llamadas a modelo.**

## Lo construido (`scripts/551vp/cambio_551vp.py`)
1. **Enganche (A) en `Parse Router Output`.**
   - Una lista estrecha de formas de «no me aparece», «no veo / no encuentro», «botón», «ver promo», «ese es el mensaje», «solo / nada más me llegó el mensaje» y «dónde está / le doy».
   - Pone `recoveryVerPromo` en verdadero **diga lo que diga el clasificador**.
   - Solo actúa en solo-contexto y no pisa `identity` ni `qualitas_parameter`.
   - No toca el prompt del router.
2. **`Recovery Ver Promo Lookup`.**
   - Devuelve **siempre una fila**: `participant_id`, que puede venir vacío, y `ver_promo_previos`.
   - `ver_promo_previos` cuenta las filas `ai` de la sesión que empiezan por «Para darte tu precio con la promoción».
3. **`Recovery Ver Promo Copy`.**
   - Con 0 previos, manda el texto de hoy, literal.
   - Con 1 o más, o con el contador ilegible (ausente, null, basura o el `$()` que lanza), **deriva**.
   - La derivación lleva tu texto de la propuesta 39 y el enlace de `WA Config`, con la forma del `#608`.
   - Sin atención humana o sin número, va el marcador del `#257`.
   - **El texto de la derivación no viaja a PROD sin la firma.** Si Alberto lo cambia, solo cambia `TEXTO_DERIVACION`.
4. **El E2E** (`e2e-551vp-stg.py`): un solo turno, «No me aparece», con `context.id` del outbound de la campaña. Menos de 8 llamadas.

## Batería offline (`offline-551vp.py`): 71/71, 0 llamadas a modelo

**Lookup**
- STG en `BEGIN READ ONLY`/`ROLLBACK` y PROD en solo lectura.
- El contador se compara con un **recuento independiente**: STG `waq_2983` da 3 y PROD `waq_4507` da 4.
- Una sesión sin interacción devuelve una fila vacía con 0 previos.
- **Corrección marcada:** yo esperaba 0 previos en `waq_2983` y tiene 3, de las E2E del `#551` v2 en STG. Era mi expectativa, no un defecto.

**Copy, en node**
- 0 previos da el texto de hoy; 1 y 4 dan la derivación con el enlace.
- Los 4 casos de contador ilegible derivan.
- Sin humano y sin número sale el marcador.
- La derivación no empieza por la frase que se cuenta, así que no cuenta como respaldo.

**Router, en node, sobre el STG vivo (`606da14f`) y el PROD vivo (`1265f994`)**
- Las 4 salidas **reales** del clasificador de `waq_4507` piden el PDF.
- «No me aparece» y «Ese es el msj nada más» lo piden con **cualquiera** de los 7 intents y con la salida vacía, salvo `identity` y `qualitas_parameter`.
- **Control fail-first:** con el nodo vivo, esas dos frases como `kb_query` u `out_of_scope` no lo pedían.
- **Control negativo, con `waq_4518` incluido:** no pide el PDF ninguno de estos 12 mensajes como `kb_query` ni como `out_of_scope`:
  - el «Estoy pagando una poliza mensual con ustedes mismos» de `waq_4518`;
  - 9 del corpus de PROD;
  - 2 sintéticos («Ya no me interesa» y «gracias»).
- Las 6 formas sintéticas de «no veo el botón» sí lo piden.
- Fuera de solo-contexto, no lo pide.
- «eres un robot no me aparece» sigue siendo `identity`.

**Cableado, sobre los dos vivos**
- Los nodos nuevos y los tocados solo leen ancestros (por BFS).
- Ninguna `$()` apunta a un nodo que no exista.

## Una cosa que decides tú
- La derivación **sí se repite** a partir de la tercera vez. La derivación no empieza por «Para darte tu precio…», así que el contador sigue en 1 o más, y cada nuevo intento fallido vuelve a derivar.
- **Ya no se repite el respaldo, que es el defecto de `waq_4507`.**
- Si quieres que la derivación salga una sola vez y después el bot se calle o haga otra cosa, dímelo. No lo he construido porque la orden no lo pide.

**Lo que falta:** el E2E N=1, cuando haya cuota y el participante limpio que pide Alberto. Después, el viaje a PROD de la adenda 20 junto con esta, con la firma de la propuesta 39.

Agente n8n · A
