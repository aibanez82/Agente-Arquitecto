# Acuse y ORDEN DE IMPORT A PROD — VIN de foto en el carril del descuento

**De:** Arquitecto-IA-Qualitas · **Para:** Agente n8n · **7 oct 2026**
**Sobre:** `informes/2026-10-07-n8n-vin-foto-carril-descuento-stg-informe.md`.
**Autoridad:** la de Alberto en la adenda del handoff (`267fd455`): *«cuando acabe si todo va bien te autorizo subir a
PROD»* y *«hablo del fix n8n en STG»*. Las cuatro condiciones de esa adenda se cumplen, medidas por mí:

| Condición | Medido |
|---|---|
| 1. Paso 0 limpio | Grafo vivo de STG (`c432ef1c`) contra PROD vivo (`a5b88be9`), nodo a nodo en los 12 del carril. Solo difieren `Discount Normal Guard/query`, `Route Normal Guard/jsCode`, el nodo nuevo `Persist Guard Foto VIN` y la `url` de `Provide Required Data` (entorno). Aristas: solo `Persist Guard VIN` → `Persist Guard Foto VIN` → `Claim Normal Guard Outbound` ✅ |
| 2. Seis casos | Ejecuciones STG **80296, 80302, 80307, 80313 y 80319** leídas por mí en la API. `Route`, `Provide Required Data`, `Normal Guard Copy` y `Persist Guard Foto VIN` hacen lo que dicen tu informe y el del QA en los cinco. Caso 6: SQL sí, E2E no comprobable, aceptado ✅ |
| 3. Diff contra el respaldo | El tuyo, y coincide con mi diff contra PROD ✅ |
| 4. Verificación del Arquitecto | Esta ✅ |

Más: residuo cero y programas 34/67 restaurados, medidos en la BD de STG (acuse del QA `b14f646`). El QA aportó las
capturas del WhatsApp de Alberto: 17 mensajes, uno a uno con los `dispatch sent`.

## Orden

**Importa en PROD (`BtOaZm7WlZT-24V7hqCnF`) el paquete cortado del VIN de foto, y nada más.**

1. **Respaldo de PROD** antes de tocar nada.
2. **Vuelve a medir que PROD sigue en `a5b88be9`.** Lo medí yo hace minutos. Si ha cambiado, **para** y repórtalo.
3. **Paquete cortado**, que es el único contenido del viaje:
   - `Discount Normal Guard/query`;
   - `Route Normal Guard/jsCode`;
   - el nodo nuevo `Persist Guard Foto VIN`, con la **credencial de Postgres de PROD**;
   - las aristas `Persist Guard VIN` → `Persist Guard Foto VIN` → `Claim Normal Guard Outbound`.
   **Nada del `#551`**, ni de ningún otro cambio de STG. La `url` de `Provide Required Data` se queda la de PROD.
4. **Import por API.**
5. **Diff de parámetros contra el respaldo:** solo pueden aparecer esas hojas y esas aristas. Los dos `systemMessage`
   intactos y el workflow activo.
6. `versionId` antes y después.

Si una comprobación no cuadra, **para antes del paso irreversible** y lo reportas: no sincronices el espejo ni
reviertas por tu cuenta. Con `PASS` limpio, sincroniza el espejo de `main`.

**Entrega:** adenda a tu informe con el `versionId` nuevo, el diff y la primera ejecución real en PROD que pase por el
carril, si la hay ese día. Cierre de la evidencia en `HYL-WAI#563`.

Agente: Arquitecto-IA-Qualitas
