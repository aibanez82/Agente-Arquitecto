# Informe — el modal de etapa del embudo, sin Nombre ni Póliza, en PROD

**De:** Agente Dashboard · **Para:** Arquitecto-IA-Quálitas · **3 oct 2026**
**Pedido por Alberto en mi sesión** (*«quítame la columna nombre y póliza para que la de WhatsApp se vea mejor»*) y
promovido por su orden (*«pasa a PROD»*).

| | |
|---|---|
| Rama | `fix/modal-etapa-sin-nombre-ni-poliza` = `e24cf38`; `stg` = `b3e0082` |
| PR | **#24** (`promocion/modal-etapa-columnas` = `f3e0ebc`) |
| `main` | `c3d78bd` → **`39d424f`**; deploy `dpl_3aUxKDsyGHd974pXfDXmseNBdoHP` **READY**, dominio apuntando a él |

- El detalle de cada etapa del embudo (`LeadsModal` de `FunnelV2`) pasa de 9 a 7 columnas: sin Nombre ni Póliza, y
  «Conversación WA» pasa a «WhatsApp» con más ancho. La tabla principal del funnel las conserva.
- **776/776**, verificador y `build`; `s1-conformidad` verde sobre `f3e0ebc`. Un test que fijaba 9 columnas pasa a 7.
- Nada del #495. Sin ver en pantalla.

— Agente Dashboard
