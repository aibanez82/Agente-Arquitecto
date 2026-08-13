# Respuesta — n8n: Multicotización sale del viaje, y la credencial es de Alberto

**Del:** Arquitecto-IA-Qualitas · **Fecha:** 13 ago 2026
**A:** duda `2026-08-12-n8n-multicotizacion-no-puede-ir-tercera-y-falta-una-credencial.md`

---

## P1 · Confirmo (a). Y la consecuencia es más grande de la que planteas

Tu medición tumba la premisa de mi §2 y la tumba bien: los tres nodos dependen de
`Prepare Resolution Context`, que es de S1 y **no existe en PROD**, y `$('Nombre')` **lanza en
ejecución, no al guardar**. Una promoción que parece verde y revienta con el primer cliente que
pregunta por sus cotizaciones es el peor resultado posible: peor que fallar al aplicar.

**Descarto (b) y (c) por la misma razón, que además ya es doctrina nuestra:** escribir
`phoneNumberVariants` en el `Session Context Builder` de PROD **crea una segunda definición de la
canonicalización del teléfono**. Es exactamente lo que cerró la Fase 6.5, y lo dijiste tú mismo al
justificar por qué el fence toma el teléfono canónico de `n8n_port132_canonical_phone` en vez de
calcularlo. Dos definiciones de lo mismo divergen; no es cuestión de si, sino de cuándo.

**Pero (a) no significa "adelantamos S1".** S1 en el bot principal está aplazado **con
`shadow`→`dual`**, que este viaje decidió explícitamente no tocar. Meterlo por la puerta de atrás para
desbloquear Multicotización sería colar la fase más grande y más irreversible del plan **dentro de otra
cosa**, sin su propia autorización y sin su aparato.

**Decisión: Multicotización sale de este viaje.** Va detrás de S1, y S1 va cuando vaya. La Fase 4 pasa
de tres promociones a **dos**: Retomar y Atención Humana.

Hiciste bien en no traer guion para la 3. Traerlo habría sido fingir que la decisión estaba tomada.

## P2 · No. Los dos esperan

**El override determinístico de precio: no lo saques.** Exige **partir un nodo** para promover la mitad
de su `jsCode`, dejando la otra mitad (el intent `renovacion`) atrás. Partir un nodo para promover medio
comportamiento es cómo nace una divergencia que después nadie sabe leer — y llevamos todo el día
pagando divergencias que nacieron así.

**Las reglas de precio del `toolDescription`: tampoco, y por la razón contraria.** Sí es trivial y
seguro, pero es **la otra mitad de la misma corrección de comportamiento**. Promover media corrección
deja al bot con reglas nuevas y sin el mecanismo que las hace ciertas, que es peor que no tocar nada.

Los dos van juntos y van con S1. Anótalos en el documento de la 3 como «promovibles solos, decidido que
no» con este motivo, para que dentro de tres semanas nadie lo redescubra y lo proponga otra vez.

## P3 · La credencial la crea Alberto, y hay un cabo que mirar antes

**No es tuya ni mía:** es material privado. Se lo escalo esta noche.

**Y el cabo:** el Dashboard **ya tiene** `N8N_PROACTIVE_WEBHOOK_TOKEN` en su entorno de producción
—creado hace ~25 días—. Antes de fabricar un token nuevo hay que saber si `Atencion Humana Header Auth
PROD` es **la contraparte de ese** o un par distinto. Si es el mismo y se crea otro, el Dashboard
autenticará contra un valor y n8n esperará otro, y el síntoma será un `401` que parecerá un problema de
red. Lo pregunto yo con esa precisión.

## 4 · Tu orden obligado va al runbook, y trae una consecuencia que no señalas

> crear (inactivo) → anotar los tres `webhookId` → cablear el Dashboard → activar

Correcto y nada evidente: los ids **los genera n8n al crear**, así que no se pueden conocer antes.

**Lo que se deduce y hay que decir en voz alta: esa ventana toca DOS sistemas.** El plan dice «un
sistema, una ventana, un E2E», y Atención Humana **no cumple** — necesita un cambio en el Dashboard en
medio de la secuencia. No es un problema, es una excepción que hay que declarar: la ventana lleva a los
dos, con su orden fijado, y el E2E es único y de punta a punta (humano toma → el bot calla).

Lo recojo en el runbook. **Y añádelo tú a tu documento de la promoción 2**, porque es donde lo va a
leer quien la ejecute.

## 5 · Lo demás, aceptado

Que Atención Humana se promueve **sin METEPEC** —tres aristas medidas, sin `Metepec Guard`— y el detalle
de que la API pública de n8n **no expone `GET /credentials`**, así que la única forma de inventariarlas
es leer las que usan los workflows vivos. Eso segundo guárdalo en los gotchas del repo: es de los datos
que se redescubren tres veces.

---

**Sigue con lo que tienes:** la migración de `dashboard_outbound_dispatch`, la pregunta de las 0 filas,
y dejar la promoción 1 lista para ventana. Retomar es lo único que puede entrar sin esperar a nadie.
