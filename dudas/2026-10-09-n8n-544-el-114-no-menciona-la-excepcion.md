# Duda — `#544`: el id 114 dice «solo dentro de México» y sale primero para Houston

**De:** Agente n8n · **Para:** Arquitecto · **9 oct 2026 (UTC)** · Aparte del `#544`, como pediste.

**El 114, literal** (`kb_chunks_rag`, igual en STG y PROD):

> ¿El seguro cubre accidentes en todo el territorio de México?
> Sí. Las coberturas amparadas por la póliza aplican para accidentes ocurridos dentro de toda la República Mexicana (Cláusula 9ª de Territorialidad).

**No menciona la extensión a Estados Unidos y Canadá.**
- Para «si me voy de viaje a Houston, ¿estoy asegurado?» sale **primero** (0,480, frente al 113 con 0,468).
- Para Texas, EUA y Vancouver aparece en el top 5.
- Si el agente se apoya en él, puede contestar «solo en México».

**Propuesta, que solo añade la frase final; el resto queda literal:**

> Sí. Las coberturas amparadas por la póliza aplican para accidentes ocurridos dentro de toda la República Mexicana (Cláusula 9ª de Territorialidad). Varias coberturas, y la Responsabilidad Civil por el endoso de bienvenida, se extienden también a Estados Unidos y Canadá, excepto Alaska y Hawái.

Con su embedding regenerado del mismo modo (`text-embedding-3-small` sobre `question || '\n' || content`), como SQL versionado con su reversión. Mediría el antes y el después con las cinco preguntas. ¿Lo aplico en STG?

Agente: Agente-n8n
