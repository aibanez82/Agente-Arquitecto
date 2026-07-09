# Handoff Arquitecto → Agente n8n — Bug #6: regex de placas rechaza 6 caracteres

> Autor: Arquitecto-IA-Qualitas · 8 jul 2026
> Ejecutor: **Agente n8n**.
> Gobernanza: reportas al Arquitecto **a través de Alberto**. No hablas con otros agentes.
> Copia canónica: `Agente-Arquitecto:docs/2026-07-08-handoff-agente-n8n-bug6-regex-placas-6-7-caracteres.md` — deja también copia en `Agente-n8n/handoffs/`.
> **Rama destino: `stg`** (decisión de Alberto — se agrupa con el fix del Bug #10 y se despliega todo junto cuando termine la validación E2E; NO es urgente ni bloqueante, así que no hay razón para adelantarlo solo a `main`).

## Objetivo

Bug #6 (`CLAUDE.md`, tabla de bugs, Issue `aguayo-co/HYL-WAI` #2): la regex de placas exige exactamente 7 caracteres alfanuméricos y rechaza placas legítimas de 6 caracteres (existen en varios estados mexicanos, sobre todo motos y formatos antiguos). Cambiar a aceptar 6 **o** 7 caracteres.

**Confirmado que es independiente del Bug #10:** revisé el fix de VIN/serie (rama `stg` actual) y no toca placas en ningún punto. También confirmé que Django (`aguayo-co/HYL-WAI`, buscado en el repo local) **no valida el formato de placas** — la única validación de placas de todo el ecosistema vive en este nodo de n8n. No hay riesgo de parity con Django aquí (a diferencia del Bug #10, donde sí había que mantener la regex de serie sincronizada con `vehicle_series.py`).

## Dónde vive el bug (confirmado leyendo el JSON, no de memoria)

Nodo **`Validate Personal Data`** (`@n8n/n8n-nodes-langchain.toolCode`), campo `jsCode`:

```js
// Placas validation (7 alphanumeric characters)
if (data.placas) {
  const placasRegex = /^[A-Z0-9]{7}$/;
  if (!placasRegex.test(data.placas.toUpperCase())) {
    errors.placas = "Formato inválido. Ejemplo: ABC1234 (7 caracteres alfanuméricos)";
    hasErrors = true;
  }
}
```

Además, el nodo **`AI Agent`** (`systemMessage`) menciona "7 caracteres" en dos lugares que hay que actualizar para consistencia (si no, el bot le dice al usuario un formato que la validación real ya no exige — mismo tipo de inconsistencia que hubo que reconciliar en el Bug #10 entre el prompt y el gate real):

1. `"Placas del vehículo (7 caracteres, opcional)"`
2. `"placas**: Opcional. Si el usuario las proporcionó: 7 caracteres alfanuméricos. Si NO las proporcionó: usar ..."`

Confirmé por búsqueda exhaustiva en el JSON completo (no solo estos dos nodos) que estas son las **únicas** 4 apariciones de "placas...7 caracteres" en todo el workflow — no hay un tercer lugar escondido (p. ej. `Issue Policy` no valida formato, solo mapea el valor ya capturado).

## Cambio propuesto

1. **`Validate Personal Data` → regex:**
   ```js
   const placasRegex = /^[A-Z0-9]{6,7}$/;
   ```
   Mensaje de error, ajustar a algo como: `"Formato inválido. Debe ser 6 o 7 caracteres alfanuméricos (ej. ABC123 o ABC1234)"`.

2. **`AI Agent` → `systemMessage`, ambas menciones:** cambiar "7 caracteres" por "6-7 caracteres" (redacción exacta a tu criterio, mientras quede claro que ambas longitudes son válidas).

## Tareas

1. Aplicar el cambio en la rama `stg` (no `main` — así queda agrupado con el resto de trabajo pendiente de ese branch).
2. Validar en staging con casos: placa de 6 chars (debe aceptar), 7 chars (debe aceptar, comportamiento ya probado), 5 y 8 chars (deben seguir rechazando).
3. Confirmar que el mensaje de error actualizado no rompe ningún LIKE de detección de hitos (`CLAUDE.md`, sección "Regla de estado real de un lead") — este mensaje de error no debería estar en esa lista, pero vale la pena el chequeo rápido.
4. Reportar el commit + resultado de la validación. No hace falta staging E2E completo tipo Bug #10 (cambio de validación aislado, sin dependencias de Quálitas/emisión) — basta con probar el tool call `Validate Personal Data` directo (pin data o Execute workflow).

## Fuera de alcance

Desplegar a `main`/prod por separado — queda empaquetado con el rollout conjunto del Bug #10 salvo que Alberto pida explícitamente adelantarlo.
