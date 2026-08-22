# Petición del Arquitecto — diagnóstico del embudo completo, para priorizar desarrollo

**De:** Arquitecto · **Para:** Agente Mejoras Conversación · **Fecha:** 21 ago 2026

## Para qué es

Tenemos más trabajo identificado del que cabe en el trimestre y lo estamos ordenando por intuición.
Este informe es el que decide **en qué orden desarrollamos**. Necesito saber dónde se pierde el
dinero de verdad, en todo el embudo — no en el trozo del que veníamos hablando.

Tu spec de rescate de cobro me la quedo y abriré el issue con ella. Pero al medir el embudo entero
resulta que **el cobro es el cubo más pequeño**, y sería un error empezar por ahí solo porque es el
que miramos primero.

---

## El embudo medido, para que no lo repitas de cero

PROD, 9 jun → 21 ago, **1.089 sesiones**. Verificado por mí contra Postgres:

| Etapa | Sesiones | Lectura |
|---|---|---|
| Nunca hubo mensaje humano | **752** | el lead no contestó al primer WhatsApp; el bot ni entra |
| El cliente escribió y no pasó de las primeras vueltas | **190** | de ellas **67 ya habían confirmado cobertura**, 5 dieron VIN, **0 dieron datos personales** |
| Captura de datos | 75 | |
| Resumen / emisión | 14 | |
| **Póliza emitida, sin pagar** | **20** | tu informe de rescate de cobro |
| **Cerradas** | **38** | |

**De 337 personas que llegaron a escribir, se cierran 38. Un 11%.**

Reparto de los que escribieron, por aguante: **93 escribieron un solo mensaje y se fueron** · 116
escribieron 2-3 · 86 escribieron 4-9 · 50 escribieron 10 o más.

Y el bot **siempre contestó**: cero sesiones sin respuesta del bot. Cuando alguien se va, no es
porque no le respondieran.

---

## ⚠️ Método: no te fíes de `conversation_phase`

**Ese campo miente y lo he comprobado hoy.** De las 190 sesiones marcadas `greeting`, **67 habían
confirmado cobertura** según el texto real de la conversación. Es el bug `#82`: la fase se queda
clavada y devuelve un valor plausible en vez de fallar.

**Construye el embudo sobre `n8n_chat_histories`**, con los detectores de texto verificados:

| Hito | Detector |
|---|---|
| el cliente respondió | existe mensaje `type='human'` |
| confirmó cobertura | AI dijo `"continuamos con"` + `"cobertura"` (ILIKE) |
| dio datos personales | AI dijo `"Nombre:"` |
| dio VIN / placas | AI dijo `"Número de serie:"` o `"Placas"` |
| dio domicilio | AI dijo `"*Domicilio:*"` |
| póliza emitida | AI dijo `"emitida exitosamente"` |

Y **una limitación que debes respetar** (`HYL-WAI#183`): esa tabla guarda el **texto** del agente,
pero de cada turno solo persiste el **último** intercambio de tool. Los detectores de arriba son
seguros porque leen texto. **Cualquier cosa que quieras contar sobre llamadas a herramientas verá una
fracción** — no saques conclusiones de ahí.

---

## Lo que te pido, cubo por cubo

Trabaja de mayor a menor. Si el tiempo no llega a todo, **prefiero los tres primeros a fondo que los
cinco por encima**.

### 1. Los 190 que escribieron y se cayeron pronto — y sobre todo los 67

Este es el cubo grande de los que sí quisieron algo. **67 llegaron a elegir cobertura y ninguno dio
datos personales.** Ahí hay un muro concreto.

- **¿Cuál es el último mensaje del bot antes del silencio?** Agrupa por patrón. Si hay una frase que
  mata conversaciones, quiero verla literal y saber cuántas veces mató.
- **¿Qué pidió el bot justo después de la cobertura?** Sospecho que ahí está el muro: pedir datos
  personales de golpe, o pedir el VIN antes de haber dado valor.
- **Los 93 que escribieron una sola vez y se fueron**: ¿qué escribieron? ¿preguntaban precio?
  ¿se equivocaron de número? ¿el bot les contestó algo que no venía a cuento?
- ¿Hay abandono por **tiempo de respuesta** del bot, o por **longitud** del mensaje?

### 2. Los 752 que nunca contestaron

No hay conversación que leer, pero sí hay algo que mirar y es tuyo: **el primer mensaje**, el que
manda Django directo por la API de Meta.

- Léelo. ¿Qué dice exactamente? ¿pide algo? ¿da algo? ¿parece spam?
- ¿Hay diferencia de respuesta según **hora** o **día** de envío?
- ¿Hay señal de que no llegara —bloqueo de Meta, número mal formado— frente a que llegara y no
  interesara? Si no se puede distinguir con lo que hay, **dilo**: eso ya es un hallazgo.

**Es el 69% del embudo.** Aunque el margen de mejora fuera pequeño en porcentaje, en volumen es el
cubo más grande que existe.

### 3. Rescate de cobro — los 20, ampliando tu informe

Tu spec ya tiene los seis patrones. Lo que me falta para ordenar la implementación:

- **Cuántos de los 20 volvieron a escribir** y cuántos callaron desde la entrega del link. Si mandan
  los mudos, el recordatorio proactivo va primero y las herramientas después.
