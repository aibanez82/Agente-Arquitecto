# Mensaje para Juan — deploy de la validación de VIN (Bug #10)

> Redactado por el Arquitecto para que Alberto lo envíe a Juan (`juan.aguayo@aguayo.co`).
> Fecha: 5 julio 2026. Contexto completo: `docs/2026-07-05-handoff-despliegue-bug10-vin.md`.

---

**Asunto:** Deploy urgente — validación de serie/VIN en emisión (rama `stg` → prod)

Hola Juan,

Necesito que despleguemos a producción tu validación de serie/VIN — la de la rama `stg`
(`vehicle_series.py`), el gate que rechaza series inválidas con `400 invalid_vehicle_serie`.

**Por qué urge:** el problema del VIN (issue #83) sigue vivo en prod. Auditamos las últimas 7
emisiones reales y **4 salieron con una ciudad en lugar del VIN** (Gómez Palacio, Ciudad General
Escobedo, Ciudad de México, Hidalgo) — casi el 60%. Hoy cada venta por WhatsApp es un volado a
emitir una póliza inválida que luego hay que reemitir a mano con Quálitas. El lunes queremos empezar
a escalar ventas y esto lo tenemos que cerrar antes.

Tu gate es **la única garantía determinista** de que ninguna ciudad llegue a Quálitas — el lado del
bot baja la probabilidad, pero a la temperatura del modelo no la elimina; tu 400 sí.

La pieza de nuestro lado (n8n: prompt de VIN-17 + manejo de tu `400`) ya está lista. Van en
**lockstep**: n8n primero (o a la vez) y tu deploy de Django justo después — así no quedan emisiones
atascadas en el intervalo. **Yo te aviso en cuanto n8n esté arriba** para que dispares el merge
`stg`→prod.

¿Puedes dejarlo listo para desplegar hoy o mañana a primera hora? Cuando lo hagas, confirmamos juntos
en prod:
- una serie tipo ciudad o de menos de 17 chars → `400 {code:"invalid_vehicle_serie"}` (no emite)
- un VIN-17 válido → emite normal

Gracias, crack. Ref: issue #83 y tu guía `docs/guia-n8n-validacion-serie-vin.md`.

---

> *(Nota interna, no para Juan: hay un 2º tema pendiente suyo — Bug #9, el 400 genérico de
> `/api/emitir-externo/` sin logging del fault real. No lo mezclo aquí para no diluir el deploy del
> VIN, que es el bloqueo del lunes. Se le plantea aparte.)*
