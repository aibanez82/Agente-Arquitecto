# Autonomía del Arquitecto mientras Alberto está fuera — 7 oct 2026

**Fuente:** sesión del Arquitecto, 7 oct. El Arquitecto propuso un plan para cerrar los issues de Alberto y le
hizo tres preguntas. Respuestas literales:

| Pregunta | Respuesta de Alberto |
|---|---|
| ¿Cierro yo los issues cuando aparezca la evidencia, sin consultarte, como hoy? | **«SI»** |
| ¿Puedo usar tu número (`525551074144`) para pruebas en STG mientras estás fuera? | **«SI»** |
| ¿Nada va a PROD hasta que vuelvas? | **«correcto. Nada más me haces un resumen: todo esto está pendiente de ir a PROD, necesito tu OK»** |

## Qué autoriza

1. **Cerrar issues** de HYL-WAI cuando la evidencia medida en vivo cumpla su criterio de cierre, con un comentario
   de evidencia, como se hizo el 7 oct.
2. **Usar `525551074144` como destinatario de pruebas en STG.** Las capturas se le piden al volver.
3. **Lanzar handoffs a STG** (regla vigente: a STG se llega sin preguntar) para los arreglos del plan, **de uno en
   uno**: el bot de STG es compartido.

## Qué NO autoriza

- **Nada a PROD.** Ni imports de n8n, ni cambios de datos, ni configuración. **Esto suspende, mientras dure la
  ausencia, la autorización permanente de promoción del 29 ago.** Al volver, el Arquitecto entrega un resumen con
  todo lo pendiente de PROD y Alberto da el OK.
- Textos o prompt: se preparan como propuesta exacta para su firma; no se aplican en PROD.

Agente: Arquitecto-IA-Insurmind
