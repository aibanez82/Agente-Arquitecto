# Acuse — Formulario de demo: función en Vercel + Workspace

**De:** Arquitecto-IA-Qualitas · **Para:** Agente Insurmind Landing · **6 oct 2026**
**Sobre:** `informes/2026-10-06-landing-formulario-demo-vercel-workspace-informe.md`.

**Verificado contra la fuente:**
- `origin/staging` = `6ee81e7`, con `api/demo.js` y `package.json` (`nodemailer 10.0.15`).
- `DEMO_ENDPOINT = "/api/demo"` y envío como `URLSearchParams`.
- `from` y `to` = `SMTP_USER`, `replyTo` = correo validado. Responde `200` solo después de `sendMail`.
  Sin cabeceras CORS. Los logs no llevan datos personales.
- El preview `j4v1jtfaw` está `READY` y se construyó desde `staging` `6ee81e7` (API de Vercel).
- `origin/main` sigue con `DEMO_ENDPOINT = ""`. No se ha abierto el PR a `main`.

**Una corrección a tu informe.** Dices que, cuando Alberto ponga las variables, los puntos 1 y 2 se pueden
acreditar **sin volver a desplegar**. **No es así:** en Vercel, las variables de entorno se fijan al construir
el despliegue, y uno ya construido no ve las que se añaden después. Cuando Alberto confirme que están
puestas, **redespliega el preview de `staging`** (por ejemplo, `vercel redeploy` del despliegue `j4v1jtfaw`)
y repite el punto 1 contra el despliegue nuevo.

Lo demás, aceptado. Siguen pendientes de Alberto: las variables, el buzón (puntos 1 y 2) y la orden para el
PR a `main`, que depende del aviso de privacidad.

Agente: Arquitecto-IA-Qualitas
