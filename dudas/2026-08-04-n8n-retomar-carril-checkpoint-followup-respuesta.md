# Respuesta del Arquitecto — carril checkpoint-followup en Retomar (S1 v1.1 §7.1)

**Veredicto: tu opción 1 es la lectura correcta como default conservador, Y la escalo a `#132`
como pregunta formal (§12) para que la autoridad la confirme como aclaración no material.**
No cambies nada mientras tanto.

Razonamiento que publico (coincide con el tuyo):
1. El párrafo transicional vive bajo el epígrafe «**Dashboard** → Retomar Conversación — request
   v1.1» y habla de «el wire **Dashboard** anterior». Su ámbito textual es el productor Dashboard.
2. El follow-up de checkpoints de Django es un productor pre-existente con wire propio
   (`checkpoint` + `idempotency_key`), tráfico explícitamente ajeno a S1. Rechazarlo rompería
   §6.3.8 (preservar comportamiento ajeno a S1) y apagaría los recordatorios de leads estancados
   en cuanto el candidato se despliegue — un efecto operativo real que el contrato no ordena en
   ninguna cláusula.
3. Tu discriminador (`checkpoint`+`idempotency_key` presentes ⇒ carril Django byte a byte;
   ausentes ⇒ §7.1 íntegro) es un punto único, probado en ambos sentidos, y no afloja ninguna
   validación del wire Dashboard. Es la implementación que menos interpreta.

Lo que hago yo: publico la ambigüedad en `#132` con cláusula/ejemplo/impacto y tu implementación
como propuesta de resolución. Si la autoridad contesta «aplica a todo el webhook» (tu opción 2),
el cambio es de Django y se coordinará aparte — tu candidato no se toca hasta entonces. Mantén la
ambigüedad listada en tu diff contractual como «pendiente de aclaración, resolución propuesta
implementada».

**Desbloqueado:** entrega en firme. Sigo con la verificación de tu informe.

---

**RESUELTO POR LA AUTORIDAD (4 ago 21:35Z, `#132 c.5184894562`): aclaración no material.**
El párrafo transicional aplica solo al productor Dashboard; el carril checkpoint-followup de
Django conserva su validación previa. Tu discriminador queda aceptado con una precisión que tu
implementación ya cumple: la presencia de `checkpoint`+`idempotency_key` no convierte un wire
Dashboard inválido en válido — el carril exige además satisfacer su propia validación. **Tu
candidato `2a9202c` NO requiere ajuste.** Mantén la rama inmóvil; el smoke integrado offline
corre ahora en el lado de Juan sobre ambos SHAs congelados.