- **El reparto por fricción**: link olvidado · verificar pago · domiciliación · métodos alternos
  (OXXO, transferencia) · error en el portal · pedir agente · algo que no sea pago.
- **Qué pasó tras cada derivación a agente**: ¿alguien recuperó al cliente, o murieron todas? Yo
  propuse derivar como salida segura y tu evidencia sugiere que hoy es un callejón — necesito
  saberlo antes de volver a usarlo.
- **El dinero mejor acotado**: dices ~$124.700 MXN citados en 9 de 20. Si en las otras 11 se puede
  sacar el importe de la póliza emitida en vez de lo citado en el chat, ese número real es el
  argumento más fuerte que tendremos.

### 4. Los 75 en captura de datos y los 14 de resumen/emisión

Cubos pequeños pero **carísimos por unidad**: es gente que ya dio marca, modelo y datos. Perder a uno
aquí cuesta mucho más que perder a uno en el saludo.

- ¿Se caen en un **campo concreto**? (VIN, domicilio, RFC, CP)
- ¿Hay **fallo técnico** disfrazado de abandono — el bot pidió algo, el cliente lo dio, y la
  conversación murió porque algo reventó por detrás?

### 5. Lo transversal, si aparece

Tono, longitud, repeticiones, el bot pidiendo dos veces lo mismo, respuestas que no vienen a cuento.
**Solo lo que veas de verdad**, no un repaso de estilo.

---

## Filtro imprescindible: no reportes como abierto lo que ya arreglamos

Vas a leer diez semanas de PROD. **Parte de lo que ahí se ve mal ya está corregido** — en PROD o en
STG. Si lo reportas como problema vivo, mandamos a alguien a arreglar algo hecho.

**Clasifica cada hallazgo:**

- **(A) Vivo en PROD hoy.** Esto es lo que quiero.
- **(B) Arreglado en STG, sin promover.** El cliente de PROD aún lo sufre, pero el trabajo existe:
  va al inventario de promoción, no a un issue nuevo.
- **(C) Ya arreglado en PROD después de esa conversación.** Histórico: menciónalo y no lo cuentes.

| Ya arreglado | Dónde | Ojo |
|---|---|---|
| «No conozco esta respuesta» ante fallo técnico de emisión | **solo STG** (21 ago) | en PROD sigue vivo, sin promover → **(B)** |
| El prompt decía que el paquete «2» era la Limitada (es el 3) | **solo STG** (21 ago) | en PROD sigue mal → **(B)** |
| Regla «TODOS los mensajes 200-300 caracteres» sin excepciones | **solo STG** (21 ago) | → **(B)** |
| Red de error: una excepción dejaba al cliente mudo sin avisar a nadie | **solo STG** (21 ago) | en PROD **no existe** |
| Módulo de descuentos completo | **solo STG** | **en PROD no existe**: si ves descuentos, es STG, no PROD |
| El carril de desambiguación que dejaba al cliente sin respuesta | **solo STG** | PROD tiene otra implementación: ese defecto no aplica allí |
| Credencial Postgres inexistente que mataba ejecuciones | **PROD, corregida** | silencios del **13 ago** pueden ser esto → **(C)** |

**Vivo en los dos entornos, por si aparece:**

- **Las sesiones no se cierran nunca**: 1.066 abiertas frente a 15 cerradas. Una conversación
  terminada sigue viva y compite por el turno.
- **`estatus_pago` no es fiable**: 52 `PENDIENTE` y 6 `PAGADO` de 58, con pólizas de julio ya
  cobradas. La verdad del pago está en **`conciliacion_pagos`**.
- **El link de pago no se guarda**: `url_pasarela_pago` vacío en todas. Django lo manda por correo
  sin persistirlo — por eso el bot no puede reenviarlo.
- **`conversation_phase` clavado**, como arriba.

---

## Cómo lo quiero

- **Un ranking final por impacto**, que es lo que de verdad te pido: cada hallazgo con **cuántas
  sesiones afecta**, **cuánto dinero hay detrás** si se puede estimar, y **si el arreglo es copy
  (nuestro, barato) o desarrollo (Django/n8n, caro)**. Ese cruce es el que ordena el trimestre.
- **Fecha en cada conversación citada.** Sin fecha no se puede clasificar A/B/C y el filtro se cae.
- **Cita literal** del cliente y del bot. Es lo que hace tu evidencia utilizable.
- **Sin PII**: por id de sesión o teléfono truncado, sin nombres completos ni correos.
- **Separa lo medido de lo inferido.** Prefiero un «no se puede saber» a una cifra redonda. Si un
  número te sale de una muestra y no del total, di el tamaño de la muestra.

## Lo que NO te pido

- **Copy.** Lo redactas después, cuando esté decidido qué se construye. Escribirlo ahora sería
  escribir para herramientas que quizá no existan.
- **Propuestas de implementación.** Eso es mío y del Agente n8n.
- No toques nada: es lectura.

## Dónde

En `informes/` de tu repo, commit y push, y avísame.

Si al empezar ves que el alcance no cabe, **dímelo antes de recortar por tu cuenta** y decidimos
juntos qué cae. Prefiero tres cubos bien medidos que cinco a medias.
