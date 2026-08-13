# Duda — `main` ya no describe PROD, y el folio sigue roto (ahora sin ordinal)

**13 ago 2026 · Agente n8n · ninguna de las dos bloquea nada.** Las dos salen de las promociones de
hoy y de la ventana C (`#77`), y ninguna es mía de decidir.

Contexto: `handoffs/2026-08-13-VENTANA-C-informe-de-cierre.md` en `Agente-n8n@main` (`f8dfcbf`).

---

## 1 · `main` ya no describe PROD: 15 nodos de drift legítimo

Lo he medido nodo a nodo contra `origin/main`, no lo supongo:

| Baseline en `main` | Versionado | Vivo | Nodos que difieren |
|---|---|---|---|
| `WhatsApp Insurance Quotation Bot.json` | 113 nodos | **119** | **15** |
| `Retomar Conversacion.json` | 12 | 12 | **1** (`Normalize & Validate`) |
| `… - Payment Confirmation.json` | 5 | 5 | 0 |
| `Monitor Qualitas SIO PROD.json` | 19 | 19 | 0 |

Los 15 del bot, con su procedencia:

```
solo vivo   Cambiar Cotizacion · Listar Cotizaciones · Limpiar Turno De Cambio   (multicotización, hoy)
solo vivo   Prepare Resolution Context                                            (multicotización, hoy)
solo vivo   Human Takeover Guard · Save Human-Gated Message                       (atención humana, hoy)
cambia      Resolve Session · RAG IA Agent                                        (atención humana, hoy)
cambia      Send Agent Error Fallback · Send Generic Error Message
            Send Not Available Message                                            (atención humana, hoy)
cambia      Format Disambiguation Message                                         (#76, hoy)
cambia      Session Resolution · Merge Session Data · AI Agent                    (#77 ventana C, hoy)
```

**Todo es cambio acreditado de hoy, ninguno es un cambio a mano de nadie.** Pero mientras el baseline
no se actualice, `detect-drift.py` reporta drift en los dos destinos, y ahí está el problema real: un
detector que ladra por 15 nodos legítimos deja de servir para avisar del 16º, que sería el ilegítimo.
Es lo mismo que pasó con `#74`, por el otro lado.

**Pregunta 1: ¿re-exporto los dos baselines de `main` al estado vivo?** Es un `sync-workflow-export.py`
por workflow. No lo hago solo porque `main` es la rama que refleja «el estado limpio de PROD» y
sobrescribirla es declarar que lo de hoy es ese estado limpio — declaración tuya, no mía.

### 1-bis · Un hueco que es culpa mía, y lo digo aquí para que no se pierda

**`Atencion Humana` (`B5ihE5xHg8bjeesl`) está vivo en PROD, inactivo, sin baseline y fuera de
`TARGETS`.** Lo creé yo esta tarde y no actualicé la tabla en el mismo movimiento, que es exactamente
la regla que el propio fichero se puso tras el incidente de los destinos S1. Nadie lo vigila: si
alguien lo edita, ningún detector se entera.

Va con la pregunta 1 porque la respuesta manda sobre las dos: si se re-exporta, lo añado a `TARGETS`
con su baseline en el mismo commit.

*(Sigue vivo también `WhatsApp Insurance Quotation Bot copy`, inactivo, sin baseline y sin vigilancia.
Ya te lo reporté el 12 ago y sigue sin dueño. No hago nada con él.)*

## 2 · La selección por folio sigue rota, y ahora tampoco hay ordinal

En `#76` dejé escrito que PROD parseaba `/^[1-9][0-9]?$/` —solo ordinal— mientras el mensaje de
desambiguación ofrecía «o con el folio». La ventana C se llevó por delante **todo** ese parseo, porque
vivía dentro de la rama `matchCount > 1` que sustituí.

**Hoy no molesta:** no hay lista que contestar, así que no hay nada que parsear. `Format Disambiguation
Message` y `Disambiguation Router` están inertes.

**Cuándo sí molesta:** el día que alguien decida volver a preguntar —tu opción B, o cualquier otra
cosa que reviva el router—. Entonces saldría una lista que **nadie puede contestar**, ni con «2» ni
con «3495», porque el parseo ya no existe. La reversión de `#77` lo devuelve todo junto, pero un
revivir parcial no.

**Pregunta 2: ¿lo abro como issue propio en `qualitas-issues`, o lo dejo como nota dentro de `#77`?**
Lo propuse como issue el 12 ago y quedó sin abrir. Mi criterio: issue, con una línea que diga que copy
y parser van juntos o no van — es la clase de cabo que dentro de tres meses nadie recuerda que existe.
Pero los issues los abro yo sin pedir permiso solo cuando son bugs que encuentro trabajando, y esto es
más bien una condición de una decisión de producto que aún no está tomada. Por eso pregunto.

---

**Ninguna de las dos me bloquea.** Sigo con lo que no depende de ellas.
