import json, sys, html, datetime
d = json.load(open(sys.argv[1], encoding="utf-8")); items = d["items"]
hoy = datetime.date.today().strftime("%d %b %Y").lower()
iso = datetime.datetime.now(datetime.timezone.utc).isoformat()
CASO = {"Descuentos":"Cerrar ventas que se caen por precio","Pagos y cobro":"Que el dinero se cobre y se reconozca",
 "Conversación":"Que el bot no pierda al cliente por el camino","Emisión":"Que la póliza salga bien a la primera",
 "Seguimientos":"Recuperar leads que se enfrían","Datos y trazas":"Saber qué pasó de verdad",
 "Infra y seguridad":"Que no se caiga ni se filtre","Arquitectura":"Que mañana esto se pueda extender"}
ORDEN = ["Pagos y cobro","Descuentos","Conversación","Emisión","Seguimientos","Infra y seguridad","Datos y trazas","Arquitectura"]
e = html.escape
sinres = sum(1 for i in items if not i["_asig"]); alto = sum(1 for i in items if i["_crit"] in ("CRÍTICO","ALTO"))
prod = sum(1 for i in items if i["_env"] in ("prod","ambos")); viejos = sum(1 for i in items if i["_edad"] > 30)

def fila(i):
    cls = {"CRÍTICO":"c-crit","ALTO":"c-alto","medio":"c-med","—":"c-non"}[i["_crit"]]
    asig = f'<span class="who">{e(i["_asig"])}</span>' if i["_asig"] else '<span class="nadie">sin responsable</span>'
    quieto = f'<span class="{"viejo" if i["_quieto"]>7 else ""}">{i["_quieto"]}d</span>'
    return f'''<tr>
<td class="num"><a href="https://github.com/aguayo-co/HYL-WAI/issues/{i['number']}" target="_blank" rel="noopener">#{i['number']}</a></td>
<td class="tit"><strong>{e(i['title'])}</strong><span class="res">{e(i['_res'])}</span></td>
<td>{asig}</td>
<td><span class="crit {cls}">{i['_crit']}</span></td>
<td><span class="env env-{i['_env']}">{e(i['_envtxt'])}</span></td>
<td class="num2">{i['_edad']}d</td>
<td class="num2">{quieto}</td>
<td class="sis">{e(i['_sist'])}</td></tr>'''

secciones = ""
for a in ORDEN:
    grp = [i for i in items if i["_area"] == a]
    if not grp: continue
    ncrit = sum(1 for i in grp if i["_crit"] in ("CRÍTICO","ALTO")); nsin = sum(1 for i in grp if not i["_asig"])
    secciones += f'''<section><div class="ah"><h2>{e(a)}</h2><p class="caso">{e(CASO[a])}</p>
<div class="astat"><span>{len(grp)} abiertos</span>{f'<span class="bad">{ncrit} crítico/alto</span>' if ncrit else ''}{f'<span class="bad">{nsin} sin responsable</span>' if nsin else ''}</div></div>
<div class="scroller"><table><thead><tr><th>#</th><th>Issue</th><th>Asignado</th><th>Crit.</th><th>Entorno</th><th>Edad</th><th>Quieto</th><th>Sistema</th></tr></thead>
<tbody>{"".join(fila(i) for i in grp)}</tbody></table></div></section>'''

