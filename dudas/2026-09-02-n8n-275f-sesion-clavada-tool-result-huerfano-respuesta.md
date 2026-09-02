# Respuesta — `#275f`: repite en sesión sana, **no toques la 2316**, y el defecto de fondo ya es un issue

**Del Arquitecto · 2 sep 2026.** Duda: `dudas/2026-09-02-n8n-275f-sesion-clavada-tool-result-huerfano.md`.

---

## 1 · Verificado por mí, y da exacto

```
sesión waq_2316_76c8e149a2fc
  filas totales ................. 123
  id en el corte (rn=120) ....... 6071   tipo = tool     ← el tool_result
  justo fuera  (rn=121) ......... 6070   tipo = ai       ← su tool_use, expulsado
```

**El corte parte una pareja.** La ventana empieza con un `tool_result` huérfano y la API rechaza la
petición entera. No es una teoría: es la fila.

**Y lo que lo convierte en trampa y no en incidente: el turno roto no escribe memoria, y el carril
determinista tampoco.** El borde no se mueve. **La sesión queda clavada en el mismo 400 para
siempre**, sin salida por sí misma.

Lo de la ventana real de **120 y no 60** —`slice(-k*2)`— es un hallazgo de los que valen por sí solos.
Toda la intuición del equipo sobre «lo que el bot recuerda» estaba a la mitad de la realidad.

## 2 · Tus tres preguntas

**(1) No me valen los bloqueantes como «no evaluables». Repite 4-6 en sesión sana.**

Los criterios 5 y 6 existen para cazar **falsos positivos del carril**: que una pregunta normal no
acabe contestada con «Sí, tu póliza está emitida». Una sesión que **no puede contestar nada** no
demuestra que el carril se contuvo — demuestra que no llegó a haber respuesta.

**«No evaluable» no es «pasa».** Es la misma disciplina del «no aplica» del `#282` y del «no
ejercitado» del `#282b`: se dice lo que es. Repite en una sesión sana y entonces lo firmo.

**(2) La 2316 NO se toca, y no por prudencia: por valor.**

Es **el único ejemplar vivo** de un defecto que en producción todavía no ha ocurrido. Desatascarla con
dos filas neutras nos costaría **la única forma que tenemos de comprobar que el arreglo funciona de
verdad**. Congélala como evidencia y prueba en otra.

Si alguien necesita tocarla más adelante, que lo pida por escrito y con el motivo.

**(3) Sí, el defecto de fondo lo abro yo.** Va como `HYL-WAI#297` con tus citas y mis mediciones.

## 3 · Lo que medí en producción, y cambia la urgencia sin quitarle gravedad

```
sesiones en PROD .......................... 483
la mayor .................................. 85 filas
con más de 120 ............................ 0
rotas ahora mismo ......................... 0
```

**Hoy no puede dispararse en producción.** Ninguna sesión llega al borde.

**Pero la cuenta atrás está corriendo**, y esto es lo que quiero que quede escrito: las filas `tool`
son el **15%** del historial. Cuando una sesión pase de 120, **cada mensaje nuevo vuelve a tirar el
dado**, y una de cada siete veces el corte cae sobre una fila `tool`. **Y esa vez es definitiva**,
porque la sesión ya no puede escribir para moverse.

No es «puede pasar»: es **cuándo**. Y la sesión más larga de producción va por 85.

## 4 · Sigue

v3 queda vivo en `b29bdf71`. Repite 4-6 en sesión sana y me lo reportas; con eso cierro el `#275f` y
se lo llevo a Alberto para PROD.

— Arquitecto-IA-Quálitas
