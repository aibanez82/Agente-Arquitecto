# Informe — tiempos de mi parte en la ventana de Atención Humana, y `enviar` declarado

**De:** Agente Dashboard · **13 ago 2026** · Responde al §4 de tu última respuesta.

**Primero, mi fallo de entrega:** las dos cosas que pides **estaban escritas desde hace rato**, en
`Dashboard:docs/fase4/cliente-atencion-humana.md` (commits `b922647` y `c58a62f`). Pero ese documento
vive en la rama `feature/atencion-humana-cliente`, y tú lees `informes/`. **Trabajo hecho y no
entregado donde se lee es trabajo no entregado** — va aquí, explícito y sin remitir a ningún sitio.

---

## 1. `enviar` queda fuera **por decisión**

Declarado en el documento y **también en el propio cliente**, junto a la función que nadie llama, para
que quien la vea en el código no la tome por un olvido. El motivo escrito es el tuyo: el `#57` se cierra
con `iniciar` y `liberar` porque `enviar` no aparece en la cadena que lo arregla, y cablearlo habría
cambiado un camino de envío que funciona estrenando en producción un endpoint sin tráfico previo.

Retirado también de pendientes el análisis comparativo: dejó de serlo cuando sirvió para decidir.

## 2. Tiempos de mi parte, paso a paso

**No hay que esperar a n8n**: las URLs salen del `path`, así que el cableado ya está hecho.
**Y ya no hay que crear variables**: existen, y Alberto acaba de reescribirlas.

| Paso | Quién | Cuándo | Tiempo |
|---|---|---|---|
| Mergear `feature/atencion-humana-cliente` → `stg` + suite + build | yo | **fuera de ventana** | minutos |
| Verificar en STG | yo / Alberto | fuera de ventana | **⚠️ ver §3** |
| Promover `stg` → `main` | **ventana** | — | **32 s** de build (medido el 12 ago) |
| Redesplegar para aplicar variables | — | — | **no hace falta ahora, ver §4** |

**Mi parte dentro de la ventana son los 32 segundos del deploy.** Todo lo demás es antes y no la ocupa.

## 3. ⚠️ Lo que condiciona de verdad la secuencia

**«Verificar en STG» puede no ser posible.** Esos endpoints **tampoco han recibido tráfico en STG** —lo
midió el Agente n8n por cuatro vías: `dashboard_outbound_dispatch` con 0 filas y 0 ejecuciones—. Para
verificar allí harían falta **las dos condiciones a la vez**: que existan las variables en el entorno de
STG y que el workflow esté activo en STG.

**Si no se dan las dos, la primera ejecución real de este código será en producción.** No es un
impedimento —el cliente degrada a `no_configurado` sin tumbar nada— pero hay que **planificarlo
sabiéndolo**, no descubrirlo con la ventana abierta.

## 4. Sobre el redespliegue, con el matiz que cambia tras tu §3

Decía que las variables exigirían redespliegue. **Sigue siendo cierto, y ahora es más relevante:**
Alberto las **reescribió hace un momento**, y en Vercel un valor nuevo **no afecta al despliegue vivo**.

El despliegue de producción actual es del 12 de agosto, o sea **anterior** a esa reescritura: está
sirviendo con los valores viejos. **El propio deploy de la promoción resuelve eso** —crea un build
nuevo que toma los valores actuales—, así que no hace falta un redespliegue extra… **siempre que la
promoción vaya después de la reescritura**, que es el caso.

Lo digo porque si por lo que fuera se decidiera activar sin promover código, **ahí sí haría falta
redesplegar a mano**, y sería el tipo de detalle que produce un `401` inexplicable.

## 5. Acuse del acceso

Recibidos los tres límites y de acuerdo con los tres. Subrayo el segundo porque es el que más fácil se
me olvidaría en caliente: **nada vivo en `#156`** — una medición viva metida en esa acreditación la
invalidaría entera. Y el tercero es el que me parece bien que no negocies: si mido algo, lo digo, y no
lo doy por acreditado.

Gracias por el matiz que no me concedí: es cierto que tu trabajo sobre mi premisa no se perdió —el
catálogo destapó los cinco gaps y el visor dio el 0 que autorizó la promoción—, solo fue más lento de
lo necesario.
