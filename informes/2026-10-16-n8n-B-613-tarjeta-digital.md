# Informe — #613 (a) + adenda 1: la tarjeta digital o virtual

**De:** Agente n8n · B · **Para:** Arquitecto · **16 oct 2026**
**Orden:** `Agente-n8n:handoffs/2026-10-16-B-613-tarjeta-digital-hoy.md` (main, `edd1c12c`) + adenda 1 (`8b214afa`) + adenda 2 (`831040f9`).
**Código:** `Agente-n8n`, rama `fix/613-tarjeta-digital` (`f09f8954`, en origin, sacada de `stg`), carpeta `scripts/613/`. **Nada importado** ni en STG ni en PROD.

## Qué hace

1. **«No me deja pagar» con póliza emitida.** El texto firmado lo pone **el grafo**, no el modelo:
   - `Merge Session Data` calcula `tarjetaDigitalFija` (`tarjeta.js`, copia literal) justo detrás de `cancelarFijo`.
   - Un carril nuevo de 13 nodos, **clonado de «Cancelar Fijo»** sin contador ni silencio, con fence `d613.reply` y fila ai `tarjeta_digital_613`. Entra en la rama «no» de `IF Cancelar Silencio?`, delante de lo que hubiera ahí (hoy `IF Recovery Resumen?`; no se solapan, porque el Recovery corre sin póliza).
   - No llama a `Ensure Payment Link`, porque el modelo no corre.
   - Solo dispara con mensajes de texto: un marcador del sistema (`[IMAGEN_CLIENTE]`…) no entra.
   - Si el último mensaje del bot ya era este mismo texto, no lo repite y contesta el modelo. **Esto lo he decidido yo; la orden no lo dice.**
2. **Adenda 1.** En el `systemMessage` del `AI Agent` cambia **solo** la línea `comprobante_o_error_de_pago`: se le añade la frase al final. La regla del 503, con el mismo texto de la pasarela, no cambia; el constructor lo comprueba (texto de la pasarela 2 veces, frase 1 vez).

## Detector (`bateria.js`, determinista)

- **32/32.** Incluye las frases reales de PROD (h11864, h13991, h15914, h16131, h13962, h5907, h4211, h5086), las del handoff y sus negativos: «no puedo pagar esa cantidad», «hasta la quincena», OXXO, domiciliación, formas de pago, «Rechazar» (el botón), la captura, sin póliza y la no repetición.
- **Corpus entero de PROD, con la póliza forzada:** 8 disparos en 3.337 mensajes de cliente. Los 8 son fallos de cobro reales; 5 de ellos, de clientes con póliza emitida.
- **Dos correcciones sobre el primer borrador**, encontradas al medir:
  - El `\b` de JavaScript no reconoce la «ó» como letra, así que «rechazó» no casaba.
  - Faltaban «no puede hacer el pago» y la errata «rechasa» (h13962, real).

## Arnés (copia temporal del bot de STG; el vivo no se toca)

- **Cómo es la copia:** los envíos a Meta están neutralizados. Los tres nodos que llaman a `payment-link/ensure` apuntan a un webhook de la propia copia que responde `503 {"status":"temporarily_unavailable"}`, así que no se llama a Django. Las sesiones sintéticas se borran por id exacto y la copia se borra al final (GET 404 comprobado).
- **Con el cambio (STG `b321eb6c`), 22/22** (`arnes-613-b321eb6c.json`):
  - **T-digital literal en las 6 frases** (las dos más repetidas, ×3): carril sí, modelo no, `Ensure Payment Link` no, fila ai `tarjeta_digital_613`.
  - **CAPTURA 3/3:** el texto de la pasarela + la frase, literal.
  - **503 3/3:** el texto de siempre, literal.
  - **Formas de pago 3/3** y **sin póliza 3/3:** no sale.
- **Control sin el cambio (STG `3d31853c`, porque A importó entre medias):**
  - Frases reales **0/6**: el modelo improvisa (pregunta, manda al banco, ofrece la liga).
  - Captura **0/1**: sale el texto viejo.
  - 503 **1/1**: igual que con el cambio, que es lo que pide la orden.
- **Lo que encontré en el arnés, y por qué no es un defecto:** con una póliza sintética, el guardarraíl de emisión (`#591`, `Validate Emision Against DB`) reescribía «Tu póliza ya está emitida…» como emisión inventada, y después el `#275` la reafirmaba. Con una póliza real de STG (cotización 2983, `7620104157`) pasa limpio. En PROD la póliza siempre es real.

## PROD (adenda 2)

- **Inventario por hunk** (`inventario_613.py`, solo lectura: un GET y el cambio aplicado sobre una copia en memoria):
  - contra `cc0f03f5`: `inventario-prod-cc0f03f5.md`;
  - y ya contra el vivo actual **`a75c713e`** (538 → 551): `inventario-prod-a75c713e.md`.
- **El diff es solo el del #613:** parámetros cambiados solo en `Merge Session Data` y `AI Agent`, ningún otro campo de ningún nodo, nada quitado, 13 nodos nuevos, y de las aristas existentes solo cambia `IF Cancelar Silencio?` [no].
- **Espero al PUT de A.** Como toca `Merge Session Data`, donde está mi ancla, rehago el inventario sobre el vivo que deje y te lo paso. No hago el PUT sin tu verificación ni sin la confirmación de Alberto.
- **Un aviso operativo:** el clasificador de permisos de mi sesión bloqueó escribir el script del PUT de PROD («Production Deploy»). Se lo he dicho a Alberto. El PUT necesitará que él lo lance o lo autorice en mi sesión.

— Agente n8n · B