open(sys.argv[2], "w", encoding="utf-8").write(f'''<title>Tablero Ejecutivo HYL-WAI</title>
<style>
:root{{--paper:#F6F7F9;--surface:#FFF;--surface-2:#EFF2F6;--ink:#161A21;--ink-2:#4E5663;--ink-3:#7C8593;--rule:#DBE0E7;--rule-s:#C2C9D3;--accent:#2C6B8A;--accent-s:rgba(44,107,138,.10);--flag:#9C3B34;--flag-s:rgba(156,59,52,.09);--warn:#8A6412;--warn-s:rgba(138,100,18,.11);--ok:#3D7355;--ok-s:rgba(61,115,85,.10);--sh:0 1px 2px rgba(22,26,33,.05),0 8px 24px -18px rgba(22,26,33,.35);--serif:Georgia,"Iowan Old Style",serif;--sans:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;--mono:ui-monospace,SFMono-Regular,Menlo,Consolas,monospace}}
@media(prefers-color-scheme:dark){{:root:not([data-theme="light"]){{--paper:#101318;--surface:#171B22;--surface-2:#1D222B;--ink:#E6E9EE;--ink-2:#A3ABB8;--ink-3:#79828F;--rule:#262C35;--rule-s:#39414D;--accent:#74B4D2;--accent-s:rgba(116,180,210,.13);--flag:#DE867F;--flag-s:rgba(222,134,127,.13);--warn:#D6AC55;--warn-s:rgba(214,172,85,.13);--ok:#7DB79A;--ok-s:rgba(125,183,154,.13);--sh:0 1px 2px rgba(0,0,0,.4),0 8px 24px -18px rgba(0,0,0,.8)}}}}
:root[data-theme="dark"]{{--paper:#101318;--surface:#171B22;--surface-2:#1D222B;--ink:#E6E9EE;--ink-2:#A3ABB8;--ink-3:#79828F;--rule:#262C35;--rule-s:#39414D;--accent:#74B4D2;--accent-s:rgba(116,180,210,.13);--flag:#DE867F;--flag-s:rgba(222,134,127,.13);--warn:#D6AC55;--warn-s:rgba(214,172,85,.13);--ok:#7DB79A;--ok-s:rgba(125,183,154,.13);--sh:0 1px 2px rgba(0,0,0,.4),0 8px 24px -18px rgba(0,0,0,.8)}}
body{{background:var(--paper);color:var(--ink);font-family:var(--sans);font-size:15px;line-height:1.55;padding:0 22px 80px;-webkit-font-smoothing:antialiased}}
.wrap{{max-width:1280px;margin:0 auto}}
header{{padding:48px 0 24px;border-bottom:2px solid var(--ink);display:flex;flex-direction:column;gap:11px}}
.kicker{{font-family:var(--mono);font-size:11px;letter-spacing:.14em;text-transform:uppercase;color:var(--ink-3);display:flex;flex-wrap:wrap;gap:8px 18px}}
h1{{font-family:var(--serif);font-weight:400;font-size:clamp(29px,4.4vw,44px);line-height:1.1;letter-spacing:-.015em;margin:0}}
.sf{{font-family:var(--serif);font-size:17.5px;color:var(--ink-2);max-width:66ch;margin:0}}
.kpis{{display:grid;grid-template-columns:repeat(auto-fit,minmax(140px,1fr));gap:13px;margin:24px 0 4px}}
.kpi{{background:var(--surface);border:1px solid var(--rule);border-radius:6px;padding:15px 17px;box-shadow:var(--sh)}}
.kpi .n{{font-family:var(--serif);font-size:32px;line-height:1;letter-spacing:-.02em;display:block}}
.kpi .l{{font-family:var(--mono);font-size:10px;letter-spacing:.1em;text-transform:uppercase;color:var(--ink-3);margin-top:7px;display:block}}
.kpi.bad .n{{color:var(--flag)}}.kpi.warn .n{{color:var(--warn)}}
section{{padding:34px 0 0}}
.ah{{display:flex;flex-wrap:wrap;align-items:baseline;gap:6px 16px;border-bottom:1px solid var(--rule-s);padding-bottom:8px;margin-bottom:2px}}
h2{{font-family:var(--serif);font-weight:400;font-size:25px;margin:0;letter-spacing:-.01em}}
.caso{{margin:0;color:var(--accent);font-size:14px;font-style:italic}}
.astat{{margin-left:auto;font-family:var(--mono);font-size:10.5px;letter-spacing:.06em;color:var(--ink-3);display:flex;gap:12px}}
.astat .bad{{color:var(--flag);font-weight:600}}
.scroller{{overflow-x:auto;margin:14px 0 0;border:1px solid var(--rule);border-radius:6px;background:var(--surface);box-shadow:var(--sh)}}
table{{border-collapse:collapse;width:100%;min-width:900px;font-size:13.5px}}
th,td{{text-align:left;padding:9px 12px;border-bottom:1px solid var(--rule);vertical-align:top}}
thead th{{font-family:var(--mono);font-size:9.5px;letter-spacing:.12em;text-transform:uppercase;color:var(--ink-3);font-weight:500;background:var(--surface-2);border-bottom:1px solid var(--rule-s);white-space:nowrap}}
tbody tr:last-child td{{border-bottom:none}}
td.num a{{font-family:var(--mono);color:var(--accent);text-decoration:none;font-variant-numeric:tabular-nums;white-space:nowrap}}
td.num a:hover{{text-decoration:underline}}
td.num2{{font-family:var(--mono);font-variant-numeric:tabular-nums;color:var(--ink-3);white-space:nowrap;font-size:12px}}
.viejo{{color:var(--warn);font-weight:700}}
td.tit strong{{font-weight:600;display:block;margin-bottom:3px}}
td.tit .res{{display:block;color:var(--ink-3);font-size:12.5px;line-height:1.45}}
.who{{font-family:var(--mono);font-size:11.5px;white-space:nowrap}}
.nadie{{font-family:var(--mono);font-size:11px;color:var(--flag);font-weight:700;white-space:nowrap}}
.crit{{font-family:var(--mono);font-size:9.5px;font-weight:700;letter-spacing:.06em;padding:2px 6px;border-radius:3px;white-space:nowrap}}
.c-crit{{color:var(--flag);background:var(--flag-s);border:1px solid var(--flag)}}
.c-alto{{color:var(--warn);background:var(--warn-s);border:1px solid var(--warn)}}
.c-med{{color:var(--ink-2);background:var(--surface-2);border:1px solid var(--rule-s)}}
.c-non{{color:var(--ink-3)}}
.env{{font-family:var(--mono);font-size:9.5px;padding:2px 6px;border-radius:3px;white-space:nowrap}}
.env-prod{{color:var(--flag);background:var(--flag-s);border:1px solid var(--flag)}}
.env-ambos{{color:var(--warn);background:var(--warn-s);border:1px solid var(--warn)}}
.env-stg{{color:var(--accent);background:var(--accent-s);border:1px solid var(--accent)}}
.env-none{{color:var(--ink-3);border:1px solid var(--rule-s)}}
td.sis{{font-family:var(--mono);font-size:11px;color:var(--ink-3);white-space:nowrap}}
.nota{{border:1px solid var(--rule-s);border-left:3px solid var(--accent);background:var(--surface);border-radius:0 6px 6px 0;padding:15px 19px;margin:22px 0}}
.nota .tag{{font-family:var(--mono);font-size:10px;letter-spacing:.13em;text-transform:uppercase;color:var(--accent);display:block;margin-bottom:6px}}
.nota p{{margin:0 0 9px;max-width:74ch}} .nota p:last-child{{margin:0}}
footer{{margin-top:46px;padding-top:19px;border-top:1px solid var(--rule);font-family:var(--mono);font-size:11.5px;color:var(--ink-3);display:flex;flex-wrap:wrap;gap:6px 18px}}
#fresc{{display:none;margin:18px 0 0;padding:13px 17px;border-radius:6px;font-size:14px;border:1px solid;align-items:baseline;gap:10px}}
#fresc.on{{display:flex;flex-wrap:wrap}}
#fresc.tibio{{color:var(--warn);background:var(--warn-s);border-color:var(--warn)}}
#fresc.frio{{color:var(--flag);background:var(--flag-s);border-color:var(--flag)}}
#fresc b{{font-family:var(--mono);font-size:11px;letter-spacing:.1em;text-transform:uppercase}}
#fresc span{{color:var(--ink-2)}}
.pedir{{font-family:var(--mono);font-size:12px;background:var(--surface-2);border:1px solid var(--rule-s);border-radius:4px;padding:2px 7px;color:var(--ink)}}
a{{color:var(--accent)}} :focus-visible{{outline:2px solid var(--accent);outline-offset:3px}}
</style>
<div class="wrap">
<header><div class="kicker"><span>aguayo-co/HYL-WAI</span><span>vista ejecutiva</span><span>datos del {hoy}</span></div>
<h1>{d["n"]} issues abiertos</h1>
<p class="sf">Agrupados por lo que compran para el negocio, no por sistema. Ordenados dentro de cada bloque por criticidad y por antigüedad — lo que más duele y lleva más tiempo doliendo, arriba.</p></header>
<div class="kpis">
<div class="kpi"><span class="n">{d["n"]}</span><span class="l">abiertos</span></div>
<div class="kpi bad"><span class="n">{sinres}</span><span class="l">sin responsable</span></div>
<div class="kpi bad"><span class="n">{alto}</span><span class="l">crítico o alto</span></div>
<div class="kpi warn"><span class="n">{prod}</span><span class="l">tocan producción</span></div>
<div class="kpi warn"><span class="n">{viejos}</span><span class="l">más de 30 días</span></div>
</div>
<div id="fresc" data-gen="{iso}"></div>
<div class="nota"><span class="tag">Cómo leer esta página</span>
<p><strong>«Área» y «Entorno» no son campos del tracker: los deduzco yo.</strong> GitHub no lleva ninguna de las dos, y por eso nadie más puede reproducir esta clasificación. El día que existan como etiquetas, este mapeo se retira y la página pasa a leer el dato real.</p>
<p><strong>«Quieto» es el dato que más señala:</strong> días desde el último movimiento. Un issue crítico y quieto no es un issue trabajándose, es uno olvidado.</p>
<p><strong>No es una página viva.</strong> No consulta GitHub: el repo es privado y una página publicada no puede llevar credenciales. Los datos son de la fecha del encabezado y se refrescan republicándola.</p></div>
{secciones}
<script>
(function(){{
  var el=document.getElementById('fresc'); if(!el) return;
  var gen=new Date(el.dataset.gen), d=Math.floor((Date.now()-gen.getTime())/86400000);
  if(d<2) return;                       // fresco: no mete ruido
  el.className='on '+(d>=7?'frio':'tibio');
  el.innerHTML='<b>'+(d>=7?'datos fríos':'datos con '+d+' días')+'</b>'+
    '<span>Esta página no consulta GitHub: la foto es del '+gen.toLocaleDateString('es-ES')+
    ', hace '+d+' días. Para refrescarla, pídeselo al Arquitecto: <code class="pedir">actualiza el tablero</code></span>';
}})();
</script>
<footer><span>Arquitecto-IA-Quálitas</span><span>clasificación de área y entorno: mía</span><span>{d["n"]} issues · {hoy}</span></footer>
</div>''')
print("html generado")
