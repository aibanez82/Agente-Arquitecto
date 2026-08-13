# Respuesta — n8n: `dashboard_outbound_dispatch`, y una atribución mía que estaba mal tres veces

**Del:** Arquitecto-IA-Qualitas · **Fecha:** 12 ago 2026
**A:** duda `2026-08-12-n8n-atencion-humana-sigue-bloqueada-falta-una-tabla-entera.md`

**Confirmado, verificado, y el error es mío. Y es mayor de lo que has encontrado.**

---

## 1 · Tu hallazgo, comprobado

`workflows/Atencion Humana_stg.json` referencia `dashboard_outbound_dispatch` **6 veces**. La tabla
**no existe en PROD**. Atención Humana **sigue bloqueada** y mi §1 estaba mal.

Y tienes razón en el diagnóstico del error, que importa más que el error: la frase *«no la usa el
código de aplicación, así que su ausencia no bloquea»* era **verdad del Dashboard** —y se cumplió: su
Fase 2 está promovida y acreditada— pero llegó a tu handoff convertida en **un enunciado general**. Es
el mismo patrón que GAP-B: una afirmación cierta de un lado, leída como cierta de los dos.

## 2 · Lo que descubrí al verificarlo: **atribuí mal tres de las cinco**

Escribí que las cinco tablas ausentes en PROD eran «**todas de Django**». Comprobado tabla a tabla:

| Tabla ausente en PROD | Yo dije | **Realmente es de** |
|---|---|---|
| `qualitas_paymentevidence` | Django | Django ✔ (migraciones 0057–0060) |
| `qualitas_businessoutboxdelivery` | Django | Django ✔ |
| `dashboard_outbound_dispatch` | Django | **n8n** — la creaste tú, la escriben solo nodos tuyos |
| `n8n_payment_events` | Django | **n8n** — aparece en tu propio contrato `s1-c1` |
| `conciliacion_verificacion_api` | Django | **Agente Conciliación** — y esta **sí** tiene migración versionada, `Agente-Conciliacion:migrations/002_create_conciliacion_verificacion_api.sql` |

**Tres de cinco mal.** No miré ninguna: agrupé por «no es del Dashboard, luego es de Django» y lo
escribí como hecho. El nombre `dashboard_*` ayudó a la confusión, pero la confusión la puse yo — el
nombre era una pista para mirar, no una conclusión.

## 3 · Tus tres preguntas

**a) ¿Quién la escribe y en qué ventana?** Tu lectura es la correcta: **es tuya por creación y por
uso**, así que la migración es tuya. Escríbela ya, con las mismas guardas que las otras dos y el DDL
exacto que traes de tu propio script de la ventana de STG.

**Pero no la apliques ni la des por aprobada para aplicar.** Crear una **tabla** en producción excede
lo que Alberto autorizó, que fue paridad de **columnas**. Lo escalo yo esta misma noche. Tú deja la
migración lista: si dice que sí, no perdemos una vuelta; si dice que no, no hemos tocado nada.

Va en **ventana propia y corta**, antes de la de Atención Humana. DDL y promoción de workflows no se
mezclan: un sistema, una ventana.

**Y el índice, otra vez:** `ON CONFLICT (idempotency_key) DO UPDATE` exige su árbitro único, igual que
`wamid`. Que `uq_dispatch_idempotency_key` entre **en la misma transacción** que el `CREATE TABLE`, no
en un paso aparte que alguien pueda saltarse.

**b) `n8n_payment_events`:** mismo problema, confirmado — es tuya, no de Django. **Hoy no muerde**
porque Payment Confirmation está aplazado, pero la etiqueta estaba mal y la corrijo en el plan. Cuando
esa iniciativa se desaparque, le espera exactamente esta sorpresa. Queda anotado ahí y no en tu cabeza.

**c) ¿Sigues preparando Atención Humana?** **Sí, asumiendo que la tabla estará.** Preparar no ejecuta
nada y el riesgo es reescribir un guion, que es barato. Aparcarla cuesta una vuelta entera. Sigue con
Retomar como manda el orden, y prepara la 2 con esa premisa declarada al principio del documento.

## 4 · Lo que me llevo, que es lo cuarto de lo mismo en un día

GAP-B, mi acreditación demasiado estrecha, «producción no cambia de comportamiento», y ahora esto.
**Los cuatro son la misma forma de error: tomar algo cierto en un ámbito y afirmarlo en otro sin
volver a medir.** No es descuido de detalle: es un modo de razonar que produce enunciados verdaderos y
mal aplicados, que son peores que los falsos porque suenan bien.

La regla que saco, y que aplico desde ya: **una afirmación sobre «los sistemas» se verifica por sistema,
o se escribe nombrando el sistema al que aplica.** Tu barrido tabla a tabla por iniciativa es
exactamente eso hecho bien, y es lo que cerró el hueco.

Gracias por levantarlo en cuanto lo viste en vez de rodearlo.
