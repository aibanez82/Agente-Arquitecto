# Iniciativa — Journeys del ecosistema en Mermaid (diagramas-como-código)

> Decisión de Alberto (30 jul 2026): aprobada la aproximación Mermaid; ejecución pospuesta
> para no mezclarla con el cierre del port #132. Retomar cuando el port quede en shadow.

## Qué

Mapear todos los journeys del ecosistema como diagramas Mermaid versionados en este repo
(`docs/journeys/`, un archivo por journey + índice), mantenidos por los agentes en el mismo
commit que documenta cada cambio real — para que el diagrama no pueda mentir.

## Privacidad (aclarado con Alberto, 30 jul)

Mermaid es una LIBRERÍA open source, no un servicio: los diagramas son texto en `.md` dentro
de este repo privado — nada se sube a ningún tercero nuevo. "Mermaid Chart"
(mermaidchart.com) es un SaaS comercial aparte que NO se usa ni se necesita. Render: GitHub
(nativo, repo privado), extensión VS Code "Markdown Preview Mermaid Support" (offline), o
Artifacts de Claude (privados por defecto). mermaid.live tampoco hace falta.

## Por qué Mermaid (y no una herramienta de dibujo)

- La fuente de verdad del proyecto vive en git (regla multi-máquina) y la mantienen agentes:
  un board manual (Miro/Lucidchart) se desactualiza al segundo sprint.
- GitHub renderiza Mermaid solo; los Artifacts de Claude también → capa visual sin coste.
- Tipos que cubren la necesidad: flowchart (funnels), sequence (Django↔n8n↔Meta),
  **state diagram** para `conversation_phase`/status/takeover — este último habría ahorrado
  discusiones en el port #132 (catálogo de estados, allowlist).

## Los 8 journeys a mapear

1. Full web (Landing → pago online)
2. Full WhatsApp (n8n → datos → póliza → pago)
3. Mixto (web → WhatsApp → web)
4. Takeover humano ↔ IA (claims, reservas, epoch — insumo: el fencing de 6.8.x)
5. Metepec (registro, exclusiones, correo)
6. Pago + conciliación (redirect usucces/ufail, Agente Conciliación, cruce fareceipt/OPL)
7. Followups / re-enganche (7 checkpoints, dry-run, filtro horario, plantilla Meta)
8. Renovación

## Extras acordados

- **Artifact interactivo** generado desde los `.md` para stakeholders (Laura/Hylant, Juan)
  sin mandarles al repo — se regenera cuando cambien los fuentes.
- Para pizarra ad-hoc con Juan: Excalidraw (`.excalidraw` también versionable en git).
- Descartado por ahora: herramientas CX dedicadas (UXPressia/TheyDo) — solo si algún día se
  necesita un entregable de negocio con personas/pain points; mantenimiento manual y de pago.

## Al retomar

Primer paso: el state diagram de `conversation_phase`/`status` (journey 4 parcial) — es el
que más valor inmediato tiene porque documenta visualmente la allowlist pactada con Juan en
el port. Después los funnels 1-3, luego el resto.
