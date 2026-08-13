# Informe — fuga de credencial de STG en Multicotización: **arreglada en PROD y en origen**

**13 ago 2026 · Agente n8n.** Handoff `2026-08-13-fuga-credencial-stg-en-multicotizacion-PROD.md`.
Ejecutado con orden de Alberto, confirmada en el chat. **No acredito yo.**

## 1 · El diff aplicado — exactamente lo que pediste

Estado de partida verificado antes de escribir: `versionId 9c2de104-…`, `updatedAt 2026-08-13T14:59:50.813Z`,
119 nodos, activo. **Coincide con el tuyo.**

Y el censo completo de credenciales del bot, todos los tipos, para no dar por bueno tu alcance sin medirlo:

```
20x postgres            Postgres account (FbodkhT9DijVcqpB)
 6x whatsAppApi         WhatsApp Send Message Hylant Account
 5x anthropicApi        Anthropic Hylant Account
 3x postgres            Postgres STG (5wlLe3gD07CLIM7U)     <<< las tres, ni una mas
 2x httpHeaderAuth      Django N8N_TOKEN PROD
 2x httpHeaderAuth      WA Media Access PROD
 2x openAiApi           OpenAI KB Embeddings PROD
 1x whatsAppTriggerApi  WhatsApp Hylant Account
```

**El `PUT` demuestra su alcance antes de enviarse.** No me fío de haber construido bien el cuerpo: lo
comparo con el vivo y aborto si aparece **una sola** diferencia fuera de las credenciales.

```
=== DIFERENCIAS del cuerpo contra el vivo: 6 ===
  .nodes[114].credentials.postgres.id    "5wlLe3gD07CLIM7U" -> "FbodkhT9DijVcqpB"
  .nodes[114].credentials.postgres.name  "Postgres STG"     -> "Postgres account"
  .nodes[115]. …idem…
  .nodes[116]. …idem…
  -> las 6 son id+name de las 3 credenciales. Ni una coma en otro sitio ✓
```

| | Resultado |
|---|---|
| `versionId` | `9c2de104-…` → **`def23539-43fc-437d-a888-9eea49585ee9`** |
| nodos | **119** · `active = true` |
| `Listar Cotizaciones` / `Cambiar Cotizacion` / `Limpiar Turno De Cambio` | **`Postgres account` (`FbodkhT9DijVcqpB`)** |
| credenciales de staging en el bot | **cero** |
| barrido de los **6** workflows de PROD | **todos limpios** |

Verificado además que el resultado no difiere de lo enviado, salvo el `versionId`.

## 2 · El guard, extendido — y con la parte que me toca dicha entera

Dices que el hueco lo acotaste tú. Lo acepto, pero **no me cubre**, y prefiero dejarlo claro:
`promover-atencion-humana.py` **sí** sustituye credenciales por un mapa, y
`promover-multicotizacion.py` **no lo hacía** — copiaba los nodos de STG tal cual. **Construí la
sustitución en un guion y la olvidé en el otro.** El guard fue la segunda red que tampoco estaba; la
primera era mía y faltaba.

Arreglado en los dos sitios:

1. **En origen:** `promover-multicotizacion.py` sustituye credenciales por mapa y **aborta** si aparece
   una de staging sin equivalente declarado.
2. **El guard:** `fuga_de_staging()` pasa a mirar **tres** formas en los tres guiones — nodo con nombre
   de STG · referencia `$('…STG…')` · **credencial por nombre O POR ID**. El id importa porque un nombre
   se puede editar en la interfaz y el id no.

**Probado en las dos direcciones**, que es lo que le faltaba a la versión anterior: detecta **las tres**
fugas contra el estado roto de esta mañana, y da **limpio** contra el estado actual.

Una precisión sobre «corregir el JSON de origen»: **el export de STG debe seguir llevando `Postgres
STG`** — es su credencial correcta. Lo que estaba mal no era el origen, era que la promoción no
sustituía. Si hubiera «corregido el origen» habría roto STG.

## 3 · Corrijo lo que escribí aquí: **no está «dormida esperando `dual`»**

Puse que Multicotización quedaba dormida hasta que Conversation ID pasara a `dual`. **Lo retiro**: lo
copié de la primera versión de tu handoff y **no lo comprobé**, y tú lo corregiste después. Propagar una
afirmación ajena sin verificarla es la misma forma de error del día — con el agravante de que la
comprobación estaba a un `SELECT` de distancia y yo tengo acceso.

**Medido ahora por mí contra la base de PROD:**

```
total_sesiones                  1084
telefonos_distintos             1084     -> 0 telefonos con mas de una sesion
session_id tipo waq_...            0
ultima sesion creada (UTC)      2026-08-13 14:57:33
creadas despues de las 17:39Z      0
```

Coincide con tu corrección: la lista ofrecía una sola opción **porque no ha entrado ningún lead desde el
cambio de modo**, no porque el modo fuera el viejo.

*(Lo que no puedo verificar: que el modo sea `dual`, que es variable de Django. Tomo tu lectura. Lo mío
es el hecho de que ninguna sesión se ha creado desde las 14:57 UTC.)*

Actualizada en mi documento la prueba de cierre: **dos leads nuevos desde la landing con el mismo
teléfono** y el bot listando **dos** cotizaciones — con tu criterio para no perseguir fantasmas: si sale
una sola, mirar la fecha de creación de las sesiones antes de tocar nada.

## 4 · Y lo que me llevo

Es el sexto error mío del día y el primero que **llegó a producción y lo notó un cliente**. Los cinco
anteriores los cacé yo antes de que mordieran; este lo cazaste tú, con el error literal en la tabla.

La forma es la misma de siempre —una comprobación más estrecha que su criterio— pero con una diferencia
que no quiero suavizar: **no fue un hueco de análisis, fue una inconsistencia entre dos guiones míos que
hacían el mismo trabajo.** La regla que saco: cuando dos guiones comparten un paso, o comparten el
código o comparten el test. Dos copias del mismo criterio divergen — llevo todo el día diciéndolo de las
migraciones y me pasó en mis propios scripts.
