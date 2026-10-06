# Handoff — Formulario de demo: función en Vercel que envía por Google Workspace

**De:** Arquitecto-IA-Qualitas · **Para:** Agente Insurmind Landing · **6 oct 2026**
**Orden de Alberto**, en la sesión del Arquitecto, 6 oct, textual: *«vamos con Vercel + Google Workspace,
publica el handoff»*. La eligió frente a Formspree y frente a Django con dominio `@insurmind.ai`.
**Responde a tu duda** `dudas/2026-10-06-landing-endpoint-formulario-demo.md` y **sustituye** la
recomendación A de su respuesta.

**Por qué este fichero vive aquí y no en tu repo:** `main` de `insurmind/insurmind_landing` está protegida
(PR obligatorio, `enforce_admins: true`) y tu repo no tiene `handoffs/`. **La orden es este fichero en
`origin/main` de `Agente-Arquitecto`**, no el mensaje que lo anuncia. Verifícalo antes de tocar nada.

## Qué se construye

El formulario envía a una función del mismo proyecto Vercel, y la función manda el correo **desde
`hola@insurmind.ai` a `hola@insurmind.ai`** por el SMTP de Google Workspace. No entra ningún proveedor nuevo.

Medido hoy, para que no lo des por supuesto:
- El correo de `insurmind.ai` es Google Workspace (`MX 10 smtp.google.com`, por DNS sobre HTTPS).
- **No hay SPF ni DMARC** en `insurmind.ai`. Por eso el remitente tiene que ser la propia cuenta de Workspace
  autenticada contra `smtp.gmail.com`: cualquier otro remitente «desde» `@insurmind.ai` iría a spam.
- En `origin/main`, `DEMO_ENDPOINT` está vacío y el envío usa `FormData` (multipart). La rama `mailto:` aún
  llama a `succeeded()` sin condición. Tu PR #21 lo corrige, pero **no está en `main`**. Construye sobre ese
  arreglo y no lo pierdas.

## Alcance exacto

1. **`api/demo.js`**: función Node (runtime por defecto de Vercel).
   - Solo `POST`. Cualquier otro método devuelve `405`. **Sin cabeceras CORS**, porque es del mismo origen.
   - **Honeypot `_gotcha` también en el servidor:** si viene relleno, responde `200` y no envía nada.
   - **Valida en el servidor** lo mismo que en el cliente: obligatorios presentes, correo con formato válido,
     longitud máxima por campo y del cuerpo total. Si no pasa, `400`.
   - Envía con `nodemailer` a `smtp.gmail.com:465` (TLS), con usuario `process.env.SMTP_USER` y contraseña
     `process.env.SMTP_APP_PASSWORD`. `from` y `to` = `SMTP_USER`. `replyTo` = el correo del visitante, ya
     validado. Asunto: `Solicitud de demo — Insurmind — <empresa>`. Cuerpo en texto plano, un campo por línea.
   - **Responde `200 {ok:true}` solo cuando `sendMail` haya resuelto.** Cualquier error → `502 {ok:false}`.
   - **No registres datos personales en logs**, solo un código de error. Y **nunca registres las variables
     de entorno**.
2. **`package.json`** con `nodemailer` como única dependencia, con la versión fijada.
3. **`index.html`**:
   - `DEMO_ENDPOINT = "/api/demo"`.
   - Envía el cuerpo como `application/x-www-form-urlencoded` (`new URLSearchParams(data)`) en lugar de
     multipart, para que la función lo lea sin parser extra.
   - Quita `_subject`: el asunto lo pone el servidor.
   - **Con respuesta distinta de 2xx, nunca se muestra el «gracias».** Se queda el `failed()` honesto con la
     dirección de correo.
4. **`CLAUDE.md`**: anota la decisión con fecha y firma. En §2, la landing **deja de ser archivo único por
   decisión de Alberto del 6 oct**: se añaden `api/demo.js` y `package.json`, y nada más. En §1 y §9, donde
   dicen `DEMO_ENDPOINT` vacío o «servicio de formularios», pon el destino real.

**Fuera de alcance, no lo toques:**
- El plan de Vercel (Hobby). Es decisión pendiente de Alberto.
- El DNS de Name.com (ni SPF, ni DKIM, ni DMARC).
- La contraseña de aplicación y las variables de entorno: **las crea y las pone Alberto**. Tú no ves el
  valor ni lo pides por ningún canal.
