# Inventario — SESIÓN A · `#593` y `#475` a PROD (dos viajes), antes del PUT

**De:** Agente n8n · A · **Para:** Arquitecto · **16 oct 2026**
**Orden:** `Agente-n8n:handoffs/2026-10-16-A-orden-prod-593-475.md` + adenda 1.
**Base medida:** PROD **`a1f22200-be2d-4db3-baf8-0aa92f918c5e`** (hoy, por API). Es la que fija la adenda 1.
**Cómo lo he medido:** cada candidato es el PROD vivo con su script de cambio aplicado encima, en local (nada escrito):
- viaje 1: `scripts/593/cambio_593.py`;
- viaje 2: `scripts/475/cambio_475.py`, aplicado sobre el candidato del 1.

No se copia nada de STG. **Sin `connections` cambiadas ni nodos nuevos o quitados** en ninguno de los dos.

## Dependencias: ¿algo que solo exista en STG?

**Ninguna.** Lo he comprobado en el vivo `a1f22200`.

- **`#593`.** `Parse VIN Extraction` de PROD ya tiene las variables que usa la nota:
  - `esTarjeta581` y `topeTarjeta581` (`#581`);
  - `WMI_MARCA`, `plausibleYears`, `yearCheck` y `wmiCheck` (canon VIN v2, `#477`/`#488`);
  - `vinConfidence` y `original.vehiculo`.

  El ancla del prompt es la viñeta del pie de foto del `#476`, que está en PROD.
- **`#475`.** Las anclas existen y aplican **exactamente una vez** en PROD:
  - `Detect Typed VIN`: el código viejo, idéntico;
  - `Check Typed VIN`: el *patch* y el `return`;
  - `Inject Serie Note`: el bloque del `[SERIE_SOSPECHOSA]`;
  - `Save Group2 Progress`: el `aviso_serie` del `#472`, con `src.provided`;
  - prompt: la frase «ese es el único momento en que el formato está comprobado de verdad.», del `#475` anterior.

  `Detect Typed VIN` lee `sessionData.capturedData` de `Merge Session Data`, que en PROD existe (lo usa el `#418`).

## Viaje 1 · `#593`

| Nodo | Hoja | Tamaño | Delta | Issue |
|---|---|---|---|---|
| `Parse VIN Extraction` | `jsCode` | 10.678 → 13.110 car. | +29 líneas, −0 | `#593` |
| `AI Agent` | `systemMessage` | 90.715 → 91.000 car. | +3 líneas, −0 | `#593` |

**Qué añade en `Parse VIN Extraction`:**
- al principio, la copia literal de `nota593.js`;
- antes del `return`, el bloque que añade `[SERIE_FOTO_NO_CUADRA] marca=…, año=…` al `chatInput` de la tarjeta. Solo se dispara con confianza alta, el año o el WMI en `fail` y la marca del WMI conocida.

`vinValid` no cambia: la serie no se propone ni se guarda.

**Hunk del systemMessage** (después de la viñeta «pendiente=nada…» del bloque `[FOTO_VIN]`, delante de la del pie de foto):
```
+- Si junto al [FOTO_VIN] aparece «[SERIE_FOTO_NO_CUADRA]», el sistema leyó la serie de la tarjeta pero es de otro vehículo distinto
+  al cotizado: el marcador es interno (no lo cites); responde con el texto que trae, copiado exacto, y NO guardes esa serie ni
+  digas que ya la tienes.
```
`#593` · único hunk del prompt en este viaje.

## Viaje 2 · `#475` (sobre el PROD que deje el viaje 1)

| Nodo | Hoja | Tamaño | Delta | Issue |
|---|---|---|---|---|
| `Detect Typed VIN` | `jsCode` | 292 → 4.186 car. | +49, −2 | `#475` |
| `Check Typed VIN` | `jsCode` | 6.178 → 6.738 car. | +6, −1 | `#475` |
| `Inject Serie Note` | `jsCode` | 969 → 1.547 car. | +9, −2 | `#475` |
| `Save Group2 Progress` | `query` | 3.780 → 4.725 car. | +9, −1 | `#475` |
| `AI Agent` | `systemMessage` | 91.000 → 91.397 car. | +1, −1 (una línea larga reescrita) | `#475` |

**Lo que hace cada nodo:**
- **`Detect Typed VIN`:** pasa del regex de 17 caracteres válidos a `detectaSerie475`, en copia literal.
  - **17 válidos:** igual que hoy.
  - **17 con O o I:** se normaliza y queda pendiente.
  - **«sí» con una serie pendiente:** se confirma.
  - **15, 16, 18 o 19 caracteres:** la nota de longitud.

  Lleva **los textos derivados aprobados por Alberto**: una I, «la he cambiado por un uno»; varias letras O/I.
- **`Check Typed VIN`:** con la serie normalizada, el *patch* guarda `serie_normalizada_pendiente` y no `serie_tecleada`; al confirmar, o si llega otra serie, la pendiente se borra.
- **`Inject Serie Note`:** el marcador `[SERIE_475]`.
- **`Save Group2 Progress`:** `aviso_serie` con el motivo real (letra I/O/Q; longitud distinta de 17). Si no es ninguno de los dos, el de procedencia de siempre.

**Hunk del systemMessage** (la línea «**Cuando el cliente escriba un número de serie:** …», al final de la frase «…ese es el único momento en que el formato está comprobado de verdad.»), se añade:
```
+ Hay una tercera excepción, del sistema: si te llega el marcador `[SERIE_475]`, haz exactamente lo que dice (es interno: no lo
+ repitas ni lo cites). Y NUNCA digas «ya tengo tu número de serie», «ya guardé tu serie» ni nada equivalente si `save_group2_progress`
+ no la devolvió guardada en este turno (`grupo2.serie` con valor y sin `aviso_serie`); si trae `aviso_serie`, dale al cliente ese motivo.
```
`#475` · único hunk del prompt en este viaje.

## Lo que NO viaja
Nada de lo que en STG va junto a estos nodos o al prompt:
- `#486`, `#596`, `#543` S, `#608`, `#609`;
- la emisión determinista;
- `URL Fidelity Guard`;
- etc.

El delta del prompt en cada viaje es **solo** el hunk de su issue: lo he medido con un diff completo del systemMessage, PROD contra el candidato.

## Plan del PUT (cuando lo verifiques)

Para cada viaje:
1. respaldo del vivo;
2. comprobar la base (`a1f22200` para el 1, el `versionId` que deje el 1 para el 2);
3. tu SÍ en mi sesión por boca de Alberto;
4. PUT;
5. diff contra el respaldo (solo estos nodos y estas hojas), `connections` idénticas, activo;
6. sync del espejo;
7. informe.

Agente: Agente n8n · A
