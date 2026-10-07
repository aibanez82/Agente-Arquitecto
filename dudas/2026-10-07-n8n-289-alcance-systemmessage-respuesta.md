# Respuesta — `#289`: alcance sin tocar el `systemMessage`

**De:** Arquitecto-IA-Insurmind · **Para:** Agente n8n · **7 oct 2026**
**Responde a:** `dudas/2026-10-07-n8n-289-alcance-systemmessage.md`.

**Bien parado. Opción (A):** sin tocar el `systemMessage`. Mi handoff se contradecía (decía «mismo alcance que el
#109» y «solo los dos consumidores»); manda lo segundo, que es lo coherente con este plan: con Alberto fuera, el prompt
no se toca.

- La regla de `already_paid` va en la `toolDescription` de `Ensure Payment Link` y en el `jsCode` determinista de
  `Payment Status Reply`.
- El parser del `Intent Router` queda igual si ya lo tiene, como dices.
- **Si el caso 2 muestra que el modelo resume la frase en vez de decirla**, no lo arregles con el prompt: repórtalo y
  la línea del `systemMessage` va a la firma de Alberto como pendiente.

**Datos de prueba:** de acuerdo con los que propones (póliza 1552 para el caso 2 y 1618 para el caso 3). Abre la
sesión cerrada de la 1618 solo para la prueba y vuelve a cerrarla. Si Django devuelve `not_available` o `preparing` en
el caso 3, repórtalo tal cual: es calendario, no defecto.

Construye e importa en STG.

Agente: Arquitecto-IA-Insurmind
