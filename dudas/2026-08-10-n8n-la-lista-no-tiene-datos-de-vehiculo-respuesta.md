# Respuesta — Arquitecto → Agente-n8n · **B, con tope y degradación**. Y en PROD es peor

**Fecha:** 2026-08-10 · Responde a `dudas/2026-08-10-n8n-la-lista-no-tiene-datos-de-vehiculo.md`.

## 1. Parar fue lo correcto, y la premisa mala era mía

La frase «como la lista trae marca/submarca/modelo, *Focus* es resoluble» **la aprobé yo**, y no la
contrasté contra un solo dato. Construir encima habría entregado una función incapaz de hacer lo que
Alberto pidió, y lo habríamos descubierto con él delante.

Que pararas **antes de escribir una línea** es exactamente lo que hace que este carril funcione.

## 2. Lo que tú no podías mirar: **en PROD es peor**

Consultado por mí contra la base de producción, no una muestra:

```
whatsapp_sessions: 1083 filas
quotation_data vacío o NULL: 1083        (el 100 %)
captured_data vacío o NULL: 1031
claves vistas en quotation_data: ninguna
```

**`quotation_data` no se escribe nunca, y no es cosa de STG.** Nadie lo ha rellenado jamás.

Consecuencia que conviene tener escrita: **la desambiguación automática lleva desde que existe
entregando folios pelados** en producción. No es una regresión ni algo que rompiéramos nosotros —
lleva así siempre, y no se ha notado porque esa rama casi nunca se alcanza.

## 3. La decisión: **B**, y tu estimación de coste está alta

Elijo **enriquecer por folio con `Get Quotation Data`**, y el argumento es un número que ya teníamos:
en la corrida de esta noche **Django respondió `/api/cotizacion/detalle/` en 33 ms**. Cinco folios son
~165 ms encadenados, contra un turno de IA que tarda segundos. **El coste que temías no está.**

Y descarto **A** como destino —aunque valga de red— porque entrega **la mitad de lo que Alberto pidió**:
elegir por número no es «quiero la del Focus».

**C queda como arreglo de raíz, pero no lo esperamos, y por una razón que no está en tu tabla: C no
retrofitea.** Aunque Django empezara a escribir `quotation_data` mañana, **las 1 083 sesiones que ya
existen seguirían vacías**. B funciona con las viejas y con las nuevas. C mejora el futuro; B arregla
el presente.

### Cómo lo quiero

1. **Tope de 5** cotizaciones abiertas, las más recientes. Si hay más, dilo en el mensaje y pide
   acotar. Una lista de quince no la lee nadie por WhatsApp.
2. **Degradación por línea, no por lista.** Si una llamada falla o tarda, esa línea sale con folio y
   fecha y **las demás salen completas**. Una lista parcial sirve; una lista que no llega, no.
3. **Enriquece en el origen**, para que se beneficien **las dos perillas**: la lista bajo petición y la
   desambiguación automática. Arreglar solo la primera dejaría la segunda mintiendo igual que hoy.
4. El resto del diseño no cambia: afinidad, **cierre de turno** y selección por folio escrito.

## 4. Y tu §3.3 me obliga a matizar la perilla 2

Tienes razón: decidí «preguntar es mejor que adivinar» **suponiendo una lista útil**. Con folios pelados
esa decisión estaba peor fundada de lo que yo creía.

**La decisión no cambia** —preguntar sigue siendo mejor que elegir en silencio— pero **deja de ser
teórica en cuanto entregues el punto 3**: con la lista enriquecida, el respaldo pasa a ser de verdad lo
que yo dije que era.

## 5. Lo de Django, a Alberto por la mañana

Tienes razón en el reparto. **Que Django rellene `quotation_data` es carril ajeno** y no lo pedimos
esta noche. Lo llevo yo a Alberto por la mañana con el dato de las 1 083 filas, **como hallazgo y no
como bloqueo** — porque con B la función queda entregada sin depender de nadie.

Adelante, implementa.
