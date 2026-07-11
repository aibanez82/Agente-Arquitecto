## Agente n8n — protocolo de uso

**Repo:** `aibanez82/Agente_n8n` (nombre a confirmar cuando se cree)
**Rol:** Ejecutor Nivel 3, especializado en workflows n8n. Yo (Arquitecto) diagnostico y le paso el bug/nodo a tocar; Agente n8n ejecuta el cambio en el JSON. Nunca decide qué tocar de forma autónoma.

**Flujo v1 (handoff manual, sin clonar repos entre sí):**
```
Arquitecto diagnostica → identifica workflow + nodo exacto a modificar
    ↓
Alberto baja la última versión del JSON
  (docs/n8n-workflows/ en este repo, o export fresco de n8n)
    ↓
Alberto se lo pasa a Agente n8n desde una carpeta local
    ↓
Agente n8n analiza, propone mejora, modifica el JSON
    ↓
Agente n8n hace commit/push a su propio repo
    ↓
Alberto importa el JSON manualmente en n8n (producción)
    ↓
Alberto actualiza docs/n8n-workflows/ en Agente-Arquitecto
  con la versión final importada (mantener fuente de verdad sincronizada)
```

**Punto de atención:** como Agente n8n no tiene clonado este repo, el JSON que modifica vive solo en su propio repo hasta que Alberto lo reimporta a producción y lo vuelve a traer aquí. Si se salta el último paso, `docs/n8n-workflows/` en este repo queda desactualizado respecto a lo que corre en producción — mismo riesgo que ya existía con el backup manual (ver `docs/architecture/backup-policy-n8n.md`).

**✅ Nombre de repo confirmado:** `aibanez82/Agente-n8n` (con guion). Clonado en local en `~/claude-projects/Agente-n8n` (8 jul) y con push directo habilitado — mismo `gh auth` (scope `repo`) que el resto de los repos de esta cuenta, sin setup adicional. Esto cierra el gap de "no tengo escritura en ese repo": ahora puedo dejar handoffs directamente en `Agente-n8n/handoffs/` en vez de depender de que Alberto los copie.
