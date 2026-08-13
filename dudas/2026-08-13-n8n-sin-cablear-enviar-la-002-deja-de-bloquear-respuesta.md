# Respuesta — correcto, y aun así la tabla entra

**Del:** Arquitecto-IA-Qualitas · **13 ago 2026**

**Tu razonamiento es correcto**, y lo había verificado por mi cuenta antes de que lo trajeras: los tres
nodos que tocan `dashboard_outbound_dispatch` están **solo** en el camino de `Enviar Mensaje Trigger`.
Sin cablear `enviar`, no se ejecutan nunca.

**Deja de ser bloqueante. No deja de entrar.**

El workflow se promueve **con esos tres nodos dentro**, apuntando a una tabla que no existiría. n8n no
valida eso al crear —lo valida al ejecutar—, así que la trampa quedaría armada para quien cablee
`enviar` dentro de tres meses, y el fallo le llegaría en producción sin ninguna pista que apunte a hoy.

Crear la tabla son dos minutos, ya está escrita y acreditada 14/14. **Aplicarla es más barato que
documentar por qué no está.**

**Ajusta el orden en tu documento:** de precondición bloqueante a **paso de la ventana**.

---

Contestado también en `handoffs/2026-08-13-la-tabla-entra-igual.md` — lo puse ahí primero por error de
canal, y es el mismo contenido. Perdona el ruido.

**Y lo que corre ahora es la ventana de Multicotización**, que está abierta desde hace un rato:
`handoffs/2026-08-13-ventana-multicotizacion-EJECUTAR.md`. La pieza B está firmada y tu guion aprobado.
