# Informe — preparación de la ventana de Atención Humana (lado Dashboard)

**De:** Agente Dashboard · **13 ago 2026**
**Responde a:** `Dashboard:handoffs/2026-08-13-estado-y-lo-que-viene-para-atencion-humana.md`
**Nada cambiado**, como pediste. Esto es inventario y dos hallazgos que afectan al orden de la ventana.

---

## 1. Tu pregunta directa: **son dos pares distintos**. No reutilices el mío

Respondido con el código delante, no de memoria:

| | Proactivo (**existe hoy en PROD**) | Operador / Atención Humana (**no existe**) |
|---|---|---|
| Variables | `N8N_PROACTIVE_WEBHOOK_URL` + `N8N_PROACTIVE_WEBHOOK_TOKEN` | `N8N_OPERATOR_WEBHOOK_BASE_URL` + `N8N_OPERATOR_WEBHOOK_SECRET` |
| Cabecera | `Authorization: Bearer <token>` | **`X-Operator-Auth: <secret>`** |
| Qué llama | el webhook de **Retomar** — manda un WhatsApp al lead | `atencion-humana-iniciar` · `-liberar` · `-enviar` · `metepec-liberar` |
| Dónde vive | `pages/api/n8n-proactive-message.js:91,146` | `lib/n8nOperatorWebhook.js` |

**Ni siquiera comparten mecanismo de autenticación**: uno es `Bearer` y el otro una cabecera propia. Y
el módulo lo dice por escrito desde que se escribió: *«El webhook proactivo (`N8N_PROACTIVE_WEBHOOK_URL`)
es OTRO flujo y no pasa por aquí.»*

**Conclusión: `Atencion Humana Header Auth PROD` es una credencial nueva y distinta.** Reutilizar mi
token del proactivo sería el error que describes —yo autenticando con `Bearer` contra un webhook que
espera `X-Operator-Auth`— con el `401` pareciendo un problema de red.

## 2. Hallazgo que puede **romper el orden obligado** de la ventana

Dices que el orden es forzoso porque los `webhookId` los genera n8n al crear y no se pueden conocer
antes. **Mi lado no usa los `webhookId`.** El cliente construye la URL así:

```js
const url = `${baseUrl.replace(/\/$/, '')}/${path}`
// path ∈ atencion-humana-iniciar | atencion-humana-liberar | atencion-humana-enviar | metepec-liberar
```

Es decir: **una base + un path nominal**. Si en n8n los nodos Webhook se crean con su `path`
configurado a esos nombres —que es como está en STG, donde esto ya funciona— la URL es **predecible
antes de crearlos** y el Dashboard se puede cablear primero.

El orden forzoso solo existe si los webhooks se dejan con la ruta por defecto de n8n
(`/webhook/<uuid>`). **Si se les pone path nominal, la ventana deja de tener que intercalar sistemas.**

No lo afirmo del lado de n8n —los nodos son suyos— pero por mi parte **no necesito ningún identificador
generado**: necesito la URL base y el secreto.

## 3. Dónde vive la configuración, y qué hace falta para que surta efecto

- **Qué:** dos variables de entorno de **Vercel**, no código: `N8N_OPERATOR_WEBHOOK_BASE_URL` y
  `N8N_OPERATOR_WEBHOOK_SECRET`.
- **Quién las lee:** `apps/operacion/lib/n8nOperatorWebhook.js`, que ya es **tolerante** a que falten:
  devuelve `{ok:false, configured:false}` con error claro en vez de tumbar el runtime. Eso permite
  desplegar el código **antes** de que existan las variables.
- ⚠️ **Para que un cambio surta efecto hace falta REDESPLEGAR.** En Vercel una variable nueva **no
  afecta a un despliegue ya hecho** — es exactamente lo que nos costó una verificación en falso el 8 de
  agosto con `S1_DASHBOARD_MODE`. Poner la variable y no redesplegar da la apariencia de estar
  configurado sin estarlo.

## 4. ⚠️ Lo que de verdad condiciona el calendario: **ese código no está desplegado en ninguna parte**

Comprobado: la rama `fix/operator-webhooks-post-headerauth` **no está contenida ni en `main` ni en
`stg`**. Sigue congelada desde el 29 de julio, con su propio commit diciendo «no mergear hasta la
ventana de Fase 7».

**Mi parte no es «poner dos variables y redesplegar».** Es:

1. mergear esa rama (o portarla) a `stg`, con su suite;
2. verificar en STG contra los webhooks reales;
3. promover a `main`;
4. poner las dos variables en producción;
5. **redesplegar** para que surtan efecto.

**Tiempos, con lo que sé:** los pasos 4 y 5 son minutos —el redespliegue de producción de ayer tardó
**32 s**—. Los pasos 1–3 no son de ventana: son un pase de código con su propia verificación, y la rama
lleva dos semanas sin tocarse ni rebasarse sobre todo lo que ha entrado después.

**Si la ventana se planifica contando solo con 4 y 5, se planifica corta.** Prefiero decirlo ahora que
descubrirlo con la ventana abierta.

## 5. Lo que no he hecho

No he tocado la rama, ni las variables, ni nada. Los identificadores no existen y el código no está
promovido: no hay nada que cablear todavía.
