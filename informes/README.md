# Canales de coordinación ejecutor ↔ Arquitecto — tabla canónica de ruteo

| Flujo | Canal | Detección |
|---|---|---|
| Handoff (Arquitecto → ejecutor) | `<repo-del-ejecutor>:handoffs/` en `main` | monitor del ejecutor sobre `handoffs/` |
| Informe del **Agente-n8n** | su propio `main` (`handoffs/<handoff>-informe.md`) | monitor del Arquitecto sobre su `main` |
| Informe del **Agente Dashboard** | `Agente-Arquitecto:informes/` (su `main` está bajo auditoría de Juan — dictamen `#132 c.5185027837`) | push de su rama candidata (monitor del Arquitecto) |
| Duda de cualquier ejecutor | `Agente-Arquitecto:dudas/` (respuesta en `<mismo>-respuesta.md`) | monitor del Arquitecto sobre `dudas/` |

Reglas: la instrucción explícita del handoff vigente manda sobre esta tabla si difieren (y
entonces esta tabla se actualiza); los ejecutores nunca se coordinan entre sí; nada en trackers
de Juan; sin PII/secretos. Nombres de fichero: `AAAA-MM-DD-<agente>-<tema>[-informe|-respuesta].md`.
