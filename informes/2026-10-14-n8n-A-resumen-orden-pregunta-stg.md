# Informe · Agente n8n · A · resumen-orden-pregunta (A) en STG (`0adf0e0e` → `ec6f86d1`)

**Orden:** `Agente-n8n:handoffs/2026-10-14-A-firmas-orden-prod-591-y-cola.md` §2b. Firma `resumen-orden-pregunta` → **A**: la pregunta al principio (11 oct; texto de la bandeja, v2).

**Un import, tres nodos:** `Rebuild Summary From Record`, `Rebuild Recovery Summary` y `AI Agent`.
- respaldo en `backups/resumen/`; hojas y connections iguales al candidato; activo; sincronizado a `stg`.
- **Ningún nodo de la sesión B.**
- **Scripts:** `scripts/resumen/` (`1ae29e51`).

## Grafo

**`rehacerResumen` cambia igual, byte a byte, en los dos nodos** (el camino del agente del `#536` y el de Recovery del `#551`; ya eran copias idénticas).

**Con el registro completo, el mensaje es:**
- **`[Nombre de pila], ¿todo correcto? Con tu sí, emito tu póliza.`**, sin nombre: «¿Todo correcto? Con tu sí, emito tu póliza.»; nunca `[Nombre]`;
- una línea en blanco;
- el bloque de datos del registro.

**Lo que ya no sale:** ni la apertura del modelo («¡[Variante]! Ya tenemos todo 🎉») ni su cierre («¡Confírmame…»).

**La línea del vehículo:** la del modelo y, si falta, `Vehículo: <vehiculo de Merge Session Data>`.

**Recovery:** `Recovery Resumen Template` no se toca. Su apertura y su pregunta final las retira `rehacerResumen`, igual que en el camino del agente (comprobado offline).

## Prompt (`AI Agent`, la contradicción L759 frente a L787/L791 del `#486`)

| hunk | antes | después |
|---|---|---|
| 1 | «Antes del bloque de datos, agrega una línea de apertura cálida…» y la plantilla abría con «¡[Variante]! Ya tenemos todo 🎉» | sin apertura. La plantilla abre con «[Nombre], ¿todo correcto? Con tu sí, emito tu póliza.» («el sistema lo monta en este orden, con los datos del registro») |
| 1b | la plantilla acababa con «[Nombre], ¿todo correcto? Con tu sí, emito tu póliza.» | acaba en el C.P. |
| 2 | CIERRE DEL MENSAJE DE RESUMEN: «…un cierre cálido con gancho de urgencia/escasez… ¡Confírmame para asegurar esta tarifa antes de que cambie! 😊» | «NADA ANTES NI DESPUÉS: no añadas apertura antes de la pregunta ni ningún cierre después del bloque de domicilio…» |

**L759** («la pregunta de confirmación AL INICIO del mensaje») se queda tal cual: ya dice lo mismo que la plantilla.

**Al pasar, desaparece el «antes de que cambie»** del cierre, que también es urgencia del `#596` (H).

## Aceptación

| caso | control (`0adf0e0e`) | cambio |
|---|---|---|
| **arnés:** sesión con los tres grupos y la factura pendiente; el cliente responde «No» → resumen | 2/2 con la **pregunta al final**: arriba «¡Listo, Juan! Ya tenemos todo 🎉», abajo «Juan, ¿todo correcto?… ¡Confírmame para ase…» | **3/3 + 1/1 en el vivo**: la primera línea es «Juan, ¿todo correcto? Con tu sí, emito tu póliza.» y la última, «…C.P. 05100»; sin «Ya tenemos todo» |
| **offline** (`rehacerResumen` sacada de los dos nodos del candidato, que son idénticos): la plantilla de Recovery · un resumen del modelo con apertura y cierre · un resumen sin línea de vehículo · sin nombre | — | **4/4** |
| regresión del `#577` (incluye el resumen y la emisión correcta) sobre el vivo | — | 9/9 |

— Agente n8n · A
