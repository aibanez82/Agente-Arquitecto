# Propuesta de mejoras: Conversación WhatsApp

## Contexto

Datos actuales del funnel (semana del 15-23 jun 2026):
- 98 mensajes enviados
- 97 entregados (99%)
- 71 leídos (73%)
- ~4 contestaron (4%)

**El problema real:** 67 personas leyeron la cotización y no respondieron.
La tasa de lectura es buena (73%) — el mensaje llega y se abre.
El problema está en el mensaje mismo o en el momento del seguimiento.

---

## 1. Mensaje inicial — de robot a humano

### Versión actual (demasiado formal)
> Hola, ¡gracias por cotizar con nosotros! Como asesor virtual te voy a ayudar a terminar el proceso para activar tu póliza. Adjunto te comparto la cotización No. 2211 para una póliza de un VOLKSWAGEN TOUAREG 2017 con Cobertura Amplia y Anual (Contado) por $19,479.33 MXN. Para activar tu póliza necesitamos algunos datos y proceder al pago. ¿Continuamos? Responde este mensaje para continuar.

**Problemas:**
- "Como asesor virtual" — el cliente sabe que es un bot, esto genera desconfianza
- "Responde este mensaje para continuar" — suena a instrucción mecánica
- Todo en un solo bloque de texto denso
- No personaliza por nombre (aunque no lo tienen en este punto)
- No genera urgencia ni valor

### Versión propuesta A (conversacional)
> ¡Hola! 👋
>
> Vi que cotizaste tu **TOUAREG 2017** — te comparto los números que salieron:
>
> 📋 Cotización #2211
> 🚗 VW Touareg 2017 · Cobertura Amplia
> 💰 $19,479 anuales (o desde $1,685/mes)
>
> La vigencia es de un año y cubre daños, robo total, RC y gastos médicos.
>
> ¿Te late? Con un par de datos más lo activamos hoy mismo 🙌

**Mejoras:**
- Elimina "asesor virtual" — suena más humano
- Rompe el texto en bloques digestibles
- Muestra el precio mensual (parece más accesible que el anual)
- "¿Te late?" — mexicanismo que genera cercanía
- "hoy mismo" — urgencia sutil sin presión

### Versión propuesta B (más directa, para testear)
> Hola, aquí tu cotización del Touareg 👇
>
> ✅ Cobertura Amplia · $19,479/año
> ✅ Vigencia inmediata al pagar
> ✅ Incluye robo total, daños y RC
>
> ¿Seguimos con la emisión? Solo necesito unos datos rápidos.

---

## 2. Secuencia de recordatorios

### Para leads EN ESPERA (recibieron WA, no han respondido, <48h)

**T+2h — Recordatorio suave**
> Hola, por si no viste mi mensaje anterior 😊
>
> Tu cotización del Touareg está lista — $19,479/año con Cobertura Amplia.
>
> ¿Tienes alguna duda sobre la cobertura o el precio? Con gusto te ayudo.

**T+6h — Énfasis en beneficio**
> Una cosa sobre tu seguro de auto 👇
>
> La cobertura de RC que incluye te protege hasta por **$3,000,000** si hay un accidente con terceros. Es lo que más preocupa y esta póliza lo cubre bien.
>
> ¿Te gustaría activarla hoy?

**T+24h — Alternativa de precio**
> Hola, ¿cómo estás?
>
> Vi que aún no has podido continuar con tu seguro. Por si el precio anual se siente pesado, también tienes opción mensual desde **$1,685/mes** — sin compromiso de permanencia.
>
> ¿Cuál modalidad te funciona mejor?

**T+48h — Última llamada (antes de marcar como abandonado)**
> Tu cotización del Touareg vence en 7 días 📅
>
> Si quieres asegurarlo en las mismas condiciones y precio, podemos activarlo ahora. Si el precio cambió o quieres ajustar la cobertura, también puedo recotizarte.
>
> ¿Qué prefieres?

---

## 3. Para leads LEÍDOS que no contestaron

Son el grupo más valioso — vieron la cotización pero no respondieron. Pueden tener dudas específicas.

**Mensaje de enganche por duda**
> Hola 👋 Leí que viste tu cotización pero no continuaste.
>
> ¿Fue el precio, la cobertura, o simplemente no era buen momento?
>
> Cuéntame y veo cómo ayudarte 😊

*(Este mensaje es más efectivo que un recordatorio genérico porque abre una conversación real)*

---

## 4. Para leads que se quedan en "capturando datos"

Leads que contestaron pero dejaron la captura a medias.

**T+1h sin respuesta durante captura**
> Hola, parece que nos quedamos a medias 😅
>
> ¿Pudiste conseguir los datos que te pedí? Si no los tienes a la mano, podemos retomarlo cuando puedas — la cotización sigue válida.

---

## 5. Mejoras al flujo de captura de datos

### Problema actual
El bot pide los datos por bloques (personales → fiscales → domicilio) con mini-confirmaciones en cada uno. Esto genera ~12-15 mensajes de ida y vuelta.

### Propuesta: reducir fricciones
1. **Pedir primero la CSF** (Constancia de Situación Fiscal) — extrae nombre, apellidos, RFC, CURP y domicilio de un solo documento. Ver `agente-csf-extraccion.md`.
2. **Pedir la Tarjeta de Circulación** — extrae placas y VIN de una foto.
3. Con esas dos imágenes, el bot confirma todos los datos en un solo mensaje en vez de preguntar uno a uno.

**Resultado esperado:** reducir de ~15 mensajes a ~5 mensajes para completar la captura.

---

## 6. A/B tests propuestos

Para medir cuál mensaje funciona mejor, probar con grupos distintos:

| Variable | Versión A | Versión B |
|---|---|---|
| Saludo inicial | Formal (actual) | Conversacional (propuesta A) |
| Horario de envío | Inmediato al cotizar | 5 min después (da sensación de revisión humana) |
| Precio mostrado | Anual ($19,479) | Mensual ($1,685/mes) |
| 1er recordatorio | T+24h | T+2h |
| CTA | "¿Continuamos?" | "¿Te late?" |

El dashboard ya tiene los datos para medir cada variante — solo hay que etiquetar qué mensaje recibió cada lead.

---

## 7. Métricas a monitorear

Con estas mejoras, los KPIs a vigilar:

| Métrica | Actual | Objetivo |
|---|---|---|
| Tasa de lectura | 73% | >80% |
| Tasa de respuesta | 4% | >15% |
| Tiempo hasta primera respuesta | desconocido | <2h |
| Conversión (pagadas/leads) | 1.2% | 6-8% |

---

*Documento generado el 23 jun 2026 · Proyecto Dashboard Qualitas / Hylant*
