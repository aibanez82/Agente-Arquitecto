#!/usr/bin/env python3
# Uso: doc_issues.py <doc> '<json de cambios>'
# cambios: {"quitar":[n,...], "filas":{"n":"| n | ... |"}, "nuevas":[["## 6. ","| n | ... |"],...], "cabecera":"texto", "movimiento":"- ..."}
import sys,re,json
p=sys.argv[1]; ch=json.loads(sys.argv[2]); L=open(p).read().split('\n')
st=lambda: next(i for i,l in enumerate(L) if l.startswith('## 1. '))
en=lambda: next(i for i,l in enumerate(L) if l.startswith('## Movimientos del'))
num=lambda l: (re.match(r'^\| (\d+)',l) or [None,None])[1]
q=set(str(x) for x in ch.get('quitar',[]))
a,b=st(),en(); L=[l for i,l in enumerate(L) if not (a<=i<b and num(l) in q)]
for n,row in ch.get('filas',{}).items():
    a,b=st(),en(); idx=[i for i in range(a,b) if num(L[i])==str(n)]
    assert idx, f'fila {n} no encontrada'; L[idx[0]]=row
for sec,row in ch.get('nuevas',[]):
    i=next(j for j,l in enumerate(L) if l.startswith(sec)); k=next(j for j in range(i,len(L)) if L[j].startswith('|---')); L.insert(k+1,row)
for i,l in enumerate(L):
    m=re.match(r'^(## \d+\. .*)\((\d+)\)$',l)
    if m:
        j=i+1;c=0
        while j<len(L) and not L[j].startswith('## '):
            c+= bool(re.match(r'^\| \d+',L[j])); j+=1
        L[i]=f'{m.group(1)}({c})'
a,b=st(),en(); rows=[L[i].split('|') for i in range(a,b) if re.match(r'^\| \d+',L[i])]
from collections import Counter
R=Counter(r[3].strip() for r in rows); P=Counter(r[4].strip() for r in rows)
def ar(x):
    x=x.strip()
    if x.startswith('—'): return 'Sin arreglo'
    if re.search(r'(?i)parcial',x): return 'Parcial'
    if x.startswith('PROD'): return 'Solo PROD (falta caso real)'
    if x.startswith('STG'): return 'Solo STG'
    if x.startswith('Ambos'): return 'En los dos entornos (falta acreditar)'
    if x.startswith('Firmado'): return 'Firmado, en curso'
    return 'Otro'
A=Counter(ar(r[5]) for r in rows)
s='\n'.join(L); ta=s.index('## Totales'); tb=s.index('\n---\n\n## 1. ')
lab={'A':'Alberto','J':'Juan','J + A':'Compartido'}; pl={'PROD':'PROD','¿?':'No consta','Ambos':'Ambos','STG':'STG'}
t=f"## Totales ({ch.get('etiqueta','')}: {len(rows)} en tablas + `#578`, la lista de prioridades)\n\n| Responsable | Issues |\n|---|---|\n"
t+=''.join(f"| {lab.get(k,k)} | {v} |\n" for k,v in R.most_common())
t+="\n| Problema en | Issues |\n|---|---|\n"+''.join(f"| {pl.get(k,k)} | {v} |\n" for k,v in P.most_common())
t+="\n| Arreglo | Issues |\n|---|---|\n"+''.join(f"| {k} | {v} |\n" for k,v in A.most_common())
s=s[:ta]+t+s[tb:]
if ch.get('cabecera'):
    s=re.sub(r'(\n> \*\*10 oct, )', '\n'+ch['cabecera']+'\n>\n> **10 oct, ', s, count=1)
if ch.get('movimiento'):
    k=s.index('\n---\n\n## Movimientos del 9 oct'); s=s[:k]+'\n'+ch['movimiento']+s[k:]
open(p,'w').write(s); print('filas',len(rows))
