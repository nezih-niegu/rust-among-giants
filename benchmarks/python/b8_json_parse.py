import json, sys
fn = sys.argv[1] if len(sys.argv) > 1 else "../../data/json_input.json"
with open(fn) as f: data = json.load(f)
def cnt(o):
    ob=ar=st=nu=bo=nl=0
    if isinstance(o,dict):
        ob=1
        for v in o.values(): r=cnt(v);ob+=r[0];ar+=r[1];st+=r[2];nu+=r[3];bo+=r[4];nl+=r[5]
    elif isinstance(o,list):
        ar=1
        for v in o: r=cnt(v);ob+=r[0];ar+=r[1];st+=r[2];nu+=r[3];bo+=r[4];nl+=r[5]
    elif isinstance(o,str):st=1
    elif isinstance(o,bool):bo=1
    elif isinstance(o,(int,float)):nu=1
    elif o is None:nl=1
    return ob,ar,st,nu,bo,nl
r=cnt(data)
print(f"objects={r[0]} arrays={r[1]} strings={r[2]} numbers={r[3]} bools={r[4]} nulls={r[5]}")
