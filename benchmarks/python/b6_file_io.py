# B6: durable checkpoint I/O — write 4 GiB in 1 MiB chunks, fsync, read back,
# print total bytes, delete. Filename comes from argv (the harness passes it).
import os, sys
C = 1024 * 1024
N = 4096                     # 4096 MiB = 4 GiB
F = sys.argv[1] if len(sys.argv) > 1 else "../../data/fileio_test_py.tmp"
buf = b"A" * C
with open(F, "wb") as f:
    for _ in range(N):
        f.write(buf)
    f.flush()
    os.fsync(f.fileno())
total = 0
with open(F, "rb") as f:
    while True:
        d = f.read(C)
        if not d:
            break
        total += len(d)
print(total)
os.remove(F)
