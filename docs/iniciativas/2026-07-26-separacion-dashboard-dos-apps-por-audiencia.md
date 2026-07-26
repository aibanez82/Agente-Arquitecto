# Iniciativa — separar el Dashboard en dos apps por audiencia (Insurmind interno vs compartido con Hylant)

> Autor: Arquitecto-IA-Qualitas · 26 jul 2026 · Estado: **propuesta v1, en discusión con Alberto**
> Ejecuta (cuando se apruebe): Dashboard Code Agent. El Arquitecto diseña, no ejecuta.

## Driver real

Alberto quiere **escalabilidad**: aparecen funciones nuevas y unas son solo para Insurmind (Juan + Alberto + agentes internos como Conciliación) y otras para todo el equipo (Insurmind + Hylant + agentes humanos de Hylant). Hoy todo vive en una sola app Next.js en la raíz de `Dashboard_SeguroAuto`, y la única barrera entre ambos mundos son checks de rol en el código (`middleware.js` + `visibleTabs` + guards por pestaña).

**El eje de separación NO es técnico (prod-only vs staging) — es una frontera de confianza con un socio externo (Hylant).** El que Conciliación/Comisiones fueran "solo-PROD" era un síntoma; la causa es que estamos mezclando datos internos de Insurmind con una herramienta que usa un tercero.

## Decisión: la frontera de despliegue = la frontera de seguridad

Con un tercero de por medio, separar en **dos apps desplegadas por separado** es la defensa correcta. Si Admin no está desplegado en la app que usa Hylant, ningún bug de esa app puede filtrar datos internos — no están ahí. Un `if (role === 'admin')` es una sola línea entre Hylant y la cobranza de Insurmind; una frontera de deploy no.

Beneficio de escalabilidad: cada feature nueva tiene regla trivial de ubicación → **¿la ve Hylant? Operación. ¿Solo Insurmind? Admin.** Se retira el gate `VERCEL_ENV` que pusimos el 26 jul (era un parche del problema de fondo).

## Arquitectura objetivo — monorepo Turborepo, dos apps, paquetes compartidos

NO dos repos copy-paste (duplicar auth/BD/UI se pudre). Un repo, un git flow, dos Vercel projects (root directory por app — soportado nativamente):

```
Dashboard_SeguroAuto/ (monorepo Turborepo)
├── apps/
│   ├── operacion/   → Vercel project · dominio ventas · audiencia: Insurmind + Hylant + agentes humanos
│   └── admin/       → Vercel project · dominio interno · audiencia: solo Insurmind (Juan/Alberto) + agentes internos
└── packages/
    ├── auth/        → login, sesión, roles, user store  (se comparte el CÓDIGO y el store, no la sesión viva)
    ├── db/          → db (readonly_leads) + db-prod (ufdg7frlrnm5on)
    └── ui/          → KpiCard, layout, estilos, primitivos
```

Añadir una tercera app en el futuro (ej. portal self-service para Hylant) es trivial → esto es lo que da la escalabilidad.

## Audiencia, roles y datos por app

| | **Operación** (compartida) | **Admin** (Insurmind interno) |
|---|---|---|
| Usuarios | Insurmind, Hylant, agentes humanos | Solo Juan + Alberto (+ superficie de agentes internos) |
| Pestañas | Resumen/funnel, Día, Chats (Inbox), Metepec | Agentes, Conciliación, Comisiones (facturación/cobranza), **Cambios de conducto** (nuevo), **Monitoreo Qualitas + n8n** (nuevo) |
| Rol BD | `readonly_leads` (lectura) + `dashboard_rw` (inbox) | `ufdg7frlrnm5on` (escritor, dueño de comisiones/conciliación) |
| Entorno | Gemelo STG real en preview → `stg → main` limpio | Siempre PROD por naturaleza (sin gate) |

**Monitoreo:** no es plomería nueva — el workflow n8n "Monitor Qualitas SIO PROD" ya alerta por Telegram. La vista Admin *superficie* esa señal existente.

## Modelo de confianza (lo más delicado)

- Se comparte el **código de auth y el user store**, NO una sesión viva cruzada. La app Admin debe ser **inalcanzable/inautenticable por un usuario de Hylant** — idealmente sesión con scope por dominio, de modo que una cookie válida de Operación no sirva en Admin. Un usuario de Hylant simplemente no tiene cuenta que Admin acepte.
- La app Operación **no contiene** queries a tablas de dinero (comisiones/cobranza) — estructuralmente no puede filtrarlas, no depende de un check en runtime.

