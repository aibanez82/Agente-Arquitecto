# Bloqueo — M41 (RC en EUA/Canadá) contradice la Cláusula 9a del PDF de Condiciones Generales

> Estado: 🔴 **Bloqueado, pendiente de que Alberto confirme con Hylant.** No aplicar el parche
> tal cual hasta resolver esto.

## Origen del parche

`Agente-MejorasConversacion:informes/parches/M41-rc-eua-canada-incluida.md` (18 jul 2026),
handoff a Agente n8n en `informes/parches/2026-07-18-handoff-agente-n8n-m41.md`. Caso real: lead
1526 (Toyota Camry 2007, cotización 2978, sesión `526861706122`) preguntó si su RC cubre en
EUA/Canadá. El bot dijo que no estaba incluida y ofreció derivar a un agente para agregarla. Un
supervisor retomó la conversación en vivo y corrigió: según el supervisor, la RC en EUA/Canadá
**sí viene incluida automáticamente**, sin costo, en pólizas Amplia y Limitada de uso particular
— el endoso se emite junto con la póliza.

El parche propone reemplazar la entrada de KB (`search_knowledge_base1`, sección `coberturas`)
que dice que la RC en EUA/Canadá "debe estar expresamente contratada en la carátula" —
argumentando que esa condición aplica solo a un producto distinto (una póliza aparte de cruce
fronterizo frecuente), no a la RC base de la Amplia/Limitada.

## Contradicción encontrada por el Arquitecto (18 jul), antes de aprobar

Verificado contra `2026-07-17-condiciones-generales-autos-qj01-1224-ga.pdf` (mismo método usado
para M36 y el hallazgo de `kb_chunks.id=38`): **Cláusula 9a, "TERRITORIALIDAD"**:

> "Las coberturas amparadas por esta póliza, se aplicarán únicamente en caso de accidentes
> ocurridos dentro de la República Mexicana. Excepción hecha al párrafo anterior, se extienden a
> los Estados Unidos de Norte América y al Canadá **únicamente** las coberturas siguientes:
> 1. Daños Materiales, 1Bis Solamente Pérdida Total, 2.- Robo Total, 5. Gastos Médicos Ocupantes
> y 9. Equipo Especial."

**Responsabilidad Civil (cobertura 3 en la numeración del propio documento) no está en esa
lista.** Revisada también la Cláusula 3 (Responsabilidad Civil por Daños a Terceros) completa —
no tiene ninguna extensión territorial propia; su alcance geográfico depende exclusivamente de la
Cláusula 9a, que la excluye explícitamente.

Esto es lo opuesto a lo que afirma el parche y a lo que corrigió el supervisor en vivo.

## Dos hipótesis, sin resolver

1. **Existe un endoso separado** (documento aparte, no incluido en este PDF de Condiciones
   Generales) que extiende específicamente la RC a EUA/Canadá para pólizas Amplia/Limitada de uso
   particular — el propio texto del parche menciona "se envía el endoso correspondiente en la
   emisión", consistente con que sea un documento distinto que el Arquitecto no tiene.
2. **El supervisor se equivocó** en la corrección en vivo (pasa, bajo presión de conversación
   real) y la KB original (que decía "debe contratarse expresamente") en realidad tenía razón
   para la RC base también, no solo para el producto de cruce fronterizo.

No se puede distinguir cuál es cierta con las fuentes disponibles hoy.

## Por qué se bloquea en vez de aplicar con reserva

Es una afirmación de cobertura con consecuencia real si es incorrecta en cualquier dirección —
decirle a un cliente que está cubierto en EUA/Canadá cuando no lo está lo deja expuesto sin
cobertura real en el extranjero, y Quálitas no estaría obligada a pagar. Mismo estándar aplicado
hoy a `kb_chunks.id=38` y al dato de "precio preferencial" — pero en este caso la verificación
contra la fuente dio un resultado contradictorio, no confirmatorio, así que no hay base para
aprobar el parche tal cual.

## Siguiente paso

Alberto va a confirmar directo con Hylant si existe el endoso que extiende la RC a EUA/Canadá
para Amplia/Limitada de uso particular. Con la respuesta:
- **Si existe el endoso:** pedirle el texto/número de cláusula exacto, verificarlo, y entonces sí
  aplicar el parche M41 (ajustando la cita de fuente si hace falta).
- **Si no existe:** el parche se descarta — la KB original (que exige contratación expresa) queda
  como estaba, y hay que corregir aparte al supervisor/al equipo sobre el error de la corrección
  en vivo, para que no se repita en otras conversaciones.

Nada aplicado en STG ni PROD todavía.
