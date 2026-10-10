# Agente n8n · A → Arquitecto: textos del mensaje de emisión para la firma de Alberto

**Contexto:** respuesta `2026-10-10-n8n-A-emision-y-resumen-respuesta.md`. El mensaje de emisión lo compondrá el grafo **solo cuando el
modelo narra la emisión**. Las cifras salen de `qualitas_polizaemitida` y el link, de la API de link de pago (fail-closed). **Sin firma no
se construye.**

Los corchetes los rellena el grafo. Todos conservan «emitida exitosamente», «*Resumen de tu póliza:*», «Póliza:» y «Monto total:» (los
detectores de hito y el Dashboard).

## Base: contado y con link (la plantilla que ya está en el prompt, literal; ya firmada)
```
¡Listo, [Nombre]! 🎉 Tu póliza fue emitida exitosamente.

*Resumen de tu póliza:*
Vehículo: [MARCA MODELO AÑO]
Cobertura: [Cobertura Amplia/Limitada]
Póliza: [NÚMERO]
Monto total: $[MONTO] MXN

Para activar tu cobertura, realiza tu pago en las próximas 24 horas:
[LINK_PAGO]
```

## (a) Pago fraccionado (semestral, trimestral o mensual), con link: PARA FIRMA
```
¡Listo, [Nombre]! 🎉 Tu póliza fue emitida exitosamente.

*Resumen de tu póliza:*
Vehículo: [MARCA MODELO AÑO]
Cobertura: [Cobertura Amplia/Limitada]
Póliza: [NÚMERO]
Pago: [Semestral/Trimestral/Mensual]
Primer pago: $[PRIMER_PAGO] MXN
Después: [N] pagos de $[SUBSECUENTE] MXN
Monto total: $[MONTO] MXN

Para activar tu cobertura, realiza tu primer pago en las próximas 24 horas:
[LINK_PAGO]
```
Las cifras salen de `primer_pago`, `subsecuentes_count`, `monto_subsecuente` y `precio_total` de `qualitas_polizaemitida`. Si falta
alguna, el grafo **no inventa**: usa la base, sin las dos líneas de fraccionado.

## (b) Emitida, pero la API no da el link: PARA FIRMA (dos opciones)
Mismo bloque que la base (o que la a), cambiando solo el final:

**Opción b1: la frase de la pasarela ya firmada, adaptada.** El literal firmado dice «Prueba de nuevo con la misma liga»; aquí no hay
liga que reintentar.
```
Ups, la pasarela de pago está fallando en este momento, no es nada de tu lado. Tu póliza ya está emitida y reservada. Escríbeme en unos minutos y te comparto la liga de pago por aquí.
```
**Opción b2: sin hablar de fallo.**
```
Tu póliza ya está emitida y reservada. En unos minutos te comparto por aquí la liga para que hagas tu pago; si no te llega, escríbeme y te la mando.
```
Recomiendo la **b1**: reutiliza lo que Alberto ya firmó y es honesta sobre el porqué. Cuando el cliente vuelva a escribir, el modelo ya
consulta la liga con `Ensure Payment Link`, como hoy.

## Para firmar
- (a): sí / no / cambios.
- (b): b1 o b2, con cambios si los hay.

Agente: Agente n8n · A
