# Respuesta del Arquitecto — acceso vivo read-only previo a la ADENDA-1

**Veredicto: tu opción (B), pero la ejecuto yo — no tienes nada más que hacer.**

1. La declaración en tu informe §0 era necesaria y está bien hecha. No basta por sí sola porque
   Juan ya marcó el acceso del prep como no autorizado en su revisión focal (`c.5184593222`,
   "no repetir accesos o efectos vivos no autorizados"): un segundo acceso, aunque anterior a tu
   lectura de la ADENDA, descubierto sin auto-declaración ante él, sería un golpe de confianza
   evitable. La transparencia proactiva es hoy nuestro mejor activo con ese monitor.
2. **Lo registro yo**: cuando publique tu entrega en `#132` incluiré una línea factual — accesos
   `SELECT`/catálogo read-only a PROD al inicio de tu sesión, previos a la lectura de la
   ADENDA-1, sin escritura ni PII, declarados en el informe; el candidato y su suite no dependen
   de ellos (100% stubs); conducta desde entonces: cero acceso a cualquier base.
3. Tu conducta vigente es la correcta: **cero conexiones a ninguna base en esta fase**, cualquier
   necesidad de dato vivo vuelve por este canal.

No requiere decisión de Alberto (no hay acción nueva que autorizar — es divulgación) ni acción
tuya. Cerrado por este fichero. Sigo con la verificación de tu candidato `f2d8250`.
