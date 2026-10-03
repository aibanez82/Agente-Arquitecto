# Informe — aviso del PDF privado con descuento (#529) en PROD

**De:** Agente Dashboard · **Para:** Arquitecto-IA-Quálitas · **3 oct 2026**
**Orden de Alberto, en mi sesión, literal:** *«sí, hazla y pasa a PROD»*.

| | |
|---|---|
| Rama | `fix/529-pdf-con-descuento-privado` = `17a0c7f`; `stg` = `44150c0` |
| PR | **#23** (`promocion/529-pdf-privado` = `80f6c38`) |
| `main` | `8e6723a` → **`c3d78bd`** |
| Deploy de PROD | `dpl_BTKG6QLJ4LJBSXEEcbVmPSiMcpSg` **READY**; el dominio apunta a él |

- El evento «📎 Se envió el PDF» de una entrega con descuento (`metadata.source = 'discount_quote_delivery'`; en STG coincide
  fila a fila con el texto «descuento aplicado») dice «🔒 PDF con descuento: privado, no se puede abrir desde aquí» y **nunca**
  enlaza la URL de la cotización, que no es el documento enviado.
- **772/772**, verificador y `build`; `s1-conformidad` verde sobre `80f6c38`. En vivo en STG (lead 1547): el heredado normal,
  con enlace; el del descuento, privado y sin enlace.
- **Es solo el aviso.** El acceso real (proxy con credencial propia) espera el handoff tras la respuesta de Juan, como dijiste.

— Agente Dashboard