- El aviso de privacidad (ver «Destino»).

## Variables de entorno (las pone Alberto)

`SMTP_USER=hola@insurmind.ai` y `SMTP_APP_PASSWORD`, en Vercel en **Production** y **Preview**. Si cuando
vayas a probar no existen, **para y dilo**: no inventes un valor ni uses otra cuenta.

## Destino y quién decide cada paso

Sigues tu flujo: `dev` → PR a `staging` → PR a `main`.
- **Hasta `staging` y su preview llegas sin preguntar.** El encargo se entrega en el entorno, no en el commit.
- **El PR a `main` no se abre sin orden expresa de Alberto.** Activar el formulario en producción empieza a
  recabar datos personales, y la casilla de consentimiento aún no enlaza a ningún aviso de privacidad. Esa
  decisión es suya, como dijiste en tu duda.

## Aceptación, en el preview de `staging`

| # | Acción | Resultado esperado | Quién lo acredita |
|---|---|---|---|
| 1 | Envío real con datos de prueba | `200`, pantalla de «gracias» y correo en la **bandeja de entrada** de `hola@` (no en spam), con `Reply-To` del visitante | Alberto mira el buzón. Tú reportas el `200` y la hora |
| 2 | El mismo envío, en «Enviados» de `hola@` | Aparece la copia | Alberto |
| 3 | Honeypot relleno (petición manual a `/api/demo`) | `200`, sin correo | Tú (respuesta) + Alberto (no llega nada) |
| 4 | Falta un obligatorio o el correo es inválido (petición manual) | `400`, sin correo | Tú |
| 5 | `GET /api/demo` | `405` | Tú |
| 6 | Fallo de SMTP (test con el transporte simulado) | `502`, y el cliente muestra `failed()`, **no** el «gracias» | Tú, con test |
| 7 | Tus pruebas de siempre: 1440 y 390 px, con y sin `prefers-reduced-motion` | Sin regresiones | Tú |

**Ojo con la Deployment Protection de Vercel en los preview:** puede responder `401` antes de llegar a la
función. Si pasa, dilo con el código HTTP. No la desactives.

## Entrega

Un informe en `Agente-Arquitecto:informes/` con: ramas y SHAs, URL del preview, la tabla de arriba con lo
que acreditaste tú y lo que queda para Alberto, y lo que no pudiste comprobar. Si algo no cuadra, **para y
pregunta por `dudas/`**: no lo resuelvas por tu cuenta.

Agente: Arquitecto-IA-Qualitas

---

## ~~Adenda (6 oct): autorización de Alberto para `main`~~ — ANULADA

> ⚠️ **ANULADA el mismo día. Error mío.** La frase de Alberto se refería al fix de n8n en STG, no a la
> landing. **No hay autorización para `main`**: el PR a `main` sigue necesitando orden expresa de Alberto,
> como dice el apartado «Destino» de arriba. Ignora todo lo que sigue en esta adenda.


**Alberto**, en la sesión del Arquitecto, 6 oct, textual: *«cuando acabe si todo va bien te autorizo subir a
PROD»*. Con esto, el PR a `main` deja de depender del aviso de privacidad: **lo decide Alberto**, y lo
asume sabiendo que la casilla de consentimiento aún no enlaza a ningún aviso.

**«Si todo va bien» quiere decir, y sin las tres cosas no se abre el PR a `main`:**
1. `SMTP_USER` y `SMTP_APP_PASSWORD` existen en Vercel en **Production y Preview** (compruébalo con
   `vercel env ls`, solo los nombres).
2. Punto 1 de la aceptación en **verde contra un preview redesplegado** después de poner las variables
   (`200` y la hora del envío).
3. **Alberto confirma** que el correo llegó a la bandeja de entrada de `hola@` (no a spam) y que aparece la
   copia en «Enviados» (puntos 1 y 2). Esa confirmación te la transmito yo **por escrito en este fichero**.
   Hasta que esté aquí, no hay orden.

Con las tres: abres el PR `staging` → `main`, lo fusionas siguiendo tu flujo y repites el punto 1 **en
producción** (`insurmind.ai`), con un envío real que Alberto vuelve a confirmar en el buzón. Lo reportas como
adenda a tu informe.
