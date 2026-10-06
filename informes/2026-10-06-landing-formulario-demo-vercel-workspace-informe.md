# Informe — Formulario de demo: función en Vercel que envía por Google Workspace

**De:** Agente Insurmind Landing · **Para:** Arquitecto-IA-Qualitas · **6 oct 2026**
**Ejecuta:** `handoffs/2026-10-06-landing-formulario-demo-vercel-workspace.md` (`037522f`).
Verifiqué el handoff en `origin/main` de este repo antes de tocar nada, como pedías.

**Entregado hasta `staging` y su preview. No he abierto PR a `main`**: hace falta orden expresa de Alberto.

## Ramas y SHAs

| | |
|---|---|
| Rama de trabajo | `formulario-vercel-workspace`, desde `arreglar-falso-exito` para no perder el arreglo del `mailto:` |
| Commit | `f87ca07` — formulario de demo: función en Vercel + Workspace |
| Commit heredado | `77cd526` — no decir «gracias» cuando el correo no se ha enviado |
| PR a `staging` | `insurmind/insurmind_landing#22`, mergeado |
| `origin/staging` | `6ee81e7` |
| PR #21 | cerrado: queda incluido en el #22 |
| Preview | `https://insurmind-landing-j4v1jtfaw-albers-projects-52295059.vercel.app` |

Ficheros: **`api/demo.js`** (nuevo, 127 líneas), **`package.json`** (nuevo, `nodemailer` fijado en `10.0.15`),
`index.html`, `CLAUDE.md`, `AGENTS.md`, `.gitignore`.

## Aceptación

| # | Acción | Resultado | Quién |
|---|---|---|---|
| 1 | Envío real con datos de prueba | **`502 {"ok":false}`**, por la razón del apartado siguiente. 20:14:54Z | Yo (parcial) |
| 2 | Copia en «Enviados» de `hola@` | **No comprobable todavía** | Alberto |
| 3 | Campo trampa relleno | **`200 {"ok":true}`** y la función no llama a `sendMail` (acreditado en la prueba unitaria; que no llegue correo lo confirma Alberto) | Yo + Alberto |
| 4 | Falta un obligatorio | **`400 {"ok":false,"error":"falta_apellido"}`** | Yo |
| 4b | Correo inválido | **`400 {"ok":false,"error":"correo_invalido"}`** | Yo |
| 5 | `GET /api/demo` | **`405`** con `allow: POST` | Yo |
| 6 | Fallo de SMTP | **`502 {ok:false}`** con transporte simulado, y el cliente enseña `failed()`, no el «gracias» | Yo |
| 7 | 1440, 768 y 390 px | Sin desbordamiento, sin texto bajo 11 px, sin objetivos bajo 24, diálogo de 352 px a 390. Detector de Impeccable: 76, igual que antes | Yo |

## Lo que bloquea los puntos 1 y 2

**`SMTP_USER` y `SMTP_APP_PASSWORD` no existen en el proyecto de Vercel.** Lo comprobé con `vercel env ls`
antes de construir: solo están `NEXT_PUBLIC_WHATSAPP_NUMBER` y `NEXT_PUBLIC_WHATSAPP_MESSAGE`, de hace 134
días. No las he creado ni he pedido su valor por ningún canal, como indica el handoff.

El `502` del punto 1 es por tanto **el comportamiento correcto**: la función comprueba que ambas existan antes
de intentar nada, y si faltan responde `502` sin llamar a `sendMail`. Sirve como prueba en el entorno real de
esa guarda. **En cuanto Alberto las ponga en Production y Preview, los puntos 1 y 2 se pueden acreditar sin
volver a desplegar.**

## Deployment Protection

Como anticipabas, el preview responde **`302`** a `curl` normal, redirigiendo a la autenticación de Vercel,
antes de llegar a la función. **No la he desactivado.** Usé `vercel curl <url>` con la sesión del CLI, que es
lo que sugiere la propia respuesta de Vercel, y con eso llegué a la función. Todos los códigos de la tabla
están medidos así.

## Dos cosas que encontré y arreglé

1. **El modal se quedaba clavado en «gracias».** Tras un envío correcto, `succeeded()` ocultaba el formulario y
   `open()` no lo restauraba. Quien reabriera el modal —o quien usara después ese navegador— no podía enviar
   nada. Lo destapó mi propia prueba de cliente al encadenar dos envíos. Ahora reabrir restaura el formulario,
   limpia los errores y, si el anterior se envió, vacía los campos.
2. **El `mailto:` de respaldo afirmaba haber enviado.** Venía del commit `77cd526`, que ya tenía PR abierto y
   he arrastrado a esta rama para no perderlo. Con el endpoint puesto esa rama no se recorre, pero sigue ahí
   por si alguna vez se vacía la constante.

## Decisiones que tomé dentro del alcance

- **`nodemailer` fijado en `10.0.15`**, que es `latest` hoy. El handoff pedía versión fijada pero no cuál.
- **Topes de tamaño**: 500 caracteres por campo, 2000 para `proceso`, 10 000 para el cuerpo entero. El handoff
  pedía topes sin fijar cifras. El del cuerpo se aplica además mientras se lee el flujo, para no acumular en
  memoria una petición enorme.
- **Una costura de pruebas** en `api/demo.js` (`__inyectarTransporte`) para poder acreditar el punto 6 sin
  tocar SMTP real. Está documentada en el fichero y en producción no se llama nunca.
- **`node_modules` al `.gitignore`**, que ya estaba.

## Lo que no he tocado, por estar fuera de alcance

El plan Hobby de Vercel, el DNS de Name.com —sigue sin SPF, sin DKIM y sin DMARC; comprobé hoy los cinco
selectores habituales de DKIM y todos dan NXDOMAIN—, las variables de entorno y el aviso de privacidad.

## Lo que queda, y de quién es

1. **Alberto**: crear la contraseña de aplicación y poner `SMTP_USER` y `SMTP_APP_PASSWORD` en Production y
   Preview. Sin eso el formulario responde `502` y enseña el aviso honesto, no el «gracias».
2. **Alberto**: acreditar los puntos 1 y 2 mirando el buzón, incluida la carpeta de spam.
3. **Alberto**: la orden para el PR a `main`, que depende del aviso de privacidad.

— Agente Insurmind Landing
