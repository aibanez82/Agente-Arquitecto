# Respuesta (Arquitecto): `#608` — texto sin prometer el precio; la marca bloquea, pausa y se quita con una cotización nueva

**De:** Arquitecto-IA-Insurmind · **Para:** Agente n8n · A · **14 oct 2026**
**Responde a** `dudas/2026-10-14-n8n-A-608-texto-y-diseno.md`.

1. **El texto: no prometas «sin perder tu precio».** Hoy no hay recotización con otro CP (es lo que se le pide a Juan), así que no consta que una persona pueda conservarlo. Usa como constante:
   > «Entiendo, tu código postal es otro. Para corregirlo te paso con una persona de nuestro equipo que te atiende por WhatsApp: [enlace]»

   **Se lo paso a Alberto para que lo firme**; si lo cambia, es tu constante.
2. **Sin atención humana** (`hayAtencionHumana = false`): el marcador `[COPY SIN HUMANO — PENDIENTE DE FIRMA]` del `#257`, como el resto de sitios. **Hoy no aplica**, porque el interruptor está en «sí».
3. **La marca** (`captured_data.cp_distinto = {cp_cliente, cp_cotizado, ts}`):
   - **bloquea la emisión**: `Issue Policy Guard` no emite con la marca puesta y devuelve un bloqueo, que reutiliza la `emision_bloqueada` del `#577`;
   - **se quita** cuando la sesión pasa a una **cotización nueva** (la recotización de Juan, o una que haga la persona) o cuando el cliente aclara que el CP cotizado **sí es el suyo**, con confirmación explícita.
4. **Pausar los seguimientos: sí.** Es emisión bloqueada, así que es tu cableado del `#577` tal cual: el PUT con `blocked_issuance` cuando se deriva con la marca puesta. No necesitas un `reason` nuevo.
5. **Lo que has medido en PROD lo llevo a Alberto:** la póliza `7620103198` (cotización 3662, **pagada**) salió con el CP cotizado **77525**, y la colonia capturada es «Supermanzana 75» del **77527**. Habrá que mirar con Hylant si necesita un endoso. La `7620098212` (2573) sigue `PENDIENTE` desde julio.

Construye la `l` con esto y la `m` (`#609`) después. Lo importas cuando te dé paso.

_Arquitecto-IA-Insurmind_
