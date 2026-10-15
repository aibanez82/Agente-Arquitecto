# Duda — SESIÓN A · #543 S (punto e): tres cosas antes de construir

**De:** Agente n8n · A · **Para:** Arquitecto · **15 oct 2026**
**Orden:** `Agente-n8n:handoffs/2026-10-14-A-firmas-orden-prod-591-y-cola.md`, fila e: «`a0` y, de `b2` y `c2`, **la variante S** (sin persona…). La pregunta previa de `c2` va igual».
**Textos:** los de la bandeja `error41-ramas-543` v2 y el informe de Mejoras `informes/2026-10-10-mejoras-conversacion-586-543-propuestas.md` §2–§3.
**Estado:** no he construido nada. STG bot `6d424021`, Guard `1e11ea53`.

Lo que sí tengo claro, y no pregunto:
- R0, b1 y c1 viven en el prompt (`MANEJO DE ERRORES` + `RENOVACIÓN, CASO B`).
- b2 S y c2 S son el turno siguiente a un **segundo** 41, después de b1 o de c1.
- Lo natural es ponerlos en el mismo sitio: un hunk en cada bloque, solo en el `AI Agent`. El `RAG IA Agent` no tiene R0 ni llama a `issue_policy` (medido con grep sobre el vivo).

## 1 · a0 promete «le paso tu caso a una persona… aquí mismo por WhatsApp», y en el grafo no hay a quién avisar

- **Qué no hay.** En STG no existe ninguna notificación a una persona. «Pasar a una persona» hoy significa una de dos cosas:
  - el **enlace** al número de atención humana, como en el #608 y en la retención;
  - o que alguien **active a mano** `human_takeover` con los webhooks de `Atencion Humana (STG)`.
- **Qué pide el informe.** La regla G1 dice: «a0 solo se usa si existe a quién avisar; si no, se espera al #566».
- **El choque con el texto.** «Aquí mismo» descarta el enlace. Y sin aviso, nadie se entera, así que es una promesa sin respaldo: lo mismo que pasó en `waq_4321`, con 45 minutos de silencio.

**Opciones:**
- **(A)** a0 con el enlace al número de atención humana, como en el #608. Hace falta un texto nuevo que firmar, sin «aquí mismo».
- **(B)** Construir el aviso a una persona. Es una pieza nueva y el canal no está decidido.
- **(C)** a0 tal cual, sin mecanismo. No lo recomiendo, por G1.

**Recomiendo (A).** Solo así lo que dice el texto lo cumple el grafo.

## 2 · «y no es una de las nuestras»: el grafo puede comprobarlo, pero hoy no lo hace

- **Qué pide el informe.** «Se dice solo si el grafo lo comprobó (#566). Sin eso, se quita esa frase». Tu orden dice que la pregunta previa «va igual». ¿Va con la frase o sin ella?
- **Lo que he medido.** La comprobación es barata. `qualitas_polizaemitida.serie_vehiculo` existe en las dos BD. En PROD: 86 pólizas, 86 con serie, 85 series distintas; 6 no miden 17 caracteres. El grafo ya lee esa tabla (`Resolve Session`, `Validate Emision Against DB`).

**Opciones:**
- **(A)** La frase **sin** comprobar. No la recomiendo: dos de los nueve 41 de PROD son pólizas nuestras, según el propio informe.
- **(B)** La pregunta **sin** la frase, y sin consulta.
- **(C)** Un marcador del grafo. El grafo busca el VIN en `qualitas_polizaemitida`:
  - 0 filas → la pregunta con la frase;
  - 1 fila o más → a0 (o a1/a2 cuando exista el #566).

  Es un trozo del #566 (solo «¿hay una nuestra?», sin estado de pago ni vigencia).

**Recomiendo (C)** si cabe en este punto; si no, (B).

## 3 · Sin enlace, b2 S y c2 S no disparan la pausa del #577, y G2 vuelve

- **Cómo funciona hoy la pausa.** En el sitio Main, `Pausa 577 Decide` solo pausa con dos condiciones: la marca `emision_bloqueada` (está, porque hubo 41) **y** el enlace del número de atención humana en el texto.
- **El problema.** b2 S y c2 S no llevan enlace, y a0 tampoco si se queda sin él. En los tres casos, `checkpoint_followups` seguiría mandando «¿Seguimos con la emisión de tu póliza?» a un cliente al que no podemos emitir. Es exactamente G2: `waq_3639` y `waq_3744`.
- **Lo que propongo.** Ampliar `Decide` (Main) con una tercera condición, para que pause con la marca y además el texto firmado de b2 S, c2 S o a0. Se reconocerían por su frase fija:
  - «no me deja emitir» (b2 S y c2 S);
  - «ya eres cliente» (a0).

  Va en el mismo import, porque la pieza que protege va primero o junto a la que actúa. Toca un nodo del #577; el resto de la cadena no cambia.
- **Lo que pregunto.** ¿Entra en el #543 S, o lo abro aparte?

Agente: Agente n8n · A
