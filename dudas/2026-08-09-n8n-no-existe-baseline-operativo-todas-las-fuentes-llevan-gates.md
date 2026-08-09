# Duda — Agente-n8n → Arquitecto · **no existe un «baseline operativo» que restaurar**: todas las fuentes actuales llevan los gates denegando

**Fecha:** 2026-08-09 · Amplía el informe `Agente-n8n:main@1a88a98` (traza del Quick Reply).
**Estado:** nada ejecutado desde ese informe. Solo lecturas locales. **Cero escrituras.**

STG está `active=true` en los cuatro workflows **y deniega todo inbound**. Antes de proponer nada fui
a inventariar **todas** las fuentes disponibles, porque la de anoche resultó no ser lo que decía ser
y no quiero repetir el error con otra.

## 1. El inventario completo — las cuatro fuentes, con lo que importa de cada una

| Fuente | Main | `C1 Gate` | Concedidos | Sirve como bot operativo |
|---|---|---|---|---|
| **`workflows/s1/main-candidato.json`** (lo vivo ahora) | 154 nodos | **25** | **0 de 25** | **no** |
| **`workflows/*_stg.json`** (el «retrato pre-A2») | 153 nodos | **25** | **0 de 25** | **no** |
| `s1_stg_f1f4` (perfil temporal, ya retirado) | 160 nodos | — | — | no aplica |
| **`backups/n8n-stg/`** (13 jul) | **66 nodos** | **0** | — | sin gates, **pero obsoleto** |

Dos cosas que esto tira abajo:

- **Mi propia propuesta de ayer no sirve.** Sugerí mirar `*_stg.json` con otros ojos por ser anterior
  a A2. Lo he comprobado: tiene **los mismos 25 gates, igual de no concedidos**, y el
  `WhatsApp Message Trigger` cableado al gate **exactamente igual** que el candidato. La diferencia
  entre ambos es de un nodo, no de gates. **Retíralo de las opciones.**
- **El único sin gates es de otra época.** El backup del 13 jul lleva **66 nodos** frente a 154: le
  faltan unos dos meses de trabajo. Restaurarlo sería tirar Metepec, atención humana, la entrega por
  quick reply, el guardrail de emisión y todo lo demás. No es una opción, es una pérdida.

## 2. Y hay una observación que lo confirma sin depender de mi lectura de ficheros

**No hay ni una sola ejecución en n8n STG entre el 30 de julio y hoy.** La última era `id=873` del
30 jul; la siguiente es la `874` de hoy, la del Quick Reply, que murió en el gate.

Si el bot hubiera estado operativo en algún momento de agosto, habría dejado ejecuciones. No las hay.
Eso encaja con lo de arriba: **el bot de STG lleva ~10 días sin poder procesar inbound**, y no es algo
que rompiéramos anoche — anoche solo lo pusimos `active=true`, que es lo que ha hecho visible el
problema al llegar por fin un evento.

## 3. La duda

**No existe una fuente que sea a la vez actual y operativa.** Así que «restaurar el baseline
operativo» no es una tarea ejecutable tal como está enunciada: no hay tal cosa que restaurar.

Lo que veo, y ninguna la doy por buena:

- **(a) Conceder las capacidades en los gates del candidato** —poner `c1CapacidadConcedida` donde
  corresponda—. Es lo único que devuelve un bot actual y funcionando. **Pero es modificar contenido
  acreditado y decidir qué capacidades se conceden, que es materia de contrato y de liderazgo, no
  mía.** Y no sé si el diseño previsto era que STG corriera con gates concedidos o si los gates son
  transitorios de C1 y deben retirarse.
- **(b) Reconstruir un baseline sin gates** desde el candidato, quitando los 25 nodos y recableando.
  Es fabricar contenido nuevo, con todo lo que eso implica. Lo menciono para descartarlo
  explícitamente, no para proponerlo.
- **(c) Desactivar STG mientras se decide.** Un bot `active=true` que deniega todo es peor que uno
  inactivo: **parece** que funciona. Si alguien prueba, verá silencio y sacará la conclusión
  equivocada. Es una escritura mínima y reversible, y la haría con una orden.

**Mi recomendación:** decidir (a) o su alternativa de diseño con liderazgo, y mientras tanto (c) —o
dejarlo activo pero **con todos avisados** de que el ingress deniega—.

## 4. Lo que necesito para no repetir el error de anoche

Anoche verifiqué que lo restaurado era **fiel a la fuente**, y lo era. No verifiqué que **la fuente
fuera operativa**. Para la próxima, sea cual sea la elección, propongo que la acreditación incluya
**una comprobación funcional mínima y no solo estructural** — por ejemplo, que el
`WhatsApp Message Trigger` no termine en un gate sin conceder. Es barato y habría cazado esto anoche.

Sin secretos ni PII. Los nombres de nodo y los conteos citados salen de ficheros versionados en el
repo.
