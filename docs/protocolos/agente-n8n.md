## Agente n8n — protocolo de uso

**Repo:** `aibanez82/Agente_n8n` (nombre a confirmar cuando se cree)
**Rol:** Ejecutor Nivel 3, especializado en workflows n8n. Yo (Arquitecto) diagnostico y le paso el bug/nodo a tocar; Agente n8n ejecuta el cambio en el JSON. Nunca decide qué tocar de forma autónoma.

**Flujo v1 (handoff manual, sin clonar repos entre sí):**
```
Arquitecto diagnostica → identifica workflow + nodo exacto a modificar
    ↓
Alberto baja la última versión del JSON
  (Agente-n8n:main/workflows/ — su propio repo — o export fresco de n8n)
    ↓
Alberto se lo pasa a Agente n8n desde una carpeta local
    ↓
Agente n8n analiza, propone mejora, modifica el JSON
    ↓
Agente n8n hace commit/push a su propio repo
    ↓
El Agente n8n importa el JSON por API (Alberto, 25 ago 2026). STG sin preguntar; PROD solo con orden explícita de Alberto.
    ↓
Alberto re-exporta de PROD a Agente-n8n:main/workflows/
  y se verifica por versionId contra la API (no por nº de nodos)
```

**Punto de atención (reescrito el 23 ago):** el riesgo ya no es que el JSON se quede en el repo del Agente n8n — **ese repo ES ahora la red de seguridad**. El riesgo es el inverso: que se importe algo a PROD y **no se re-exporte**, dejando la instancia por delante del repo sin que nadie lo note.

La comprobación es **`versionId` contra `GET /api/v1/workflows`**, no el recuento de nodos: dos grafos distintos pueden coincidir en número. Medido así el 23 ago, los cinco de PROD estaban al día.

> La versión anterior de este párrafo mandaba sincronizar `docs/n8n-workflows/` de Agente-Arquitecto. Esa carpeta está retirada: llevaba desde el 26 jul con 3 de 5 workflows y el bot en 113 nodos contra los 119 vivos.

**✅ Nombre de repo confirmado:** `aibanez82/Agente-n8n` (con guion). Clonado en local en `~/claude-projects/Agente-n8n` (8 jul) y con push directo habilitado — mismo `gh auth` (scope `repo`) que el resto de los repos de esta cuenta, sin setup adicional. Esto cierra el gap de "no tengo escritura en ese repo": ahora puedo dejar handoffs directamente en `Agente-n8n/handoffs/` en vez de depender de que Alberto los copie.


## Regla de concurrencia en el clon local (28 jul 2026)

El Arquitecto y el Agente n8n comparten `~/claude-projects/Agente-n8n` en la misma máquina.
Detectado durante la Fase 0 del port de HYL-WAI#132: un checkout del Arquitecto cambió la rama
del working tree mientras el Agente n8n trabajaba (riesgo real de carrera; esa vez sin pérdida).
Regla desde entonces: **el Arquitecto no opera directamente sobre ese clon** — usa un
`git worktree` propio (p. ej. en su scratchpad) para leer/commitear en paralelo, y solo el
Agente n8n toca el working tree principal.
