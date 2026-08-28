#!/usr/bin/env python3
"""Genera la vista ejecutiva del tracker HYL-WAI a partir de `gh issue list --json`.

Uso:  gh issue list --repo aguayo-co/HYL-WAI --state open --limit 200 \
        --json number,title,labels,assignees,createdAt,updatedAt,comments,body > iss.json
      python3 gen-tablero.py iss.json salida.html

La columna «área» y la de «entorno» son CLASIFICACIÓN DEL ARQUITECTO, no campos del
tracker: GitHub no las lleva. Si algún día existen como labels, este mapeo se retira.
"""
import json, sys, re, datetime, html

AREAS = [
    ("Infra y seguridad", r"seguridad|hardcode|n8n_token|scheduler|aislar n8n|grant |privileg|rotar|\[infra\]"),
    ("Seguimientos",      r"followup|quote_followup|seguimiento|recordatorio|reenganche|re-enganche"),
    ("Descuentos",        r"descuento|discount|recotiz"),
    ("Pagos y cobro",     r"pago|payment|recibo|receipt|cobran|conciliaci|comision|factur|opl|liga de pago|ledger"),
    ("Emisión",           r"emisi|emitir|vin|placas|n[uú]mero de serie|p[óo]liza emitida"),
    ("Conversación",      r"bot|conversaci|copy|whatsapp|takeover|atenci[óo]n humana|r[áa]faga|prompt|cobertura|mensaje"),
    ("Datos y trazas",    r"trazabilidad|histor|inventario|schema|lead\.estado|drift|export|duplicad"),
]
AREA_CASO = {
    "Descuentos":        "Cerrar ventas que se caen por precio",
    "Pagos y cobro":     "Que el dinero se cobre y se reconozca",
    "Conversación":      "Que el bot no pierda al cliente por el camino",
    "Emisión":           "Que la póliza salga bien a la primera",
    "Seguimientos":      "Recuperar leads que se enfrían",
    "Datos y trazas":    "Saber qué pasó de verdad",
    "Infra y seguridad": "Que no se caiga ni se filtre",
    "Arquitectura":      "Que mañana esto se pueda extender",
}
def area(i):
    t = (i["title"] + " " + (i.get("body") or ""))[:1200].lower()
    if re.search(r"\[arquitectura\]|\[c6\]|\[c9\]|schema steward|separar identidad", t): return "Arquitectura"
    for nombre, pat in AREAS:
        if re.search(pat, t): return nombre
    return "Arquitectura"

def entorno(i):
    t = (i["title"] + " " + (i.get("body") or ""))[:2000]
    prod = bool(re.search(r"\[PROD\]|en PROD|producci[óo]n|PROD vivo", t, re.I))
    stg  = bool(re.search(r"\[STG\]|staging|en STG", t, re.I))
    if prod and stg: return ("ambos", "Arreglado en STG · vivo en PROD")
    if prod: return ("prod", "Producción")
    if stg:  return ("stg", "Staging")
    return ("none", "Sin entorno")

def crit(i):
    ls = {l["name"] for l in i["labels"]}
    for k, v in (("criticidad:critico","CRÍTICO"),("criticidad:alto","ALTO"),("criticidad:medio","medio")):
        if k in ls: return v
    return "—"
CRIT_ORD = {"CRÍTICO":0,"ALTO":1,"medio":2,"—":3}

def resumen(i):
    b = re.sub(r"```.*?```", " ", (i.get("body") or ""), flags=re.S)
    b = re.sub(r"[#>*`|_\[\]]", " ", b)
    b = re.sub(r"https?://\S+", " ", b)
    b = re.sub(r"\s+", " ", b).strip()
    for salto in ("Qué pasa", "Objetivo", "Contexto", "Problema"):
        m = re.search(re.escape(salto) + r"(.{40,300})", b)
        if m: b = m.group(1).strip(); break
    return (b[:190] + "…") if len(b) > 190 else (b or "—")

hoy = datetime.date.today()
def edad(i): return (hoy - datetime.date.fromisoformat(i["createdAt"][:10])).days
def quieto(i): return (hoy - datetime.date.fromisoformat(i["updatedAt"][:10])).days

data = json.load(open(sys.argv[1], encoding="utf-8"))
for i in data:
    i["_area"] = area(i); i["_env"], i["_envtxt"] = entorno(i)
    i["_crit"] = crit(i); i["_res"] = resumen(i)
    i["_edad"] = edad(i); i["_quieto"] = quieto(i)
    i["_asig"] = ", ".join(a["login"] for a in i["assignees"]) or ""
    i["_sist"] = ", ".join(sorted(l["name"].split(":")[1] for l in i["labels"] if l["name"].startswith("sistema:"))) or "—"
data.sort(key=lambda i: (CRIT_ORD[i["_crit"]], 0 if not i["_asig"] else 1, -i["_edad"]))
json.dump({"n": len(data), "items": data}, open(sys.argv[2] + ".data.json", "w"), ensure_ascii=False)
print(f"clasificados {len(data)} issues -> {sys.argv[2]}.data.json")
for a in sorted({i['_area'] for i in data}):
    print(f"   {a:<20} {sum(1 for i in data if i['_area']==a)}")
