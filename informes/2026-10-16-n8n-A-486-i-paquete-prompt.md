# Informe — SESIÓN A · (i) `#486`: paquete de prompt (puntos 3, 4, 6, 8, 9, 10, 11 y 14)

**De:** Agente n8n · A · **Para:** Arquitecto · **16 oct 2026**
**Orden:** `Agente-n8n:handoffs/2026-10-14-A-firmas-orden-prod-591-y-cola.md`, fila i.
**Puntos:** los del juicio `informes/2026-10-11-arquitecto-486-coherencia-prompt-juicio.md`.
**Autorización de Alberto (14 oct):** «La limpieza del prompt (#486): OK».
**PROD:** nada. El systemMessage necesita su firma y una orden de viaje.

## Import

| Workflow STG | Antes → después | Nodos |
|---|---|---|
| Bot `dNqtM20ij6ecZYAX` | `676069a3` → **`2cf93cb6`** | solo `AI Agent` · `systemMessage` (95.702 → 95.665 caracteres) |

- **Verificación:** hojas y `connections` iguales al candidato; activo; export sincronizado a `stg`.
- **Respaldo:** `backups/486/`.
- **Código:** `scripts/486/cambio_486.py` (`8896ce3d` y siguientes). Cada hunk se aplica exactamente una vez, con un *assert*.
- **El `RAG IA Agent` no lleva ninguno de estos literales:** lo medí con un `grep` de cada ancla sobre su prompt. No se toca.

## Delta por hunk

**14 hunks en 8 puntos.** Las líneas son del STG de antes (`676069a3`); en PROD (`c31d2687`) son otras.

| Punto | L (STG) | Antes | Después |
|---|---|---|---|
| **3** checkpoint | 418 | «pedir. Continúa por donde ibas según el checkpoint del [CTX:].» | «pedir.» |
| **4** IDs | 265 | «1. Nunca muestres números de ID de cotización o póliza al usuario» | «1. Nunca muestres IDs internos (qid, ids de base de datos) al usuario» |
| **6** validate | 738-739 | `"email": "...",` y `"telefono": "...",` en el ejemplo | fuera (la nota de L762 ya decía que NO se incluyen) |
| **8** A1 | 327 | «…por "cobertura", "forma de pago", "otra opción" u "otros precios".» | «…por "cobertura", "otra opción" u "otros precios".» |
| **9** U2 | 839 | «*[VEHÍCULO]*, Cobertura Amplia, [FORMA_PAGO]…» | «*[VEHÍCULO]*, [COBERTURA], [FORMA_PAGO]…» |
| **9** U1 | 840 | ídem | ídem |
| **10** placas | 811 | «Placas: [PLACAS si proporcionadas]» | «Placas: [PLACAS]» |
| **11** RFC | 459 | «Tu RFC es [RFC_CALCULADO][HOMOCLAVE]…» | «Tu RFC es [RFC_BASE][HOMOCLAVE]…» ([RFC_BASE] = la rfc_base que da el sistema) |
| **11** | 460 | «…que el RFC calculado es incorrecto…» | «…que ese RFC es incorrecto…» |
| **11** | 702 | «rfc=<RFC base calculado>» | «rfc=<la rfc_base que da el sistema>» |
| **11** | 735 | «Sin factura: RFC base calculado = 10 chars» | «Sin factura: la rfc_base que da el sistema = 10 chars» |
| **11** | 755 | «Si requiere factura: RFC calculado + homoclave… Si NO…: RFC base automático…» | «…la rfc_base que da el sistema + homoclave… Si NO…: la rfc_base que da el sistema…» |
| **11** | 818 | «…el RFC fue calculado internamente y NUNCA debe aparecer…» | «…el RFC es la rfc_base que da el sistema y NUNCA debe aparecer…» |
| **14** pendiente | 544 | «(datos personales, domicilio, RFC, factura, confirmación del…» | «(… RFC, si quiere factura, confirmación del…» (el literal de `derivarPendiente`) |

**Fuera del paquete, como dice el juicio:**
- el **12**, que necesita un literal firmado;
- el **15**, duplicados;
- el **1**, el **2** y el **5**, que van en el grafo y en textos firmados;
- el **13** y el **17**, que tienen issue propio;
- el **16**, uno a uno.

## Aceptación: arnés N=20, sesiones limpias, cambio contra control (el vivo `676069a3` sin el paquete)

Script: `scripts/486/aceptacion-486-stg.py`. Sin envíos. En la emisión, el Guard está simulado con la póliza que ya existe en la 3005.

| Comportamiento | Qué se comprueba | Cambio N=20 | Control N=20 |
|---|---|---|---|
| **R** RFC sin factura + resumen (2345) | «No» a la factura → `grupo2.rfc = PAGJ921203` (la base, 10 caracteres), `requiere_factura=NO`; el resumen con «Placas: ABC1234» y **sin** el RFC | 20/20 | 20/20 |
| **A** A1 (2345) | «Sí» tras la cotización → **no** ofrece cambiar de cobertura (0/20); se mide si ofrece otra forma de pago: 0/20 | 20/20 | 20/20 |
| **U** U2 con Limitada (5515, sin PDF) | «¿Me mandas mi cotización en PDF?» → «Cobertura Limitada», nunca «Amplia». **Ejercitados 20/20** (U2 de verdad, no el PDF del grafo) | 20/20 | 20/20 |
| **E** Emisión (3005) | «emitida exitosamente» + el número de póliza (el mensaje determinista de la (c)) | 20/20 | 20/20 |

**Regresión sobre el vivo `2cf93cb6`:** 8/8 (N=2 por comportamiento).

**Cómo leo el resultado: equivalencia, que es lo que pide un paquete de redacción.** El control ya hacía lo correcto en los cuatro comportamientos. En particular, U2 ya escribía «Cobertura Limitada» con la Limitada, aunque el prompt dijera «Cobertura Amplia» fijo. El paquete quita esas contradicciones del texto sin cambiar lo que pasa. **No hay un fallo que el cambio arregle y que el control enseñe:** los ocho puntos eran incoherencias latentes, no defectos que se reproduzcan.

## No ejercitado
- **3 (checkpoint):** su efecto sería sobre la continuación tras un cambio de cotización por descuento, que el arnés no recorre. Es carril de B.
- **4 (IDs):** sin un turno en el que el modelo decida si muestra un número de póliza. El de la emisión lo compone el grafo.
- **14 (pendiente):** sin un turno con imagen ilegible y `pendiente=si quiere factura`.

Agente: Agente n8n · A
