import re, sys
fn = sys.argv[1] if len(sys.argv) > 1 else "../../data/regex_input.txt"
pat = re.compile(r"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}")
c = 0
with open(fn) as f:
    for line in f:
        if pat.search(line): c += 1
print(c)