## Plan por fases (sin big-bang — Operación funciona, se extrae Admin)

> **Refinamiento 26 jul (tras leer el código):** la app es JS puro, sin path aliases, imports relativos. Mover el árbol completo a `apps/operacion` preserva todos los imports (cero reescritura). La extracción de paquetes tiene ~22 sitios de import a reescribir y su valor solo aparece con Admin — se mueve de P0 a **P1a**, para verificarla contra dos consumidores.

- **P0 — Esqueleto monorepo (solo mover):** ✅ **HECHO Y VERIFICADO (26 jul).** Turborepo + workspaces, app movida a `apps/operacion` verbatim (51 archivos rename puro, 0 líneas de diff, certificado por el Arquitecto). `globalEnv` en turbo.json para silenciar warning de env. Root Directory de Vercel cambiado a `apps/operacion`. Mergeado a `stg` (`03e33f8`). **Verificado en vivo en el preview de `stg`:** build verde, login real de Alberto OK, dashboard renderiza. Aprendizajes: (a) previews van tras Vercel Deployment Protection (SSO) — abrir logueado en Vercel o usar bypass; (b) `DATABASE_URL` de Preview está scopeado a la rama `stg`, por eso el preview de la rama `refactor/monorepo-p0` daba 500 en login (no era bug de P0). **Handoff:** `Dashboard_SeguroAuto/docs/2026-07-26-handoff-p0-monorepo-skeleton.md`. **Pendiente:** merge `stg → main` (con prerequisito del rol CONCILIACION, abajo).
- **P1a — Extraer paquetes de plomería:** ✅ **HECHO (26 jul, ejecutado directo por el Arquitecto, no vía Code Agent, para cerrar el día).** `packages/db` (db+db-prod) + `packages/auth` (auth+password+roles) como workspace packages; 5 módulos `git mv` (rename puro), 15 consumidores reescritos a `@repo/db`/`@repo/auth`, `transpilePackages` en next.config. **Gotcha resuelto:** el barrel de `@repo/auth` metía bcryptjs en el bundle edge del middleware (32→43 kB); se añadieron subpath exports (`@repo/auth/session`, `/roles`) y el middleware volvió a 32.4 kB. `turbo build` verde local, diff = renames + solo líneas de import. Mergeado a `main`, desplegado. **Pendiente:** verificación de login en prod por Alberto. **`packages/ui` se difiere a P1b** — `components/` mezcla primitivos compartidos con vistas específicas; qué UI comparte Admin se decide mejor con `apps/admin` existiendo (verificable contra dos consumidores). Todos los módulos a extraer son backend (usados en `pages/api`+`middleware.js`+un uso de `roles` en `index.js`); ningún componente los importa. ~26 sitios de import a reescribir a `@repo/*`. Verificar Operación idéntica. **Handoff:** `Dashboard_SeguroAuto/docs/2026-07-26-handoff-p1a-extraer-packages-db-auth.md`.
- **P1b — Crear `apps/admin`:** nuevo Vercel project + dominio + acceso restringido a Insurmind. Extraer `packages/ui` (primitivos que Admin reutilice). **Mover** (no duplicar) Agentes, Conciliación, Comisiones desde Operación, consumiendo los paquetes. Retirar el gate `VERCEL_ENV`. Quitar esas pestañas de Operación.
- **P2 — Vistas nuevas en Admin:** Cambios de conducto, Monitoreo Qualitas+n8n.
- **P3 — Pulido:** deep links cruzados (lead en Operación ↔ su conciliación/comisión en Admin), consolidar con `plan-adelgazamiento-agente-dashboard.md`.

## Cautelas

1. No reconstruir Operación — extraer Admin, no rehacer.
2. Auth compartido desde P0 o mantendrás dos logins divergentes (dolor ya sufrido con credenciales).
3. Enlaces cruzados entre apps: el detalle más subestimado. Planear deep links entre dominios en P3.
4. Costo real: dos Vercel projects/dominios = algo más de ops. Justificado por la frontera con Hylant, no es gold-plating.

## Preguntas abiertas para Alberto

1. **Nombres/dominios** de cada app (ej. `operacion.` / `admin.` o marca propia).
2. ¿Hace falta un paso intermedio (A) — reagrupar por rol dentro de la app actual esta semana — o vamos directo a (B)?
3. Timeline y quién mantiene: ¿solo tú + agentes IA, o entra alguien más?
4. ¿"Cambios de conducto" qué es exactamente? (¿cambio de forma de pago / datos bancarios de la póliza?) — para dimensionar esa vista.
